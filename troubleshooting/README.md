# Troubleshooting

Use this order when a job fails:

1. `sacct -j JOB_ID --format=JobID,JobName,State,Elapsed,ExitCode`
2. Read the SLURM `.err` file.
3. Read the SLURM `.out` file.
4. Read the GROMACS `.log` file.
5. Confirm the expected `.tpr` exists.
6. Confirm the correct GROMACS environment.
7. Confirm the working directory.
8. Confirm CHARMM-GUI preparation completed successfully.
9. Confirm the requested SLURM resources were appropriate.

A CHARMM-GUI preparation error is not a SLURM error.

A GROMACS simulation instability is not automatically a scheduler error.
