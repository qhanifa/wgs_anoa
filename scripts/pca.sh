#!/bin/bash

#SBATCH --job-name=pca
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/pca.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/pca.%j.err

source ~/.bashrc
conda activate anoa_wgs

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
SCRATCH=/mgpfs/home/qhanifa/_scratch
FILTERED=$SCRATCH/filtered
OUT=$HOME_DIR/plink
mkdir -p $OUT

# Step 4a: VCF to PLINK binary
echo "=== Converting VCF to PLINK binary ==="
plink \
    --vcf $FILTERED/filtered_snps.vcf.gz \
    --make-bed \
    --allow-extra-chr \
    --set-missing-var-ids @:# \
    --double-id \
    --out $OUT/anoa_plink \
    2> $HOME_DIR/logs/plink_convert.log

# Step 4b: LD pruning
echo "=== LD pruning ==="
plink \
    --bfile $OUT/anoa_plink \
    --indep-pairwise 50 10 0.1 \
    --allow-extra-chr \
    --out $OUT/anoa_pruned \
    2> $HOME_DIR/logs/plink_prune.log

echo "=== SNPs retained after pruning ==="
wc -l $OUT/anoa_pruned.prune.in

# Step 4c: PCA
echo "=== Running PCA ==="
plink \
    --bfile $OUT/anoa_plink \
    --extract $OUT/anoa_pruned.prune.in \
    --pca 10 \
    --allow-extra-chr \
    --out $OUT/anoa_pca \
    2> $HOME_DIR/logs/plink_pca.log

echo "=== DONE ==="
ls -lh $OUT/anoa_pca.eigenval $OUT/anoa_pca.eigenvec
