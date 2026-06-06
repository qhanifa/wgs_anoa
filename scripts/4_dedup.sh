#!/bin/bash

#SBATCH --job-name=dedup
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/dedup.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/dedup.%j.err

source ~/.bashrc
conda activate anoa_wgs

SAMPLE=$1

if [[ -z "$SAMPLE" ]]; then
    echo "Usage: sbatch dedup.sh <SAMPLE>"
    exit 1
fi

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
BAM=$HOME_DIR/bam/${SAMPLE}.sorted.bam
OUT=$HOME_DIR/bam/${SAMPLE}.sorted.dedup.bam
TMP=$HOME_DIR/bam/${SAMPLE}.fixmate.bam

echo "=== Step 1: Sort by name ==="
samtools sort -n -@ 8 $BAM -o $HOME_DIR/bam/${SAMPLE}.namesorted.bam

echo "=== Step 2: Fixmate ==="
samtools fixmate -m -@ 8 $HOME_DIR/bam/${SAMPLE}.namesorted.bam $TMP

echo "=== Step 3: Sort by position ==="
samtools sort -@ 8 $TMP -o $HOME_DIR/bam/${SAMPLE}.fixmate.sorted.bam

echo "=== Step 4: Markdup ==="
samtools markdup -r -s --threads 8 $HOME_DIR/bam/${SAMPLE}.fixmate.sorted.bam $OUT

echo "=== Cleaning up intermediates ==="
rm $HOME_DIR/bam/${SAMPLE}.namesorted.bam $TMP $HOME_DIR/bam/${SAMPLE}.fixmate.sorted.bam

echo "=== Indexing ==="
samtools index -@ 8 $OUT

echo "=== Stats after dedup ==="
samtools flagstat $OUT > $HOME_DIR/qc/${SAMPLE}_dedup_flagstat.txt
samtools stats $OUT > $HOME_DIR/qc/${SAMPLE}_dedup_stats.txt

echo "=== DONE ==="
echo "Files:"
ls -lh $HOME_DIR/bam/${SAMPLE}.sorted.dedup.bam*
