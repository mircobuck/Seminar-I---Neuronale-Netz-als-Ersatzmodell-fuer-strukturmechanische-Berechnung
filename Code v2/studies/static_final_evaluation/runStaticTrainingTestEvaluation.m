function result = runStaticTrainingTestEvaluation(outputDir,trainingCases)
%runStaticTrainingTestEvaluation Evaluate frozen static POD-MLP models.
%   Evaluates widths 64/128, depths 1:6 and seeds 42/43/44 on the existing
%   static test split. TRAININGCASES selects the saved 384- or 768-case stage.
%   No models are retrained and no plots are exported.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
studyRoot=fileparts(mfilename('fullpath'));
addpath(root,studyRoot);
assert(isscalar(trainingCases) && ismember(trainingCases,[384 768]), ...
    'surrogate:final:TrainingCount','Training count must be 384 or 768.');
dataDir=fullfile(root,'data_generation','data','static');
widths=[64 128]; layers=1:6; seeds=[42 43 44];
if trainingCases==384
    records=readtable(fullfile(root,'..','..','POD_MLP_Versuchsprotokoll', ...
        'alle_versuchslaeufe.csv'),'TextType','string');
    records=records(records.TrainingCases==trainingCases,:);
else
    records=table();
end
models=repmat(struct('label',"",'file',""),numel(widths)*numel(layers)*numel(seeds),1);
k=0;
for width=widths
    for layer=layers
        for seed=seeds
            k=k+1;
            if trainingCases==768
                folder=fullfile(root,'experiments','static_768_20261105', ...
                    sprintf('width_%d_layers_%d',width,layer));
                file=fullfile(folder,sprintf('pod_mlp_adam_%d_n%d_seed%d.mat', ...
                    width,trainingCases,seed));
            else
                match=records.NeuronsPerLayer==width & records.HiddenLayers==layer & ...
                    records.Seed==seed;
                assert(nnz(match)==1,'surrogate:final:Models', ...
                    'Expected one historical model record for width %d, depth %d, seed %d.', ...
                    width,layer,seed);
                relativeFile=string(records.ModelFile(match));
                file=fullfile(root,'..','..',relativeFile);
            end
            models(k)=struct('label',sprintf("POD_MLP_ADAM_%d_NEURONS_%d_LAYERS_SEED%d", ...
                width,layer,seed),'file',string(file));
        end
    end
end
for k=1:numel(models)
    assert(isfile(models(k).file),'surrogate:final:Models', ...
        'Missing frozen model file: %s',models(k).file);
    model=surrogate.loadModel(models(k).file);
    assert(numel(model.trainingCaseIds)==trainingCases,'surrogate:final:TrainingCount', ...
        'Expected %d training IDs in model: %s',trainingCases,models(k).file);
end
config=studyConfigTemplate();
config.datasetFile=fullfile(dataDir,'test.mat');
config.datasetId="static-test-v1";
config.selectionRule="All 12 prespecified width/depth configurations and all seeds 42/43/44; no selection uses test results.";
config.freezeDescription=sprintf("Frozen %d-case model artifacts from 2026-11-05: POD rank 10, widths 64/128, hidden layers 1-6, Adam learning rate 0.001, 200 epochs, batch size 32. Evaluate saved models without retraining.",trainingCases);
if trainingCases==384
    config.testLabelHistory="The earlier protocol states that the original architecture comparison used validation data and had not performed a final test evaluation. The same test labels were subsequently evaluated on the frozen 768-case models on 2026-11-05; this 384-case evaluation is a paired retrospective comparison, not an independent test.";
else
    config.testLabelHistory="The earlier protocol states that the original architecture comparison used validation data and had not performed a final test evaluation. This test split was evaluated on the frozen 768-case models on 2026-11-05.";
end
config.metricConfig.staticReferenceFloor=0;
config.models=models;
result=runStaticFinalEvaluation(config,outputDir,false);
assert(numel(result.metadata.caseIds)==64,'surrogate:final:TestCount', ...
    'Expected the existing 64 static test cases.');
assert(all(result.summary.Status=="complete"),'surrogate:final:Incomplete', ...
    'One or more frozen models failed; inspect run_status.csv.');
end
