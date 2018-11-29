# auto_find_circ
### automating the find_circ pipeline on a server
detecting circular RNA candidates


## will not work if one of these things is missing:
- find_circ scripts from the official repo
- bedtools installed                                      -> sudo apt install bedtools -y
- bowtie2 installed                                       -> sudo apt install bowtie2 -y
- hg19.fa                                                 -> download instructions from https://www.gungorbudak.com/blog/2014/04/13/download-human-reference-genome-hg19/
- circbase.org known circular RNAs mapping file           ->(.txt) http://circbase.org/cgi-bin/downloads.cgi
- all here listed .pl files in the same directory         -> git clone http://github.com/daaaaande/auto_find_circ/ .

- for each run/sample: two reads.fastq.gz files, and a samplename to be handled by find_circ_auto.pl
- protip: get a different name for each sample! (that means unique ones!)- that always needs at least one letter in its name! (697 and 697_r are not well suited, b697 and a697_r are!)


>> auto_automaker.pl is just a small wrapper for find_circ_auto.pl, wich in return is a wrapper for test2.pl and steptwo.pl wich are in return are scripts to simplify find_circ

 // for debugging: in /home/daniel/ the logfile_auto.log will be created that includes error messages from every of these scripts and additional information

# 4 levels of automation:
  1. manually; perl test2.pl | perl steptwo.pl
  2. find_circ_auto.pl above scripts executed for one sample
    -> perl matrixmaker.pl needs to be done manually in each of the above cases with chosen sample(s)!
    -> matrixtwo.pl can be used later to make the same information more dense
  3. auto_automaker.pl above scripts for multiple samples, makes one matrix.txt for each group if given in the auto_automaker input file
  4. godfather.pl -> does everything above for sets of samples but with each of the three pipelines one after another


## you can either start each step manually:
go to find_circ/

1. perl test2.pl sample_line_1_trimmed_reads.fastq.gz sample_line_2_trimmed_reads.fastq.gz samplename
this will create the dir find_circ/run_samplename/ and put the outfile in $dirn/auto_run_samplename.sites.bed


2. perl steptwo.pl $dirn/auto_run_samplename.sites.bed (output from 1. )
will create $dirn/auto_run_samplename.sites.bed.csv with better coordinates and only relevant information in one easy to parse \t separated file




 choose several or one auto_run_samplename.sites.bed.csv file from 2. (group) and cat allimportantones>allsamples.csv
3. perl matrixmaker allsamples.csv allimportantmatrix.txt
this will create the file allimportantmatrix.txt where all circs with the relevent information is in.

4. perl matrixtwo.pl allimportantmatrix.txt smallerallimportantmatrix.tsv
this will create a second, more dense form of information from the first matrix and add a few extra mappings

5. play with the output from 4. in the first_heatmap.R script, find candidates suiting your use case  

## or start find_circ_auto.pl with first_readline second_inline samplename as input vars
  - here you will have to start matrixmaker.pl with the final outfile separately for every sample group you want to look at




## or start auto_automaker.pl with inputfile1 inputfile2 samplename groupname table, separated by \t
```bash
~ head infiles_for_auto_automaker.txt   
lineonefile1 linetwofile1 samplename1 group1   
lineonefile2  linetwofile2  samplename2 group1
```    
the group will lead to auto_automaker making a directory named after the group where all the resulting .csv files will be copied into, catted into one big .csv file and then run matrixmaker.pl with this as an input and then start matrixtwo.pl with this as an input


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
