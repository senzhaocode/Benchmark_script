#!/bin/bash

# Environment options for Java
export _JAVA_OPTIONS="-XX:ParallelGCThreads=1"

# prints out help if the number of command line paraters is not as expected
if [ $# -ne 7 ]
then
	echo "1: INPUT_DIR"
	echo "2: OUTPUT_DIR"
	echo "3: SAMPLE_ID"
	echo "4: FLOWCELL_LANE_LIST"
	echo "5: REFERENCE_DIR"
	echo "6: CORES_TOTAL"
	echo "7: MEMORY_FULL"
	echo; echo "Exiting."
	exit
fi

# Pipeline steps
STEP_00_FASTQC="FLASE"
STEP_01_BWA="TRUE"
STEP_02_SORTING="TRUE"
STEP_03_MARK_DUP="TRUE"
STEP_06_BASE_RECALIBR="TRUE"
STEP_07_PRINTREAD="TRUE"

# Input (command line) arguments
INPUT_DIR=$1
OUTPUT_DIR=$2
SAMPLE_ID=$3
FLOWCELL_LANE_LIST=$4
SOFTWARE_BASE=$5
CORES_TOTAL=$6
MEMORY_FULL_VAL=$7

MEMORY_FULL="-Xmx"${MEMORY_FULL_VAL}"g"
MEMORY_HALF=`python -c "print '-Xmx' + str(${MEMORY_FULL_VAL}/2) + 'g'"`
MEMORY_13=`python -c "print '-Xmx' + str(${MEMORY_FULL_VAL}/14) + 'g'"`

# Creation of output subdirectories
mkdir ${OUTPUT_DIR}/COVERAGE
mkdir ${OUTPUT_DIR}/BWA
mkdir ${OUTPUT_DIR}/FASTQC
mkdir ${OUTPUT_DIR}/GATK
mkdir ${OUTPUT_DIR}/LOGS
mkdir ${OUTPUT_DIR}/BAM
mkdir ${OUTPUT_DIR}/HAPLOTYPE_CALLER
mkdir ${OUTPUT_DIR}/LOGS

# Master log file (general progress messages)
LOG_FILE=${OUTPUT_DIR}/LOGS/${SAMPLE_ID}.log

# Logging of the input arguments (STDOUT and the master log file)
echo "Input command line parameters:" | tee -a ${LOG_FILE}
echo "1: INPUT_DIR              " $1 | tee -a ${LOG_FILE}
echo "2: OUTPUT_DIR             " $2 | tee -a ${LOG_FILE}
echo "3: SAMPLE_ID              " $3 | tee -a ${LOG_FILE}
echo "4: FLOWCELL_LANE_LIST     " $4 | tee -a ${LOG_FILE}
echo "5: REFERENCE_DIR     	" $4 | tee -a ${LOG_FILE}
echo "6: CORES_TOTAL            " $5 | tee -a ${LOG_FILE}
echo "7: MEMORY_FULL            " $6 | tee -a ${LOG_FILE}
echo


# Paths to the binaries and reference files
P_GENREF="${SOFTWARE_BASE}/human_g1k_v37_decoy.fasta"
P_GENREF_DICT="${SOFTWARE_BASE}/human_g1k_v37_decoy.dict"
P_TGINDL="${SOFTWARE_BASE}/1000G_phase1.indels.b37.vcf"
P_MDINDL="${SOFTWARE_BASE}/Mills_and_1000G_gold_standard.indels.b37.vcf"
P_DBSNPN="${SOFTWARE_BASE}/dbsnp_138.b37.vcf"
P_COSMIC="${SOFTWARE_BASE}/cosmic_v64_sorted_b37.vcf"
P_PHASE1="${SOFTWARE_BASE}/1000G_phase1.snps.high_confidence.b37.vcf"
P_HAMAP="${SOFTWARE_BASE}/hapmap_3.3.b37.vcf"
P_OMNI="${SOFTWARE_BASE}/1000G_omni2.5.b37.vcf"
B37INDEX=${P_GENREF}

###################################################
#
#		Mapping
#
###################################################

NOW=`date`
echo "[Start]   1	BWA-mem " $NOW | tee -a ${LOG_FILE}

for FLOWCELL_LANE in ${FLOWCELL_LANE_LIST}
do

bwa mem \
  -t ${CORES_TOTAL} \
  -R "@RG\tID:${SAMPLE_ID}_${FLOWCELL_LANE}\tSM:${SAMPLE_ID}\tLB:${SAMPLE_ID}\tPL:illumina" \
  -M \
  -V \
  ${B37INDEX} \
  ${INPUT_DIR}/${SAMPLE_ID}_${FLOWCELL_LANE}_R1.* \
  ${INPUT_DIR}/${SAMPLE_ID}_${FLOWCELL_LANE}_R2.* \
  >  ${OUTPUT_DIR}/BWA/${SAMPLE_ID}_${FLOWCELL_LANE}.sam \
  2> ${OUTPUT_DIR}/LOGS/01_${SAMPLE_ID}_${FLOWCELL_LANE}_bwa_mem.log

done

NOW=`date`
echo "[Finish]  1       BWA-mem " $NOW  | tee -a ${LOG_FILE}

###############################################
#
#	Sort and Markduplicates
#
###############################################

NOW=`date`
echo "[Start]  2       Picard_SortSam  " $NOW  | tee -a ${LOG_FILE}

for FLOWCELL_LANE in ${FLOWCELL_LANE_LIST}
do

gatk --java-options "${MEMORY_FULL} -Djava.io.tmpdir=${OUTPUT_DIR}/TMP" SortSam \
  --SORT_ORDER coordinate \
  --CREATE_INDEX true \
  --MAX_RECORDS_IN_RAM 5000000 \
  -I ${OUTPUT_DIR}/BWA/${SAMPLE_ID}_${FLOWCELL_LANE}.sam \
  -O ${OUTPUT_DIR}/BWA/${SAMPLE_ID}_${FLOWCELL_LANE}_sorted.bam \
  >  ${OUTPUT_DIR}/LOGS/02_${SAMPLE_ID}_${FLOWCELL_LANE}_SortSam_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/02_${SAMPLE_ID}_${FLOWCELL_LANE}_SortSam_stderr.log

done

NOW=`date`
echo "[Finish]  2       Picard_SortSam  " $NOW  | tee -a ${LOG_FILE}

############### MarkDup ###############

NOW=`date`
echo "[Start]   3       Picard_MarkDuplicates   " $NOW  | tee -a ${LOG_FILE}

for FLOWCELL_LANE in ${FLOWCELL_LANE_LIST}
do
BAMS="${OUTPUT_DIR}/BWA/${SAMPLE_ID}_${FLOWCELL_LANE}_sorted.bam"
done

echo "[MarkDuplicates]  processing      ${BAMS}" | tee -a ${LOG_FILE}

gatk --java-options "${MEMORY_FULL} -Djava.io.tmpdir=${OUTPUT_DIR}/TMP" MarkDuplicates \
  -I ${BAMS} \
  -M ${OUTPUT_DIR}/BAM/${SAMPLE_ID}_MarkDup.metric \
  -ASO coordinate \
  --CREATE_INDEX true \
  --MAX_RECORDS_IN_RAM 5000000 \
  -O ${OUTPUT_DIR}/BAM/${SAMPLE_ID}_MarkDup.bam \
  >  ${OUTPUT_DIR}/LOGS/03_${SAMPLE_ID}_MarkDup_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/03_${SAMPLE_ID}_MarkDup_stderr.log

NOW=`date`
echo "[Finish]  3       Picard_MarkDuplicates   " $NOW  | tee -a ${LOG_FILE}

############### BaseRecalibrator ###############

NOW=`date`
echo "[Start]   6       GATK_BaseRecalibrator   " $NOW | tee -a ${LOG_FILE}

INPUT_BAM_FILE="${OUTPUT_DIR}/BAM/${SAMPLE_ID}_MarkDup.bam"
declare -A CHROM=( ["1"]="1" ["2"]=2 ["3_21"]="3,21" ["4_22"]="4,22" ["5_19"]="5,19" ["6_20"]="6,20" ["7_18"]="7,18" ["8_17"]="8,17" ["9_16"]="9,16" ["10_15"]="10,15" ["11_14"]="11,14" ["12_13"]="12,13" ["X_Y"]="X,Y" )

for ID in "${!CHROM[@]}"
do

if [ ${ID} == "1" ] || [ ${ID} == "2" ]
then
gatk --java-options "${MEMORY_13} -XX:ParallelGCThreads=1" BaseRecalibrator \
  -R ${P_GENREF} \
  -I ${INPUT_BAM_FILE} \
  -L ${CHROM[$ID]} \
  -O ${OUTPUT_DIR}/GATK/${SAMPLE_ID}_BaseRecalibrator_data.${ID}.grp \
  --known-sites ${P_PHASE1} \
  --known-sites ${P_DBSNPN} \
  --known-sites ${P_TGINDL} \
  --known-sites ${P_MDINDL} \
  >  ${OUTPUT_DIR}/LOGS/06_${SAMPLE_ID}_${ID}_BaseRecalibrator_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/06_${SAMPLE_ID}_${ID}_BaseRecalibrator_stderr.log &
else
  FRONT=`echo $ID | cut -d '_' -f 1`
  BACK=`echo $ID | cut -d '_' -f 2`
gatk --java-options "${MEMORY_13} -XX:ParallelGCThreads=1" BaseRecalibrator \
  -R ${P_GENREF} \
  -I ${INPUT_BAM_FILE} \
  -L $FRONT \
  -L $BACK \
  -O ${OUTPUT_DIR}/GATK/${SAMPLE_ID}_BaseRecalibrator_data.${ID}.grp \
  --known-sites ${P_PHASE1} \
  --known-sites ${P_DBSNPN} \
  --known-sites ${P_TGINDL} \
  --known-sites ${P_MDINDL} \
  >  ${OUTPUT_DIR}/LOGS/06_${SAMPLE_ID}_${ID}_BaseRecalibrator_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/06_${SAMPLE_ID}_${ID}_BaseRecalibrator_stderr.log &
fi

done

gatk --java-options "${MEMORY_13} -XX:ParallelGCThreads=1" BaseRecalibrator \
  -R ${P_GENREF} \
  -I ${INPUT_BAM_FILE} \
  -XL 1 -XL 2 -XL 3 -XL 4 -XL 5 -XL 6 -XL 7 -XL 8 -XL 9 -XL 10 -XL 11 -XL 12 -XL 13 -XL 14 -XL 15 -XL 16 -XL 17 -XL 18 -XL 19 -XL 20 -XL 21 -XL 22 -XL "X" -XL "Y" \
  -O ${OUTPUT_DIR}/GATK/${SAMPLE_ID}_BaseRecalibrator_data.other.grp \
  --known-sites ${P_PHASE1} \
  --known-sites ${P_DBSNPN} \
  --known-sites ${P_TGINDL} \
  --known-sites ${P_MDINDL} \
  >  ${OUTPUT_DIR}/LOGS/06_${SAMPLE_ID}_other_BaseRecalibrator_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/06_${SAMPLE_ID}_other_BaseRecalibrator_stderr.log & 

wait
NOW=`date`
echo "[Finish]  6       GATK_BaseRecalibrator   " $NOW | tee -a ${LOG_FILE}

############### GatherBQSRReports ########

NOW=`date`
echo "[Start]   7       GATK_GatherBQSRReports   " $NOW | tee -a ${LOG_FILE}

INPUT_BQSR_FILE=""
for ID in "${!CHROM[@]}"
do
INPUT_BQSR_FILE="${INPUT_BQSR_FILE} -I ${OUTPUT_DIR}/GATK/${SAMPLE_ID}_BaseRecalibrator_data.${ID}.grp"
done
INPUT_BQSR_FILE="${INPUT_BQSR_FILE} -I ${OUTPUT_DIR}/GATK/${SAMPLE_ID}_BaseRecalibrator_data.other.grp"

gatk --java-options "${MEMORY_FULL}" GatherBQSRReports \
  ${INPUT_BQSR_FILE} \
  -O ${OUTPUT_DIR}/GATK/${SAMPLE_ID}_BaseRecalibrator_data.grp \
  >  ${OUTPUT_DIR}/LOGS/07_${SAMPLE_ID}_GatherBQSRReports_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/07_${SAMPLE_ID}_GatherBQSRReports_stderr.log

NOW=`date`
echo "[Finish]  7       GATK_GatherBQSRReports   " $NOW | tee -a ${LOG_FILE}

############### PrintReads ###############

INPUT_BAM_FILE="${OUTPUT_DIR}/BAM/${SAMPLE_ID}_MarkDup.bam"

NOW=`date`
echo "[Start]   8       GATK_PrintReads " $NOW | tee -a ${LOG_FILE}

gatk --java-options "${MEMORY_FULL} -Djava.io.tmpdir=${OUTPUT_DIR}/TMP" ApplyBQSR \
  -R ${P_GENREF} \
  -I ${INPUT_BAM_FILE} \
  -bqsr ${OUTPUT_DIR}/GATK/${SAMPLE_ID}_BaseRecalibrator_data.grp \
  -O ${OUTPUT_DIR}/BAM/${SAMPLE_ID}_final.bam \
  >  ${OUTPUT_DIR}/LOGS/08_${SAMPLE_ID}_PrintReads_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/08_${SAMPLE_ID}_PrintReads_stderr.log

NOW=`date`
echo "[Finish]  8       GATK_PrintReads " $NOW | tee -a ${LOG_FILE}
