function candidates=studyCandidates(method)
base=struct('seed',42,'datasetId',"main_static",'optimizer',"adam", ...
    'maxEpochs',200,'miniBatchSize',32,'learningRate',.001);
candidates={};
switch string(method)
    case "mlp"
        for w=[64 128], for depth=2:3, for rate=[.0005 .001], for loss=["standardized_output_mse","weighted_field_mse"]
            c=base; c.hiddenWidth=w; c.hiddenLayers=depth; c.learningRate=rate; c.lossMode=loss;
            candidates{end+1}=c; %#ok<AGROW>
        end, end, end, end
    case "rbf"
        for depth=2:3, for count=[32 64], for width=[.5 1 2], for loss=["standardized_output_mse","weighted_field_mse"]
            c=base; c.hiddenWidth=64; c.hiddenLayers=depth; c.centerCount=count; c.rbfWidth=width; c.lossMode=loss;
            candidates{end+1}=c; %#ok<AGROW>
        end, end, end, end
    case "pod_mlp"
        for rank=[2 10 15], for w=[64 80], for depth=2:3
            c=base; c.rank=rank; c.hiddenWidth=w; c.hiddenLayers=depth; c.lossMode="weighted_field_mse";
            candidates{end+1}=c; %#ok<AGROW>
        end, end, end
    case "pod_gpr"
        for rank=[2 10 15], for kernel=["ardsquaredexponential","ardmatern52"], ...
                for meanFunction=["constant","linear"], for sigma=[1e-4 1e-3]
            c=base; c.rank=rank; c.kernel=kernel; c.basisFunction=meanFunction; c.sigma=sigma;
            candidates{end+1}=c; %#ok<AGROW>
        end, end, end, end
    otherwise, error('study:Method','Unknown method.');
end
N=numel(candidates); candidates=candidates(mod((0:N-1)*5,N)+1);
end
