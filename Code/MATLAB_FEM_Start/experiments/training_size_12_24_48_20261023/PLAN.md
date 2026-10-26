# Training-size experiment: 12 -> 24 -> 48

Protocol fixed before new FEM solves or model training.
Only the training set is extended. No pilot stage is run.
Original smoke artifacts are copied to n12 without retraining.
Validation IDs 13-18 and test IDs 19-24 stay fixed, with identical FEM values.
Nested training: n12 IDs 1-12; n24 adds 25-36; n48 adds 37-60.
New points: 36 randomized Latin-hypercube points, 6 inputs, seed 20261023 (twister).
Each coordinate uses an independent random permutation and uniform jitter.
The first 12 added points are the predetermined n24 extension.
The combined 24/48-point designs are nested, not newly optimized LHS designs.
Original parameter bounds, physics, mesh, reference grid and guards are unchanged.
Effective POD candidate ranks fixed to [2 4 8 11] for all sample sizes.
RBF lambdas, MLP widths/epochs/minibatch/early stopping, GP kernel and seed 42 unchanged.
Scaling, POD and regressors are fitted separately on each training subset.
Rank and regression hyperparameters are selected on the same validation cases.
MLP minibatch size remains 16: more samples imply more optimizer steps per epoch.
One model seed per size. This is a descriptive learning-curve experiment.
Six test cases give little statistical precision; P95 equals max here.
The test set was already inspected in the baseline. It is a comparison set, not a new blind holdout.
No choices in this series are made from new test errors.
Existing models are never overwritten. Source snapshot and per-stage output are retained.
There are 36 new physical FEM cases in total; n48 reuses all n24 cases.
Resume with run_training_size_study(stage,studyDir).
Stages: generate24, train24, evaluate24, generate48, train48, evaluate48, summarize.
