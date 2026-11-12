function export_metadata
here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
main=fullfile(root,'experiments','static_gpr_main_v1_20261111_run2');
methods={'mlp','rbf','pod_mlp','pod_gpr'}; a=load(fullfile(main,'selections.mat'),'selections');
output=struct; output.selections=a.selections;
for j=1:4
    f=fullfile(main,'runs',sprintf('n768_rep1_%s_seed42',methods{j}),'result.mat');
    b=load(f,'result'); output.main.(methods{j})=struct('config',b.result.config, ...
        'trainingFingerprint',b.result.trainingFingerprint,'trainingIds',b.result.trainingIds, ...
        'validationFingerprint',b.result.validationFingerprint,'fitSeconds',b.result.fitSeconds);
end
mainGpr=output.main.pod_gpr;
for j=2:3
    f=fullfile(main,'timing_repeats',sprintf('n768_pod_gpr_repeat%d',j),'result.mat');
    b=load(f,'result'); assert(isequaln(b.result.config,mainGpr.config));
    assert(isequal(b.result.trainingIds,mainGpr.trainingIds));
    assert(strcmp(b.result.trainingFingerprint,mainGpr.trainingFingerprint));
    assert(strcmp(b.result.validationFingerprint,mainGpr.validationFingerprint));
    output.gprRepeats(j-1)=b.result.fitSeconds;
end
output.gprTimingScope='Each outer fitSeconds measures public surrogate.fitModel; excludes save and validation prediction.';
fid=fopen(fullfile(here,'metadata.json'),'w'); fwrite(fid,jsonencode(output,'PrettyPrint',true),'char'); fclose(fid);
b=load(fullfile(here,'benchmark_results.mat')); femMedians=median(b.femTimes,2); rows=table;
for m=1:4
    individual=median(b.single(:,:,m),2);
    rows=[rows;table(b.methods(m),median(femMedians),iqr(femMedians),median(individual),iqr(individual), ...
        median(b.batch(:,m)),iqr(b.batch(:,m)),sum(femMedians),b.loadTimes(m), ...
        'VariableNames',{'method','femSingleMedian','femBetweenCaseIQR','surrogateSingleMedian', ...
        'surrogateBetweenCaseIQR','surrogateBatch12Median','surrogateBatch12IQR','femSerial12Sum','modelLoad'})]; %#ok<AGROW>
end
writetable(rows,fullfile(here,'benchmark_summary.csv'));
rows=table;
for j=1:numel(b.ids)
    for k=1:2
        rows=[rows;table(b.ids(j),k,b.femTimes(j,k),b.femInternal(j,k), ...
            'VariableNames',{'caseId','repeat','wallSeconds','solveCaseSeconds'})]; %#ok<AGROW>
    end
end
writetable(rows,fullfile(here,'benchmark_fem_raw.csv'));
rows=table;
for m=1:4
    for k=1:30
        for j=1:numel(b.ids)
            rows=[rows;table(b.methods(m),b.ids(j),k,"single",b.single(j,k,m), ...
                'VariableNames',{'method','caseId','repeat','kind','seconds'})]; %#ok<AGROW>
        end
        rows=[rows;table(b.methods(m),NaN,k,"batch12",b.batch(k,m), ...
            'VariableNames',{'method','caseId','repeat','kind','seconds'})]; %#ok<AGROW>
    end
end
writetable(rows,fullfile(here,'benchmark_surrogate_raw.csv'));
end
