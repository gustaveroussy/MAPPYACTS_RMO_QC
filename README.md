# MAPPYACTS_RMO_QC
Additional quality controls for the MAPPYACTS/MOSCATO cohorts WES data


## Context

Reanalysis of the **MAPPYACTS** and **MOSCATO** cohorts using the pipeline described in [Gröbner et al., PMC10157368](https://pmc.ncbi.nlm.nih.gov/articles/PMC10157368/), aligned on hg19 (Sergey's team). (code in : https://github.com/gustaveroussy/gesa-wes-extended/)

This repository provides **additional quality controls** on top of the original pipeline.

---

## Contacts

| Institution | Name | Email |
|---|---|---|
| Gustave Roussy | Antonin Marchais | antonin.marchais@gustaveroussy.fr |
| Gustave Roussy | Mathilde Bertrand | mathilde.bertrand@gustaveroussy.fr |
| Collaboration | Sarah Cherkaoui | sarah.cherkaoui@gustaveroussy.fr |

---

 
The analysis is organized in three main steps:
 
| Step | Purpose | Tools |
|------|---------|-------|
| 1. GESA pipeline *(external)* | Primary processing of the WES data | [GESA](https://github.com/gustaveroussy/gesa-wes-extended) (Sergey's team) |
| 2. Additional QC | Coverage assessment, callable regions, PAR masking check | mosdepth, custom scripts |
| 3. PDX analysis | Remove mouse reads, then process RNA-seq and WES | Xenome, nf-core/rnaseq (RNA), GESA (WES) |

 
```
Steps 1-2
  WES FASTQ ──► GESA pipeline ──► QC (mosdepth, callable regions, PAR check)
 
Step 3 (PDX)
  PDX FASTQ ──► Xenome (human / mouse) ──► human reads ──┬──► RNA : nf-core/rnaseq
                                                         └──► WES : GESA pipeline
```


## Repository Structure
 
```
.
├── README.md
├── PAR_regions.sh   # PAR regions masking check
├── mosdepth/              # Coverage QC
└── PDX/
    ├── 00_QC/            # NGSCheckMate Snakemake Pipeline
    ├── 01_Xenome/            # Host/graft classification
    ├── 02_RNA/            # nf-core/rnaseq configs and samplesheets
    └── 02_WES/               # Samplesheets / configs to run GESA on Xenome human reads
```

