#!/bin/bash
#SBATCH --job-name=bwa_index
#SBATCH --mem=60G
#SBATCH --cpus-per-task=8
#SBATCH --time=24:00:00
#SBATCH --output=bwa_index.%j.out
#SBATCH --error=bwa_index.%j.err

source ~./bashrc
conda activate anoa_wgs

cd /mgpfs/home/qhanifa/anoa_analysis

which bwa

bwa index -a bwtsw GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz
