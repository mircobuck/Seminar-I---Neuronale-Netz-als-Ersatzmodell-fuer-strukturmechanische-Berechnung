function studyRecordSearch(folder,method,startUtc,timer)
file=fullfile(folder,'search_sessions.csv'); exists=isfile(file);
fid=fopen(file,'a'); assert(fid>=0,'study:SearchLog','Cannot open search timing log.');
closer=onCleanup(@()fclose(fid));
if ~exists, fprintf(fid,'method,start_utc,elapsed_seconds\n'); end
fprintf(fid,'%s,%s,%.9f\n',char(method),char(startUtc),toc(timer));
end
