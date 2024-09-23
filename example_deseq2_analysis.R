# DESeq2 analysis of RNA-seq alignments of multiple donor samples with replicates
# Requirements: a featureCounts table that summarizes the number of reads mapped to genomic features (genes in this case) for each sample

# how to run featureCounts for a list of paired-end read alignment files in your working directory: 
## bams=($(ls | grep -E '.*bam$'))
## featureCounts -a GRCh38_gencode.v46.annotation.gtf -o all_sample_featureCounts.txt -p --countReadPairs -g gene_name ${bams[@]} > featureCounts.log 2>&1

# 'GRCh38_gencode.v46.annotation.gtf' can be replaced with the gene/feature annotation file of your choice

# load libraries
library(BiocManager)
library(ggplot2)
library(clusterProfiler)
library(biomaRt)
library(ReactomePA)
library(DOSE)
library(KEGG.db)
library(org.Hs.eg.db)
library(pheatmap)
library(genefilter)
library(RColorBrewer)
library(GO.db)
library(topGO)
library(dplyr)
library(gage)
library(ggsci)
library(stringr)
library(DESeq2)
library(wesanderson)
library(readr)

# Import featureCounts table

setwd("/path/to/all_sample_featureCounts.txt")
countdata <- read.table("all_sample_featureCounts.txt", header = TRUE, skip = 1, row.names = 1)
tbl <- read_table("all_sample_featureCounts.txt.summary")

# identify libraries with very few reads and remove them
exclude <- colnames(tbl[,which(tbl[1,]<1000000)])
countdata <- countdata[, !colnames(countdata) %in% exclude]

# make sample names readable
## write some code to adjust your sample names (colnames of countdata table) to something comprehensive and consistent
## for example: "305-ctrl-rep1" (#donor-condition-replicate)

# select only the columns with the read counts
# last column before the samples is called "Length"
countdata <- countdata %>% dplyr::select((grep("Length", colnames(countdata))+1):length(colnames(countdata)))

# create metadata table
metadata <- data.frame(sampleid = colnames(countdata))
rownames(metadata) <- colnames(countdata)

# Consider this data for the following analysis:
# RNA-seq of human monocyte-derived macrophages (hMDMs) from four different donors, stimulated with IL4, LPS, LPS+IL4 or at basal state.

# make col for replicate
metadata$replicate <- str_extract(metadata$sampleid, "rep[0-9]")
# donor
metadata$donor <- str_extract(metadata$sampleid, "[0-9]+")
# stim
metadata$stimulation <- str_extract(metadata$sampleid, "ctrl|LPS\\+IL4|LPS|IL4")

# Reorder sampleID's to match featureCounts column order.
metadata <- metadata[match(colnames(countdata), metadata$sampleid), ]


ddsMat <- DESeqDataSetFromMatrix(countData = countdata,
                                 colData = metadata,
                                 design = ~donor + stimulation)

ddsMat <- DESeq(ddsMat)

results_ctrl_LPS <- results(ddsMat, pAdjustMethod = "fdr", alpha = 0.05, contrast=c("stimulation","LPS","ctrl"))

results_ctrl_IL4 <- results(ddsMat, pAdjustMethod = "fdr", alpha = 0.05, contrast=c("stimulation","IL4","ctrl"))

results_ctrl_LPS.IL4 <- results(ddsMat, pAdjustMethod = "fdr", alpha = 0.05, contrast=c("stimulation","LPS+IL4","ctrl"))

results_LPS_IL4 <- results(ddsMat, pAdjustMethod = "fdr", alpha = 0.05, contrast=c("stimulation","LPS","IL4"))

results_LPS_LPS.IL4 <- results(ddsMat, pAdjustMethod = "fdr", alpha = 0.05, contrast=c("stimulation","LPS","LPS+IL4"))

results_IL4_LPS.IL4 <- results(ddsMat, pAdjustMethod = "fdr", alpha = 0.05, contrast=c("stimulation","IL4","LPS+IL4"))

# make palettes for heatmap

stim_palette <- c(wes_palette("Moonrise2")[1], wes_palette("FantasticFox1")[4:5], wes_palette("FantasticFox1")[3])

annotation_colors <- list(
  stimulation = c(ctrl = stim_palette[1], IL4 = stim_palette[2], LPS = stim_palette[3], `LPS+IL4` = stim_palette[4]),
  donor = c(`305` = "darkorchid", `306` = "darkkhaki", `325` = "pink", `326` = "darkgreen")
)

## make a heatmap of your genes of interest:
### Change Gene1 and Gene2 to your favorite genes

pheatmap(assay(vst(ddsMat))[c("Gene1","Gene2"),], cluster_rows=FALSE, show_rownames=TRUE,   # normalized data shown here
         cluster_cols=TRUE, show_colnames = F,
         annotation_col= as.data.frame(colData(ddsMat)[,c("stimulation","donor")]),
         annotation_colors = annotation_colors)

## Gather all result objects in a list
result_list <- mget(grep("results", ls(), value = T))
rm(list = grep("results", ls(), value = T))

# Add gene full name
result_list <- lapply(result_list, function(y) {
                        y$description = mapIds(x = org.Hs.eg.db,
                              keys = row.names(y),
                              column = "GENENAME",
                              keytype = "SYMBOL",
                              multiVals = "first")
                        return(y)
})

# Add gene symbol
result_list <- lapply(result_list, function(x) {
                            x$symbol = row.names(x)
                            return(x)
                                  })

# Add ENTREZ ID
result_list <-lapply(result_list, function(y) {
              y$entrez <- mapIds(x = org.Hs.eg.db,
                         keys = rownames(y),
                         column = "ENTREZID",
                         keytype = "SYMBOL",
                         multiVals = "first")
              return(y) })

# Add ENSEMBL
result_list <- lapply(result_list, function(y) {
            y$ensembl <- mapIds(x = org.Hs.eg.db,
                          keys = row.names(y),
                          column = "ENSEMBL",
                          keytype = "SYMBOL",
                          multiVals = "first")
            return(y) })

## subset 20 most significant genes per contrast
result_sig <- lapply(result_list, function(x) { subset(x, padj<=0.05) })
sig_genes <- unlist(lapply(result_sig, function(x) { rownames(x)[1:20]}))

## 20 most significant genes heatmap

heat20 <- assay(vst(ddsMat))[sig_genes,]

# Choose which column variables you want to annotate the columns by.
annotation_col = data.frame(
  donor = factor(colData(vst(ddsMat))$donor),
  stimulation = factor(colData(vst(ddsMat))$stimulation),
  row.names = colData(vst(ddsMat))$sampleid
)

donor_pal <- c(RColorBrewer::brewer.pal(n = 4, name = "Set3")) #n=number of donors
names(donor_pal) <- unique(colData(vst(ddsMat))$donor)

names(stim_palette) <- c("ctrl", "IL4", "LPS", "LPS+IL4")

ann_colors = list(
  donor = donor_pal,
  stimulation = stim_palette
)

pheatmap(mat = heat20[unique(sig_genes),],
         color = colorRampPalette(brewer.pal(9, "Blues"))(255),
         scale = "row", # Scale genes to Z-score (how many standard deviations)
         annotation_col = annotation_col, # Add multiple annotations to the samples
         annotation_colors = ann_colors,# Change the default colors of the annotations
         fontsize = 6.5, # Make fonts smaller
         cellwidth = 20, # Make the cells wider
         show_colnames = T)
