function model=fitFrequency(train,val)
%FITFREQUENCY Select only on validation; test data are not accepted.
assert(isempty(intersect(train.id,val.id)),'femstudy:split:Leakage','Training and validation overlap.');
assert(all(train.F(:)>0) && all(val.F(:)>0));
rng(42); kernels=["ardmatern52","ardsquaredexponential"];
xm=mean(train.X,1); xs=std(train.X,0,1); xs(xs==0)=1;
Z=(train.X-xm)./xs; V=(val.X-xm)./xs;
Y=log(train.F); ym=mean(Y,1); ys=std(Y,0,1); ys(ys==0)=1;
for k=1:2
    candidate=cell(1,size(Y,2)); pred=zeros(size(val.F));
    for j=1:size(Y,2)
        candidate{j}=fitrgp(Z,(Y(:,j)-ym(j))/ys(j),KernelFunction=kernels(k), ...
            Standardize=false,Sigma=1e-4,SigmaLowerBound=1e-8,ConstantSigma=true);
        pred(:,j)=exp(ym(j)+ys(j)*predict(candidate{j},V));
    end
    score(k)=mean(abs(pred-val.F)./val.F,'all'); %#ok<AGROW>
    candidates{k}=candidate; %#ok<AGROW>
end
[~,winner]=min(score);
model=struct('schema',"frequency-gpr-v1",'kernel',kernels(winner), ...
    'validationScores',score,'xm',xm,'xs',xs,'ym',ym,'ys',ys, ...
    'net',{candidates{winner}},'trainIDs',train.id,'validationIDs',val.id,'seed',42);
end
