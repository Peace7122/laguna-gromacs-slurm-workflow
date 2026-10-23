# CHARMM-GUI → GROMACS → Laguna → SLURM Protocol

## 1. Purpose

This protocol describes how to take a molecular system prepared with CHARMM-GUI, move the generated GROMACS files to USC CARC Laguna, submit the simulation through SLURM, monitor the run, troubleshoot failures, and continue or restart long simulations.

## 2. Overall workflow

```text
CHARMM-GUI
    ↓
prepare molecular system
    ↓
generate GROMACS-compatible package
    ↓
transfer package to Laguna
    ↓
inspect files and stage instructions
    ↓
prepare or verify .tpr
    ↓
submit through SLURM
    ↓
GROMACS runs on a compute node
    ↓
monitor and inspect logs
    ↓
verify outputs
    ↓
continue / next stage / analysis
```

## 3. Log in to Laguna

After login:

```bash
hostname
pwd
```

You normally begin on a login node.

Use the login node for:
- navigation and file management
- editing scripts
- checking modules
- lightweight preprocessing
- submitting jobs
- monitoring jobs
- reading logs

Do not run long production MD directly on a login node.

## 4. Use the shared project space

Ray Lab project storage:

```bash
/project/animesh_ray_1465
```

Create a dedicated working directory for each user or project, for example:

```bash
mkdir -p /project/animesh_ray_1465/<USER_OR_PROJECT>_MD
```

Recommended layout:

```text
<USER_OR_PROJECT>_MD/
├── charmm_gui_packages/
├── runs/
├── scripts/
├── analysis/
└── notes/
```

## 5. Finish CHARMM-GUI preparation first

Complete the system-building workflow in CHARMM-GUI before trying to run the simulation on Laguna.

Do not proceed while CHARMM-GUI still reports unresolved problems involving:
- periodic-boundary setup
- membrane construction
- solvation
- ion placement
- topology generation
- force-field assignment
- restraint generation
- another required preparation stage

A SLURM job cannot repair an incorrectly prepared molecular system.

For this workflow, generate the GROMACS-compatible package.

## 6. Transfer the CHARMM-GUI package to Laguna

Move the complete generated package into the project space.

Example destination:

```bash
/project/animesh_ray_1465/<USER_OR_PROJECT>_MD/charmm_gui_packages/<SYSTEM>
```

Then enter the directory:

```bash
cd /project/animesh_ray_1465/<USER_OR_PROJECT>_MD/charmm_gui_packages/<SYSTEM>
```

Confirm location and inspect the files:

```bash
pwd
ls -lah
find . -maxdepth 2 -type f | sort
```

Initially preserve the CHARMM-GUI-generated directory structure and filenames.

Read any README or run instructions supplied by CHARMM-GUI before changing the generated workflow.

## 7. Know the common GROMACS files

- `.mdp` — simulation parameter file
- `.gro` — GROMACS coordinate file
- `.pdb` — structural coordinate file
- `.top` — main topology
- `.itp` — included topology
- `.tpr` — compiled GROMACS run input used by `mdrun`
- `.xtc` — compressed trajectory
- `.trr` — higher-detail trajectory data, depending on output settings
- `.edr` — energy and thermodynamic data
- `.cpt` — checkpoint file
- `.log` — GROMACS log

## 8. Check GROMACS on Laguna

Inspect available modules:

```bash
module spider gromacs
```

or:

```bash
module avail gromacs
```

Load the currently appropriate GROMACS environment, then verify the executable and version:

```bash
gmx_mpi --version
```

If the loaded module provides a different executable name, use that executable instead.

Record the GROMACS version used for production simulations.

## 9. Understand `grompp` and `.tpr`

The basic relationship is:

```text
.mdp + coordinates + topology
            ↓
          grompp
            ↓
           .tpr
            ↓
          mdrun
```

Generic example:

```bash
gmx_mpi grompp \
    -f md.mdp \
    -c starting_structure.gro \
    -p topol.top \
    -o md.tpr
```

This is only a generic example.

If CHARMM-GUI provides stage-specific GROMACS commands, follow those instructions rather than replacing them with generic commands.

Before submission, confirm the expected `.tpr` exists:

```bash
ls -lh *.tpr
```

For a run expected to use `md.tpr`:

```bash
ls -lh md.tpr
```

Do not submit `mdrun` if the required `.tpr` is missing.

## 10. Login node versus compute node

Expected workflow:

```text
login node
    ↓
sbatch
    ↓
SLURM queue
    ↓
compute node allocated
    ↓
GROMACS runs
```

The login node is for preparation and submission. Compute nodes are for heavy simulation work.

## 11. Prepare the SLURM script

Start from `slurm/10_gromacs_template.sh`.

Production resource requests must be checked against the current Laguna configuration and the needs of the system. Do not guess them.

The script should contain:
- job name
- project account
- wall time
- partition
- CPU request
- GPU request if needed
- memory
- output and error filenames
- required module loads
- the correct GROMACS command

## 12. Check before submission

From the run directory:

```bash
pwd
ls -lah
ls -lh md.tpr
less run_md.sh
```

Confirm:
- correct system
- correct stage
- previous stage completed successfully
- required topology and coordinate files are present
- correct `.tpr` exists
- correct GROMACS environment is used
- SLURM resource requests are appropriate
- sufficient storage is available

## 13. Submit the job

```bash
sbatch run_md.sh
```

SLURM should return:

```text
Submitted batch job JOB_ID
```

Record the job ID.

## 14. Monitor the job

Show current jobs:

```bash
squeue -u $USER
```

Inspect one job:

```bash
scontrol show job JOB_ID
```

Compact view:

```bash
squeue -j JOB_ID -o "%.18i %.12j %.2t %.10M %.30R"
```

Common states:
- `PD` — Pending
- `R` — Running
- `CG` — Completing
- `CD` — Completed
- `F` — Failed
- `CA` — Cancelled
- `TO` — Timeout
- `OOM` — Out of memory

A pending job is not automatically broken. `Resources` and `Priority` are common normal pending reasons.

## 15. Read SLURM logs

If the script uses:

```bash
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
```

read the files with:

```bash
less JOBNAME_JOBID.out
less JOBNAME_JOBID.err
```

Follow a running output file with:

```bash
tail -f JOBNAME_JOBID.out
```

Press `Ctrl+C` to stop `tail`. This does not cancel the SLURM job.

## 16. Read the GROMACS log

A production run commonly creates `md.log`.

Inspect the end with:

```bash
tail -n 100 md.log
```

SLURM logs and GROMACS logs diagnose different layers of the workflow.

## 17. Check a completed job

Completed jobs normally disappear from `squeue`.

Use:

```bash
sacct -j JOB_ID --format=JobID,JobName,State,Elapsed,ExitCode
```

A successful job should normally report `COMPLETED`.

Then inspect the run directory:

```bash
ls -lah
```

Typical outputs may include:

```text
md.log
md.xtc
md.edr
md.cpt
md.gro
```

## 18. Cancel a job

```bash
scancel JOB_ID
```

Then verify:

```bash
squeue -u $USER
```

## 19. Continue from a checkpoint

Checkpoint files use the `.cpt` extension.

Do not delete a valid checkpoint from an incomplete long run.

Typical continuation:

```bash
gmx_mpi mdrun \
    -s md.tpr \
    -deffnm md \
    -cpi md.cpt \
    -append
```

This command resumes an interrupted simulation toward the endpoint already encoded in the existing `.tpr`. It does **not** automatically extend the simulation beyond the end time defined in that run input.

If the intended simulation length itself needs to be extended, prepare an appropriately extended run input before restarting. Do not assume that `-cpi` alone changes the planned simulation duration.

Only continue when the checkpoint is valid and continuation is appropriate.

## 20. Sequential stages

A typical workflow may include:

```text
energy minimization
        ↓
equilibration stage(s)
        ↓
production MD
```

CHARMM-GUI may generate several equilibration stages. Do not assume a universal number of stages.

Follow the stage order generated for the actual system and verify each stage before proceeding.

## 21. Five SLURM commands to remember

```bash
sbatch run.sh
squeue -u $USER
scontrol show job JOB_ID
sacct -j JOB_ID
scancel JOB_ID
```

## 22. Troubleshooting order

If a job fails:

1. Check the SLURM state with `sacct`.
2. Read the SLURM `.err` file.
3. Read the SLURM `.out` file.
4. Read the GROMACS `.log` file.
5. Confirm the correct `.tpr`.
6. Confirm the GROMACS environment.
7. Confirm the working directory.
8. Confirm CHARMM-GUI preparation completed successfully.
9. Confirm the requested SLURM resources were appropriate.

A CHARMM-GUI preparation problem is not a SLURM problem.

A GROMACS simulation instability is not automatically a scheduler problem.

## 23. Working SLURM example

A real production script used successfully for a previous Ray Lab GROMACS MD project on Laguna is available at:

`slurm/examples/md_300ns_array_example.sh`

Read `slurm/examples/README.md` first. The script demonstrates a working job structure, not a universal resource prescription. Its GPU type, CPU count, memory, wall time, array size, filenames, directory layout, and GROMACS options were specific to that project.

## 24. Reproducibility

For each production simulation, record:
- system name
- starting structure
- CHARMM-GUI setup
- force field
- water model
- GROMACS version
- temperature and pressure
- time step
- number of steps
- simulation length
- SLURM job ID
- requested resources
- checkpoint information
- analysis location
