function ids = subsets(data,cfg)
%subsets Nested selections from a single pool, with no invented block labels.
prior=rng; cleanup=onCleanup(@()rng(prior)); %#ok<NASGU>
ids=cell(numel(cfg.training_sizes),numel(cfg.seeds_selection));
for rep=1:numel(cfg.seeds_selection)
    rng(cfg.seeds_selection(rep),'twister'); order=randperm(numel(data.caseIds));
    for k=1:numel(cfg.training_sizes)
        n=cfg.training_sizes(k);
        assert(n<=numel(data.caseIds),'modalstudy:Sizes','Training pool too small.');
        ids{k,rep}=data.caseIds(order(1:n));
        if n==numel(data.caseIds), ids{k,rep}=data.caseIds; end
    end
end
end
