#!/bin/bash

#SBATCH --job-name=qualimap_dedup
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/qualimap_dedup.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/qualimap_dedup.%j.err

source ~/.bashrc
conda activate anoa_wgs

if [ $# -eq 0 ]; then
    echo "Usage: sbatch qualimap_dedup.sh <SAMPLE> [SAMPLE2 ...]"
    exit 1
fi

SAMPLES=("$@")

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
QUALIMAP_OUT=$HOME_DIR/QC/03_post_dedup/qualimap
MULTIQC_OUT=$HOME_DIR/QC/03_post_dedup/multiqc

mkdir -p $QUALIMAP_OUT $MULTIQC_OUT

for SAMPLE in "${SAMPLES[@]}"; do
    BAM=$HOME_DIR/bam/${SAMPLE}.sorted.dedup.bam

    if [[ ! -f "$BAM" ]]; then
        echo "WARNING: BAM not found, skipping: $BAM"
        continue
    fi

    echo "=== Qualimap bamqc: $SAMPLE ==="
    qualimap bamqc \
        -bam $BAM \
        -outdir $QUALIMAP_OUT/${SAMPLE} \
        -outformat HTML \
        --java-mem-size=28G \
        -nt 8 \
        --paint-chromosome-limits

    echo "=== DONE: $SAMPLE ==="
done

echo "=== Running MultiQC on Qualimap results ==="
multiqc $QUALIMAP_OUT \
    --outdir $MULTIQC_OUT \
    --filename multiqc_qualimap_dedup.html \
    --force

echo "=== All samples complete ==="
