#/usr/bin/perl -w
use strict;

## example usage of map_file sub 
my%hash_test=map_file("/home/daric/auto_find_circ/protein_class_COSMIC.tsv",0,3);




#
# ## test
# my$testval=$hash_test{TPM4};
# print "test= $testval\nrr\n";
#
# my@allk=keys %hash_test;
# my$wert=scalar(@allk);
# print "found $wert keys\n";
# #print "keys are : $allkeys\n";
#

sub map_file  {
  # given params
  my$file=$_[0];
#  my%hash_to_fill=$_[1];
  my$position_key=$_[1];
  my%hash_to_fill=();
  my$position_values=$_[2];

  # body...

  open(IN,$file) || die "$!";
  my@all_lines=<IN>;
  foreach my $singleline (@all_lines){
    chomp $singleline;
      my@al_line_contents=split(/\t/,$singleline);
      my$key=$al_line_contents[$position_key];
      my$value=$al_line_contents[$position_values];
      print "filling now with key $key and value $value\n";
      $hash_to_fill{$key}="$value";
  }
  return %hash_to_fill;
}
