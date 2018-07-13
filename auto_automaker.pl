#/usr/bin/perl -w
use strict;

system("clear");

open(ER,'>>',"logfile_auto.log")||die "$!";

system(`rm auto.bam.*.bam`);# just deleting leftovers to be sure

my$inputfile=$ARGV[0];
chomp$inputfile;
open(IN,$inputfile)|| die "$!";
my@lines=<IN>;
my$error="";# collecting dump
my@groups=();
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
		if($groupname=~/[a-z]/gi){
			if(!(grep(/$groupname/,@groups))){ # check if group already present
				mkdir $groupname;		# IF NOT, MAKE GROUPDIR
				push(@groups,$groupname);	
			}
		$errortwo=system ("cp run_$samplename/auto_run_$samplename.sites.bed.csv $groupname/");
		}
		
		print ER "errors auto_moving:\n$errortwo\n";
	}


}

foreach my $groupname (@groups){
	my$errcat=system("cat $groupname/*.csv >$groupname/allsites_bedgroup_$groupname.csv");
	my$errmatxrix=system("perl matrixmaker.pl $groupname/allsites_bedgroup_$groupname.csv allcircs_matrixout.txt");
	print ER "errors catting $groupname .csv files together:\n$errcat\n";
	print ER "errors making matrix for $groupname/allsites_bedgroup_$groupname.csv :\n$errmatxrix\n";
}

print ER "finished with all groups\n";


## now adding the groups: extra column for groupname
## each steptwo.pl outfile ist afterwards moved into one group directory and then made into one matrix with matrixmaker.pl
#
#if(!(grep(/$namesmale/,@allenames))){			# get all samplenames into @allenames
			#push (	@allenames, $namesmale);
		#}
		
#
#
#
