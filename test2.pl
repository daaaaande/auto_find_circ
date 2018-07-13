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
open(ER,'>>',"logfile_auto.log")||die "$!";
my $start = time;
# Do stuff
print ER "started at $start\n";

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
print ER "doing currently:\nbowtie2 -p 12 --very-sensitive --mm --score-min=C,-15,0 -x hg19 -1 $lineonefile -2 $linetwofile >temp.sam 2> firstpass.log\n";
       my$err = system (`bowtie2 -p 12 --very-sensitive --mm --score-min=C,-15,0 -x hg19 -1 $lineonefile -2 $linetwofile >temp.sam 2> firstpass.log`);


print ER "creating temp.bam...\n";
my$err2 = system (`samtools view -hbuS -o temp.bam temp.sam`);
print "errors:\n$err2\n\n";
system ("cp temp.bam $dirn/temp.bam");
#

# new name convention MB01==auto , MB01.bam=auto.bam
print ER "sorting temp.bam...\n";
my$err3 = system (`samtools sort -O bam -o auto.bam temp.bam`);
print ER "errors:\n$err3\n\n";
system ("cp auto.bam $dirn/auto.bam");
#echo ">>> get the unmapped"
print ER "getting the unmapped...\n";
my$err4 = system (`samtools view -hf 4 auto.bam | samtools view -Sb - > unmapped_auto.bam`);


system ("cp unmapped_auto.bam  $dirn/unmapped_auto.bam");
#echo ">>> split into anchors"
print ER "splitting into anchors...\n";
my$err5 = system (`python2.7 $bowtiepace/unmapped2anchors.py unmapped_auto.bam > $dirn/auto_anchors.qfa`);
print ER "errors:\n$err5\n\n";
#echo ">>> run find_circ.py"

# maybe the dirn in the bowtie command is the problem?

print ER "creating $dirn/auto_$dirn.sites.reads \tand  $dirn/auto_$dirn.sites.bed\n";
my$err7 = system (`bowtie2 --reorder --mm --score-min=C,-15,0 -q -x hg19 -U $dirn/auto_anchors.qfa 2> $dirn/auto_bt2_secondpass.log | python2.7 $bowtiepace/find_circ.py -G $bowtiepace/genome/chroms/ -p $dirn -s $bowtiepace/$dirn/$dirn.sites.log > $dirn/auto_$dirn.sites.bed 2> $dirn/auto_$dirn.sites.reads`);

print ER "errors:\n$err7\n\n";

my $duration = ((time - $start)/60);
print ER "Execution time first steps: $duration minutes\n";

print ER "done with first steps with sample $outfn.\n";




##bowtie2 -p 12 --very-sensitive --mm --score-min=C,-15,0 -x hg19 -1 daric/HAL01_R1_trimmed.fastq.gz -2 daric/HAL01_R2_trimmed.fastq.gz >tmp.sam 2> log.log

