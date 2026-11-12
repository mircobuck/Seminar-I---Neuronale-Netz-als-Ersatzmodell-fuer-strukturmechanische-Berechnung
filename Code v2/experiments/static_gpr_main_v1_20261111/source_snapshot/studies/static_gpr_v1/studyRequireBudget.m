function studyRequireBudget(out,estimatedSeconds)
% Conservative elapsed-time limit; interrupted work remains resumable.
a=load(fullfile(out,'environment.mat'),'metadata'); m=a.metadata;
elapsed=posixtime(datetime('now','TimeZone','UTC'))-m.startedPosix;
remaining=m.budgetSeconds-m.pilotSpentSeconds-elapsed;
assert(remaining>=estimatedSeconds,'study:BudgetExhausted', ...
    'Remaining %.1f seconds below estimated %.1f seconds.',remaining,estimatedSeconds);
end
