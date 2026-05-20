#!/bin/bash

# =============================================================================
# PAR (Pseudoautosomal Regions) masking check — GRCh37
# =============================================================================
# Context : WES data from the MAPPYACTS cohort, processed through Sergey's
# pipeline using human_g1k_v37 as reference genome.
#
# Goal : verify that PAR regions on chromosome Y are masked (N) in the
# reference genome, to rule out double-mapping artefacts in CNV analysis.
#
# Expected result:
#   ALL N     → PARs are masked   ✓
#   NOT ALL N → PARs are NOT masked 
# =============================================================================

set -euo pipefail
FASTA="human_g1k_v37.fasta"


# -----------------------------------------------------------------------------
# 1. Download PAR coordinates from NCBI
# -----------------------------------------------------------------------------
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.14_GRCh37.p13/GCA_000001405.14_GRCh37.p13_assembly_regions.txt

echo "PAR coordinates (GRCh37):"
grep "PAR" GCA_000001405.14_GRCh37.p13_assembly_regions.txt
# PAR#1  X  60001       2699520    PAR
# PAR#2  X  154931044   155260560  PAR
# PAR#1  Y  10001       2649520    PAR
# PAR#2  Y  59034050    59363566   PAR



# =============================================================================
# Check whether a genomic region is fully masked (N-only) in the reference FASTA
# =============================================================================
#
# This command extracts a genomic interval from the reference genome and tests
# whether it consists exclusively of 'N' characters (i.e., masked sequence).
#
# Step-by-step:
# 1. samtools faidx: Extracts the specified region from the FASTA file.
#
# 2. grep -v ">": Removes the FASTA header line (starting with '>').
#
# 3. tr -d '\n': Concatenates all sequence lines into a single continuous string.
#
# 4. grep -vq '[^N]': Checks whether any character different from 'N' is present:
#       - [^N]  : matches any character that is NOT 'N'
#       - -q    : quiet mode (no output, only exit status)
#       - -v    : inverts the match
#
#    Result:
#       - exit code 0 → no non-N characters found → region is fully masked
#       - exit code 1 → at least one non-N base present → region not fully masked
#
# 5. && / || logic:
#    - If fully masked → print "ALL N"
#    - Otherwise      → print "NOT ALL N"
#
# Interpretation:
#    ALL N     → region is masked in the reference (expected for Y-PAR if masked)
#    NOT ALL N → region contains real sequence (A/C/G/T), not fully masked
# =============================================================================

# Check contig names and chrY size
echo ""
echo "--- chrY contig info ---"
grep "^Y" ${FASTA}.fai

# PAR1 on chrY
echo ""
echo "--- PAR1 chrY:10001-10100 ---"
samtools faidx human_g1k_v37.fasta Y:10001-2649520 | \
grep -v ">" | tr -d '\n' | grep -vq '[^N]' && echo "ALL N" || echo "NOT ALL N"

# PAR2 on chrY
echo ""
echo "--- PAR2 chrY:59034050-59034100 ---"
samtools faidx human_g1k_v37.fasta Y:59034050-59363566 | \
grep -v ">" | tr -d '\n' | grep -vq '[^N]' && echo "ALL N" || echo "NOT ALL N"


# PAR1 on chrX (for comparison)
echo ""
echo "--- PAR1 chrX:60001-60100 (for comparison) ---"
samtools faidx human_g1k_v37.fasta X:60001-2699520 | \
grep -v ">" | tr -d '\n' | grep -vq '[^N]' && echo "ALL N" || echo "NOT ALL N"


# PAR2 on chrX (for comparison)
echo ""
echo "--- PAR2 chrX:154931044-154931100 (for comparison) ---"
samtools faidx human_g1k_v37.fasta X:154931044-155260560 | \
grep -v ">" | tr -d '\n' | grep -vq '[^N]' && echo "ALL N" || echo "NOT ALL N"


