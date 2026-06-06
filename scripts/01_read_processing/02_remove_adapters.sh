#!/bin/bash

#SBATCH --job-name=remove_adapters
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/remove_adapters.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/remove_adapters.%j.err

source ~/.bashrc
conda activate anoa_wgs

SCRATCH=/mgpfs/home/qhanifa/_scratch
HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis

if [ $# -gt 0 ]; then
    SAMPLES=("$@")
else
    SAMPLES=(Ronkon Bahen Baraku Denok Hesti Maesa Manis Raden Rambo Rita Sindereng)
fi

for SAMPLE in "${SAMPLES[@]}"; do
    echo "=== Trimming: $SAMPLE ==="
    AdapterRemoval \
        --file1 $SCRATCH/raw_reads/${SAMPLE}_1.fastq.gz \
        --file2 $SCRATCH/raw_reads/${SAMPLE}_2.fastq.gz \
        --output1 $SCRATCH/${SAMPLE}_1_trimmed.fastq \
        --output2 $SCRATCH/${SAMPLE}_2_trimmed.fastq \
        --trimns --trimqualities
    echo "=== DONE: $SAMPLE ==="
done
