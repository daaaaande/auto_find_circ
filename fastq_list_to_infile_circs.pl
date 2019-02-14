#/usr/bin/perl -w

# script to get from a list of .fastqs to a acceptable infile for godfather.pl
#usage:
# go to folder with only interesting fastq files
#   ls -1 *.fastq >files.list
#     perl ~/Desktop/fastq_list_to_infile_circs.pl fastqs.list >godfather_infile.txt
#       move/copy .fastqs to /find_circ
#         copy godfather_infile.txt into find_circ/
#           cd find_circ/auto_find_circ
#             perl godftaher.pl godfather_infile.txt
use strict;

my$inputfile=$ARGV[0];


my@file_names=(); # save file names here
chomp$inputfile;
open(IN,$inputfile)|| die "$!";	# infile is a .csv file steptwo output.csv
my@lines=<IN>;

foreach my $singleline (@lines){
  chomp $singleline;
  # the 2.fastq vs 1.fastq
  if($singleline=~/1\.fastq/){
    # first file of two
    my$file_1=$singleline;
    $singleline=~s/1\.fastq/2\.fastq/;
    my$second_file=$&;
    my$file_2=$singleline;
    # files are now $file1 and my$second_file
    $singleline=~s/\.fastq//;
    $singleline=~s/R1//;
    $singleline=~s/__2//;
    # testing if the second file is really there the way it is written out
    $inputfile=~s/\..*//g; # remove the infile.txt ending
    my$default_group="default_group_$inputfile";
    my$there_test=`ls -1 $file_2`;
  #  print "checking now for $file_2\n";
    if($there_test=~/\.fastq/){
      # file is there
      #print "second file found\n";
    }
    else{
      die "file $file_2 infered from $file_1 not found in $there_test\n";
    }

    #my$sample_name=$&;
    print "$file_1\t$file_2\t$singleline\t$default_group\n";
  }
}
