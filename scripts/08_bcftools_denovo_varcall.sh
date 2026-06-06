#!/bin/bash

#SBATCH --job-name=bcftools_denovo
#SBATCH --partition=medium-small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=12:00:00
#SBATCH --output=/mgpfs/home/qhanifa/anoa_analysis/logs/bcftools_denovo.%j.out
#SBATCH --error=/mgpfs/home/qhanifa/anoa_analysis/logs/bcftools_denovo.%j.err

source ~/.bashrc
conda activate anoa_wgs

CHR=$1

if [[ -z "$CHR" ]]; then
    echo "Usage: sbatch bcftools_denovo.sh <CHR>"
    echo "  CHR: 1-29, X, or full accession (e.g. NC_037328.1)"
    exit 1
fi

PLOIDY_FILE=""
if [[ "$CHR" == "X" ]]; then
    PLOIDY_FILE=/mgpfs/home/qhanifa/anoa_analysis/chrX_ploidy.txt
fi

# Map chromosome number/name to ARS-UCD2.0 NCBI accession
declare -A CHR_MAP
CHR_MAP[1]=NC_037328.1  CHR_MAP[2]=NC_037329.1  CHR_MAP[3]=NC_037330.1
CHR_MAP[4]=NC_037331.1  CHR_MAP[5]=NC_037332.1  CHR_MAP[6]=NC_037333.1
CHR_MAP[7]=NC_037334.1  CHR_MAP[8]=NC_037335.1  CHR_MAP[9]=NC_037336.1
CHR_MAP[10]=NC_037337.1 CHR_MAP[11]=NC_037338.1 CHR_MAP[12]=NC_037339.1
CHR_MAP[13]=NC_037340.1 CHR_MAP[14]=NC_037341.1 CHR_MAP[15]=NC_037342.1
CHR_MAP[16]=NC_037343.1 CHR_MAP[17]=NC_037344.1 CHR_MAP[18]=NC_037345.1
CHR_MAP[19]=NC_037346.1 CHR_MAP[20]=NC_037347.1 CHR_MAP[21]=NC_037348.1
CHR_MAP[22]=NC_037349.1 CHR_MAP[23]=NC_037350.1 CHR_MAP[24]=NC_037351.1
CHR_MAP[25]=NC_037352.1 CHR_MAP[26]=NC_037353.1 CHR_MAP[27]=NC_037354.1
CHR_MAP[28]=NC_037355.1 CHR_MAP[29]=NC_037356.1 CHR_MAP[X]=NC_037357.1

if [[ -n "${CHR_MAP[$CHR]}" ]]; then
    ACCESSION=${CHR_MAP[$CHR]}
elif [[ "$CHR" == NC_* ]]; then
    ACCESSION=$CHR
else
    echo "ERROR: Unknown chromosome '$CHR'. Use 1-29, X, or a full NC_ accession."
    exit 1
fi

HOME_DIR=/mgpfs/home/qhanifa/anoa_analysis
CRAM_DIR=$HOME_DIR/cram
REF=$HOME_DIR/reference/GCF_002263795.3_ARS-UCD2.0_genomic.fna.gz
OUT=$HOME_DIR/vcf_denovo
mkdir -p $OUT

CRAMS=$(ls ${CRAM_DIR}/*.cram | tr '\n' ' ')

echo "=== Mpileup + Call: chr${CHR} (${ACCESSION}) ==="
bcftools mpileup \
    -f $REF \
    -r ${ACCESSION} \
    -q 20 -Q 20 \
    --threads 4 \
    $CRAMS | \
bcftools call \
    -m \
    --threads 4 \
    ${PLOIDY_FILE:+--ploidy-file $PLOIDY_FILE} \
    -Oz -o ${OUT}/all_samples_chr${CHR}.vcf.gz

echo "=== Indexing: chr${CHR} ==="
bcftools index -t ${OUT}/all_samples_chr${CHR}.vcf.gz

echo "=== DONE: chr${CHR} ==="
