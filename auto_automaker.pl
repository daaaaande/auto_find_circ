#/usr/bin/perl -w
use strict;
# change into the parent dir - this is where the infile needs to be
chdir "/media/daniel/NGS1/RNASeq/find_circ/";
#######################################################
# usage: get samples.csv into find_circ/
#					 go to find_circ/auto_find_circ/
#						perl auto_automaker.pl samples.csv dirname
#######################################################
#auto_automaker.pl for find_circ
# 		- needs a inputfile as specified in the README.md
#			- will start find_circ_auto.pl for every sample
#			- can in return be started by the godfather.pl script, this will handle the infile location correctly
#			- makes a group into a dir of the parent dir where the bed.csv files for each group will be collected
#			- then makes the two matrices for each group in the groupfolders
#			- also makes one dir run_startdate in the parent dir where data from all samples will be made into two big matrices
###############################################

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

my$ndir=$ARGV[1];
chomp $ndir;
mkdir "$ndir";


foreach my $singleline (@lines){

	if($singleline =~ /[a-z]/gi){
		chomp $singleline;
		my@lineparts=split(/\s+/,$singleline);
		my$fileone=$lineparts[0];
		my$filetwo=$lineparts[1];
		my$samplename=$lineparts[2];
		$samplename=~s/\-/_/g;# avoid - in samplenames
		my$groupname=$lineparts[3];
		## if no group is defined, put one default group there
		if($groupname eq ''){ # empty or only space-char
			$groupname="default_group_$ndir";
		}




		#####
		chomp $samplename;
		chomp $fileone;
		chomp $filetwo;
		my$tim=localtime();
		print ER "##############################################################\n";
		print ER "starting @ $tim \nfinding circs in sample $samplename with find_circ ...\n";


		$error=system("perl auto_find_circ/find_circ_auto.pl $fileone $filetwo $samplename");
		print ER "errors:\n$error\n\n";
		if($groupname=~/[A-z]/gi){
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
	my$errseding=system("sed -i '1d' $groupname/*.csv"); # will remove first line from steptwo output i.e headers
	my$errcat=system("cat $groupname/*.csv >$groupname/allsites_bedgroup_$groupname.csv");
	my$errmatxrix=system("nice perl auto_find_circ/matrixmaker-V3_A.pl $groupname/allsites_bedgroup_$groupname.csv $groupname/allcircs_matrixout.txt");
	my$matrtmaker=system("perl auto_find_circ/matrixtwo.pl $groupname/allcircs_matrixout.txt $groupname/allc_matrixtwo.tsv");
	print ER "errors making second matrix for $groupname/allsites_bedgroup_$groupname.csv :\n$matrtmaker\n";
	system("cp $groupname/allsites_bedgroup_$groupname.csv $ndir/");
	print ER "errors catting $groupname .csv files together:\n$errcat\n";
	print ER "errors making matrix for $groupname/allsites_bedgroup_$groupname.csv :\n$errmatxrix\n";
}
my$erralcat=system("cat $ndir/*.csv >$ndir/$ndir.allbeds.find_circ.out");
my$er_check_in=`perl auto_find_circ/matrix_infile_checker.pl $ndir/$ndir.allbeds.find_circ.out`;
print "checking the infile for find_circ matrix in $ndir ...\n$er_check_in \n";
my$erralm1=system("nice perl auto_find_circ/matrixmaker-V3_A.pl $ndir/$ndir.allbeds.find_circ.out $ndir/allsamples_matrix.find_circ.mat1");
my$err_mat2=system("perl auto_find_circ/matrixtwo.pl $ndir/allsamples_matrix.find_circ.mat1 $ndir/allsamples_m_heatmap.find_circ.mat2");

print "error making files in $ndir :\ncat:\t$erralcat\nmatrix 1 creation:\t$erralm1 \nmatrix 2 creation:\n$err_mat2\n";


print ER "finished with all groups\n";
