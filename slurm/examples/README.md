# Example: 300-ns GROMACS Production Job Array

This directory contains a real SLURM script used successfully for a previous Ray Lab GROMACS molecular-dynamics project on USC CARC Laguna.

## What the example does

The script `md_300ns_array_example.sh` launches three independent production-MD replicates using a SLURM job array.

The original workflow used:

- GPU partition
- 1 node
- 1 task per array job
- 12 CPUs per task
- 1 NVIDIA L40S GPU
- 48 GB memory
- 7-day wall-time limit
- SLURM array indices 1-3
- GROMACS GPU module
- `gmx_mpi mdrun`

Each array task enters its corresponding replicate directory:

```text
rep1/
rep2/
rep3/
```

and runs:

```bash
gmx_mpi mdrun -s md.tpr -deffnm md_300ns -ntomp $OMP_NUM_THREADS -gpu_id 0
```

## Before submitting this example

The script writes SLURM standard output and error files into a `logs/` directory:

```bash
#SBATCH --output=logs/md_300ns_reps_%A_%a.out
#SBATCH --error=logs/md_300ns_reps_%A_%a.err
```

Create that directory before submission:

```bash
mkdir -p logs
```

The example script is preserved from the original project workflow. Comments referring to numbered steps, filenames such as `md.tpr`, replicate directories such as `rep1/`, `rep2/`, and `rep3/`, and the 300-ns duration are project-specific and should not be interpreted as universal instructions.

## Important

This script is provided as a working example of SLURM structure, GPU-resource requests, job arrays, module loading, logging, and GROMACS execution on Laguna.

Do not assume that the same GPU type, CPU count, memory, wall time, filenames, number of replicates, or GROMACS command options are appropriate for every molecular system.

Always adapt the script to the current Laguna configuration and the requirements of the simulation being run.
