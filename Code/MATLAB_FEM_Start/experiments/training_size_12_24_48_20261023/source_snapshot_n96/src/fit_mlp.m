function M=fit_mlp(X,A,Xv,Av,width,c)
M.kind="mlp"; M.xm=mean(X,1); M.xs=std(X,0,1); M.xs(M.xs==0)=1;
M.ym=mean(A,1); M.ys=std(A,0,1); M.ys(M.ys==0)=1;
Xt=single((X-M.xm)./M.xs); At=single((A-M.ym)./M.ys);
Xv=single((Xv-M.xm)./M.xs); Av=single((Av-M.ym)./M.ys);
rng(c.modelSeed);
layers=[featureInputLayer(size(X,2),Normalization="none")
    fullyConnectedLayer(width)
    tanhLayer
    fullyConnectedLayer(width)
    tanhLayer
    fullyConnectedLayer(size(A,2))];
opts=trainingOptions("adam",MaxEpochs=c.epochs,MiniBatchSize=16, ...
    InitialLearnRate=1e-3,Shuffle="every-epoch", ...
    ValidationData={Xv,Av},ValidationFrequency=max(1,ceil(size(X,1)/16)), ...
    ValidationPatience=20,OutputNetwork="best-validation", ...
    ExecutionEnvironment="cpu",Verbose=false);
M.net=trainnet(Xt,At,layers,"mse",opts); M.width=width;
end
