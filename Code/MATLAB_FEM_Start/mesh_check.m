function result=mesh_check(mode)
% Run BEFORE expensive data generation. This is not a learned-model test.
if nargin<1, mode="smoke"; end
c=config(mode); addpath(genpath(fullfile(c.root,'modelle')));
% Midpoint and the most flexible selected corner.
X=[(c.lower+c.upper)/2; c.upper(1),c.lower(2:4),0.30,c.lower(6)];
levels=[2 3 4 5]; result=table();
for i=1:size(X,1)
    prev=[];
    for div=levels
        c.meshDivisor=div; out=solve_case(X(i,:),c);
        if isempty(prev), change=NaN;
        else, change=norm(out.S-prev)/max(norm(out.S),eps); end
        row=table(i,div,out.nNodes,out.Y(1),out.Y(2),change,out.seconds, ...
            'VariableNames',{'Case','Divisor','Nodes','TipUz_m','MaxGridU_m', ...
            'RelativeChangeToCoarser','Seconds'});
        if isempty(result), result=row; else, result=[result;row]; end %#ok<AGROW>
        prev=out.S;
    end
end
if ~isfolder(c.out), mkdir(c.out); end
writetable(result,fullfile(c.out,'mesh_check.csv')); disp(result);
end
