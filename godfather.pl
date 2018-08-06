#/usr/bin/perl -w
use strict;

system("clear");

open(ER,'>>',"logfile_auto.log")||die "$!";		# global logfile

my$infile=$ARGV[0];
chomp $infile;


## enter your directories for the pipelines .pl files here 
my$find_circ_dir="/media/daniel/NGS1/RNASeq/find_circ";
my$circexplorer1_dir="/media/daniel/NGS1/RNASeq/find_circ/circexplorer/CIRCexplorer";


my$cu=`pwd`;

my$there=`ls $infile`;

if($there=~/$infile/){
  print "found file $infile in $cu, starting ...\n";
}
else{
  die  "did not find $infile in $cu\n";
}
# copying fastq files
my$err_cpone=system("cp *.fastq $find_circ_dir/");
my$err_cptwo=system("cp *.fastq $circexplorer1_dir/");

print "errors moving fastq files:\n$err_cpone\n$err_cptwo\n";

# copying filesheet
my$copyfind_circ= system("cp $infile $find_circ_dir/auto_infile.txt");
my$copycircexone= system("cp $infile $circexplorer1_dir/auto_infile.txt");

# now start both auto_automaker.pl with auto_infile.txt
chdir "$find_circ_dir/";
my$startfin_ci= system("perl $find_circ_dir/auto_automaker.pl auto_infile.txt");

chdir "$circexplorer1_dir/";
my$startcirex= system("perl $circexplorer1_dir/auto_automaker.pl auto_infile.txt");

print "logs find_circ: $startfin_ci\n";
print "logs circexplorer1 : $startcirex\n";
# need to copy all .gz files into the two folders?
# delete copies of fastq?
