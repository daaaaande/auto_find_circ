#/usr/bin/perl -w
use strict;
# takes in two fastq.gz files, aligns them and creates a subdirectory for the output files it creates
# needs to be started in find_circ directory
# output; $dirn/auto_$dirn.sites.reads and logfiles
#system("clear");


######################################## example run
# perl test2.pl line_1_file.fastq.gz line_2_file.fastq.gz _important_sample_dir
#########################################


my$bowtiepace="/media/daniel/NGS1/RNASeq/find_circ";

my $start = time;
# Do stuff
print "started at $start\n";

# call needs to be :

#input files could be anywhere, script NEEDS to run in find_circ, output folder will be created in find_circ/**

#			perl test2.pl daric/HAL01_R1_trimmed.fastq.gz daric/HAL01_R2_trimmed.fastq.gz outdir



# get line one, line two and output dir name

my$lineonefile= $ARGV[0];
chomp $lineonefile;

my$linetwofile= $ARGV[1];
chomp $linetwofile;

my$outfn=$ARGV[2];
chomp $outfn;


my$dirn="run_$outfn";
mkdir $dirn ;


#this NEEDS to be executed in find_circ dir, otherwise bowtie will not run
chdir $bowtiepace ;


# first alignment
print "doing currently:\nbowtie2 -p 12 --very-sensitive --mm --score-min=C,-15,0 -x hg19 -1 $lineonefile -2 $linetwofile >temp.sam 2> firstpass.log\n";
       my$err = system (`bowtie2 -p 12 --very-sensitive --mm --score-min=C,-15,0 -x hg19 -1 $lineonefile -2 $linetwofile >temp.sam 2> firstpass.log`);


print "creating temp.bam...\n";
my$err2 = system (`samtools view -hbuS -o temp.bam temp.sam`);
print "errors aligning :\n$err2\n\n";
system ("cp temp.bam $dirn/temp.bam");
#

# new name convention MB01==auto , MB01.bam=auto.bam
print "sorting temp.bam...\n";
my$err3 = system (`samtools sort -O bam -o auto.bam temp.bam`);
print "errors samtools:\n$err3\n\n";
system ("cp auto.bam $dirn/auto.bam");
#echo ">>> get the unmapped"
print"getting the unmapped...\n";
my$err4 = system (`samtools view -hf 4 auto.bam | samtools view -Sb - > unmapped_auto.bam`);


system ("cp unmapped_auto.bam  $dirn/unmapped_auto.bam");
#echo ">>> split into anchors"
print "splitting into anchors...\n";
my$err5 = system (`python2.7 $bowtiepace/unmapped2anchors.py unmapped_auto.bam > auto_anchors.qfa`);
print "errors anchoring:\n$err5\n\n";
#echo ">>> run find_circ.py"



print "creating $dirn/auto_$dirn.sites.reads \tand  $dirn/auto_$dirn.sites.bed\n";
my$err7 = system (`bowtie2 --reorder --mm --score-min=C,-15,0 -q -x hg19 -U auto_anchors.qfa 2> auto_bt2_secondpass.log | python2.7 $bowtiepace/find_circ.py -G $bowtiepace/genome/chroms/ -p $dirn -s $bowtiepace/$dirn/$dirn.sites.log > $dirn/auto_$dirn.sites.bed 2> $dirn/auto_$dirn.sites.reads`);

print "errors bowtie2:\n$err7\n\n";

my $duration = time - $start;
print "Execution time: $duration s\n";

print "done.\n";




##bowtie2 -p 12 --very-sensitive --mm --score-min=C,-15,0 -x hg19 -1 daric/HAL01_R1_trimmed.fastq.gz -2 daric/HAL01_R2_trimmed.fastq.gz >tmp.sam 2> log.log
