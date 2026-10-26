function run_rom_logged_impl(stage,varargin)
%run_rom_logged - Persist output and status for a ROM study stage
%   run_rom_logged(STAGE,...) invokes run_rom_study with durable logging.
%   See also run_rom_study
assert(strlength(string(stage))>0); args=varargin; %#ok<NASGU>
folder=fullfile(fileparts(mfilename('fullpath')),'experiments','active','pod_galerkin_20261023_v1');
started=string(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
failure=[]; clock=tic;
captured=evalc('try; run_rom_study(stage,args{:}); catch cause; failure=cause; fprintf(''%s\n'',getReport(cause,''extended'',''hyperlinks'',''off'')); end');
seconds=toc(clock); finished=string(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
stamp=string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
log=fullfile(folder,'logs',string(stage)+"_"+stamp+".txt");
writelines(["Started: "+started;"Finished: "+finished;"";string(captured)],log);
row=table(string(stage),string(mat2str(cell2mat(varargin))),started,finished,seconds,isempty(failure), ...
    'VariableNames',{'Stage','Arguments','Started','Finished','Seconds','Succeeded'});
file=fullfile(folder,'events.csv');
if isfile(file), old=readtable(file,TextType="string"); row=[old;row]; end
writetable(row,file); fprintf('%s',captured); fprintf('Stage seconds: %.3f\n',seconds);
if ~isempty(failure), rethrow(failure); end
end
