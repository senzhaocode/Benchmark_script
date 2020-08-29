#!/bin/bash

# Environment options for Java
export _JAVA_OPTIONS="-XX:ParallelGCThreads=1"
export R_LIBS="/cluster/projects/p21/Software/standard/R_libs_3.4.0"

# prints out help if the number of command line paraters is not as expected
if [ $# -ne 5 ]
then
        echo "1: OUTPUT_DIR"
        echo "2: SAMPLE_ID"
        echo "3: REFERENCE_DIR"
        echo "4: CORES_TOTAL"
        echo "5: MEMORY_FULL"
        echo; echo "Exiting."
        exit
fi

OUTPUT_DIR=$1
SAMPLE_ID=$2
SOFTWARE_BASE=$3
CORES_TOTAL=$4
MEMORY_FULL_VAL=$5

MEMORY_FULL="-Xmx"${MEMORY_FULL_VAL}"g"
MEMORY_HALF=`python -c "print '-Xmx' + str(${MEMORY_FULL_VAL}/2) + 'g'"`
MEMORY_14=`python -c "print '-Xmx' + str(${MEMORY_FULL_VAL}/14) + 'g'"`

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

###################################################
#
#       HaplotypeCaller
#
###################################################
NOW=`date`
echo "[Start]   8       GATK_HaplotypeCaller    " $NOW | tee -a ${LOG_FILE}

declare -A CHROM=( ["1"]="1" ["2"]=2 ["3_21"]="3,21" ["4_22"]="4,22" ["5_19"]="5,19" ["6_20"]="6,20" ["7_18"]="7,18" ["8_17"]="8,17" ["9_16"]="9,16" ["10_15"]="10,15" ["11_14"]="11,14" ["12_13"]="12,13" ["X_Y"]="X,Y" )

# allele-specific
for ID in "${!CHROM[@]}"
do
if [ ${ID} == "1" ] || [ ${ID} == "2" ]
then
gatk --java-options "${MEMORY_14} -XX:ParallelGCThreads=1" HaplotypeCaller \
  -R ${P_GENREF} \
  -I ${OUTPUT_DIR}/BAM/${SAMPLE_ID}_final.bam \
  -O ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.${ID}.HaplotypeCaller_allele_specific.raw.snps.indels.g.vcf \
  -ERC GVCF \
  -L ${CHROM[$ID]} \
  -G StandardAnnotation -G AS_StandardAnnotation \
  >  ${OUTPUT_DIR}/LOGS/08_${SAMPLE_ID}_${ID}_HaplotypeCaller_allele_specific_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/08_${SAMPLE_ID}_${ID}_HaplotypeCaller_allele_specific_stderr.log &
else
  FRONT=`echo $ID | cut -d '_' -f 1`
  BACK=`echo $ID | cut -d '_' -f 2`
gatk --java-options "${MEMORY_14} -XX:ParallelGCThreads=1" HaplotypeCaller \
  -R ${P_GENREF} \
  -I ${OUTPUT_DIR}/BAM/${SAMPLE_ID}_final.bam \
  -O ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.${ID}.HaplotypeCaller_allele_specific.raw.snps.indels.g.vcf \
  -ERC GVCF \
  -L $FRONT \
  -L $BACK \
  -G StandardAnnotation -G AS_StandardAnnotation \
  >  ${OUTPUT_DIR}/LOGS/08_${SAMPLE_ID}_${ID}_HaplotypeCaller_allele_specific_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/08_${SAMPLE_ID}_${ID}_HaplotypeCaller_allele_specific_stderr.log &
fi
done

gatk --java-options "${MEMORY_14} -XX:ParallelGCThreads=1" HaplotypeCaller \
  -R ${P_GENREF} \
  -I ${OUTPUT_DIR}/BAM/${SAMPLE_ID}_final.bam \
  -O ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.other.HaplotypeCaller_allele_specific.raw.snps.indels.g.vcf \
  -ERC GVCF \
  -XL 1 -XL 2 -XL 3 -XL 4 -XL 5 -XL 6 -XL 7 -XL 8 -XL 9 -XL 10 -XL 11 -XL 12 -XL 13 -XL 14 -XL 15 -XL 16 -XL 17 -XL 18 -XL 19 -XL 20 -XL 21 -XL 22 -XL "X" -XL "Y" \
  -G StandardAnnotation -G AS_StandardAnnotation \
  >  ${OUTPUT_DIR}/LOGS/08_${SAMPLE_ID}_other_HaplotypeCaller_allele_specific_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/08_${SAMPLE_ID}_other_HaplotypeCaller_allele_specific_stderr.log &

wait

NOW=`date`
echo "[Finish]  8       GATK_HaplotypeCaller    " $NOW | tee -a ${LOG_FILE}

##########################################
#
#  GenotypeGVCFs (GATK)
#
##########################################
NOW=`date`
echo "[Start]   9       GATK_GenotypeGVCFs    " $NOW | tee -a ${LOG_FILE}

for ID in "${!CHROM[@]}"
do
gatk --java-options "${MEMORY_14}" GenotypeGVCFs \
  -R ${P_GENREF} \
  -V ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.${ID}.HaplotypeCaller_allele_specific.raw.snps.indels.g.vcf \
  -O ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.${ID}.GenotypeGVCFs.raw.snps.indels.vcf \
  -G StandardAnnotation -G AS_StandardAnnotation \
  >  ${OUTPUT_DIR}/LOGS/12_${SAMPLE_ID}_${ID}_GenotypeGVCFs_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/12_${SAMPLE_ID}_${ID}_GenotypeGVCFs_stderr.log &
done

gatk --java-options "${MEMORY_14}" GenotypeGVCFs \
  -R ${P_GENREF} \
  -V ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.other.HaplotypeCaller_allele_specific.raw.snps.indels.g.vcf \
  -O ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.other.GenotypeGVCFs.raw.snps.indels.vcf \
  -G StandardAnnotation -G AS_StandardAnnotation \
  >  ${OUTPUT_DIR}/LOGS/12_${SAMPLE_ID}_other_GenotypeGVCFs_stdout.log \
  2> ${OUTPUT_DIR}/LOGS/12_${SAMPLE_ID}_other_GenotypeGVCFs_stderr.log &

wait

################################################################
# Concatenate VCF file per chromosome to the whole genome
################################################################

head -n 1000 ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.1.GenotypeGVCFs.raw.snps.indels.vcf | grep "^#" > ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.GenotypeGVCFs.raw.snps.indels.vcf 2> ${OUTPUT_DIR}/LOGS/12_${SAMPLE_ID}_CONCATENATE_GenotypeGVCFs_stderr.log
# Gather Chrom 1 => Y
for ID in "${!CHROM[@]}"
do
grep -v "^#" ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.${ID}.GenotypeGVCFs.raw.snps.indels.vcf >> ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.GenotypeGVCFs.raw.snps.indels.vcf 2>> ${OUTPUT_DIR}/LOGS/12_${SAMPLE_ID}_CONCATENATE_GenotypeGVCFs_stderr.log
done
# Sort the gather results
grep "^#" ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.GenotypeGVCFs.raw.snps.indels.vcf > ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.GenotypeGVCFs.raw.snps.indels.sort.vcf && grep -v "^#" ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.GenotypeGVCFs.raw.snps.indels.vcf | LC_ALL=C sort -t $'\t' -V -k1,1 -k2,2n >> ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.GenotypeGVCFs.raw.snps.indels.sort.vcf
# Add the scaffold and config to sorting result
grep -v "^#" ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.other.GenotypeGVCFs.raw.snps.indels.vcf >> ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.GenotypeGVCFs.raw.snps.indels.sort.vcf
rm ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.GenotypeGVCFs.raw.snps.indels.vcf

NOW=`date`
echo "[Finish]  9       GATK_GenotypeGVCFs    " $NOW | tee -a ${LOG_FILE}

##########################################
# 
# GATK VariantRecalibrator: for INDEL first
#
###########################################
NOW=`date`
echo "[Start]   10       GATK_VariantRecalibrator    " $NOW | tee -a ${LOG_FILE}

# For INDEL VariantRecalibrator
gatk --java-options "${MEMORY_FULL}" VariantRecalibrator \
  -R ${P_GENREF} \
  -mode INDEL -AS \
  -V ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.GenotypeGVCFs.raw.snps.indels.sort.vcf \
  --resource:mills,known=false,training=true,truth=true,prior=12.0 ${P_MDINDL} \
  --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${P_DBSNPN} \
  --resource:1000G,known=false,training=true,truth=false,prior=10.0 ${P_TGINDL} \
  -an QD -an DP -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
  -tranche 100.0 -tranche 99.95 -tranche 99.9 -tranche 99.5 -tranche 99.0 -tranche 97.0 -tranche 96.0 -tranche 95.0 -tranche 94.0 -tranche 93.5 -tranche 93.0 -tranche 92.0 -tranche 91.0 -tranche 90.0 \
  --max-gaussians 2 \
  -O ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.AS.indel.recal \
  --tranches-file ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.AS.indel.tranches \
  --rscript-file ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.plots.AS.indel.R \
  >  ${OUTPUT_DIR}/LOGS/13_${SAMPLE_ID}_VariantRecalibrator_indel_stdout.log \
  2>  ${OUTPUT_DIR}/LOGS/13_${SAMPLE_ID}_VariantRecalibrator_indel_stderr.log

# For INDEL ApplyRecalibration
gatk --java-options "${MEMORY_FULL}" ApplyVQSR \
  -R ${P_GENREF} \
  -mode INDEL -AS \
  -V ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.GenotypeGVCFs.raw.snps.indels.sort.vcf \
  -O ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.ASfiltered.indels.sort.vcf \
  --recal-file ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.AS.indel.recal \
  --tranches-file ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.AS.indel.tranches \
  -ts-filter-level 95.0 \
  >  ${OUTPUT_DIR}/LOGS/13_${SAMPLE_ID}_ApplyRecalibration_indel_stdout.log \
  2>  ${OUTPUT_DIR}/LOGS/13_${SAMPLE_ID}_ApplyRecalibration_indel_stderr.log

###########################################
# 
# GATK VariantRecalibrator: for SNP second
#
###########################################
# For SNP VariantRecalibrator
gatk --java-options "${MEMORY_FULL}" VariantRecalibrator \
  -R ${P_GENREF} \
  -mode SNP -AS \
  -V ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.ASfiltered.indels.sort.vcf \
  --resource:hapmap,known=false,training=true,truth=true,prior=15.0 ${P_HAMAP} \
  --resource:omni,known=false,training=true,truth=true,prior=12.0 ${P_OMNI} \
  --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${P_DBSNPN} \
  --resource:1000G,known=false,training=true,truth=false,prior=10.0 ${P_PHASE1} \
  -an QD -an DP -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
  -tranche 100.0 -tranche 99.9 -tranche 99.8 -tranche 99.6 -tranche 99.5 -tranche 99.4 -tranche 99.3 -tranche 99.0 -tranche 98.0 -tranche 97.0 -tranche 90.0 \
  --max-gaussians 4 \
  -O ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.AS.snp.recal \
  --tranches-file ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.AS.snp.tranches \
  --rscript-file ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.plots.AS.snp.R \
  >  ${OUTPUT_DIR}/LOGS/13_${SAMPLE_ID}_VariantRecalibrator_snp_stdout.log \
  2>  ${OUTPUT_DIR}/LOGS/13_${SAMPLE_ID}_VariantRecalibrator_snp_stderr.log 

# For SNPs ApplyRecalibration
gatk --java-options "${MEMORY_FULL}" ApplyVQSR \
  -R ${P_GENREF} \
  -mode SNP -AS \
  -V ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.ASfiltered.indels.sort.vcf \
  -O ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.ASfiltered.indels.snps.sort.vcf \
  --recal-file ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.AS.snp.recal \
  --tranches-file ${OUTPUT_DIR}/HAPLOTYPE_CALLER/${SAMPLE_ID}.VariantRecalibrator.AS.snp.tranches \
  -ts-filter-level 99.6 \
  >  ${OUTPUT_DIR}/LOGS/13_${SAMPLE_ID}_ApplyRecalibration_snp_stdout.log \
  2>  ${OUTPUT_DIR}/LOGS/13_${SAMPLE_ID}_ApplyRecalibration_snp_stderr.log

NOW=`date`
echo "[Finish]  10       GATK_VariantRecalibrator    " $NOW | tee -a ${LOG_FILE}
