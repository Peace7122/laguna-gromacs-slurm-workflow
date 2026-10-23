#!/bin/bash
#
# TEMPLATE: validate all resource requests before production use.
#
#SBATCH --job-name=gromacs_md
#SBATCH --account=animesh_ray_1465
#SBATCH --time=<WALLTIME>
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

# Add validated Laguna settings:
# #SBATCH --partition=<PARTITION>
# #SBATCH --nodes=<NODES>
# #SBATCH --ntasks=<TASKS>
# #SBATCH --cpus-per-task=<CPUS>
# #SBATCH --gres=gpu:<GPU_TYPE>:<COUNT>
# #SBATCH --mem=<MEMORY>

set -euo pipefail

module purge
# Load the currently validated GROMACS environment here.

echo "Job ID: ${SLURM_JOB_ID:-NA}"
echo "Node: $(hostname)"
echo "Working directory: $(pwd)"
echo "Started: $(date)"

gmx_mpi --version

if [[ ! -f md.tpr ]]; then
    echo "ERROR: md.tpr not found in $(pwd)" >&2
    exit 2
fi

gmx_mpi mdrun -s md.tpr -deffnm md

echo "Finished: $(date)"
