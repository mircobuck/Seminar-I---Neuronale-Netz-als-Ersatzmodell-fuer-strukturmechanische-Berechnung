---
name: create-fem-surrogate
description: Implement or adapt a MATLAB surrogate model for the Code v2 static displacement or modal frequency workflow using the shared contract. Do not use for FEM data generation or test-only work.
---

# Create a FEM surrogate

Read `docs/SCHNITTSTELLEN.md` from the Code v2 root before changing a model.
Follow its versioned data, fit, artifact and prediction contracts. Place a new
method in the named `+surrogate/+models/+<methodId>` package and retain the
existing model and dataset interfaces. Train only on the supplied training split;
derive preprocessing and reduced bases from that split, including within folds.
Keep any validation-based selection in the study coordinator and never use test
labels for training or selection.

Store every learned transformation and required metadata in the model artifact;
predictions must use physical units, preserve case order and never invoke FEM.
Do not silently correct invalid outputs. Add method-specific behavioral checks
and run `runtests('tests/surrogateContractTest.m')` plus relevant model tests.
Report actual results, data and configuration used, limitations and any checks
not run. A passing contract suite establishes compatibility, not model accuracy.
