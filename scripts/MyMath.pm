#!/usr/bin/env perl
package MyMath;
use Util;
use POSIX;

sub FindInterpolation
{
  my ($xCoord, $array, $j1, $j2, $c1, $c2) = @_;
  #this line is necessary if we want to get data from sub caller
  my @xCoords=@$array;

  $dx1=0.0;
  $dx=0.0;
#also allow exporlation if x is not too far off from x0
  if($xCoord <= $xCoords[0])
  {
	$i1=0;
	$i2=1;
        $dx1=$xCoords[$i2]-$xCoords[$i1];
        $dx=$xCoords[$i2]-$xCoord;
	if($dx > (2.0*$dx1))
	{
        	print "X coordinate ", $xCoord, " is negative way beyond the range (", $xCoords[0], ", ", $xCoords[$#xCoords], ")\n";
	}
  }
  elsif($xCoord >= $xCoords[$#xCoords])
  {
	$i1=$#xCoords-1;
	$i2=$#xCoords;
        $dx1=$xCoords[$i2]-$xCoords[$i1];
        $dx=$xCoords[$i2]-$xCoord; #this is negative
	if(-$dx > $dx1)
	{
        	print "X coordinate ", $xCoord, " is positive way beyond the range (", $xCoords[0], ", ", $xCoords[$#xCoords], ")\n";
	}
  }
  else
  {
        for $i (1..$#xCoords)
        {
                if($xCoord<=$xCoords[$i])
                {
                        $i1=$i-1;
                        $i2=$i;
                        last;
                }
        }
  }
  $cx1=($xCoords[$i2]-$xCoord)/($xCoords[$i2]-$xCoords[$i1]);
  $cx2=1.0-$cx1;
  #It is necessary to deferencing them to assign values to $avg and $stdev
  $$j1=$i1;
  $$c1=$cx1;
  $$j2=$i2;
  $$c2=$cx2;
}

sub GetStatistics
{
  my ($avg, $stdev, $array, $beg, $end) = @_;
  #this line is necessary if we want to get data from sub caller
  my @values=@$array;

  $count=$#values+1;
  #print "Array has ",$#values+1, " data\n"; 
  if($count<1)
  {
	die "GetStatistics(), array size 0\n";
  }
  #print "from $beg to $end\n";
  if($beg<0)
  {
	print "$beg is less than 0, set to 0\n";
	$beg=0;
  }
  if($end==0)
  {
	$end=$#values;
  }
  if($end>$#values)
  {
	print "$end reaches beyond the end of array, set to $#values\n";
	$end=$#values;
  }
  $count=$end-$beg+1.0;
  $average=0;
  $count2=0;
  for $i ($beg..$end)
  {
	$var=$values[$i];
	$average+=$var;
#	print $var, "\n";
  }
  $average=$average/$count;
  $variance=0;
  for $i ($beg..$end)
  {
	$var=$values[$i];
	$diff=$var-$average;
	$variance+=$diff*$diff;
  }
 
  $variance=$variance/($count+1.0);
  $variance=sqrt($variance);

  #It is necessary to deferencing them to assign values to $avg and $stdev
  $$avg=$average;
  $$stdev=$variance;
}
1;
