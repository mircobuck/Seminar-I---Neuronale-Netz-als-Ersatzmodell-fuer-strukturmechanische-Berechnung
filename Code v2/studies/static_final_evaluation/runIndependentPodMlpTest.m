function result = runIndependentPodMlpTest(outputRoot)
%runIndependentPodMlpTest Generate fresh static FEM cases and test frozen POD-MLPs.
%   Evaluates all 36 saved 768-case POD-MLP models on 64 new Latin-hypercube
%   cases. Model selection and artifact hashes are recorded before FEM labels
%   are generated. OUTPUTROOT must not already exist.
if nargin<1
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    outputRoot=fullfile(root,'experiments','pod_mlp_independent_test_20261106');
end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
studyRoot=fullfile(root,'studies','static_final_evaluation');
addpath(root,studyRoot,fullfile(root,'scripts','matlab'));
assert(~isfolder(outputRoot) && ~isfile(outputRoot), ...
    'surrogate:independentTest:Exists','Output path already exists: %s',outputRoot);

dataDir=fullfile(root,'experiments','static_768_20261105');
widths=[64 128]; layers=1:6; seeds=[42 43 44];
models=repmat(struct('label',"",'file',""),numel(widths)*numel(layers)*numel(seeds),1);
modelHashes=strings(numel(models),1);
k=0;
for width=widths
    for layer=layers
        for seed=seeds
            k=k+1;
            file=fullfile(dataDir,sprintf('width_%d_layers_%d',width,layer), ...
                sprintf('pod_mlp_adam_%d_n768_seed%d.mat',width,seed));
            assert(isfile(file),'surrogate:independentTest:ModelMissing', ...
                'Missing frozen model: %s',file);
            model=surrogate.loadModel(file);
            assert(numel(model.trainingCaseIds)==768, ...
                'surrogate:independentTest:TrainingCount', ...
                'Expected a 768-case model: %s',file);
            models(k)=struct('label',sprintf( ...
                "POD_MLP_ADAM_%d_NEURONS_%d_LAYERS_SEED%d",width,layer,seed), ...
                'file',string(file));
            modelHashes(k)=sha256File(file);
        end
    end
end

if ~isfolder(outputRoot), mkdir(outputRoot); end
referenceRoot=fullfile(outputRoot,'reference_data');
evaluationRoot=fullfile(outputRoot,'evaluation');
freezePath=fullfile(outputRoot,'model_freeze.txt');
selection="All 12 prespecified width/depth configurations and seeds 42/43/44; no selection or tuning uses the fresh test labels.";
freezeText="Created before generating fresh test labels."+newline+ ...
    "Models: frozen 768-case POD-MLP artifacts; widths 64/128, hidden layers 1:6, seeds 42/43/44."+newline+ ...
    "Selection: "+selection+newline+ ...
    "Test design: 64 new static Latin-hypercube cases, seed 20261106, parameter bounds from data_generation_v1.json."+newline+ ...
    "Prior-label history: the original static test split was previously evaluated and read for analytical FEM validation; this run generates new FEM labels."+newline+ ...
    "SHA-256 model artifacts (in model list order):"+newline;
for i=1:numel(models)
    freezeText=freezeText+models(i).label+" "+modelHashes(i)+newline;
end
writeText(freezePath,freezeText);

cfgPath=fullfile(outputRoot,'fresh_test_data_config.json');
cfg=jsondecode(fileread(fullfile(root,'data_generation','configs','data_generation_v1.json')));
cfg.seed=20261106;
cfg.static.idStart=811001;
cfg.static.counts.train=0;
cfg.static.counts.val=0;
cfg.static.counts.test=64;
writeText(cfgPath,string(jsonencode(cfg)));

run_data_generation_v2("design",cfgPath,referenceRoot);
freshDesign=readtable(fullfile(referenceRoot,'static','design.csv'),'TextType','string');
oldDesign=readtable(fullfile(root,'data_generation','data','static','design.csv'), ...
    'TextType','string');
assert(height(freshDesign)==64 && all(freshDesign.split=="test") && ...
    numel(unique(freshDesign.id))==64, ...
    'surrogate:independentTest:Design','Fresh design is not 64 unique test cases.');
parameterNames=setdiff(freshDesign.Properties.VariableNames,{'id','split'},'stable');
assert(isempty(intersect(freshDesign.id,oldDesign.id)) && ...
    ~any(ismember(freshDesign{:,parameterNames},oldDesign{:,parameterNames},'rows')), ...
    'surrogate:independentTest:Overlap','Fresh test design overlaps the existing design.');
fprintf('Frozen %d models; generating fresh FEM labels for 64 cases.\n',numel(models));
run_data_generation_v2("static_test",cfgPath,referenceRoot);

config=studyConfigTemplate();
config.datasetFile=fullfile(referenceRoot,'static','test.mat');
config.datasetId="static-independent-lhs-v1-seed20261106-n64";
config.selectionRule=selection;
config.freezeDescription="Frozen 768-case artifacts; SHA-256 hashes recorded in model_freeze.txt before fresh test FEM labels were generated.";
config.testLabelHistory="The previous static test labels were already evaluated and read for analytical FEM validation. The 64 cases in this evaluation have new IDs and a fresh Latin-hypercube design; their FEM labels were generated only after the model freeze.";
config.metricConfig.staticReferenceFloor=0;
config.models=models;
result=runStaticFinalEvaluation(config,evaluationRoot,false);
assert(numel(result.metadata.caseIds)==64 && all(result.summary.Status=="complete"), ...
    'surrogate:independentTest:Incomplete', ...
    'Independent evaluation incomplete; inspect evaluation/run_status.csv.');
end

function hash=sha256File(file)
fid=fopen(file,'rb');
assert(fid>=0,'surrogate:independentTest:HashRead','Cannot open model: %s',file);
cleanup=onCleanup(@()fclose(fid));
bytes=fread(fid,Inf,'*uint8');
digest=java.security.MessageDigest.getInstance('SHA-256');
digest.update(typecast(bytes,'int8'));
hash=lower(string(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[])));
clear cleanup
end

function writeText(file,text)
fid=fopen(file,'w');
assert(fid>=0,'surrogate:independentTest:Write','Cannot write file: %s',file);
cleanup=onCleanup(@()fclose(fid));
fwrite(fid,char(text),'char');
clear cleanup
end
