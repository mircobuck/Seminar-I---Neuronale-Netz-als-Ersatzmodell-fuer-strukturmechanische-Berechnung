function studyDir=run_training_size_study(stage,studyDir)
%run_training_size_study - Run the nested training-size experiment
%   STUDYDIR = run_training_size_study(STAGE) prepares or resumes the
%   12/24/48-case study. STAGE is "prepare", "generate24", "train24",
%   "evaluate24", "generate48", "train48", "evaluate48", or "summarize".
%
%   STUDYDIR = run_training_size_study(STAGE,STUDYDIR) uses the specified
%   experiment directory. Existing model files are never overwritten.
%
%   See also generate_dataset, train_models, evaluate_models

root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'src'));
if nargin<1, stage="prepare"; end
if nargin<2
    studyDir=fullfile(root,'experiments','training_size_12_24_48_20261023');
end
studyDir=string(studyDir); stage=string(stage);
if stage=="prepare"
    prepareStudy(root,studyDir);
    return;
end
assert(isfile(fullfile(studyDir,'protocol.mat')),'Prepare the study first.');
protocol=load(fullfile(studyDir,'protocol.mat'));
switch stage
    case {"generate24","train24","evaluate24"}
        c=protocol.c24;
    case {"generate48","train48","evaluate48"}
        c=protocol.c48;
    case "summarize"
        summarizeStudy(studyDir);
        return;
    otherwise
        error('Unknown study stage: %s',stage);
end
if startsWith(stage,"generate")
    assert(~isfile(fullfile(c.out,'models.mat')), ...
        'Models already frozen: do not regenerate this dataset.');
    if stage=="generate48"
        copyCases(protocol.c24.out,c.out);
    end
    action=@()generate_dataset(c);
elseif startsWith(stage,"train")
    assert(~isfile(fullfile(c.out,'models.mat')), ...
        'Models already frozen: refusing to overwrite.');
    verifyData(c,protocol.baseline);
    action=@()train_models(c);
else
    verifyData(c,protocol.baseline);
    assert(~isfile(fullfile(c.out,'test_summary.csv')), ...
        'Evaluation already exists: preserve the recorded results.');
    action=@()evaluate_models(c);
end
runLogged(action,stage,studyDir);
if startsWith(stage,"generate"), verifyData(c,protocol.baseline); end
end

function prepareStudy(root,studyDir)
assert(~isfolder(studyDir),'Study already exists. Resume a specific stage.');
baseline=fullfile(root,'runs','smoke');
assert(isfile(fullfile(baseline,'models.mat')),'Smoke baseline is required.');
base=load(fullfile(baseline,'models.mat'),'meta');
c0=base.meta.config;
assert(isequal(c0.counts,[12 6 6]),'Unexpected baseline split sizes.');
assert(strcmp(base.meta.MATLAB,version),'MATLAB version differs from baseline.');
assert(isfile(fullfile(baseline,'test_summary.csv')));
T=readtable(c0.design,TextType="string");
assert(height(T)==24 && nnz(T.split=="train")==12);
assert(numel(unique(T.id))==24 && size(unique(T{:,c0.names},'rows'),1)==24);
mkdir(studyDir); mkdir(fullfile(studyDir,'logs'));
copyfile(baseline,fullfile(studyDir,'n12'));
copyfile(c0.design,fullfile(studyDir,'baseline_design.csv'));
snapshot=fullfile(studyDir,'source_snapshot'); mkdir(snapshot);
copyfile(fullfile(root,'src'),fullfile(snapshot,'src'));
copyfile(fullfile(root,'tests'),fullfile(snapshot,'tests'));
sourceFiles=dir(fullfile(root,'*.m'));
for i=1:numel(sourceFiles)
    copyfile(fullfile(root,sourceFiles(i).name),snapshot);
end
copyfile(fullfile(root,'README.md'),snapshot);
copyfile(fullfile(root,'CHECKS.md'),snapshot);
designSeed=20261023; rng(designSeed,'twister');
U=zeros(36,6);
for j=1:6, U(:,j)=(randperm(36)'-rand(36,1))/36; end
X=c0.lower+U.*(c0.upper-c0.lower);
extra=array2table(X,'VariableNames',c0.names);
extra=addvars(extra,(max(T.id)+(1:36))',repmat("train",36,1), ...
    'Before',1,'NewVariableNames',{'id','split'});
assert(size(unique([T{:,c0.names};X],'rows'),1)==60);
assert(all(X>=c0.lower & X<=c0.upper,'all'));
writeDesign(extra,fullfile(studyDir,'additional_training_design.csv'),c0.names);
source=repmat("new_FEM",60,1);
source(1:24)="original_smoke";
provenance=table([T.id;extra.id],source, ...
    'VariableNames',{'CaseID','Source'});
writetable(provenance,fullfile(studyDir,'case_provenance.csv'));
frozenRanks=unique(min(c0.ranks,11));
configs=cell(1,2);
for k=1:2
    n=[24 48]; count=n(k);
    c=c0; c.root=root; c.mode="training_size_n"+count;
    c.counts=[count 6 6]; c.ranks=frozenRanks;
    c.additionalDesignSeed=designSeed;
    c.out=fullfile(studyDir,"n"+count);
    c.design=fullfile(studyDir,"design_n"+count+".csv");
    train=[T(T.split=="train",:);extra(1:count-12,:)];
    design=[train;T(T.split~="train",:)];
    assert(height(train)==count && height(design)==count+12);
    assert(numel(unique(design.id))==height(design));
    writeDesign(design,c.design,c0.names);
    mkdir(c.out); copyCases(baseline,c.out);
    configs{k}=c;
end
c24=configs{1}; c48=configs{2};
baseline=fullfile(studyDir,'n12');
save(fullfile(studyDir,'protocol.mat'), ...
    'c0','c24','c48','designSeed','frozenRanks','baseline');
plan=["# Training-size experiment: 12 -> 24 -> 48"; ""; ...
    "Protocol fixed before new FEM solves or model training."; ...
    "Only the training set is extended. No pilot stage is run."; ...
    "Original smoke artifacts are copied to n12 without retraining."; ...
    "Validation IDs 13-18 and test IDs 19-24 stay fixed, with identical FEM values."; ...
    "Nested training: n12 IDs 1-12; n24 adds 25-36; n48 adds 37-60."; ...
    "New points: 36 randomized Latin-hypercube points, 6 inputs, seed 20261023 (twister)."; ...
    "Each coordinate uses an independent random permutation and uniform jitter."; ...
    "The first 12 added points are the predetermined n24 extension."; ...
    "The combined 24/48-point designs are nested, not newly optimized LHS designs."; ...
    "Original parameter bounds, physics, mesh, reference grid and guards are unchanged."; ...
    "Effective POD candidate ranks fixed to [2 4 8 11] for all sample sizes."; ...
    "RBF lambdas, MLP widths/epochs/minibatch/early stopping, GP kernel and seed 42 unchanged."; ...
    "Scaling, POD and regressors are fitted separately on each training subset."; ...
    "Rank and regression hyperparameters are selected on the same validation cases."; ...
    "MLP minibatch size remains 16: more samples imply more optimizer steps per epoch."; ...
    "One model seed per size. This is a descriptive learning-curve experiment."; ...
    "Six test cases give little statistical precision; P95 equals max here."; ...
    "The test set was already inspected in the baseline. It is a comparison set, not a new blind holdout."; ...
    "No choices in this series are made from new test errors."; ...
    "Existing models are never overwritten. Source snapshot and per-stage output are retained."; ...
    "There are 36 new physical FEM cases in total; n48 reuses all n24 cases."; ...
    "Resume with run_training_size_study(stage,studyDir)."; ...
    "Stages: generate24, train24, evaluate24, generate48, train48, evaluate48, summarize." ];
writelines(plan,fullfile(studyDir,'PLAN.md'));
fprintf('Prepared study: %s\n',studyDir);
fprintf('Frozen POD ranks: '); disp(frozenRanks);
end

function writeDesign(T,file,names)
% Preserve every input double across CSV export and subsequent import.
rows=compose('%.17g',T.id)+","+T.split;
for name=string(names)
    rows=rows+","+compose('%.17g',T.(name));
end
writelines([strjoin(string(T.Properties.VariableNames),",");rows],file);
restored=readtable(file,TextType="string");
assert(isequaln(T,restored),'CSV numeric round-trip changed the design.');
end

function copyCases(from,to)
files=dir(fullfile(from,'cases','case_*.mat'));
caseDir=fullfile(to,'cases');
if ~isfolder(caseDir), mkdir(caseDir); end
for i=1:numel(files)
    dest=fullfile(caseDir,files(i).name);
    if ~isfile(dest), copyfile(fullfile(files(i).folder,files(i).name),dest); end
end
end

function verifyData(c,baseline)
ids=cell(1,3); labels=["train","val","test"];
for i=1:3
    a=load(fullfile(c.out,labels(i)+'.mat'),'D'); D=a.D;
    assert(numel(D.id)==c.counts(i)); ids{i}=D.id;
    assert(isequal(size(D.X),[c.counts(i) 6]));
    assert(isequal(size(D.S),[1575 c.counts(i)]));
    assert(all(isfinite(D.S),'all') && all(isfinite(D.Y),'all'));
    b=load(fullfile(baseline,labels(i)+'.mat'),'D');
    if i==1
        assert(isequal(D.id(1:12),b.D.id));
        assert(isequal(D.X(1:12,:),b.D.X) && isequal(D.S(:,1:12),b.D.S));
        assert(isequal(D.Y(1:12,:),b.D.Y));
    else
        assert(isequaln(D,b.D),'Held-out data changed.');
    end
    assert(isequaln(D.physics,b.D.physics));
end
assert(numel(unique(vertcat(ids{:})))==sum(c.counts),'Split leakage.');
fprintf('Verified n=%d: nested original training data; identical val/test.\n',c.counts(1));
end

function runLogged(action,stage,studyDir)
assert(isa(action,'function_handle'));
started=string(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
t=tic; failure=[];
captured=evalc('try; action(); catch cause; failure=cause; fprintf(''%s\n'',getReport(cause,''extended'',''hyperlinks'',''off'')); end');
elapsed=toc(t); ended=string(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
stamp=string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
logFile=fullfile(studyDir,'logs',stage+"_"+stamp+".txt");
writelines(["Started: "+started;"Ended: "+ended; ...
    "Elapsed seconds: "+elapsed;"Succeeded: "+isempty(failure); ...
    "";string(captured)],logFile);
event=table(stage,started,ended,elapsed,isempty(failure),string(logFile), ...
    'VariableNames',{'Stage','Started','Ended','Seconds','Succeeded','LogFile'});
eventFile=fullfile(studyDir,'events.csv');
if isfile(eventFile), previous=readtable(eventFile,TextType="string"); event=[previous;event]; end
writetable(event,eventFile);
fprintf('%s',captured);
fprintf('%s: %.3f seconds; log %s\n',stage,elapsed,logFile);
if ~isempty(failure), rethrow(failure); end
end

function summarizeStudy(studyDir)
summary=table(); perCase=table(); selected=table();
for n=[12 24 48]
    folder=fullfile(studyDir,"n"+n);
    T=readtable(fullfile(folder,'test_summary.csv'),TextType="string");
    T=addvars(T,repmat(n,height(T),1),'Before',1,'NewVariableNames','TrainingCases');
    P=readtable(fullfile(folder,'test_per_case.csv'),TextType="string");
    P=addvars(P,repmat(n,height(P),1),'Before',1,'NewVariableNames','TrainingCases');
    a=load(fullfile(folder,'models.mat'),'models');
    for k=1:numel(a.models)
        M=a.models{k}; rank=NaN; hp=NaN; score=NaN;
        if M.type=="field"
            rank=M.pod.r; score=M.validationScore;
            if M.reg.kind=="rbf", hp=M.reg.lambda; end
            if M.reg.kind=="mlp", hp=M.reg.width; end
        end
        row=table(n,M.name,rank,hp,score,'VariableNames', ...
            {'TrainingCases','Model','PODRank','Hyperparameter','ValidationMeanRelativeL2'});
        if isempty(selected), selected=row; else, selected=[selected;row]; end
    end
    if isempty(summary), summary=T; perCase=P;
    else, summary=[summary;T]; perCase=[perCase;P]; end
end
writetable(summary,fullfile(studyDir,'comparison.csv'));
writetable(perCase,fullfile(studyDir,'case_errors.csv'));
writetable(selected,fullfile(studyDir,'selected_models.csv'));
F=summary(~isnan(summary.FieldMedianRelL2),:);
disp(F(:,{'TrainingCases','Model','FieldMedianRelL2','FieldWorstRelL2'}));
fig=figure('Position',[100 100 1200 600]);
tiledlayout(1,2);
nexttile; hold on;
names=unique(F.Model,'stable');
for name=names'
    z=F(F.Model==name,:);
    semilogy(z.TrainingCases,100*z.FieldMedianRelL2,'-o','DisplayName',name);
end
set(gca,'YScale','log'); grid on; xticks([12 24 48]);
xlabel('Training cases'); ylabel('Median relative field L2 error [%]');
legend('Location','best','Interpreter','none');
nexttile; hold on;
for name=names'
    z=F(F.Model==name,:);
    semilogy(z.TrainingCases,100*z.FieldWorstRelL2,'-o','DisplayName',name);
end
set(gca,'YScale','log'); grid on; xticks([12 24 48]);
xlabel('Training cases'); ylabel('Worst relative field L2 error [%]');
legend('Location','best','Interpreter','none');
drawnow; exportgraphics(fig,fullfile(studyDir,'learning_curve.png'),Resolution=150);
end
