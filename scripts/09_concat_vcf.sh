#!/bin/bash

#SBATCH --job-name=concat_vcf
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=07:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/concat_vcf.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/concat_vcf.%j.err

source ~/.bashrc
conda activate anoa_wgs

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
SCRATCH=/mgpfs/home/qhanifa/_scratch
REF=$HOME_DIR/reference/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz
VCF_DIR=$HOME_DIR/vcf_denovo

for vcf in all_samples_chr*.vcf.gz; do
	[ -f "${vcf}.tbi" ] || bcftools index =t "$vcf"
done

echo "=== Concatenating VCF files ==="
bcftools concat \
    --naive \
    -0 z \
    --threads 8 \
    -o raw_variants.vcf.gz\
	$(ls -v all_samples_chr*.vcfgz)

bcftools index -t raw_variants.vcf.gz

echo "=== Checking sample count ==="
bcftools query -l raw_variants.vcf.gz | wc -l

echo "=== Checking whether all chromosomes are present ==="
bcftools index --stats raw_variants.vcf.gz | cut -f1

echo "=== Checking total site count  ==="
bcftools stats raw_variants.vcf.gz | grep "^SN"
    { echo "CRAM verification passed, removing individual chromosome"; rm all_samples_chr*.vcf.gz; } || \
    echo "CRAM verification failed, BAM kept"

echo "=== DONE ==="
ls -lh raw_variants.vcf.gz
