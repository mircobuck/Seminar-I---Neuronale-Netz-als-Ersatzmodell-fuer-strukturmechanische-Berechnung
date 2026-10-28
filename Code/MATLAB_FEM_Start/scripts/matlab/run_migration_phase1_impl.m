function run_migration_phase1_impl(stage)
%RUN_MIGRATION_PHASE1 Independent, resumable small modal integration.
if nargin==0, stage="convergence"; end
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root,genpath(fullfile(root,'modelle')));
out=fullfile(root,'experiments','archive','architecture_phase1_v1');
if ~isfolder(out), mkdir(out); end
lockFile=fullfile(out,'run.lock');
lock=java.io.File(lockFile);
assert(lock.createNewFile(),'femstudy:run:Locked','Run is locked; check whether MATLAB is still running before removing run.lock.');
unlock=onCleanup(@()delete(lockFile)); %#ok<NASGU>
base=fullfile(root,'experiments','active','training_size_12_24_48_20261023','n384');
tr=load(fullfile(base,'train.mat')); va=load(fullfile(base,'val.mat'));
T=tr.D; V=va.D;
assert(isempty(intersect(T.id,V.id)));
if any(string(stage)==["static","data","evaluate"])
    te=load(fullfile(base,'test.mat')); E=te.D;
    assert(isempty(intersect(T.id,E.id)) && isempty(intersect(V.id,E.id)));
end
switch string(stage)
    case "static"
        frozen=load(fullfile(base,'models.mat'),'models');
        results=struct;
        for k=1:numel(frozen.models)
            m=frozen.models{k}; direct=predict_surrogate(m,E.X);
            adapted=femstudy.models.predictLegacy(m.name,m,E.X,struct);
            results.(char(m.name)).maximumDifference=max(abs(direct-adapted),[],'all');
            if m.type=="field"
                results.(char(m.name)).medianRelativeFieldError=median(field_error(E.S,adapted,E.w));
            else
                results.(char(m.name)).meanAbsoluteError=mean(abs(E.Y(:,1)-adapted(:,1)));
            end
        end
        results.Beam_theory.maximumDifference=max(abs(beam_tip(E.X)-femstudy.models.predictLegacy("Beam_theory",[],E.X,struct)),[],'all');
        deep=load(fullfile(root,'experiments','archive','deeponet_20261023_v1','n384','seed42','model.mat'),'model');
        direct=predict_deeponet(deep.model,E.X,E.xi);
        adapted=femstudy.models.predictLegacy("DeepONet",deep.model,E.X,struct('xi',E.xi));
        results.DeepONet.maximumDifference=max(abs(direct-adapted),[],'all');
        results.DeepONet.medianRelativeFieldError=median(field_error(E.S,adapted,E.w));
        romRoot=fullfile(root,'experiments','active','pod_galerkin_20261023_v1');
        rom=load(fullfile(romRoot,'n384','model.mat'),'model'); protocol=load(fullfile(romRoot,'protocol.mat'),'mesh');
        direct=rom_predict(protocol.mesh,rom.model.V,E.X(1,:));
        adapted=femstudy.models.predictLegacy("POD_Galerkin",rom.model,E.X(1,:),struct('mesh',protocol.mesh));
        results.POD_Galerkin.maximumDifference=max(abs(direct-adapted{1}.field),[],'all');
        file=fullfile(out,'static_integration.mat'); saveAtomic(file,results);
        file=fullfile(out,'static_gpr_proof.mat');
        if ~isfile(file)
            model=struct('name',"Scalar_GPR",'type',"scalar",'reg',fit_gps(T.X(1:12,:),T.Y(1:12,:)), ...
                'trainIDs',T.id(1:12)); saveAtomic(file,model);
        end
        fprintf('Legacy direct and adapter maximum difference: %.3g\n',max(structfun(@(x)x.maximumDifference,results)));
    case "convergence"
        indices=[1 6 12]; divisors=[2 3 4];
        for i=1:numel(indices)
            x=[T.X(indices(i),1:5),7850];
            for j=1:3
                file=fullfile(out,sprintf('convergence_%02d_%d.mat',indices(i),divisors(j)));
                if ~isfile(file)
                    result=femstudy.fem.modal(x,divisors(j)); saveAtomic(file,result);
                end
            end
            a=load(fullfile(out,sprintf('convergence_%02d_3.mat',indices(i))));
            b=load(fullfile(out,sprintf('convergence_%02d_4.mat',indices(i))));
            comparison=femstudy.fem.compareModes(a.result,b.result,.01);
            saveAtomic(fullfile(out,sprintf('comparison_%02d.mat',indices(i))),comparison);
            coarse=load(fullfile(out,sprintf('convergence_%02d_2.mat',indices(i))));
            coarseComparison=femstudy.fem.compareModes(coarse.result,a.result,.01);
            saveAtomic(fullfile(out,sprintf('comparison_coarse_%02d.mat',indices(i))),coarseComparison);
            fprintf('Case %d: pass=%d, relative errors: ',indices(i),comparison.pass); disp(comparison.relativeFrequency(1:6)');
        end
    case "data"
        allD={T,V,E}; labels=["train","val","test"]; limits=[12 6 6];
        for s=1:3
            D=allD{s};
            for i=1:limits(s)
                file=fullfile(out,sprintf('modal_%s_%03d.mat',labels(s),D.id(i)));
                if ~isfile(file)
                    result=femstudy.fem.modal([D.X(i,1:5),7850],3); saveAtomic(file,result);
                    fprintf('Saved %s\n',file);
                else
                    saved=load(file,'result');
                    assert(saved.result.schema=="modal-v1" && saved.result.divisor==3 && ...
                        isequal(saved.result.parameters,[D.X(i,1:5),7850]),'Incompatible modal checkpoint.');
                end
            end
        end
    case "density"
        x=[T.X(1,1:5),7850]; a=femstudy.fem.modal(x,2);
        x(6)=2*x(6); b=femstudy.fem.modal(x,2);
        assert(isequal(a.nodes,b.nodes) && isequal(a.elements,b.elements),'Density test meshes differ.');
        expected=1/sqrt(2); actual=b.frequencyHz(1:6)./a.frequencyHz(1:6);
        result=struct('densities',[7850 15700],'ratio',actual,'expectedRatio',expected, ...
            'maxRelativeDeviation',max(abs(actual/expected-1)),'sameMesh',true);
        saveAtomic(fullfile(out,'density_check.mat'),result);
        fprintf('Density scaling max relative deviation %.3g\n',result.maxRelativeDeviation);
    case "train"
        train=readData(out,T,"train",12); val=readData(out,V,"val",6);
        file=fullfile(out,'frequency_model.mat');
        assert(~isfile(file),'Existing trained model is immutable.');
        model=femstudy.models.fitFrequency(train,val); saveAtomic(file,model);
        fprintf('Selected %s; validation scores ',model.kernel); disp(model.validationScores);
    case "evaluate"
        M=load(fullfile(out,'frequency_model.mat')); test=readData(out,E,"test",6);
        assert(isempty(intersect(test.id,[M.result.trainIDs(:);M.result.validationIDs(:)])));
        prediction=femstudy.models.predictFrequency(M.result,test.X);
        result=struct('prediction',prediction,'metrics',femstudy.metrics.frequency(prediction,test.F), ...
            'testIDs',test.id,'truthHz',test.F);
        saveAtomic(fullfile(out,'frequency_evaluation.mat'),result);
        fprintf('Mean sorted relative frequency error: %.3f%%; order violations %.1f%%\n', ...
            100*mean(result.metrics.relativeSorted,'all'),100*result.metrics.orderViolationFraction);
    otherwise
        error('Use static, convergence, data, train or evaluate.');
end
end
function d=readData(folder,D,label,n)
d.X=[D.X(1:n,1:5),7850*ones(n,1)]; d.id=D.id(1:n); d.F=zeros(n,6);
for i=1:n
    path=fullfile(folder,sprintf('modal_%s_%03d.mat',label,d.id(i)));
    assert(isfile(path),'Missing data stage output: %s',path);
    a=load(path); d.F(i,:)=a.result.frequencyHz(1:6)';
end
end
function saveAtomic(file,result)
tmp=string(file)+".tmp.mat"; save(tmp,'result','-v7.3');
[ok,msg]=movefile(tmp,file); assert(ok,'%s',msg);
end
