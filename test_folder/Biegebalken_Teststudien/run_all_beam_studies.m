function allStudies = run_all_beam_studies(studyIndices)
%RUN_ALL_BEAM_STUDIES Run selected reproducible neural-network beam studies.
%   RUN_ALL_BEAM_STUDIES runs all eight studies.
%   RUN_ALL_BEAM_STUDIES(4:8) runs only studies four through eight.
%   RUN_ALL_BEAM_STUDIES([1 3 7]) runs only the listed studies.

arguments
    studyIndices (1,:) {mustBeNumeric,mustBeInteger,mustBePositive,mustBeReal} = []
end

root = fileparts(mfilename('fullpath'));
cfg = makeConfig(root, 1:5, 1:15, 1:8, [80 160], 50, 100);
definitions = studyDefinitions(cfg);
if isempty(studyIndices)
    selectedIndices = 1:numel(definitions);
else
    if any(studyIndices > numel(definitions))
        error('run_all_beam_studies:InvalidStudyIndex', ...
            'Studienindex muss zwischen 1 und %d liegen.',numel(definitions));
    end
    selectedIndices = unique(studyIndices,'stable');
end

runId = datestr(now,'yyyymmdd_HHMMSS');
outRoot = fullfile(root,'results',['run_' runId]);
mkdir(outRoot);
writeRunInfo(cfg,outRoot,selectedIndices);

allStudies = struct([]);
for k = 1:numel(selectedIndices)
    index = selectedIndices(k);
    definition = definitions(index);
    fprintf('\n[%d/%d] %s\n',index,numel(definitions),definition.Name);
    studyDir = fullfile(outRoot,definition.Folder);
    mkdir(studyDir);
    current = runOneStudy(definition,cfg,studyDir);
    if k == 1, allStudies = current; else, allStudies(k) = current; end %#ok<AGROW>
end

allSummary = makeOverallSummary(allStudies);
writetable(allSummary,fullfile(outRoot,'overall_summary.csv'));
makeOverallPlots(allSummary,outRoot);
save(fullfile(outRoot,'all_studies.mat'),'allStudies','cfg','allSummary','-v7.3');
writePresentationData(allSummary,outRoot,root);
fprintf('\nFinished. Results: %s\n',outRoot);
end

function cfg = makeConfig(root,seeds,oneLayer,twoLayer,dataSizes,nVal,nTest)
cfg.Root = root;
cfg.Seeds = seeds;
cfg.OneLayer = oneLayer;
cfg.TwoLayer = twoLayer;
cfg.DataSizes = dataSizes;
cfg.NumValidationCases = nVal;
cfg.NumInterpolationCases = nTest;
cfg.TrainPositions = linspace(0,1,21)';
cfg.EvalPositions = [0; ((1:200)'-0.5)/200; 1];
cfg.PlotPositions = linspace(0,1,101)';
cfg.MaxIterations = 5000;
cfg.SuccessLimit = 0.01;
cfg.FigureVisible = 'off';
cfg.E = 210e9;
cfg.I1 = 8.333e-6;
cfg.LRange = [0.5 2.0];
cfg.FRange = [100 1000];
cfg.AlphaRange = [0.2 0.8];
cfg.HeightRatioRange = [0.6 1.5];
end

function defs = studyDefinitions(cfg)
defs = struct('Name',{},'Folder',{},'Geometry',{},'Layers',{},'TrainingCases',{});
geometries = {'constant','step'};
for g = 1:numel(geometries)
    for layerCount = 1:2
        for n = cfg.DataSizes
            geometry = geometries{g};
            defs(end+1) = struct( ... %#ok<AGROW>
                'Name',sprintf('%s, %d hidden layer(s), %d cases',geometry,layerCount,n), ...
                'Folder',sprintf('%s_%dlayer_%dcases',geometry,layerCount,n), ...
                'Geometry',geometry,'Layers',layerCount,'TrainingCases',n);
        end
    end
end
end

function result = runOneStudy(def,cfg,studyDir)
[Tr,Val,Int,Ext,plotSets,modelInfo] = buildDatasets(def,cfg);
architectures = architecturesFor(def,cfg);
nA = size(architectures,1); nS = numel(cfg.Seeds);
metrics = initMetrics(nS,nA,numel(Ext.Groups));
models = cell(nS,nA);

for a = 1:nA
    for s = 1:nS
        rng(cfg.Seeds(s),'twister');
        timer = tic;
        try
            net = trainNetwork(Tr,architectures(a,:),cfg);
            models{s,a} = net;
            metrics = recordMetrics(metrics,s,a,net,Val,Int,Ext,cfg,toc(timer));
        catch exception
            metrics.Failed(s,a) = true;
            metrics.ErrorMessage{s,a} = exception.message;
            metrics.Seconds(s,a) = toc(timer);
        end
    end
    fprintf('  %s complete\n',architectureLabel(architectures(a,:)));
end

[bestIndex,bestSeed] = selectModel(metrics.ValMax,cfg.Seeds);
rng(bestSeed,'twister');
best = trainNetwork(Tr,architectures(bestIndex,:),cfg,Val);
metrics = recordMetrics(metrics,find(cfg.Seeds==bestSeed,1),bestIndex,best,Val,Int,Ext,cfg,NaN);

summary = makeSummary(architectures,metrics,modelInfo,cfg);
writetable(summary,fullfile(studyDir,'summary.csv'));
writetable(makeRunTable(architectures,cfg.Seeds,metrics),fullfile(studyDir,'runs.csv'));
writeStudyReport(def,summary,bestIndex,bestSeed,studyDir,cfg);
plotMainFigure(def,architectures,metrics,best,bestIndex,plotSets,modelInfo,cfg,studyDir);
plotLossFigure(def,best,studyDir,cfg);
if def.Layers == 2
    plotHeatmaps(def,architectures,metrics,studyDir,cfg);
end

result = struct('Definition',def,'Architectures',architectures,'Metrics',metrics, ...
    'Summary',summary,'BestIndex',bestIndex,'BestSeed',bestSeed, ...
    'BestArchitecture',architectures(bestIndex,:),'ModelInfo',modelInfo);
save(fullfile(studyDir,'study.mat'),'result','architectures','metrics','models','summary','best','cfg','-v7.3');
end

function [Tr,Val,Int,Ext,plotSets,info] = buildDatasets(def,cfg)
rng(20261108,'twister');
if strcmp(def.Geometry,'constant')
    sampleCases = @(n) [randomIn(n,cfg.LRange) randomIn(n,cfg.FRange)];
    trainCases160 = sampleCases(max(cfg.DataSizes));
    trainCases = trainCases160(1:def.TrainingCases,:);
    valCases = sampleCases(cfg.NumValidationCases);
    intCases = [0.7 200; 1.1 600; 1.8 900; sampleCases(cfg.NumInterpolationCases-3)];
    extGroups = { ...
        [randomIn(25,[2 2.5]) randomIn(25,cfg.FRange)], ...
        [randomIn(25,cfg.LRange) randomIn(25,[1000 1500])], ...
        [randomIn(25,[2 2.5]) randomIn(25,[1000 1500])]};
    plotInt = intCases(1:3,:);
    plotExt = extGroups{3}(1,:);
    info = struct('InputNames',{{'x','L'}},'Geometry','constant', ...
        'OutputText','w/F','CaseColumns',{{'L','F'}});
else
    sampleCases = @(n) [randomIn(n,cfg.LRange) randomIn(n,cfg.AlphaRange) ...
        randomIn(n,cfg.HeightRatioRange) randomIn(n,cfg.FRange)];
    trainCases160 = sampleCases(max(cfg.DataSizes));
    trainCases = trainCases160(1:def.TrainingCases,:);
    valCases = sampleCases(cfg.NumValidationCases);
    intCases = [0.7 .5 1.3 200; 1.1 .3 .7 600; 1.8 .7 1.4 900; ...
        sampleCases(cfg.NumInterpolationCases-3)];
    extGroups = { ...
        [randomIn(20,[2 2.5]) randomIn(20,cfg.AlphaRange) randomIn(20,cfg.HeightRatioRange) randomIn(20,cfg.FRange)], ...
        [randomIn(20,cfg.LRange) randomIn(20,cfg.AlphaRange) randomIn(20,cfg.HeightRatioRange) randomIn(20,[1000 1500])], ...
        [randomIn(20,cfg.LRange) randomIn(20,[.05 .2]) randomIn(20,cfg.HeightRatioRange) randomIn(20,cfg.FRange)], ...
        [randomIn(20,cfg.LRange) randomIn(20,cfg.AlphaRange) randomIn(20,[.4 .6]) randomIn(20,cfg.FRange)], ...
        [randomIn(20,[2 2.5]) randomIn(20,[.05 .2]) randomIn(20,[.4 .6]) randomIn(20,[1000 1500])]};
    plotInt = intCases(1:3,:);
    plotExt = extGroups{5}(1,:);
    info = struct('InputNames',{{'x','L','a/L','h_2/h_1'}},'Geometry','step', ...
        'OutputText','w/F','CaseColumns',{{'L','a/L','h2/h1','F'}});
end
Tr = makeDataset(trainCases,cfg.TrainPositions,info,cfg);
Val = makeDataset(valCases,cfg.EvalPositions,info,cfg);
Int = makeDataset(intCases,cfg.EvalPositions,info,cfg);
Ext.Groups = cellfun(@(c) makeDataset(c,cfg.EvalPositions,info,cfg),extGroups,'UniformOutput',false);
Ext.All = concatenateDatasets(Ext.Groups);
plotSets = struct('Interpolation',makeDataset(plotInt,cfg.PlotPositions,info,cfg), ...
    'Extrapolation',makeDataset(plotExt,cfg.PlotPositions,info,cfg));
end

function v = randomIn(n,r), v = r(1) + diff(r)*rand(n,1); end

function S = makeDataset(cases,xi,info,cfg)
nCases = size(cases,1); S.Nx = numel(xi); S.Cases = cases;
S.L = kron(cases(:,1),ones(S.Nx,1)); S.F = kron(cases(:,end),ones(S.Nx,1));
S.xi = repmat(xi(:),nCases,1); S.x = S.xi.*S.L;
if strcmp(info.Geometry,'constant')
    S.y = constantDeflection(S.x,S.L,S.F,cfg);
    S.X = [normalise(S.x,[0 cfg.LRange(2)]), normalise(S.L,cfg.LRange)];
else
    S.Alpha = kron(cases(:,2),ones(S.Nx,1)); S.HRatio = kron(cases(:,3),ones(S.Nx,1));
    S.y = stepDeflection(S.x,S.L,S.F,S.Alpha,S.HRatio,cfg);
    S.X = [normalise(S.x,[0 cfg.LRange(2)]), normalise(S.L,cfg.LRange), ...
        normalise(S.Alpha,cfg.AlphaRange), normalise(S.HRatio,cfg.HeightRatioRange)];
end
tipPerCase = S.y(S.Nx:S.Nx:end);
S.tip = repelem(tipPerCase,S.Nx);
end

function S = concatenateDatasets(groups)
fields = fieldnames(groups{1});
for f = 1:numel(fields)
    value = groups{1}.(fields{f});
    if isnumeric(value) && ~isscalar(value)
        pieces = cellfun(@(g) g.(fields{f}),groups,'UniformOutput',false);
        S.(fields{f}) = vertcat(pieces{:});
    elseif isnumeric(value) && isscalar(value)
        S.(fields{f}) = value;
    end
end
end

function z = normalise(v,r), z = 2*(v-r(1))/diff(r)-1; end

function y = constantDeflection(x,L,F,cfg)
y = F.*x.^2.*(3.*L-x)/(6*cfg.E*cfg.I1);
end

function y = stepDeflection(x,L,F,alpha,hr,cfg)
a = alpha.*L; I2 = cfg.I1.*hr.^3;
y1 = F.*x.^2.*(3.*L-x)/(6*cfg.E*cfg.I1);
d = max(x-a,0);
g = (L-a).*d.^2/2-d.^3/6;
y2 = F.*a.^2.*(3.*L-a)/(6*cfg.E*cfg.I1) + ...
    F.*a.*(2.*L-a).*d/(2*cfg.E*cfg.I1) + F.*g./(cfg.E*I2);
y = y1; y(x>a) = y2(x>a);
end

function architectures = architecturesFor(def,cfg)
if def.Layers == 1
    architectures = cfg.OneLayer(:);
else
    [n1,n2] = ndgrid(cfg.TwoLayer,cfg.TwoLayer(1:min(7,end)));
    architectures = [n1(:) n2(:)];
    [~,order] = sortrows([sum(architectures,2) architectures],[1 2 3]);
    architectures = architectures(order,:);
end
end

function net = trainNetwork(Tr,layers,cfg,varargin)
wN = outputScale(cfg);
weights = wN./(Tr.tip./Tr.F);
args = {'LayerSizes',layers,'Activations','tanh','Lambda',0, ...
    'Standardize',false,'StandardizeResponses',false, ...
    'IterationLimit',cfg.MaxIterations,'GradientTolerance',1e-8, ...
    'LossTolerance',1e-10,'StepTolerance',1e-10,'Weights',weights};
if ~isempty(varargin)
    Va = varargin{1}; valWeights = wN./(Va.tip./Va.F);
    args = [args {'ValidationData',{Va.X,Va.y./Va.F/wN,valWeights}, ...
        'ValidationFrequency',1,'ValidationPatience',cfg.MaxIterations+1,'StoreHistory',true}];
end
net = fitrnet(Tr.X,Tr.y./Tr.F/wN,args{:});
end

function value = outputScale(cfg)
value = constantDeflection(cfg.LRange(2),cfg.LRange(2),1,cfg);
end

function metrics = initMetrics(nS,nA,nGroups)
metrics.ValMax = nan(nS,nA); metrics.IntMax = nan(nS,nA); metrics.ExtMax = nan(nS,nA);
metrics.ValL2 = nan(nS,nA); metrics.IntL2 = nan(nS,nA); metrics.ExtL2 = nan(nS,nA);
metrics.ExtGroupMax = nan(nS,nA,nGroups); metrics.Seconds = nan(nS,nA);
metrics.Failed = false(nS,nA); metrics.ErrorMessage = cell(nS,nA);
end

function metrics = recordMetrics(metrics,s,a,net,Val,Int,Ext,cfg,seconds)
metrics.ValMax(s,a) = maxRelativeError(net,Val,cfg); metrics.ValL2(s,a) = relativeL2(net,Val,cfg);
metrics.IntMax(s,a) = maxRelativeError(net,Int,cfg); metrics.IntL2(s,a) = relativeL2(net,Int,cfg);
metrics.ExtMax(s,a) = maxRelativeError(net,Ext.All,cfg); metrics.ExtL2(s,a) = relativeL2(net,Ext.All,cfg);
for g = 1:numel(Ext.Groups), metrics.ExtGroupMax(s,a,g) = maxRelativeError(net,Ext.Groups{g},cfg); end
if ~isnan(seconds), metrics.Seconds(s,a) = seconds; end
end

function y = predictDeflection(net,S,cfg), y = predict(net,S.X).*S.F*outputScale(cfg); end
function value = maxRelativeError(net,S,cfg), value = max(abs(predictDeflection(net,S,cfg)-S.y)./abs(S.tip)); end
function value = relativeL2(net,S,cfg), value = norm(predictDeflection(net,S,cfg)-S.y)/norm(S.y); end

function [index,seed] = selectModel(valErrors,seeds)
med = median(valErrors,1,'omitnan'); [~,index] = min(med);
[~,row] = min(valErrors(:,index)); seed = seeds(row);
end

function T = makeSummary(architectures,metrics,info,cfg)
n = size(architectures,1);
labels = strings(n,1); p = zeros(n,1);
for a=1:n, labels(a)=architectureLabel(architectures(a,:)); p(a)=parameterCount(architectures(a,:),numel(info.InputNames)); end
T = table(labels,architectures(:,1),'VariableNames',{'Architecture','Layer1'});
if size(architectures,2)>1, T.Layer2=architectures(:,2); else, T.Layer2=nan(n,1); end
T.TotalNeurons=sum(architectures,2); T.Parameters=p;
T.MedianValMax=median(metrics.ValMax,1,'omitnan')'; T.MedianInterpolationMax=median(metrics.IntMax,1,'omitnan')';
T.MedianExtrapolationMax=median(metrics.ExtMax,1,'omitnan')'; T.MedianValidationL2=median(metrics.ValL2,1,'omitnan')';
T.MedianInterpolationL2=median(metrics.IntL2,1,'omitnan')'; T.MedianExtrapolationL2=median(metrics.ExtL2,1,'omitnan')';
T.MedianSeconds=median(metrics.Seconds,1,'omitnan')'; T.SuccessRate=mean(metrics.IntMax < cfg.SuccessLimit,1,'omitnan')';
T.FailedRuns=sum(metrics.Failed,1)';
end

function T = makeRunTable(architectures,seeds,metrics)
[row,col] = ndgrid(1:numel(seeds),1:size(architectures,1));
seedColumn = reshape(seeds(row(:)),[],1);
labels = strings(numel(col),1);
for k=1:numel(col), labels(k)=architectureLabel(architectures(col(k),:)); end
T = table(seedColumn,labels, ...
    metrics.ValMax(:),metrics.IntMax(:),metrics.ExtMax(:),metrics.ValL2(:),metrics.IntL2(:),metrics.ExtL2(:),metrics.Seconds(:),metrics.Failed(:), ...
    'VariableNames',{'Seed','Architecture','ValidationMax','InterpolationMax','ExtrapolationMax','ValidationL2','InterpolationL2','ExtrapolationL2','Seconds','Failed'});
end

function text = architectureLabel(a)
if numel(a)==1, text=sprintf('%d',a); else, text=sprintf('[%d %d]',a(1),a(2)); end
end

function p = parameterCount(layers,nIn)
p=(nIn+1)*layers(1); for k=2:numel(layers), p=p+(layers(k-1)+1)*layers(k); end; p=p+layers(end)+1;
end

function plotMainFigure(def,architectures,metrics,best,bestIndex,plotSets,info,cfg,studyDir)
fig = figure('Visible',cfg.FigureVisible,'Color','w','Position',[50 50 1500 460]); tiledlayout(1,3,'Padding','compact');
nexttile; hold on; grid on; set(gca,'YScale','log');
[x,chosen] = plotArchitectureSelection(def,architectures,metrics);
plot(x,100*median(metrics.ValMax(:,chosen),1,'omitnan'),'-o','LineWidth',1.5,'DisplayName','Validierung');
plot(x,100*median(metrics.IntMax(:,chosen),1,'omitnan'),'-s','LineWidth',1.5,'DisplayName','Interpolation');
plot(x,100*median(metrics.ExtMax(:,chosen),1,'omitnan'),'-^','LineWidth',1.5,'DisplayName','Extrapolation');
yline(100*cfg.SuccessLimit,'--','1 %','HandleVisibility','off');
if def.Layers == 1, xlabel('Neuronen'); else, xlabel('Neuronen gesamt'); end
ylabel('Maximaler Fehler [% von w(L)]'); legend('Location','best');
title(sprintf('%s, %d Trainingsfaelle',def.Geometry,def.TrainingCases));
nexttile; hold on; grid on; plotBendingLines(best,plotSets,info,cfg);
nexttile; hold on; grid on; plotLocalErrors(best,plotSets,info,cfg);
exportFigure(fig,studyDir,'main_plot'); close(fig);
end

function [x,chosen] = plotArchitectureSelection(def,architectures,metrics)
if def.Layers==1, x=architectures(:,1)'; chosen=1:size(architectures,1); return; end
x=unique(sum(architectures,2))'; chosen=zeros(size(x));
for k=1:numel(x), idx=find(sum(architectures,2)==x(k)); [~,j]=min(median(metrics.ValMax(:,idx),1,'omitnan')); chosen(k)=idx(j); end
end

function plotBendingLines(net,plotSets,info,cfg)
plotLinesForSet(net,plotSets.Interpolation,info,cfg,lines(3));
plotLinesForSet(net,plotSets.Extrapolation,info,cfg,[0 0 0]);
set(gca,'YDir','reverse'); xlabel('x [m]'); ylabel('Durchbiegung [mm]'); title('Analytisch: durchgezogen, Netz: gestrichelt');
end

function plotLocalErrors(net,plotSets,info,cfg)
plotErrorsForSet(net,plotSets.Interpolation,info,cfg,lines(3));
plotErrorsForSet(net,plotSets.Extrapolation,info,cfg,[0 0 0]);
xlabel('x/L'); ylabel('Lokaler Fehler [% von w(L)]'); title('Drei Interpolationsfaelle, ein Extrapolationsfall');
end

function plotLinesForSet(net,S,info,cfg,colors)
yp = predictDeflection(net,S,cfg);
for c=1:size(S.Cases,1)
    idx=(c-1)*S.Nx+(1:S.Nx); color=colors(min(c,size(colors,1)),:); plot(S.x(idx),1000*S.y(idx),'-','Color',color,'LineWidth',1.8);
    plot(S.x(idx),1000*yp(idx),'--','Color',color,'LineWidth',1.2);
    if strcmp(info.Geometry,'step'), xline(S.Alpha(idx(1))*S.L(idx(1)),':','Color',color,'HandleVisibility','off'); end
end
end

function plotErrorsForSet(net,S,info,cfg,colors)
yp=predictDeflection(net,S,cfg);
for c=1:size(S.Cases,1)
    idx=(c-1)*S.Nx+(1:S.Nx); color=colors(min(c,size(colors,1)),:); plot(S.xi(idx),100*(yp(idx)-S.y(idx))./S.tip(idx),'Color',color,'LineWidth',1.3);
    if strcmp(info.Geometry,'step'), xline(S.Alpha(idx(1)),':','Color',color,'HandleVisibility','off'); end
end
end

function plotLossFigure(def,best,studyDir,cfg)
if ~isprop(best,'TrainingHistory') || isempty(best.TrainingHistory), return; end
h=best.TrainingHistory; fig=figure('Visible',cfg.FigureVisible,'Color','w','Position',[120 120 720 450]); hold on; grid on;
plot(h.Iteration,max(h.TrainingLoss,eps),'-','LineWidth',1.6,'DisplayName','Training'); plot(h.Iteration,max(h.ValidationLoss,eps),'--','LineWidth',1.6,'DisplayName','Validierung');
set(gca,'YScale','log'); xlabel('Iteration'); ylabel('Gewichteter MSE'); title(sprintf('Loss: %s, %d Trainingsfaelle',def.Geometry,def.TrainingCases)); legend('Location','best'); exportFigure(fig,studyDir,'loss'); close(fig);
end

function plotHeatmaps(def,architectures,metrics,studyDir,cfg)
fig=figure('Visible',cfg.FigureVisible,'Color','w','Position',[120 120 1300 400]); tiledlayout(1,3,'Padding','compact');
values={median(metrics.ValMax,1,'omitnan'),median(metrics.IntMax,1,'omitnan'),median(metrics.ExtMax,1,'omitnan')}; titles={'Validierung','Interpolation','Extrapolation'};
for q=1:3
    nexttile; M=nan(8,7); for a=1:size(architectures,1), M(architectures(a,1),architectures(a,2))=100*values{q}(a); end
    imagesc(M); set(gca,'YDir','normal'); colorbar; xlabel('Neuronen Layer 2'); ylabel('Neuronen Layer 1'); title([titles{q} ' [%]']);
end
sgtitle(sprintf('%s, zwei Layer, %d Trainingsfaelle',def.Geometry,def.TrainingCases)); exportFigure(fig,studyDir,'architecture_heatmaps'); close(fig);
end

function exportFigure(fig,folder,base)
exportgraphics(fig,fullfile(folder,[base '.png']),'Resolution',200); exportgraphics(fig,fullfile(folder,[base '.pdf']),'ContentType','vector'); savefig(fig,fullfile(folder,[base '.fig']));
end

function T = makeOverallSummary(studies)
T=table();
for k=1:numel(studies)
    S=studies(k); row=S.Summary(S.BestIndex,:); row.Geometry=string(S.Definition.Geometry); row.Layers=S.Definition.Layers; row.TrainingCases=S.Definition.TrainingCases; row.BestSeed=S.BestSeed; T=[T; row]; %#ok<AGROW>
end
T=movevars(T,{'Geometry','Layers','TrainingCases','BestSeed'},'Before',1);
end

function makeOverallPlots(T,outRoot)
fig=figure('Visible','off','Color','w','Position',[80 80 1100 650]); tiledlayout(2,2,'Padding','compact');
metrics={'MedianInterpolationMax','MedianExtrapolationMax','MedianSeconds','Parameters'}; labels={'Interpolation: Maximaler Fehler','Extrapolation: Maximaler Fehler','Median Trainingszeit [s]','Trainierbare Parameter'};
for q=1:4
    nexttile; groups=string(T.Geometry)+", "+string(T.Layers)+" Layer, "+string(T.TrainingCases)+" Faelle";
    b=bar(categorical(groups),T.(metrics{q})); grid on; xlabel('Studientyp'); ylabel(labels{q});
    xtickangle(25); text(b.XEndPoints,b.YEndPoints,string(T.TrainingCases),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',9);
end
sgtitle('Vergleich der ausgewaehlten Modelle: Beschriftung = Trainingsfaelle'); exportFigure(fig,outRoot,'overall_comparison'); close(fig);
end

function writeStudyReport(def,T,bestIndex,bestSeed,folder,cfg)
f=fopen(fullfile(folder,'REPORT.md'),'w'); cleaner=onCleanup(@() fclose(f)); %#ok<NASGU>
fprintf(f,'# %s\n\n',def.Name); fprintf(f,'Auswahl erfolgte nur ueber den Median des Validierungs-Maximalfehlers.\n\n');
fprintf(f,'Ausgewaehlte Architektur: **%s**, Seed **%d**.\n\n',T.Architecture(bestIndex),bestSeed);
fprintf(f,'Maximaler Interpolationsfehler: **%.4g %%**.  Maximaler Extrapolationsfehler: **%.4g %%**.\n\n',100*T.MedianInterpolationMax(bestIndex),100*T.MedianExtrapolationMax(bestIndex));
fprintf(f,'Das 1-%%-Kriterium betrifft den maximalen Fehler, normiert mit der analytischen Enddurchbiegung.\n');
end

function writeRunInfo(cfg,outRoot,selectedIndices)
f=fopen(fullfile(outRoot,'README.md'),'w'); cleaner=onCleanup(@() fclose(f)); %#ok<NASGU>
fprintf(f,'# Biegebalken-Teststudien\n\n'); fprintf(f,'Ausgefuehrte Studien: %s. Seeds: %s.\n\n',mat2str(selectedIndices),mat2str(cfg.Seeds));
fprintf(f,'Die Studiennummern sind: 1 konstant/1 Layer/80, 2 konstant/1 Layer/160, 3 konstant/2 Layer/80, 4 konstant/2 Layer/160, 5 Sprung/1 Layer/80, 6 Sprung/1 Layer/160, 7 Sprung/2 Layer/80, 8 Sprung/2 Layer/160.\n');
end

function writePresentationData(T,outRoot,root)
f=fopen(fullfile(root,'vortrag','results_path.tex'),'w');
relative=strrep(outRoot,root,'..'); relative=strrep(relative,'\','/'); fprintf(f,'\newcommand{\ResultsPath}{%s}\n',relative); fclose(f);
f=fopen(fullfile(root,'vortrag','study_summary.tex'),'w');
for k=1:height(T), fprintf(f,'%s & %d & %d & %.3g\\%% & %.3g\\%% \\\\ \n',T.Geometry(k),T.Layers(k),T.TrainingCases(k),100*T.MedianInterpolationMax(k),100*T.MedianExtrapolationMax(k)); end
fclose(f);
end

