# Benchmark_script

## Introduction

The scripts and tools used for benchmarking evalutation of three germline variants calling pipelines ([GATK](https://gatk.broadinstitute.org/hc/en-us), [DRAGEN](https://www.illumina.com/products/by-type/informatics-products/dragen-bio-it-platform.html) and [DeepVariant](https://github.com/google/deepvariant)) in the paper [Zhao *et al.* 2020. *BioRxiv*. Accuracy and efficiency of germline variant calling pipelines for human genome data](https://www.biorxiv.org/content/10.1101/2020.03.27.011767v1)

## Requirements:
  
1. GATK pipeline dependencies:
 
   * [BWA v0.7.17](https://github.com/lh3/bwa)
   * [python2 v(>=2.7.15)](https://www.python.org/downloads/)
   * [Java SE Development Kit 8](https://www.oracle.com/java/technologies/javase/javase-jdk8-downloads.html)
   * [GATK v4.1.0.0](https://gatk.broadinstitute.org/hc/en-us)

2. DeepVariant pipeline dependencies:

   * [DeepVariant v0.7.2](https://github.com/google/deepvariant)
   * [GNU Parallel](https://www.gnu.org/software/parallel/)
   * [Singularity v(>2.6.1)](https://github.com/hpcng/singularity)
   
3. [DRAGEN platform v3.3.11](https://emea.support.illumina.com/sequencing/sequencing_software/dragen-bio-it-platform/downloads.html) 

4. Genome reference, annotation and index files ([b37](https://gatk.broadinstitute.org/hc/en-us/articles/360035890811-Resource-bundle))

## Sources of WGS data downloading:

1. GiaB NA12878 (HG001) - [PrecisionFDA](https://precision.fda.gov/challenges/truth) and [SRR6794144](https://trace.ncbi.nlm.nih.gov/Traces/sra/?run=SRR6794144)

2. “Synthetic-diploid” WGS data - [ERR1341793](https://www.ebi.ac.uk/ena/browser/view/ERR1341793) and [ERR1341796](https://www.ebi.ac.uk/ena/browser/view/ERR1341796)

3. Simulated WGS data - in silico reads were synthesized using the tool [NeatGenReads](https://github.com/zstephens/neat-genreads), and available on request.

## Variants calling via pipelines

1. GATK running, e.g. GiaB NA12878 sample

```bash
# Upstream analysis from fastq to BAM
bash GATK_upstream.sh \
  "/cluster/projects/p21/Projects/BigMed_WGS_benchmark_data" \ # Input fastq directory
  "/cluster/projects/p21/Analysis/GATK/BigMed_WGS_benchmark_output" \ # Output directory (as input directory of downstream script)
  "HG001-NA12878-50x" \ # sample name of fastq file
  "AHLLWWBBXX" \ # flow cell name of fastq file
  "/cluster/projects/p21/Projects/references" \ # directory of genome reference, annotation and index files
  64 \ # number of cores allocated
  128 # RAM size allocated (Gb)
  
# Downstream analysis from BAM to VCF
bash GATK_downstream.sh \
  "/cluster/projects/p21/Analysis/GATK/BigMed_WGS_benchmark_output" \ # Input BAM directory (also as Output path)
  "HG001-NA12878-50x" \ # sample name of fastq file
  "/cluster/projects/p21/Projects/references" \ # directory of genome reference, annotation and index files
  64 \ # number of cores allocated
  128 # RAM size allocated (Gb)
```

2. DRAGEN running, e.g. GiaB NA12878 sample

```bash
# Upstream analysis from fastq to BAM
bash Dragen_upstream.sh \
  "/cluster/projects/p21/Projects/BigMed_WGS_benchmark_data" \ # Input fastq directory
  "HG001-NA12878-50x" \ # sample name of fastq file
  "AHLLWWBBXX" \ # flow cell name of fastq file
  "/cluster/projects/p21/Analysis/DRAGEN/BigMed_WGS_benchmark_output" \ # Output directory (as input directory of downstream script)
  "/cluster/projects/p21/Projects/dragen_v3" \ # Directory of reference hash table built for DRAGEN
  "/cluster/projects/p21/Projects/references" # directory of genome reference, annotation and index files
  
# Downstream analysis from BAM to VCF
bash Dragen_downstream.sh \
  "/cluster/projects/p21/Analysis/DRAGEN/BigMed_WGS_benchmark_output" \ # Input BAM directory (also as Output path)
  "HG001-NA12878-50x" \ # sample name of fastq file
  "/cluster/projects/p21/Projects/dragen_v3" \ # Directory of reference hash table built for DRAGEN
  "/cluster/projects/p21/Projects/references" # directory of genome reference, annotation and index files
```

3. DeepVariant running, e.g. GiaB NA12878 sample

```bash
# Downstream analysis from BAM to fastq
bash DL_downstream.sh \
  "/cluster" \ # '/cluster' directory on the host system is binded and mounted to the directory inside of container (users have to change it for their own host)
  "projects/p21/Analysis/GATK/BigMed_WGS_benchmark_output/BAM/HG001-NA12878-50x_final.bam" \ # relative path of input BAM file generated from GATK upstream analysis
  "projects/p21/Analysis/DL/BigMed_WGS_benchmark_output" \ # relative path of output directory
  "HG001-NA12878-50x" \ # sample name of fastq file
  "/cluster/projects/p21/Projects/DL_container/deepvariant_container.sqsh" \ # full path of DeepVariant Singularity container image file
  "projects/p21/Projects/references/human_g1k_v37_decoy.fasta" \ # relative path of genome reference sequence
  "projects/p21/Projects/DL_container/model.ckpt" \ # relative path of deep learning model used by Deepvariant
  60 # number of cores allocated
```
