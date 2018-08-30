#/usr/bin/perl -w
use strict;
# clean command line before starting the whole analysis
system("clear");
# change into the parent dir- find_circ- where all the action happens
chdir "../";
# global logfile- every pipeline and godfather.pl dumps its errors there
open(ER,'>>',"/home/daniel/logfile_auto.log")||die "$!";		# global logfile
######################################################
## usage: get samples.csv into find_circ/
#					 go to find_circ/auto_find_circ/
#						perl godfather.pl samples.csv dirname
######################################################
# godfather.pl
#   - as a wrapper for all three pipelines
#   - the in .fastq files need to be in all thre directories before the analysis starts- otherwise only those pipelines will run that find the files in their parent dir
#   - will copy the infile into the three parent directories where the processing will be done (so one cd .. away from the corresponding .pl scripts) into the file auto_infile.txt
#   - will then first start find_circ_auto pipeline, then circexplorer1_auto and in the end automate_DCC
#   - drops errors into the global logfile as every other script does aswell- keep in mind to redirect the stdout from STAR and bowtie aligner into a file, otherwise it will get lost
#   - for each pipeline it cd's into the script dir, but copies the infile into the parent dir (from scriptdir 'cd ..'). THAT IS EXPEXTED BEHAVIOUR to keep the git repos free from samplesheets!
#
##################################################
my$infile=$ARGV[0];
chomp $infile;
my$ndir=$ARGV[1];# the final output dir
chomp $ndir;


## enter your directories for the pipelines .pl files here cd
my$find_circ_dir="/media/daniel/NGS1/RNASeq/find_circ";
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
my$copy_dcc= system("cp $infile $dcc_dir/auto_infile.txt");
my$copyfind_circ= system("cp $infile $find_circ_dir/auto_infile.txt");




# now start both auto_automaker.pl with auto_infile.txt
chdir "$find_circ_dir/auto_find_circ/";
my$startfin_ci= system("perl auto_automaker.pl auto_infile.txt $ndir");

chdir "$circexplorer1_dir/circexplorer1_auto/";
my$startcirex= system("perl auto_automaker.pl auto_infile.txt $ndir");

chdir "$dcc_dir/automate_DCC/";
my$start_dcc= system("perl auto_automaker.pl auto_infile.txt $ndir");# but execute auto from repo

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
