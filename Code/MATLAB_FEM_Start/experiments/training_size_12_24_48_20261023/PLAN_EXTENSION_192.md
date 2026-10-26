# Protocol extension: 96 -> 192 training cases

User requested the next doubling after the 96-case results were visible.
This extension is fixed before generating or training its new cases.
96 additional randomized Latin-hypercube points, seed 20261025 (twister).
New training IDs 109-204. All previous 96 training cases are reused exactly.
Validation IDs 13-18 and test IDs 19-24 remain unchanged.
Original physics, solver, scaling policy, model seed and all search candidates unchanged.
POD rank candidates remain [2 4 8 11]; same GP, RBF and MLP policies.
No model or solver tuning is introduced. No pilot stage is run.
The choice to extend the series was made after seeing its earlier test results.
Consequently this is an exploratory fixed-test comparison, not a blind confirmation.
milestone_96 preserves the completed previous report, tables, journal and plot.
source_snapshot_n192 preserves the runner version used for this extension.
Run generate192, train192, evaluate192, then summarize. Never overwrite existing models.
