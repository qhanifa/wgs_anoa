#!/bin/bash

#SBATCH --job-name=vep_annotation
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/vep_annotation.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/vep_annotation.%j.err

set -euo pipefail

set +u
source ~/.bashrc
conda activate anoa_wgs
set -u

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
FILTERED=$HOME_DIR/filtered
REF=$HOME_DIR/reference
VEP_DIR=$HOME_DIR/vep
SIF=/mgpfs/home/qhanifa/ensembl-vep_latest.sif
GFF=$REF/GCF_002263795.3_ARS-UCD2.0_genomic.gff.gz
FASTA=$REF/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz

mkdir -p $VEP_DIR

# Combine SNPs + Indels
echo "=== Combining SNPs and Indels ==="
bcftools concat \
    --allow-overlaps \
    -O z \
    --threads 8 \
    -o $FILTERED/filtered_variants_all.vcf.gz \
    $FILTERED/filtered_snps.vcf.gz \
    $FILTERED/filtered_indels.vcf.gz

bcftools index -t $FILTERED/filtered_variants_all.vcf.gz

echo "=== Variant count after combining ==="
bcftools stats $FILTERED/filtered_variants_all.vcf.gz | grep "^SN"

# Run VEP via Singularity using local GFF + FASTA (no cache needed)
echo "=== Running VEP annotation ==="
singularity exec \
    --bind $HOME_DIR:/data \
    --bind $REF:/ref \
    $SIF \
    vep \
    --input_file /data/filtered/filtered_variants_all.vcf.gz \
    --output_file /data/vep/annotated_variants.vcf \
    --vcf \
    --gff /ref/$(basename $GFF) \
    --fasta /ref/$(basename $FASTA) \
    --fork 8 \
    --force_overwrite \
    2> $HOME_DIR/logs/vep.log

bgzip $VEP_DIR/annotated_variants.vcf
bcftools index -t $VEP_DIR/annotated_variants.vcf.gz

echo "=== DONE ==="
ls -lh $FILTERED/filtered_variants_all.vcf.gz $VEP_DIR/annotated_variants.vcf.gz
