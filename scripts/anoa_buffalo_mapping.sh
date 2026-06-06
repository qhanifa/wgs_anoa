#!/bin/bash
#SBATCH --job-name=anoa_map
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/map_Anara.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/map_Anara.%j.err

# Load modules (adjust for your HPC)
# module load bwa/0.7.17 samtools/1.15
# OR activate conda
source ~/.bashrc
conda activate anoa_wgs

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
SCRATCH=/mgpfs/home/qhanifa/_scratch


REF=$HOME_DIR/reference/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz
R1=$SCRATCH/Anara_1_trimmed.fastq
R2=$SCRATCH/Anara_2_trimmed.fastq

cd $SCRATCH

# 1. Mapping
echo "1. BWA-MEM mapping..."
bwa mem -t 8 $REF $R1 $R2 \
  | samtools sort -@ 8 -o Anara.sorted.bam

# 2. Index
echo "2. Index BAM..."
samtools index -@ 8 Anara.sorted.bam

# 3. Stats
echo "3. Mapping stats..."
samtools flagstat Anara.sorted.bam > Anara_mapping_stats.txt
samtools idxstats Anara.sorted.bam > Anara_idxstats.txt
samtools stats Anara.sorted.bam > Anara_samtools_stats.txt

# 4. Move back to home
mkdir -p $HOME_DIR/bam
mkdir -p $HOME_DIR/qc

mv Anara.sorted.bam* $HOME_DIR/bam/
mv Anara_*stats.txt $HOME_DIR/qc/

echo "=== DONE ==="
echo "Files:"
ls -lh $HOME_DIR/bam/Anara.sorted.bam*

