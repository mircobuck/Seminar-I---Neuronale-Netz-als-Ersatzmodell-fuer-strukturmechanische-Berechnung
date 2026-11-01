# Experiment index

| Location | Decision | Purpose and retained evidence | Reproduction status / successor |
| --- | --- | --- | --- |
| `experiments/active/restfield_mlp_architecture_training_20261028_v1` | active, limited campaign complete | Controlled comparison of `[16]`, `[16,16]`, `[32,32]` MLPs under Adam; paired Adam/L-BFGS comparison for selected `[32,32]`; and a fixed-kernel GPR reference on the same fold-specific, train-only POD representation. Three grouped folds in the established 384 training cases; selected L-BFGS `[32,32]` and fitted three final models on all 384 cases. Retains the complete protocol, attempt ledger including 18 failed attempts and successful retries, per-case CV/final metrics, training histories, selections, plots, and immutable provenance amendments. No prior holdout or new FEM labels were used. | Completed and audited with `run_restfield_architecture_training('evaluate')` and `analyze_restfield_architecture_training()`. See `FINAL_REPORT_v2.md`; CV remains model-selection evidence, not an independent test. |
| `experiments/active/static_shared_comparison_20261028_v1` | active, independent 64-case evaluation complete | Common n=384 static field comparison of the analytical beam field, three seeds each of POD-MLP and beam-residual MLP, existing POD-GPR, and newly fitted beam-field plus POD-GPR residual. Retains the sealed holdout, all 64 FEM references, complete per-case/pair/timing results, hashes, a preserved first-attempt runner failure, and its successful same-ID retry. | Reproduce/resume with `run_static_shared_comparison("final_data")`, then `"final_evaluate"`; audit with `analyze_static_shared_holdout()`. See `FINAL_REPORT.md`, PROTOCOL.md, and MODEL_MANIFEST.md. |
| `experiments/active/neural_comparison_20261027_v1` | active, evaluation complete | Preregistered static neural-field and variable-density modal-frequency comparison; complete 64-case independent evaluations, retained model artifacts, per-case metrics, and timings. No eigenform surrogate or MAC mode-family evaluation. | Reproduce with `configs/neural_comparison_v1.json` and `scripts/matlab/run_neural_comparison.m`; see PROTOCOL.md, PROTOTYPES.md, and PROGRESS_20261027.md for results and limitations. |
| `experiments/active/training_size_12_24_48_20261023` | active | Nested training-size learning curve and model artifacts. | Historical result; successor work uses the packaged architecture. |
| `experiments/active/pod_galerkin_20261023_v1` | active | POD-Galerkin reference study and final report. | Reproducible from runner and recorded provenance. |
| `experiments/active/static_confirmation_v1` | active | Independent 64-case confirmation of frozen static models. | Final confirmation evidence; do not reuse as untouched test data. |
| `experiments/active/scientific_synthesis_20261026_v1` | active | Current scientific synthesis and final presentation artifacts. | Derived from the indexed studies. |
| `experiments/archive/deeponet_20261023_v1` | archive | Negative DeepONet comparison; retained as evidence against the evaluated replacement. | Closed; no follow-up without a new protocol. |
| `experiments/archive/hybrid_*` | archive | Preliminary hybrid fits, audits, and diagnostics. | Closed exploratory evidence; the confirmation study supersedes conclusions. |
| `experiments/archive/architecture_phase1_v1` | archive | Initial package/architecture integration experiment. | Superseded by the current package migration. |
| `experiments/archive/modal_hybrid_followup_v1` | archive | Incomplete modal-hybrid follow-up. | Retained only as provenance. |
| `configs/historical-study-definitions` | archive | Historical study-definition draft, not a result. | Use a new versioned config for new experiments. |

An experiment is active only if it is current evidence, its report names inputs and outputs,
and its result can be traced to stored artifacts. Generated caches and compiler intermediates
are never evidence and are excluded by `.gitignore`.

| `experiments/active/restfield_learning_curve_20261028_v1` | active | Completed rest-field MLP/GPR learning curve; 128 development FEM cases. | P95 target first met at n=48 for all three MLP seeds and GPR; not an independent test. |

## Sampling study, 29 October 2026

`experiments/active/restfield_sampling48_20261028_v1`: completed comparison
of three random and three maximin-LHS 48-case training designs. All models
were evaluated on the previously used 128-case development validation set.
Nine of 18 MLP runs met the P95 target; all three seeds met it for one of six
designs. The three designs per strategy do not establish general superiority
or replace an independent test. See the study's `FINAL_REPORT_v2.md`.

## Modal frequency optimizer study, 29 October 2026

`experiments/active/modal_frequency_optimizer_20261029_v1`: completed
three-fold comparison on the existing 384 modal training cases, with 18
fixed-architecture MLP fits and three GPR references. The preregistered raw-Hz
mean relative CV error selected L-BFGS over Adam; three 384-case final fits
are saved without independent evaluation. See `FINAL_REPORT_v2.md`.

## Independent static and modal evaluation, 29 October 2026

`experiments/active/independent_static_modal_20261029_v1` completes two
independent 128-case FEM holdouts for the frozen n=384 models. Static P95
meets 1% for all three residual MLP seeds and the shared-POD GPR; modal raw
P95 exceeds 1% for every tested frequency and model/seed. See
`FINAL_REPORT_v2.md`, including the timing-pilot limitation and the modal FEM
wall-time interruption. These results do not establish a minimum training size.
