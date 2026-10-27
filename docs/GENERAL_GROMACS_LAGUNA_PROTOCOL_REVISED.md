# General GROMACS Molecular Dynamics Workflow on Laguna

## Purpose

This protocol is a reusable guide for preparing and running a molecular dynamics (MD) simulation with GROMACS on USC CARC Laguna, starting from a molecular structure such as a PDB file.

It is adapted from a workflow previously used for antibody–peptide simulations on Laguna, but project-specific paths, usernames, molecular systems, run lengths, replicate counts, protonation choices, and resource requests have been removed.

This protocol is intended as a **general workflow**, not a substitute for system-specific scientific judgment.

---

## Overall workflow

```text
Starting structure
    ↓
Inspect structure and protonation
    ↓
pdb2gmx / topology generation
    ↓
Define simulation box
    ↓
Solvate
    ↓
Add ions
    ↓
Energy minimization
    ↓
NVT equilibration
    ↓
NPT equilibration
    ↓
Production MD
    ↓
Monitor / restart if needed
    ↓
Analysis
```

---

# 1. Before you begin

You should have:

- access to USC CARC Laguna;
- access to a project directory where you are permitted to write files;
- a starting molecular structure, typically a `.pdb` file;
- validated GROMACS `.mdp` files appropriate for your system;
- an appropriate force field and water model selected for your scientific question;
- a plan for protonation states, ions, simulation length, and number of replicates.

Do **not** run long MD simulations directly on a Laguna login node. Use SLURM.

Cluster modules, GPU types, partitions, CPU counts, memory limits, and wall-time policies can change. Verify the current Laguna configuration before production runs.

---

# 2. Create a working directory

Choose a project path and run name.

```bash
BASE=/project/YOUR_PROJECT_DIRECTORY
RUN=your_system_name
WORK="${BASE}/${RUN}_MD"

mkdir -p "$WORK"
cd "$WORK"

pwd
```

Copy the starting structure into the working directory using a simple filename:

```bash
cp /path/to/your_structure.pdb model.pdb
```

Confirm:

```bash
ls -lh model.pdb
```

---

# 3. Load GROMACS

The exact module names can change. First inspect what is available:

```bash
module avail gromacs
```

A previously used Laguna environment included:

```bash
module purge
module load gcc
module load fftw
module load gromacs-gpu
```

Then verify:

```bash
which gmx_mpi
gmx_mpi --version | head
```

If your project requires additional software, such as PROPKA, load or activate it separately.

---

# 4. Validate the MDP files before running

Before starting system preparation or equilibration, inspect the `.mdp` files you intend to use.

This protocol assumes files named:

```text
ions.mdp
minim.mdp
nvt.mdp
npt.mdp
md.mdp
```

Your filenames may differ. The important point is to verify the settings before generating run inputs.

A useful first-pass check is:

```bash
echo "===== minim.mdp ====="
grep -E "integrator|emtol|emstep|nsteps" minim.mdp

echo "===== nvt.mdp ====="
grep -E "integrator|nsteps|dt|continuation|tcoupl|ref_t|gen_vel|gen_seed|ld_seed" nvt.mdp

echo "===== npt.mdp ====="
grep -E "integrator|nsteps|dt|continuation|tcoupl|pcoupl|tau_p|ref_t|ref_p|gen_vel" npt.mdp

echo "===== md.mdp ====="
grep -E "integrator|nsteps|dt|continuation|tcoupl|pcoupl|tau_p|ref_t|ref_p|gen_vel|constraints|nstxout-compressed" md.mdp
```

Check that:

- `dt` and `nsteps` give the intended simulation duration;
- NVT/NPT/production continuation settings are appropriate;
- velocity generation is used only where intended;
- independent replicates use appropriate independent seeds when velocities are generated;
- thermostat and barostat choices match the project;
- temperature and pressure targets are correct;
- constraints and output frequencies are intentional.

For production MD:

```text
simulation time = dt × nsteps
```

For example, if `dt = 0.002 ps`, then `150000000` steps corresponds to `300000 ps = 300 ns`.

That example is only arithmetic. It does **not** mean every project should run for 300 ns.

Do not proceed if you do not understand an important `.mdp` setting or if the file was copied from another project without review.

---

# 5. Inspect the starting structure

Before topology generation, confirm that the structure is the one you intend to simulate.

Examples:

```bash
head -n 20 model.pdb
grep '^ATOM' model.pdb | head
grep '^ATOM' model.pdb | awk '{print $5}' | sort -u
```

Check:

- chain identities;
- missing residues or atoms;
- alternate conformations;
- ligands or cofactors;
- disulfide bonds;
- protonation-sensitive residues;
- nonstandard residues;
- whether the structure contains crystallographic waters or other molecules that should be retained or removed.

Do not assume that chain names, residue numbering, or protonation states from another project apply to your system.

---

# 6. Determine protonation states

Protonation choices are system-dependent.

If PROPKA is available, one possible check is:

```bash
python3 -m propka model.pdb -o 7.4
```

Inspect the resulting output, especially histidines and other titratable residues.

Do not automatically reuse protonation choices from a different protein or peptide.

If the protonation state is uncertain and scientifically important, resolve that question before proceeding.

---

# 7. Generate the GROMACS topology with pdb2gmx

A general interactive command is:

```bash
gmx_mpi pdb2gmx \
  -f model.pdb \
  -o model_processed.gro \
  -ignh \
  -inter
```

GROMACS will prompt for a force field and water model if they are not specified on the command line.

Choose these based on the molecular system and project requirements.

If you have already selected and validated them, they may be specified explicitly, for example:

```bash
gmx_mpi pdb2gmx \
  -f model.pdb \
  -o model_processed.gro \
  -ignh \
  -inter \
  -ff YOUR_FORCE_FIELD \
  -water YOUR_WATER_MODEL
```

Afterward, confirm that topology files were created:

```bash
ls -lh model_processed.gro topol.top
ls -lh *.itp 2>/dev/null
```

Stop if `pdb2gmx` reports a fatal error or if important residues cannot be parameterized.

---

# 8. Define the simulation box

A common starting point is to center the system and add solvent padding.

Example:

```bash
gmx_mpi editconf \
  -f model_processed.gro \
  -o model_newbox.gro \
  -c \
  -d 1.0 \
  -bt cubic
```

Here, `-d 1.0` gives approximately 1.0 nm of padding between the solute and the box edge.

Box type and padding are **system-dependent**. Do not treat this value as universal.

Check:

```bash
ls -lh model_newbox.gro
```

---

# 9. Solvate the system

Use a solvent coordinate file compatible with the selected water model.

A common GROMACS solvent box is:

```bash
gmx_mpi solvate \
  -cp model_newbox.gro \
  -cs spc216.gro \
  -o model_solv.gro \
  -p topol.top
```

Check:

```bash
ls -lh model_solv.gro topol.top
tail -n 20 topol.top
```

Confirm that the solvent count was added to the topology.

---

# 10. Prepare for ion addition

You need an `.mdp` file suitable for generating the ion-placement run input.

Assume it is called:

```text
ions.mdp
```

Generate the temporary `.tpr`:

```bash
gmx_mpi grompp \
  -f ions.mdp \
  -c model_solv.gro \
  -p topol.top \
  -o ions.tpr
```

Check:

```bash
ls -lh ions.tpr
```

A nonzero total charge before neutralization can be normal.

---

# 11. Add ions

A common setup is to neutralize the system and add a chosen salt concentration.

Example for 0.15 M NaCl:

```bash
echo "SOL" | gmx_mpi genion \
  -s ions.tpr \
  -o model_solv_ions.gro \
  -p topol.top \
  -pname NA \
  -nname CL \
  -neutral \
  -conc 0.15
```

The solvent group may not always be named `SOL`; verify the group name in your system.

Check:

```bash
ls -lh model_solv_ions.gro topol.top
tail -n 20 topol.top
```

The salt concentration, ion types, and neutralization strategy are project-dependent.

---

# 12. Energy minimization

Assume a validated minimization parameter file named:

```text
minim.mdp
```

Prepare the run input:

```bash
gmx_mpi grompp \
  -f minim.mdp \
  -c model_solv_ions.gro \
  -p topol.top \
  -o em.tpr
```

Run minimization:

```bash
gmx_mpi mdrun -deffnm em
```

Inspect:

```bash
grep -E "Potential Energy|Maximum force|Norm of force|converged|finished" em.log | tail -20
```

Do not proceed simply because the command finished. Confirm that the minimization behavior meets the criteria defined in your project.

---

# 13. Decide on replicate structure

Independent replicates are recommended when scientifically appropriate.

For three replicates:

```bash
mkdir -p production/rep1 production/rep2 production/rep3 production/logs
```

Copy shared files into each replicate:

```bash
for r in rep1 rep2 rep3; do
  cp em.gro "production/$r/"
  cp topol.top "production/$r/"
  cp *.itp "production/$r/" 2>/dev/null || true
done
```

If your project uses one replicate, a different number of replicates, or another directory structure, modify this section accordingly.

---

# 14. Prepare NVT equilibration

Use a validated NVT `.mdp` file, for example:

```text
nvt.mdp
```

For each replicate:

```bash
for r in rep1 rep2 rep3; do
  cd "production/$r"

  gmx_mpi grompp \
    -f ../../nvt.mdp \
    -c em.gro \
    -r em.gro \
    -p topol.top \
    -o nvt.tpr

  cd ../..
done
```

Independent replicates should use appropriately independent random seeds when velocity generation is enabled.

Do not reuse a seed strategy from another project without checking the `.mdp` settings.

---

# 15. Run NVT through SLURM

Long jobs should be submitted through SLURM rather than run on the login node.

Example array-job structure:

```bash
#!/bin/bash
#SBATCH --job-name=nvt_reps
#SBATCH --partition=compute
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --array=1-3
#SBATCH --output=logs/nvt_%A_%a.out
#SBATCH --error=logs/nvt_%A_%a.err

set -e

module purge
module load gcc
module load fftw
module load gromacs-gpu

REP=${SLURM_ARRAY_TASK_ID}
cd "rep${REP}"

gmx_mpi mdrun -deffnm nvt
```

Save this in the `production/` directory, for example as:

```text
nvt_array.sh
```

Before submitting, verify all resource requests against current Laguna policies.

Submit:

```bash
cd production
sbatch nvt_array.sh
```

Monitor:

```bash
squeue -u "$USER"
```

After the queue is empty, confirm that **all** replicates finished:

```bash
grep -i "Finished mdrun" rep1/nvt.log rep2/nvt.log rep3/nvt.log
```

Confirm the final coordinates and checkpoints exist:

```bash
ls -lh rep1/nvt.gro rep2/nvt.gro rep3/nvt.gro
ls -lh rep1/nvt.cpt rep2/nvt.cpt rep3/nvt.cpt
```

Search the SLURM and GROMACS logs for serious errors:

```bash
grep -iE \
"fatal error|segmentation fault|mpi_abort|nan detected|constraint error|too many lincs warnings|bond rotated more than" \
logs/nvt_*.out logs/nvt_*.err rep*/nvt.log 2>/dev/null
```

A clean run should show `Finished mdrun` for every replicate, expected output files should exist, and the serious-error search should not report unresolved failures.

Do not start NPT until NVT has been checked.

---

# 16. Prepare and run NPT equilibration

Use a validated NPT `.mdp` file, for example:

```text
npt.mdp
```

Prepare one NPT run input for each replicate:

```bash
cd "$WORK"

for r in rep1 rep2 rep3; do
  cd "production/$r"

  gmx_mpi grompp \
    -f ../../npt.mdp \
    -c nvt.gro \
    -r nvt.gro \
    -t nvt.cpt \
    -p topol.top \
    -o npt.tpr

  cd ../..
done
```

Confirm all run inputs were created:

```bash
ls -lh production/rep1/npt.tpr \
       production/rep2/npt.tpr \
       production/rep3/npt.tpr
```

## NPT SLURM array example

Create a reusable SLURM script in the `production/` directory, for example:

```text
npt_array.sh
```

Example:

```bash
#!/bin/bash
#SBATCH --job-name=npt_reps
#SBATCH --partition=compute
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --array=1-3
#SBATCH --output=logs/npt_%A_%a.out
#SBATCH --error=logs/npt_%A_%a.err

set -e

module purge
module load gcc
module load fftw
module load gromacs-gpu

REP=${SLURM_ARRAY_TASK_ID}
REP_DIR="rep${REP}"

cd "$REP_DIR"

gmx_mpi mdrun -deffnm npt
```

The resource requests above are examples only. Verify the current Laguna partition, CPU, memory, module, and wall-time requirements before use.

Submit from the `production/` directory:

```bash
cd "$WORK/production"
sbatch npt_array.sh
```

Monitor:

```bash
squeue -u "$USER"
```

After the queue is empty, confirm completion:

```bash
grep -i "Finished mdrun" rep1/npt.log rep2/npt.log rep3/npt.log
```

Confirm final coordinates and checkpoints:

```bash
ls -lh rep1/npt.gro rep2/npt.gro rep3/npt.gro
ls -lh rep1/npt.cpt rep2/npt.cpt rep3/npt.cpt
```

Search for serious errors:

```bash
grep -iE \
"fatal error|segmentation fault|mpi_abort|nan detected|constraint error|too many lincs warnings|bond rotated more than" \
logs/npt_*.out logs/npt_*.err rep*/npt.log 2>/dev/null
```

Do not proceed to production MD until all intended NPT replicates have completed and the equilibration behavior has been reviewed.

---

# 17. Prepare production MD

Use a validated production parameter file, for example:

```text
md.mdp
```

The production duration is controlled primarily by `dt` and `nsteps` in the `.mdp` file:

```text
simulation time = dt × nsteps
```

Do not assume that 300 ns is appropriate for every project.

For each replicate:

```bash
cd "$WORK"

for r in rep1 rep2 rep3; do
  cd "production/$r"

  gmx_mpi grompp \
    -f ../../md.mdp \
    -c npt.gro \
    -t npt.cpt \
    -p topol.top \
    -o md.tpr

  cd ../..
done
```

Check:

```bash
ls -lh production/rep1/md.tpr \
       production/rep2/md.tpr \
       production/rep3/md.tpr
```

---

# 18. Production MD SLURM example

The following is a **template**, not a universal Laguna resource request.

Verify the current GPU partition, GPU resource syntax, wall-time limit, CPU count, and memory request before use.

```bash
#!/bin/bash
#SBATCH --job-name=md_reps
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --gres=gpu:1
#SBATCH --mem=48G
#SBATCH --time=1-00:00:00
#SBATCH --array=1-3
#SBATCH --output=logs/md_%A_%a.out
#SBATCH --error=logs/md_%A_%a.err

set -e

module purge
module load gcc
module load fftw
module load gromacs-gpu

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

REP=${SLURM_ARRAY_TASK_ID}
REP_DIR="rep${REP}"

cd "$REP_DIR"

gmx_mpi mdrun \
  -s md.tpr \
  -deffnm md \
  -ntomp "$OMP_NUM_THREADS"
```

Save as:

```text
md_array.sh
```

Then submit from the `production/` directory:

```bash
sbatch md_array.sh
```

Monitor:

```bash
squeue -u "$USER"
```

---

# 19. Optional production smoke test through SLURM

Before launching a long production simulation, it can be useful to confirm that the production input starts correctly on the intended compute resources.

Do not run the smoke test as a long interactive calculation on the login node. Use SLURM.

Create a script in the `production/` directory, for example:

```text
md_smoke_array.sh
```

Example:

```bash
#!/bin/bash
#SBATCH --job-name=md_smoke
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --gres=gpu:1
#SBATCH --mem=48G
#SBATCH --time=00:30:00
#SBATCH --array=1-3
#SBATCH --output=logs/md_smoke_%A_%a.out
#SBATCH --error=logs/md_smoke_%A_%a.err

set -e

module purge
module load gcc
module load fftw
module load gromacs-gpu

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

REP=${SLURM_ARRAY_TASK_ID}
REP_DIR="rep${REP}"

cd "$REP_DIR"

gmx_mpi mdrun \
  -s md.tpr \
  -deffnm md_smoke \
  -ntomp "$OMP_NUM_THREADS" \
  -nsteps 1000
```

The GPU, CPU, memory, and wall-time requests above are examples. Verify the current Laguna configuration first.

Submit from `production/`:

```bash
cd "$WORK/production"
sbatch md_smoke_array.sh
```

Monitor:

```bash
squeue -u "$USER"
```

After the queue is empty, confirm all intended smoke tests finished:

```bash
grep -i "Finished mdrun" \
  rep1/md_smoke.log \
  rep2/md_smoke.log \
  rep3/md_smoke.log
```

Check generated files:

```bash
ls -lh rep1/md_smoke.* rep2/md_smoke.* rep3/md_smoke.*
```

Search for serious errors, including GPU-related failures:

```bash
grep -iE \
"fatal error|segmentation fault|mpi_abort|nan detected|constraint error|too many lincs warnings|bond rotated more than|cuda|gpu" \
logs/md_smoke_*.out logs/md_smoke_*.err rep*/md_smoke.log 2>/dev/null
```

A successful smoke test confirms that the job can start with the selected input and resources. It does **not** prove that the full production trajectory will remain stable or scientifically valid.

The smoke-test output is separate from the real production output because it uses the `md_smoke` prefix.

---

# 20. Monitor production runs

Useful commands:

```bash
squeue -u "$USER"
```

Check log completion:

```bash
grep -i "Finished mdrun" production/rep*/md.log
```

Search for serious errors:

```bash
grep -iE \
"fatal error|segmentation fault|mpi_abort|nan detected|constraint error|too many lincs warnings|bond rotated more than|cuda|gpu" \
production/logs/* production/rep*/md.log 2>/dev/null
```

Do not assume that an empty SLURM queue means the simulation completed successfully. Always inspect the GROMACS and SLURM logs.

---

# 21. Restart an interrupted production run

If a run stopped but produced a valid checkpoint file, it can usually be resumed from that checkpoint.

Example:

```bash
gmx_mpi mdrun \
  -s md.tpr \
  -deffnm md \
  -cpi md.cpt \
  -append
```

This resumes the simulation toward the endpoint already encoded in `md.tpr`.

It does **not** automatically extend the simulation beyond the end time contained in the existing run input.

For continuation on Laguna, submit the restart command through SLURM rather than running a long continuation on the login node.

---

# 22. Extending a completed simulation

Extending a simulation beyond the endpoint encoded in the original `.tpr` requires creating an extended run input.

One GROMACS approach is:

```bash
gmx_mpi convert-tpr \
  -s md.tpr \
  -extend ADDITIONAL_TIME_PS \
  -o md_extended.tpr
```

Then run from the latest checkpoint:

```bash
gmx_mpi mdrun \
  -s md_extended.tpr \
  -deffnm md \
  -cpi md.cpt \
  -append
```

Choose the extension length based on the scientific question, not simply because more simulation time is available.

---

# 23. Minimum completion checks

Before treating a run as complete, verify at minimum:

```bash
ls -lh md.tpr md.log md.edr md.xtc md.gro
```

Then check:

```bash
grep -i "Finished mdrun" md.log
```

Also inspect the trajectory and thermodynamic outputs for stability and physical plausibility.

A completed GROMACS process is not, by itself, evidence that the simulation is scientifically valid.

---

# 24. Common problems

## `gmx_mpi` is not found

Check modules:

```bash
module avail gromacs
module list
which gmx_mpi
```

Do not hard-code an old GROMACS installation path unless you have confirmed that it is still valid.

## `grompp` fails

Read the full fatal error. Common causes include:

- missing topology includes;
- missing position-restraint files;
- atom-count mismatch;
- incompatible coordinates and topology;
- unsupported residues or ligands;
- incorrect file paths.

Do not use `-maxwarn` simply to bypass an error unless you understand and accept the warning.

## SLURM job exits immediately

Inspect:

```bash
cat logs/*.err
cat logs/*.out
```

Then check module loading, paths, filenames, permissions, and requested resources.

## GPU job fails

Verify:

- current Laguna GPU partition;
- current `--gres` syntax;
- GPU availability;
- GROMACS GPU-enabled build;
- SLURM error output.

---

# 25. What should be project-specific

The following should **not** be copied blindly from another MD project:

- force field;
- water model;
- protonation states;
- treatment of disulfide bonds;
- ligand or cofactor parameters;
- box geometry and padding;
- ion identity and concentration;
- minimization criteria;
- thermostats and barostats;
- temperature and pressure;
- restraints;
- timestep;
- equilibration length;
- production length;
- number of replicates;
- random seeds;
- trajectory output frequency;
- GPU/CPU/memory requests;
- wall time;
- analysis strategy.

Document these choices for each project.

---

# 26. Recommended directory structure

One reusable layout is:

```text
your_system_MD/
├── model.pdb
├── model_processed.gro
├── model_newbox.gro
├── model_solv.gro
├── model_solv_ions.gro
├── topol.top
├── *.itp
├── ions.mdp
├── minim.mdp
├── nvt.mdp
├── npt.mdp
├── md.mdp
├── em.*
└── production/
    ├── logs/
    ├── nvt_array.sh
    ├── md_array.sh
    ├── rep1/
    ├── rep2/
    └── rep3/
```

Adapt this structure as needed.

---

# 27. Final checklist

Before production MD:

```text
[ ] Starting structure inspected
[ ] MDP files reviewed and intended run lengths/settings confirmed
[ ] Protonation states considered
[ ] Force field selected appropriately
[ ] Water model selected appropriately
[ ] Topology generated without unresolved errors
[ ] System boxed and solvated
[ ] Ions added as intended
[ ] Energy minimization completed and inspected
[ ] NVT completed, output files present, and logs checked for serious errors
[ ] NPT completed, output files present, and logs checked for serious errors
[ ] Production .tpr generated
[ ] SLURM resources verified against current Laguna configuration
[ ] Production command smoke-tested through SLURM if appropriate
```

During and after production:

```text
[ ] SLURM jobs monitored
[ ] GROMACS logs inspected
[ ] Checkpoints preserved
[ ] Completion confirmed
[ ] Thermodynamic behavior reviewed
[ ] Trajectory integrity checked
[ ] Analysis performed using a documented protocol
```

---

## Relationship to the other protocol in this repository

If your system was prepared with **CHARMM-GUI**, use the repository's CHARMM-GUI → GROMACS → Laguna workflow as the primary guide.

Use this protocol when you need the more general **starting structure → GROMACS preparation → Laguna → SLURM** path.

The historical intern protocol may also be retained in this repository as a reference example from a completed project, but its usernames, paths, systems, protonation choices, simulation duration, replicate design, and resource requests are project-specific and should not be copied blindly.
