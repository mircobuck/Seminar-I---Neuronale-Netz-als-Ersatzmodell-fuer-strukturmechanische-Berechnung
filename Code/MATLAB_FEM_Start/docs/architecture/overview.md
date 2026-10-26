# Architecture overview

`femstudy.*` under `src/+femstudy` is the target implementation boundary. It owns
FEM primitives, data contracts, model interfaces, metrics, and reporting. The original
functions in `src/` remain available only for existing studies; new functionality must
be added to the package or a narrowly scoped adapter in `src/legacy`.

Data flow: versioned configuration -> FEM reference -> immutable experiment artifact ->
model fit -> prediction -> metric/report. Test references are used only after prediction
for evaluation. Study runners live in `scripts/matlab`; root-level `run_*` files are
compatibility wrappers. Python report helpers live in `scripts/python`.

Open `matlab.toml` in MATLAB R2026b+ or `blank_project.prj` in MATLAB R2025b. It adds `src` and `scripts/matlab` to the
path and registers `tests` as the test folder; no manual `addpath` is required.