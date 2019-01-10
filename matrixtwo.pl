#/usr/bin/perl -w
use strict;
require "/media/daniel/NGS1/RNASeq/find_circ/read_mapping.pl"; # module reading mapping file for additional information- can be ignored when useless
use List::MoreUtils qw(uniq); # used to get to a list of unique samplenames later


############################################################ usage
# perl matrixtwo.pl matrixmaker_outfile.csv matrixtwo_output.tsv
############################################################
#			matrixtwo.pl
#			- needs an infile -> the correct infile format is made by matrixmaker.pl as ouput, can directly given to matrixtwo
#			- adds additional biologic information, but also removes information from the first matrix that is not used in the heatmap that will be created with the output from this script
#			- needs output file name , outputs in a .tsv file format
#     - will run in the dir where it was started
#			- will output errors into ER file : /home/daniel/logfile_auto.log, can be changed

############## example input :
#coordinates	strand	RefseqID	Gene	known_circ	num_samples_present	total_sum_unique_counts	qualities	present_in_sample	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB	sample	-unique_count	-qualA	-qualB
#chr10:102683731-102685776	+	NM_001136123	SLF2	hsa_circ_0006654	16	88	,6;40,40;40,40;5,40;5,6;40,6;40,6;40,40;40,40;5,40;40,40;40,40;40,40;40,40;5,40;40,40;40	-run_hal01_test1a-run_697_r_test1a-run_hal01_r_test1a-run_hal01_r_test1c-run_hal01_test1c-run_hal01_test1d-run_hal01_test1b-run_697_r_test1c-run_hal01_r_test1b-run_697_test1c-run_697_r_test1b-run_697_test1e-run_697_r_test1d-run_hal01_r_test1d-run_697_test1a-run_697_test1d	run_hal01_test1a	5	6	40	run_697_r_test1a	7	40	40	run_hal01_r_test1a	7	40	5	run_hal01_r_test1c	7	40	5	run_hal01_test1c	5	6	40	run_hal01_test1d	5	6	40	run_hal01_test1b	5	6	40	run_697_r_test1c	7	40	40	run_hal01_r_test1b	7	40	5	run_697_test1c	3	40	40	run_697_r_test1b	7	40	40	run_697_test1e	3	40	40	run_697_r_test1d	7	40	40	run_hal01_r_test1d	7	40	5	run_697_test1a	3	40	40	run_697_test1d	3	40	40
#chr10:102683734-102685776	+	NM_001136123	SLF2	unknown	4	8	,40;40,40;40,40;40,40;40	-run_697_r_test1a-run_697_r_test1c-run_697_r_test1b-run_697_r_test1d	run_hal01_test1a	0	0	0	run_697_r_test1a	2	40	40	run_hal01_r_test1a	0	0	0	run_hal01_r_test1c	0	0	0	run_hal01_test1c	0	0	0	run_hal01_test1d	0	0	0	run_hal01_test1b	0	0	0	run_697_r_test1c	2	40	40	run_hal01_r_test1b	0	0	0	run_697_test1c	0	0	0	run_697_r_test1b	2	40	40	run_697_test1e	0	0	0	run_697_r_test1d	2	40	40	run_hal01_r_test1d	0	0	0	run_697_test1a	0	0	0	run_697_test1d	0	0	0
#
############# example output :
#
#coordinates	refseqid	gene	circn	hallm	biom_desc	run_hal01_test1a	run_697_r_test1a	run_hal01_r_test1a	run_hal01_r_test1c	run_hal01_test1c	run_hal01_test1d	run_hal01_test1b	run_697_r_test1c	run_hal01_r_test1b	run_697_test1c	run_697_r_test1b	run_697_test1e	run_697_r_test1d	run_hal01_r_test1d	run_697_test1a	run_697_test1d
#chr10:102683731-102685776	NM_001136123	SLF2	hsa_circ_0006654	none	SMC5-SMC6_complex_localization_factor_2_	5	7	7	7	5	5	5	7	7	3	7	3	7	7	3	3
#chr10:102683734-102685776	NM_001136123	SLF2	unknown	none	SMC5-SMC6_complex_localization_factor_2_	0	2	0	0	0	0	0	2	0	0	2	0	2	0	0	0
#
#
#
#

open(ER,'>>',"/home/daniel/logfile_auto.log")||die "$!";		# global logfile
my $start = time;

my$linfile= $ARGV[0];
chomp $linfile;
print ER "reading input file $linfile ...\n";
# output file second argument adding coordinates
open(IN,$linfile)|| die "$!";
my@allelines= <IN>;

my$outfile=$ARGV[1];  # outfile
chomp $outfile;
open (OUT ,">",$outfile)|| die "$!";

## mapping file with hallmark gene names : beginning of line is hallmark** then website http://www.broadinstitute.org/gsea/msigdb/cards/HALLMARK_CHOLESTEROL_HOMEOSTASIS then gene names

my$hallmark_mapping_file="/media/daniel/NGS1/RNASeq/find_circ/hallmark_genes.tsv"; # unusual mapping file, not one gene per line
open(MA,$hallmark_mapping_file) || die "$!";

# uses subroutine map_file from read_mapping.pl
my%mart_info=map_file("/media/daniel/NGS1/RNASeq/find_circ/mart_export_ensembl_gene_desc.txt",1,2,"\t");
my@mart_infos= keys %mart_info;


########################################################################### gene mapping file reading into hash %mapping

##exapmle line : HALLMARK_TNFA_SIGNALING_VIA_NFKB	http://www.broadinstitute.org/gsea/msigdb/cards/HALLMARK_TNFA_SIGNALING_VIA_NFKB	JUNB	CXCL2	ATF3	NFKBIA	TNFAIP3	PTGS2	CXCL1	IER3	CD83	CCL20	CXCL3	MAFF	NFKB2	TNFAIP2	HBEGF	KLF6	BIRC3	PLAUR	ZFP36	ICAM1	JUN	EGR3	IL1B	BCL2A1	PPP1R15A	ZC3H12A	SOD2	NR4A2	IL1A	RELB	TRAF1	BTG2	DUSP1	MAP3K8	ETS2	F3	SDC4	EGR1	IL6	TNF	KDM6B	NFKB1	LIF	PTX3	FOSL1	NR4A1	JAG1	CCL4	GCH1	CCL2	RCAN1	DUSP2	EHD1	IER2	REL	CFLAR	RIPK2	NFKBIE	NR4A3	PHLDA1	#IER5	TNFSF9	GEM	GADD45A	CXCL10	PLK2	BHLHE40	EGR2	SOCS3	SLC2A6	PTGER4	DUSP5	SERPINB2	NFIL3	SERPINE1	TRIB1	TIPARP	RELA	BIRC2	CXCL6	LITAF	TNFAIP6	CD44	INHBA	PLAU	MYC	TNFRSF9	SGK1	TNIP1	NAMPT	FOSL2	PNRC1	ID2	CD69	IL7R	EFNA1	PHLDA2	PFKFB3	CCL5	YRDC	IFNGR2	SQSTM1	BTG3	GADD45B	KYNU	G0S2	BTG1	MCL1	VEGFA	MAP2K3	CDKN1A	CYR61	TANK	IFIT2	IL18	TUBB2A	IRF1	FOS	OLR1	RHOB	AREG	NINJ1	ZBTB10	PPAP2B	KLF4	CXCL11	SAT1	CSF1	GPR183	PMEPA1	PTPRE	TLR2	CXCR7	KLF10	MARCKS	#LAMB3	CEBPB	TRIP10	F2RL1	KLF9	LDLR	TGIF1	RNF19B	DRAM1	B4GALT1	DNAJB4	CSF2	PDE4B


my@allemappings= <MA>;
my%mapping_hash=();  # mapping hash: gene name is key, hallmark mechanism is value?
# each line now one array part
#print "reading gene mapping...\n";

foreach my $mapline (@allemappings){
	# fill a hash that is used later
	chomp $mapline;
  my@mappingline_parts=split(/\s+/,$mapline);
  my$hallmarktype_full=shift @mappingline_parts;# getting hallmark description properly with some regex cleaning by shifting first array index
  $hallmarktype_full=~s/HALLMARK//;
  $hallmarktype_full=~s/\s+//;
  my$address= shift @mappingline_parts;
  #my$allhallmarkg= join(@mappingline_parts,"_");
  #now a string of gene1_genetwo_gene3
  # rest of the line is all hallmark genes, need to be cleaned up before saving
  foreach my $hallmg (@mappingline_parts){
    $hallmg=~s/\s+//;
    if($hallmg=~/[A-Z]/){  # checking for empty lines and gene names
      $mapping_hash{"$hallmg"}="$hallmarktype_full";
      #print "mapping _:$hallmg:_ to type $hallmarktype_full g ---\n";
    }
  #    print "mapping $hallmg to type $hallmarktype_full g ---\n";
  }
#  $mapping_hash{"$allhallmarkg"}="$hallmarktype_full"# gene string is key, hallmark type is value




}
my@allehallmarkg=keys %mapping_hash;
my@all_hm_genes= values %mapping_hash;
############################################################################
# arrays in use
my@sampleuniqc=();# positions of unique count columns
my@samplenames=();# names of all detected samples
my@uniqcounts=(); # where maybe all unique counts will be added into a two-dimensional array?
my@headers=();    # headers with relevant information for each circ candidates
my@alluniques=();# empty yet



# default non-matching descriptions
my$marti="NaN";
my$hallm="none\t";
# starting to read inputfile line by line
for (my $var = 0; $var < scalar(@allelines); $var++) {
  my$longline=$allelines[$var];
  if (!($longline=~/coordinates/g)) {   # ignoring header

    # getting relevant information for each circ candidate ...
    my@lineparts=split(/\t/,$longline);
    my$coords=$lineparts[0];
		my$strand=$lineparts[1];
    my$refseqID=$lineparts[2];
    my$gene=$lineparts[3];
    my$circn=$lineparts[4];
    # adding hallmark gene type
	#	print "refseqid is $refseqID\n";
    if(grep(/$gene/,@allehallmarkg)){			# get all samplenames into @allenames)
  #  print "looking for $gene in gene mapping ---\n";
    # find hallmark class  and add to matrix file
      if($mapping_hash{$gene}=~/[A-Z]/){
        $hallm=$mapping_hash{$gene};
      }
    }
		else{
			$hallm="none";
		}

    if(grep(/$gene?/,@mart_infos)){              # mart mapping
      # gene has information available to it
      $marti=$mart_info{$gene};
      $marti=~s/\[.*\]//g;
			$marti=~s/\ /_/g;
    }
		else{
			$marti="NaN";
		}
    # check for empty mart information
    if(!($marti=~/[A-z]/gi)){
      $marti="NaN";
    }

    push(@headers,"$coords\t$strand\t$refseqID\t$gene\t$circn\t$hallm\t$marti\t");# header into array
      my$e=0;
      my$allthings="";
      foreach my$samplepos (@sampleuniqc){
        $e++; # second coordinate for two-dimensional array of all unique counts
        my$samplename = $lineparts[$samplepos-1];
        push(@uniqcounts,$lineparts[$samplepos]); #the unique
      #  print "found a sample= $samplename \nand its counts are $lineparts[$samplepos] circrna of interest is $lineparts[4]\n";
        push (@samplenames,$samplename);
        ## do the magic and find all unique counts for each sample for each circrna candindate, get all this into a string and then print all that out later
        $allthings="$allthings\t$lineparts[$samplepos]";
        #$alluniques[$var][$e]=$lineparts[$samplepos];# two-dimensional array
      }
      push(@alluniques,$allthings);# all unique count positions in .mat1 file
  }
  else{
  # header bar only- catch columns with samplenames in it and their position
    my@wholeheader=split(/\t/,$longline);
    my $i=0;
    foreach my $headername (@wholeheader){
      $i++;
      if ($headername=~/sample/) {
        if(!($headername=~/\_sample/)){
          push (@sampleuniqc,$i);  #get positions of sample ids
          # body...
        #  print "header position is $i in $headername\n";
        }
      }
    }
  }
}



# actual file creation:
# header line in output file ...
my@uniques= uniq @samplenames;
print OUT"coordinates\tstrand\trefseqid\tgene\tcircn\thallm\tbiom_desc\t";
foreach my $sampl (@uniques){
  print OUT"$sampl\t";
}
print OUT "\n";
# now the real content, cleaning it from junk and then printing it
for (my $v = 0; $v < scalar(@headers); $v++) {
  my$outline="$headers[$v]$alluniques[$v]";
	# messy whitespace cleanup
  $outline=~s/\t\t+/\t/g;
  $outline=~s/\t\s+/\t/g;
	$outline=~s/\s+\t/\t/g;

  #print "$headers[$v]\t";
  print OUT "$outline\n";

}
