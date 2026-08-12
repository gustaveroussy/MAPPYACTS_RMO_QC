#!/bin/bash

########################################################################
## Script to launch Xenome
## using: sbatch launch.sh
########################################################################

## JOB PARAMETERS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

#SBATCH --job-name=xenome
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --partition=longq
#SBATCH --output=job_%j.out
#SBATCH --error=job_%j.err

source /mnt/beegfs02/software/recherche/miniconda/25.1.1/etc/profile.d/conda.sh
conda activate environnements_conda/xenome_env
module load snakemake/7.32.4
export LD_LIBRARY_PATH=environnements_conda/xenome_env/lib:$LD_LIBRARY_PATH
export TMPDIR=ma_bertrand/tmp

#parameters
path_to_configfile="config_xenome.json"



#launch
snakemake --profile profiles/slurm \
-s pipelines/Xenome/snakefile \
--default-resources "tmpdir='ma_bertrand/tmp'" \
--configfile ${path_to_configfile}  \
--use-conda --jobs 15

conda deactivate

