function subsets = nestedTrainingSubsets(caseIds,firstBlock,sizes,seeds)
%nestedTrainingSubsets Select balanced nested training IDs by repetition.
assert((islogical(firstBlock) || isnumeric(firstBlock)) && isreal(firstBlock) && ...
    all(isfinite(firstBlock(:))) && all(firstBlock(:)==0 | firstBlock(:)==1), ...
    'surrogate:study:Blocks','Block membership must contain logical values.');
caseIds=caseIds(:); firstBlock=logical(firstBlock(:)); sizes=double(sizes(:)); seeds=double(seeds(:));
assert(numel(caseIds)==numel(firstBlock) && numel(unique(caseIds))==numel(caseIds), ...
    'surrogate:study:Ids','IDs must be unique and block membership must align.');
a=caseIds(firstBlock); b=caseIds(~firstBlock);
assert(numel(a)==numel(b) && all(sizes>=2 & sizes<=numel(caseIds) & mod(sizes,2)==0) && ...
    issorted(sizes) && numel(unique(sizes))==numel(sizes), ...
    'surrogate:study:Sizes','Require two equally sized blocks and increasing even sizes.');
assert(all(isfinite(seeds) & seeds>=0 & seeds==fix(seeds)), ...
    'surrogate:study:Seeds','Seeds must be nonnegative integers.');
prior=rng; cleanup=onCleanup(@()rng(prior)); %#ok<NASGU>
subsets=cell(numel(sizes),numel(seeds));
for rep=1:numel(seeds)
    rng(seeds(rep),'twister'); aa=a(randperm(numel(a))); bb=b(randperm(numel(b)));
    for j=1:numel(sizes)
        n=sizes(j)/2;
        if sizes(j)==numel(caseIds)
            subsets{j,rep}=caseIds;
        else
            pair=[aa(1:n),bb(1:n)]; subsets{j,rep}=reshape(pair',[],1);
        end
    end
end
end
