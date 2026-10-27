# Summer Intern MD Runs on Laguna — Dummy-Proof Intern README

**Project:** Antibody–peptide molecular dynamics simulations  
**System:** GROMACS on Laguna HPC  
**Prepared for:** Jie and Junhong  
**Prepared by:** Peace Olatoyinbo  

---

## Read this first

This README is the **intern-specific operating protocol** for the summer MD runs.

Use this README instead of the older general MD README when running the assigned intern complexes. The older README is useful for background, but this one contains the exact folder structure, assigned complexes, and copy/paste-safe commands for the intern workflow.

### Main rule

**One complex = one folder.**

Do not run two complexes in the same folder because files like `model.pdb`, `topol.top`, `300ns/`, `rep1/`, `rep2/`, and `rep3/` will overwrite each other.

### Do not work in this folder

```bash
/project/animesh_ray_1465/Peace_MD/antibody_antigen_MDs
```

That folder contains completed/ongoing thesis MD simulations.

### Work only here

```bash
/project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs
```

Folder structure:

```text
summer_intern_MD_runs/
├── assigned_pdbs/          # assigned PDB files are stored here
├── shared_templates/       # shared .mdp and .sh template files are stored here
├── jie/                    # Jie’s run folders go here
├── junhong/                # Junhong’s run folders go here
├── assigned_complexes.txt
└── INTERN_PROTOCOL.md
```

The `jie` and `junhong` folders already exist. Do not recreate them.  
For each complex, create a **complex-specific folder inside your assigned student folder**.

---

# Assigned complexes

## Demo complex for Peace’s live teaching

```text
ct5811-pep3_dk6-model0.pdb
```

This is a demo/practice complex. It is **not** part of the final six assigned complexes unless Peace says otherwise.

## Jie’s assigned complexes

```text
ct5811-pep3_dk8-model0.pdb
ct6350-pep6_dkS-model0.pdb
ct7152-pep7_dk8-model0.pdb
```

## Junhong’s assigned complexes

```text
ct6341-pep6_dk8-model0.pdb
ct6475-pep4_dkS-model0.pdb
ct7290-pep7_dkS-model0.pdb
```

---

# How to use this README

Only copy terminal commands from code blocks.

Do **not** paste explanation text, expected output, or headings into the terminal.

Every command section is labeled **COPY/PASTE**.

When a section says **Check**, read it only. Do not paste it.

---

# Section A — Peace’s live demo protocol

Use this section only for the teaching/demo complex:

```text
ct5811-pep3_dk6-model0.pdb
```

The demo folder will be:

```bash
/project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs/jie/demo_ct5811-pep3_dk6-model0_MD
```

---

## Demo Step 1 — Log in to Laguna

Purpose: enter the Laguna HPC environment.

COPY/PASTE from your local terminal:

```bash
ssh polatoyinbo21@kgi.edu@laguna.usc.edu
```

After logging in, COPY/PASTE:

```bash
hostname
whoami
pwd
squeue -u "polatoyinbo21@kgi.edu"
```

Check:

- `hostname` should show a Laguna login node.
- `whoami` should show Peace’s account.
- `squeue` should be empty before starting a demo.

---

## Demo Step 2 — Create a clean demo folder and copy files

Purpose: create one clean folder for the demo complex and copy the assigned PDB plus shared templates.

COPY/PASTE:

```bash
cd /project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs/jie

rm -rf demo_ct5811-pep3_dk6-model0_MD

BASE=/project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs
STUDENT=jie
PDB=ct5811-pep3_dk6-model0.pdb
RUN=demo_ct5811-pep3_dk6-model0
WORK="${BASE}/${STUDENT}/${RUN}_MD"

echo "BASE=$BASE"
echo "STUDENT=$STUDENT"
echo "PDB=$PDB"
echo "RUN=$RUN"
echo "WORK=$WORK"

mkdir -p "$WORK"
cd "$WORK"

cp "$BASE/assigned_pdbs/$PDB" model.pdb
cp "$BASE/shared_templates/"*.mdp .
cp "$BASE/shared_templates/"*.sh .

cat > run_env.sh <<EOF
BASE=$BASE
STUDENT=$STUDENT
PDB=$PDB
RUN=$RUN
WORK=$WORK
EOF

pwd
ls -lh
```

Check:

`pwd` should show:

```bash
/project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs/jie/demo_ct5811-pep3_dk6-model0_MD
```

The folder should contain:

```text
model.pdb
ions.mdp
minim.mdp
nvt_template.mdp
npt.mdp
md.mdp
nvt_reps.sh
md_300ns_array.sh
run_env.sh
```

---

## Demo Step 3 — Confirm chain A peptide sequence

Purpose: confirm that chain A is the expected peptide6 sequence.

COPY/PASTE:

```bash
source run_env.sh

python3 - <<'PY'
res3 = {
    "ALA":"A","ARG":"R","ASN":"N","ASP":"D","CYS":"C",
    "GLN":"Q","GLU":"E","GLY":"G","HIS":"H","ILE":"I",
    "LEU":"L","LYS":"K","MET":"M","PHE":"F","PRO":"P",
    "SER":"S","THR":"T","TRP":"W","TYR":"Y","VAL":"V"
}

seq = []
seen = set()

with open("model.pdb") as f:
    for line in f:
        if line.startswith("ATOM") and line[21] == "A" and line[12:16].strip() == "CA":
            resname = line[17:20].strip()
            resid = line[22:26].strip()
            icode = line[26].strip()
            key = (resid, icode)
            if key not in seen:
                seen.add(key)
                seq.append(res3.get(resname, "X"))

sequence = "".join(seq)
expected = "SYECDIPIGAGICASYQTQTNSPRRARSVASQSIIAYTMSLGAENSVAYS"

print("CHAIN A length:", len(seq))
print("CHAIN A sequence:", sequence)

if sequence == expected:
    print("MATCH: peptide6")
    print("STATUS: OK - chain A is peptide6")
else:
    print("STATUS: CHECK - sequence does not match expected peptide6")
PY
```

Check:

Expected output should include:

```text
CHAIN A length: 50
MATCH: peptide6
STATUS: OK - chain A is peptide6
```

If it does not match, stop and ask Peace.

---

## Demo Step 4 — Load required modules

Purpose: load GROMACS and Python.

COPY/PASTE:

```bash
module purge
module load gcc
module load fftw
module load gromacs-gpu
module load python/3.10.16

which gmx_mpi
gmx_mpi --version | head
python3 --version
```

Check:

Expected GROMACS version:

```text
GROMACS 2024.3
```

Expected Python version:

```text
Python 3.10.16
```

---

## Demo Step 5 — Check MDP settings

Purpose: confirm that the `.mdp` files match the validated 300 ns workflow.

COPY/PASTE:

```bash
echo "===== md.mdp ====="
grep -E "nsteps|dt|pcoupl|tau_p|continuation|gen_vel" md.mdp

echo "===== nvt_template.mdp ====="
grep -E "nsteps|dt|continuation|pcoupl|gen_vel|gen_seed|ld_seed" nvt_template.mdp

echo "===== npt.mdp ====="
grep -E "nsteps|dt|pcoupl|tau_p|gen_vel|continuation" npt.mdp
```

Check:

The production `md.mdp` should include:

```text
nsteps = 150000000
dt = 0.002
continuation = yes
gen_vel = no
```

This corresponds to 300 ns.

---

## Demo Step 6 — Run PROPKA

Purpose: estimate pKa values, especially for histidines.

COPY/PASTE:

```bash
python3 -m propka model.pdb -o 7.4

ls -lh model.pka
grep -i HIS model.pka
```

Check:

For the demo complex, histidines should have pKa values below 7.4, so they are neutral at pH 7.4.

If unsure, ask Peace before continuing.

---

## Demo Step 7 — Run pdb2gmx

Purpose: generate GROMACS coordinate and topology files.

COPY/PASTE:

```bash
gmx_mpi pdb2gmx -f model.pdb -o model_processed.gro -ignh -inter -ff amber99sb-ildn -water tip3p
```

When prompted, enter these choices manually:

```text
ASP: 0
GLU: 0
GLN: 0
LYS: 1
ARG: 1
HIS: 1
```

For the cysteine/disulfide prompt, enter:

```text
y
```

Then COPY/PASTE:

```bash
ls -lh model_processed.gro topol.top topol_Protein_chain_*.itp posre_Protein_chain_*.itp
```

Check:

Expected files include:

```text
model_processed.gro
topol.top
topol_Protein_chain_A.itp
topol_Protein_chain_H.itp
topol_Protein_chain_L.itp
posre_Protein_chain_A.itp
posre_Protein_chain_H.itp
posre_Protein_chain_L.itp
```

---

## Demo Step 8 — Create simulation box

Purpose: center the complex in a cubic simulation box.

COPY/PASTE:

```bash
gmx_mpi editconf -f model_processed.gro -o model_newbox.gro -c -d 1.0 -bt cubic

ls -lh model_newbox.gro
```

Check:

Expected file:

```text
model_newbox.gro
```

---

## Demo Step 9 — Solvate

Purpose: fill the box with water and update `topol.top`.

COPY/PASTE:

```bash
gmx_mpi solvate -cp model_newbox.gro -cs spc216.gro -o model_solv.gro -p topol.top

ls -lh model_solv.gro topol.top
grep SOL topol.top
```

Check:

Expected output should include a `SOL` line in `topol.top`.

---

## Demo Step 10 — Prepare ions

Purpose: create the `ions.tpr` file needed for ion replacement.

COPY/PASTE:

```bash
gmx_mpi grompp -f ions.mdp -c model_solv.gro -p topol.top -o ions.tpr

ls -lh ions.tpr
```

Check:

Expected file:

```text
ions.tpr
```

A note about nonzero system charge is normal at this stage.

---

## Demo Step 11 — Add ions and 0.15 M salt

Purpose: neutralize the system and add 0.15 M NaCl.

COPY/PASTE:

```bash
echo "SOL" | gmx_mpi genion -s ions.tpr -o model_solv_ions.gro -p topol.top -pname NA -nname CL -neutral -conc 0.15

ls -lh model_solv_ions.gro topol.top
grep -E "SOL|NA|CL" topol.top
```

Check:

For the demo, the dry run gave approximately:

```text
SOL 17252
NA 51
CL 54
```

Because the system charge was `+3`, the check was:

```text
CL = NA + 3
```

---

## Demo Step 12 — Prepare energy minimization

Purpose: create the `em.tpr` file for energy minimization.

COPY/PASTE:

```bash
gmx_mpi grompp -f minim.mdp -c model_solv_ions.gro -p topol.top -o em.tpr

ls -lh em.tpr
```

Check:

Expected file:

```text
em.tpr
```

---

## Demo Step 13 — Run energy minimization

Purpose: relax bad contacts before dynamics.

COPY/PASTE:

```bash
gmx_mpi mdrun -deffnm em

ls -lh em.gro em.edr em.log em.tpr em.trr

grep -E "Potential Energy|Maximum force|Norm of force|converged|finished" em.log | tail -20
```

Check:

Expected:

```text
Steepest Descents converged to Fmax < 1000
Maximum force < 1000
```

If maximum force is above 1000 or minimization fails, stop and ask Peace.

---

## Demo Step 14 — Set up 300 ns replicate folders

Purpose: create `rep1`, `rep2`, and `rep3` folders for triplicate MD.

COPY/PASTE:

```bash
source run_env.sh

rm -rf 300ns

mkdir -p 300ns/rep1 300ns/rep2 300ns/rep3 300ns/logs

cp em.gro topol.top nvt_template.mdp npt.mdp md.mdp nvt_reps.sh md_300ns_array.sh 300ns/
cp topol_Protein_chain_*.itp posre_Protein_chain_*.itp 300ns/

for r in rep1 rep2 rep3; do
  cp em.gro 300ns/$r/
  cp topol.top 300ns/$r/
  cp npt.mdp 300ns/$r/
  cp md.mdp 300ns/$r/
  cp topol_Protein_chain_*.itp 300ns/$r/
  cp posre_Protein_chain_*.itp 300ns/$r/
done

ls -lh 300ns
ls -lh 300ns/rep1
```

Check:

Expected folders:

```text
300ns/
300ns/rep1/
300ns/rep2/
300ns/rep3/
300ns/logs/
```

---

## Demo Step 15 — Inspect NVT script

Purpose: confirm NVT will run as three independent replicates.

COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

pwd

grep -nE "SBATCH|module|SEED|GEN_SEED|LD_SEED|rep|grompp|mdrun|deffnm|cd " nvt_reps.sh
```

Check:

Expected important parts:

```text
#SBATCH --array=1-3
GEN_SEED
LD_SEED
grompp
mdrun
```

---

## Demo Step 16 — Submit NVT

Purpose: run temperature equilibration for all three replicates.

COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

chmod +x nvt_reps.sh md_300ns_array.sh

squeue -u "polatoyinbo21@kgi.edu"

sbatch nvt_reps.sh

squeue -u "polatoyinbo21@kgi.edu"
```

Check:

Three NVT array jobs should appear. Wait until the queue is empty before moving on.

---

## Demo Step 17 — Check NVT results

Purpose: confirm all three NVT replicates finished cleanly.

COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

grep -i "Finished mdrun" rep1/nvt.log rep2/nvt.log rep3/nvt.log

ls -lh rep1/nvt.gro rep2/nvt.gro rep3/nvt.gro

ls -lh rep1/nvt.cpt rep2/nvt.cpt rep3/nvt.cpt

grep -iE "fatal error|segmentation fault|mpi_abort|nan detected|constraint error|too many lincs warnings|bond rotated more than" logs/nvt_reps_*.out rep*/nvt.log 2>/dev/null
```

Check:

All three logs should show `Finished mdrun`.

The serious-error check should print nothing.

---

## Demo Step 18 — Prepare NPT

Purpose: prepare pressure equilibration input files.

COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

module purge
module load gcc
module load fftw
module load gromacs-gpu

for r in rep1 rep2 rep3; do
  echo "Preparing NPT for $r"
  cd $r
  gmx_mpi grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
  cd ..
done

ls -lh rep1/npt.tpr rep2/npt.tpr rep3/npt.tpr
```

Check:

Expected files:

```text
rep1/npt.tpr
rep2/npt.tpr
rep3/npt.tpr
```

---

## Demo Step 19 — Submit NPT

Purpose: run pressure equilibration for all three replicates.

COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

sbatch \
  --job-name=npt_demo_ct5811 \
  --partition=compute \
  --ntasks=1 \
  --cpus-per-task=8 \
  --mem=24G \
  --time=04:00:00 \
  --array=1-3 \
  --output=logs/npt_demo_ct5811_%A_%a.out \
  --error=logs/npt_demo_ct5811_%A_%a.err \
  --wrap="module purge; module load gcc; module load fftw; module load gromacs-gpu; cd ${WORK}/300ns/rep\${SLURM_ARRAY_TASK_ID}; gmx_mpi mdrun -deffnm npt"

squeue -u "polatoyinbo21@kgi.edu"
```

Check:

Three NPT array jobs should appear. Wait until the queue is empty before checking results.

---

## Demo Step 20 — Check NPT results

Purpose: confirm all three NPT replicates finished cleanly.

COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

grep -i "Finished mdrun" rep1/npt.log rep2/npt.log rep3/npt.log

ls -lh rep1/npt.gro rep2/npt.gro rep3/npt.gro

ls -lh rep1/npt.cpt rep2/npt.cpt rep3/npt.cpt

grep -iE "fatal error|segmentation fault|mpi_abort|nan detected|constraint error|too many lincs warnings|bond rotated more than" logs/npt_demo_ct5811_*.err rep*/npt.log 2>/dev/null
```

Check:

All three logs should show `Finished mdrun`.

The serious-error check should print nothing.

---

## Demo Step 21 — Prepare production MD files

Purpose: create final `md.tpr` files for 300 ns production MD.

COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

module purge
module load gcc
module load fftw
module load gromacs-gpu

for r in rep1 rep2 rep3; do
  echo "Preparing production MD for $r"
  cd $r
  gmx_mpi grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md.tpr
  cd ..
done

ls -lh rep1/md.tpr rep2/md.tpr rep3/md.tpr
```

Check:

Expected files:

```text
rep1/md.tpr
rep2/md.tpr
rep3/md.tpr
```

---

## Demo Step 22 — Inspect production script

Purpose: confirm the production script is correct before launching a long GPU job.

COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

grep -nE "SBATCH|module|OMP_NUM_THREADS|REP_DIR|SLURM_ARRAY_TASK_ID|cd |gmx_mpi|deffnm|gpu_id|mdrun" md_300ns_array.sh
```

Check:

Expected important parts:

```text
#SBATCH --partition=gpu
#SBATCH --gres=gpu:l40s:1
#SBATCH --array=1-3
cd ${REP_DIR}
gmx_mpi mdrun -s md.tpr -deffnm md_300ns
```

---

## Demo Step 23 — Optional smoke test

Purpose: test production startup without running full 300 ns.

COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

cp md_300ns_array.sh md_smoke_array.sh

sed -i 's/#SBATCH --job-name=md_300ns_reps/#SBATCH --job-name=md_smoke_test/' md_smoke_array.sh
sed -i 's/#SBATCH --time=7-00:00:00/#SBATCH --time=00:30:00/' md_smoke_array.sh
sed -i 's/md_300ns_reps/md_smoke_test/g' md_smoke_array.sh
sed -i 's/gmx_mpi mdrun -s md.tpr -deffnm md_300ns -ntomp $OMP_NUM_THREADS -gpu_id 0/gmx_mpi mdrun -s md.tpr -deffnm md_smoke -ntomp $OMP_NUM_THREADS -gpu_id 0 -nsteps 1000/' md_smoke_array.sh

grep -nE "SBATCH|mdrun|deffnm|nsteps|gpu_id|array|time|job-name|output|error" md_smoke_array.sh
```

Then COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

sbatch md_smoke_array.sh

squeue -u "polatoyinbo21@kgi.edu"
```

After queue is empty, COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

grep -i "Finished mdrun" rep1/md_smoke.log rep2/md_smoke.log rep3/md_smoke.log

ls -lh rep1/md_smoke.* rep2/md_smoke.* rep3/md_smoke.*

grep -iE "fatal error|segmentation fault|mpi_abort|nan detected|constraint error|too many lincs warnings|bond rotated more than|cuda|gpu" logs/md_smoke_test_*.err rep*/md_smoke.log 2>/dev/null
```

Check:

All three `md_smoke.log` files should show `Finished mdrun`.

---

## Demo Step 24 — Full 300 ns production submission

Purpose: submit the actual long production MD. Only run this if you want the demo complex to run fully.

COPY/PASTE:

```bash
source run_env.sh
cd "$WORK/300ns"

squeue -u "polatoyinbo21@kgi.edu"

sbatch md_300ns_array.sh

squeue -u "polatoyinbo21@kgi.edu"
```

Check:

Three GPU jobs should appear. This may run for days.

---

## Demo Step 25 — Cleanup demo folder after teaching

Purpose: remove demo files after teaching.

First COPY/PASTE:

```bash
squeue -u "polatoyinbo21@kgi.edu"
```

If no demo jobs are running, COPY/PASTE:

```bash
cd /project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs/jie

rm -rf demo_ct5811-pep3_dk6-model0_MD

ls -lh
```

Check:

The demo folder should be gone.

---

# Section B — Student actual run protocol

This section is for Jie and Junhong’s real assigned complexes.

Students should not create new `jie` or `junhong` folders. Those already exist.

Each complex gets its own folder inside the assigned student folder.

---

## Student Step 1 — Log in to Laguna

COPY/PASTE:

```bash
ssh YOUR_LAGUNA_USERNAME@laguna.usc.edu
```

Then COPY/PASTE:

```bash
hostname
whoami
pwd
groups
squeue -u "$USER"
```

Check:

`groups` should include:

```text
animesh_ray_1465
```

If it does not, the student may not have access to the project folder.

---

## Student Step 2 — Choose one assigned complex

Only paste the block for the complex being run.

### Jie complex 1

COPY/PASTE:

```bash
BASE=/project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs
STUDENT=jie
PDB=ct5811-pep3_dk8-model0.pdb
RUN=ct5811-pep3_dk8-model0
WORK="${BASE}/${STUDENT}/${RUN}_MD"

echo "BASE=$BASE"
echo "STUDENT=$STUDENT"
echo "PDB=$PDB"
echo "RUN=$RUN"
echo "WORK=$WORK"
```

### Jie complex 2

COPY/PASTE:

```bash
BASE=/project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs
STUDENT=jie
PDB=ct6350-pep6_dkS-model0.pdb
RUN=ct6350-pep6_dkS-model0
WORK="${BASE}/${STUDENT}/${RUN}_MD"

echo "BASE=$BASE"
echo "STUDENT=$STUDENT"
echo "PDB=$PDB"
echo "RUN=$RUN"
echo "WORK=$WORK"
```

### Jie complex 3

COPY/PASTE:

```bash
BASE=/project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs
STUDENT=jie
PDB=ct7152-pep7_dk8-model0.pdb
RUN=ct7152-pep7_dk8-model0
WORK="${BASE}/${STUDENT}/${RUN}_MD"

echo "BASE=$BASE"
echo "STUDENT=$STUDENT"
echo "PDB=$PDB"
echo "RUN=$RUN"
echo "WORK=$WORK"
```

### Junhong complex 1

COPY/PASTE:

```bash
BASE=/project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs
STUDENT=junhong
PDB=ct6341-pep6_dk8-model0.pdb
RUN=ct6341-pep6_dk8-model0
WORK="${BASE}/${STUDENT}/${RUN}_MD"

echo "BASE=$BASE"
echo "STUDENT=$STUDENT"
echo "PDB=$PDB"
echo "RUN=$RUN"
echo "WORK=$WORK"
```

### Junhong complex 2

COPY/PASTE:

```bash
BASE=/project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs
STUDENT=junhong
PDB=ct6475-pep4_dkS-model0.pdb
RUN=ct6475-pep4_dkS-model0
WORK="${BASE}/${STUDENT}/${RUN}_MD"

echo "BASE=$BASE"
echo "STUDENT=$STUDENT"
echo "PDB=$PDB"
echo "RUN=$RUN"
echo "WORK=$WORK"
```

### Junhong complex 3

COPY/PASTE:

```bash
BASE=/project/animesh_ray_1465/Peace_MD/summer_intern_MD_runs
STUDENT=junhong
PDB=ct7290-pep7_dkS-model0.pdb
RUN=ct7290-pep7_dkS-model0
WORK="${BASE}/${STUDENT}/${RUN}_MD"

echo "BASE=$BASE"
echo "STUDENT=$STUDENT"
echo "PDB=$PDB"
echo "RUN=$RUN"
echo "WORK=$WORK"
```

---

## Student Step 3 — Create complex folder and copy files

Purpose: create one clean folder for one assigned complex.

COPY/PASTE after choosing one setup block above:

```bash
if [ -z "$BASE" ] || [ -z "$STUDENT" ] || [ -z "$PDB" ] || [ -z "$RUN" ] || [ -z "$WORK" ]; then
  echo "ERROR: One or more variables are empty. Go back and paste the correct setup block."
  exit 1
fi

if [ ! -f "$BASE/assigned_pdbs/$PDB" ]; then
  echo "ERROR: Assigned PDB does not exist: $BASE/assigned_pdbs/$PDB"
  exit 1
fi

if [ -e "$WORK" ]; then
  echo "ERROR: Working folder already exists: $WORK"
  echo "Do not overwrite it. Ask Peace before continuing."
  exit 1
fi

mkdir -p "$WORK"
cd "$WORK"

cp "$BASE/assigned_pdbs/$PDB" model.pdb
cp "$BASE/shared_templates/"*.mdp .
cp "$BASE/shared_templates/"*.sh .

cat > run_env.sh <<EOF
BASE=$BASE
STUDENT=$STUDENT
PDB=$PDB
RUN=$RUN
WORK=$WORK
EOF

pwd
ls -lh
```

Check:

The folder should contain:

```text
model.pdb
ions.mdp
minim.mdp
nvt_template.mdp
npt.mdp
md.mdp
nvt_reps.sh
md_300ns_array.sh
run_env.sh
```

---

## Student Step 4 — Confirm chain A sequence

Purpose: confirm that chain A is the peptide/antigen.

COPY/PASTE:

```bash
source run_env.sh

python3 - <<'PY'
res3 = {
    "ALA":"A","ARG":"R","ASN":"N","ASP":"D","CYS":"C",
    "GLN":"Q","GLU":"E","GLY":"G","HIS":"H","ILE":"I",
    "LEU":"L","LYS":"K","MET":"M","PHE":"F","PRO":"P",
    "SER":"S","THR":"T","TRP":"W","TYR":"Y","VAL":"V"
}

seq = []
seen = set()

with open("model.pdb") as f:
    for line in f:
        if line.startswith("ATOM") and line[21] == "A" and line[12:16].strip() == "CA":
            resname = line[17:20].strip()
            resid = line[22:26].strip()
            icode = line[26].strip()
            key = (resid, icode)
            if key not in seen:
                seen.add(key)
                seq.append(res3.get(resname, "X"))

print("CHAIN A length:", len(seq))
print("CHAIN A sequence:", "".join(seq))
PY
```

Check:

Chain A should usually be about 50 amino acids.

If it is missing, length 0, or looks wrong, stop and ask Peace.

---

## Student Step 5 — Continue with the shared workflow

After Student Step 4, use the same workflow as Demo Steps 4–24:

```text
Demo Step 4 — Load modules
Demo Step 5 — Check MDP settings
Demo Step 6 — Run PROPKA
Demo Step 7 — Run pdb2gmx
Demo Step 8 — Create simulation box
Demo Step 9 — Solvate
Demo Step 10 — Prepare ions
Demo Step 11 — Add ions and 0.15 M salt
Demo Step 12 — Prepare energy minimization
Demo Step 13 — Run energy minimization
Demo Step 14 — Set up 300 ns replicate folders
Demo Step 15 — Inspect NVT script
Demo Step 16 — Submit NVT
Demo Step 17 — Check NVT results
Demo Step 18 — Prepare NPT
Demo Step 19 — Submit NPT
Demo Step 20 — Check NPT results
Demo Step 21 — Prepare production MD files
Demo Step 22 — Inspect production script
Demo Step 24 — Full 300 ns production submission
```

Students should skip the smoke test unless Peace asks for it.

---

## Student Step 6 — Report to Peace

Copy/paste this message and fill it in:

```text
Student name:
Complex/PDB:
Working folder:

Chain A length:
Chain A sequence:

Ion counts:
SOL =
NA =
CL =

Energy minimization:
Maximum force =
Converged? yes/no

NVT:
rep1 finished? yes/no
rep2 finished? yes/no
rep3 finished? yes/no

NPT:
rep1 finished? yes/no
rep2 finished? yes/no
rep3 finished? yes/no

Production:
Job ID:
Started? yes/no
Finished? yes/no
Any errors? yes/no
```

---

# Stop signs

Stop and ask Peace if any of these happen:

```text
You cannot access /project/animesh_ray_1465
The assigned PDB file is missing
The shared_templates folder is missing files
Chain A is missing or length 0
pdb2gmx fails
You are unsure about histidine protonation
You are unsure about cysteine/disulfide prompts
grompp gives a fatal error
Energy minimization does not converge
Maximum force is above 1000
NVT does not finish for all three replicates
NPT does not finish for all three replicates
Any serious-error grep prints fatal errors
You accidentally submit the same job twice
```

---

# Common mistakes to avoid

Do not paste expected outputs into the terminal.

Do not run:

```bash
./nvt_reps.sh
```

Do not run:

```bash
bash nvt_reps.sh
```

Use:

```bash
sbatch nvt_reps.sh
```

Do not run multiple complexes directly inside `jie/` or `junhong/`.

Do not work inside:

```bash
/project/animesh_ray_1465/Peace_MD/antibody_antigen_MDs
```

Do not rename `model.pdb` back to the long PDB name.

Do not delete outputs unless Peace tells you to.

Do not submit full production MD unless Peace confirms.
