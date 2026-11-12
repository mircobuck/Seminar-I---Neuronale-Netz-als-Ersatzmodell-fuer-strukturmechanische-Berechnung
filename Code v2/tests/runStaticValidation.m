function results = runStaticValidation(outputDirectory,smokeLocalFile)
%runStaticValidation Check dependencies, tests and FEM smoke on a clean MATLAB path.
arguments
    outputDirectory (1,1) string
    smokeLocalFile (1,1) string = "workflows/static_comparison/configs/smoke.local.json"
end
root=fileparts(fileparts(mfilename('fullpath')));
previousPath=path;
cleanup=onCleanup(@()path(previousPath)); %#ok<NASGU>
entries=string(strsplit(path,pathsep));
path(char(strjoin(entries(startsWith(entries,string(matlabroot))),pathsep)));
addpath(root,fullfile(root,'tests'),fullfile(root,'workflows','static_comparison'), ...
    fullfile(root,'fem_core'),fullfile(root,'fem_core','src'));
out=char(java.io.File(fullfile(root,outputDirectory)).getCanonicalPath());
assert(~isfolder(out),'study:ValidationOutput','Use a new validation output directory.');
mkdir(out);
roots={fullfile(root,'runStaticStudy.m'),fullfile(root,'examples','trainStaticModelExample.m'), ...
    fullfile(root,'examples','showStaticResultsExample.m')};
for method=["mlp","rbf","pod_mlp","pod_gpr"]
    for operation=["fit","predict"]
        file=which("surrogate.models."+method+"."+operation);
        assert(startsWith(string(file),string(root)),'study:Dependency','Wrong model implementation resolved.');
        roots{end+1}=file; %#ok<AGROW>
    end
end
[dependencies,products]=matlab.codetools.requiredFilesAndProducts(roots);
dependencies=string(dependencies(:));
dependencies=dependencies(startsWith(dependencies,string(root)));
writetable(table(dependencies,'VariableNames',{'Path'}),fullfile(out,'dependencies.csv'));
metadata=struct('matlab',version,'products',{products},'path',string(path));
writelines(jsonencode(metadata,PrettyPrint=true),fullfile(out,'environment.json'));
files=dependencies;
for folder=["+surrogate","fem_core","workflows/static_comparison","tests","examples"]
    found=dir(fullfile(root,folder,'**','*.m'));
    files=[files;string(fullfile({found.folder},{found.name}))']; %#ok<AGROW>
end
files=unique(files);
analysis=table('Size',[0 3],'VariableTypes',{'string','double','string'}, ...
    'VariableNames',{'File','Line','Message'});
for file=files(:)'
    messages=checkcode(file,'-id');
    for k=1:numel(messages)
        analysis=[analysis;table(file,double(messages(k).line),string(messages(k).message), ...
            'VariableNames',analysis.Properties.VariableNames)]; %#ok<AGROW>
    end
end
writetable(analysis,fullfile(out,'code_analysis.csv'));
assert(~any(contains(lower(analysis.Message),'parse error')),'study:Syntax','Resolve MATLAB parse errors first.');
results=runtests(fullfile(root,'tests'));
summary=table(string({results.Name})',[results.Passed]',[results.Failed]', ...
    [results.Incomplete]',[results.Duration]', ...
    'VariableNames',{'Name','Passed','Failed','Incomplete','Duration'});
writetable(summary,fullfile(out,'unit_results.csv'));
save(fullfile(out,'unit_results.mat'),'results');
assertSuccess(results);
runStaticWorkflowSmoke("workflows/static_comparison/configs/smoke.json",smokeLocalFile);
loaded=string(inmem('-completenames'));
loaded=loaded(startsWith(loaded,string(root)));
allowed=string(fullfile(root,{'+surrogate','fem_core','workflows','tests','examples'}));
allowedRoots=string(fullfile(root,{'runStaticStudy.m','setupProject.m','loadFemDataset.m'}));
for file=loaded(:)'
    assert(any(startsWith(file,allowed)) || any(file==allowedRoots), ...
        'study:HistoricalDependency','Unexpected project code loaded: %s',file);
end
writetable(table(loaded(:),'VariableNames',{'Path'}),fullfile(out,'loaded_project_functions.csv'));
writelines("All current tests and full FEM smoke passed on a MATLAB-only initial path.", ...
    fullfile(out,'validation.complete'));
fprintf('VALIDATION_COMPLETE tests=%d passed=%d failed=%d incomplete=%d\n', ...
    numel(results),nnz([results.Passed]),nnz([results.Failed]),nnz([results.Incomplete]));
end
