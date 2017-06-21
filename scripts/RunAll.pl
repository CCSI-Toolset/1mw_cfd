#!/usr/bin/env perl
for $i (1..351)
{
  $case="Case".sprintf("%.3d", $i);
  $Rcase="RCase".sprintf("%.3d", $i);
  print "Run $case\n";
  `cd $case; sbatch $Rcase`;
}
