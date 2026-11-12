function subset=subset(train,ids)
    [found,idx]=ismember(ids,train.caseIds);
    assert(all(found),'study:TrainingIds','Unknown training IDs.');
    subset=train;
    subset.caseIds=train.caseIds(idx);
    subset.inputParameters=train.inputParameters(idx,:);
    subset.displacementFields=train.displacementFields(:,idx);
end
