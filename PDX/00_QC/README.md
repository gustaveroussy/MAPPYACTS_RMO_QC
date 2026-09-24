# NGSCheckMate Snakemake Pipeline
 
This pipeline checks whether WES and RNAseq FASTQ files (PDX grafts) match the same
patient/individual, using [NGSCheckMate](https://github.com/parklab/NGSCheckMate) in
FASTQ mode. It compares allele fractions at a panel of known SNPs to confirm that
all sequencing files (WES and RNAseq, across data types) belonging to a given sample
cluster together, flagging any potential sample swap or contamination.
 
Input FASTQ files are expected to already be filtered for human reads
(e.g. post-Xenome deconvolution for PDX samples).

This strategy was used in this paper : https://www.nature.com/articles/s41467-023-43373-1#Sec10


## Pipeline overview
 
1. **`ncm_fastq_wes`** — runs `ngscheckmate_fastq` on each WES sample, producing a `.vaf` file.
2. **`ncm_fastq_rna`** — runs `ngscheckmate_fastq` on each RNAseq sample, producing a `.vaf` file.
3. **`aggregate_ncm`** — runs `vaf_ncm.py` on all `.vaf` files together (WES + RNAseq,
   all samples) to compute a correlation matrix, a matched/unmatched sample list, and
   a clustering dendrogram.


## Requirements

- snakemake/8.28.0
- A conda environment with NGSCheckMate installed : cf `ngscheckmate.yaml` to install the same environment :

```
conda env create -f ngscheckmate.yaml -n ngscheckmate
conda activate ngscheckmate
```

- Access to the NGSCheckMate SNP pattern file (`SNP.pt`), shipped with the package
  (e.g. `<conda_env>/NGSCheckMate/SNP/SNP.pt`)
- A SLURM cluster profile for `--profile`


## Directory structure expected for input data
 
```
WES/
  datasetID/
    datasetID_graft_1.fastq.gz
    datasetID_graft_2.fastq.gz

WES_normal/
  datasetID/
    datasetID_R1.fastq.gz
    datasetID_R2.fastq.gz

RNA/
  datasetID/
    datasetID_graft_1.fastq.gz
    datasetID_graft_2.fastq.gz
```
 
Each `datasetID` found under `WES/`, `WES_normal/` and/or `RNA/` is automatically detected by the
pipeline — no need to list samples manually.


## Files
 
- `snakefile.py` — the pipeline itself
- `config.yaml` — paths to the input data, the SNP pattern file, and the output directory
- `profiles/slurm/` — your SLURM cluster profile (not included here, assumed to already exist)

## Config.yaml 

Edit `config.yaml`:
 
```yaml
wes_dir: "/path/to/WES"
wes_normal_dir: "/path/to/WES_normal"
rna_dir: "/path/to/RNA"
pt_file: "/path/to/SNP.pt"
outdir: "/path/to/results"
```

## How to run 

Edit `launch.sh`:

```
sbatch launch.sh
```


## Outputs
 
```
results/
  vaf/                     # one .vaf file per sample
  final_results/
    output_all.txt         # all pairwise comparisons
    output.pdf     # same in pdf
    output_corr_matrix.txt # sample x sample correlation matrix
  logs/                    # one log per rule/sample
```
 
`output_all.txt` have no header and contain 5 tab-separated columns:
 
| Column | Content |
|---|---|
| 1 | Sample 1 |
| 2 | NGSCheckMate call: `matched` (same individual) or `unmatched` |
| 3 | Sample 2 |
| 4 | Correlation between the VAF profiles of the two samples |
| 5 | Mean sequencing depth of the pair |
 
The matched/unmatched threshold depends on depth: correlations are noisier at low coverage,
so the threshold is lowered accordingly.
 
## Interpreting the results

Results are compared with the sample annotations in the script `link_ncm_to_patients.Rmd`.
