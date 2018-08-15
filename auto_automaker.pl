#/usr/bin/perl -w
use strict;

system("clear");

chdir "../";

open(ER,'>>',"/home/daniel/logfile_auto.log")||die "$!";		# global logfile

system("rm auto.bam.*.bam");# just deleting leftovers to be sure
system("rm tmp_*.bam");

my$inputfile=$ARGV[0];
chomp$inputfile;
open(IN,$inputfile)|| die "$!";	# infile is a .csv file steptwo output.csv
my@lines=<IN>;
my$error="";# collecting dump
my@groups=();
my$errortwo="";
foreach my $singleline (@lines){
	if($singleline =~ /[a-z]/gi){
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
		$error=system("perl auto_find_circ/find_circ_auto.pl $fileone $filetwo $samplename");
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
my$date= localtime();
$date=~s/\s+/_/g;
$date=~s/[0-9]//g;
$date=~s/\://g;
$date=~s/\_\_//g;
mkdir "all_run_$date";

foreach my $groupname (@groups){
	my$errseding=system("sed -i '1d' $groupname/*.csv"); # will remove first line from steptwo output i.e headers
	my$errcat=system("cat $groupname/*.csv >$groupname/allsites_bedgroup_$groupname.csv");
	my$errmatxrix=system("perl matrixmaker.pl $groupname/allsites_bedgroup_$groupname.csv $groupname/allcircs_matrixout.txt");
	my$matrtmaker=system("perl matrixtwo.pl $groupname/allcircs_matrixout.txt $groupname/allc_matrixtwo.tsv");
	print ER "errors making second matrix for $groupname/allsites_bedgroup_$groupname.csv :\n$matrtmaker\n";
	system("cp $groupname/allsites_bedgroup_$groupname.csv all_run_$date/");
	print ER "errors catting $groupname .csv files together:\n$errcat\n";
	print ER "errors making matrix for $groupname/allsites_bedgroup_$groupname.csv :\n$errmatxrix\n";
}
my$erralcat=system("cat all_run_$date/* >all_run_$date.allbeds.out");
my$erralm1=system("perl matrixmaker.pl all_run_$date/all_run_$date.allbeds.out all_run_$date/allsamples_matrix.tsv");
my$err_mat2=system("perl matrixtwo.pl all_run_$date/allsamples_matrix.tsv all_run_$date/allsamples_m_heatmap.tsv");

print "error making files in all_run_$date :\ncat:\t$erralcat\nmatrix 1 creation:\t$erralm1 \nmatrix 2 creation:\n$err_mat2\n";


print ER "finished with all groups\n";
