#!/bin/bash

#SBATCH --job-name=qc_dedup
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/qc_dedup.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/qc_dedup.%j.err

source ~/.bashrc
conda activate anoa_wgs

if [ $# -eq 0 ]; then
    echo "Usage: sbatch qc_dedup.sh <SAMPLE> [SAMPLE2 ...]"
    exit 1
fi

SAMPLES=("$@")

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
FASTQC_OUT=$HOME_DIR/QC_reports/fastqc_dedup

mkdir -p $FASTQC_OUT

for SAMPLE in "${SAMPLES[@]}"; do
    BAM=$HOME_DIR/bam/${SAMPLE}.sorted.dedup.bam

    echo "=== FastQC: $SAMPLE ==="
    fastqc $BAM --outdir $FASTQC_OUT --threads 4

    echo "=== MultiQC ==="
    multiqc $FASTQC_OUT --outdir $HOME_DIR/QC_reports --filename multiqc_dedup_${SAMPLE}.html

    echo "=== DONE: $SAMPLE ==="
done
