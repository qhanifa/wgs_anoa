#!/bin/bash
#SBATCH --job-name=anoa_map
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/map_%x.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/map_%x.%j.err

source ~/.bashrc
conda activate anoa_wgs

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
SCRATCH=/mgpfs/home/qhanifa/_scratch
REF=$HOME_DIR/reference/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz

SAMPLES=(Anara Ronkon Bahen Baraku Denok Hesti Maesa Manis Raden Rambo Rita Sindereng)

mkdir -p $HOME_DIR/bam
mkdir -p $HOME_DIR/qc

for SAMPLE in "${SAMPLES[@]}"; do
    echo "=== Processing $SAMPLE ==="

    R1=$SCRATCH/${SAMPLE}_1_trimmed.fastq
    R2=$SCRATCH/${SAMPLE}_2_trimmed.fastq

    # 1. Mapping
    echo "1. BWA-MEM mapping..."
    bwa mem -t 8 $REF $R1 $R2 \
      | samtools sort -@ 8 -o $SCRATCH/${SAMPLE}.sorted.bam

    # 2. Index
    echo "2. Index BAM..."
    samtools index -@ 8 $SCRATCH/${SAMPLE}.sorted.bam

    # 3. Stats
    echo "3. Mapping stats..."
    samtools flagstat $SCRATCH/${SAMPLE}.sorted.bam > $SCRATCH/${SAMPLE}_mapping_stats.txt
    samtools idxstats $SCRATCH/${SAMPLE}.sorted.bam > $SCRATCH/${SAMPLE}_idxstats.txt
    samtools stats $SCRATCH/${SAMPLE}.sorted.bam > $SCRATCH/${SAMPLE}_samtools_stats.txt

    # 4. Move to home
    mv $SCRATCH/${SAMPLE}.sorted.bam* $HOME_DIR/bam/
    mv $SCRATCH/${SAMPLE}_*stats.txt $HOME_DIR/qc/

    echo "=== DONE: $SAMPLE ==="
    ls -lh $HOME_DIR/bam/${SAMPLE}.sorted.bam*
done
