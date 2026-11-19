---
name: test-fem-surrogates
description: Implement or modify the shared MATLAB evaluation and comparison workflow for Code v2 surrogate models, including contract tests and reproducible metrics. Do not use for creating surrogate models or generating FEM data.
---

# Test FEM surrogates

Read `docs/SCHNITTSTELLEN.md` and the relevant study protocol from the Code v2
root. Use the shared loader, prediction and evaluation interfaces; do not add
method-specific evaluation paths or silently reorder, filter or repair output.
Use synthetic data and the dummy method to develop the harness independently.

For an actual final test, document the selected frozen artifacts, reference
dataset, split, metric definitions, thresholds and study configuration before
accessing test labels. The existing interface does not enforce freeze or access
control; do not claim otherwise. Compare equivalent outputs on the same case IDs
and retain undefined relative errors, invalid runs and their reasons. Distinguish
frequency results from eigenforms and prediction time from training and FEM time.
Run `runtests('tests/surrogateContractTest.m')` and meaningful metric or harness
tests. Report actual validation, limitations and any checks not run.
