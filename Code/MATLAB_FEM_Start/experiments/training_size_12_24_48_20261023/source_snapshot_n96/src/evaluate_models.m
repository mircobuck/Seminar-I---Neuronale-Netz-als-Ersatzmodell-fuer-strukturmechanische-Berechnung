function evaluate_models(c)
a=load(fullfile(c.out,'models.mat')); models=a.models; meta=a.meta;
a=load(fullfile(c.out,'test.mat'),'D'); te=a.D;
assert(isempty(intersect([meta.trainIDs;meta.valIDs],te.id)));
assert(isequal(meta.physics,te.physics),'Incompatible test data.');
summary=table(); perCase=table(); predictions=cell(size(models));
for k=1:numel(models)
    M=models{k}; H=predict_surrogate(M,te.X); predictions{k}=H;
    latency=timeit(@()predict_surrogate(M,te.X(1,:)));
    fieldMedian=NaN; fieldP95=NaN; fieldWorst=NaN; podFloor=NaN;
    tipMAE=NaN; maxMAE=NaN;
    if M.type=="field"
        e=field_error(te.S,H,te.w);
        fieldMedian=median(e); fieldP95=prctile(e,95); fieldWorst=max(e);
        proj=M.pod.mean+M.pod.V*pod_encode(M.pod,te.S)';
        podFloor=median(field_error(te.S,proj,te.w));
        nq=size(te.xi,2); nh=size(H,2);
        mag=sqrt(H(1:nq,:).^2+H(nq+1:2*nq,:).^2+H(2*nq+1:end,:).^2);
        maxMAE=mean(abs(max(mag,[],1)'-te.Y(:,2)));
    else
        tipMAE=mean(abs(H(:,1)-te.Y(:,1)));
        e=abs(H(:,1)-te.Y(:,1))./max(abs(te.Y(:,1)),1e-12);
        if size(H,2)>1, maxMAE=mean(abs(H(:,2)-te.Y(:,2))); end
    end
    row=table(M.name,fieldMedian,fieldP95,fieldWorst,podFloor,tipMAE,maxMAE, ...
        latency,M.seconds,'VariableNames',{'Model','FieldMedianRelL2', ...
        'FieldP95RelL2','FieldWorstRelL2','PODProjectionMedian', ...
        'TipMAE_m','MaxGridDisplacementMAE_m','OnlineSecondsOneCase', ...
        'TrainingAndSelectionSeconds'});
    pc=table(repmat(M.name,numel(te.id),1),te.id,e, ...
        'VariableNames',{'Model','CaseID','RelativeError'});
    if isempty(summary), summary=row; perCase=pc;
    else, summary=[summary;row]; perCase=[perCase;pc]; end %#ok<AGROW>
end
writetable(summary,fullfile(c.out,'test_summary.csv'));
writetable(perCase,fullfile(c.out,'test_per_case.csv'));
beamMAE=mean(abs(beam_tip(te.X)-te.Y(:,1)));
fprintf('Beam theory tip MAE: %.5g m\n',beamMAE); disp(summary);
femTiming=struct('medianEndToEndSeconds',median(te.seconds), ...
    'beamTipMAE_m',beamMAE);
save(fullfile(c.out,'test_predictions.mat'),'predictions','summary','femTiming','-v7.3');
end
