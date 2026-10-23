#!/bin/bash
#SBATCH --job-name=slurm_test
#SBATCH --account=animesh_ray_1465
#SBATCH --time=00:05:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

set -euo pipefail

echo "SLURM test"
echo "Job ID: ${SLURM_JOB_ID:-NA}"
echo "Node: $(hostname)"
echo "Working directory: $(pwd)"
echo "Started: $(date)"
echo "SLURM submission is working."
echo "Finished: $(date)"
