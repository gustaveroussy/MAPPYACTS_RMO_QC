#!/bin/bash
#set -euo pipefail
##
## Author : Marine Aglave, adaptation MBE for specific reference
## Date : 2022, adaptation in 2026
## Organism : homo sapiens, mus musculus
## Build : GRCh38 (graft, Gencode v45), GRCm38 (host, Ensembl r99)
##
## Usage: sbatch PREPROC_create_gossamer_index.sh
##
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=35G
#SBATCH --partition=longq
#SBATCH --output=xenome_index_%j.out
#SBATCH --error=xenome_index_%j.err

### SCRIPT PARAMETERS TO CHANGE ########################################
INDEXDIR='/mnt/beegfs01/scratch/ma_bertrand/P025/RMO_WES_PDX'
NAME_INDEX='b37_human_g1k_GRCm38_ENSr99_DNA.idx'

# Graft: hg19 (same as for Sergey's pipeline)
GRAFT_FASTA='/mnt/beegfs01/scratch/ma_bertrand/PEDRESLIP/references/ref/human_g1k_v37.fasta'

# Host: to be downloaded from Ensembl (https more reliable than ftp on cluster)
WGET_HOST_FASTA='https://ftp.ensembl.org/pub/release-99/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz'

XENOME='/mnt/beegfs01/software_old_centos7/xenome/1.0.0_patched/gossamer-1.0.0/build/src/xenome'


source /mnt/beegfs02/software/recherche/miniconda/25.1.1/etc/profile.d/conda.sh
conda activate /home/ma_bertrand/environnements_conda/xenome_env/
export LD_LIBRARY_PATH=/home/ma_bertrand/environnements_conda/xenome_env/lib:$LD_LIBRARY_PATH
export TMPDIR=/mnt/beegfs01/scratch/ma_bertrand/tmp


### CODE ################################################################
echo "======================================================"
echo "Start: $(date)"
echo "Index dir: ${INDEXDIR}"
echo "Index name: ${NAME_INDEX}"
echo "Graft: ${GRAFT_FASTA}"
echo "Host: ${WGET_HOST_FASTA}"
echo "======================================================"

if [ ! -f "${GRAFT_FASTA}" ]; then
    echo "ERROR: Graft FASTA not found: ${GRAFT_FASTA}"
    exit 1
fi

mkdir -p "${INDEXDIR}"

if [ -e "${INDEXDIR}/${NAME_INDEX}-both.header" ]; then
    echo "ERROR: Index files already exist in ${INDEXDIR}. Remove them first if you want to rebuild."
    exit 1
fi

echo "Downloading host reference..."
wget "${WGET_HOST_FASTA}" -P "${INDEXDIR}"

HOST_FASTA="${INDEXDIR}/$(basename "${WGET_HOST_FASTA}")"

#echo "Adding 'chr' prefix to chromosomes..."
#HOST_FASTA_CHR="${INDEXDIR}/$(basename "${WGET_HOST_FASTA}" .fa.gz)_chr.fa.gz"
#zcat "${HOST_FASTA}" | sed 's/^>/>chr/' | gzip > "${HOST_FASTA_CHR}"
#rm "${HOST_FASTA}"
HOST_FASTA="${HOST_FASTA}"

echo "Building index..."
"${XENOME}" index \
    -M 32 \
    -T 8 \
    -P "${INDEXDIR}/${NAME_INDEX}" \
    -H "${HOST_FASTA}" \
    -G "${GRAFT_FASTA}"

echo "Index built in: ${INDEXDIR}/"

echo "Cleaning up..."
rm "${HOST_FASTA}"

echo "Done: $(date)"
