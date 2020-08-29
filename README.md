# Benchmark_script

Introduction
------------
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

## Sources of WGS data downloading:

1. GiaB NA12878 (HG001) - [PrecisionFDA](https://precision.fda.gov/challenges/truth) and [SRR6794144](https://trace.ncbi.nlm.nih.gov/Traces/sra/?run=SRR6794144)

2. “Synthetic-diploid” WGS data - [ERR1341793](https://www.ebi.ac.uk/ena/browser/view/ERR1341793) and [ERR1341796](https://www.ebi.ac.uk/ena/browser/view/ERR1341796)


