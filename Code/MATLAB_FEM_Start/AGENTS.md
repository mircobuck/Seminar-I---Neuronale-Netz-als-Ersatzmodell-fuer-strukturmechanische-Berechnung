# Project rules: MATLAB FEM surrogate study

## Canonical location

`github_dd_branch/Code/MATLAB_FEM_Start` is the only editable project copy. Work in the
Git checkout and keep changes reviewable. The historical loose duplicate must not be used.

## Structure

- Model implementations belong in `modelle/<model family>`; shared FEM and data functions belong in `modelle/Grundlagen`.
- Package-based MATLAB implementation belongs in `modelle/Framework/+femstudy`; keep thin compatibility adapters only in `src/legacy`.
- MATLAB runners belong in `scripts/matlab`; Python report tools belong in `scripts/python`.
- Versioned inputs belong in `configs`; experiment artifacts belong in `experiments`.
- `experiments/active` holds current evidence; `experiments/archive` holds closed studies.

## Current project context

Read `docs/PROJECT_STATUS.md` for a dated overview of the implemented models,
active study, verification status, and known limitations. It is an orientation
snapshot; verify the live Git state and experiment artifacts before acting.

## Results and reproducibility

Every new study requires a versioned configuration, explicit invocation, provenance, and
an entry in `docs/experiment-index.md`. Never overwrite an existing study result.
Do not commit caches, Python bytecode, LaTeX auxiliaries, MATLAB autosaves, or editor
backups. Retain scientific negative results as archived evidence rather than deleting them.

## MATLAB

Open `matlab.toml` in MATLAB R2026b+ or `blank_project.prj` in MATLAB R2025b; do not spread `addpath` calls through new code. Run `run_checks(false)`
before nontrivial changes and use FEM-dependent tests only when their toolboxes are present.