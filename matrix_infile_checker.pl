#!/usr/bin/perl -w
use strict;

#matrixmaker_inputchecker.pl
# checks file handled to matrixmaker if there qare any missaligned columns

#open(ER,'>>',"/home/daniel/logfile_auto.log")||die "$!";		# global logfile
my$start = time;
my$linfile= $ARGV[0];
chomp $linfile;



open(IN,$linfile)|| die "$!";
########################################################################### get samlenames into array, get coordinates and basic info into arrays allenames, allecoords allebasicinfo
my@allelines= <IN>; #input file
my$mist=0;
for (my$i=0;$i<scalar(@allelines);$i++){

	my$line_o_o=$allelines[$i];	# current line
  my@parts=split(/\t+/,$line_o_o);
  my$cord=$parts[0];
  my$strand=$parts[1];
  my$Refseqid=$parts[6];
  my$namesmale=$parts[2];# sample

# now checking the inputfile

if(!($strand=~/[+-]/)){
  warn "line $i file $linfile: strand is $strand \n";
  $mist++;
}
if(!($cord=~/chr/)){
    warn "line $i file $linfile: coordinates $cord does not include chromosome! \n";
    $mist++;
}
if(!($Refseqid=~/N/)){
  warn "line $i file $linfile: Refseqid $Refseqid does not include refseqid! \n";
  $mist++;

}

if($mist > 0){
  print "line with mistaken parts: $line_o_o\n"
}
$mist=0;

}
