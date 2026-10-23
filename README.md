# Laguna GROMACS + SLURM Workflow

A reusable workflow for running GROMACS molecular dynamics simulations on USC CARC Laguna when molecular-system preparation is performed with CHARMM-GUI.

## Workflow

CHARMM-GUI → GROMACS-compatible files → Laguna project space → SLURM submission → GROMACS run → monitoring → restart/next stage → analysis

## What each component does

- **CHARMM-GUI**: web-based molecular-system preparation.
- **GROMACS**: performs the molecular dynamics calculation.
- **SLURM**: allocates Laguna compute resources and launches the GROMACS job.

## Main protocol

See `docs/PROTOCOL.md` for the complete step-by-step workflow.

## Ray Lab project space

`/project/animesh_ray_1465`

Each user or simulation project should use its own working directory inside the shared project space.

## Repository structure

```text
laguna-gromacs-slurm-workflow/
├── README.md
├── docs/
│   └── PROTOCOL.md
├── slurm/
│   ├── 00_slurm_test.sh
│   └── 10_gromacs_template.sh
├── charmm_gui/
│   └── README.md
├── troubleshooting/
│   └── README.md
└── .gitignore
```

## Important

Do not run long GROMACS simulations directly on a Laguna login node.

Cluster modules, partitions, GPU types, CPU counts, memory requests, and wall-time limits can change. Verify the current Laguna configuration before production runs.
