#!/usr/bin/env bash
#
# ==============================================================================
#  prepare_capture.sh
# ------------------------------------------------------------------------------
#  Author : MBE
#  Date   : 25/09/2026
#  Usage  : bash prepare_capture.sh
# ==============================================================================
#
#  Context
#  -------
#  One year after the first WES analysis, the PDX samples had to be run through
#  the same pipeline for comparison, but their capture BED files differ.
#
#  We therefore start from the BED file used for the first MAPPYACTS analysis
#  (coding regions shared by the capture kits) and intersect it with the PDX
#  capture BED files. The resulting BED will contain fewer regions: it keeps
#  only the regions present in both the patient kits and the PDX kits.
#
#  No need to rerun MAPPYACTS: just refilter its existing VCFs on this new BED
#  so both analyses cover the same regions.
#
#  Steps
#  -----
#   1. Download the CCDS annotations (hg19).
#   2. Convert them into an exon BED file and remove the "chr" prefix.
#   3. Sort the capture BED files.
#   4. Keep regions shared by the MAPPYACTS CCDS BED and the PDX SureSelect v2 BED.
#   5. Keep only the regions within CCDS exons.
#   6. Convert the result to a GATK IntervalList (for CollectHsMetrics).
#
# ==============================================================================


# ------------------------------------------------------------------------------
#  1. Download the CCDS annotations
# ------------------------------------------------------------------------------
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ccdsGene.txt.gz
zcat ccdsGene.txt.gz > ccdsGene.hg19.txt


# ------------------------------------------------------------------------------
#  2. Convert CCDS to an exon BED file (without "chr" prefix)
# ------------------------------------------------------------------------------
awk 'BEGIN{OFS="\t"} {
    split($10, exonStarts, ",");
    split($11, exonEnds, ",");
    for (i=1; i<=length(exonStarts); i++) {
        if (exonStarts[i] != "" && exonEnds[i] != "") {
            print $3, exonStarts[i]-1, exonEnds[i], $2, 0, $4
        }
    }
}' ccdsGene.hg19.txt > ccds_hg19.bed
sort -k1,1 -k2,2n ccds_hg19.bed > ccds_hg19_sorted.bed


# ------------------------------------------------------------------------------
#  3. Sort the capture BED files
# ------------------------------------------------------------------------------
module load bedtools/2.28.0

for file in 2191546/SureSelect_Clinical_Research_Exome_Regions_v2_noCHR.bed \
            captures_ccds_overlap.v37_nochr.bed; do
    grep -v -E '^(track|browser|#)' "$file" \
        | tr -d '\r' \
        | sort -k1,1 -k2,2n > "${file%.bed}_sorted.bed"
done


# ------------------------------------------------------------------------------
#  4. Keep regions shared by both capture BED files
# ------------------------------------------------------------------------------
bedtools multiinter -i \
  2191546/SureSelect_Clinical_Research_Exome_Regions_v2_noCHR_sorted.bed \
  captures_ccds_overlap.v37_nochr_sorted.bed \
  | awk '$4 >= 2' > regions_all_kits.bed

sort -k1,1 -k2,2n regions_all_kits.bed > captures_sort.v37.bed


# ------------------------------------------------------------------------------
#  5. Keep only the regions within CCDS exons
# ------------------------------------------------------------------------------
sed 's/^chr//' ccds_hg19_sorted.bed > ccds_hg19_sorted_nochr.bed
bedtools intersect -a captures_sort.v37.bed -b ccds_hg19_sorted_nochr.bed \
  | cut -f1-3 \
  | sort -k1,1 -k2,2n \
  | bedtools merge -i - > captures_ccds_overlap_pdx.v37.bed


# ------------------------------------------------------------------------------
#  6. Generate the IntervalList for CollectHsMetrics
# ------------------------------------------------------------------------------
source /mnt/beegfs02/software/recherche/miniconda/25.1.1/etc/profile.d/conda.sh
conda activate /home/ma_bertrand/environnements_conda/Sergei_lab/envs/GATK4

gatk BedToIntervalList \
  -I captures_ccds_overlap_pdx.v37.bed \
  -O hsmetrics_interval.interval_list \
  --SEQUENCE_DICTIONARY /home/a_ivashkin/userdata/references/genome_data/gatk/human_g1k_v37.dict

