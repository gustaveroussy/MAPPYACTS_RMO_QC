#!/bin/bash

########################################################################
## Script to launch Mosdepth snakefile
## using: sbatch launch.sh
########################################################################

## JOB PARAMETERS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

#SBATCH --job-name=mosdepth
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --partition=mediumq
#SBATCH --output=job_%j.out
#SBATCH --error=job_%j.err



source /mnt/beegfs02/software/recherche/miniconda/25.1.1/etc/profile.d/conda.sh
conda activate /home/ma_bertrand/environnements_conda/mosdepth


path_to_configfile="config.yaml"
path_to_pipeline="/mnt/beegfs01/scratch/ma_bertrand/P025/MOSDEPTH"


snakemake --profile profiles/slurm \
-s ${path_to_pipeline}/snakefile \
--default-resources "tmpdir='/mnt/beegfs01/scratch/ma_bertrand/tmp'" \
--configfile ${path_to_configfile} \


conda deactivate
