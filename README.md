# auto_find_circ
### automating the find_circ pipeline on a server
detecting circular RNA candidates


## will not work if one of these things is missing:
- find_circ scripts from the official repo
- bedtools installed
- bowtie2 installed
- hg19.fa
- circbase.org known circular RNAs mapping file
- all here listed .pl files in the same directory


>> auto_automaker.pl is just a small wrapper for find_circ_auto.pl, wich in return is a wrapper for test2.pl and steptwo.pl wich are in return are scripts to simplify find_circ



# three levels of automation:
  1. manually; perl test2.pl | perl steptwo.pl
  2. find_circ_auto.pl above scripts executed for one sample
  3. auto_automaker.pl above scripts for multiple samples
    -> perl matrixmaker.pl needs to be done manually in each of the above cases with chosen sample(s)!




## you can either start each step manually:
go to find_circ/

1. perl test2.pl sample_line_1_trimmed_reads.fastq.gz sample_line_2_trimmed_reads.fastq.gz samplename
   this will create the dir find_circ/run_samplename/ and put the outfile in $dirn/auto_run_samplename.sites.bed


2. perl steptwo.pl $dirn/auto_run_samplename.sites.bed (output from 1. )
  will create $dirn/auto_run_samplename.sites.bed.csv with better coordinates and only relevant information in one easy to parse \t separated file




 choose several or one auto_run_samplename.sites.bed.csv file from 2. (group) and cat allimportantones>allsamples.csv
3. perl matrixmaker allsamples.csv allimportantmatrix.txt
  this will create the file allimportantmatrix.txt where all circs with the relevent information is in.



## or start find_circ_auto.pl with first_readline second_inline samplename as input vars
  - here you will have to start matrixmaker.pl with the final outfile separately fore every sample group you want to look at




## or start auto_automaker.pl with inputfile1 inputfile2 and samplename table, separated by \t
head infiles_for_auto_automaker.pl:
lineonefile linetwofile samplename1 group1
lineonefile2  linetwofile2  samplename2 group1
the group will lead to auto_automaker making a directory named after the group where all the resulting .csv files will be copied into.


- keep in mind that all mentioned files need to be in the current wdir to be able to work as expected
- directories of mapping files for all scripts need to be changed for each environment*



## ideas to improve auto_find_circ

1. make in auto_automaker and its input a fourth column indicating the samplegroup.
  auto_auautomaker.pl should then in the end move only the relevant outputfile into the groupdir that it will create  
