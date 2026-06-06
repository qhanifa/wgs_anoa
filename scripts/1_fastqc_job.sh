#!/bin/bash

#SBATCH --job-name=fastqc
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/fastqc.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/fastqc.%j.err

source ~/.bashrc
conda activate anoa_wgs

SCRATCH=/mgpfs/home/qhanifa/_scratch
HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis

if [ $# -gt 0 ]; then
    SAMPLES=("$@")
else
    SAMPLES=(Anara Ronkon Bahen Baraku Denok Hesti Maesa Manis Raden Rambo Rita Sindereng)
fi

mkdir -p $HOME_DIR/qc/fastqc

for SAMPLE in "${SAMPLES[@]}"; do
    echo "=== FastQC: $SAMPLE ==="
    fastqc \
        $SCRATCH/raw_reads/${SAMPLE}_1.fastq.gz \
        $SCRATCH/raw_reads/${SAMPLE}_2.fastq.gz \
        --outdir $HOME_DIR/qc/fastqc \
        --threads 4
    echo "=== DONE: $SAMPLE ==="
done
