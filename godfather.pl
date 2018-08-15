#/usr/bin/perl -w
use strict;

system("clear");

chdir "../";

open(ER,'>>',"/home/daniel/logfile_auto.log")||die "$!";		# global logfile

my$infile=$ARGV[0];
chomp $infile;


## enter your directories for the pipelines .pl files here cd
my$find_circ_dir="/media/daniel/NGS1/RNASeq/find_circ/auto_find_circ";
my$circexplorer1_dir="/media/daniel/NGS1/RNASeq/find_circ/circexplorer/CIRCexplorer";
my$dcc_dir="/media/daniel/NGS1/RNASeq/find_circ/dcc";

my$cu=`pwd`;

my$there=`ls $infile`;

if($there=~/$infile/){
  print "found file $infile in $cu, starting ...\n";
}
else{
  die  "did not find $infile in $cu\n";
}
# copying fastq files
#my$err_cpone=system("cp *.fastq $find_circ_dir/");
#my$err_cptwo=system("cp *.fastq $circexplorer1_dir/");
#my$err_cpthr=system("cp *.fastq $dcc_dir/");

#print "errors moving fastq files:\n$err_cpone\n$err_cptwo\n$err_cpthr\n";

# copying filesheet

my$copycircexone= system("cp $infile $circexplorer1_dir/auto_infile.txt");# keep the samplefile in the parent dir
my$copy_dcc=      system("cp $infile $dcc_dir/auto_infile.txt");
# find_circ needs the .gz files..
#system("");
my$copyfind_circ= system("cp $infile $find_circ_dir/auto_infile.txt");

# now start both auto_automaker.pl with auto_infile.txt
chdir "$find_circ_dir/";
my$startfin_ci= system("perl $find_circ_dir/auto_automaker.pl auto_infile.txt");

chdir "$circexplorer1_dir/";
my$startcirex= system("perl $circexplorer1_dir/auto_automaker.pl auto_infile.txt");

chdir "$dcc_dir/";
my$start_dcc= system("perl $dcc_dir/automate_DCC/auto_automaker.pl auto_infile.txt");# but execute auto from repo

# copy all three outputs into one dir where it all started
#print "moving all outfiles into all/...\n";

#kdir "all";
#system("cp $find_circ_dir/all_run_*/*.tsv all/");
#system("cp $circexplorer1_dir//all_run_*/*.tsv all/");
#system("cp $dcc_dir/all_run_*/*.tsv all/");



print "logs find_circ: $startfin_ci\n";
print "logs circexplorer1 : $startcirex\n";
print "logs dcc: $start_dcc\n";
# need to copy all .gz files into the two folders?
# delete copies of fastq?
