function benchmark_v1
here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
main=fullfile(root,'experiments','static_gpr_main_v1_20261111_run2');
snap=fullfile(main,'source_snapshot'); addpath(snap,fullfile(snap,'fem_core'),fullfile(snap,'fem_core','src'));
addpath(fullfile(snap,'studies','static_gpr_v1'));
studyCheckFrozen(main);
indices=[1 24 47 70 93 116 139 162 185 208 231 254];
data=surrogate.loadDataset(fullfile(main,'references','interpolation','test.mat'));
X=data.inputParameters(indices,:); ids=data.caseIds(indices);
T=array2table([double(ids(:)),X],'VariableNames',{'id','L_m','b_m','h_m','E_Pa','nu','Fz_N'});
writetable(T,fullfile(here,'benchmark_cases.csv'));
femConfig=config('smoke'); femConfig.meshDivisor=3; femConfig.geometricOrder="quadratic";
femConfig.saveRawMesh=false; femConfig.maxDeflectionRatio=0.02;
meta=struct('matlab',version,'computer',computer,'startedUTC',char(datetime('now','TimeZone','UTC')), ...
    'indices',indices,'ids',ids,'femConfig',femConfig,'warmup',1,'femRepeats',2,'surrogateRepeats',30);
save(fullfile(here,'benchmark_meta.mat'),'meta');
femWarm=solve_case(X(1,:),femConfig); assert(numel(femWarm.S)==1575);
femTimes=zeros(12,2); femInternal=femTimes;
for k=1:2
    order=1:12; if k==2, order=12:-1:1; end
    for j=order
        t=tic; value=solve_case(X(j,:),femConfig); femTimes(j,k)=toc(t);
        femInternal(j,k)=value.seconds;
        fprintf('FEM repeat %d case %d: %.3f s\n',k,ids(j),femTimes(j,k));
        save(fullfile(here,'fem_partial.mat'),'femTimes','femInternal','ids');
    end
end
methods=["mlp","rbf","pod_mlp","pod_gpr"]; single=zeros(12,30,4); batch=zeros(30,4); loadTimes=zeros(4,1);
for m=1:4
    file=fullfile(main,'runs',sprintf('n768_rep1_%s_seed42',methods(m)),'model.mat');
    t=tic; model=surrogate.loadModel(file); loadTimes(m)=toc(t);
    request=struct('inputParameters',X,'parameterNames',data.parameterNames,'parameterUnits',data.parameterUnits,'caseIds',ids);
    one=request; one.inputParameters=X(1,:); one.caseIds=ids(1);
    surrogate.predictModel(model,one); surrogate.predictModel(model,request);
    for k=1:30
        for j=1:12
            one.inputParameters=X(j,:); one.caseIds=ids(j);
            t=tic; surrogate.predictModel(model,one); single(j,k,m)=toc(t);
        end
        t=tic; surrogate.predictModel(model,request); batch(k,m)=toc(t);
    end
    fprintf('Surrogate %s done\n',methods(m));
    save(fullfile(here,'surrogate_partial.mat'),'single','batch','loadTimes','methods','ids');
end
studyCheckFrozen(main);
save(fullfile(here,'benchmark_results.mat'),'meta','femTimes','femInternal','single','batch','loadTimes','methods','ids');
fid=fopen(fullfile(here,'benchmark_complete.txt'),'w'); fprintf(fid,'complete\n'); fclose(fid);
end
