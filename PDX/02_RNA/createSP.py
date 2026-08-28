Expected structure (Xenome pipeline output):
Xenome/
├── DATASET1/
│   ├── DATASET1_graft_1.fastq.gz
│   ├── DATASET1_graft_2.fastq.gz
│   ├── DATASET1_host_1.fastq.gz
│   ├── ...
├── DATASET2/
│   ├── DATASET2_graft_1.fastq.gz
│   ├── DATASET2_graft_2.fastq.gz
│   ├── ...

Only files "*_graft_1.fastq.gz" / "*_graft_2.fastq.gz" are kept

Output:
samplesheet.csv :
    sample,fastq_1,fastq_2,strandedness
    DATASET1,/abs/path/DATASET1_graft_1.fastq.gz,/abs/path/DATASET1_graft_2.fastq.gz,auto
    DATASET2,/abs/path/DATASET2_graft_1.fastq.gz,/abs/path/DATASET2_graft_2.fastq.gz,auto
"""

import os
import csv
import glob

base_path = "Xenome"


graft_r1_files = sorted(glob.glob(os.path.join(base_path, "*", "*_graft_1.fastq.gz")))

samples = {}
for r1_path in graft_r1_files:
    filename = os.path.basename(r1_path)
    dataset = os.path.basename(os.path.dirname(r1_path))  # nom du dossier = nom du dataset

    r2_path = r1_path.replace("_graft_1.fastq.gz", "_graft_2.fastq.gz")

    if not os.path.exists(r2_path):
        print(f"Attention: R2 manquant pour {dataset} ({r2_path})")
        continue

    samples[dataset] = {
        "R1": os.path.abspath(r1_path),
        "R2": os.path.abspath(r2_path),
    }

output_csv = "samplesheet.csv"
with open(output_csv, "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["sample", "fastq_1", "fastq_2", "strandedness"])
    for dataset, reads in sorted(samples.items()):
        writer.writerow([dataset, reads["R1"], reads["R2"], "auto"])

print(f"{output_csv} généré avec succès ({len(samples)} échantillons)")
