#!/bin/bash

#SBATCH --job-name=min13_iqtree
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/iqtree_min13.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/iqtree_min13.%j.err

set -euo pipefail

set +u
source ~/.bashrc
conda activate anoa_wgs
set -u

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
ALIGN=$HOME_DIR/iqtree
OUT=$HOME_DIR/iqtree
mkdir -p $OUT/min13

VARSITES=$OUT/min4/anoa_min4.varsites.phy

# Generate varsites.phy if not yet present (IQ-TREE writes it before failing on invariant sites)
if [ ! -f "$VARSITES" ]; then
    echo "=== Generating varsites.phy ==="
    iqtree -s $ALIGN/snps_alignment_min13.min13.phy -m MFP+ASC --prefix $OUT/min13/anoa_min13 || true
    if [ ! -f "$VARSITES" ]; then
        echo "ERROR: varsites.phy was not generated — alignment may have no invariant sites"
        exit 1
    fi
fi

echo "=== IQ-TREE: min13 alignment ==="
iqtree \
    -s $OUT/min13/anoa_min13.varsites.phy \
    -m GTR+ASC+R4 \
    -B 1000 \
    -T $SLURM_CPUS_PER_TASK \
    -o african_buffalo \
    --prefix $OUT/min13/anoa_min13 \
    --redo

echo "=== Best-fit model (min13) ==="
grep "^Best-fit model" $OUT/min13/anoa_min13.log || true

echo "=== DONE ==="
ls -lh $OUT/min13/anoa_min13.treefile
