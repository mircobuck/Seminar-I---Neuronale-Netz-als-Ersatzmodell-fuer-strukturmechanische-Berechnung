function runStaticWorkflowSmoke(configFile,localFile)
%runStaticWorkflowSmoke Integration assertions across the actual public phases.
root=fileparts(fileparts(mfilename('fullpath')));
previousPath=path;
cleanup=onCleanup(@()path(previousPath)); %#ok<NASGU>
addpath(root,fullfile(root,'workflows','static_comparison'));
cfg=staticstudy.configure(root,configFile,localFile);
out=runStaticStudy("init",configFile,localFile);
runStaticStudy("generate",configFile,localFile);
testCase=matlab.unittest.TestCase.forInteractiveUse;
testCase.assertError(@()runStaticStudy("evaluate",configFile,localFile),'study:FreezeRequired');
runStaticStudy("tune",configFile,localFile);
runStaticStudy("train",configFile,localFile);
before=checkpointHashes(out);
runStaticStudy("train",configFile,localFile);
testCase.assertEqual(checkpointHashes(out),before);
runStaticStudy("freeze",configFile,localFile);
testCase.assertError(@()runStaticStudy("tune",configFile,localFile),'study:AlreadyFrozen');
testCase.assertError(@()runStaticStudy("train",configFile,localFile),'study:AlreadyFrozen');
runStaticStudy("evaluate",configFile,localFile);
runStaticStudy("benchmark",configFile,localFile);
before=checkpointHashes(out);
runStaticStudy("report",configFile,localFile);
runStaticStudy("report",configFile,localFile);
testCase.assertEqual(checkpointHashes(out),before);
rows=readtable(fullfile(out,'run_results.csv'),'TextType','string');
testCase.assertTrue(all(rows.status=="ok"));
testCase.assertEqual(sort(unique(rows.method)),sort(string(cfg.methods(:))));
testCase.assertEqual(sort(unique(rows.role)),["extrapolation";"interpolation"]);
% A frozen metadata change must fail even before test labels are opened.
marker=fullfile(out,'training.complete');
bytes=fileread(marker);
restore=onCleanup(@()restoreText(marker,bytes));
writelines("modified for negative freeze test",marker);
testCase.assertError(@()staticstudy.reference(out,"evaluate","interpolation"),'study:FreezeChanged');
clear restore
staticstudy.checkFrozen(out);
writelines("All four methods, FEM generation, resume, report-only and freeze gates passed.", ...
    fullfile(out,'smoke_validation.complete'));
end

function manifest=checkpointHashes(out)
files=dir(fullfile(out,'**','model.mat'));
paths=string(fullfile({files.folder},{files.name}))';
hashes=strings(size(paths));
for k=1:numel(paths), hashes(k)=string(staticstudy.hash(paths(k))); end
manifest=table(paths,hashes);
end

function restoreText(file,text)
fid=fopen(file,'wb');
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fwrite(fid,unicode2native(text,'UTF-8'),'uint8');
end
