#!/bin/bash

########################################################################
## Script to launch tin score computation 
## using: sbatch launch.sh
########################################################################

## JOB PARAMETERS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

#SBATCH --job-name=test
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --partition=mediumq
#SBATCH --output=job_%j.out
#SBATCH --error=job_%j.err

module load snakemake/7.32.4
source /mnt/beegfs02/software/recherche/miniconda/25.1.1/etc/profile.d/conda.sh
conda activate /home/ma_bertrand/environnements_conda/ngscheckmate


#parameters
path_to_configfile="config.yaml"


#launch
snakemake --profile /mnt/beegfs01/scratch/ma_bertrand/pipelines_save_bk/profiles/slurm \
-s snakefile.py \
--default-resources "tmpdir='/mnt/beegfs01/scratch/ma_bertrand/tmp'" \
--configfile ${path_to_configfile}   \
--jobs 12        

conda deactivate

