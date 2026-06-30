# Trillium
Large parallel cluster built by Lenovo Canada and hosted by SciNet at the University of Toronto.

* /home – For personal files and configurations.
* /scratch – High-speed, temporary storage for job data.
* /project – Shared storage for project teams and collaborations.

```bash
# Entrar no sistema
ssh -i ~/.ssh/ssh_key lusaro@trillium.alliancecan.ca

# Copiar arquivos do sistema para o computador local
scp -i ~/.ssh/ssh_key lusaro@trillium.alliancecan.ca:/scratch/lusaro/arquivo .
    #-r se for pasta
```

Trillium uses the environment modules system to manage compilers, libraries, and other software packages
```bash
module load <module-name> #Load the default version of a software package.
module purge              #Unload all currently loaded modules.
module avail              #List available modules that can be loaded.
module list               #Show currently loaded modules.
module spider             #Search for available modules and their versions.
```

Script basico para submeter Job:
```bash
#!/bin/sh
#SBATCH -J NOME_DO_JOB
#SBATCH --time=3:00:00
#SBATCH --ntasks-per-node=40
#SBATCH --nodes=1

cd $SLURM_SUBMIT_DIR

module load CCEnv nixpkgs/16.09

parallel -j $SLURM_TASKS_PER_NODE <<EOF #opcional. Apenas para scripts em paralelo

<commands>

EOF
```
