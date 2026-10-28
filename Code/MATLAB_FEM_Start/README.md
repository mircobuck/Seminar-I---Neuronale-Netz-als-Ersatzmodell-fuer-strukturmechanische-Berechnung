# MATLAB FEM surrogate study

This repository contains reproducible FEM, reduced-order-model, and surrogate-model
studies for a parametrised cantilever benchmark.

## Start

Open `matlab.toml` in MATLAB R2026b+ or `blank_project.prj` in MATLAB R2025b. It configures the model folders, `scripts/matlab`, and
`tests`; manual `addpath` is unnecessary.

```matlab
run_checks(false)       % fast algebra and split checks
run_project("smoke","generate")
run_project("smoke","train")
```

Run FEM-dependent checks only with the required PDE Toolbox installed. Current studies
and their status are indexed in [docs/experiment-index.md](docs/experiment-index.md).
Architecture and migration rules are in [docs/architecture/overview.md](docs/architecture/overview.md).

## Layout

- `modelle`: MATLAB source grouped by model family, with shared code in `Grundlagen` and the package in `Framework/+femstudy`.
- `src/legacy`: reserved for thin compatibility adapters.
- `scripts/matlab`: study runners; root-level `run_*` functions are compatibility wrappers.
- `configs`: inputs and historical study definitions.
- `experiments/active`: current evidence; `experiments/archive`: completed or superseded evidence.
- `scripts/python`: report helpers only.