function studyRecordGeneration(folder,role,startUtc,timer)
file=fullfile(folder,'generation_sessions.csv'); exists=isfile(file);
fid=fopen(file,'a'); assert(fid>=0,'study:GenerationLog','Cannot open generation timing log.');
closer=onCleanup(@()fclose(fid));
if ~exists, fprintf(fid,'role,start_utc,elapsed_seconds\n'); end
fprintf(fid,'%s,%s,%.9f\n',char(role),char(startUtc),toc(timer));
end
