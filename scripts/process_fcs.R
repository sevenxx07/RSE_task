#!/usr/bin/env Rscript

library(optparse)
library(flowCore)
library(ggplot2)
library(uwot)

option_list <- list(
  make_option(c("-i", "--input"), type="character", help="Input FCS file"),
  make_option(c("-o", "--output"), type="character", help="Output FCS file"),
  make_option(c("-p", "--plot"), type="character", help="Output plot file"),
  make_option(c("-c", "--channels"), type="character", default=NULL,
              help="Optional channels txt file specifying which channels to use")
)

opt <- parse_args(OptionParser(option_list=option_list))

if (is.null(opt$input) || is.null(opt$output) || is.null(opt$plot)) {
  stop("Input, output and plot must be provided")
}

ff <- read.FCS(opt$input, transformation = FALSE)
params <- parameters(ff)
desc <- pData(params)$desc

if(!is.null(opt$channels)){
  ch <- read.table(opt$channels, header=TRUE, sep="\t", stringsAsFactors = FALSE)
  selected <- ch$desc[ch$use == 1]
  present <- selected[selected %in% desc]
  if(length(present) == 0){
    channels <- which(!is.na(desc) & !grepl("^FSC|^SSC", desc, ignore.case = TRUE))
  }else{
    print("some channels same")
    channels <- which(desc %in% selected)
  }
}else{
  channels <- which(!is.na(desc) & !grepl("^FSC|^SSC", desc, ignore.case = TRUE))
}
expr <- exprs(ff)[, channels, drop=FALSE]
expr_trans <- asinh(expr / 5)

umap_res <- umap(expr_trans, n_components = 2)
km <- kmeans(umap_res, centers = 5)

new_expr <- cbind(exprs(ff), UMAP1=umap_res[,1], UMAP2=umap_res[,2], Cluster=km$cluster)
new_ff <- flowFrame(new_expr)

write.FCS(new_ff, filename = opt$output)

df <- data.frame(UMAP1=umap_res[,1], UMAP2=umap_res[,2], Cluster=factor(km$cluster))
plt <- ggplot(df, aes(x=UMAP1, y=UMAP2, color=Cluster)) + geom_point(size=0.5) + theme_minimal()

ggsave(opt$plot, plot=plt)
