#/usr/bin/perl -w
use strict;

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

my@allemappings= <MA>;
my%mapping_hash=();  # mapping hash: gene name is key, hallmark mechanism is value?
# each line now one array part
print "reading gene mapping...\n";

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
    $mapping_hash{"$hallmg"}="$hallmarktype_full";
      print "mapping $hallmg to type $hallmarktype_full g ---\n";
  }
#  $mapping_hash{"$allhallmarkg"}="$hallmarktype_full"# gene string is key, hallmark type is value




}
my@allehallmarkg=keys %mapping_hash;
my@all_hm_genes= values %mapping_hash;
#################
my@sampleuniqc=();# positions of unique count columns
my@samplenames=();# names of all detected samples
my@uniqcounts=(); # where maybe all unique counts will be added into a two-dimensional array?
my@headers=();    # headers with relevant information for each circ candidates
my@alluniques=();# empty yet



for (my $var = 0; $var < scalar(@allelines); $var++) {
  my$longline=$allelines[$var];
  if (!($longline=~/coordinates/g)) {
    my$hallm="none\t";
    # getting relevant information for each circ candidate ...
    my@lineparts=split(/\t/,$longline);
    my$coords=$lineparts[0];
    my$refseqID=$lineparts[2];
    my$gene=$lineparts[3];
    my$circn=$lineparts[4];
    # adding hallmark gene type
    if(grep(/$gene/,@allehallmarkg)){			# get all samplenames into @allenames)
    print "looking for $gene in gene mapping ---\n";
    # find hallmark class  and add to matrix file
      $hallm=$mapping_hash{$gene};
    ####
    }
    push(@headers,"$coords\t$refseqID\t$gene\t$circn\t$hallm");# header into array
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
print OUT"coordinates\trefseqid\tgene\tcircn\thallm";
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
