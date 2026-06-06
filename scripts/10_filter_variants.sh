#!/bin/bash

#SBATCH --job-name=filter_variants
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/filter_variants.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/filter_variants.%j.err

set -euo pipefail

set +u
source ~/.bashrc
conda activate anoa_wgs
set -u

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
VCF_DIR=$HOME_DIR/vcf_denovo
OUT=$HOME_DIR/filtered
mkdir -p $OUT

# SNPs - filtered
echo "=== Filtering SNPs ==="
bcftools view \
    -m2 -M2 \
    -v snps \
    -O u \
    $VCF_DIR/raw_variants.vcf.gz | \
bcftools +fill-tags \
    -O u -- -t MAF,F_MISSING | \
bcftools filter \
    -e 'MAF<0.05 || F_MISSING>0.05 || AC==0 || AC==AN' \
    -O z \
    --threads 8 \
    -o $OUT/filtered_snps.vcf.gz

bcftools index -t $OUT/filtered_snps.vcf.gz

echo "=== SNP count after filtering ==="
bcftools stats $OUT/filtered_snps.vcf.gz | grep "^SN"

# Indels - filtered
echo "=== Filtering Indels ==="
bcftools view \
    -m2 -M2 \
    -v indels \
    -O u \
    $VCF_DIR/raw_variants.vcf.gz | \
bcftools +fill-tags \
    -O u -- -t MAF,F_MISSING | \
bcftools filter \
    -e 'MAF<0.05 || F_MISSING>0.05 || AC==0 || AC==AN' \
    -O z \
    --threads 8 \
    -o $OUT/filtered_indels.vcf.gz

bcftools index -t $OUT/filtered_indels.vcf.gz

echo "=== Indel count after filtering ==="
bcftools stats $OUT/filtered_indels.vcf.gz | grep "^SN"

echo "=== DONE ==="
ls -lh $OUT/filtered_snps.vcf.gz $OUT/filtered_indels.vcf.gz
