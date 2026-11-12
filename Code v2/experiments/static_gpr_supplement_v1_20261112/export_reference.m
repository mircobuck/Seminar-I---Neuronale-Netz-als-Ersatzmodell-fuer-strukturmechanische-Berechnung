function export_reference
here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
main=fullfile(root,'experiments','static_gpr_main_v1_20261111_run2');
a=load(fullfile(main,'references','extrapolation','test.mat'),'D'); D=a.D;
n=numel(D.id); fields=reshape(D.S,525,3,n);
maxRef=squeeze(max(sqrt(sum(fields.^2,2)),[],1)); maxRef=maxRef(:);
tip=find(all(abs(D.xi-[1;.5;.5])<1e-12,1)); assert(numel(tip)==1);
tipRef=D.S(1050+tip,:)';
T=table(D.id(:),tipRef,maxRef,'VariableNames',{'id','femTip_m','femMaximum_m'});
writetable(T,fullfile(here,'extrapolation_references.csv'));
end
