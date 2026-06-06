#!/bin/bash

#SBATCH --job-name=angsd_theta
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=250G
#SBATCH --time=48:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/angsd_theta.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/angsd_theta.%j.err

set -euo pipefail

set +u
source ~/.bashrc
conda activate anoa_wgs
set -u

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
SCRATCH=/mgpfs/home/qhanifa/_scratch
CRAM_DIR=$SCRATCH/cram
REF=$HOME_DIR/reference/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz
OUT=$HOME_DIR/angsd
mkdir -p $OUT

export REF_CACHE=$HOME_DIR/reference/hts-cache/%2s/%2s/%s
export REF_PATH=$REF_CACHE

for SPECIES in lowland mountain; do

    echo "=== Processing: ${SPECIES} ==="

    # Step 1: Generate site allele frequency likelihoods
    angsd \
        -bam ${CRAM_DIR}/${SPECIES}_crams.list \
        -ref $REF \
        -anc $REF \
        -GL 1 \
        -doSaf 1 \
        -nThreads 8 \
        -out ${OUT}/${SPECIES}_saf

    echo "=== SAF done: ${SPECIES} ==="

    # Step 2: Estimate SFS
    realSFS \
        ${OUT}/${SPECIES}_saf.saf.idx \
        -P 8 \
        -fold 1 \
        > ${OUT}/${SPECIES}.sfs

    echo "=== SFS done: ${SPECIES} ==="

    # Step 3: Calculate thetas
    realSFS saf2theta \
        ${OUT}/${SPECIES}_saf.saf.idx \
        -sfs ${OUT}/${SPECIES}.sfs \
        -outname ${OUT}/${SPECIES}_theta

    echo "=== Theta done: ${SPECIES} ==="

    # Step 4: Sliding window statistics
    thetaStat do_stat \
        ${OUT}/${SPECIES}_theta.thetas.idx \
        -win 10000 \
        -step 10000 \
        -outnames ${OUT}/${SPECIES}_theta_win

    echo "=== Window stats done: ${SPECIES} ==="

done

echo "=== ALL DONE ==="
