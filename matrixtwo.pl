#/usr/bin/perl -w
use strict;

system("clear");

open(ER,'>>',"logfile_auto.log")||die "$!";		# global logfile
my $start = time;

my$linfile= $ARGV[0];
chomp $linfile;
print "reading input file $linfile ...\n";
# output file second argument adding coordinates
open(IN,$linfile)|| die "$!";
my@allelines= <IN>;

my@sampleuniqc=();# positions of unique count columns
my@samplenames=();# names of all detected samples
my@uniqcounts=(); # where maybe all unique counts will be added into a two-dimensional array?
my@headers=();    # headers with relevant information for each circ candidates
my@alluniques=();# empty yet



for (my $var = 0; $var < scalar(@allelines); $var++) {
  my$longline=$allelines[$var];
  if (!($longline=~/coordinates/g)) {
    # getting relevant information for each circ candidate ...
    my@lineparts=split(/\t/,$longline);
    my$coords=$lineparts[0];
    my$refseqID=$lineparts[2];
    my$gene=$lineparts[3];
    my$circn=$lineparts[4];
    push(@headers,"$coords\t$refseqID\t$gene\t$circn\t");# header into array
    #if($var==1){# to test first only the second line , later all lines
      my$e=0;
      my$allthings="";
      foreach my$samplepos (@sampleuniqc){
        $e++; # second coordinate for two-dimensional array of all unique counts
        my$samplename = $lineparts[$samplepos-1];
        push(@uniqcounts,$lineparts[$samplepos]); #the unique
        print "found a sample= $samplename \nand its counts are $lineparts[$samplepos] circrna of interest is $lineparts[4]\n";
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
          print "header position is $i in $headername\n";
        }
      }
    }
  }


}


print "coordinates\trefseqid\tgene\tcircn";
foreach my $sampl (@samplenames){
  print "$sampl\t";
}

for (my $v = 0; $v < scalar(@headers); $v++) {
  print "$headers[$v]\t";
  print "$alluniques[$v]\n";

}
