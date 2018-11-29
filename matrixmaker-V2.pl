#!/usr/bin/perl -w
use strict;
use Parallel::ForkManager;
# get the candidatelist_auto_all_sites.bed.csv file created with steptwo.pl
############################### example run
# perl matrixmaker.pl candidatelist_importantsamples_processed.csv important_sample_circpresencematrix.csv
##########################################
#	matrixmaker.pl for find_circ
#		- takes the outfiles from steptwo (processed.csv)
#		- for more than one sample (more useful matrix) cat the .processed.csv files into one big file, the rest will be handled by matrixmaker.pl
#		- adds a little relevant information to each candidate
#		- needs an output filename- itwill output in .tsv format to be readable for matrixtwo.pl (look at the bottom of this file for example lines for each relevant file)
#		- tracks time of usage
#		- dumps errors into logfile into global logfile
##########################################
############################################# starting- getting input vars
open(ER,'>>',"/home/daniel/logfile_auto.log")||die "$!";		# global logfile
my$start = time;
my$linfile= $ARGV[0];
chomp $linfile;

my%mapping=();
open(MA,"/media/daniel/NGS1/RNASeq/find_circ/genes_to_refseqID_nc_and_nr.tsv")|| die "$!";
my@allemappings= <MA>;
########################################################################### gene mapping file reading into hash %mapping
# each line now one array part
print ER "reading gene mapping...\n";
foreach my $mapline (@allemappings){
	chomp $mapline;
	#my $pid = $pm->start and next;
	if(!($mapline=~/^$/)){
		my@slit=split(/\s+/,$mapline);
		my$genene=$slit[0];
		$genene =~ s/\s+//g; # remove emptieness
		my$nnum="";

		if(scalar(@slit)>1){
			$nnum=$slit[1];# will be key
			if($nnum=~/N/){
				$nnum =~ s/\s+//g;
				$mapping{"$nnum"}="$genene";
			}
		}
		$nnum="";
	}
}
close MA;
# candidatelist_auto_all_sites.bed.csv file created with steptwo.pl
print ER "reading input file $linfile ...\n";
# output file second argument adding coordinates
open(IN,$linfile)|| die "$!";
########################################################################### get samlenames into array, get coordinates and basic info into arrays allenames, allecoords allebasicinfo
my@allelines= <IN>; #input file
my@allenames=();		# sample names
my@allecooords=();	# circ coordinates
my@allebasicinfo=();	# circ annotations
# $pm = Parallel::ForkManager->new(10);
for (my$i=0;$i<scalar(@allelines);$i++){
	# ignore first line
	my$line_o_o=$allelines[$i];	# current line
	#my $pid = $pm->start and next;
	if ($i>0){
		## without threading, start here
		get_names($line_o_o);
		#with threading use this
		#my $thri = threads->create("get_names","$line_o_o");$thri->detach();
		sub get_names{# later multithread this also
			my$lin= shift(@_);
			if(!($lin eq "")){
				my$line=$lin;
				if((!($line=~/coordinates/)) && ($line=~/[a-z]/)){			# check for empty line
					my@parts=split(/\t+/,$line);
					my$cord=$parts[0];
					my$strand=$parts[1];
					my$Refseqid=$parts[6];
					my$namesmale=$parts[2];
					if(!(grep(/$namesmale/,@allenames))){			# get all samplenames into @allenames
						if($namesmale ne "sampleid"){
							push (@allenames, $namesmale);
						}
					}
					if(!(grep(/$cord/,@allecooords))){			# get first threee columns into two arrays
						push (@allecooords, $cord);
						push ( @allebasicinfo, "$strand\t$Refseqid\t");
					}
				}
			}
		}
	}
#	$pm->finish;
}
#$pm->wait_all_children;
my%allinfoonesamplehash;
my$sampleout;
my%known_circs=();
open(CI,"/media/daniel/NGS1/RNASeq/find_circ/bed_files/circbase_known_circs.bed")|| die "$!";
my@alleci= <CI>;
########################################################################### gene mapping file reading into hashknown_circs
print ER "reading known circs...\n";
foreach my $circline (@alleci){			# fill a hash that is used later
	chomp $circline;
	if($circline=~/[a-z]/){
		my@slit=split(/\s+/,$circline);
		my$chr=$slit[0];	# plan ; chr:start-end to regex the coordinates of candidates
		my$cordst=$slit[1];
		my$cordnd=$slit[2];
		my$circname=$slit[3];
		my$fullcordmap="$chr:$cordst-$cordnd";# does this work??
		chomp $fullcordmap;
		$known_circs{"$fullcordmap"}="$circname";
	}
}
close CI;
############################################# get all information from one sample into a hash , key is samplename and value is all information in one var
foreach my $samplenames (@allenames){
	#print ER "looking for $samplenames circs...\n";# for each sample find all lines
	$sampleout= `grep -w $samplenames $linfile`;	#
	#print "$sampleout\n\n\n is grep $samplenames $linfile\n";
	$allinfoonesamplehash{"$samplenames"} = "$sampleout";
	# hash structure= KEY=SAMPLENAME, VALUE = ALL INFO , full line
	#my@onlysample=split(/\n+/,$sampleout);		# each line for each sample,
}
my@samples= keys %allinfoonesamplehash;
#print"should be all samplenames @samples\n";
my$outfile=$ARGV[1];
chomp $outfile;
open(OU,">",$outfile)|| die "$!";
############################################# get stable header, build resizeable header for samples
print OU "coordinates\tstrand\tRefseqID\tGene\tknown_circ\tnum_samples_present\ttotal_sum_unique_counts\tqualities\tpresent_in_sample\t";
foreach my $sampls  (@allenames) {
	print OU "sample\t-unique_count\t-qualA\t-qualB\t"; # $sampls not in same order as below, need to change it
}
print OU "\n";
############################################# look for each circ in each sample and build a matrix
					# not number of cores, but parallel processes you want, 200 seems good for 8 cores
my $pm = Parallel::ForkManager->new(1000);
my$ni=0;
our$count=0;
findc(\@allecooords);
sub findc{
  my@c=@{$_[0]};
  foreach my $circs (@allecooords){
    $count ++;
    my $pid = $pm->start and next;
    find_circ($circs);
    sub find_circ {
      my$circ= shift(@_);
      my$circcand=$circ;
	my$basicinfo=$allebasicinfo[$count -1];
	if($basicinfo=~/[A-z]/g){
		chomp $circcand;
		my$circn="";
		chomp $basicinfo;
		my$presencething=""; # for each circ cand, add names of sapmles where it is present
		my$totalcounts=0;	# for each circ cand, add unique counts
		my$allquas=""; 		# for each sample, summarize qualities
		my$line="$circcand\t$basicinfo\t";
		$line=~s/\n//g;
		#	print "line is $basicinfo\n";
		$basicinfo =~ /N*[\+\-]{1}/; # find refseqid
		my$tolookup = $';
		chomp $tolookup;
		#print "finding information for circ $tolookup\n";
		$tolookup =~s/\s+//g;
		my$allsamplelines="";
		my$allsamplehit=0;
		my$gene_name="";
		if(exists($mapping{$tolookup})){
			my$geneo=$mapping{$tolookup};
			$line="$line\t$geneo";
			$gene_name=$geneo;
			#	print "found gene $gene_name for circ $tolookup in gene mapping hash\n";
		}
		else {
			$line="$line\tunkn";
			$gene_name="unkn";
		}
		if(exists($known_circs{$circcand})){
			$circn=$known_circs{$circcand};
		}
		else{
			$circn="unknown";
		}
		foreach my $single_sample (@samples) {# looking for each sample for each circ
	  		my$allonesample= $allinfoonesamplehash{$single_sample};
        		if($allonesample=~/$circcand*.*\n/gi){### is the circ is found in sample
          			my$line_of_i=$&;
          			my$lineonesample=$line_of_i; #declare the interesting line
	    			my@hitsamples=();
          			$lineonesample=~s/$circcand//;
          			$lineonesample=~s/\n//;
	    			chomp $lineonesample;
	    			$lineonesample=~s/\t+\+//;	# removing the strand information from the hit
	    			$lineonesample=~s/\t+\-//;
	    			# has still the refseq id for every sample , need to remove that redundant informastion aswell
	    			$lineonesample =~ s/NM_[0-9]{3,11}//g;
	    			$lineonesample =~ s/NR_[0-9]{3,11}//g;
	    			$lineonesample =~ s/\.\s+//; # first remove the dot with space
	    			$lineonesample =~ tr/\.//;# then withpout
	    			if(!(grep(/^$single_sample$/,@hitsamples))){			# get all samplenames into @allenames
  	      			$allsamplelines="$allsamplelines$lineonesample";
	      			push(@hitsamples,$single_sample);# if detected, get samplename into this array
	      			$presencething="$presencething-$single_sample";
	      			$lineonesample =~/\s+[0-9]{1,4}\s+/;# only first hit is unique count
	      			my$findnum = $&; # the unique count for each sample
	      			my$twoquals=$'; # the two qualities into one
	      			$twoquals =~ s/\s+/;/;
	      			$allquas = "$allquas,$twoquals";
	      			$allquas =~s/\s+//g;
	      			$totalcounts=$totalcounts + $findnum;
	      			$ni=$totalcounts;
	      			$allsamplehit++;
	    			}
	  		}
        			else{# new: if circ not in all one samples
					chomp $single_sample;
	      			$allsamplelines="$allsamplelines$single_sample\t0\t0\t0\t";
	  			}
  		}
		$basicinfo=~s/\n//g;
		$gene_name=~s/\n//g;
		if(((($circcand=~/\:/)&&($presencething=~/[A-z]/)))){
			#hr10:93590679-93602148 -       NM_001142434    OGA     hsa_circ_0008170
	  		my$linestring="$circcand\t$basicinfo\t$gene_name\t$circn\t$allsamplehit\t$ni\t$allquas\t$presencething\t$allsamplelines\n";
	  		$linestring  =~s/\t\t/\t/g;
	  		print OU $linestring;
	  		$linestring="";
			$gene_name="";
		}
		else{			# in case something with the line is wrong
	  		print ER "error in line: circand is $circcand \n basicinfo is $basicinfo \n and presencething is $presencething\n";
		}
    	}
    	$pm->finish;
    }
  }
}# findc end
$pm->wait_all_children;
my$end=time;
my$used_mins=($end-$start)/60;
print ER "done with matrix creation of file $outfile with input $linfile\nBuilding the matrix took $used_mins minutes\n";
