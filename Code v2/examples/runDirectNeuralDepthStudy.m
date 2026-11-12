function summary = runDirectNeuralDepthStudy(outputDir)
%runDirectNeuralDepthStudy Compare direct MLP and RBF+tanh depths with Adam.
%   18 runs: methods mlp/rbf, total hidden depths 1/2/3, seeds 42/43/44.
%   Uses 768 static training cases and the existing 128-case validation set.
%   RBF depth includes the fixed Gaussian layer. No test data is loaded.
%   Completed, verified checkpoints are reused on restart.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
if nargin<1
    outputDir=fullfile(root,'experiments','direct_neural_depth_adam_20261111');
end
assert(java.io.File(root).getUsableSpace()>1024^3, ...
    'surrogate:depthStudy:DiskSpace','At least 1 GiB free space is required before starting.');
trainingFile=fullfile(root,'data_generation','data','static','train.mat');
validationFile=fullfile(root,'experiments','pod_mlp_fresh_validation_128_20261108', ...
    'reference_data','static','val.mat');
training=surrogate.loadDataset(trainingFile);
validation=surrogate.loadDataset(validationFile);
surrogate.validateTrainingSplits(training,validation);
assert(numel(training.caseIds)==768 && numel(validation.caseIds)==128, ...
    'surrogate:depthStudy:Counts','Expected 768 training and 128 validation cases.');
cfg=struct('seed',42,'hiddenWidth',64,'hiddenLayers',1,'centerCount',64, ...
    'rbfWidth',1,'optimizer',"adam",'maxEpochs',200,'miniBatchSize',32, ...
    'learningRate',1e-3,'momentum',0.9,'maxWorkspaceBytes',1024^3);
plan=struct('baseConfig',cfg,'methods',["mlp","rbf"],'depths',1:3,'seeds',42:44, ...
    'trainingCaseIds',training.caseIds,'validationCaseIds',validation.caseIds, ...
    'trainingSHA256',sha256File(trainingFile),'validationSHA256',sha256File(validationFile), ...
    'trainingOrder',"original order, identical for all seeds and methods", ...
    'testDataLoaded',false,'validationPreviouslyUsed',true,'matlabVersion',string(version));
sourceFiles=[dir(fullfile(root,'+surrogate','**','*.m')); ...
    dir(fullfile(root,'examples','runDirectNeuralDepthStudy.m'))];
sourcePaths=string(fullfile({sourceFiles.folder},{sourceFiles.name}))';
plan.sourceFiles=erase(sourcePaths,string(root)+filesep);
plan.sourceHashes=arrayfun(@sha256File,sourcePaths);
if isfolder(outputDir)
    old=load(fullfile(outputDir,'study_plan.mat'),'plan');
    assert(isequaln(old.plan,plan),'surrogate:depthStudy:ChangedPlan', ...
        'Data, code or configuration changed since this study was started.');
else
    mkdir(outputDir); mkdir(fullfile(outputDir,'models'));
    save(fullfile(outputDir,'study_plan.mat'),'plan');
end
writetable(table(plan.sourceFiles,plan.sourceHashes, ...
    'VariableNames',{'File','SHA256'}),fullfile(outputDir,'code_manifest.csv'));
writeScope(outputDir);
request=struct('inputParameters',validation.inputParameters, ...
    'parameterNames',validation.parameterNames,'parameterUnits',validation.parameterUnits, ...
    'caseIds',validation.caseIds);
floors=struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0);
runs=table(); cases=table(); modelFiles=strings(0,1); modelHashes=strings(0,1);
for method=plan.methods
    for depth=plan.depths
        for seed=plan.seeds
            cfg.seed=seed; cfg.hiddenLayers=depth;
            file=fullfile(outputDir,'models',sprintf('%s_depth%d_seed%d.mat',method,depth,seed));
            if isfile(file)
                saved=load(file,'model','elapsed');
                model=saved.model; elapsed=saved.elapsed;
                assert(isequaln(model.config,cfg) && model.methodId==method && ...
                    isequal(model.trainingCaseIds,training.caseIds), ...
                    'surrogate:depthStudy:Checkpoint','Checkpoint does not match plan.');
            else
                assert(java.io.File(outputDir).getUsableSpace()>256*1024^2, ...
                    'surrogate:depthStudy:DiskSpace','Less than 256 MiB free; restart after freeing space.');
                fprintf('START %s depth=%d seed=%d\n',method,depth,seed);
                timer=tic;
                [model,report]=surrogate.fitModel(method,training,cfg);
                elapsed=toc(timer);
                temporary=[file,'.partial'];
                save(temporary,'model','report','elapsed','-v7.3');
                movefile(temporary,file);
            end
            prediction=surrogate.predictModel(model,request);
            metrics=surrogate.evaluatePrediction(prediction,validation,floors);
            % Independent direct L2 calculation checks evaluation/export alignment.
            weights=validation.displacementComponentWeights;
            difference=prediction.displacementFields-validation.displacementFields;
            absolute=sqrt(sum(weights.*difference.^2,1))';
            reference=sqrt(sum(weights.*validation.displacementFields.^2,1))';
            assert(all(abs(absolute-metrics.absoluteWeightedFieldError)<1e-12), ...
                'surrogate:depthStudy:Metric','Independent weighted L2 check failed.');
            defined=reference>0;
            relative=absolute(defined)./reference(defined);
            assert(all(isfinite(relative)) && ~isempty(relative), ...
                'surrogate:depthStudy:Metric','No finite relative errors available.');
            sorted=sort(relative*100);
            run=table(method,depth,seed,elapsed,mean(sorted),median(sorted), ...
                sorted(ceil(0.95*numel(sorted))),max(sorted),sum(~defined), ...
                'VariableNames',{'Method','Depth','Seed','TrainingSeconds', ...
                'MeanPercent','MedianPercent','P95Percent','MaxPercent','UndefinedCount'});
            count=numel(validation.caseIds);
            block=table(repmat(method,count,1),repmat(depth,count,1), ...
                repmat(seed,count,1),validation.caseIds,absolute,reference, ...
                metrics.relativeWeightedFieldError, ...
                'VariableNames',{'Method','Depth','Seed','CaseId', ...
                'AbsoluteErrorM','ReferenceNormM','RelativeError'});
            runs=[runs;run]; cases=[cases;block]; %#ok<AGROW>
            modelFiles(end+1,1)=string(file); %#ok<AGROW>
            modelHashes(end+1,1)=sha256File(file); %#ok<AGROW>
            writetable(runs,fullfile(outputDir,'run_metrics.csv'));
            writetable(cases,fullfile(outputDir,'validation_case_errors.csv'));
            fprintf('DONE %s depth=%d seed=%d mean=%.3f%% p95=%.3f%% time=%.1fs\n', ...
                method,depth,seed,run.MeanPercent,run.P95Percent,elapsed);
        end
    end
end
assert(height(runs)==18 && height(cases)==18*128, ...
    'surrogate:depthStudy:Incomplete','Study is incomplete.');
summary=groupsummary(runs,["Method","Depth"],"mean", ...
    ["MeanPercent","MedianPercent","P95Percent","TrainingSeconds"]);
worst=groupsummary(runs,["Method","Depth"],"max","MaxPercent");
summary=innerjoin(summary,worst(:,["Method","Depth","max_MaxPercent"]), ...
    'Keys',{'Method','Depth'});
summary=sortrows(summary,'mean_MeanPercent');
writetable(summary,fullfile(outputDir,'summary_by_architecture.csv'));
writetable(table(modelFiles,modelHashes,'VariableNames',{'File','SHA256'}), ...
    fullfile(outputDir,'model_manifest.csv'));
plotResults(summary,outputDir);
writeResults(summary,outputDir);
fprintf('COMPLETE: 18 models and 2304 case predictions verified.\n');
disp(summary);
end

function plotResults(summary,outputDir)
fig=figure('Visible','off','Position',[50 50 1200 760]);
cleanup=onCleanup(@()close(fig));
layout=tiledlayout(fig,2,2,'TileSpacing','compact');
fields=["mean_MeanPercent","mean_MedianPercent","mean_P95Percent","max_MaxPercent"];
titles=["Mean across cases (seed average)","Median across cases (seed average)", ...
    "P95 across cases (seed average)","Worst case across all seeds"];
for k=1:4
    ax=nexttile(layout); hold(ax,'on');
    for method=["mlp","rbf"]
        rows=sortrows(summary(summary.Method==method,:),'Depth');
        plot(ax,rows.Depth,rows.(fields(k)),'-o','LineWidth',1.8,'DisplayName',upper(method));
    end
    xticks(ax,1:3); grid(ax,'on'); xlabel(ax,'Total hidden layers');
    ylabel(ax,'Relative weighted L2 error [%]'); title(ax,titles(k));
    legend(ax,'Location','best');
end
title(layout,{'MLP vs RBF+tanh: Adam, width 64, 200 epochs', ...
    '768 training / 128 reused validation cases; RBF depth includes Gaussian layer'});
exportgraphics(fig,fullfile(outputDir,'architecture_comparison.png'),'Resolution',150);
end

function writeScope(outputDir)
file=fopen(fullfile(outputDir,'STUDY_SCOPE.txt'),'w');
assert(file>=0); cleanup=onCleanup(@()fclose(file));
fprintf(file,['Exploratory static validation study, not an independent test.\n', ...
    '768 identical training cases in original order; 128 reused validation cases.\n', ...
    'Methods: direct MLP and RBF+tanh; total hidden depths 1,2,3.\n', ...
    'MLP: depth tanh layers of width 64. RBF: 64 fixed Gaussian features,\n', ...
    'width 1 in standardized input space, then depth-1 tanh layers of width 64.\n', ...
    'Adam, learning rate 0.001, 200 epochs, batch 32, seeds 42/43/44, CPU.\n', ...
    'Training loss: per-output standardized MSE, no POD or weighted-field loss.\n', ...
    'Last training iteration, no validation early stopping; no test data read.\n', ...
    'Selection metric: mean relative weighted L2 case error, averaged over seeds.\n', ...
    'P95: nearest rank per seed; maximum: worst actual case across all seeds.\n', ...
    'Same RBF centers for every seed; seeds change initialization and batch order.\n']);
end

function writeResults(summary,outputDir)
file=fopen(fullfile(outputDir,'ERGEBNISSE.md'),'w');
assert(file>=0); cleanup=onCleanup(@()fclose(file));
fprintf(file,'# MLP/RBF Adam-Tiefenstudie\n\n18 Trainingslaeufe abgeschlossen.\n\n');
fprintf(file,'768 Trainingsfaelle, 128 bereits verwendete Validierungsfaelle, Seeds 42/43/44.\n');
fprintf(file,'64 Einheiten pro Schicht; Adam, 200 Epochen, Lernrate 0.001, Batch 32.\n\n');
fprintf(file,'| Methode | Schichten | Mittelwert | Median | P95 | Maximum |\n');
fprintf(file,'|---|---:|---:|---:|---:|---:|\n');
for k=1:height(summary)
    r=summary(k,:);
    fprintf(file,'| %s | %d | %.3f %% | %.3f %% | %.3f %% | %.3f %% |\n', ...
        upper(r.Method),r.Depth,r.mean_MeanPercent,r.mean_MedianPercent, ...
        r.mean_P95Percent,r.max_MaxPercent);
end
fprintf(file,['\nMittelwert, Median und P95 werden zuerst pro Seed ueber Faelle berechnet,\n', ...
    'danach ueber drei Seeds gemittelt. Maximum ist der groesste Fallfehler aller Seeds.\n', ...
    'RBF zaehlt eine feste Gauss-Schicht plus 0/1/2 tanh-Schichten; MLP zaehlt nur tanh-Schichten.\n', ...
    'Die Ausgabe ist jeweils linear. Trainiert wird standardisierte Ausgabe-MSE.\n', ...
    'Dies ist eine explorative Modellwahl auf wiederverwendeter Validierung, kein Abschlusstest.\n']);
end

function hash = sha256File(path)
fid=fopen(path,'rb'); assert(fid>=0); cleanup=onCleanup(@()fclose(fid));
digest=java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    digest.update(fread(fid,1024^2,'*uint8'));
end
hash=string(lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[])));
end
