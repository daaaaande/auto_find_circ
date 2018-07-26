#/usr/bin/perl -w
use strict;
# this file to be used as a function in several parts when a file needs to be mapped into a hash 
sub map_file  {
  # given params
  my$file=$_[0];
  my$position_key=$_[1];
  my%hash_to_fill=();
  my$position_values=$_[2];
  my$separator=$_[3];

  open(IN,$file) || die "$!";
  my@all_lines=<IN>;
  foreach my $singleline (@all_lines){
    chomp $singleline;
      my@al_line_contents=split(/$separator/,$singleline);
      my$key=$al_line_contents[$position_key];
      my$value=$al_line_contents[$position_values];
          if($key=~/[A-z]/){                # check both for empty values
            if($value=~/[A-z]/){
        #        print "filling now with key $key and value $value\n";
                $hash_to_fill{$key}="$value";
        }
      }
  }
  return %hash_to_fill;
}
1;
