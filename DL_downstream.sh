#!/bin/bash

# prints out help if the number of command line paraters is not as expected
if [ $# -ne 8 ]
then
        echo "1: SHARE_VOLUME"
        echo "2: INPUT_BAM"
        echo "3: OUTPUT_DIR"
        echo "4: SAMPLE_ID"
        echo "5: CONTAINER_PATH"
        echo "6: REFERENCE_DIR"
        echo "7: MODEL_PATH"
        echo "8: TASK_TOTAL"
        echo; echo "Exiting."
        exit
fi

# set to path parameters
share_directory=$1
BAM=$2
OUTPUT_DIR=$3
SAMPLE=$4
container=$5
REF=$6
MODEL=$7
N_SHARDS=$8
mkdir "${share_directory}/${OUTPUT_DIR}"

# set and divide tasks
N_TOTAL="000"${N_SHARDS}
job=("sample1")

for (( i=0; i<${N_SHARDS}; i++ ))
do
if (( $i < 10 )); then
	sample1[$i]="0000"$i
else
	sample1[$i]="000"$i
fi
done

##### main jobscript #####
#// step 1//
time seq 0 $((N_SHARDS-1)) | parallel -k --line-buffer \
 singularity exec -B ${share_directory}:/cluster/ ${container} /opt/deepvariant/bin/make_examples \
 --mode calling \
 --ref ${share_directory}/${REF} \
 --reads ${share_directory}/${BAM} \
 --examples "${share_directory}/${OUTPUT_DIR}/${SAMPLE}.tfrecord@${N_SHARDS}.gz" \
 --gvcf "${share_directory}/${OUTPUT_DIR}/${SAMPLE}.gvcf.tfrecord@${N_SHARDS}.gz" \
 --task {}

#// step 2 - 60 loop //
for id in "${job[@]}"
do
	ref=$id[@]
	for S in ${!ref}
	do
	singularity exec -B ${share_directory}:/cluster/ ${container} /opt/deepvariant/bin/call_variants \
 	--outfile "${share_directory}/${OUTPUT_DIR}/${SAMPLE}.cv.tfrecord-${S}-of-${N_TOTAL}.gz" \
 	--examples "${share_directory}/${OUTPUT_DIR}/${SAMPLE}.tfrecord-${S}-of-${N_TOTAL}.gz" \
 	--checkpoint ${share_directory}/${MODEL} &
	done
	wait
done

#// step 3 //
singularity exec -B ${share_directory}:/cluster/ ${container} /opt/deepvariant/bin/postprocess_variants \
 --gvcf_outfile "${share_directory}/${OUTPUT_DIR}/${SAMPLE}.deepvariant.g.vcf.gz" \
 --outfile "${share_directory}/${OUTPUT_DIR}/${SAMPLE}.deepvariant.vcf.gz" \
 --nonvariant_site_tfrecord_path "${share_directory}/${OUTPUT_DIR}/${SAMPLE}.gvcf.tfrecord@${N_SHARDS}.gz" \
 --infile "${share_directory}/${OUTPUT_DIR}/${SAMPLE}.cv.tfrecord@${N_SHARDS}.gz" \
 --ref ${share_directory}/${REF}

