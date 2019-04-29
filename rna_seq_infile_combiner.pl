#/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);
# takes a ls -1 *.fastq file and combines the files into two lanes, each called cb_ with all same lane same sample files catted into one


#
#ICGC_MB96_s_120712_5b_R1_1.fastq
#ICGC_MB96_s_120712_5b_R1_2.fastq
#ICGC_MB96_s_130822_5_R1_1.fastq
#ICGC_MB96_s_130822_5_R1_2.fastq
#ICGC_MB98_s_120712_5a_R1_1.fastq
#ICGC_MB98_s_120712_5a_R1_2.fastq
#ICGC_MB98_s_130418_5_R1_1.fastq
#ICGC_MB98_s_130418_5_R1_2.fastq
#ICGC_MB99_s_120712_7a_R1_1.fastq
#ICGC_MB99_s_120712_7a_R1_2.fastq
#ICGC_MB99_s_130822_6_R1_1.fastq
#ICGC_MB99_s_130822_6_R1_2.fastq
#ICGC_MB9_s_111110_3a_R1_1.fastq
#ICGC_MB9_s_111110_3a_R1_2.fastq
#ICGC_MB9_s_131010_2_R1_1.fastq
#ICGC_MB9_s_131010_2_R1_2.fastq

# should result in (for first sample here )
# cat ICGC_MB96_s_120712_5b_R1_1.fastq ICGC_MB96_s_130822_5_R1_1.fastq >ICGC_MB96_s_130822_5_cb__R1_1.fastq


#

# first get the file list, get samplenames and lane names combinations from filenames
# we need to make a few assumptions here:
#1. the

my$inputfile=$ARGV[0];

chomp$inputfile;
open(IN,$inputfile)|| die "$!";	# infile is a .csv file steptwo output.csv
my@lines=<IN>;

my@full_file_names=();
my@sample_names=();
my$all_used_ones;

foreach my $singleline (@lines){
  # get the fukll file name into an array, the sample name isolate and the lane
  #print "line is $singleline\n";
  # get the full filename into a
  $singleline=~s/\s+//g; # no emptyness allowed here
  my$full_file=$singleline;
  # now we get the sample name
  # most of the sample names have ICGC beforehand, so thats nice
  $singleline=~/MB\w+\_?/;
  my$sample=$&;
  $sample=~/\_/;
  $sample=$`;
  # should be something like MB99_
  $singleline=~/\d\.fastq/;
  my$lane_n=$&;
  $lane_n=~s/\.fastq//;
#  print "sample name is $sample, lane is $lane_n, full line $singleline\n";
# checks out. now push into arrays, combine then
   # we could already cat here ?
    #sample does not matter- w can make one out of that- so sample name and lane are the same? -> then cat them!
   # push all into the three arrays
   my$ident="$sample.$lane_n";
   push(@sample_names,$ident);
   push(@full_file_names,$singleline);
  # print "ident $ident fullfile $singleline\n";


}
# remove numbers, do the a and fs
# there are cases where more than twi files are catted!
#@sample_names= uniq (@sample_names);

my@tried_ones=();#avoiding making the same command as many times as files are there
my$o=0;
foreach my $identity (@sample_names){

#  print "checking $identity\n";
  my@all_file_names_for_single_ident=();
  # get all files with same ident, cat them
  my$file_single_ident=$full_file_names[$o];
 #print "checking ident $identity\n";
  for(my$i=0;$i<=scalar(@sample_names);$i++){
    my$single_ident=$sample_names[$i];
  #print "checking  $single_ident to $identity\n";
    if("$single_ident" eq "$identity"){
      #print "fitted $single_ident to $identity\n";
      my$fileoo=$full_file_names[$i];
      push(@all_file_names_for_single_ident,$fileoo);# here are now all fioles with the same idetity as the one chosen...
      # now we need a combined filename, make a proper cat command and execute it
    #  print "so nowfile $file_single_ident will be catted with$fileoo \n";
    }
    else{
    #  print "failed to match $single_ident to $identity\n";
    }
  }
# here all same ident files should be in the array
# get a final filename and that should be it
my$new_file_name="cb_$file_single_ident";
my$all_file=join(" ",@all_file_names_for_single_ident);
# check for more than one file
my$sc_zi=scalar(@all_file_names_for_single_ident);
#print "have $sc_zi files for $identity\n";
if($sc_zi>1){
  if(!($all_used_ones=~/$identity/)){


    $all_file=~s/\n//g;
    print "cat $all_file >$new_file_name\n";
    $all_used_ones="$all_used_ones.\n.$identity";
  }
  # only combine if more than one file has the same $identity
}
$o++;
}
