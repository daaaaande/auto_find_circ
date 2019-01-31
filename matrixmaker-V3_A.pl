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
#		- needs an output filename- it will output in .tsv format to be readable for matrixtwo.pl (look at the bottom of this file for example lines for each relevant file)
#		- tracks time of usage
#		- dumps errors into logfile into global logfile
##########################################
#
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
	#	print "$mapline\n";
		my@slit=split(/\s+/,$mapline);
		my$genene=$slit[0];
		$genene =~ s/\s+//g; # remove emptieness
		my$nnum="";
		if(scalar(@slit)>1){
			$nnum=$slit[1];# will be key
			if($nnum=~/N/){
				$nnum =~ s/\s+//g;
				$mapping{"$nnum"}="$genene";
				#	print "mapping now $nnum to gene $genene\n";
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

my%sample_hash;
my%basic_info_hash;
my%alle_coords_hash;
my%alle_new_info_try_hash; # coords and strand to avoid redundant coords + strands with only different refseqid

DATA_IN:
for (my$i=0;$i<scalar(@allelines);$i++){
	my$line_o_o=$allelines[$i];	# current line
	if (!($line_o_o=~/coordinates/)){# ignore header if there , but should not be present at this stage anyway
		get_names($line_o_o);
		sub get_names{# later multithread this also
			my$line= shift(@_);
			my@parts=split(/\t+/,$line);
			my$cord=$parts[0];
			my$strand=$parts[1];
			my$Refseqid=$parts[6];
			my$namesmale=$parts[2];
			if(!(exists($sample_hash{$namesmale}))){
				$sample_hash{$namesmale}=$i;
			}
			if(!(exists($alle_new_info_try_hash{"$cord"}))){ # check for coords redundancy
				$alle_new_info_try_hash{"$cord"}=$i;
				$basic_info_hash{"$Refseqid\t$i"}=$i;
				$alle_coords_hash{"$cord\t$strand"}=$i;
			}

		}
	}
}

# without tie to keep the hashes in order we need to sort the hash keys by their value- i.e the line number of the infile
# sort the hash keys based on their values (line number in infile )
my@sorted_by_val_allenames = sort{$sample_hash{$a} <=> $sample_hash{$b}} keys %sample_hash;# sort the keys according to their value
my@allenames=@sorted_by_val_allenames;		# sample names
my@sorted_by_val_allecooords = sort{$alle_coords_hash{$a} <=> $alle_coords_hash{$b}} keys %alle_coords_hash;
my@allecooords=@sorted_by_val_allecooords; # coordinates
my@sorted_by_val_allebasicinfo = sort{$basic_info_hash{$a} <=> $basic_info_hash{$b}} keys %basic_info_hash;
my@allebasicinfo=@sorted_by_val_allebasicinfo;


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
		my$chr=$slit[0];
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
#	print  "looking for $samplenames circs...\n";# for each sample find all lines
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
					# number of cores
my $pf = Parallel::ForkManager->new(24);
my$ni=0;
our$count=0;
findc(\@allecooords);
sub findc{
	my@c=@{$_[0]};
  	DATA_OUT:
  	foreach my $circs (@allecooords){
    		$count ++;
		$pf->start and next DATA_OUT;
    		find_circ($circs);
    		sub find_circ {
      		my$circcand= shift(@_);
			#print "old line is $circcand\n";
			$circcand=~s/\t[0-9]{1,30}//;# remove the attached infile line number to not ignore strand differences
			# remove strand, attach later in full line
			$circcand=~s/\t[+-]{1}//;
			my$str=$&;
			my$basicinfo=$allebasicinfo[$count -1];
			$basicinfo=~s/\t[0-9]{1,30}//;# remove the unique makwer of maybe double circ information
			if($basicinfo=~/[A-z]/g){
				chomp $circcand;
				my$circn="unknown";
				chomp $basicinfo;
				my$presencething=""; # for each circ cand, add names of sapmles where it is present
				my$totalcounts=0;	# for each circ cand, add unique counts
				my$allquas=""; 		# for each sample, summarize qualities
				my$line="$circcand\t$basicinfo\t";
				$line=~s/\n//g;
				my$tolookup=$basicinfo;
				chomp $tolookup;
				my$allsamplelines="";
				my$allsamplehit=0;
				my$gene_name="";
				if(exists($mapping{$tolookup})){
					my$geneo=$mapping{$tolookup};
					$line="$line\t$geneo";
					$gene_name=$geneo;
					#		print "found gene $gene_name for circ $tolookup in gene mapping hash\n";
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
				foreach my $single_sample (@allenames) {# looking for each sample for each circ
	  				my$allonesample= $allinfoonesamplehash{$single_sample};
        				if($allonesample=~/$circcand*.*\n/gi){### is the circ is found in sample###
						my$line_of_i=$&;
          					my$lineonesample=$line_of_i; #declare the interesting line
      					$lineonesample=~s /$circcand//;
          					$lineonesample=~s/\n//g;
	    					$lineonesample=~s/\t+[\+\-]//;	# removing the strand information from the hit
	    					$lineonesample =~ s/N[MR]_[0-9]{3,11}//g; # removing refseqid- is the same for the same coordinates
						$lineonesample =~ s/chr[0-9]{0,3}.*\-[0-9]{1,98}\s+?//g;# remove coords sometimes mixed up in here
  	      				$allsamplelines="$allsamplelines$lineonesample";
						if($allsamplelines=~/chr/){
							warn "error in file: $allsamplelines should not include coordinates , whats the problem?\nfull line: $line_of_i\n";
						}
	      				$presencething="$presencething-$single_sample";
	      				$lineonesample =~/\s+[0-9]{1,4}\s+/;# only first hit is unique count
	      				my$findnum = $&; # the unique count for each sample
	      				my$twoquals=$'; # the two qualities into one
	      				$twoquals =~ s/\s+/;/;
						if(!($allquas=~/N/g)){ # check for refseqid instead of number
	      					$allquas = "$allquas,$twoquals";
	      					$allquas =~s/\s+//g;
	      					$totalcounts=$totalcounts + $findnum;
	      					$ni=$totalcounts;
	      					$allsamplehit++;
						}
						else{
							# refseqid is recognized as strand...
							warn "line not recognized :$line_of_i ,quality is not $allquas or $twoquals\t totalcounts are $totalcounts for sample $single_sample circ $circcand basicinfo $basicinfo \n";
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
  					my$linestring="$circcand\t$str\t$basicinfo\t$gene_name\t$circn\t$allsamplehit\t$ni\t$allquas\t$presencething\t$allsamplelines\n";
	  				$linestring  =~s/\t\t/\t/g;
	  				print OU $linestring;
	  				$linestring="";
					$gene_name="";
				}
				else{			# in case something with the line is wrong
	  				print ER "error in line: circand is $circcand \n basicinfo is $basicinfo \n and presencething is $presencething\n";
				}
    			}
    		}
  		$pf->finish;
  	}
}# findc end
$pf->wait_all_children;
my$end=time;
my$used_mins=($end-$start)/60;
print ER "done with matrix creation of file $outfile with input $linfile\nBuilding the matrix took $used_mins minutes\n";
