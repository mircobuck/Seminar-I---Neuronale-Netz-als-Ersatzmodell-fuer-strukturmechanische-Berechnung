function runModalWorkflowSmoke(configFile,localFile)
%runModalWorkflowSmoke EXPLICIT real FEM/full-phase smoke, never a default unit test.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setupProject;
out=runModalStudy("init",configFile,localFile);
runModalStudy("generate",configFile,localFile);
t=matlab.unittest.TestCase.forInteractiveUse;
t.assertError(@()runModalStudy("evaluate",configFile,localFile),'study:FreezeRequired');
runModalStudy("tune",configFile,localFile); runModalStudy("train",configFile,localFile);
files=dir(fullfile(out,'**','model.mat')); paths=string(fullfile({files.folder},{files.name}))';
before=modalstudy.manifest(paths); runModalStudy("train",configFile,localFile);
t.assertEqual(modalstudy.manifest(paths),before);
runModalStudy("freeze",configFile,localFile);
t.assertError(@()runModalStudy("train",configFile,localFile),'study:AlreadyFrozen');
runModalStudy("evaluate",configFile,localFile); runModalStudy("benchmark",configFile,localFile);
runModalStudy("report",configFile,localFile); runModalStudy("report",configFile,localFile);
rows=readtable(fullfile(out,'run_results.csv'),'TextType','string');
t.assertTrue(all(rows.Status=="ok")); modalstudy.checkFrozen(out);
t.assertEqual(modalstudy.manifest(paths),before);
writelines("Full real FEM and model smoke completed.",fullfile(out,'smoke.complete'));
end
