#!/usr/bin/env Rscript
library(optparse)
script_path <- box::file()

option_list = list(
  make_option(c("-s", "--sample"), type="character", default=NULL, 
              help="(Required) Sample sheet TSV, 3 columns: sample, VCF and trgt sorted bam (in this order). TSV should not have a header",
              metavar="character"),
  make_option(c("-c", "--control"), type="character", default="/app/control_samples_repeat_2023-4-10.tsv.gz", 
              help="(Required) Repeats TSV file for background control. This is provided as control_samples_repeat.tsv.gz on GitHub", metavar="character"),
  make_option(c("--trvz"), type="character", default="/app/trvz", 
              help="(Required) trvz binary location", metavar="character"),
  make_option(c("-b", "--repeats_bed"), default="/app/pathogenic_repeats.hg38.bed", type="character", 
              help="(Required) Pathogenic bed file used to genotype in trgt", metavar="character"),
  make_option(c("--reference"), type="character", default=NULL, 
              help="(Required) Reference FASTA file. This will be hg38 if using trgt bed file", metavar="character"),
  make_option(c("-d", "--repeatDB"), type="character", default="/app/repeats_information.tsv", 
              help="(Required) Database for repeats annotation. Provided as repeats_information.tsv on GitHub", metavar="character"),
  make_option(c("--hideGene"), type="character", default="NIPA1, TCF4", 
              help='(Optional) Genes to hide on the report table. Comma separated. Set input to "" if do not want to filter.
                   Default: %default', metavar="character"),
  make_option(c("--knownOnly"), type="logical", default=TRUE, 
              help='(Optional) Show only loci known to have pathogenic repeats. Default: TRUE.
                   Default: %default', metavar="logical"),
  make_option(c("--output"), type="character", default="trgt_report", 
              help="(Optional) Output directory prefix. Specify $(pwd) before output dir if using Docker or Singularity.
                   Default: %default", metavar="character")
)

opt_parser = OptionParser(option_list=option_list,
                          description = '
                          Example command below. If using Docker/Singularity, there is no need to specify 
                          control, trvz, repeats_bed and repeatDB parameters

                          /usr/local/bin/Rscript --vanilla TRexs.R \\
                            --sample sample_sheet.tsv \\
                            --control control_samples_repeat_2022-10-20.tsv.gz \\
                            --trvz /home/user/softwares/trgt/trvz \\
                            --repeats_bed pathogenic_repeats.hg38.bed \\
                            --reference GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions_v2.fasta \\
                            --repeatDB repeats_information.tsv \\
                            --hideGene "" \\
                            --output test_report
                          ');
opt = parse_args(opt_parser)

# Copy Rmd to current directory and render this one (Singularity root directory
# cannot be written so Rmd will fail without doing this as Rmd insist on
# creating a temporary file at the location of .Rmd)
if(!dir.exists(file.path(opt$output))){
  dir.create(file.path(opt$output))
}
system(paste0("cp ", script_path, "/TRexs.Rmd ", opt$output, "/TRexs.Rmd"))

rmarkdown::render(paste0(opt$output, "/TRexs.Rmd"), params=list(sample_sheet=opt$sample, 
                                                                 control_tsv=opt$control, 
                                                                 trvz_binary=opt$trvz, 
                                                                 pathogenic_bed=opt$repeats_bed, 
                                                                 hg38=opt$reference, 
                                                                 repeats_db=opt$repeatDB, 
                                                                 high_prev_genes=opt$hideGene,
                                                                 show_additional_gene=!opt$knownOnly,
                                                                 odir=opt$output),
                  output_dir = opt$output,
                  knit_root_dir = opt$output)
