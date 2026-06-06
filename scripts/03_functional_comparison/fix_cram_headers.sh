#!/bin/bash

#SBATCH --job-name=fix_cram_headers
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=1:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/fix_cram_headers.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/fix_cram_headers.%j.err

set -euo pipefail

set +u
source ~/.bashrc
conda activate anoa_wgs
set -u

CRAM_DIR=/mgpfs/home/qhanifa/_scratch/cram
REF=/mgpfs/home/qhanifa/anoa_analysis/reference/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz
OLD_UR="UR:/Users/raisatatumsaka/Documents/UNIX/ref_gen/GCF_002263795\.3_ARS-UCD2\.0_genomic\.fna"
NEW_UR="UR:/mgpfs/home/qhanifa/anoa_analysis/reference/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz"

for SAMPLE in Denok Maesa Manis Raden Rambo Rita; do
    CRAM=${CRAM_DIR}/${SAMPLE}.cram
    TMP=${CRAM_DIR}/${SAMPLE}.tmp.cram

    echo "=== Fixing header: ${SAMPLE} ==="
    samtools reheader -c "sed \"s|${OLD_UR}|${NEW_UR}|g\"" "$CRAM" > "$TMP"
    mv "$TMP" "$CRAM"
    samtools index "$CRAM"
    echo "=== Done: ${SAMPLE} ==="
done

echo "=== Verifying headers ==="
for SAMPLE in Denok Maesa Manis Raden Rambo Rita; do
    echo -n "${SAMPLE}: "
    samtools view -T "$REF" -H "${CRAM_DIR}/${SAMPLE}.cram" | grep -m1 "UR:" | grep -o "UR:[^ \t]*" || true
done
