# `TRexs`

- Table of Contents
  * [Introduction](#introduction)
  * [Installation and usage](#installation)
  * [Input and usage](#input-and-usage)
  * [Resource usage example](#resource-usage-example)
  
## Note
This tool is still in active development and results may change from version to version. Please file an GitHub issue if you run into any bugs or would like to suggest any improvements.
  
## Introduction

`TRexs` is a companion tool to parse known pathogenic repeats genotyped using [`trgt`](https://github.com/PacificBiosciences/trgt).
This tool will generate a HTML report summarising and visualizing the genotyped repeats expansion against a background
of control samples from HPRC. Example of a report is [here](examples/TRexs.html?raw=1). Right click and save the HTML to your computer, then double click to open it on your computer browser (Rename the extension to HTML if your browser changes it to `.txt`).

The tool also attempts to filter a set of potentially pathogenic repeats expansion using
a database manually curated based on multiple sources such as [`DRED`](https://omicslab.genetics.ac.cn/dred),
[`STRipy`](https://stripy.org/) and manual literatures search.

## Installation

`TRexs` depends on a set of tools. To make the installation process easier, we 
provide a `Docker` image if your computer/server supports `Singularity` or `Docker`.

```
# With Docker
docker run --rm kpinpb/trexs:latest TRexs --help

# With Singularity
singularity exec docker://kpinpb/trexs:latest TRexs --help
```

If you would like to install the environments locally, you may use `Conda`:
```
# Installing dependencies with Conda
git clone https://github.com/proteinosome/TRexs.git
cd TRexs
wget 'https://github.com/PacificBiosciences/trgt/releases/download/v0.3.2/trvz-v0.3.2-linux_x86_64.gz'
gunzip trvz-v0.3.2-linux_x86_64.gz && chmod +x trvz-v0.3.2-linux_x86_64

# If using default Conda
conda env create --file env/TRexs.yml

# Faster using Mamba
mamba env create --file env/TRexs.yml

# Install a few dependencies
conda activate TRexs
wget 'https://cran.rstudio.com/src/contrib/box_1.1.2.tar.gz'
R CMD INSTALL --build box_1.1.2.tar.gz
R -e "install.packages('isotree',dependencies=TRUE, repos='http://cran.rstudio.com/')"
Rscript --vanilla TRexs --help
```

## Input and usage

For the impatient, run this on the example HG02055 VCF in this repo (Please define 
the `REF` and `REF_DIR` variables (hg38 FASTA) below to the file path on your server/computer):
```
# Create a sample sheet defining the path to VCF and BAM
echo -e "HG02055\t$(readlink -f examples/HG02055.vcf.gz)\t$(readlink -f examples/HG02055.spanning.bam)" > sample_sheet.tsv

# Define path to hg38 FASTA file
REF=/path/to/hg38.fa
REF_DIR=/path/to

# With Docker
docker run -v $(pwd):/wd -v $(pwd):$(pwd) -v ${REF_DIR}:${REF_DIR} \
  -u $(id -u) --rm \
  kpinpb/trexs:latest TRexs \
  --sample $(pwd)/sample_sheet.tsv
  --reference ${REF}
  --output /wd/report_docker
  
# With Singularity
singularity exec --bind $(pwd),${REF_DIR} \
  docker://kpinpb/trexs:latest TRexs \
  --sample $(pwd)/sample_sheet.tsv \
  --reference ${REF} \
  --output $(pwd)/report_singularity
  
# With local Conda environment
conda activate TRexs

# Define resources (Part of TRexs repo)
control=/path/to/TRexs/resources/control_samples_repeat_2022-10-20.tsv.gz
trvz=/path/to/TRexs/resources/trvz-v0.3.2-linux_x86_64
bed=/path/to/TRexs/resources/pathogenic_repeats.hg38.bed
repeatDB=/path/to/TRexs/resources/repeats_information.tsv

Rscript --vanilla TRexs \
  --sample sample_sheet.tsv \
  --reference ${REF} \
  -c ${control} \
  --trvz ${trvz} \
  -b ${bed} \
  -d ${repeatDB} \
  --output report
```

The `sample_sheet.tsv` file is a tab-delimited text file containing 3 columns (No headers), example:

```
sample1 /path/to/sample1.vcf.gz  /path/to/sample1.spanning.bam
sample2 /path/to/sample2.vcf.gz  /path/to/sample2.spanning.bam
```

where the VCF and `spanning.bam` (sorted) files are generated from `trgt`. Note that the control TSV, 
`trvz` binary, pathogenic bed file and repeats database TSV are not necessary to 
specify with the `Docker` or `Singularity` run because those are already defined and contained
within the container. 

You will also need to ensure that the paths and directories containing the VCF and BAM files
are mounted by `Docker` and `Singularity`. For example, if the VCFs are located at `/funny/path/sample1.vcf.gz`,
you need to run `Docker` with `docker run -v /funny/path:/funny/path` or `Singularity` with
`singularity exec --bind /funny/path`. Examples above show how you can mount the `examples`
directory.

All parameters are detailed below:

```
Usage: /app/TRexs [options]

Options:
        -s CHARACTER, --sample=CHARACTER
                Sample sheet TSV, 3 columns: sample, VCF and trgt sorted bam (in this order). TSV should not have a header

        -c CHARACTER, --control=CHARACTER
                Repeats TSV file for background control. This is provided as control_samples_repeat.tsv.gz on GitHub

        --trvz=CHARACTER
                trvz binary location

        -b CHARACTER, --repeats_bed=CHARACTER
                Pathogenic bed file used to genotype in trgt

        --reference=CHARACTER
                Reference FASTA file. This will be hg38 if using trgt bed file

        -d CHARACTER, --repeatDB=CHARACTER
                Database for repeats annotation. Provided as repeats_information.tsv on GitHub

        --hideGene=CHARACTER
                Genes to hide on the report table. Comma separated. Default: NIPA1, TCF4

        --output=CHARACTER
                Output directory prefix. Default: trgt_report

        -h, --help
                Show this help message and exit
```

## Output
In the output directory, you will find:
* `TRexs.html`: HTML report from the pipeline.
* `potential_pathogenic_repeats.tsv`: This file contains repeat expansions that are 
  longer than the pathogenic threshold. The list is similar to what's in the HTML report.
* `high_potential_pathogenic_repeats.tsv`: This is a subset of `potential_pathogenic_repeats.tsv`
  but requires the repeat motifs to match known pathogenic motif.
* `unknown_or_novel_motifs.tsv`: This file lists repeat expansion with motifs that
  are different from what's genotyped in `TRGT` bed.
* `trvz_logs` and `trvz_figures`: Figures and log file for `TRVZ`. The log folder
  is useful to troubleshoot in case any repeats fail to generate a figure.

## Resource usage example
On a cohort of 1000 samples/VCFs, the tool used 3.4GB RAM and 10 minutes on 4 CPUs.

## Support information
TRexs is a pre-release software intended for research use only and not for use in diagnostic procedures. While efforts have been made to ensure that TRexs lives up to the quality that PacBio strives for, we make no warranty regarding this software.

As TRexs is not covered by any service level agreement or the like, please do not contact a PacBio Field Applications Scientists or PacBio Customer Service for assistance with any TRGT release. Please report all issues through GitHub instead. We make no warranty that any such issue will be addressed, to any extent or within any time frame.

## DISCLAIMER
THIS WEBSITE AND CONTENT AND ALL SITE-RELATED SERVICES, INCLUDING ANY DATA, 
ARE PROVIDED "AS IS," WITH ALL FAULTS, WITH NO REPRESENTATIONS OR WARRANTIES 
OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, ANY 
WARRANTIES OF MERCHANTABILITY, SATISFACTORY QUALITY, NON-INFRINGEMENT OR FITNESS 
FOR A PARTICULAR PURPOSE. YOU ASSUME TOTAL RESPONSIBILITY AND RISK FOR YOUR USE 
OF THIS SITE, ALL SITE-RELATED SERVICES, AND ANY THIRD PARTY WEBSITES OR 
APPLICATIONS. NO ORAL OR WRITTEN INFORMATION OR ADVICE SHALL CREATE A WARRANTY 
OF ANY KIND. ANY REFERENCES TO SPECIFIC PRODUCTS OR SERVICES ON THE WEBSITES 
DO NOT CONSTITUTE OR IMPLY A RECOMMENDATION OR ENDORSEMENT BY PACIFIC BIOSCIENCES.
