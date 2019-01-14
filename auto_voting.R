#!/usr/bin/env Rscript
# needed: four arguments: find_circ matrix infile, circex heatmap. dcc heatmap, output file ,median/men/min
# example; Rscript --vanilla auto_filtering.R find_circ/allsamples_m_heatmap.find_circ.tsv circex1/allsamples_m_heatmap.circex1.tsv dcc/matrixtwo_out_allsamples_dcc.tsv testout_test_mean.tsv mean


#
#vote instead of consensus: save the 3 3/3 voted approved dataframes with original quants, do the vote
#
#
##


args = commandArgs(trailingOnly=TRUE)


# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).\n", call.=FALSE)
} else if (length(args)<4) {
  # default output file

  args[4] = "heatmap_median_approved_all.csv"
  args[5] = "median"
}

# only the important parts from output_filtering.R
#install.packages('dplyr') # to delete columns from dataframes
#install.packages("VennDiagram")
#install.packages("gplots")

library(gplots)
library('dplyr')
library(methods)
library(utils)
#library("VennDiagram")
###### functions      #######

sd_per_row <- function(df){
  sds=c()
  for(i in seq(1,nrow(df),1)){
    all_nums=df[i,]
    all_nums=as.double(all_nums)
    sd_row=as.numeric(sd(all_nums))
    sds=c(sds,sd_row)
  }
  return (sds)
}

# function to get detection events : 1,0->0 || >=2->1
quant_into_detection_events <- function(x) {

  x[x ==1 ] <- 0
  x[x >= 2] <- 1
  return(x)
}
# binary matrices= detection events

######### full quantifications##################
#groups=read.csv("~/work_enclave/first_output/groups_medullos.csv",header = T)


# heatmap files
heat_find_circ=read.table(file=args[1], header=T,sep="\t", fill = TRUE,quote = "")
heat_circex1=read.table(file=args[2], header=T,sep="\t", fill = TRUE,quote = "")
heat_dcc=read.table(file=args[3], header=T,sep="\t", fill = TRUE,quote = "")
# DCC had an extra sample name called sample, that should be an error, thus removing it...
# heat_dcc <- select(heat_dcc, -sample)
# convert to numeric for calculations
sapply(heat_circex1,as.numeric)# needs to be done with every of the three dataframes: convert to numeric, then apply min reads filter
sapply(heat_dcc,as.numeric)
sapply(heat_find_circ,as.numeric)

# cleanup for filtering
tokeep_cx <- which(sapply(heat_circex1,is.numeric))
only_num_heat_circex1=heat_circex1[ , tokeep_cx, with=FALSE]

tokeep_dc <- which(sapply(heat_dcc,is.numeric))
only_num_heat_dcc=heat_dcc[ , tokeep_dc, with=FALSE]

tokeep_fc <- which(sapply(heat_find_circ,is.numeric))
only_num_heat_find_circ=heat_find_circ[ , tokeep_fc, with=FALSE]

# cleanup for filtering
#only_num_heat_circex1=select(heat_circex1,-c(coordinates,refseqid,gene,circn,hallm,biom_desc ))
#only_num_heat_find_circ=select(heat_find_circ,-c(coordinates,refseqid,gene,circn,hallm,biom_desc ))
#only_num_heat_dcc=select(heat_dcc,-c(coordinates,refseqid,gene,circn,hallm,biom_desc ))
# exchanfge this part





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
# all unique by at least two pipelines detected circs
all_voted_coordinates=unique( c(majority_approved_find_circ_andcirc_ex,majority_approved_find_circ_anddcc,majority_approved_circex_anddcc))
# get extra data back
all_appr_dcc=acc_dcc[acc_dcc$coordinates %in% all_voted_coordinates,]
all_appr_circex=acc_circex[acc_circex$coordinates %in% all_voted_coordinates,]
all_appr_findc=acc_find_circ[acc_find_circ$coordinates %in% all_voted_coordinates,]
# get only numeric values, ignore extra stuff
col_circex=select(all_appr_circex,-c(refseqid,gene,circn,hallm,biom_desc ))
col_dcc=select(all_appr_dcc,-c(refseqid,gene,circn,hallm,biom_desc ))
col_findc=select(all_appr_findc,-c(refseqid,gene,circn,hallm,biom_desc ))

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

##################### consensus and output #####################
# get only quantifications for circs on that all agree - into numeric
only_ab_all_aggr_circex=sapply(select(ordered_circex,-c(coordinates,refseqid,gene,circn,hallm,biom_desc)), as.numeric)
only_ab_all_aggr_findc=sapply(select(ordered_findc,-c(coordinates,refseqid,gene,circn,hallm,biom_desc)), as.numeric)
only_ab_all_aggr_dcc=sapply(select(ordered_dcc,-c(coordinates,refseqid,gene,circn,hallm,biom_desc)), as.numeric)

# for presence/detection events matrices into binary
#ordered_bin_findc=quant_into_detection_events(ordered_findc)
#ordered_bin_circex=quant_into_detection_events(ordered_circex)
#ordered_bin_dcc=quant_into_detection_events(ordered_dcc)

# get the median of 3 quantifiacations of each sample in each pipeline. options are median, mean, min
consensus_filtered_abundances_median=apply(abind::abind(only_ab_all_aggr_circex, only_ab_all_aggr_findc, only_ab_all_aggr_dcc,  along = 3), 1:2, args[5])
# add relevant information
consensus_filtered_abundances_all_=cbind(all_agree_info,consensus_filtered_abundances_median)
#consensus_filtered_abundances_all_=select(consensus_filtered_abundances_all_,-X)

# first output file; full sorted consensus matrix median
#write.csv(consensus_filtered_abundances_all_,file = args[4])
