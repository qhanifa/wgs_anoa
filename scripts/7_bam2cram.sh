#!/bin/bash

#SBATCH --job-name=bam2cram
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=07:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/bam2cram.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/bam2cram.%j.err

source ~/.bashrc
conda activate anoa_wgs

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
SCRATCH=/mgpfs/home/qhanifa/_scratch
REF=$HOME_DIR/reference/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz
BAM_DIR=$HOME_DIR/bam
CRAM_DIR=$HOME_DIR/cram

mkdir -p $CRAM_DIR

SAMPLE=$1
BAM=${BAM_DIR}/${SAMPLE}.sorted.dedup.bam

if [[ -z "$SAMPLE" ]]; then
    echo "Usage: sbatch bam2cram.sh <SAMPLE>"
    exit 1
fi

echo "=== Converting BAM to CRAM: $SAMPLE ==="
samtools view \
    -C \
    -T $REF \
    --threads 8 \
    -o ${CRAM_DIR}/${SAMPLE}.cram \
    $BAM

echo "=== Indexing ==="
samtools index ${CRAM_DIR}/${SAMPLE}.cram

echo "=== Verifying CRAM ==="
samtools quickcheck ${CRAM_DIR}/${SAMPLE}.cram

echo "=== Removing BAM if CRAM verified ==="
samtools quickcheck ${CRAM_DIR}/${SAMPLE}.cram && \
    { echo "CRAM verification passed, removing BAM"; rm ${BAM_DIR}/${SAMPLE}.sorted.dedup.bam; } || \
    echo "CRAM verification failed, BAM kept"

echo "=== DONE ==="
ls -lh ${CRAM_DIR}/${SAMPLE}.cram*
