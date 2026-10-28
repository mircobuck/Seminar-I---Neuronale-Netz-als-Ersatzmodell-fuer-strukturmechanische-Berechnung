function run_hybrid_static_audit_impl(stage)
%RUN_HYBRID_STATIC_AUDIT Frozen development protocol and exploratory test.
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root,genpath(fullfile(root,'modelle')));
out=fullfile(root,'experiments','hybrid_static_audit_v1');
if ~isfolder(out), mkdir(out); end
src=fullfile(root,'experiments','active','training_size_12_24_48_20261023','n384');
trainIDs=[1:12 25:30]; valIDs=31:36; testIDs=19:24;
assert(isempty(intersect(trainIDs,valIDs)) && isempty(intersect(trainIDs,testIDs)) && isempty(intersect(valIDs,testIDs)));
a=load(fullfile(src,'train.mat'),'D'); D=a.D;
it=find(ismember(D.id,trainIDs)); iv=find(ismember(D.id,valIDs));
assert(numel(it)==18 && numel(iv)==6);
X=D.X(it,:); S=D.S(:,it); Xv=D.X(iv,:); Sv=D.S(:,iv); w=D.w(:); xi=D.xi;
assert(size(unique([X;Xv],'rows'),1)==24,'Repeated physical parameter combination.');
switch string(stage)
    case "train"
        file=fullfile(out,'selection.mat'); assert(~isfile(file),'Frozen selection exists.');
        spec=struct('trainIDs',trainIDs,'valIDs',valIDs,'testIDs',testIDs, ...
            'ranks',[1 2 4 8 12],'kernels',["ardmatern52","ardsquaredexponential"], ...
            'criterion',"validation mean relative weighted field L2", ...
            'seed',42,'historicalTestPreviouslyInspected',true);
        save(fullfile(out,'protocol.mat'),'spec');
        rng(42); B=femstudy.fem.beamField(X,xi); Bv=femstudy.fem.beamField(Xv,xi);
        fields={S,S-B}; scores=inf(2,5,2); models=cell(2,5,2); elapsed=zeros(2,5,2);
        for kind=1:2
            for j=1:5
                P=pod_fit(fields{kind},w,spec.ranks(j)); coeff=pod_encode(P,fields{kind});
                for k=1:2
                    t=tic; reg=fit_gps(X,coeff,spec.kernels(k)); elapsed(kind,j,k)=toc(t);
                    H=P.mean+P.V*predict_reg(reg,Xv)';
                    if kind==2, H=H+Bv; end
                    scores(kind,j,k)=mean(field_error(Sv,H,w));
                    models{kind,j,k}=struct('pod',P,'reg',reg,'rank',P.r,'kernel',spec.kernels(k));
                end
            end
        end
        [~,ix]=min(reshape(scores(1,:,:),[],1)); [j,k]=ind2sub([5 2],ix); direct=models{1,j,k};
        [~,ix]=min(reshape(scores(2,:,:),[],1)); [j,k]=ind2sub([5 2],ix); hybrid=models{2,j,k};
        beamScore=mean(field_error(Sv,Bv,w));
        selected="hybrid"; if beamScore<=min(scores(2,:,:),[],'all'), selected="beam"; end
        save(file,'spec','scores','direct','hybrid','beamScore','selected','elapsed','-v7.3');
        fprintf('Validation beam %.6g, direct %.6g, hybrid %.6g; selected %s\n',beamScore,min(scores(1,:,:),[],'all'),min(scores(2,:,:),[],'all'),selected);
    case "evaluate"
        frozen=load(fullfile(out,'selection.mat')); a=load(fullfile(src,'test.mat'),'D'); T=a.D;
        assert(isequal(sort(T.id(:)),testIDs(:)));
        assert(size(unique([X;Xv;T.X],'rows'),1)==30,'Repeated physical parameter combination.');
        B=femstudy.fem.beamField(T.X,xi);
        H=frozen.hybrid.pod.mean+frozen.hybrid.pod.V*predict_reg(frozen.hybrid.reg,T.X)'+B;
        Q=frozen.direct.pod.mean+frozen.direct.pod.V*predict_reg(frozen.direct.reg,T.X)';
        A=pod_encode(frozen.hybrid.pod,T.S-B);
        projection=B+frozen.hybrid.pod.mean+frozen.hybrid.pod.V*A';
        result=struct('ids',T.id,'beam',field_error(T.S,B,w),'direct',field_error(T.S,Q,w), ...
            'hybrid',field_error(T.S,H,w),'projection',field_error(T.S,projection,w), ...
            'regressionGap',sqrt(sum(w.*(H-projection).^2,1))', ...
            'selected',frozen.selected);
        f=fullfile(out,'exploratory_test.mat'); assert(~isfile(f),'Existing evaluation protected.');
        save(f,'result','-v7.3');
        fprintf('Exploratory median beam %.6g, direct %.6g, hybrid %.6g, projection %.6g\n',median(result.beam),median(result.direct),median(result.hybrid),median(result.projection));
    otherwise
        error('Use train or evaluate.');
end
end
