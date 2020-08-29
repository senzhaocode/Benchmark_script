#!/bin/bash

# prints out help if the number of command line paraters is not as expected
if [ $# -ne 4 ]
then
        echo "1: INPUT_OUTPUT_DIR"
        echo "2: SAMPLE_ID"
        echo "3: REFERENCE_HASH_DIR"
        echo "4: REFERENCE_FILE_PATH"
        echo; echo "Exiting."
        exit
fi

# Input (command line) arguments
BASEPATH=$1
ID=$2
REFERENCES_HASH=$3
REFERENCES=$4
# Paths to the binaries and reference files
GENOME="human_g1k_v37_decoy.fasta"
DBSNP="dbsnp_138.b37.vcf"

###################### Start ####################
echo "Start ${ID} sample from File Name ${VCF}"

dragen_reset

# The Job -- variant calling
dragen -f                                                      \
-v                                                             \
-b                         ${BASEPATH}/${ID}.bam               \
--output-directory         ${BASEPATH}/                        \
-r                         ${REFERENCES_HASH}/                 \
--intermediate-results-dir /staging/tmp                        \
--output-file-prefix       ${ID}                               \
--pair-by-name             true                                \
--enable-sort              false                               \
--enable-variant-caller    true                                \
--enable-vcf-compression   false                               \
--enable-vcf-indexing      true                                \
--vc-sample-name           ${ID}

# The Job -- VQSR
dragen -f                                                      \
-v                                                             \
--vqsr-input               ${BASEPATH}/${ID}.vcf               \
--output-directory         ${BASEPATH}/                        \
-r                         ${REFERENCES_HASH}/                 \
--vc-reference             ${REFERENCES}/${GENOME}             \
--intermediate-results-dir /tmp               			\
--output-file-prefix       ${ID}_vqsr                          \
--enable-vqsr              true                                \
--vqsr-annotation "SNP,DP,QD,FS,SOR,ReadPosRankSum,MQRankSum,MQ" \
--vqsr-annotation "INDEL,DP,QD,FS,SOR,ReadPosRankSum,MQRankSum" \
--vqsr-resource "SNP,15.0,${REFERENCES}/hapmap_3.3.b37.vcf" \
--vqsr-resource "SNP,12.0,${REFERENCES}/1000G_omni2.5.b37.vcf" \
--vqsr-resource "SNP,10.0,${REFERENCES}/1000G_phase1.snps.high_confidence.b37.vcf" \
--vqsr-resource "SNP,2.0,${REFERENCES}/dbsnp_138.b37.vcf" \
--vqsr-resource "INDEL,12.0,${REFERENCES}/Mills_and_1000G_gold_standard.indels.b37.vcf" \
--vqsr-resource "INDEL,10.0,${REFERENCES}/1000G_phase1.indels.b37.vcf" \
--vqsr-resource "INDEL,2.0,${REFERENCES}/dbsnp_138.b37.vcf" \
--vqsr-lod-cutoff -5.0     \
--vqsr-tranche 100.00    \
--vqsr-tranche 99.95     \
--vqsr-tranche 99.90     \
--vqsr-tranche 99.80     \
--vqsr-tranche 99.60     \
--vqsr-tranche 99.50     \
--vqsr-tranche 99.40     \
--vqsr-tranche 99.30     \
--vqsr-tranche 99.00     \
--vqsr-tranche 98.50     \
--vqsr-tranche 97.00     \
--vqsr-tranche 96.00     \
--vqsr-tranche 95.00     \
--vqsr-tranche 94.00     \
--vqsr-tranche 93.50     \
--vqsr-tranche 93.00     \
--vqsr-tranche 92.00     \
--vqsr-tranche 90.00     \
--vqsr-filter-level "SNP,99.60"    \
--vqsr-filter-level "INDEL,95.00"  \
--vqsr-num-gaussians 8,2,4,2       \
--enable-vcf-compression   false   \
--enable-vcf-indexing      true         

echo "Close the job"

