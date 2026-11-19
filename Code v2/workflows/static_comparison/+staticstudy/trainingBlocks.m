function firstBlock = trainingBlocks(data,cfg)
    %trainingBlocks Join explicit case metadata, preserving dataset row order.
    blocks = readtable(cfg.paths.training_blocks,'TextType','string');
    assert(numel(unique(blocks.CaseId))==height(blocks),  'study:Blocks', ...
        'Training block metadata contains duplicate case IDs.');
    [present,location] = ismember(data.caseIds,blocks.CaseId);
    assert(all(present) && all(ismember(blocks.Block,[1 2])),  'study:Blocks', ...
        'Every training case needs an explicit block 1 or 2.');
    firstBlock = blocks.Block(location)==1;
end
