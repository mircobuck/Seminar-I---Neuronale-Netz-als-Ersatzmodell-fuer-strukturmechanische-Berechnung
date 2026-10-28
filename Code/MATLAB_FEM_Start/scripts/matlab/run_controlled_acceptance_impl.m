function run_controlled_acceptance_impl()
%RUN_CONTROLLED_ACCEPTANCE Verify online interface and record timed batches.
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root,genpath(fullfile(root,'modelle')));
out=fullfile(root,'experiments','hybrid_controlled_fits_v1');
a=load(fullfile(root,'experiments','active','training_size_12_24_48_20261023','n384','train.mat'),'D'); D=a.D;
a=load(fullfile(root,'experiments','hybrid_static_audit_v1','selection.mat'),'spec');
ix=ismember(D.id,a.spec.valIDs); X=D.X(ix,:); xi=D.xi;
results=table; times=zeros(2,5,6);
for k=1:2
    a=load(fullfile(out,sprintf('fit_%d_8.mat',k)),'result'); r=a.result;
    [u,~]=controlled_predict(r,X,xi); discrepancy=max(abs(u-r.valField),[],'all');
    assert(discrepancy<1e-12); results=[results;table(k,"saved/load and prediction",discrepancy,"<1e-12 m","pass")]; %#ok<AGROW>
    bad=X; bad(1,6)=0; assert_failure(@()controlled_predict(r,bad,xi),'controlled:parameters');
    bad=X; bad(1,4)=0; assert_failure(@()controlled_predict(r,bad,xi),'controlled:parameters');
    badxi=xi; badxi(1,1)=badxi(1,1)+1e-3; assert_failure(@()controlled_predict(r,X,badxi),'controlled:space');
    assert_failure(@()controlled_predict(struct(),X,xi),'controlled:schema');
    assert(nargin('controlled_predict')==3);
    for j=1:5
        [~,t]=controlled_predict(r,X,xi);
        times(k,j,:)=[t.physics t.transfer t.regression t.reconstruction t.postprocessing t.total];
    end
end
metadata=struct('matlab',version,'computer',computer,'host',getenv('COMPUTERNAME'), ...
 'batchSize',size(X,1),'warmup',1,'repetitions',5,'spaceTolerance',1e-12, ...
 'timingUnits','seconds per six-case batch','transfer','zero: field evaluated directly on reference grid');
save(fullfile(out,'acceptance.mat'),'results','times','metadata');
disp(results); disp(metadata); disp(squeeze(mean(times,2)));
end
function assert_failure(f,id)
try, f(); catch e, assert(strcmp(e.identifier,id),'Unexpected error: %s',e.identifier); return; end
error('Expected failure %s did not occur.',id);
end
