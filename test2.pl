#/usr/bin/perl -w
use strict;
# takes in two fastq.gz files, aligns them and creates a subdirectory for the output files it creates
# needs to be started in find_circ directory
# output; $dirn/auto_$dirn.sites.reads and logfiles
#`clear`;

chdir "../";

######################################## example run
# perl test2.pl line_1_file.fastq.gz line_2_file.fastq.gz _important_sample_dir
#########################################


my$bowtiepace="/media/daniel/NGS1/RNASeq/find_circ";
open(ER,'>>',"/home/daniel/logfile_auto.log")||die "$!";		# global logfile
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
mkdir "$bowtiepace/$dirn";


#this NEEDS to be executed in find_circ dir, otherwise bowtie will not run
chdir $bowtiepace ;


# first alignment
print ER "doing currently:\nbowtie2 -p 12 --very-sensitive --mm --score-min=C,-15,0 -x hg19 -1 $lineonefile -2 $linetwofile >temp.sam 2> firstpass.log\n";
my$err = `bowtie2 -p 12 --very-sensitive --mm --score-min=C,-15,0 -x hg19 -1 $lineonefile -2 $linetwofile >temp.sam 2> firstpass.log`;


print ER "creating temp.bam...\n";
my$err2 = `samtools view -@ 10 -hbuS -o temp.bam temp.sam`;
print ER "errors:\n$err2\n";
my$er_cpo=`cp temp.bam $bowtiepace/$dirn/temp.bam`;
#
print ER "errors copying :\n$err2\n";
# new name convention MB01==auto , MB01.bam=auto.bam
print ER "sorting temp.bam...\n";
my$err3 = `samtools sort -@ 10 -O bam -o auto.bam temp.bam`;
print ER "errors:\n$err3\n";
my$er_cpa=`cp auto.bam $bowtiepace/$dirn/auto.bam`;
print ER "errors copying auto.bam:\n$er_cpa\n";

#echo ">>> get the unmapped"

print ER "getting the unmapped...\n";
my$err4 = `samtools view -@ 10 -hf 4 auto.bam | samtools view -@ 10 -Sb - > unmapped_auto.bam`;


my$rtrt=`cp unmapped_auto.bam  $bowtiepace/$dirn/unmapped_auto.bam`;
#echo ">>> split into anchors"
print ER "errors:$err4\nerrors copying the unmapped: $rtrt\n";

print ER "splitting into anchors...\n";
my$err5 = `python2.7 $bowtiepace/unmapped2anchors.py unmapped_auto.bam > $dirn/auto_anchors.qfa`;
print ER "errors:\n$err5\n";
#echo ">>> run find_circ.py"

# maybe the dirn in the bowtie command is the problem?

print ER "creating $bowtiepace/$dirn/auto_$dirn.sites.reads \tand  $bowtiepace/$dirn/auto_$dirn.sites.bed\n";
my$err7 = `bowtie2 --reorder --mm --score-min=C,-15,0 -q -x hg19 -U $bowtiepace/$dirn/auto_anchors.qfa 2> $bowtiepace/$dirn/auto_bt2_secondpass.log | python2.7 $bowtiepace/find_circ.py -G $bowtiepace/genome/chroms/ -p $outfn -s $bowtiepace/$dirn/$dirn.sites.log > $bowtiepace/$dirn/auto_$dirn.sites.bed 2> $bowtiepace/$dirn/auto_$dirn.sites.reads`;

print ER "errors:\n$err7\n";

my $duration = ((time - $start)/60);
print ER "Execution time first steps: $duration minutes\n";

print ER "done with first find_circ steps with sample $outfn.\n";




##bowtie2 -p 12 --very-sensitive --mm --score-min=C,-15,0 -x hg19 -1 daric/HAL01_R1_trimmed.fastq.gz -2 daric/HAL01_R2_trimmed.fastq.gz >tmp.sam 2> log.log
