
# Xenome — Graft/Host Deconvolution (PDX)

Read classification pipeline for PDX (Patient-Derived Xenograft) samples, used on both **RNA-seq** and **WES** data.

Xenome sorts sequenced reads by their species of origin:
- **graft**: human-derived reads (tumor)
- **host**: mouse-derived reads (host animal)
- **both**, **ambiguous**, **neither**: reads that are ambiguous or cannot be assigned

## Reference genomes

| | Genome | Build | Source |
|---|---|---|---|
| **Graft (human)** | `human_g1k_v37.fasta` | **hg19 / b37** (GRCh37) | same reference as Sergey's pipeline |
| **Host (mouse)** | `Mus_musculus.GRCm38.dna.primary_assembly.fa.gz` | GRCm38 | Ensembl release 99 |

> ⚠️ The human reference genome used here is **hg19 (b37)**, not hg38. Any downstream analysis (alignment, annotation, sashimi plots, etc.) on `graft` reads must stay consistent with this build.


## Step 1 — Index construction (`PREPROC_create_gossamer_index.sh`)

SLURM script (`sbatch`) that builds the Xenome index combining both reference genomes. This only needs to be run once. => Around 2 days running

**Parameters to set at the top of the script:**
- `INDEXDIR`: output directory for the index
- `NAME_INDEX`: prefix for the index files (e.g. `b37_human_g1k_GRCm38_ENSr99_DNA.idx`)
- `GRAFT_FASTA`: path to the human hg19 FASTA (must already exist)
- `WGET_HOST_FASTA`: Ensembl URL for the mouse FASTA (downloaded automatically)
- `XENOME`: path to the `xenome` binary

**SLURM resources**: 8 CPUs, 35G RAM, `longq` partition.

```bash
sbatch PREPROC_create_gossamer_index.sh
```

The script:
1. checks that the graft FASTA exists and that the index hasn't already been built,
2. downloads and prefixes (`chr`) the host FASTA,
3. runs `xenome index` (`-M 32 -T 8`) to build the combined index,
4. cleans up intermediate files.

This step only needs to be rerun if the index itself needs rebuilding (reference genome change, annotation version update, etc.) — not for every new sample.

## Step 2 — Read classification (Snakemake)

Once the index is available, the Snakemake workflow classifies the reads of each sample (RNA-seq or WES) into 5 categories, then compresses them.

### Rules

- **`xenome_classify`**: runs `xenome classify --pairs` on the paired FASTQs (`r1`/`r2`) of a sample, using the index built in Step 1. Produces one FASTQ per category (`graft`, `host`, `ambiguous`, `both`, `neither`) × per read (`1`/`2`), plus a `{dataset}_stats.txt` file summarizing the proportions.
- **`gzip`**: compresses each output FASTQ with `pigz`.

### Expected configuration (`config.yaml`)

```yaml
base_path: /path/to/results

samples:
  sample_1:
    r1: /path/to/sample_1_R1.fastq.gz
    r2: /path/to/sample_1_R2.fastq.gz
  sample_2:
    r1: /path/to/sample_2_R1.fastq.gz
    r2: /path/to/sample_2_R2.fastq.gz

xenome_classify:
  name: /path/to/xenome            # xenome binary
  xenome_index: /path/to/index/b37_human_g1k_GRCm38_ENSr99_DNA.idx
  threads: 8
  mem_mb: 35000
  time_min: 720
```

### Running the pipeline

```bash
sbatch xenome_launch.sh
```

## Output structure

```
{base_path}/Xenome/{dataset}/
├── {dataset}_graft_1.fastq.gz       # human (tumor) reads — used downstream
├── {dataset}_graft_2.fastq.gz
├── {dataset}_host_1.fastq.gz        # mouse reads
├── {dataset}_host_2.fastq.gz
├── {dataset}_ambiguous_1.fastq.gz
├── {dataset}_ambiguous_2.fastq.gz
├── {dataset}_both_1.fastq.gz
├── {dataset}_both_2.fastq.gz
├── {dataset}_neither_1.fastq.gz
├── {dataset}_neither_2.fastq.gz
└── {dataset}_stats.txt              # % of reads per category
```

For downstream analysis (alignment, variant calling, expression quantification, etc.), only the **`{dataset}_graft_*.fastq.gz`** files are generally used, aligned against the **hg19/b37** reference genome.
