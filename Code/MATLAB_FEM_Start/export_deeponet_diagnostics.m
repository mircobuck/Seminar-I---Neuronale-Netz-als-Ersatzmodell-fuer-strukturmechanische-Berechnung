function export_deeponet_diagnostics
%export_deeponet_diagnostics - Export reproducible field and component data.
root=fileparts(mfilename('fullpath')); addpath(genpath(fullfile(root,'modelle')));
out=fullfile(root,'experiments','deeponet_20261023_v1');
old=fullfile(root,'experiments','training_size_12_24_48_20261023');
a=load(fullfile(old,'n384','train.mat')); D=a.D;
v=load(fullfile(old,'n384','val.mat')); V=v.D;
t=load(fullfile(old,'n384','test.mat')); T=t.D;
assert(size(unique([D.X;V.X;T.X],'rows'),1)==396);
assert(isequal(D.w,V.w,T.w));
cfg=config("smoke"); allX=[D.X;V.X;T.X];
assert(all(allX>=cfg.lower & allX<=cfg.upper,'all'));
assert(isequaln(D.physics,V.physics,T.physics));
partitions={D,V,T};
for partition=1:3
    A=partitions{partition}; Q=size(A.xi,2);
    tip=find(all(A.xi==[1;.5;.5],1));
    gridMaximum=max(sqrt(A.S(1:Q,:).^2+A.S(Q+(1:Q),:).^2+ ...
        A.S(2*Q+(1:Q),:).^2),[],1)';
    assert(max(abs(gridMaximum-A.Y(:,2)))<1e-12);
    assert(max(abs(A.S(2*Q+tip,:)'-A.Y(:,1)))<1e-12);
    clamp=repmat(A.xi(1,:)'==0,3,1);
    assert(all(A.S(clamp,:)==0,'all'));
end
Q=size(T.xi,2); spatial=table; components=table; timings=table; preparation=table;
for N=[12 24 48 96 192 384]
    tick=tic;
    a=load(fullfile(old,"n"+N,'train.mat')); train=a.D;
    a=load(fullfile(old,"n"+N,'val.mat')); validation=a.D;
    dataLoadSeconds=toc(tick); tick=tic;
    meanX=mean(train.X,1); stdX=std(train.X,0,1);
    scaleU=sqrt(mean(sum(train.w.*train.S.^2,1)));
    Z=((train.X-meanX)./stdX)'; Y=single(train.S/scaleU);
    scalingSeconds=toc(tick);
    assert(all(isfinite(Z),'all') && all(isfinite(Y),'all'));
    assert(isequal(validation.id,V.id));
    preparation=[preparation;table(N,dataLoadSeconds,scalingSeconds,scaleU, ...
        'VariableNames',{'TrainingCases','WarmDataLoadSeconds','ScalingSeconds','DisplacementScale_m'})]; %#ok<AGROW>
    for seed=42:46
        folder=fullfile(out,"n"+N,"seed"+seed);
        a=load(fullfile(folder,'model.mat')); model=a.model;
        assert(isequal(model.meanX,meanX) && isequal(model.stdX,stdX) && model.scaleU==scaleU);
        a=load(fullfile(folder,'test_predictions.mat')); H=a.H;
        for c=1:3
            idx=(c-1)*Q+(1:Q); w=T.w(idx);
            e=field_error(T.S(idx,:),H(idx,:),w);
            absolute=sqrt(sum(w.*(T.S(idx,:)-H(idx,:)).^2,1));
            components=[components;table(repmat(N,6,1),repmat(seed,6,1), ...
                T.id(:),repmat(c,6,1),e(:),absolute(:), ...
                'VariableNames',{'TrainingCases','Seed','CaseID','Component', ...
                'ComponentRelativeL2','ComponentWeightedRMS_m'})]; %#ok<AGROW>
        end
        for j=1:6
            for repeat=1:5
                timings=[timings;table(N,seed,T.id(j),repeat,a.times(j,repeat), ...
                    'VariableNames',{'TrainingCases','Seed','CaseID','Repeat','Seconds'})]; %#ok<AGROW>
            end
        end
        if N==384 && seed==42
            for j=1:6
                gap=sqrt(sum(reshape(H(:,j)-T.S(:,j),Q,3).^2,2));
                spatial=[spatial;table(repmat("DeepONet",Q,1),repmat(T.id(j),Q,1), ...
                    T.xi(1,:)',T.xi(2,:)',T.xi(3,:)',gap, ...
                    T.S(2*Q+(1:Q),j),H(2*Q+(1:Q),j), ...
                    'VariableNames',{'Model','CaseID','Xi','Eta','Zeta', ...
                    'VectorError_m','ReferenceUz_m','PredictedUz_m'})]; %#ok<AGROW>
            end
        end
        assert(all(isfinite(H),'all'));
        assert(isequal(model.valIDs,V.id));
    end
end
writetable(spatial,fullfile(out,'deeponet_spatial_seed42.csv'));
writetable(components,fullfile(out,'component_errors.csv'));
writetable(timings,fullfile(out,'deeponet_timing_samples.csv'));
writetable(preparation,fullfile(out,'data_preparation.csv'));
writelines('PASS: 396 unique parameter rows; bounds, SI order, shared weights, all 30 finite predictions and validation IDs.', ...
    fullfile(out,'final_data_audit.txt'));
end
