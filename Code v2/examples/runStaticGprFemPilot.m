function runStaticGprFemPilot(outputDir)
%runStaticGprFemPilot Explore static FEM feasibility, outside all study splits.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root,fullfile(root,'fem_core'), ...
    fullfile(root,'fem_core','src'));
assert(~isfolder(outputDir),'surrogate:pilot:OutputExists','Use a new pilot directory.');
mkdir(outputDir); mkdir(fullfile(outputDir,'cases'));
oldRng=rng; cleanup=onCleanup(@()rng(oldRng)); rng(20261111,'twister');
lo=[.6 .06 .08 70e9 .25 -1000]; hi=[1.2 .10 .14 210e9 .35 -100]; span=hi-lo;
U=zeros(24,6);
for j=1:6, U(:,j)=(randperm(24)'-rand(24,1))/24; end
X=lo+U.*span; groups=zeros(24,1);
for k=1:12
    parameter=ceil(k/2); side=mod(k-1,2); groups(12+k)=k;
    if side==0, X(12+k,parameter)=lo(parameter)-span(parameter)*(.05+.05*rand);
    else, X(12+k,parameter)=hi(parameter)+span(parameter)*(.05+.05*rand); end
end
assert(all(X(:,1:4)>0,'all') && all(X(:,5)>-1 & X(:,5)<.5) && all(X(:,6)<0), ...
    'surrogate:pilot:Physical','Pilot design contains physically inadmissible parameters.');
manifest=readtable(fullfile(root,'experiments','static_pod_gpr_20261111','design_manifest.csv'), ...
    'TextType','string'); names={'L_m','b_m','h_m','E_Pa','nu','Fz_N'};
for k=1:height(manifest)
    t=readtable(fullfile(root,manifest.file(k)));
    old=t{:,names};
    for j=1:size(X,1)
        assert(~any(max(abs((old-X(j,:))./span),[],2)<=1e-10), ...
            'surrogate:pilot:Overlap','Pilot overlaps historical design.');
    end
end
assert(size(unique(X,'rows'),1)==24);
plan=array2table([(1:24)' groups X],'VariableNames',[{'pilotId','group'},names]);
writetable(plan,fullfile(outputDir,'pilot_design.csv'));
c=config('smoke'); c.saveRawMesh=false; c.geometricOrder="quadratic";
start=tic; rows=table;
for k=1:24
    meshLevels=3; if k>12, meshLevels=[3 4 6]; end
    baseline=[];
    for level=meshLevels
        c.meshDivisor=level; wall=tic; status="ok"; message=""; solverSeconds=NaN; diff=NaN;
        try
            value=solve_case(X(k,:),c); solverSeconds=value.seconds;
            if level==3, baseline=value; else
                delta=value.S-baseline.S; diff=sqrt(sum(value.w.*delta.^2))/sqrt(sum(value.w.*baseline.S.^2));
            end
            save(fullfile(outputDir,'cases',sprintf('case_%02d_mesh_%d.mat',k,level)),'value');
        catch err
            status="failed"; message=string(err.identifier)+": "+string(err.message);
        end
        rows=[rows;table(k,groups(k),level,status,message,solverSeconds,toc(wall),diff, ...
            'VariableNames',{'PilotId','Group','MeshDivisor','Status','Message','SolverSeconds','WallSeconds','RelativeToMesh3'})]; %#ok<AGROW>
        writetable(rows,fullfile(outputDir,'pilot_results.csv'));
    end
end
writelines(["PILOT ONLY: no candidate selection or test reference labels."; ...
    "Elapsed wall seconds: "+string(toc(start)); ...
    "Differences compare mesh 4 and 6 separately to mesh 3; not an error bound."], ...
    fullfile(outputDir,'STATUS.txt'));
end
