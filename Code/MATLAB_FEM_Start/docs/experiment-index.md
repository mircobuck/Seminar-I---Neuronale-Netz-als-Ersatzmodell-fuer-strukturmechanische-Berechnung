# Experiment index

| Location | Decision | Purpose and retained evidence | Reproduction status / successor |
| --- | --- | --- | --- |
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