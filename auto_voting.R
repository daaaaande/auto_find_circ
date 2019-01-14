#!/usr/bin/env Rscript
# needed: four arguments: find_circ matrix infile, circex heatmap. dcc heatmap, output file ,median/men/min
# example; Rscript --vanilla auto_filtering.R find_circ/allsamples_m_heatmap.find_circ.tsv circex1/allsamples_m_heatmap.circex1.tsv dcc/matrixtwo_out_allsamples_dcc.tsv testout_test_mean.tsv mean

args = commandArgs(trailingOnly=TRUE)


# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).\n", call.=FALSE)
} else if (length(args)<3) {
print("you should have given three input files: dcc, find_circ and circexplorer1 heatmap .mat2 ")
}


library(gplots)
library('dplyr')
library(methods)
library(utils)

######### full quantifications##################

# heatmap files
heat_find_circ=read.table(file=args[1], header=T,sep="\t", fill = TRUE,quote = "")
heat_circex1=read.table(file=args[2], header=T,sep="\t", fill = TRUE,quote = "")
heat_dcc=read.table(file=args[3], header=T,sep="\t", fill = TRUE,quote = "")
# DCC had an extra sample name called sample, that should be an error, thus removing it...
# convert to numeric for calculations
sapply(heat_circex1,as.numeric)# needs to be done with every of the three dataframes: convert to numeric, then apply min reads filter
sapply(heat_dcc,as.numeric)
sapply(heat_find_circ,as.numeric)

# cleanup for filtering: take only numeric columns, keep only those and then take only numeric columns from that all three df have 
tokeep_cx <- which(sapply(heat_circex1,is.numeric))
only_num_heat_circex1=heat_circex1[ , tokeep_cx, ]

tokeep_dc <- which(sapply(heat_dcc,is.numeric))
only_num_heat_dcc=heat_dcc[ , tokeep_dc,]

tokeep_fc <- which(sapply(heat_find_circ,is.numeric))
only_num_heat_find_circ=heat_find_circ[ , tokeep_fc,]


# get only the samples where all three dfs have data on 
samples_fc=colnames(only_num_heat_find_circ)
samples_dc=colnames(only_num_heat_dcc)
samples_cx=colnames(only_num_heat_circex1)

consensus_samples=intersect(samples_fc,samples_dc)
consensus_samples=intersect(consensus_samples,samples_cx)

print ("the sample names that all three dfs agree on are")
print (consensus_samples)
only_num_heat_find_circ=only_num_heat_find_circ[consensus_samples]
only_num_heat_dcc=only_num_heat_dcc[consensus_samples]
only_num_heat_circex1=only_num_heat_circex1[consensus_samples]


# filtering= at least 1 circ detected twice in at least one sample
acc_circex=heat_circex1[rowSums(only_num_heat_circex1 > 1) >= 1, ]
acc_find_circ=heat_find_circ[rowSums(only_num_heat_find_circ > 1) >= 1, ]
acc_dcc=heat_dcc[rowSums(only_num_heat_dcc > 1) >= 1, ]
# get only filtered coordinates
find_circcoords=acc_find_circ$coordinates
dcc_coords=acc_dcc$coordinates
circ_excoords=acc_circex$coordinates
# majority vote
majority_approved_find_circ_andcirc_ex=intersect(find_circcoords,circ_excoords)
# now overlap find_circ and dcc
majority_approved_find_circ_anddcc=intersect(find_circcoords,dcc_coords)
# now dcc and circex
majority_approved_circex_anddcc=intersect(circ_excoords,dcc_coords)
# circs all 3 pipelines detected at least twice in at least one sample
circ_RNA_candidates_3_out_of_3_approved=intersect(majority_approved_find_circ_andcirc_ex,majority_approved_find_circ_anddcc)
# all unique by all pipelines detected circs
all_voted_coordinates=unique( c(majority_approved_find_circ_andcirc_ex,majority_approved_find_circ_anddcc,majority_approved_circex_anddcc))
# get extra data back
all_appr_dcc=acc_dcc[acc_dcc$coordinates %in% all_voted_coordinates,]
all_appr_circex=acc_circex[acc_circex$coordinates %in% all_voted_coordinates,]
all_appr_findc=acc_find_circ[acc_find_circ$coordinates %in% all_voted_coordinates,]

# coordinates approved by all 3 pipelines
quant_all_a_circex=acc_circex[acc_circex$coordinates %in% circ_RNA_candidates_3_out_of_3_approved,]
quant_all_a_findc=acc_find_circ[acc_find_circ$coordinates %in% circ_RNA_candidates_3_out_of_3_approved,]
quant_all_a_dcc=acc_dcc[acc_dcc$coordinates %in% circ_RNA_candidates_3_out_of_3_approved,]

# order rows
quant_all_a_circex=quant_all_a_circex[order(quant_all_a_circex$coordinates),]
quant_all_a_findc=quant_all_a_findc[order(quant_all_a_findc$coordinates),]
quant_all_a_dcc=quant_all_a_dcc[order(quant_all_a_dcc$coordinates),]

# we need to order the columns of these three dataframes before we find an average...
ordered_circex=quant_all_a_circex[ , order(colnames(quant_all_a_circex))]
ordered_findc=quant_all_a_findc[ , order(colnames(quant_all_a_findc))]
ordered_dcc=quant_all_a_dcc[ , order(colnames(quant_all_a_dcc))]

# additional info is enough from one pipeline, the others can be discarded
all_agree_info=select(ordered_findc,c(coordinates,refseqid,gene,circn,hallm))


########### output three filtered circ datasets#####################
write.csv(ordered_circex,file = "ordered_circex_approved_by_all_three.csv")
write.csv(ordered_findc,file = "ordered_find_circ_approved_by_all_three.csv")
write.csv(ordered_dcc,file = "ordered_dcc_approved_by_all_three.csv")

### END
# all output file should end where the R script was started.