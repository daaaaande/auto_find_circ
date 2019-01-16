#/usr/bin/perl -w
use strict;
# clean command line before starting the whole analysis
`clear`;
# change into the parent dir- find_circ- where all the action happens
chdir "../";
# global logfile- every pipeline and godfather.pl dumps its errors there
open(ER,'>>',"/home/daniel/logfile_auto.log")||die "$!";		# global logfile
######################################################
## usage: get samples.csv into find_circ/
#					 go to find_circ/auto_find_circ/
#                                   perl godfather.pl samples.csv dirname
#					OR:	perl godfather.pl samples.csv dirname | tee pipeline_run.out | less
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
my$date=localtime();
$date=~s/\s+/_/gi;


## enter your directories for the pipelines .pl files here
my$find_circ_dir="/media/daniel/NGS1/RNASeq/find_circ";

my$circexplorer1_dir="$find_circ_dir/circexplorer/CIRCexplorer";
my$dcc_dir="$find_circ_dir/dcc";

my$cu=`pwd`;

my$there=`ls $infile`;

if($there=~/$infile/){
  print ER "found file $infile in $cu, starting ...\n";
}
else{
  die  "did not find $infile in $cu\n";
}

my$inf_backup=`cp $find_circ_dir/$infile $find_circ_dir/infile_$date.backup`;

my$rmcircexone= `rm $circexplorer1_dir/auto_infile.txt`;# keep the samplefile in the parent dir
my$rm_dcc= `rm $dcc_dir/auto_infile.txt`;
my$rmfind_circ= `rm $find_circ_dir/auto_infile.txt`;

print ER "deleted old input files:\ncircexplorer1: $rmcircexone\nDCC: $rm_dcc\nfind_circ: $rmfind_circ\n\n";


# copying filesheet

my$copycircexone= `cp $find_circ_dir/$infile $circexplorer1_dir/auto_infile.txt`;# keep the samplefile in the parent dir
my$copy_dcc= `cp $find_circ_dir/$infile $dcc_dir/auto_infile.txt`;
my$copyfind_circ= `cp $find_circ_dir/$infile $find_circ_dir/auto_infile.txt`;

# starting the actual auto_automakers...
 my$startfin_ci= `perl $find_circ_dir/auto_find_circ/auto_automaker.pl auto_infile.txt $ndir`;
 my$startcirex= `nice perl $circexplorer1_dir/circexplorer1_auto/auto_automaker.pl auto_infile.txt $ndir`;
 my$start_dcc=`nice perl $dcc_dir/automate_DCC/auto_automaker.pl auto_infile.txt $ndir`;# but execute auto from repo


 # making the voting in the output dir
 chdir "$find_circ_dir/$ndir/"; #change into dir where df should be placed
 my$er_vot=`Rscript --vanilla $find_circ_dir/auto_find_circ/auto_voting.R allsamples_m_heatmap.find_circ.mat2 allsamples_m_heatmap.circex1.mat2 allsamples_m_heatmap.dcc.mat2`;
 print"errors doing the vote : $er_vot\n";
 # reverse into default dir
 chdir "$find_circ_dir/";
