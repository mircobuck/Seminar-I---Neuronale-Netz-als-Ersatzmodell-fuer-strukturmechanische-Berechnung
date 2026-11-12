function [singleTimes,batchTimes] = timePrediction(model,request,cfg)
    %timePrediction Warm up and measure complete public predictions with reconstruction.
    one=request;
    one.inputParameters=one.inputParameters(1,:);
    one.caseIds=one.caseIds(1);
    batch=request;
    batch.inputParameters=batch.inputParameters(1:cfg.prediction_batch_size,:);
    batch.caseIds=batch.caseIds(1:cfg.prediction_batch_size);
    surrogate.predictModel(model,one);
    surrogate.predictModel(model,batch);
    singleTimes=zeros(cfg.prediction_repetitions,1);
    batchTimes=singleTimes;
    for t=1:cfg.prediction_repetitions
        start=tic;
        surrogate.predictModel(model,one);
        singleTimes(t)=toc(start);
        start=tic;
        surrogate.predictModel(model,batch);
        batchTimes(t)=toc(start);
    end
end
