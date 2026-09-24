import os
import glob 

configfile: "config.yaml"

WES_DIR = config["wes_dir"]
WES_NORMAL_DIR = config["wes_normal_dir"]
RNA_DIR = config["rna_dir"]
PT_FILE = config["pt_file"]
OUTDIR = config["outdir"]


def get_wes_normal_r1(wildcards):
    matches = glob.glob(os.path.join(WES_NORMAL_DIR, wildcards.dataset, "*R1*fastq.gz"))
    if len(matches) != 1:
        raise ValueError(f"Expected exactly 1 R1 fastq for {wildcards.dataset}, found {len(matches)}: {matches}")
    return matches[0]

def get_wes_normal_r2(wildcards):
    matches = glob.glob(os.path.join(WES_NORMAL_DIR, wildcards.dataset, "*R2*fastq.gz"))
    if len(matches) != 1:
        raise ValueError(f"Expected exactly 1 R2 fastq for {wildcards.dataset}, found {len(matches)}: {matches}")
    return matches[0]





WES_IDS, _ = glob_wildcards(os.path.join(WES_DIR, "{dataset}", "{dataset2}_graft_1.fastq.gz"))
RNA_IDS, _ = glob_wildcards(os.path.join(RNA_DIR, "{dataset}", "{dataset2}_graft_1.fastq.gz"))


WES_IDS = sorted(set(WES_IDS))
RNA_IDS = sorted(set(RNA_IDS))
WES_NORMAL_IDS = sorted([
    d for d in os.listdir(WES_NORMAL_DIR)
    if os.path.isdir(os.path.join(WES_NORMAL_DIR, d))
])

rule all:
    input:
        os.path.join(OUTDIR, "final_results", "output_all.txt"),
        os.path.join(OUTDIR, "final_results", "output.pdf"),
        expand(os.path.join(OUTDIR, "vaf", "{dataset}_WES.vaf"), dataset=WES_IDS),
        expand(os.path.join(OUTDIR, "vaf", "{dataset}_WES_NORMAL.vaf"), dataset=WES_NORMAL_IDS),
        expand(os.path.join(OUTDIR, "vaf", "{dataset}_RNA.vaf"), dataset=RNA_IDS)


# ----------------------------------------------------------------------------------------------
# Generate .vaf file for each WES tumor/PDX sample
# ----------------------------------------------------------------------------------------------
rule ncm_fastq_wes:
    input:
        r1 = os.path.join(WES_DIR, "{dataset}", "{dataset}_graft_1.fastq.gz"),
        r2 = os.path.join(WES_DIR, "{dataset}", "{dataset}_graft_2.fastq.gz")
    output:
        vaf = os.path.join(OUTDIR, "vaf", "{dataset}_WES.vaf")
    params:
        pt = PT_FILE
    threads: 4
    resources:
        mem_mb = 4000,
        time_min = 480
    log:
        os.path.join(OUTDIR, "logs", "ncm_fastq_wes_{dataset}.log")
    shell:
        """
        ngscheckmate_fastq -1 {input.r1} -2 {input.r2} -p {threads}  {params.pt} > {output.vaf} 2> {log}
        """


# ----------------------------------------------------------------------------------------------
# Generate .vaf file for each WES normal sample
# ----------------------------------------------------------------------------------------------
rule ncm_fastq_wes_normal:
    input:
        r1 = get_wes_normal_r1,
        r2 = get_wes_normal_r2
    output:
        vaf = os.path.join(OUTDIR, "vaf", "{dataset}_WES_NORMAL.vaf")
    params:
        pt = PT_FILE
    threads: 4
    resources:
        mem_mb = 4000,
        time_min = 480
    log:
        os.path.join(OUTDIR, "logs", "ncm_fastq_wes_normal_{dataset}.log")
    shell:
        """
        ngscheckmate_fastq -1 {input.r1} -2 {input.r2} -p {threads}  {params.pt} > {output.vaf} 2> {log}
        """

# ----------------------------------------------------------------------------------------------
# Generate .vaf file for each RNAseq sample
# ----------------------------------------------------------------------------------------------
rule ncm_fastq_rna:
    input:
        r1 = os.path.join(RNA_DIR, "{dataset}", "{dataset}_graft_1.fastq.gz"),
        r2 = os.path.join(RNA_DIR, "{dataset}", "{dataset}_graft_2.fastq.gz")
    output:
        vaf = os.path.join(OUTDIR, "vaf", "{dataset}_RNA.vaf")
    params:
        pt = PT_FILE
    threads: 4
    resources:
        mem_mb = 4000,
        time_min = 480
    log:
        os.path.join(OUTDIR, "logs", "ncm_fastq_rna_{dataset}.log")
    shell:
        """
        ngscheckmate_fastq -1 {input.r1} -2 {input.r2} -p {threads} {params.pt} > {output.vaf} 2> {log}
        """


# ----------------------------------------------------------------------------------------------
# Aggregate all .vaf (WES tumor, WES normal, RNA - all patients) and compute correlation matrix
# ----------------------------------------------------------------------------------------------
rule aggregate_ncm:
    input:
        wes = expand(os.path.join(OUTDIR, "vaf", "{dataset}_WES.vaf"), dataset=WES_IDS),
        wes_normal = expand(os.path.join(OUTDIR, "vaf", "{dataset}_WES_NORMAL.vaf"), dataset=WES_NORMAL_IDS),
        rna = expand(os.path.join(OUTDIR, "vaf", "{dataset}_RNA.vaf"), dataset=RNA_IDS)
    output:
        matrix = os.path.join(OUTDIR, "final_results", "output_all.txt"),
        matched = os.path.join(OUTDIR, "final_results", "output.pdf")
    params:
        vaf_dir = os.path.join(OUTDIR, "vaf"),
        out_dir = os.path.join(OUTDIR, "final_results")
    threads: 1
    resources:
        mem_mb = 16000,
        time_min = 480
    log:
        os.path.join(OUTDIR, "logs", "aggregate_ncm.log")
    shell:
        """
        vaf_ncm.py -I {params.vaf_dir} -O {params.out_dir}  > {log} 2>&1
        """
