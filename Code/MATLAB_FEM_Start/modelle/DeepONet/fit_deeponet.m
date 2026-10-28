function [model,info] = fit_deeponet(D,V,options,folder)
%fit_deeponet - Fit a parametric multi-output DeepONet on complete cases.
%   [model,info] = fit_deeponet(D,V,options,folder) saves resumable Adam
%   state and the best validation checkpoint. Existing final models return
%   unchanged. Validation is mean relative weighted squared field error.
%   See also predict_deeponet, deeponet_gradients
if ~isfolder(folder), mkdir(folder); end
final = fullfile(folder,'model.mat');
if isfile(final)
    saved = load(final); model=saved.model; info=saved.info;
    assert(isequal(model.trainIDs,D.id) && isequaln(model.options,options));
    return
end
clockPrep=tic;
checkpoint=fullfile(folder,'checkpoint.mat');
if isfile(checkpoint)
    a=load(checkpoint,'state'); state=a.state;
    assert(isequal(state.model.trainIDs,D.id));
    assert(isequaln(state.model.options,options));
else
    rng(options.seed,'twister');
    model.options=options; model.trainIDs=D.id; model.valIDs=V.id;
    model.meanX=mean(D.X,1); model.stdX=std(D.X,0,1);
    model.scaleU=sqrt(mean(sum(D.w.*D.S.^2,1)));
    model.branch=make_net(6,options.width,3*options.latent);
    model.trunk=make_net(3,options.width,options.latent);
    model.name="Parametric_DeepONet";
    state=struct('model',model,'epoch',0,'aB',[],'sB',[], ...
        'aT',[],'sT',[],'best',inf,'stale',0,'history',zeros(0,4), ...
        'trainSeconds',0,'bestEpoch',0,'prepSeconds',0);
end
Z=((D.X-state.model.meanX)./state.model.stdX)';
Y=single(D.S/state.model.scaleU);
gradientFunction=dlaccelerate(@deeponet_gradients);
state.prepSeconds=state.prepSeconds+toc(clockPrep);
clockTrain=tic;
for epoch=state.epoch+1:options.epochs
    lr=options.learnRate*0.5^floor((epoch-1)/500);
    [loss,gB,gT]=dlfeval(gradientFunction,state.model.branch, ...
        state.model.trunk,Z,D.xi,options.latent,Y,D.w);
    value=double(extractdata(loss));
    assert(isfinite(value),'DeepONet:NonfiniteLoss','Nonfinite training loss');
    [state.model.branch,state.aB,state.sB]=adamupdate(state.model.branch, ...
        gB,state.aB,state.sB,epoch,lr);
    [state.model.trunk,state.aT,state.sT]=adamupdate(state.model.trunk, ...
        gT,state.aT,state.sT,epoch,lr);
    state.epoch=epoch;
    if mod(epoch,options.validateEvery)==0 || epoch==1
        H=predict_deeponet(state.model,V.X,V.xi);
        e=field_error(V.S,H,V.w); score=mean(e.^2);
        state.history(end+1,:)=[epoch value score lr];
        if score<state.best*(1-1e-5)
            state.best=score; state.bestModel=state.model;
            state.bestEpoch=epoch; state.stale=0;
        else
            state.stale=state.stale+1;
        end
    end
    if mod(epoch,100)==0 || epoch==options.epochs || ...
            state.stale>=options.patience
        state.trainSeconds=state.trainSeconds+toc(clockTrain);
        save_atomic(checkpoint,state); clockTrain=tic;
    end
    if state.stale>=options.patience, break; end
end
state.trainSeconds=state.trainSeconds+toc(clockTrain);
save_atomic(checkpoint,state);
model=state.bestModel;
info=struct('epochs',state.epoch,'bestEpoch',state.bestEpoch, ...
    'gradientEngine',"dlaccelerate", ...
    'validationScore',state.best,'trainingSeconds',state.trainSeconds, ...
    'preparationSeconds',state.prepSeconds, ...
    'parameterCount',sum(cellfun(@numel,model.branch.Learnables.Value))+ ...
    sum(cellfun(@numel,model.trunk.Learnables.Value)));
history=array2table(state.history,'VariableNames', ...
    {'Epoch','TrainingRelativeSquared','ValidationRelativeSquared','LearnRate'});
writetable(history,fullfile(folder,'history.csv'));
save(final,'model','info','-v7.3');
fprintf('N=%d seed=%d width=%d latent=%d epochs=%d val=%.6g time=%.2fs\n', ...
    size(D.X,1),options.seed,options.width,options.latent,info.epochs, ...
    info.validationScore,info.trainingSeconds);
end

function net=make_net(inputs,width,outputs)
net=dlnetwork([featureInputLayer(inputs,Normalization="none")
    fullyConnectedLayer(width)
    tanhLayer
    fullyConnectedLayer(width)
    tanhLayer
    fullyConnectedLayer(outputs)]);
end

function save_atomic(file,state)
tmp=string(file)+".tmp.mat";
save(tmp,'state','-v7.3'); movefile(tmp,file,'f');
end
