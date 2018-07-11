#/usr/bin/perl -w
use strict;

system("clear");

my$inputfile=$ARGV[0];
chomp$inputfile;
open(IN,$inputfile)|| die "$!";
my@lines=<IN>;
my$error="";# collecting dump
foreach my $singleline (@lines){
	if($singleline =~ /[a-z]/g){# checking for empty lines to avoid weird errors
		chomp $singleline;
		my@lineparts=split(/\s+/,$singleline);
		my$fileone=$lineparts[0];
		my$filetwo=$lineparts[1];
		my$samplename=$lineparts[2];
		chomp $samplename;
		chomp $fileone;
		chomp $filetwo;
		print "finding circs in sample $samplename...\n";
		$error=system(`perl find_circ_auto.pl $fileone $filetwo $samplename`);
	}


}
print "errors:\n$error\n\n";
print "finished\n";
