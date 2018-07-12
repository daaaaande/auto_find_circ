#/usr/bin/perl -w
use strict;

system("clear");

open(ER,'>>',"logfile_auto.log")||die "$!";


my$inputfile=$ARGV[0];
chomp$inputfile;
open(IN,$inputfile)|| die "$!";
my@lines=<IN>;
my$error="";# collecting dump
my$errortwo="";
foreach my $singleline (@lines){
	if($singleline =~ /[a-z]/g){
		chomp $singleline;
		my@lineparts=split(/\s+/,$singleline);
		my$fileone=$lineparts[0];
		my$filetwo=$lineparts[1];
		my$samplename=$lineparts[2];
		my$groupname=$lineparts[3];
		chomp $samplename;
		chomp $fileone;
		chomp $filetwo;
		print "finding circs in sample $samplename...\n";
		$error=system(`perl find_circ_auto.pl $fileone $filetwo $samplename`);
		print ER "errors:\n$error\n\n";
		mkdir $groupname;
		$errortwo=system (`mv run_$samplename/auto_run_$samplename.sites.bed.csv $groupname/`);
		print ER "errors auto_moving:\n$errortwo\n";
	}


}


print ER "finished\n";


## now adding the groups: extra column for groupname
## each steptwo.pl outfile ist afterwards moved into one group directory and then made into one matrix with matrixmaker.pl
