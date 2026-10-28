function evaluate_deeponet_baselines(count)
%evaluate_deeponet_baselines - Evaluate frozen baselines without retraining.
root=fileparts(mfilename('fullpath')); addpath(genpath(fullfile(root,'modelle')));
out=fullfile(root,'experiments','deeponet_20261023_v1');
source=fullfile(root,'experiments','training_size_12_24_48_20261023');
romFolder=fullfile(root,'experiments','pod_galerkin_20261023_v1');
if nargin==0
    for n=[12 24 48 96 192 384], evaluate_deeponet_baselines(n); end
    for kind=["summary","per_case","spatial","timing_samples"]
        combined=table;
        for n=[12 24 48 96 192 384]
            file=fullfile(out,"baseline_n"+n+"_"+kind+".csv");
            if isfile(file)
                part=readtable(file,TextType="string");
                combined=[combined;part]; %#ok<AGROW>
            end
        end
        writetable(combined,fullfile(out,"baseline_"+kind+".csv"));
    end
    return
end
if isfile(fullfile(out,'baseline_summary.csv')), return; end
if isfile(fullfile(out,"baseline_n"+count+"_summary.csv")), return; end
rp=load(fullfile(romFolder,'protocol.mat')); rows=table; cases=table;
spatial=table; timingRows=table;
for N=count
    a=load(fullfile(source,"n"+N,'models.mat')); models=a.models;
    a=load(fullfile(source,"n"+N,'test.mat')); D=a.D;
    a=load(fullfile(romFolder,"n"+N,'model.mat')); ROM=a.model;
    reference=load(fullfile(romFolder,"n"+N,'test_predictions.mat'),'predictions');
    Q=size(D.xi,2); tip=find(all(D.xi==[1;.5;.5],1));
    for k=1:7
        floorE=nan(1,6); rank=NaN;
        if k<=5
            M=models{k}; name=M.name; fullField=M.type=="field";
            predict=@(x) predict_surrogate(M,x);
            offline=M.seconds;
            if fullField
                rank=size(M.pod.V,2);
                B=sqrt(D.w).*M.pod.V;
                floorH=M.pod.mean+M.pod.V*(B\(sqrt(D.w).*(D.S-M.pod.mean)));
                floorE=field_error(D.S,floorH,D.w);
            end
        elseif k==6
            name="Beam_theory"; fullField=false;
            predict=@beam_tip; offline=0;
        else
            name="POD_Galerkin"; fullField=true;
            predict=@(x) rom_field(rp.mesh,ROM.V,x); offline=NaN;
            rank=size(ROM.V,2); B=sqrt(D.w).*(rp.mesh.O*ROM.V);
            floorH=(rp.mesh.O*ROM.V)*lsqminnorm(B,sqrt(D.w).*D.S);
            floorE=field_error(D.S,floorH,D.w);
        end
        E=nan(6,1); C=nan(6,1); Y=nan(6,2); H=nan(3*Q,6);
        elapsed=zeros(6,5);
        for j=1:6
            pred=predict(D.X(j,:));
            if fullField
                H(:,j)=pred;
                Y(j,:)=scalars(pred,Q,tip);
                E(j)=field_error(D.S(:,j),pred,D.w);
                C(j)=max(abs(pred(repmat(D.xi(1,:)'==0,3,1))));
            else
                Y(j,1:numel(pred))=pred;
            end
            for repeat=1:5
                tick=tic; predict(D.X(j,:));
                elapsed(j,repeat)=toc(tick);
                timingRows=[timingRows;table(N,string(name),D.id(j),repeat,elapsed(j,repeat), ...
                    'VariableNames',{'TrainingCases','Model','CaseID','Repeat','Seconds'})]; %#ok<AGROW>
            end
        end
        if k==7
            assert(max(field_error(reference.predictions{6},H,D.w))<1e-9, ...
                'ROM field-only timing path must reproduce the verified predictor.');
        end
        row=table(N,string(name),rank,median(E),prctile(E,95),max(E), ...
            mean(abs(Y(:,1)-D.Y(:,1))),mean(abs(Y(:,2)-D.Y(:,2))), ...
            max(C),median(elapsed,'all'),median(floorE),offline, ...
            'VariableNames',{'TrainingCases','Model','PODRank','FieldMedianRelL2', ...
            'FieldP95RelL2','FieldWorstRelL2','TipMAE_m','MaxGridMAE_m', ...
            'ClampMax_m','OnlineSeconds','ProjectionMedianRelL2','HistoricalFitSeconds'});
        rows=[rows;row]; %#ok<AGROW>
        pc=table(repmat(N,6,1),repmat(string(name),6,1),D.id(:),E, ...
            abs(Y(:,1)-D.Y(:,1)),abs(Y(:,2)-D.Y(:,2)),C,floorE(:), ...
            'VariableNames',{'TrainingCases','Model','CaseID','FieldRelativeL2', ...
            'TipAbsError_m','MaxGridAbsError_m','ClampMax_m','ProjectionFloor'});
        cases=[cases;pc]; %#ok<AGROW>
        if fullField && N==384
            for j=1:6
                gap=sqrt((H(1:Q,j)-D.S(1:Q,j)).^2+ ...
                    (H(Q+(1:Q),j)-D.S(Q+(1:Q),j)).^2+ ...
                    (H(2*Q+(1:Q),j)-D.S(2*Q+(1:Q),j)).^2);
                spatial=[spatial;table(repmat(string(name),Q,1),repmat(D.id(j),Q,1), ...
                    D.xi(1,:)',D.xi(2,:)',D.xi(3,:)',gap, ...
                    D.S(2*Q+(1:Q),j),H(2*Q+(1:Q),j), ...
                    'VariableNames',{'Model','CaseID','Xi','Eta','Zeta','VectorError_m','ReferenceUz_m','PredictedUz_m'})]; %#ok<AGROW>
            end
        end
    end
end
writetable(cases,fullfile(out,"baseline_n"+count+"_per_case.csv"));
if ~isempty(spatial), writetable(spatial,fullfile(out,"baseline_n"+count+"_spatial.csv")); end
writetable(timingRows,fullfile(out,"baseline_n"+count+"_timing_samples.csv"));
writetable(rows,fullfile(out,"baseline_n"+count+"_summary.csv"));
end

function y=scalars(H,Q,tip)
y=[H(2*Q+tip),max(sqrt(H(1:Q).^2+H(Q+(1:Q)).^2+H(2*Q+(1:Q)).^2))];
end

function H=rom_field(mesh,V,X)
% Same verified Galerkin equations, with no post-prediction diagnostics.
[K,f]=rom_assemble(mesh,X);
Kr=V'*(K*V); fr=V'*f;
H=mesh.O*(V*(Kr\fr));
end
