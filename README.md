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
│   ├── 10_gromacs_template.sh
│   └── examples/
│       ├── README.md
│       └── md_300ns_array_example.sh
├── charmm_gui/
│   └── README.md
├── troubleshooting/
│   └── README.md
└── .gitignore
```

## Important

Do not run long GROMACS simulations directly on a Laguna login node.

Cluster modules, partitions, GPU types, CPU counts, memory requests, and wall-time limits can change. Verify the current Laguna configuration before production runs.

## Real SLURM Example From a Completed Project

In addition to the reusable template, this repository includes a real production SLURM script that was used successfully for a previous Ray Lab GROMACS MD project on Laguna:

`slurm/examples/md_300ns_array_example.sh`

This example shows how a working Laguna production job was structured in practice, including GPU allocation, CPU and memory requests, a three-replicate SLURM job array, module loading, log naming, and the `gmx_mpi mdrun` command.

**Start with `slurm/examples/README.md` before copying the script.** The example preserves project-specific filenames, replicate directories, resource requests, and comments from the original run, so it should be adapted rather than used unchanged for a different molecular system.
