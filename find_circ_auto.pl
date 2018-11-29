#/usr/bin/perl -w
use strict;

# expecting input files in the parent dir...
chdir "../";

my $start = time;# uses for one sample about one hour on 10 cores
# Do stuff
print "started at $start\n";
# global logfile
open(ER,'>>',"/home/daniel/logfile_auto.log")||die "$!";		# global logfile
####################################################################### usage
# perl find_circ_auto.pl read1.fastq.trimmed read2.fastq.trimmed samplename
#######################################################################
# find_circ_auto.pl
#   - starts test2.pl (the alignment steps of find_circ)
#   - and then starts steptwo.pl with its output
#   - also removed the .bam and .sam files created that take a lot of space to not fill up the storage when they are no longer needed
#   - keeps track of used time for each run
######################################################################
# get test2.pl input vars
my$infile1=$ARGV[0];
chomp $infile1;

my$infile2=$ARGV[1];
chomp $infile2;

my$samplename=$ARGV[2];# samplename
chomp $samplename;

my$currentdir=`pwd`;
chomp $currentdir;

#			# NGS number changes with every reboot
my$steponedir="/media/daniel/NGS1/RNASeq/find_circ";
my$steptwodir="/media/daniel/NGS1/RNASeq/find_circ";
my$stepthreedir="/media/daniel/NGS1/RNASeq/find_circ";
chdir($steponedir);
############################################################################# first step
# test2.pl takes unmapped/trimmed/fastq.gz/line1 and line2 reads...
my$errstepone = system ("perl auto_find_circ/test2.pl $infile1 $infile2 $samplename");

print ER "-------------------------------------------------\nsample $samplename processing:\n";
print ER "step 1:\n$errstepone\n";
#$outfn=$ARGV[2]
#$dirn="run_$outfn"
# output will be $dirn/auto_$dirn.sites.bed
# also get files in find_circ/run_$samplename/auto_$samplename.sites.bed


############################################################################# second step
my$steptwoinput="$steponedir/run_$samplename/auto_run_$samplename.sites.bed";# right?maybe...
#my$steptwooutput="$steponedir/run_$samplename";

# auto_run_hal01_r.sites.bed error

# perl steptwo/steptwo.pl important_samples.bed important_samples_processed.csv
print ER "trying now perl auto_find_circ/steptwo.pl $steptwoinput \n";
my$errsteptwo = system ("perl $steptwodir/auto_find_circ/steptwo.pl $steptwoinput");


print ER "step 2:\n$errsteptwo\n";
print ER "done making $steptwoinput.csv, moving it to run_$samplename/... \n";


system("mv $steponedir/temp.bam run_$samplename/tmp_$samplename.bam");
system("mv $steponedir/temp.sam run_$samplename/tmp_$samplename.sam");
#system()
system("rm run_$samplename/*.bam");
system("rm run_$samplename/*.sam");

my $end = time;
my$timeused=(($end-$start)/60);# into minutes
print ER "############################################################\nsample $samplename done :\n";

print ER "done.\n used $timeused minutes for $samplename\n ";
