#/usr/bin/perl -w
use strict;
require "/home/daric/auto_find_circ/read_mapping.pl";
use List::MoreUtils qw(uniq);
system("clear");

open(ER,'>>',"logfile_auto.log")||die "$!";		# global logfile
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

my$hallmark_mapping_file="/home/daric/auto_find_circ/hallmark_genes.tsv";
open(MA,$hallmark_mapping_file) || die "$!";


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
#################
# next useful gene mapping is https://www.proteinatlas.org/search/protein_class:COSMIC%20Somatic%20Mutations .tsv downloaded
# ACKR3	CMKOR1, CXCR7, GPR159, RDC1	ENSG00000144476	Atypical chemokine receptor 3	2	236567787-236582358	Cancer-related genes, G-protein coupled receptors, Predicted membrane proteins	Evidence at protein level	HPA032003, HPA049718	Approved		Supported	Vesicles<br>Plasma membrane	Renal cancer:1.76e-6 (unfavourable), Stomach cancer:2.01e-4 (unfavourable), Urothelial cancer:2.93e-4 (unfavourable), Cervical cancer:4.64e-4 (unfavourable)	Expressed in all	Expressed in all			placenta: 176.7	Cell line enhanced		RT4: 248.8;SiHa: 100.8;U-2197: 297.4




# making more with

# key is gene name, value is description
my%mapping_more_info=map_file("/home/daric/auto_find_circ/protein_class_COSMIC.tsv",0,3);

my@mapping_info_genes= keys %mapping_more_info;




### do the same now with mart_export_ensembl_gene... in fin_circ dir
















my@sampleuniqc=();# positions of unique count columns
my@samplenames=();# names of all detected samples
my@uniqcounts=(); # where maybe all unique counts will be added into a two-dimensional array?
my@headers=();    # headers with relevant information for each circ candidates
my@alluniques=();# empty yet


my$hallm="none\t";
my$desc="nA\t";
for (my $var = 0; $var < scalar(@allelines); $var++) {
  my$longline=$allelines[$var];
  if (!($longline=~/coordinates/g)) {

    # getting relevant information for each circ candidate ...
    my@lineparts=split(/\t/,$longline);
    my$coords=$lineparts[0];
    my$refseqID=$lineparts[2];
    my$gene=$lineparts[3];
    my$circn=$lineparts[4];
    # adding hallmark gene type
    if(grep(/$gene/,@allehallmarkg)){			# get all samplenames into @allenames)
  #  print "looking for $gene in gene mapping ---\n";
    # find hallmark class  and add to matrix file
      if($mapping_hash{$gene}=~/[A-Z]/){
        $hallm=$mapping_hash{$gene};
        #print "found hallmark $hallm for $gene  in gene mapping ---\n";

    ####
      }
    }
    # second information mapping
    if(grep(/$gene/,@mapping_info_genes)){
      # gene has information available to it
      $desc=$mapping_more_info{$gene};
    }








    push(@headers,"$coords\t$refseqID\t$gene\t$circn\t$hallm\t$desc\t");# header into array
    #if($var==1){# to test first only the second line , later all lines
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
      push(@alluniques,$allthings);
    #}
  }
  else{
  # header bar
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
# header line in output file ...
my@uniques= uniq @samplenames;
print OUT"coordinates\trefseqid\tgene\tcircn\thallm\tinfo_m\t";
foreach my $sampl (@uniques){
  print OUT"$sampl\t";
}
print OUT "\n";

for (my $v = 0; $v < scalar(@headers); $v++) {
  my$outline="$headers[$v]$alluniques[$v]";
  $outline=~s/\t\t+/\t/g;
  $outline=~s/\t\s+/\t/g;
  #print "$headers[$v]\t";
  print OUT "$outline\n";

}
