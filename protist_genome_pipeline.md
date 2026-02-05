# Protist genome extraction from metagenomic assembly

**Author:** Rodrigo Lusa  
**Email:** lusarodrigo4@gmail.com  
**Date:** 2025-07-15

This guide describes a reproducible pipeline to extract protist genomes from metagenomic assemblies using SPAdes, BWA, CONCOCT, EukCC, and BUSCO on the Niagara cluster (SciNet). It standardizes paths, uses Apptainer containers for portability, and includes concrete commands from raw reads to protist-enriched bins and quality assessment.

---

## Overview and prerequisites

- **Goal:** Recover a protist genome (or enriched draft) from a metagenome assembly by mapping, binning, taxonomic screening, and quality checks.
- **Cluster environment:** Niagara (SLURM scheduler).
- **Scratch space:** Use `$SCRATCH` and paths under `/scratch/user/...`.
- **Core tools:**
  - Assemblers and mappers: [SPAdes](https://github.com/ablab/spades), [BWA](https://github.com/lh3/bwa)
  - Binning: [CONCOCT](https://github.com/BinPro/CONCOCT)
  - Eukaryotic bin QC and taxon: [EukCC v2](https://github.com/microbiome-informatics/EukCC)
  - Universal completeness: [BUSCO v6](https://github.com/ezlabgva/busco)
  - Utilities: [Apptainer](https://apptainer.org/), [samtools](http://www.htslib.org/), [GNU Parallel](https://www.gnu.org/software/parallel/), [seqkit](https://github.com/shenwei356/seqkit), [NCBI Datasets CLI](https://github.com/ncbi/datasets)
- **Modules you’ll likely need on Niagara:**
  - `module load CCEnv nixpkgs/16.09`
  - `module load apptainer`
  - Optionally ensure `samtools`, `parallel`, and `python` are available (via modules or containers).

> Tip: Replace placeholder paths like `path/to/...` with your actual locations under `/scratch/user/...`. Keep filenames consistent (e.g., `Para2_Meta_Assembly.fasta`).

---

## Installation and data preparation

### NCBI Datasets CLI

Add CLI binaries to your `$SCRATCH/bin` and extend PATH:

```bash
mkdir -p $SCRATCH/bin
cd $SCRATCH/bin
curl -o datasets 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/datasets'
curl -o dataformat 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/dataformat'
chmod +x datasets dataformat
echo 'export PATH=$SCRATCH/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

Download example reference genomes (optional):
```bash
datasets download genome accession GCF_001186125.1 --include gff3,rna,cds,protein,genome,seq-report  # Sphaeroforma arctica JP610
datasets download genome accession GCA_002812265.1 --include gff3,rna,cds,protein,genome,seq-report  # Abeoforma whisleri
datasets download genome accession GCA_002812295.1 --include gff3,rna,cds,protein,genome,seq-report  # Pirum gemmata
```

SPAdes meta-assembly (if you don’t already have an assembly)
```bash
# Example for paired-end Illumina reads
spades.py --meta \
  -1 /scratch/user/path/to/reads_1.fastq.gz \
  -2 /scratch/user/path/to/reads_2.fastq.gz \
  -o /scratch/user/spades_meta_out

# Resulting assembly:
cp /scratch/user/spades_meta_out/contigs.fasta /scratch/user/Para2_Meta_Assembly.fasta
```

BUSCO v6 via Apptainer
```bash
module load apptainer
cd /scratch/user
apptainer pull busco_6.0.0.sif docker://ezlabgva/busco:v6.0.0_cv1
echo 'alias busco="apptainer exec --bind $SCRATCH busco_6.0.0.sif busco"' >> ~/.bashrc
source ~/.bashrc
```
EukCC v2 and database
```bash
module load apptainer
mkdir -p /scratch/user/eukccdb/results
cd /scratch/user/eukccdb

apptainer pull eukcc_latest.sif docker://quay.io/microbiome-informatics/eukcc
wget http://ftp.ebi.ac.uk/pub/databases/metagenomics/eukcc/eukcc2_db_ver_1.1.tar.gz
tar -xzvf eukcc2_db_ver_1.1.tar.gz

export EUKCC2_DB=/scratch/user/eukccdb/eukcc2_db_ver_1.1
echo 'export EUKCC2_DB=/scratch/user/eukccdb/eukcc2_db_ver_1.1' >> ~/.bashrc
```

CONCOCT container and helper scripts

```bash
module load apptainer
cd /scratch/user/concoct
apptainer pull concoct_latest.sif docker://binpro/concoct_latest

# Helper scripts from CONCOCT repo
wget https://raw.githubusercontent.com/BinPro/CONCOCT/develop/scripts/cut_up_fasta.py
wget https://raw.githubusercontent.com/BinPro/CONCOCT/develop/scripts/concoct_coverage_table.py
wget https://raw.githubusercontent.com/BinPro/CONCOCT/develop/scripts/merge_cutup_clustering.py
wget https://raw.githubusercontent.com/BinPro/CONCOCT/develop/scripts/extract_fasta_bins.py
chmod +x *.py
```

BWA build
```bash
cd /scratch/user
git clone https://github.com/lh3/bwa.git
cd bwa && make
```
# Pipeline: SPAdes → BWA → CONCOCT → EukCC → BUSCO
A) Map trimmed reads to the meta-assembly with BWA
```bash
cd /scratch/user

# Index the assembly
/scratch/user/bwa/bwa index /scratch/user/Para2_Meta_Assembly.fasta

# Map paired-end reads
/scratch/user/bwa/bwa mem \
  /scratch/user/Para2_Meta_Assembly.fasta \
  /scratch/user/path/to/reads_1P.fq.gz \
  /scratch/user/path/to/reads_2P.fq.gz \
  > /scratch/user/bwa_para2.sam
```

Convert to BAM, sort, and index:
```bash
module load samtools
samtools view -@ 8 -Sb /scratch/user/bwa_para2.sam > /scratch/user/bwa_para2.bam
samtools sort -@ 8 /scratch/user/bwa_para2.bam -o /scratch/user/bwa_para2.sorted.bam
samtools index /scratch/user/bwa_para2.sorted.bam
```
B) Bin contigs with CONCOCT
Cut contigs into 10 kbp chunks and record coordinates:

```bash
cd /scratch/user/concoct
apptainer exec --bind="$SCRATCH" concoct_latest.sif \
  python cut_up_fasta.py /scratch/user/Para2_Meta_Assembly.fasta \
  -c 10000 -o 0 --merge_last -b contigs_10K.bed > contigs_10K.fa
```

Compute coverage per subcontig from BAM:
```bash
apptainer exec --bind="$SCRATCH" concoct_latest.sif \
  python concoct_coverage_table.py contigs_10K.bed \
  /scratch/user/bwa_para2.sorted.bam > coverage_table.tsv
```

Run CONCOCT and merge subcontigs back to full contigs:
```bash
apptainer exec --bind="$SCRATCH" concoct_latest.sif \
  concoct --composition_file contigs_10K.fa \
          --coverage_file coverage_table.tsv \
          -b concoct_output/

# Ensure header exists before merging (some versions require it)
sed -i '1i contig_id,cluster' concoct_output/clustering_gt1000.csv

apptainer exec --bind="$SCRATCH" concoct_latest.sif \
  python merge_cutup_clustering.py concoct_output/clustering_gt1000.csv \
  > concoct_output/clustering_merged.csv
```

Extract bins as FASTA:
```bash
mkdir -p concoct_output/fasta_bins
apptainer exec --bind="$SCRATCH" concoct_latest.sif \
  python extract_fasta_bins.py /scratch/user/Para2_Meta_Assembly.fasta \
  concoct_output/clustering_merged.csv \
  --output_path concoct_output/fasta_bins
```
C) Identify eukaryotic/protist bins with EukCC → Run EukCC on each bin (single-bin mode):

```bash
module load apptainer
export EUKCC2_DB=/scratch/user/eukccdb/eukcc2_db_ver_1.1

mkdir -p /scratch/user/eukcc_results
for file in /scratch/user/concoct/concoct_output/fasta_bins/*.fa; do
  bin_name=$(basename "$file" .fa)
  out_dir="/scratch/user/eukcc_results/$bin_name"
  mkdir -p "$out_dir"
  echo "Processing $bin_name..."
  apptainer exec --bind="$SCRATCH" /scratch/user/eukccdb/eukcc_latest.sif \
    eukcc single --out "$out_dir" --threads 8 "$file"
done
```

Summarize completeness, contamination, Best TaxID into a TSV:
```bash
#!/usr/bin/env bash
BASE_DIR="/scratch/user/eukcc_results"
OUTPUT="/scratch/user/eukcc_summary.tsv"
echo -e "bin\tCompleteness\tContamination\tBest_TaxID" > "$OUTPUT"

for BIN_DIR in "$BASE_DIR"/*; do
  [ -d "$BIN_DIR" ] || continue
  BIN=$(basename "$BIN_DIR")
  CSV="$BIN_DIR/eukcc.csv"
  LOG="$BIN_DIR/eukcc.log"

  if [ -f "$CSV" ]; then
    # Prefer the CSV for robustness
    comp=$(awk -F, 'NR==1{for(i=1;i<=NF;i++)h[$i]=i} NR>1{print $h["completeness"]; exit}' "$CSV")
    cont=$(awk -F, 'NR==1{for(i=1;i<=NF;i++)h[$i]=i} NR>1{print $h["contamination"]; exit}' "$CSV")
    taxid=$(awk -F, 'NR==1{for(i=1;i<=NF;i++)h[$i]=i} NR>1{print $h["best_taxid"]; exit}' "$CSV")
    echo -e "${BIN}\t${comp}\t${cont}\t${taxid}" >> "$OUTPUT"
  elif [ -f "$LOG" ]; then
    comp=$(grep -m1 "Completeness:" "$LOG" | awk -F ':' '{print $NF}' | xargs)
    cont=$(grep -m1 "Contamination:" "$LOG" | awk -F ':' '{print $NF}' | xargs)
    taxid=$(grep -m1 "Best TaxID:" "$LOG" | awk -F ':' '{print $NF}' | xargs)
    echo -e "${BIN}\t${comp}\t${cont}\t${taxid}" >> "$OUTPUT"
  else
    echo -e "${BIN}\tUnknown\tUnknown\tUnknown" >> "$OUTPUT"
  fi
done
```

Identify candidate protist bins by Best TaxID or clade:
* Strategy: Filter eukcc_summary.tsv for target protist clades (e.g., Opisthokonta, Amoebozoa, etc.) or specific NCBI TaxIDs.
* Example: Suppose bins 47.fa, 59.fa, and 6.fa match the desired protist group (with low but non-zero completeness). Concatenate:

```bash
cat /scratch/user/concoct/concoct_output/fasta_bins/47.fa \
    /scratch/user/concoct/concoct_output/fasta_bins/59.fa \
    /scratch/user/concoct/concoct_output/fasta_bins/6.fa \
    > /scratch/user/protist_3_merged.fa
```
D) Recover additional protist contigs using SCMGs (EukCC extra)

Run EukCC with extra outputs on the full  meta-assembly:
```bash
export EUKCC2_DB=/scratch/user/eukccdb/eukcc2_db_ver_1.1
mkdir -p /scratch/user/eukcc_clean
apptainer exec --bind="$SCRATCH" /scratch/user/eukccdb/eukcc_latest.sif \
  eukcc single --out /scratch/user/eukcc_clean --threads 8 --extra \
  /scratch/user/Para2_Meta_Assembly.fasta
  ```

Extract contigs carrying the clade’s Single-Copy Marker Genes (SCMGs):
```bash
cd /scratch/user/eukcc_clean
# The table typically contains contig identifiers; normalize if prefixes/suffixes were added
cut -f1 scmg_marker_table.csv | sed 's/^metaeuk_//' | sed 's/_0$//' > contigs_with_scmgs.txt

# List contigs present in your merged protist bins:
seqkit seq -n /scratch/user/protist_3_merged.fa > merged_bin_contigs.txt

# Find SCMG contigs missing from the merged bins:
grep -Fvx -f merged_bin_contigs.txt contigs_with_scmgs.txt > scmg_missing_contigs.txt

# Extract those missing contigs from the assembly and append them to the merged protist FASTA:
seqkit grep -n -f scmg_missing_contigs.txt /scratch/user/Para2_Meta_Assembly.fasta > scmg_missing_seqs.fa
cat scmg_missing_seqs.fa >> /scratch/user/protist_3_merged.fa
``` 

E) Quality assessment with BUSCO
```bash
# Example against eukaryota_odb12 (or a narrower clade if appropriate)
busco -i /scratch/user/protist_3_merged.fa \
      -m genome \
      -l /scratch/user/busco_search/busco_downloads/lineages/eukaryota_odb12 \
      --offline \
      -o protist_busco_run

# Plot (given a folder of BUSCO JSONs)
busco --plot /scratch/user/path/to/folder_with_jsons
```

Downloading results to your local machine
```bash
# Replace your_username with your SciNet username
scp -i ~/.ssh/private_key_scinet \
your_username@niagara.scinet.utoronto.ca:/scratch/user/path/to/results ./
```
# Minimal SLURM examples (optional)
If you prefer batch submission, wrap commands into scripts and submit with `sbatch`:

Template:
```bash
#!/bin/sh
#SBATCH -J JOBNAME
#SBATCH --time=3:00:00
#SBATCH --ntasks-per-node=40
#SBATCH --nodes=1

cd $SLURM_SUBMIT_DIR

module load CCEnv nixpkgs/16.09
module load apptainer

<other busco commands>
```

BUSCO example
```bash
#!/bin/sh
#SBATCH -J BUSCO
#SBATCH --time=3:00:00
#SBATCH --ntasks-per-node=40
#SBATCH --nodes=1

cd $SLURM_SUBMIT_DIR

module load CCEnv nixpkgs/16.09 apptainer

parallel -j $SLURM_TASKS_PER_NODE <<EOF
busco -i /scratch/user/protist_3_merged.fa -m genome -l /scratch/user/busco_search/busco_downloads/lineages/eukaryota_odb12 --offline -o protist_busco_run
<other busco commands>

EOF
```

EukCC example
```bash
# EukCC on bins example
#!/bin/sh
#SBATCH -J eukcc
#SBATCH --time=5:00:00
#SBATCH --cpus-per-task=8
#SBATCH --nodes=1

cd $SLURM_SUBMIT_DIR

module load CCEnv nixpkgs/16.09 apptainer

export EUKCC2_DB=/scratch/user/eukccdb/eukcc2_db_ver_1.1

for f in /scratch/user/concoct/concoct_output/fasta_bins/*.fa; do
  bn=$(basename "$f" .fa)
  apptainer exec --bind="$SCRATCH" /scratch/user/eukccdb/eukcc_latest.sif eukcc single --out /scratch/user/eukcc_results/$bn --threads 8 "$f"
done
```


BWA example
```bash
#!/bin/sh
#SBATCH -J BWA
#SBATCH --time=5:00:00
#SBATCH --ntasks-per-node=40
#SBATCH --nodes=1

cd $SLURM_SUBMIT_DIR

module load CCEnv nixpkgs/16.09

parallel -j $SLURM_TASKS_PER_NODE <<EOF

./bwa mem Para2_Meta_Assembly.fasta /scratch/y/yanwang/lusaro/raw_para/RAWreads/para2_CKDN230016751-1A_H7YCNDSX7_L1_trimmed_1P.fq /scratch/y/yanwang/lusaro/raw_para/RAWreads/para2_CKDN230016751-1A_H7YCNDSX7_L1_trimmed_2P.fq > bwa_para2.sam

EOF
```