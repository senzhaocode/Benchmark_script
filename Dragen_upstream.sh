#!/bin/bash

# prints out help if the number of command line paraters is not as expected
if [ $# -ne 6 ]
then
        echo "1: INPUT_DIR"
        echo "2: SAMPLE_ID"
        echo "3: FLOWCELL_LANE"
        echo "4: OUTPUT_DIR"
        echo "5: REFERENCE_HASH_DIR"
        echo "6: REFERENCE_FILE_PATH"
        echo; echo "Exiting."
        exit
fi

# Input (command line) arguments
INPUT_DIR=$1
ID=$2
FLOWCELL_LANE=$3
BASEPATH=$4
REFERENCES_HASH=$5
REFERENCES=$6
# Paths to the binaries and reference files
GENOME="human_g1k_v37_decoy.fasta"
DBSNP="dbsnp_138.b37.vcf"

###################### Start #####################
echo "Start ${ID} sample from File Name"

# The Job
dragen_reset

dragen -f                                                                     \
-v -l                                                                         \
-1                         ${INPUT_DIR}/${ID}_${FLOWCELL_LANE}_R1.fastq.gz    \
-2                         ${INPUT_DIR}/${ID}_${FLOWCELL_LANE}_R2.fastq.gz    \
-r                         ${REFERENCES_HASH}/                                \
--output-directory         ${BASEPATH}/                                       \
--output-file-prefix       ${ID}                                              \
--vc-reference             ${REFERENCES}/${GENOME}                            \
--dbsnp                    ${REFERENCES}/${DBSNP}                             \
--intermediate-results-dir /staging/tmp                 	                  \
--enable-map-align         true                                               \
--enable-map-align-output  true                                               \
--enable-sort              true                                               \
--enable-bam-indexing      true                                               \
--enable-duplicate-marking true                                               \
--remove-duplicates        false                                              \
--preserve-bqsr-tags       true                                

echo "Close the job ${ID}"

