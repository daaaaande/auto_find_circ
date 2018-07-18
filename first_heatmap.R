heat=read.table(file='~/auto_find_circ/heatmapone.txt', header=T)


##################
# new, smaller matrix 
bettersmall=as.matrix(cbind(as.numeric(heat$run_hal01_test1a),as.numeric(heat$run_697_test1c),as.numeric(heat$run_697_r_test1a),as.numeric(heat$run_hal01_r_test1a)))
#heatmap(bettersmall)




#########################################
#calculate fold changes, filter circs found in 1 or 3 samples

foldchhalo=as.numeric(heat$run_hal01_r_test1a/as.numeric(heat$run_hal01_test1a))# total/rnase treated absolute counts
foldchsix=as.numeric(heat$run_697_r_test1a/as.numeric(heat$run_697_test1c))


# combining fold change and names of circular RNA candidates
circsofinterest=cbind(as.character(heat$circn),as.numeric(foldchhalo),as.numeric(foldchsix))

#adding raw unique reads per sample 
newmatrxi=as.matrix(cbind(circsofinterest,bettersmall))

# making a datafram out of it, adding labels
df=as.data.frame(newmatrxi)
colnames(df) =c("circname","fChalo","fCr697","abshalo1","abs697","abs697_R","abshalo1_R")



################################################################################################
# filtering 

#at first for total low counts. later find group specific circs and then ones that are in all samples present 

# at first at least one two-fold change from total to rnaseR treated
df_filteredfirst = subset(df,(as.numeric(fChalo) >= 2))
df_filter2=subset(df_filteredfirst,as.numeric(fCr697) >= 2)


df_filter3=subset(df_filter2,((as.numeric(abs697_R) + as.numeric(abshalo1_R)) >= 4)) # at least frour unique counts in RnAse treated 
df_filter4=subset(df_filter3,((as.numeric(abs697) + as.numeric(abshalo1)) >= 2)) # at least two in total RNA


# filter for presence in 697 and 697_R - at leat 3 times in each and not more that 2 times in halo1 and halo1R
in_697=subset(df_filter4,((as.numeric(abs697_R) >= 3 ) &  (as.numeric(abs697) >= 3) & (as.numeric(abshalo1_R) <= 2) & (as.numeric(abshalo1) <= 2))) # at least once in halo and halo1_R
# are here 86 circs  

# filter for absence in 697 and 697_R - at most 2 times in each and more that 2 times in halo1 and halo1R
in_halo1=subset(df_filter4,((as.numeric(abshalo1) >= 3 ) &  (as.numeric(abshalo1_R) >= 3) & (as.numeric(abs697) <= 2) & (as.numeric(abs697_R) <= 2))) # at least once in halo and halo1_R
# are are 258

# circs that are at least once in each of the four samples 
in_all=subset(df_filter4,((as.numeric(abshalo1) >= 1 ) &  (as.numeric(abshalo1_R) >= 1) & (as.numeric(abs697) >= 1 ) &  (as.numeric(abs697_R) >= 1)))
# are here 1250
# 


