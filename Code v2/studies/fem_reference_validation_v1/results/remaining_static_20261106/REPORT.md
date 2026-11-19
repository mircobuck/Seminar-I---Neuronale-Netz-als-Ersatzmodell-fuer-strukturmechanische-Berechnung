# Additional analytical validation of static FEM cases

**Run date:** 2026-11-06  
**Scope:** 384 added training, 12 validation and 64 test cases (460 total).  
**Status:** completed; existing FEM results were read only.

The remaining cases were compared with Euler-Bernoulli and Timoshenko beam curves along the 21-point beam center axis, including tip deflection. No FEM runs, surrogate training or surrogate predictions were performed. Validation and test FEM labels were read for this physics-reference check; this is not an independent POD-MLP test and must not be used for model selection.

The original 384 training cases and their stored results were not changed. The all-static summary combines those 384 cases with the 460 remaining cases (844 unique cases). Relative errors are ratios; multiply by 100 for percent. P95 uses nearest rank.

## Remaining cases by split and theory

| Split | Theory | Cases | Axis RMS median | Axis RMS P95 | Axis RMS max | Tip median | Tip P95 | Tip max |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| train_added | Euler-Bernoulli | 384 | 0.0044421172 | 0.018824492 | 0.030719323 | 0.0038262822 | 0.016143623 | 0.026467497 |
| train_added | Timoshenko | 384 | 0.0093666573 | 0.016627595 | 0.020502792 | 0.0080095327 | 0.014314063 | 0.017540752 |
| validation | Euler-Bernoulli | 12 | 0.0059664527 | 0.01523221 | 0.01523221 | 0.0050834019 | 0.012965655 | 0.012965655 |
| validation | Timoshenko | 12 | 0.0086101414 | 0.020953355 | 0.020953355 | 0.0073470328 | 0.01799345 | 0.01799345 |
| test | Euler-Bernoulli | 64 | 0.0046424583 | 0.020545499 | 0.029910579 | 0.0040195744 | 0.017721212 | 0.025629651 |
| test | Timoshenko | 64 | 0.0090318552 | 0.013770013 | 0.01705853 | 0.0077444492 | 0.011689348 | 0.014610978 |
| all_remaining | Euler-Bernoulli | 460 | 0.0045514469 | 0.018824492 | 0.030719323 | 0.0038703526 | 0.016143623 | 0.026467497 |
| all_remaining | Timoshenko | 460 | 0.0093129477 | 0.016586829 | 0.020953355 | 0.0079299467 | 0.014294112 | 0.01799345 |

## All 844 static cases (original plus remaining)

| Theory | Cases | Axis RMS median | Axis RMS P95 | Axis RMS max | Tip median | Tip P95 | Tip max |
|---|---:|---:|---:|---:|---:|---:|---:|
| Euler-Bernoulli | 844 | 0.0043490462 | 0.018824492 | 0.034440097 | 0.0037003699 | 0.016143623 | 0.029458684 |
| Timoshenko | 844 | 0.0093480053 | 0.016440284 | 0.021837933 | 0.0079696384 | 0.014096982 | 0.018629062 |

## Limitations

- This is a one-dimensional center-axis/tip comparison, not a full 3D field validation.
- Euler-Bernoulli and Timoshenko are approximations, not exact 3D solutions.
- Reading validation/test FEM labels here does not assess or select a surrogate.
