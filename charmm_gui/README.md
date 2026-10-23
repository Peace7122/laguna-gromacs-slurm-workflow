# CHARMM-GUI Notes

Use CHARMM-GUI in the browser to prepare the molecular system and generate GROMACS-compatible output.

Before transferring the package to Laguna:
1. Complete all required CHARMM-GUI setup stages.
2. Resolve any PBC, membrane, solvation, ion, topology, force-field, or restraint errors.
3. Generate/download the complete GROMACS package.
4. Preserve the generated directory structure initially.
5. Read the generated README/run instructions before changing filenames or stage order.

CHARMM-GUI prepares the system. GROMACS runs the simulation. SLURM allocates Laguna compute resources.
