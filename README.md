# auto_find_circ
a multiple sample multiple pipeline wrapper for RNA seq -> circ RNA detection;  automating the find_circ pipeline on a server

## ..but why?
We found ourselves in the situation to look for circular RNAs in human RNA sequence data more and more. The three pipelines find_circ, DCC and circexplorer1 are known and we wanted to look for circs in multiple datasets at best with all three mentioned pielines and compare the results thereof. the scripts provided are a solution to this problem. Configured correctly, the godfather script will output circs from each pipeline - for all samples in an easy to parse fashion.
It also leaves the option open to add samples later, re-run the matrixmaker scripts and redefine groups by just combining the individual outfiles as the user wants. As far as we tested, when you run the same sample 10 times, the output will be the same 10 times. The output format for each of the original pielines is different, but the here provided scripts will re-format the output into a minimalistic .tsv file for each sample in each pipeline. Configured once the godfather.pl script runs until all 3 pipelines finished with all groups, no further input needed. If you want to use the hardware while the pipeline is running, just start the perl scripts with "nice" in front- all child processes will inherit the lower priority and thus not block the hardware for other things. There are at this point no plans to add another pipeline to the current workflow.


## will not work if one of these things is missing:
- find_circ scripts from the official repo                
- bedtools installed                                      -> sudo apt install bedtools -y
- bowtie2 installed                                       -> sudo apt install bowtie2 -y
- hg19.fa                                                 -> download instructions from https://www.gungorbudak.com/blog/2014/04/13/download-human-reference-genome-hg19/ // should work with other organisms aswell
- circbase.org known circular RNAs mapping file           ->(.txt) http://circbase.org/cgi-bin/downloads.cgi
- all here listed .pl files in the same directory         -> git clone http://github.com/daaaaande/auto_find_circ/ .

### preparation steps:
- get a linux (Ubuntu) machine (more performance is better)
- install python 2.7, up-to-date Perl (plus package Parallel::ForkManager)
- get bowtie2 to run, use hg19 to create genome index
- get find_circ running (should be okay to only download)
- change the directories in each script (just exchange the file path to where you want to run it)
- first test test2.pl, then steptwo.pl, then find_circ_auto.pl, then auto_automaker.pl - matrixmaker.pl and matrixtwo.pl are optional and are helpful for multiple samples, test them only if you intend to use them
- adjust usage to hardware (unfortunately not all steps are multi-threaded, but most steps do have some core parameters where you could optimize the usage)  
- godfather.pl only needs to work if you are planning to use more than one pipeline on the same sample/infiles


>> auto_automaker.pl is just a small wrapper for find_circ_auto.pl, wich in return is a wrapper for test2.pl and steptwo.pl wich are in return are scripts to simplify find_circ for more than one sample

 // for debugging: in /home/daniel/ the logfile_auto.log will be created that includes error messages from every of these scripts and additional information

## 4 levels of automation:
  1. manually:
  __________________________  
`perl test2.pl infilelane1.fastq infilelane2.fastq samplename`
   this will create the dir find_circ/run_samplename/ and put the outfile in $dirn/auto_run_samplename.sites.bed  
  `perl steptwo.pl steptwoinput=steponedir/run_$samplename/auto_run_samplename.sites.bed `
   will create $dirn/auto_run_samplename.sites.bed.csv with better coordinates and only relevant information in one easy to parse \t separated file
   optional  step:
  `cat all_samples_steptwo:output.csv >all_interesting_samples_circs.in  `
   optional  step:
  `perl matrixmaker.pl steptwooutput.csv `  
   (or for multiple samples at once : all_interesting_samples_circs.in ) matrixoutput.tsv : this will create the file allimportantmatrix.txt where all circs with the relevent information is in.
   optional  step:
  `perl matrixtwo.pl matrixoutput.tsv matrixtwo_out.tsv `<- this file should be readable for R, Excel... # this will create a second, more dense form of information from the first matrix and add a few extra mappings

  2. find_circ_auto.pl above scripts executed for one sample:
 __________________________
`perl find_circ_auto.pl infilelane1.fastq infilelane2.fastq samplename`
    -> perl matrixmaker.pl can be done manually with its output aswell as
    -> matrixtwo.pl can be used later to make the same information more dense

  3. auto_automaker.pl above scripts for multiple samples, makes one matrix.tsv for each group and all samples if given in the auto_automaker input file and dumps every outfile in specified folder :
   __________________________  
`perl auto_automaker.pl infile.txt full_run_outdir`

  4. godfather.pl -> does everything above for sets of samples but with each of the three pipelines one after another , need to specify a run output dir name (as parameter) aswell as groups and sample names (in the infile) :
   __________________________  
   `perl godfather.pl infile.txt full_run_outdir `


### you can either start each step manually:
go to find_circ/
`perl test2.pl sample_line_1_trimmed_reads.fastq.gz sample_line_2_trimmed_reads.fastq.gz samplename`

`perl steptwo.pl $dirn/auto_run_samplename.sites.bed `(output from 1. )

choose several or one auto_run_samplename.sites.bed.csv file from 2. (group) and `cat allimportantones>allsamples.csv`
`perl matrixmaker allsamples.csv allimportantmatrix.txt`

`perl matrixtwo.pl allimportantmatrix.txt smallerallimportantmatrix.tsv`
then  play with the output from 4. in the first_heatmap.R script, find candidates suiting your use case  

### or start find_circ_auto.pl with first_readline second_inline samplename as input vars
  - here you will have to start matrixmaker.pl with the final outfile separately for every sample group you want to look at




### or start auto_automaker.pl  or godfather.pl with inputfile1 inputfile2 samplename groupname table, separated by \t
start the godfather :

`cd find_circ/`
` head infiles_for_auto_automaker.txt   `
`lineonefile1.fastq linetwofile1.fastq samplename1 group1   `
`lineonefile2.fastq  linetwofile2.fastq  samplename2 group1`
`cd auto_find_circ/`
` nice perl godfather.pl infiles_for_auto_automaker.txt run_dirname` all 3 pipelines
 or
`nice perl auto_automaker.pl infiles_for_auto_automaker.txt run_dirname` only find_circ      

the optional group will lead to auto_automaker making a directory named after the group where all the resulting .csv files will be copied into, catted into one big .csv file and then run matrixmaker.pl with this as an input and then start matrixtwo.pl with this as an input

the run_dirname creates a folder in each pipeline dir, and dumps the final result of all samples into there.

- keep in mind that all mentioned files need to be in the current wdir to be able to work as expected
- directories of mapping files for all scripts need to be changed for each environment

## the last steps for each group in auto_automaker.pl:
- removes header lines from each groupname/.csv just be be sure
- cat all .csv files into one groupname/allsites_bedgroup_groupname.csv
- create a matrix with matrixmaker.pl groupname/allcircs_matrixout.txt
- create a second, more dense matrix with perl matrixtwo.pl groupname/allcircs_matrix_heatmap.txt

-> from there on first_heatmap.R will filter the results, needs to be run manually and should be an example of how to handle the  allcircs_matrix_heatmap.txt

## godfather.pl
->  will start the auto_automaker with the same input file for all three here seen pipelines, then add everything together into one dir called all_run_DAY_MONTH/

 >the main data output is already done for the steptwo output, the matrixmaker.pl and matrixtwo.pl combined with the first_hetmap.R will just make it more easy to analyze the data that comes out. so in theory you could ignore the last 3 steps!


 > when mapping files for the matrix making steps are missing you could just comment those lines if you do not want the addistional information!
