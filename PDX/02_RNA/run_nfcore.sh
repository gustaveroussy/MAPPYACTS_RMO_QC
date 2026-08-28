#!/bin/bash

#SBATCH --job-name=pipeline_rnaseq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --partition longq
#SBATCH --output=job_%j.out
#SBATCH --error=job_%j.err

module load java
module load singularity
source /mnt/beegfs02/software/recherche/miniconda/25.1.1/etc/profile.d/conda.sh
conda activate /home/ma_bertrand/environnements_conda/oncoanalyser_utils

export NXF_SINGULARITY_CACHEDIR=/mnt/beegfs01/scratch/ma_bertrand/P025/RMO_RNA_PDX/containers

# https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_45/

nextflow run /home/ma_bertrand/pipelines/nf_core_rnaseq/3_12/main.nf -resume \
-w /mnt/beegfs01/scratch/ma_bertrand/tmp \
-c nextflow.config \
-profile singularity \
--save_reference \
--input 'samplesheet.csv' \
--outdir 'RMO_RNA_PDX' \
--fasta 'human_g1k_v37.fasta' \
--gtf 'gencode.v19.nochr.gtf' \
--aligner 'star_salmon' \
--save_reference \
--featurecounts_group_type 'gene_type' \
--gencode \
--skip_bbsplit  --remove_ribo_rna false --skip_bigwig --skip_deseq2_qc \
--rseqc_modules bam_stat,inner_distance,infer_experiment,junction_annotation,junction_saturation,read_distribution,read_duplication

conda deactivate
