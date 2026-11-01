# MATLAB FEM surrogate study

This repository contains reproducible FEM, reduced-order-model, and surrogate-model
studies for a parametrised cantilever benchmark.

## Start

Open `matlab.toml` in MATLAB R2026b+ or `blank_project.prj` in MATLAB R2025b. It configures `src`, `scripts/matlab`, and
`tests`; manual `addpath` is unnecessary.

```matlab
run_checks(false)       % fast algebra and split checks
run_study                 % show the available stages
run_study("all")          % current static/modal study, in order
```

The main workflow is split into resumable stages: `run_study("prepare")`,
`run_study("train")`, `run_study("evaluate")`, and `run_study("plot")`.
Final test FEM labels are generated only during evaluation, after models have
been fitted. `run_study("all")` invokes these stages sequentially and may take
substantial time because FEM calculations and model training are required.

The older `run_project("smoke","generate")` / `"train"` / `"evaluate"` workflow
remains available for compatibility and historical experiments. Run FEM-dependent
checks only with the required PDE Toolbox installed. Current studies and their
status are indexed in [docs/experiment-index.md](docs/experiment-index.md).
Architecture and migration rules are in [docs/architecture/overview.md](docs/architecture/overview.md).

## Layout

- `src/+femstudy`: target MATLAB package.
- `src`: existing implementation retained for reproducible legacy studies.
- `scripts/matlab`: study runners; root-level `run_*` functions are compatibility wrappers.
- `configs`: inputs and historical study definitions.
- `experiments/active`: current evidence; `experiments/archive`: completed or superseded evidence.
- `scripts/python`: report helpers only.