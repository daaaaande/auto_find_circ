#/usr/bin/perl -w
use strict;
# get the windows.bed file, add the chr:start-end string in the beginning of the line
# needs a filename for the sorted output with coordinates added as second argument
# relies on find_circ scripts and gene ref files in $scriptplace and $generefplace
#system("clear");


######################################## example run 
# mkdir samplename
# when more than one sample ;(cat important_sample_*.sites.bed >important_samples.bed)
# perl steptwo.pl important_samples.bed important_samples_processed.csv
#########################################








my $start = time;

# Do stuff
print "started at $start\n";


# get starting place to return to later
my$currdir=`pwd`;
chomp $currdir;
print "started step two at dir $currdir\n";
# input should be all .bed files cat into one
my$linfile= $ARGV[0];
chomp $linfile;

# where find_circ scripts will work
my$scriptplace="/media/daniel/NGS1/RNASeq/find_circ";
my$Generefplace="/media/daniel/NGS1/RNASeq/find_circ/bed_files";
my$chdirort="/media/daniel/NGS1/RNASeq/find_circ";
# command1

chdir($chdirort);

print "creating $linfile.circ_candidates_auto_.bed with score filtering...\n";
my$err = system ("grep circ $linfile | grep -v chrM | python2.7 $scriptplace/sum.py -2,3 | python2.7 $scriptplace/scorethresh.py -16 1 | python2.7 $scriptplace/scorethresh.py -15 2 | python2.7 $scriptplace/scorethresh.py -14 2 | python2.7 $scriptplace/scorethresh.py 7 2 | python2.7 $scriptplace/scorethresh.py 8,9 35 | python2.7 $scriptplace/scorethresh.py -17 100000 >$linfile.circ_candidates_auto_.bed");

print "errors:\n$err\n\n";
# output of command1
my$infiletwo="$linfile.circ_candidates_auto_.bed";



#this NEEDS to be executed in find_circ dir, otherwise bedtools will not run?
#chdir $chdirort ;

# command2
# will only take the present windows, the circ_candidates.window_not_present.bed will not be created
print "looking up generefs with $Generefplace/Genes_RefSeq_hg19_09.20.2013.bed\ncreating $infiletwo.out...\n";
my$err2=system("bedtools window -a $infiletwo -b $Generefplace/Genes_RefSeq_hg19_09.20.2013.bed -w 1 >$infiletwo.out");
print "errors:\n$err2\n\n";
# output of command2
my$newnametwo="$infiletwo.out";

# ist jetzt also $linfile.circ_candidates_auto_.bed.out

######################################### 
# here comes the fix file in excel part
# command 2 output is taken in,
# each line getts coordinates added
# outfile in current directorty is output



# get input file name


open(IN,$newnametwo)|| die "$!";
my@infile = <IN> ;


# new filename for steptwo output ;
# ist jetzt also $linfile.circ_candidates_auto_.bed.out_.processsed


my$linetwofile= "$linfile.circ_candidates_auto_.bed.out.processed";
#chomp $linetwofile;


print "adding unique coordinates\ncreating $currdir/$linetwofile ...\n"; 
# output file second argument adding coordinates 
open(OUT,">","$currdir/$linetwofile")|| die "$!";

foreach my $line (@infile){
	#print "$line";
	my@parts=split(/\t+/,$line);	# split line to find coordinates of gene
	my$chr=$parts[0];
	my$beg=$parts[1];
	my$end=$parts[2];
	#print"$chr:$beg-$end\n";
	my$un="$chr:$beg-$end";		# all coordinades together are the unique id here
	chomp $un;
	my$newline="$un\t$line";
	#chomp
	print OUT "$newline";
}


# now the fitting outfile is $currdir/$linetwofile and this is the input for next steps
# command3, the sort
print "sorting by coordinates...\ncreating $currdir/$linfile.sort.bed ...\n";
my$errso=system("sort -k 1,1 $currdir/$linetwofile  > $currdir/$linetwofile.sorted");
print "errors:\n$errso\n\n";
### now reorder the output file, delete unwanted information
# file to dump information into
print "reordering $currdir/$linetwofile.sorted entries...\n";


my$outfilethre="$currdir/$linfile.csv";


# outfile for finding relevant columns...
print "creating $outfilethre...\n";
open(ND,">",$outfilethre)|| die "$!";
print ND "coordinates\tstrand\tsampleid\tunique_counts\tqualA\tqualB\tRefSeqID\n";


## see excel file for that
# this is the input file for finding the relevant columns,
# and the outfile from sorting line 87 
open(SO,"$currdir/$linetwofile.sorted")||die "$!";
# edit this file 
my@newin = <SO>;

foreach my $lein (@newin){
	chomp $lein;
	my@all_things=split(/\t+/,$lein);
	# NOW GET ONLY RELEVANT THINGS 
	my$ccord=$all_things[0]; # should be chr10:101654702-101656154
	my$long_id=$all_things[4]; # should be auto_circ_004447
	## this string needs some work : remove circ_..
	$long_id =~s/circ\_*.[0-9]{1,20}//ig ;
	# removed circ_8945 for each line
	
	my$strand=$all_things[6];
	my$uniques=$all_things[7];
	my$bestqa=$all_things[8];	
	my$bestqb=$all_things[9];
	my$refseqid=$all_things[21];
	#my$bestqa=$all_things[6];# gives you 7th element in line $lein


	print ND "$ccord\t$strand\t$long_id\t$uniques\t$bestqa\t$bestqb\t$refseqid\n";
}


#############################################I/O 
# file descriptions






######## input cat allsamples.bed>allsamples.bed
#chr5:619104-620376      chr5    619104  620376  run_3679_testneucirc_000003     2       +       2       40      6       1       0       unknown 2       0       0       1       1272.0  chr5    612404  653666  NM_018140       0
 #      +       612476  653268  0       12      154,128,193,109,179,213,302,136,197,127,112,564,        0,6700,7779,12181,21479,23082,25227,26799,28118,32009,35515,40698,




# directory need to be made before , in place where script is stared, with exact sample name


# output ;$currdir/candidatelist_auto_$linfile.csv";
# coordinates     strand  sampleid        unique_counts   qualA   qualB   RefSeqID
#chr10:101654702-101656154       -       run_3r_testneu  3       34      40      NM_015221
#chr10:101689364-101691202       -       daric/Chen01_   2       40      40      NM_015221
#chr10:101689364-101691202       -       daric/Chen01_   2       40      40      NR_024130
#chr10:101923760-101943594       -       auto_   2       40      6       NM_006459
#chr10:101923760-101943594       -       auto_   2       40      6       NM_001100626





