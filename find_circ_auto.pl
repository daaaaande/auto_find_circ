#/usr/bin/perl -w
use strict;

#system("clear");


my $start = time;
# Do stuff
print "started at $start\n";

# get test2.pl input vars

my$infile1=$ARGV[0];
chomp $infile1;

my$infile2=$ARGV[1];
chomp $infile2;

my$samplename=$ARGV[2];# danach sollten alle anderen files benannt werden die da raus kommen, und auch in die unterdir verschoben werden
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
my$errstepone = system (`perl $steponedir/test2.pl $infile1 $infile2 $samplename`);


print "step 1:\n$errstepone\n";
#$outfn=$ARGV[2]
#$dirn="run_$outfn"					
# output will be $dirn/auto_$dirn.sites.bed
# also get files in find_circ/run_$samplename/auto_$samplename.sites.bed


############################################################################# second step
my$steptwoinput="$steponedir/run_$samplename/auto_$samplename.sites.bed";# right?maybe...
my$steptwooutput="$steponedir/run_$samplename";

# auto_run_hal01_r.sites.bed error

# perl steptwo/steptwo.pl important_samples.bed important_samples_processed.csv
print "trying now perl $steptwodir/steptwo.pl $steptwoinput auto_$samplename.sites_processed.csv\n\n";
my$errsteptwo = system (`perl $steptwodir/steptwo.pl $steptwoinput auto_$samplename.sites_processed.csv`);


print "step 2:\n$errsteptwo\n";
print "done making $steptwoinput.csv, moving it to run_$samplename/... \n";

system(`mv $steptwoinput.csv run_$samplename/`);
# $linfile.csv
# step three will be done later

############################################################################# third step
#my$errstepthree = system(`perl $stepthreedir/matrixmaker.pl $steptwooutput/auto_$samplename.sites_processed.csv $steptwooutput/auto_$samplename.circmatrix.csv`);



#print "step 3:\n$errstepthree\n";


## to not process the same file twice...

system(`mv $steponedir/tmp.bam tmp_$samplename.bam`);
system(`mv $steponedir/tmp.sam tmp_$samplename.sam`);

my $end = time;
my$timeused=(($end-$start)/60);# into minutes

print "done.\n used $timeused minutes for $samplename\n in $steptwooutput/auto_$samplename.sites_processed.csv";

