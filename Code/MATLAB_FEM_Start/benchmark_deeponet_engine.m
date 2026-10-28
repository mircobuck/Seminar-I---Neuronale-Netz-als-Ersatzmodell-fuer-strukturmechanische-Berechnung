function result=benchmark_deeponet_engine
%benchmark_deeponet_engine - Measure cached autodifferentiation equivalence.
%   This diagnostic changes neither trained models nor optimization options.
root=fileparts(mfilename('fullpath')); addpath(genpath(fullfile(root,'modelle')));
out=fullfile(root,'experiments','deeponet_20261023_v1');
a=load(fullfile(out,'n384','candidate1','model.mat')); model=a.model;
a=load(fullfile(root,'experiments','training_size_12_24_48_20261023','n384','train.mat')); D=a.D;
Z=((D.X-model.meanX)./model.stdX)'; Y=single(D.S/model.scaleU);
args={model.branch,model.trunk,Z,D.xi,model.options.latent,Y,D.w};
plain=@() dlfeval(@deeponet_gradients,args{:});
plain(); baseline=timeit(plain);
profile on
for j=1:5, plain(); end
profile off
profiler=profile('info'); save(fullfile(out,'gradient_profile.mat'),'profiler');
accelerated=dlaccelerate(@deeponet_gradients);
cached=@() dlfeval(accelerated,args{:});
[l,b,t]=dlfeval(@deeponet_gradients,args{:});
[lc,bc,tc]=dlfeval(accelerated,args{:});
lossDifference=abs(double(extractdata(l-lc)));
gradientDifference=0;
for k=1:height(b)
    x=extractdata(b.Value{k}); y=extractdata(bc.Value{k});
    gradientDifference=max(gradientDifference,norm(x(:)-y(:))/max(norm(x(:)),1e-20));
end
for k=1:height(t)
    x=extractdata(t.Value{k}); y=extractdata(tc.Value{k});
    gradientDifference=max(gradientDifference,norm(x(:)-y(:))/max(norm(x(:)),1e-20));
end
assert(lossDifference<1e-6 && gradientDifference<1e-5);
cached(); optimized=timeit(cached);
result=table(baseline,optimized,baseline/optimized,lossDifference,gradientDifference, ...
    'VariableNames',{'PlainGradientSeconds','CachedGradientSeconds','Ratio', ...
    'LossAbsoluteDifference','MaxGradientRelativeDifference'});
writetable(result,fullfile(out,'gradient_engine_benchmark.csv')); disp(result);
end
