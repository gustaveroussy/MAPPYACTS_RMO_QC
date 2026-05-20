# MAPPYACTS_RMO_QC
Additional quality controls for the MAPPYACTS/MOSCATO cohorts WES data


## Context

Reanalysis of the **MAPPYACTS** and **MOSCATO** cohorts using the pipeline described in [Gröbner et al., PMC10157368](https://pmc.ncbi.nlm.nih.gov/articles/PMC10157368/), aligned on hg19 (Sergey's team).

This repository provides **additional quality controls** on top of the original pipeline.

---

## Contacts

| Institution | Name | Email |
|---|---|---|
| Gustave Roussy | Antonin Marchais | antonin.marchais@gustaveroussy.fr |
| Gustave Roussy | Mathilde Bertrand | mathilde.bertrand@gustaveroussy.fr |
| Collaboration | Sarah Cherkaoui | sarah.cherkaoui@gustaveroussy.fr |

---

## Table of Contents

- [Repository Structure](#repository-structure)
- [Installation](#installation)
- [Callable Genome Regions](#callable-genome-regions)
  - [Criteria](#criteria)
  - [Pipeline](#pipeline)
  - [Output Format](#output-format)
  - [Usage](#usage)
- [PAR Regions Masking Check](#par-regions-masking-check)


---
## Callable genome regions 

Genomic intervals where sequencing coverage is sufficient to reliably detect somatic mutations. These regions are used for somatic mutation analyses such as comparing metabolic gene tumor mutational burden (TMB) vs other genes TMB.


### Criteria

The callable regions are defined based on the following filters:

- Restriction to captured target regions
- Restriction to exonic regions as defined by the set of canonical transcripts used by VEP (GRCh37)
- Tumor coverage ≥ 20x
- Normal coverage ≥ 10x


### Pipeline

The Snakemake pipeline consists of three main steps:

1. **Build target regions** — intersect the capture BED with VEP canonical exons, sort and merge overlapping intervals → `resources/target_regions.bed`
2. **Compute coverage** — run [mosdepth](https://github.com/brentp/mosdepth) over these target regions for each sample (tumor and normal separately) → `mapping_QC/mosdepth/{sample}.regions.bed.gz`
3. **Generate callable regions** — apply coverage thresholds (≥20x tumor, ≥10x normal) per tumor/normal pair and tag each interval as `PASS` or `FAIL` → `callable/{tumor}_{normal}.bed`

## Repository Structure

```
mosdepth/
├── env/
│   └── mosdepth.yaml          # Conda environment
└── Pipeline/
    ├── config.yaml            # Pipeline configuration (paths, thresholds)
    ├── launch.sh              # SLURM submission script
    └── Snakefile              # Snakemake pipeline
```


## Installation

Create the conda environment from the provided file:

```bash
conda env create -f env/mosdepth.yaml
conda activate mosdepth
```

Key dependencies:

| Tool | Version |
|---|---|
| mosdepth | 0.3.3 |
| bedtools | 2.31.1 |

## Usage

1. Edit `Pipeline/config.yaml` to set the paths and parameters for your samples.

2. Submit the pipeline to SLURM:

```bash
cd Pipeline/
sbatch launch.sh
```

Logs are written to `job_{jobid}.out` and `job_{jobid}.err`.

> **Note:** Remove `--dryrun` from `launch.sh` to run the pipeline for real.

### Output format

Each output file is a tab-separated BED file with the following columns:

| Column | Description |
|---|---|
| `chrom` | Chromosome |
| `start` | Start position (0-based) |
| `end` | End position |
| `tumor_depth` | Coverage in tumor sample |
| `normal_depth` | Coverage in normal sample |
| `status` | `PASS` if both thresholds are met, `FAIL` otherwise |


## PAR Regions Masking Check

 
Verifies that PAR regions on chromosome Y are masked (`N`) in `human_g1k_v37`, to rule out double-mapping artefacts in CNV analysis.
 
**Run:**
 
```bash
bash par_masking_check.sh
```
 
Expected: `ALL N` for chrY PARs, `NOT ALL N` for chrX PARs.
 
