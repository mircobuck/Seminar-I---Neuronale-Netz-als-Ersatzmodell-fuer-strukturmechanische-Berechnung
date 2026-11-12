function studyVerify(root,studyRoot,out)
f=fullfile(out,'source_manifest.csv'); assert(isfile(f),'study:NotInitialized','Study not initialized.');
old=readtable(f,'TextType','string','Delimiter',',','ReadVariableNames',true,'VariableNamingRule','preserve'); now=studySources(root,studyRoot);
assert(isequal(old,now),'study:SourceChanged','Source, configuration or training data changed; use a new study.');
end
