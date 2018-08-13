#/usr/bin/perl -w
use strict;
# get the candidatelist_auto_all_sites.bed.csv file created with steptwo.pl


######################################## example run
# perl matrixmaker.pl candidatelist_importantsamples_processed.csv important_sample_circpresencematrix.csv
#########################################
open(ER,'>>',"/home/daniel/logfile_auto.log")||die "$!";		# global logfile

########################################################################### input start
#system("clear");

my $start = time;

my$linfile= $ARGV[0];
chomp $linfile;
# candidatelist_auto_all_sites.bed.csv file created with steptwo.pl


print ER "reading input file $linfile ...\n";
# output file second argument adding coordinates
open(IN,$linfile)|| die "$!";





my%mapping=();
open(MA,"/media/daniel/NGS1/RNASeq/find_circ/nc_and_mRNA_mapping.txt")|| die "$!";

my@allemappings= <MA>;
########################################################################### gene mapping file reading into hash %mapping

# each line now one array part
print ER "reading gene mapping...\n";

foreach my $mapline (@allemappings){
	# fill a hash that is used later
		chomp $mapline;
		if(!($mapline=~/^$/)){
			my@slit=split(/\t+/,$mapline);
			my$genene=$slit[11];
			$genene =~ s/\s+//g; # remove emptieness
			my$nnum=$slit[10];# will be key
			$nnum =~ s/\s+//g;
			if($nnum=~/N/){ # empty lines do not help
				$mapping{"$nnum"}="$genene";
				#print "mapping now key  $nnum to $genene \n";
			# hash now = mapping
			# filled= key = NE_???
			# value = gene name
			#print " key is $nnum \t value is $genene\n";
			}
		}
}

#


close MA;

############################################################################


# add genemapping from circbase, maybe later add newly downloaded one
#daniel@TERRA-SERVER:/media/daniel/NGS/RNASeq/find_circ/bed_files$ head hsa_hg19_circRNA.bed*
#chr1	24737	24891	hsa_circ_0009177	1000	-	24891	24891	0,0,255	1	#154	0
#chr1	324438	324686	hsa_circ_0009178	1000	+	324686	324686	255,0,0	1	#248	0
#chr1	667396	667587	hsa_circ_0009179	1000	-	667587	667587	0,0,255	1	#191	0
#chr1	667396	675566	hsa_circ_0009180	1000	-	675566	675566	0,0,255	1	#8170	0
#chr1	667396	678730	hsa_circ_0009181	1000	-	678730	678730	0,0,255	1	#11334	0
#chr1	674213	678730	hsa_circ_0007211	1000	-	678730	678730	0,0,255	1	#4517	0
#chr1	682074	684761	hsa_circ_0009046	1000	-	684761	684761	0,0,255	1	#2687	0
#chr1	704876	714068	hsa_circ_0009182	1000	-	714068	714068	0,0,255	4	#216,132,110,405	0,3479,4674,8787
#chr1	709550	714068	hsa_circ_0009183	1000	-\t\t	714068	714068	0,0,255	2	#110,405	0,4113
#chr1	741178	745550	hsa_circ_0002333	1000	-	745550	745550	0,0,255	3	#93,50,104	0,2775,4268
#
#
#
#
#
#
#
##

#




################################################# get already known cirrnas from circbasemapping file daniel@TERRA-SERVER:/media/daniel/NGS/RNASeq/find_circ/bed_files$ head hsa_hg19_circRNA.bed*






my%known_circs=();
open(CI,"/media/daniel/NGS1/RNASeq/find_circ/bed_files/circbase_known_circs.bed")|| die "$!";

my@alleci= <CI>;
########################################################################### gene mapping file reading into hash %mapping

# each line now one array part
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
	#print "full coordinates are $fullcordmap\n";

	# now filling the hash- key are coords and value is circ name
		$known_circs{"$fullcordmap"}="$circname";
	# hash filled

		}
	}

#


close CI;























############################################################################ get samlenames into array, get coordinates and basic info into arrays allenames, allecoords allebasicinfo
my@dataarray=();

my@allelines= <IN>;
my@allenames=();
my@allecooords=();


my@allebasicinfo=();
my@allecircarrays=();

my@linieperline=();
 print ER "collecting sample names...\n";
for (my$i=0;$i<=scalar(@allelines);$i++){
	# ignore first line
	if ($i>=1){
		## now only relevant stuff
		my$line=$allelines[$i];	# current line
		if((!($line=~/coordinates/)) && ($line=~/[a-z]/)){			# check for empty line
			my@parts=split(/\t+/,$line);
			my$cord=$parts[0];

			my$strand=$parts[1];
			my$Refseqid=$parts[6];

			my$namesmale=$parts[2];
			if(!(grep(/$namesmale/,@allenames))){			# get all samplenames into @allenames
					if($namesmale ne "sampleid"){
						push (	@allenames, $namesmale);
					}
			}




			if(!(grep(/$cord/,@allecooords))){			# get first threee columns into two arrays
				push (	@allecooords, $cord);
				push ( @allebasicinfo, "$strand\t$Refseqid\t");

			}
		}

	}

}
#print "$gene_nametaarray[0][2]\n";
#print "allenames are\n";
#print "should be only one sample name:$allenames[0]\n";
#print "\n";
# now for each sample name fill ona array with all info


############################################################################ split file into subfiles for each sample and get it into hash

my%allinfoonesamplehash;
my$sampleout;

#$color_of{'apple'} = 'red';
 print ER "looking for circs for each sample...\n";
foreach my $samplenames (@allenames){
		print ER "looking for $samplenames circs...\n";# for each sample find all lines
		$sampleout= `grep -w $samplenames $linfile`;	#
		#print "$sampleout\n\n\n is grep $samplenames $linfile\n";
		$allinfoonesamplehash{"$samplenames"} = "$sampleout";
		# hast structure= KEY=SAMPLENAME, VALUE = ALL INFO , full line
		my@onlysample=split(/\n+/,$sampleout);		# each line for each sample,

}

############################################################################ prepare for output file

# go throug all coords, look in value for each hash...
my@samples= keys %allinfoonesamplehash;
#print"should be all samplenames again(before hash) @samples\n";



my$outfile=$ARGV[1];
chomp $outfile;
open(OU,">",$outfile)|| die "$!";



############################################################################ actual output file craetion- sorting by coordinates ald listing info for each sample, adding some info

# file header
print OU "coordinates\tstrand\tRefseqID\tGene\tknown_circ\tnum_samples_present\ttotal_sum_unique_counts\tqualities\tpresent_in_sample\t";
foreach my $sampls  (@allenames) {
	print OU "sample\t-unique_count\t-qualA\t-qualB\t"; # $sampls not in same order as below, need to change it
}
print OU "\n";


my$numcou=0;
## opening the two mapping files, catted into one big file,

my$ni=0;
my$countm=0;

for(my$count=0;$count<scalar(@allecooords);$count++){
	my$circcand=$allecooords[$count];
	my$basicinfo=$allebasicinfo[$count];
	chomp $circcand;
	my$circn="";
	chomp $basicinfo;
	my$presencething=""; # for each circ cand, add names of sapmles where it is present
	my$totalcounts=0;	# for each circ cand, add unique counts
	my$allquas=""; 		# for each sample, summarize qualities
	my$line="$circcand\t$basicinfo\t";
	$line=~s/\n//g;
	$basicinfo =~ /N*[\+\-]{1}/; # find refseqid
	my$tolookup = $';
	chomp $tolookup;
	$tolookup =~s/\s+//g;
	# print "tolookup ist ;$tolookup;;\n"; ## tolookup ist ;NM_000314;;-> can be mapped to circbase?
	my$allsamplelines="";
	my$allsamplehit=0;
	#print "now looking for $tolookup...";
	# now find tolookup in one of the two files
	my$gene_name="";
	if(exists($mapping{$tolookup})){
	#	print "looking for key value $tolookup in gene hash\n";
		my$geneo=$mapping{$tolookup};
		$line="$line\t$geneo";
	#	print "found $geneo\n";
		$gene_name=$geneo;
	}

	else {
		$line="$line\tunkn";
		$gene_name="unkn";
	}

	# built in; $known_circs{"$fullcordmap"}="$circname";

	#### circrna mapping added

	if(exists($known_circs{$circcand})){
		$circn=$known_circs{$circcand};
		#$line="$line\t$geneo";
		#$gene_name=$geneo;
	}

	else{
		$circn="unknown";
	}




	#print "line is:\n$circcand\t$basicinfo\t::";
	foreach my $single_sample (@samples) {
		#$numcou=scalar(@samples);# number of samples where the candidate is in
    		#print "The color of '$single_sample' is $color_of{$single_sample}\n";
		my$allonesample= $allinfoonesamplehash{$single_sample};
		# first split into lines
		my@everyline=split(/\n/,$allonesample);
		#print "looking for $circcand in sample $single_sample...\n";

		foreach my $lineonesample (@everyline){
			#$countm=0;
		# see if coord match
		my@hitsamples=();
			if($lineonesample =~s/$circcand//){

				chomp $lineonesample;
				$lineonesample=~s/\t+\+//;	# removing the strand information from the hit
				$lineonesample=~s/\t+\-//;
				# has still the refseq id for every sample , need to remove that redundant informastion aswell
				$lineonesample =~ s/NM_[0-9]{3,11}//g;## does that work?yes
				$lineonesample =~ s/NR_[0-9]{3,11}//g;## does that work?yes
				# now remove annoying . before sampleid
				$lineonesample =~ tr/\.\s+//; # first remove the dot with space
				$lineonesample =~ tr/\.//;# then withpout
				$line="$line$lineonesample";

				# check for presence of sample
				# full name. i.e 697 should not match 697_r
				if(!(grep(/^$single_sample$/,@hitsamples))){			# get all samplenames into @allenames

					$allsamplelines="$allsamplelines$lineonesample";
					push(@hitsamples,$single_sample);# if detected, get samplename into this array
					$presencething="$presencething-$single_sample";
				#print "lineonesqampleis:$lineonesample::\t";
				# line has still the strand on it, need to remove it
					$countm++;
					$lineonesample =~/\s+[0-9]{1,4}\s+/;# only first hit is unique count
					my$findnum = $&; # the unique count for each sample
					my$twoquals=$'; # the two qualities into one
					$twoquals =~ s/\s+/;/;
					$allquas = "$allquas,$twoquals";
					$allquas =~s/\s+//g;
					$totalcounts=$totalcounts + $findnum;
					$ni=$totalcounts;
					$allsamplehit++;
				#print "totalcount $ni for $circcand\n";
				}
			}
			else{# else space needs to be filled with zeros
				#print "0\t0\t0\t0\t"	# did print a 0 for every non match in samplespace,
			}
			if($countm==1){		# if found one entry in a sample for the circ candidate, finish
				last;
			}
		}
		if($countm==0){		# at the end of each sample, if not found fill space with zeroes
			chomp $single_sample;
			#print "nohit is:$single_sample\t0\t0\t0\t0\t::";
			$line="$line\t$single_sample\t0\t0\t0\t";
			$allsamplelines="$allsamplelines$single_sample\t0\t0\t0\t";

		}

	$countm=0;
	#$allsamplenames should be all sample information to stick at the end...
	#print "done looking for coordinates $circcand\n";

	}
	chomp $line;
	$basicinfo=~s/\n//g;
	$gene_name=~s/\n//g;
	if(((($circcand=~/\:/)&&($presencething=~/[a-z]/)))){
		my$linestring="$circcand\t$basicinfo\t$gene_name\t$circn\t$allsamplehit\t$ni\t$allquas\t$presencething\t$allsamplelines\n";
		$linestring  =~s/\t\t/\t/g;

	 	print OU $linestring;
	 	$linestring="";
	}
		else{			# in case something with the line is wrong
			print ER "error in line: circand is $circcand \n basicinfo is $basicinfo \n and $presencething is $presencething\n";
		}
 }
	#						|				|				|			|							|				|									|								$ni												t$allquas			$allsamplelines one after another
	#coordinates\tstrand\tRefseqID\tGene\tknown_circ\tnum_samples_present\tpresent_in_sample\ttotal_sum_unique_counts\tqualities\t
	#print "$line\t$presencething\t$totalcounts\t$allquas\n";# presecething is a list of samples where circ candidate is present, totalcounts is the unique counts added together
	#print "next line , circ should be fully done by now...\n";
	#print "\n";
	#$count++;



#############################################I/O
## additional mapping : http://www.ensembl.org/biomart/martview/d34523b70fd370bdc53ee6e882e8cff8

# input ; is ARGV[0] ;candidatelist_auto_$linfile.csv";
# coordinates     strand  sampleid        unique_counts   qualA   qualB   RefSeqID
#chr10:101654702-101656154       -       run_3r_testneu  3       34      40      NM_015221
#chr10:101689364-101691202       -       daric/Chen01_   2       40      40      NM_015221
#chr10:101689364-101691202       -       daric/Chen01_   2       40      40      NR_024130
#chr10:101923760-101943594       -       auto_   2       40      6       NM_006459
#chr10:101923760-101943594       -       auto_   2       40      6       NM_001100626



## output is ARGV[1] created in directory where it is run;
# coordinates     strand  RefseqID        Gene    present_in_sample       total_sum_unique_counts qualities       sample  -unique_count   -qualA  -qualB  sample  -unique_count   -qualA  -qualB  sample  -unique_count   -qualA  -qualB  sample  -unique_count   -qualA  -qualB
#chr10:101654702-101656154       -       NM_015221               DNMBP   -run_3r_testneu 3       ,34;40          run_3679_testneu        0       0       0       daric/Chen01_   0       0       0       auto_   0       0       0               run_3r_testneu  3       34      40
#chr10:101689364-101691202       -       NM_015221               DNMBP   -daric/Chen01_  2       ,40;40          run_3679_testneu        0       0       0               daric/Chen01_   2       40      40      auto_   0       0       0       run_3r_testneu  0       0       0

# make a score # present# cpount matrix for each candidate with one for each sample




## relies on mapping files from ensembl http://www.ensembl.org/biomart/martview/e6bfa814a8ad21d2591da4206dabbb19 ;

# file needs to be in find_circ/nc_and_mRNA_mapping.txt



# ENSG00000217801 AL390719.1      NR_148960       XR_001737603
#ENSG00000217801 AL390719.1      NR_148960       XR_001737598
#ENSG00000217801 AL390719.1      NR_148960       XR_001737602
#ENSG00000217801 AL390719.1      NR_148960       XR_001737600
#ENSG00000217801 AL390719.1      NR_148960       XR_001737597



#
#
#reading input file steptwo/candidatelist_auto_allesites.bed.csv ...
#reading gene mapping...
#collecting sample names...
#looking for circs for each sample...
#looking for run_3r_testneu circs...
#looking for daric/Chen01_ circs...
#looking for auto_ circs...
#looking for run_3679_testneu circs...
#
#
#
##
