#!/usr/bin/env perl
package PostMfix;
use Util;
use POSIX;
#Read a post_mfix output
# and populate a few variables???
#INPUT:
#	$file:	file name, the output file from post_mfix
#Assumption on input file format:
#  The file should have data for X,Y,Z coordinates and one variable, e.g.,
#      Time = 105.00
#     X		Y	Z       EP_g
#   0.123     0.456	1.2	0.78
#   ..............
#OUTPUT ?:
#current users:
#PrintVariableAtTime()
sub ReadFile
{
  my ($file,$conditions) = @_;
  $xMaxCondition=0; #There is x<xConditionMax condition
  $xMinCondition=0;
  $yMaxCondition=0;
  $yMinCondition=0;
  $zMaxCondition=0;
  $zMinCondition=0;
  my(@criterias);
  if($conditions eq "")
  {
	print "There is no condition on X, Y, or Z, take all values\n";
  }
  else
  {
	$conditions=uc($conditions);
	@criterias=split(";", $conditions);
	for $i (0..$#criterias)
	{
		if(($criterias[$i] =~ "X") and $criterias[$i] =~ ">")
		{
			$xMinCondition=1;
			($dummy, $xConditionMin)=split(">",$criterias[$i]);
		}
		elsif(($criterias[$i] =~ "X") and $criterias[$i] =~ "<")
		{
			$xMaxCondition=1;
			($dummy, $xConditionMax)=split("<",$criterias[$i]);
		}
		if(($criterias[$i] =~ "Y") and $criterias[$i] =~ ">")
		{
			$yMinCondition=1;
			($dummy, $yConditionMin)=split(">",$criterias[$i]);
		}
		elsif(($criterias[$i] =~ "Y") and $criterias[$i] =~ "<")
		{
			$yMaxCondition=1;
			($dummy, $yConditionMax)=split("<",$criterias[$i]);
		}
		if(($criterias[$i] =~ "Z") and $criterias[$i] =~ ">")
		{
			$zMinCondition=1;
			($dummy, $zConditionMin)=split(">",$criterias[$i]);
		}
		elsif(($criterias[$i] =~ "Z") and $criterias[$i] =~ "<")
		{
			$zMaxCondition=1;
			($dummy, $zConditionMax)=split("<",$criterias[$i]);
		}
	}
  }
  if($xMinCondition==1)
  {
	print "Condition X > ", $xConditionMin, "\n";
  }
  if($xMaxCondition==1)
  {
	print "Condition X < ", $xConditionMax, "\n";
  }
  if($yMinCondition==1)
  {
	print "Condition Y > ", $yConditionMin, "\n";
  }
  if($yMaxCondition==1)
  {
	print "Condition Y < ", $yConditionMax, "\n";
  }
  if($zMinCondition==1)
  {
	print "Condition Z > ", $zConditionMin, "\n";
  }
  if($zMaxCondition==1)
  {
	print "Condition Z < ", $zConditionMax, "\n";
  }
  #my ($file, $var1Name, $var2Name, $array0, $array1) = @_;
  my(@xCoords, @yCoords,@zCoords);

  #print "File=", $file, "\n";
  #these two lines are necessary if we want to get data from sub caller 
  #my @coords=@$array0;
  #my @values=@$array1;

  $vMax=-1.0e20;
  $vMin=1.0e20;

  my @values;
  $file=$_[0];
  #print "File=", $file, "\n";
  if(-f $file) {
   open(FILEIN, $file);
   $fileout=$file."new";
   open(FILEOUT, ">$fileout");
   open(DEBUGOUT, ">/tmp/kevinlai.debug");
   $dataStart=0; #the first "Time ="
   $dataStart2=0; #after dataStart=1, no more "Time ="
   $index=0;
   while (<FILEIN>) {
	chop($_); #delete the ending \n
	$_ =~ s/^\s+|\s+$//g; #delete all starting white space
	if($_ =~ /Time =/)
	{
		$dataStart=1;
		#print $_, ":::dataStart set to 1\n";
	}
	elsif(($dataStart == 1) and ($dataStart2 != 1))
	{
		if($_ !~ /Time =/)
		{
			#print $_, ":::dataStarti2 set to 1\n";
			$dataStart2=1;
			#not yet, need to get "Species=2" for varName
			($coordName1,$coordName2, $coordName3,$varName)=split(/\s+/,$_);
			print FILEOUT $_,"\n";
			#It is necessary to deferencing them to assign values to $var1Name and $var2Name
			$$var1Name=$coordName;
			$$var2Name=$varName;
		}
	}
	elsif($dataStart2 == 1)
	{
		($x,$y,$z,$v)=split(/\s+/,$_);
		if($v<1.0e20 and $v>-1.0e20)
		{
			InsertCoord($x,\@xCoords);
			InsertCoord($y,\@yCoords);
			InsertCoord($z,\@zCoords);
			print FILEOUT $x,"\t",$y,"\t",$z,"\t",$v,"\n";
			$vMax=($vMax<$v)? $v : $vMax;
			$vMin=($vMin>$v)? $v : $vMin;
		}
	}
   }
 }
 close(FILEIN);
 close(FILEOUT);
 #print "X Coordinates: ", $#xCoords, ":\n";
 #for $i (0..$#xCoords)
 #{
#	print "\t",$xCoords[$i],"\n";
 #}
 #print "Y Coordinates: ", $#yCoords, ":\n";
 #for $i (0..$#yCoords)
# {
#	print "\t",$yCoords[$i],"\n";
# }
# print "Z Coordinates: ", $#zCoords, ":\n";
# for $i (0..$#zCoords)
# {
#	print "\t",$zCoords[$i],"\n";
# }
# print "Variable Maximum value: ", $vMax;
# print "\t Minimum value: ", $vMin, "\n";
 my(@variables); 
 for $I (0..$#xCoords)
 {
    for $J (0..$#yCoords)
    {
    	for $K (0..$#zCoords)
    	{
		$variables[$I][$J][$K]=$vMax*1.1+100;
	}
    }
 }

 $Count=0;
 open(FILEIN, $fileout);
 while (<FILEIN>) {
	chop($_); #delete the ending \n
	($x,$y,$z,$v)=split(/\s+/,$_);
	$I=GetCoordIndex($x,\@xCoords);	
	$J=GetCoordIndex($y,\@yCoords);	
	$K=GetCoordIndex($z,\@zCoords);	
	if($I>=0 and $J>=0 and $K>=0)
	{
 		$Count++;
		$variables[$I][$J][$K]=$v;
	}
	#print "(", $I,",",$J, ",",$K,")=",$variables[$I][$J][$K], "\n";
 }
 close(FILEIN);
#Find variable vs. X
my (@VAvg_X, @VAvg_Y,@VAvg_Z);
#X vs. variable
for $i (0 .. $#xCoords)
{
        $VAvg_X[$i]=$vMax*1.1+100;
}

print DEBUGOUT "Total valid count $Count\n";
print DEBUGOUT "printing variable vs. X\n"; 
for $i (0 .. $#xCoords)
{
	print DEBUGOUT "x = ", $xCoords[$i],"\n"; 
        $TotalValue=0;
        $Count=0;
    	for $j (0 .. $#yCoords)
        {
    		for $k (0 .. $#zCoords)
                {
                        if($variables[$i][$j][$k]<=$vMax)
                        {
				print DEBUGOUT "($i,$j,$k)=$variables[$i][$j][$k]\n";
				#default: all
				$pickThis=1;
				#condition clause might have x>, x<, y>, y<, z>, and z< conditions
  				if($xMinCondition==1 && ($xCoords[$i]<$xConditionMin))
				{
					print DEBUGOUT "skip because of xMin\n";
					$pickThis = 0;
				}
  				if($xMaxCondition==1 && ($xCoords[$i]>$xConditionMax))
				{
					print DEBUGOUT "skip because of xMax\n";
					$pickThis = 0;
				}
  				if($yMinCondition==1 && ($yCoords[$j]<$yConditionMin))
				{
					print DEBUGOUT "skip because of yMin $yConditionMin\n";
					$pickThis = 0;
				}
  				if($yMaxCondition==1 && ($yCoords[$j]>$yConditionMax))
				{
					print DEBUGOUT "skip because of yMax\n";
					$pickThis = 0;
				}
  				if($zMinCondition==1 && ($zCoords[$k]<$zConditionMin))
				{
					print DEBUGOUT "skip because of zMin\n";
					$pickThis = 0;
				}
  				if($zMaxCondition==1 && ($zCoords[$k]>$zConditionMax))
				{
					print DEBUGOUT "skip because of zMax\n";
					$pickThis = 0;
				}

				#only when all satisfied, $pickThis remains 1
				if($pickThis==1)
				{
                                	$TotalValue+=$variables[$i][$j][$k];
                                	$Count++;
				}
                        }
                }
        }
	if($Count>0)
	{
       		$VAvg_X[$i]=$TotalValue/$Count;
	}

	
	print DEBUGOUT " count ", $Count, "\n"; 
}
print " value vs. X, averaging over Y and Z:\n";
for $i (0 .. $#xCoords)
{
	if($VAvg_X[$i]<$vMax)
	{
		print $xCoords[$i], "\t", $VAvg_X[$i],"\n";
	}
}
	
#Y vs. variable
print DEBUGOUT "printing variable vs. Y\n"; 
for $i (0 .. $#yCoords)
{
        $VAvg_Y[$i]=$vMax*1.1+100;
}

for $j (0 .. $#yCoords)
{
	print DEBUGOUT "y = ", $yCoords[$j]; 
        $TotalValue=0;
        $Count=0;
    	for $i (0 .. $#xCoords)
        {
    		for $k (0 .. $#zCoords)
                {
			#pick anything that is not infinity
                        if($variables[$i][$j][$k]<=$vMax)
                        {
				#default: all
				$pickThis=1;
				#condition clause might have x>, x<, y>, y<, z>, and z< conditions
  				if($xMinCondition==1 && ($xCoords[$i]<$xConditionMin))
				{
					$pickThis = 0;
				}
  				if($xMaxCondition==1 && ($xCoords[$i]>$xConditionMax))
				{
					$pickThis = 0;
				}
  				if($yMinCondition==1 && ($yCoords[$j]<$yConditionMin))
				{
					$pickThis = 0;
				}
  				if($yMaxCondition==1 && ($yCoords[$j]>$yConditionMax))
				{
					$pickThis = 0;
				}
  				if($zMinCondition==1 && ($zCoords[$k]<$zConditionMin))
				{
					$pickThis = 0;
				}
  				if($zMaxCondition==1 && ($zCoords[$k]>$zConditionMax))
				{
					$pickThis = 0;
				}

				#only when all satisfied, $pickThis remains 1
				if($pickThis==1)
				{
                                	$TotalValue+=$variables[$i][$j][$k];
                                	$Count++;
				}
                        }
                }
        }
	print DEBUGOUT " count ", $Count, "\n"; 
	if($Count>0)
	{
       		$VAvg_Y[$j]=$TotalValue/$Count;
	}
}
print " value vs. Y, averaging over X and Z:\n";
print DEBUGOUT "printing variable vs. Z\n"; 
for $i (0 .. $#yCoords)
{
	if($VAvg_Y[$i]<$vMax)
	{
		print $yCoords[$i], "\t", $VAvg_Y[$i],"\n";
	}
}
	
#Z vs. variable
for $i (0 .. $#zCoords)
{
        $VAvg_Z[$i]=$vMax*1.1+100;
}

for $k (0 .. $#zCoords)
{
        $TotalValue=0;
        $Count=0;
    	for $i (0 .. $#xCoords)
        {
		for $j (0 .. $#yCoords)
                {
                        if($variables[$i][$j][$k]<=$vMax)
                        {
				#default: all
				$pickThis=1;
				#condition clause might have x>, x<, y>, y<, z>, and z< conditions
  				if($xMinCondition==1 && ($xCoords[$i]<$xConditionMin))
				{
					$pickThis = 0;
				}
  				if($xMaxCondition==1 && ($xCoords[$i]>$xConditionMax))
				{
					$pickThis = 0;
				}
  				if($yMinCondition==1 && ($yCoords[$j]<$yConditionMin))
				{
					$pickThis = 0;
				}
  				if($yMaxCondition==1 && ($yCoords[$j]>$yConditionMax))
				{
					$pickThis = 0;
				}
  				if($zMinCondition==1 && ($zCoords[$k]<$zConditionMin))
				{
					$pickThis = 0;
				}
  				if($zMaxCondition==1 && ($zCoords[$k]>$zConditionMax))
				{
					$pickThis = 0;
				}

				#only when all satisfied, $pickThis remains 1
				if($pickThis==1)
				{
                                	$TotalValue+=$variables[$i][$j][$k];
                                	$Count++;
				}
                        }
                }
        }
	if($Count>0)
	{
       		$VAvg_Z[$k]=$TotalValue/$Count;
	}
}
print " value vs. Z, averaging over X and Y:\n";
for $i (0 .. $#zCoords)
{
	if($VAvg_Z[$i]<$vMax)
	{
		print $zCoords[$i], "\t", $VAvg_Z[$i],"\n";
	}
}
	
 close(DEBUGOUT);
 return @values; 
} #ReadFile()

sub GetCoordIndex
{
  $index=-1;
  my ($x, $array) = @_;
#  if($x ne $x+0) this DOES NOT work
#  {
#	print " return here because $x x!=x\n";
#	$index;
#	return;
#  }
  my @coords=@$array;
  if($x < $coords[0])
  {
  	$index=-1;
	return;
  }
  if($x > $coords[$#coords])
  {
  	$index=-1;
	return;
  }
  for $i (0..$#coords)
  {
	if($x==$coords[$i])
	{
		$index=$i;
		last;
	}
  }
 $index;
}

sub InsertCoord
{
  my ($x, $array0) = @_;
  #these two lines are necessary if we want to get data from sub caller 
  my @coords=@$array0;
  if($#coords<0)
  {
	#print "Insert the first one: ", $x, "\n";
	$coords[0]=$x;
  }
  elsif($x>$coords[$#coords])
  {
	#print "Insert at the end: ", $x, "\n";
	$coords[$#coords+1]=$x;
  }
  else
  {
	#print "Already has ", $#coords+1, "\n";
	$curLast=$#coords;
  	for $i (0 .. $curLast)
  	{
		if($x < $coords[$i])
		{
			for ($j=$curLast;$j>=$i;$j--)
			{
				$coords[$j+1]=$coords[$j];
				#print "moving to ", $j+1, ":", $coords[$j], " from ", $j, "\n";
			}
			$coords[$i]=$x;
			#print "Insert at ", $i, ": ", $x, "\n";
			last;
		}
		elsif($x == $coords[$i])
		{
			#print "duplicate, do not insert\n";
			last;
		}
	}
  }
 #this line is for passing the local arrays back to caller
 @$array0=@coords;
}

#Read a post_mfix output and populate a few variables
#INPUT:
#	$file:	file name, the output file from post_mfix
#Assumption on input file format:
#  The file should have data for only one coordinate and one variable, e.g.,
#      Time = 105.00
#     Y       EP_g
#   0.123     0.456
#   ..............
#OUTPUT:
#	var1Name
#	var2Name
#	array0:		values of coordinate
#	array1:		values of the variable
sub ReadFile2
{
  my ($file, $var1Name, $var2Name, $array0, $array1) = @_;
  #print "File=", $file, "\n";
  #these two lines are necessary if we want to get data from sub caller 
  #my @coords=@$array0;
  #my @values=@$array1;

  my @coords;
  my @values;
  $file=$_[0];
  #print "File=", $file, "\n";
  if(-f $file) {
   open(FILEIN, $file);
   $dataStart=0; #the first "Time ="
   $dataStart2=0; #after dataStart=1, no more "Time ="
   $index=0;
   while (<FILEIN>) {
	chop($_); #delete the ending \n
	$_ =~ s/^\s+|\s+$//g; #delete all starting white space
	if($_ =~ /=/)
	{
		$dataStart=1;
		#print $_, ":::dataStart set to 1\n";
	}
	elsif(($dataStart == 1) and ($dataStart2 != 1))
	{
		if($_ !~ /=/)
		{
			#print $_, ":::dataStarti2 set to 1\n";
			$dataStart2=1;
			#not yet, need to get "Species=2" for varName
			($coordName,$varName)=split(/\s+/,$_);
			#It is necessary to deferencing them to assign values to $var1Name and $var2Name
			$$var1Name=$coordName;
			$$var2Name=$varName;
			#my @vars=split(/\s+/,$_);
			#foreach my $var(@vars)
			#{
			#	print $var,"\n";
			#}
			#print "coord=", $coordName, " variable=", $varName, "\n";
		}
	}
	elsif($dataStart2 == 1)
	{
		($coords[$index],$values[$index])=split(/\s+/,$_);
		$index++;
		#print "Starting data\n";
	}
   }
   #print "number: ", $#Xcoords,"\n";
   #for $index (0 .. $#coords)
   #{
	#print $coords[$index], " - ", $values[$index],"\n";
   #}
   close(FILEIN);
 }
 else
 {
 	print "$file does not exist\n";
 }
 #these two lines are for pass the local arrays back to caller
 @$array0=@coords;
 @$array1=@values;
 return @values; 
}

#Used in conjunction with e.g., PostMfix::BuildPostMfixVarAtYTopT12
#The file should have the following format
# Y = 1.003
# Z = -3.134
#Time = 0.000
#   X    V_g
# 0.12	0.01
# 0.16  0.05
# ......
#Time = 1.002
#   X    V_g
# 0.12	0.03
# 0.16  0.06
# ......
sub ReadFileTimedCoordAndValue
{
  my ($file, $var1Name, $var2Name, $arrayT, $array0, $array1) = @_;
  #print "File=", $file, "\n";
  #these two lines are necessary if we want to get data from sub caller 
  #my @coords=@$array0;
  #my @values=@$array1;

  my @coords;
  my @values;
  my @times;
  $file=$_[0];
  #print "File=", $file, "\n";
  if(-f $file) {
   open(FILEIN, $file);
   $dataStart=0; #the first "Time ="
   $dataStart2=0; #after dataStart=1, no more "Time ="
   $index=0;
   $t=-1; #so the first one after $t++ will be 0
   while (<FILEIN>) {
	chop($_); #delete the ending \n
	$_ =~ s/^\s+|\s+$//g; #delete all starting white space
	if($_ =~ /Time/)
	{
		$dataStart=1;
		$t++;
		($dummy,$times[$t])=split(/\s+=/,$_);
   		$index=0;
   		$dataStart2=0;
		#print $_, ":::dataStart set to 1\n";
	}
	elsif(($dataStart == 1) and ($dataStart2 != 1))
	{
		if($_ !~ /=/)
		{
			#print $_, ":::dataStarti2 set to 1\n";
			$dataStart2=1;
			#not yet, need to get "Species=2" for varName
			($coordName,$varName)=split(/\s+/,$_);
			#It is necessary to deferencing them to assign values to $var1Name and $var2Name
			$$var1Name=$coordName;
			$$var2Name=$varName;
			#my @vars=split(/\s+/,$_);
			#foreach my $var(@vars)
			#{
			#	print $var,"\n";
			#}
			#print "coord=", $coordName, " variable=", $varName, "\n";
		}
	}
	elsif($dataStart2 == 1)
	{
		($coords[$index],$values[$t][$index])=split(/\s+/,$_);
		$index++;
		#print "Starting data\n";
	}
   }
   #print "number: ", $#Xcoords,"\n";
   #for $index (0 .. $#coords)
   #{
	#print $coords[$index], " - ", $values[$index],"\n";
   #}
 }
 close(FILEIN);
 #these two lines are for pass the local arrays back to caller
 @$arrayT=@times;
 @$array0=@coords;
 @$array1=@values;
 return @values; 
}

#compare two output files from post_mfix
sub Compare2Data
{
  my ($array11, $array12, $array21, $array22) = @_;
  #print "File=", $file, "\n";
  #these two lines are necessary if we want to get data from sub caller 
  my @coords1=@$array11;
  my @values1=@$array12;
  my @coords2=@$array21;
  my @values2=@$array22;
  #some sanity check
  if($#coords1 != $#coords2)
  {
 	print "Compare2Data, size different, linear interpolation or expolation applied for comparison\n";
	Compare2DiffSizedData(\@coords1, \@values1, \@coords2, \@values2);
	return;
  }
  $size=$#coords1+1;
  print "Compare2Data, size ", $size, "\n\n";

  #make sure two data have the same coordinates
  $sameCoords=1;
  for $index (0 .. $#coords1)
  {
	if($coords1[$index] != $coords2[$index])
	{
  		$sameCoords=0;
		last;
	}
  }
  if($sameCoords==0)
  {
 	print "Compare2Data, coordinates different, linear interpolation or expolation applied for comparison\n";
	Compare2DiffSizedData(\@coords1, \@values1, \@coords2, \@values2);
	return;
  }

  my(@diff, @diffRatio,@diffRatioNormal);
  $MaxValue=-1.0e10;
  $MinValue=1.0e10;
  $diffMax=0.0;
  $MaxIndex=0;

  $diffRatioMax=0.0;
  $RatioMaxIndex=0;
  $SumDiffSquare=0.0;
  #print "Compare two data\n";
  print "Coord\t        Value1\t        Value2\t        Difference\tDiff ratio\tNormalized Diff\n";
  for $index (0 .. $#coords1)
  {
	$MaxValue=($values1[$index]>$MaxValue) ? $values1[$index] : $MaxValue;
	$MinValue=($values1[$index]<$MinValue) ? $values1[$index] : $MinValue;
	$diff[$index]=abs($values1[$index]-$values2[$index]);
  	$SumDiffSquare+=($diff[$index]*$diff[$index]);
	if($diffMax < $diff[$index])
	{
		$diffMax=$diff[$index];
  		$MaxIndex=$index;
	}
	$diffRatio[$index]=0;
	if($values1[$index]!=0)
	{
		$diffRatio[$index]=$diff[$index]/abs($values1[$index]);
		if($diffRatioMax < $diffRatio[$index])
		{
			$diffRatioMax=$diffRatio[$index];
  			$RatioMaxIndex=$index;
		}
	} 
  }
#diffRatio might be too skewed if values are small
  $AvergDiffSquare=$SumDiffSquare/($#coords1+1.0);
  $AvergDiff=sqrt($AvergDiffSquare); 
  $Delta=$MaxValue-$MinValue;
  $MediumValue=0.5*abs($MaxValue+$MinValue);
  $Normalizer=($Delta>$MediumValue) ? $Delta : $MediumValue;
  $AvergDiffRatio=$AvergDiff/$Normalizer; 
  $TotalDiffRatio=0;
  $MaxDiffRatioNormal=0;
  for $index (0 .. $#coords1)
  {
	$diffRatioNormal[$index]=abs($values1[$index]-$values2[$index])/$Normalizer;
	$MaxDiffRatioNormal=($MaxDiffRatioNormal > $diffRatioNormal[$index]) ? $MaxDiffRatioNormal : $diffRatioNormal[$index];
  	$TotalDiffRatio+=$diffRatioNormal[$index];
	print sprintf("%.4e",$coords1[$index]), "\t", sprintf("%.4e",$values1[$index]), "\t", sprintf("%.4e",$values2[$index]), "\t";
	print sprintf("%.4e",$diff[$index]), "\t", sprintf("%.4e",$diffRatio[$index]),"\t";
	print sprintf("%.4e",$diffRatioNormal[$index]),"\n";
  }
  $TotalDiffRatio=$TotalDiffRatio/($#coords1+1.0);
  print "Comparison summary:\n";
  print "\tCoordinates:\t(", $coords1[0], ",",$coords1[$#coords1],")\n";
  print "\tVariable:\t(", $MinValue, ",",$MaxValue,")\n";

  print "\tMaximum difference:\t";
  print $diff[$MaxIndex], " or ratio ", sprintf("%.4f",$diffRatio[$MaxIndex]*100), "% at ";
  print $coords1[$MaxIndex], " Values ", $values1[$MaxIndex], " vs. ",  $values2[$MaxIndex], "\n";  

  print "\tMaximum diff ratio:\t";
  print $diff[$RatioMaxIndex], " or ratio ", sprintf("%.4f",$diffRatio[$RatioMaxIndex]*100), "% at ";
  print $coords1[$RatioMaxIndex], " Values ", $values1[$RatioMaxIndex], " vs. ",  $values2[$RatioMaxIndex], "\n";  

  print "\tMaximum Normalized different ratio:\t",sprintf("%.4f",$MaxDiffRatioNormal*100),"%\n";
  print "\tAveraged Normalized different ratio:\t",sprintf("%.4f",$TotalDiffRatio*100),"%\n";
  print "\tSqureroot (Delta square): \t",sprintf("%.4f",$AvergDiff),sprintf("\tNormalized %.4f",$AvergDiffRatio*100),"%\n\n";
  $MaxDiffRatioNormal;
}

#compare two output files from post_mfix with different size
sub Compare2DiffSizedData
{
  my ($array11, $array12, $array21, $array22) = @_;
  #print "File=", $file, "\n";
  #these two lines are necessary if we want to get data from sub caller 
  my @coords1=@$array11;
  my @values1=@$array12;
  my @coords2=@$array21;
  my @values2=@$array22;
  #some sanity check
  $size1=$#coords1+1;
  $size2=$#coords2+1;
  if($#coords1 > $#coords2)
  {
 	print "First data has larger size ", $size1, " than the second ", $size2, "\n";
  }
  else
  {
 	print "First data has smaller size ", $size1, " than the second ", $size2, "\n";
  }
#check they have about the same coordinate range
  $range1=$coords1[$size1-1]-$coords1[0];
  $range2=$coords2[$size2-1]-$coords2[0];
  if($range1 > 1.1*$range2 or $range1 < 0.9*$range2) 
  {
	print "Ranges for two data are very different: ", $range1, " vs. ", $range2, " Quit comparision\n";
	return;
  }
  print "\n";
  #first 1st coordinates
  my(@diff, @diffRatio);
  $diffMax=0.0;
  $diffRatioMax=0.0;
  print "Compare two data in the first data coordinates\n";
  print "Coord\t        Value1\t        Value2\t        Difference\tDiff ratio\n";
  for $index (0 .. $#coords1)
  {
	$value2=GetInterpolationValue(\@coords2, \@values2, $coords1[$index]);
	$diff[$index]=abs($values1[$index]-$value2);
	$diffMax=$diffMax > $diff[$index] ? $diffMax : $diff[$index];
	$diffRatio[$index]=0;
	if($values1[$index]!=0)
	{
		$diffRatio[$index]=$diff[$index]/abs($values1[$index]);
		#print $coords1[$index], "\t", $values1[$index], "\t", $values2[$index], "\t", $diff[$index], "\t", $diffRatio[$index],"\n";
		print sprintf("%.4e",$coords1[$index]), "\t", sprintf("%.4e",$values1[$index]), "\t", sprintf("%.4e",$value2), "\t";
		print sprintf("%.4e",$diff[$index]), "\t", sprintf("%.4e",$diffRatio[$index]),"\n";
	} 
	$diffRatioMax=$diffRatioMax > $diffRatio[$index] ? $diffRatioMax : $diffRatio[$index];
  }
  print "Comparison summary:\n";
  print "\tMaximum difference: ", $diffMax, "\n";  
  print "\tMaximum difference ratio: ", sprintf("%.4f",$diffRatioMax*100), "%\n";  

  #2nd coordinates
  $diffMax=0.0;
  $diffRatioMax=0.0;
  print "\nCompare two data in the second data coordinates\n";
  print "Coord\t        Value1\t        Value2\t        Difference\tDiff ratio\n";
  for $index (0 .. $#coords2)
  {
	$value1=GetInterpolationValue(\@coords1, \@values1, $coords2[$index]);
	$diff[$index]=abs($values2[$index]-$value1);
	$diffMax=$diffMax > $diff[$index] ? $diffMax : $diff[$index];
	$diffRatio[$index]=0;
	if($values1[$index]!=0)
	{
		$diffRatio[$index]=$diff[$index]/abs($values1[$index]);
		#print $coords1[$index], "\t", $values1[$index], "\t", $values2[$index], "\t", $diff[$index], "\t", $diffRatio[$index],"\n";
		print sprintf("%.4e",$coords2[$index]), "\t", sprintf("%.4e",$value1), "\t", sprintf("%.4e",$values2[$index]), "\t";
		print sprintf("%.4e",$diff[$index]), "\t", sprintf("%.4e",$diffRatio[$index]),"\n";
	} 
	$diffRatioMax=$diffRatioMax > $diffRatio[$index] ? $diffRatioMax : $diffRatio[$index];
  }
  print "Comparison summary:\n";
  print "\tMaximum difference: ", $diffMax, "\n";  
  print "\tMaximum difference ratio: ", sprintf("%.4f",$diffRatioMax*100), "%\n";  
  $diffRatioMax;
}

#return a value for a given coordinate $coord, from array pair @coords, @values
sub GetInterpolationValue
{
  my ($array1, $array2, $coord) = @_;
  my @coords=@$array1;
  my @values=@$array2;
  $size=$#coords+1;
  $i1=$size-2;
  $i2=$size-1;
  for $index (0 .. $#coords)
  {
     if($coord == $coords[$index])
     {
	return $values[$index];
     }
  }

  for $index (0 .. $#coords)
  {
     if($coord < $coords[$index])
     {
	if($index>0)
	{
		$i1=$index-1;
		$i2=$index;
	}
	else #expolation
	{
		$i1=$index;
		$i2=$index+1;
	}
	last;
     }
  }
  $dv=$values[$i2]-$values[$i1];
  $dc=$coords[$i2]-$coords[$i1];
  if($dc==0)
  {
	print "ERROR: i1=", $i1, " and i2=", $i2, " dv=", $dv, "\n";
	print "coords size=", $#coords+1, "\n";
	print "coord=", $coord, " coord1=", $coords[$i1], " coord2=", $coords[$i2], "\n";
	return $values[$i1];
  }
  $value=$values[$i1]+$dv/$dc*($coord-$coords[$i1]);
  return $value;
}
  #print "File=", $file, "\n";
#provide a simulation name, search for its name.LOG file, and find the last t= value
sub GetMaxTime
{
  my ($name) = @_;
  $logfile=$name . ".LOG";
  $result = `egrep "t=" $logfile | egrep "Wrote RES" | tail -1`;
  $result2=substr($result,index($result,"t=")+2);
  $result2=Util::trim($result2);
  ($time,$rest)=split(/\s+/,$result2);

  #print "Time=",$time,"END\n";
  return floor($time);
}

sub GetMfixExpressionValue
{
  $value=0;
  my ($expression) = @_;
  if($expression =~ /@/)
  {
    $r1=index($expression,"\(");
    $r2=index($expression,"\)");
    $expression=substr($expression,$r1+1,$r2-$r1-1);
    $expression =~ s/\*/t/g;
    $expression =~ s/\//d/g;

    #print "New expression string is $expression \n"; 
    $value=GetValue($expression);
  }
  else
  {
     print "$expression is not a valid expression\n";
  } 
  $value;
}
#evaluate an expression with only * and /, will not take + and -?
sub GetValue
{
  my ($expression) = @_;
  #print "GetValue on $expression \n";
  my @values = split(/[dt]+/, $expression);
  #print "There are $#values+1 values\n";
  $value=$values[0];
  for $i (1..$#values)
  {
	#print $values[$i], ", ";
  	$ot=index($expression,"t");
  	$od=index($expression,"d");
	if($ot<0 and $od<0)
        {
		print "no more, should not happen\n";
		last;
	}
  	elsif($ot>0 and ($ot<$od or $od<0))
	{
		#print "$value times $values[$i] = ";
		$value*=$values[$i];
		$expression=substr($expression,$ot+1);
		#print "$value\n";
		#print "new expression $expression\n";
	}
  	elsif($od>0 and ($od<$ot or $ot<0))
	{
		#print "$value divided $values[$i] = ";
		$value/=$values[$i];
		$expression=substr($expression,$od+1);
		#print "$value\n";
		#print "new expression $expression\n";
	}
  }
  $value;
}

#Populate the following from the mfix.dat
#RUNNAME
#IMAX
#JMAX
#KMAX
sub GetInfoFromMfixInput
{
  my ($mfixInput,$RUNNAME, $IMAX, $JMAX, $KMAX) = @_;
  $kmax=1; #KMAX default is 1, if not defined, it is a 2D model
#Get runname from mfixinput file
  open(FILEIN, $mfixInput);
  while (<FILEIN>) {
	if($_ =~ /^#/)
	{
		next;
	}
	if($_ =~ /^!/)
	{
		next;
	}
	chop($_); #delete the ending \n
	$line=uc($_);
	if($line =~ /RUN_NAME/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($dummy,$runname,$dummy2)=split(/'/,$line);
		#print "runname $runname\n";
	}
	elsif($line =~ /IMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($imax,$dummy2)=split(/\s+/,$line);
		#print "imax $imax\n";
	}
	elsif($line =~ /JMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($jmax,$dummy2)=split(/\s+/,$line);
		#print "jmax $jmax\n";
	}
	elsif($line =~ /KMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($kmax,$dummy2)=split(/\s+/,$line);
		#print "kmax $kmax\n";
	}
  }
#It is necessary to deferencing them to assign values to $RUNNAME etc.
  $$RUNNAME=$runname;
  $$IMAX=$imax;
  $$JMAX=$jmax;
  $$KMAX=$kmax;
  close(FILEIN);
}

sub GetVariableFromMfixInput
{
  my ($mfixInput, $variable) = @_;
#Get runname from mfixinput file
  open(FILEIN, $mfixInput);
  while (<FILEIN>) {
	if($_ =~ /^#/)
	{
		next;
	}
	if($_ =~ /^!/)
	{
		next;
	}
	chop($_); #delete the ending \n
	$line=uc($_);
	if($line =~ /$variable/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		$runname=$line;
		last;
	}
  }
  close(FILEIN);
  $runname;
}

sub GetRunNameFromMfixInput
{
  my ($mfixInput) = @_;
#Get runname from mfixinput file
  open(FILEIN, $mfixInput);
  while (<FILEIN>) {
	if($_ =~ /^#/)
	{
		next;
	}
	if($_ =~ /^!/)
	{
		next;
	}
	chop($_); #delete the ending \n
	$line=uc($_);
	if($line =~ /RUN_NAME/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		#print $line,"END\n";
		($dummy,$runname,$dummy2)=split(/'/,$line);
		#print $runname,"END\n";
		last;
	}
  }
  close(FILEIN);
  $runname;
}

sub GetMaxTimeFromMfixInput
{
  my ($mfixInput) = @_;
#Get runname from mfixinput file
  open(FILEIN, $mfixInput);
  while (<FILEIN>) {
	if($_ =~ /^#/)
	{
		next;
	}
	if($_ =~ /^!/)
	{
		next;
	}
	chop($_); #delete the ending \n
	$line=uc($_);
	if($line =~ /RUN_NAME/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		#print $line,"END\n";
		($dummy,$runname,$dummy2)=split(/'/,$line);
		#print $runname,"END\n";
		last;
	}
  }
  close(FILEIN);
  $logfile=$runname . ".LOG";
  if(-e $logfile)
  {
  }
  else
  {
    $logfile=$runname . "000.LOG";
  }
  $result = `egrep "t=" $logfile | egrep "Wrote RES" | tail -1`;
  $result2=substr($result,index($result,"t=")+2);
  $result2=Util::trim($result2);
  ($time,$rest)=split(/\s+/,$result2);
  if(floor($time)<1.0)
  {
	print "Warning: maximum runtime is less than 1 second: ", $time, "\n";
	print "result2=",$result2;
  }
  floor($time);
}
sub GetLogFileNameFromRunName
{
  my ($runname) = @_;
  $runname=uc($runname);
  $logfile=$runname . ".LOG";
  if(-e $logfile)
  {
  }
  else
  {
    $logfile=$runname . "000.LOG";
	if(-e $logfile)
	{
	}
	else
	{
		print "Neither ", $runname, ".LOG nor ", $logfile, " exists\n";
		$logfile="";
	}
  }
 $logfile;
}

#construct a post_mfix script
# to get the variable at y=top at given time
sub BuildPostMfixVarAtYBotT12
{
  my ($runname,$postmfixFile,$outputFile,$IMAX,$JMAX,$time1,$time2,$var,$index) = @_;
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nN\n"; 
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
  print FILEOUT "N\n";
  print FILEOUT "2,2\n";
  print FILEOUT "1,1\n";
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#construct a post_mfix script
# to get the variable at y=top at given time
sub BuildPostMfixVarAtYTopT12
{
  my ($runname,$postmfixFile,$outputFile,$IMAX,$JMAX,$time1,$time2,$var,$index) = @_;
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nN\n"; 
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
  print FILEOUT "N\n";
  print FILEOUT $JMAX+1,",",$JMAX+1,"\n";
  print FILEOUT "1,1\n";
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}
#construt a post_mfix script
#Inputs
#	mfix.dat:	the file contains run_name information
#	time:		300
#	var:		EP_g
#	index:		2 (optional)
# It creates a file for post_mfix, with naming convention:
#   ADSORBER_EP_g_Y_T300.get, to create an output from post_mfix
#   ADSORBER_EP_g_Y_T300.out
sub BuildPostMfixXYZInput
{
  `mkdir /scratch/kevinlai`;
  my ($mfixFile,$time,$var,$index) = @_;
  #print "mfixfile=", $mfixFile,"END\n";
  $KMAX=1; #default 1 for 2D
  if(not (-f $mfixFile))
  {
	print "MFIX input file ", $mfixFile, " DOES NOT exist\n";
 	return;
  }
  open(FILEIN, $mfixFile);
  while (<FILEIN>) {
	if($_ =~ /^#/)
	{
		next;
	}
	if($_ =~ /^!/)
	{
		next;
	}
	chop($_); #delete the ending \n
	$line=uc($_);
	if($line =~ /RUN_NAME/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($dummy,$runname,$dummy2)=split(/'/,$line);
		#print "RunName=", $runname,"END\n";
	}
	elsif($line =~ /IMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($IMAX,$dummy2)=split(/\s+/,$line);
	}
	elsif($line =~ /JMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($JMAX,$dummy2)=split(/\s+/,$line);
	}
	elsif($line =~ /KMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($KMAX,$dummy2)=split(/\s+/,$line);
	}
  }
  close(FILEIN);

  $postmfixFile="/scratch/kevinlai/".$runname ."_". $var . $index ."_T".$time.".get";
  #print "post_mfix script file=",$postmfixFile,"\n";
  $outputFile="/scratch/kevinlai/".$runname . "_". $var . $index ."_T".$time.".out";
  #print "post_mfix output file=",$outputFile,"\n"; 
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time,",",$time,"\n"; 
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
  print FILEOUT "N\n";
  print FILEOUT "2,",$JMAX+1,"\n";
  print FILEOUT "N\n";
  if($KMAX == 1)
  {
	print FILEOUT "1,1\n";
  }
  else
  {
  	print FILEOUT "2,",$KMAX+1,"\n";
	print FILEOUT "N\n";
  }
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#construt a post_mfix script
#Inputs
#	mfix.dat:	the file contains run_name information
#	time:		300
#	coord:		Y
#	var:		EP_g
#	index:		2 (optional)
# It creates a file for post_mfix, with naming convention:
#   ADSORBER_EP_g_Y_T300.get, to create an output from post_mfix
#   ADSORBER_EP_g_Y_T300.out
sub BuildPostMfixInput
{
  my ($mfixFile,$time,$coord,$var,$index) = @_;
  $coord = uc($coord);
  if(($coord ne "X") and ($coord ne "Y") and ($coord ne "Z"))
  {
    print "Coordinate must be X, or Y, or Z\n";
    return;
  }
  #print "mfixfile=", $mfixFile,"END\n";
  $KMAX=1; #default 1 for 2D
  open(FILEIN, $mfixFile);
  while (<FILEIN>) {
	if($_ =~ /^#/)
	{
		next;
	}
	if($_ =~ /^!/)
	{
		next;
	}
	chop($_); #delete the ending \n
	$line=uc($_);
	if($line =~ /RUN_NAME/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($dummy,$runname,$dummy2)=split(/'/,$line);
	}
	elsif($line =~ /IMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($IMAX,$dummy2)=split(/\s+/,$line);
	}
	elsif($line =~ /JMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($JMAX,$dummy2)=split(/\s+/,$line);
	}
	elsif($line =~ /KMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($KMAX,$dummy2)=split(/\s+/,$line);
	}
  }
  close(FILEIN);

  `mkdir /scratch/kevinlai`;
  $postmfixFile="/scratch/kevinlai/".$runname ."_". $var . $index ."_".$coord."_T".$time.".get";
  #print "post_mfix script file=",$postmfixFile,"\n";
  $outputFile="/scratch/kevinlai/".$runname . "_". $var . $index ."_".$coord."_T".$time.".out";
  #print "post_mfix output file=",$outputFile,"\n"; 
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time,",",$time,"\n"; 
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
  if($coord eq "X")
  {
	print FILEOUT "N\n";
  }
  else
  {
	print FILEOUT "Y\n";
  }
  print FILEOUT "2,",$JMAX+1,"\n";
  if($coord eq "Y")
  {
	print FILEOUT "N\n";
  }
  else
  {
	print FILEOUT "Y\n";
  }
  if($KMAX == 1)
  {
	print FILEOUT "1,1\n";
  }
  else
  {
  	print FILEOUT "2,",$KMAX+1,"\n";
  	if($coord eq "Z")
  	{
		print FILEOUT "N\n";
  	}
  	else
  	{
		print FILEOUT "Y\n";
  	}
  }
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

sub CheckSteadyStateAtTime
{
  my ($mfixFile,$AtTime,$coord,$var,$index) = @_;
  $maxTime=GetMaxTimeFromMfixInput($mfixFile);
  if($maxTime<5.0)
  {
	print "Total simulation time ", $maxTime, " is less than 5 seconds, insufficient to check for a steady state\n";
	return 100;
  }
  if($maxTime<$AtTime)
  {
	print "Total simulation time ", $maxTime, " is less than given time ", $AtTime," QUIT\n";
	return 100;
  }
  if($AtTime<0)
  {
	printf "Time ", $AtTime, " is negative, stop checking\n";
	return 100;
  }

#decide t1 and t2 for steady state comparison
  $t1=$AtTime-10;
  if($AtTime<10)
  {
	$t1=$AtTime/2.0;
  }

  ($sec,$min)=localtime();
  $user=`whoami`;
  chop($user);
  $filebase="/tmp/".$user.$min.$sec.int(rand(10));
  $file1=$filebase.".get";
  $file1out=$filebase.".out";
  BuildPostMfixInput2($mfixFile,$file1,$file1out,$t1,$coord,$var,$index);
  if(-e $file1out)
  {
	print "post_mfix output file ", $file1out, " already exists. Use existing file for comparison\n";
  }
  else
  {
  `post_mfix<$file1`;
  }

  $t2=$AtTime-2;
  if($AtTime<2)
  {
	$t1=$AtTime/4.0;
  }
  ($sec,$min)=localtime();
  $user=`whoami`;
  chop($user);
  $filebase="/tmp/".$user.$min.$sec.int(rand(10));
  $file2=$filebase.".get";
  $file2out=$filebase.".out";

  BuildPostMfixInput2($mfixFile,$file2,$file2out,$t2,$coord,$var,$index);
  if(-e $file2out)
  {
	print "post_mfix output file ", $file2out, " already exists. Use existing file for comparison\n";
  }
  else
  {
  `post_mfix<$file2`;
  }

  $DiffMax=Compare2ResultFiles($file1out,$file2out);
  if($DiffMax>0.1)
  {
	print "MFIX simulation has not reached a steady state at t=",$AtTime,"\n";
  } 
  elsif($DiffMax<0.05)
  {
	print "MFIX simulation has reached a steady state at t=",$AtTime,"\n";
  }
  else
  {
	print "MFIX simulation has or has not reached a steady state at t=",$AtTime,"\n";
  }
}

#check if one variable is steady state
#call this by CheckMfixSteadyState(mfixfile, "Y", "EP_g"), or
# CheckMfixSteadyState(mfixfile, "Y", "X_g"i, 2)
sub CheckMfixSteadyState
{
  my ($mfixFile,$coord,$var,$index) = @_;
  $maxTime=GetMaxTimeFromMfixInput($mfixFile);
  if($maxTime<5.0)
  {
	print "Total simulation time ", $maxTime, " is less than 5 seconds, insufficient to check for a steady state\n";
	return 100;
  }

#decide t1 and t2 for steady state comparison
  $t1=$maxTime-10;
  if($maxTime<10)
  {
	$t1=$maxTime/2.0;
  }

  ($sec,$min)=localtime();
  $user=`whoami`;
  chop($user);
  $filebase="/tmp/".$user.$min.$sec.int(rand(10));
  $file1=$filebase.".get";
  $file1out=$filebase.".out";

  BuildPostMfixInput2($mfixFile,$file1,$file1out,$t1,$coord,$var,$index);
  if(-e $file1out)
  {
	print "post_mfix output file ", $file1out, " already exists. Use existing file for comparison\n";
  }
  else
  {
	print "Running post_mfix using ", $file1, "\n";
  `post_mfix<$file1`;
  }

  ($sec,$min)=localtime();
  $user=`whoami`;
  chop($user);
  $filebase="/tmp/".$user.$min.$sec.int(rand(10));
  $file2=$filebase.".get";
  $file2out=$filebase.".out";
  $t2=$maxTime-2;
  BuildPostMfixInput2($mfixFile,$file2,$file2out,$t2,$coord,$var,$index);
  if(-e $file2out)
  {
	print "post_mfix output file ", $file2out, " already exists. Use existing file for comparison\n";
  }
  else
  {
	print "Running post_mfix using ", $file2, "\n";
  `post_mfix<$file2`;
  }

  $DiffMax=Compare2ResultFiles($file1out,$file2out);
  if($DiffMax>0.05)
  {
	print "MFIX simulation has not reached a steady state at t=",$maxTime,"\n";
	$err5=CheckMfixPeriodicSteadyState($mfixFile,$coord,$var,$index,5);
	$err10=CheckMfixPeriodicSteadyState($mfixFile,$coord,$var,$index);
	$err15=CheckMfixPeriodicSteadyState($mfixFile,$coord,$var,$index,15);
	$err20=CheckMfixPeriodicSteadyState($mfixFile,$coord,$var,$index,20);
	$err30=CheckMfixPeriodicSteadyState($mfixFile,$coord,$var,$index,30);

	print "\tperiod=5, err=", $err5,"\n";
	print "\tperiod=10, err=", $err10,"\n";
	print "\tperiod=15, err=", $err15,"\n";
	print "\tperiod=20, err=", $err20,"\n";
	print "\tperiod=30, err=", $err30,"\n";

	CheckPSteadyState($mfixFile,$coord,$var,$index, $maxTime-100, 10);
  } 
  elsif($DiffMax<=0.05)
  {
	print "MFIX simulation has reached a steady state at t=",$maxTime,"\n";
	print "Checking other time spot ...\n";
	$checkTime=50.0;
	while($checkTime<$maxTime)
	{
		CheckSteadyStateAtTime($mfixFile,$checkTime,$coord,$var,$index);
		$checkTime+=50;
	}
  }
}

#Check periodic steady state at the maximum time
sub CheckMfixPeriodicSteadyState
{
  $dtime=10;
  my ($mfixFile,$coord,$var,$index, $dt) = @_;
  if($dt > 0)
  {
    print "Taking input dtime ", $dt, "\n";
    $dtime=$dt;
  }
  else
  {
    print "Taking default dtime ", $dtime, "\n";
  }

  $maxTime=GetMaxTimeFromMfixInput($mfixFile);
  if($maxTime<100.0)
  {
	print "Total simulation time ", $maxTime, " is less than 100 seconds, insufficient to check for a periodic steady state\n";
	return;
  }
#decide t1 and t2 for steady state comparison
  $t1=$maxTime-$dtime;
  $t2=$maxTime;

($sec,$min)=localtime();
print "Localtime() returns $sec:$min:$hour:$mday\n";
$user=`whoami`;
chop($user);
$filebase="/tmp/".$user.$min.$sec.int(rand(10));
$file1=$filebase.".get";
$file1out=$filebase.".out";

  BuildPostMfixInputTAvg2($mfixFile,$file1,$file1out,$t1,$t2,$coord,$var,$index);
  if(-e $file1out)
  {
	print "post_mfix output file ", $file1out, " already exists. Delete it\n";
	`rm $file1out`;
  }
  `post_mfix<$file1`;
  print "post_mfix output file ", $file1out, "\n";

  $t1=$maxTime-$dtime*2;
  $t2=$maxTime-$dtime;
($sec,$min)=localtime();
$min++;
print "LocalTime() $sec:$min:$hour:$mday\n";
$user=`whoami`;
chop($user);
$filebase="/tmp/".$user.$min.$sec.int(rand(10));
$file2=$filebase.".get";
$file2out=$filebase.".out";

  BuildPostMfixInputTAvg2($mfixFile,$file2,$file2out,$t1,$t2,$coord,$var,$index);
  if(-e $file2out)
  {
	print "post_mfix output file ", $file2out, " already exists. Delete it\n";
	`rm $file2out`;
  }
  `post_mfix<$file2`;
  print "post_mfix output file ", $file2out, "\n";

  print "Comparing $file1out and $file2out\n";
  $DiffMax=Compare2ResultFiles($file1out,$file2out);
  print "For averaging over ", $dtime, " the maximum difference ratio is ", $DiffMax*100, "%\n";
  if($DiffMax<0.05)
  {
	print "MFIX simulation has reached a periodic steady state at t=",$maxTime," for period=", $dtime, "\n";
  }
  else
  {
	print "MFIX simulation has NOT reached a periodic steady state at t=",$maxTime," for period=", $dtime, "\n";
  }
  $DiffMax;
}

#Check periodic steady state at a given time
#the only difference with that of CheckMfixPeriodicSteadyState()
#   which Checks periodic steady state at the maximum time
sub CheckPSteadyState
{
  $dtime=10;
  my ($mfixFile,$coord,$var,$index, $time, $dt) = @_;
  if($dt > 0)
  {
    print "Taking input dtime ", $dt, "\n";
    $dtime=$dt;
  }
  else
  {
    print "Taking default dtime ", $dtime, "\n";
  }

  $maxTime=GetMaxTimeFromMfixInput($mfixFile);
  if($maxTime<100.0)
  {
	print "Total simulation time ", $maxTime, " is less than 100 seconds, insufficient to check for a periodic steady state\n";
	return;
  }
  if($maxTime<$time)
  {
	print "Total simulation time ", $maxTime, " is less than given time for status checking ", $time, ", insufficient to check for a periodic steady state\n";
	return;
  }
  if($time < 2*$dt)
  {
  	print "Insufficient time ", $time, " to do periodic steady state check\n";
	return;
  }
#decide t1 and t2 for steady state comparison
  $t1=$time-$dtime;
  $t2=$time;

($sec,$min)=localtime();
print "$sec:$min:$hour:$mday\n";
$user=`whoami`;
chop($user);
$filebase="/tmp/".$user.$min.$sec.int(rand(10));
$file1=$filebase.".get";
$file1out=$filebase.".out";

  BuildPostMfixInputTAvg2($mfixFile,$file1,$file1out,$t1,$t2,$coord,$var,$index);
  if(-e $file1out)
  {
	print "post_mfix output file ", $file1out, " already exists. Delete it\n";
	`rm $file1out`;
  }
  `post_mfix<$file1`;

  $t1=$time;
  $t2=$time+$dtime;
($sec,$min)=localtime();
print "$sec:$min:$hour:$mday\n";
$user=`whoami`;
chop($user);
$filebase="/tmp/".$user.$min.$sec.int(rand(10));
$file2=$filebase.".get";
$file2out=$filebase.".out";

  $file2=BuildPostMfixInputTAvg2($mfixFile,$file2,$file2out,$t1,$t2,$coord,$var,$index);
  if(-e $file2out)
  {
	print "post_mfix output file ", $file2out, " already exists. Delete it\n";
	`rm $file2out`;
  }
  `post_mfix<$file2`;

  $DiffMax=Compare2ResultFiles($file1out,$file2out);
  print "For averaging over ", $dtime, " the maximum difference ratio is ", $DiffMax*100, "%\n";
  if($DiffMax<0.05)
  {
	print "MFIX simulation has reached a periodic steady state at t=",$time," for period=", $dtime, "\n";
	1;
  }
  else
  {
	print "MFIX simulation has NOT reached a periodic steady state at t=",$time,"\n";
	0;
  }
}

sub Compare2ResultFiles
{
	my($file1,$file2)=@_;
	print "Compare2ResultFiles: ", $file1, " vs. ", $file2,"\n";
	@Values3=PostMfix::ReadFile2($file1,\$var11, \$var12, \@Coords1, \@Values1);
	@Values4=PostMfix::ReadFile2($file2,\$var21, \$var22, \@Coords2, \@Values2);

	#print $file1, ":\n";
	#print $var11, "\t", $var12,"\n";
	#for $index (0 .. $#Coords1)
	#{
        #	print $Coords1[$index], "\t", $Values1[$index], "\n";
	#}
	#print $file2, ":\n";
	#print $var21, "\t", $var22,"\n";
	#for $index (0 .. $#Coords2)
	#{
        #	print $Coords2[$index], "\t", $Values2[$index], "\n";
	#}
#Do some comparisons
	if($var11 ne $var21)
	{
  	print $file1, " coordinate ", $var11, " != ", $file2, " coordinate ", $var21, "\n";
  	die "Cannot compare\n";
	}
	if($var12 ne $var22)
	{
  	print $file1, " variable ", $var12, " != ", $file2, " variable ", $var22, "\n";
  	die "Cannot compare\n";
	}
	if($#Coords1 != $#Coords2)
	{
  	print $file1, "# data ", $#Coords1+1, " != ", $file2, " # data ",  $#Coords2+1, "\n";
	}
	Compare2Data(\@Coords1, \@Values1, \@Coords2, \@Values2);
}

#construt a post_mfix script
#Inputs
#	mfix.dat:	
#	time1:		300
#	time2:		310
#	var:		EP_g
#	index:		2 (optional)
# It creates a file for post_mfix, with naming convention:
#   ADSORBER_EP_g_T300.get, to create an output from post_mfix
#   ADSORBER_EP_g_T300.out
sub BuildPostMfixXYZInputTAvg
{
  my ($mfixFile,$time1,$time2,$var,$index) = @_;
  $KMAX=1; #default 1 for 2D
  PostMfix::GetInfoFromMfixInput($mfixFile, \$runname, \$IMAX, \$JMAX, \$KMAX);
	print "KMAX=$KMAX\n";

  `mkdir /scratch/kevinlai`;
  $postmfixFile="/scratch/kevinlai/".$runname ."_". $var . $index ."_T".$time1."_".$time2.".get";
  #print "post_mfix script file=",$postmfixFile,"\n";
  $outputFile="/scratch/kevinlai/".$runname . "_". $var . $index ."_T".$time1."_".$time2.".out";
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  #print "post_mfix output file=",$outputFile,"\n"; 
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nY\n"; #time averging
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
	print FILEOUT "N\n";
  print FILEOUT "2,",$JMAX+1,"\n";
	print FILEOUT "N\n";
  if($KMAX == 1)
  {
	print FILEOUT "1,1\n";
  }
  else
  {
  	print FILEOUT "2,",$KMAX+1,"\n";
		print FILEOUT "N\n";
  }
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#construt a post_mfix script
#Inputs
#	mfix.dat:	
#	time1:		300
#	time2:		310
#	coord:		Y
#	var:		EP_g
#	index:		2 (optional)
# It creates a file for post_mfix, with naming convention:
#   ADSORBER_EP_g_Y_T300.get, to create an output from post_mfix
#   ADSORBER_EP_g_Y_T300.out
sub BuildPostMfixInputTAvg
{
  my ($mfixFile,$time1,$time2,$coord,$var,$index) = @_;
  $coord = uc($coord);
  if(($coord ne "X") and ($coord ne "Y") and ($coord ne "Z"))
  {
    print "Coordinate must be X, or Y, or Z\n";
    return;
  }
  $KMAX=1; #default 1 for 2D
  PostMfix::GetInfoFromMfixInput($mfixFile, \$runname, \$IMAX, \$JMAX, \$KMAX);
  $postmfixFile=$runname ."_". $var . $index ."_".$coord."_T".$time1."_".$time2.".get";
  $outputFile=$runname . "_". $var . $index ."_".$coord."_T".$time1."_".$time2.".out";
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  #print "post_mfix output file=",$outputFile,"\n"; 
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nY\n"; #time averging
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
  if($coord eq "X")
  {
	print FILEOUT "N\n";
  }
  else
  {
	print FILEOUT "Y\n";
  }
  print FILEOUT "2,",$JMAX+1,"\n";
  if($coord eq "Y")
  {
	print FILEOUT "N\n";
  }
  else
  {
	print FILEOUT "Y\n";
  }
  if($KMAX == 1)
  {
	print FILEOUT "1,1\n";
  }
  else
  {
  	print FILEOUT "2,",$KMAX+1,"\n";
  	if($coord eq "Z")
  	{
		print FILEOUT "N\n";
  	}
  	else
  	{
		print FILEOUT "Y\n";
  	}
  }
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#Read a post_mfix output
# and populate a few variables???
#INPUT:
#	$file:	file name, the output file from post_mfix
#Assumption on input file format:
#  The file should have data for X,Y,Z coordinates and one variable, e.g.,
#      Time = 105.00
#     X		Y	Z       EP_g
#   0.123     0.456	1.2	0.78
#   ..............
#OUTPUT ?:
#  @xCoords
#  @yCoords
#  @zCoords
#current users:
#PrintVariableAtTime()
sub ReadFileXYZ
{
  my ($file, $arrayx, $arrayy, $arrayz) = @_;
  my(@xCoords, @yCoords,@zCoords);

  my @values;
  $file=$_[0];
  #print "File=", $file, "\n";
  if(-f $file) {
   open(FILEIN, $file);
   $dataStart=0; #the first "Time ="
   $dataStart2=0; #after dataStart=1, no more "Time ="
   $index=0;
   while (<FILEIN>) {
	chop($_); #delete the ending \n
	$_ =~ s/^\s+|\s+$//g; #delete all starting white space
	if($_ =~ /=/)
	{
		$dataStart=1;
		#print $_, ":::dataStart set to 1\n";
	}
	elsif(($dataStart == 1) and ($dataStart2 != 1))
	{
		if($_ !~ /=/)
		{
			#print $_, ":::dataStarti2 set to 1\n";
			$dataStart2=1;
			#not yet, need to get "Species=2" for varName
			($coordName1,$coordName2, $coordName3,$varName)=split(/\s+/,$_);
			#It is necessary to deferencing them to assign values to $var1Name and $var2Name
			$$var1Name=$coordName;
			$$var2Name=$varName;
		}
	}
	elsif($dataStart2 == 1)
	{
		($x,$y,$z,$v)=split(/\s+/,$_);
		InsertCoord($x,\@xCoords);
		InsertCoord($y,\@yCoords);
		InsertCoord($z,\@zCoords);
	}
   }
 }
 else
 {
	print "File ", $file, " does not exist\n";
 }
 close(FILEIN);
# print "X Coordinates: ", $#xCoords+1, ":\n";
# for $i (0..$#xCoords)
# {
#	print "\t",$xCoords[$i],"\n";
# }
# print "Y Coordinates: ", $#yCoords+1, ":\n";
# for $i (0..$#yCoords)
# {
#	print "\t",$yCoords[$i],"\n";
# }
# print "Z Coordinates: ", $#zCoords+1, ":\n";
# for $i (0..$#zCoords)
# {
#	print "\t",$zCoords[$i],"\n";
# }

 #these three lines are for pass the local arrays back to caller
 @$arrayx=@xCoords;
 @$arrayy=@yCoords;
 @$arrayz=@zCoords;
 return @xCoords;
} #ReadFileXYZ()
1;

#construt a post_mfix script
#Inputs
#	mfix.dat:	the file contains run_name information
#       postmfixFile:	user provided file name for post_mfix script
#       outputFile:	user specified output file name in post_mfix script
#	time:		300
#	var:		EP_g
#	index:		2 (optional, used only for array variable such as X_g)
# The only difference with original method is that user provides postmfixFile abd outputFile
sub BuildPostMfixXYZInput2
{
  my ($mfixFile,$postmfixFile,$outputFile,$time,$var,$index) = @_;
  #print "mfixfile=", $mfixFile,"END\n";
  $KMAX=1; #default 1 for 2D
  if(not (-f $mfixFile))
  {
	print "MFIX input file ", $mfixFile, " DOES NOT exist\n";
 	return;
  }
  open(FILEIN, $mfixFile);
  while (<FILEIN>) {
	if($_ =~ /^#/)
	{
		next;
	}
	if($_ =~ /^!/)
	{
		next;
	}
	chop($_); #delete the ending \n
	$line=uc($_);
	if($line =~ /RUN_NAME/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($dummy,$runname,$dummy2)=split(/'/,$line);
		#print "RunName=", $runname,"\n";
	}
	elsif($line =~ /IMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($IMAX,$dummy2)=split(/\s+/,$line);
	}
	elsif($line =~ /JMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($JMAX,$dummy2)=split(/\s+/,$line);
	}
	elsif($line =~ /KMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($KMAX,$dummy2)=split(/\s+/,$line);
	}
  }
  close(FILEIN);

  #check if the LOG file exist
  $logfile=$runname . ".LOG";
  $logExist=0;
  if(-e $logfile)
  {
  	$logExist=1;
  }
  else
  {
    $logfile=$runname . "000.LOG";
    if(-e $logfile)
    {
	$logExist=1;
    }
  }
  if($logExist==0)
  {
	die "MFIX model $runname does not have data for post-processing\n";
  }
  #print "post_mfix script file=",$postmfixFile,"\n";
  #print "post_mfix output file=",$outputFile,"\n"; 
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time,",",$time,"\n"; 
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
  print FILEOUT "N\n";
  print FILEOUT "2,",$JMAX+1,"\n";
  print FILEOUT "N\n";
  if($KMAX == 1)
  {
	print FILEOUT "1,1\n";
  }
  else
  {
  	print FILEOUT "2,",$KMAX+1,"\n";
	print FILEOUT "N\n";
  }
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#construt a post_mfix script
#Inputs
#	mfix.dat:	the file contains run_name information
#       postmfixFile:	user provided file name for post_mfix script
#       outputFile:	user specified output file name in post_mfix script
#	time:		300
#	coord:		Y
#	var:		EP_g
#	index:		2 (optional)
# It creates a file for post_mfix, with naming convention:
#   ADSORBER_EP_g_Y_T300.get, to create an output from post_mfix
#   ADSORBER_EP_g_Y_T300.out
sub BuildPostMfixInput2
{
  my ($mfixFile,$postmfixFile,$outputFile,$time,$coord,$var,$index) = @_;
  $coord = uc($coord);
  if(($coord ne "X") and ($coord ne "Y") and ($coord ne "Z"))
  {
    print "Coordinate must be X, or Y, or Z\n";
    return;
  }
  #print "mfixfile=", $mfixFile,"END\n";
  $KMAX=1; #default 1 for 2D
  open(FILEIN, $mfixFile);
  while (<FILEIN>) {
	if($_ =~ /^#/)
	{
		next;
	}
	if($_ =~ /^!/)
	{
		next;
	}
	chop($_); #delete the ending \n
	$line=uc($_);
	if($line =~ /RUN_NAME/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($dummy,$runname,$dummy2)=split(/'/,$line);
	}
	elsif($line =~ /IMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($IMAX,$dummy2)=split(/\s+/,$line);
	}
	elsif($line =~ /JMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($JMAX,$dummy2)=split(/\s+/,$line);
	}
	elsif($line =~ /KMAX/)
	{
		($dummy,$line)=split(/=/,$line);
		$line=Util::trim($line);
		($KMAX,$dummy2)=split(/\s+/,$line);
	}
  }
  close(FILEIN);

  #print "post_mfix script file=",$postmfixFile,"\n";
  #print "post_mfix output file=",$outputFile,"\n"; 
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time,",",$time,"\n"; 
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
  if($coord eq "X")
  {
	print FILEOUT "N\n";
  }
  else
  {
	print FILEOUT "Y\n";
  }
  print FILEOUT "2,",$JMAX+1,"\n";
  if($coord eq "Y")
  {
	print FILEOUT "N\n";
  }
  else
  {
	print FILEOUT "Y\n";
  }
  if($KMAX == 1)
  {
	print FILEOUT "1,1\n";
  }
  else
  {
  	print FILEOUT "2,",$KMAX+1,"\n";
  	if($coord eq "Z")
  	{
		print FILEOUT "N\n";
  	}
  	else
  	{
		print FILEOUT "Y\n";
  	}
  }
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#construt a post_mfix script
#
#Inputs
#	mfix.dat:	
#       postmfixFile:	user provided file name for post_mfix script
#       outputFile:	user specified output file name in post_mfix script
#	time1:		300
#	time2:		310
#	var:		EP_g
#	index:		2 (optional)
# It creates a file for post_mfix, with naming convention:
#   ADSORBER_EP_g_T300.get, to create an output from post_mfix
#   ADSORBER_EP_g_T300.out
sub BuildPostMfixXYZInputTAvg2
{
  my ($mfixFile,$postmfixFile,$outputFile,$time1,$time2,$var,$index) = @_;
  $KMAX=1; #default 1 for 2D
  GetInfoFromMfixInput($mfixFile, \$runname, \$IMAX, \$JMAX, \$KMAX);

  #print "post_mfix script file=",$postmfixFile,"\n";
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  #print "post_mfix output file=",$outputFile,"\n"; 
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nY\n"; #time averging
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
	print FILEOUT "N\n";
  print FILEOUT "2,",$JMAX+1,"\n";
	print FILEOUT "N\n";
  if($KMAX == 1)
  {
	print FILEOUT "1,1\n";
  }
  else
  {
  	print FILEOUT "2,",$KMAX+1,"\n";
		print FILEOUT "N\n";
  }
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#construt a post_mfix script
#   $var vs. $coord, with averaging in 3 things
#        Time: time1 to time2
#        2nd Coord
#        3rd Coord
#Inputs
#	mfix.dat:	get the run_name?
#       postmfixFile:	user provided file name for post_mfix script
#       outputFile:	user specified output file name in post_mfix script
#	time1:		300
#	time2:		310
#	coord:		Y
#	var:		EP_g
#	index:		2 (optional)
# It creates a file for post_mfix, with naming convention:
#   ADSORBER_EP_g_Y_T300.get, to create an output from post_mfix
#   ADSORBER_EP_g_Y_T300.out
sub BuildPostMfixInputTAvg2
{
  my ($mfixFile,$postmfixFile,$outputFile,$time1,$time2,$coord,$var,$index) = @_;
  $coord = uc($coord);
  if(($coord ne "X") and ($coord ne "Y") and ($coord ne "Z"))
  {
    print "Coordinate must be X, or Y, or Z\n";
    return;
  }
  #print "mfixfile=", $mfixFile,"END\n";
  $KMAX=1; #default 1 for 2D
  PostMfix::GetInfoFromMfixInput($mfixFile, \$runname, \$IMAX, \$JMAX, \$KMAX);
  print "DELETE this, mfixFile=$mfixFile,runname=$runname\n";
  #print "post_mfix script file=",$postmfixFile,"\n";
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  #print "post_mfix output file=",$outputFile,"\n"; 
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nY\n"; #time averging
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
  if($coord eq "X")
  {
	print FILEOUT "N\n";
  }
  else
  {
	print FILEOUT "Y\n";
  }
  print FILEOUT "2,",$JMAX+1,"\n";
  if($coord eq "Y")
  {
	print FILEOUT "N\n";
  }
  else
  {
	print FILEOUT "Y\n";
  }
  if($KMAX == 1)
  {
	print FILEOUT "1,1\n";
  }
  else
  {
  	print FILEOUT "2,",$KMAX+1,"\n";
  	if($coord eq "Z")
  	{
		print FILEOUT "N\n";
  	}
  	else
  	{
		print FILEOUT "Y\n";
  	}
  }
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#construt a post_mfix script
#   $var vs. $coord, with averaging in 3 things
#        Time: time1 to time2
#        2nd Coord
#        3rd Coord
#Inputs
#	mfix.dat:	get the run_name?
#       postmfixFile:	user provided file name for post_mfix script
#       outputFile:	user specified output file name in post_mfix script
#	time1:		300
#	time2:		310
#	coord:		Y
#	var:		X_s
#	index:		1 (solid phase #)
#	index:		2 (solid specis)
sub BuildPostMfixInputTAvg2Index
{
  my ($mfixFile,$postmfixFile,$outputFile,$time1,$time2,$coord,$var,$index1, $index2) = @_;
  $coord = uc($coord);
  if(($coord ne "X") and ($coord ne "Y") and ($coord ne "Z"))
  {
    print "Coordinate must be X, or Y, or Z\n";
    return;
  }
  #print "mfixfile=", $mfixFile,"END\n";
  $KMAX=1; #default 1 for 2D
  PostMfix::GetInfoFromMfixInput($mfixFile, \$runname, \$IMAX, \$JMAX, \$KMAX);

  #print "post_mfix script file=",$postmfixFile,"\n";
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  #print "post_mfix output file=",$outputFile,"\n"; 
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nY\n"; #time averging
  print FILEOUT $var,"\n"; 
  if(length($index1)>0)
  {
     print FILEOUT $index1, "\n"; 
  }
  if(length($index2)>0)
  {
     print FILEOUT $index2, "\n"; 
  }
  print FILEOUT "2,",$IMAX+1,"\n";
  if($coord eq "X")
  {
	print FILEOUT "N\n";
  }
  else
  {
	print FILEOUT "Y\n";
  }
  print FILEOUT "2,",$JMAX+1,"\n";
  if($coord eq "Y")
  {
	print FILEOUT "N\n";
  }
  else
  {
	print FILEOUT "Y\n";
  }
  if($KMAX == 1)
  {
	print FILEOUT "1,1\n";
  }
  else
  {
  	print FILEOUT "2,",$KMAX+1,"\n";
  	if($coord eq "Z")
  	{
		print FILEOUT "N\n";
  	}
  	else
  	{
		print FILEOUT "Y\n";
  	}
  }
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#construt a post_mfix script
#Inputs
#	mfix.dat:	
#       postmfixFile:	user provided file name for post_mfix script
#       outputFile:	user specified output file name in post_mfix script
#	time1:		300
#	time2:		310
#	coord:		Y
#	var:		EP_g
#	index:		2 (optional)
sub BuildPostMfixVarAtPointTimes2
{
  my ($mfixFile,$postmfixFile,$outputFile,$time1,$time2,$I,$J,$K,$var,$index) = @_;
  $runname=PostMfix::GetRunNameFromMfixInput($mfixfile);
  BuildPostMfixVarAtPointTimes($runname,$postmfixFile,$outputFile,$time1,$time2,$I,$J,$K,$var,$index);
  $postmfixFile;
}

#values for a specified variable at a specific location, time history from time1 to time2
#Input
#	$runname
sub BuildPostMfixVarAtPointTimes
{
  my ($runname,$postmfixFile,$outputFile,$time1,$time2,$I,$J,$K,$var,$index) = @_;
  #print "post_mfix script file=",$postmfixFile,"\n";
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  #print "post_mfix output file=",$outputFile,"\n"; 
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nN\n"; #Display values each each time step
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT $I,",",$I,"\n";
  print FILEOUT $J,",",$J,"\n";
  print FILEOUT $K,",",$K,"\n";
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

sub BuildPostMfixVarAvgSpatialAtTimes
{
  my ($runname,$postmfixFile,$outputFile,$time1,$time2,$i1,$i2,$j1,$j2,$k1,$k2,$var,$index1,$index2) = @_;
  if($i2<$i1 or $j2<$j1 or $k2<$k1)
  {
	print "Eror, BuildPostMfixVarAvgSpatialAtTimes($i1,$i2,$j1,$j2,$k1,$k2)\n";
 	return;
  }
  #print "post_mfix script file=",$postmfixFile,"\n";
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  #print "post_mfix output file=",$outputFile,"\n"; 
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nN\n"; #Display values each each time step
  print FILEOUT $var,"\n"; 
  if(length($index1)>0)
  {
     print FILEOUT $index1, "\n"; 
     if(length($index2)>0)
     {
     	print FILEOUT $index2, "\n"; 
     }
  }
  print FILEOUT $i1,",",$i2,"\n";
  if($i1 ne $i2)
  {
	print FILEOUT "Y\n";
  }
  print FILEOUT $j1,",",$j2,"\n";
  if($j1 ne $j2)
  {
	print FILEOUT "Y\n";
  }
  print FILEOUT $k1,",",$k2,"\n";
  if($k1 ne $k2)
  {
	print FILEOUT "Y\n";
  }
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#values for a specified variable at a specific location, time history from time1 to time2
#copied from BuildPostMfixVarAtPointTime()
#For solid species which require TWO indexes: 1 for phase, and 1 for species
#Input
#	$runname
sub BuildPostMfixVarAtPointTimes2Index
{
  my ($runname,$postmfixFile,$outputFile,$time1,$time2,$I,$J,$K,$var,$index1,$index2) = @_;
  if(length($index1)==0 or length($index2)==0)
  {
	print "ERROR: calling BuildPostMfixVarAtPointTimes2Index() for $var with $index1 and $index2\n";
	return;
  }
  #print "post_mfix script file=",$postmfixFile,"\n";
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  #print "post_mfix output file=",$outputFile,"\n"; 
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nN\n"; #Display values each each time step
  print FILEOUT $var,"\n"; 
  print FILEOUT $index1,"\n"; 
  print FILEOUT $index2,"\n"; 
  print FILEOUT $I,",",$I,"\n";
  print FILEOUT $J,",",$J,"\n";
  print FILEOUT $K,",",$K,"\n";
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}

#same as BuildPostMfixVarAtPointTimes2Index, except input mfixFile
sub BuildPostMfixVarAtPointTimes2Index2
{
  my ($mfixFile,$postmfixFile,$outputFile,$time1,$time2,$I,$J,$K,$var,$index1,$index2) = @_;
  $runname=PostMfix::GetRunNameFromMfixInput($mfixfile);
  BuildPostMfixVarAtPointTimes2Index($runname,$postmfixFile,$outputFile,$time1,$time2,$I,$J,$K,$var,$index1,$index2);
  $postmfixFile;
}

#values for a specified variable at a specific location (x,y), time history from time1 to time2
#but average K (suitable for 3D cylinder coordinate)
sub BuildPMVarAtPointTimesAvgK
{
  my ($runname,$postmfixFile,$outputFile,$time1,$time2,$I,$J,$K1,$K2,$var,$index) = @_;
  #print "post_mfix script file=",$postmfixFile,"\n";
  if(length($outputFile)>30)
  {
    print "Warning: post_mfix output name ", $outputFile, " truncated to 30 due to post_mfix limitation, ";
    $outputFile = substr($outputFile,0,30);
    print $outputFile, "\n"; 
  }
  #print "post_mfix output file=",$outputFile,"\n"; 
  open(FILEOUT, ">$postmfixFile");
  print FILEOUT $runname,"\n"; 
  print FILEOUT "1\nF\n"; 
  print FILEOUT $time1,",",$time2,"\nN\n"; #Display values each each time step
  print FILEOUT $var,"\n"; 
  if(length($index)>0)
  {
     print FILEOUT $index, "\n"; 
  }
  print FILEOUT $I,",",$I,"\n";
  print FILEOUT $J,",",$J,"\n";
  print FILEOUT $K1,",",$K2,"\nY\n"; #'Y' means averaging
  print FILEOUT $outputFile,"\n"; 
  print FILEOUT "-1\n0\n"; 
  close(FILEOUT);
  $postmfixFile;
}


#Read a post_mfix output
# and populate a few variables???
#Copied and modified from ReadFileXYZ()
#INPUT:
#	$file:	file name, the output file from post_mfix
#Assumption on input file format:
#  The file should have data for X,Y,Z coordinates and one variable, e.g.,
#      Time = 105.00
#     X		Y	Z       EP_g
#   0.123     0.456	1.2	0.78
#   ..............
#OUTPUT ?:
#  @xCoords
#  @yCoords
#  @zCoords
#  @variable
sub ReadFileXYZV
{
  my ($file, $arrayx, $arrayy, $arrayz, $arrayv) = @_;
  my(@xCoords, @yCoords,@zCoords, @variables);

  my @values;
  $file=$_[0];
  #print "File=", $file, "\n";
  if(-f $file) {
   open(FILEIN, $file);
   $dataStart=0; #the first "Time ="
   $dataStart2=0; #after dataStart=1, no more "Time ="
   $index=0;
   while (<FILEIN>) {
	chop($_); #delete the ending \n
	$_ =~ s/^\s+|\s+$//g; #delete all starting white space
	if($_ =~ /=/)
	{
		$dataStart=1;
		#print $_, ":::dataStart set to 1\n";
	}
	elsif(($dataStart == 1) and ($dataStart2 != 1))
	{
		if($_ !~ /=/)
		{
			#print $_, ":::dataStarti2 set to 1\n";
			$dataStart2=1;
			#not yet, need to get "Species=2" for varName
			($coordName1,$coordName2, $coordName3,$varName)=split(/\s+/,$_);
			#It is necessary to deferencing them to assign values to $var1Name and $var2Name
			$$var1Name=$coordName;
			$$var2Name=$varName;
		}
	}
	elsif($dataStart2 == 1)
	{
		($x,$y,$z,$v)=split(/\s+/,$_);
		InsertCoord($x,\@xCoords);
		InsertCoord($y,\@yCoords);
		InsertCoord($z,\@zCoords);
	}
   }
 }
 else
 {
	print "File ", $file, " does not exist\n";
 }
 close(FILEIN);

#re-open for V this time
 open(FILEIN, $file);
 $Count=0;
 while (<FILEIN>) {
	chop($_); #delete the ending \n
	$_ =~ s/^\s+|\s+$//g; #delete all starting white space
	($x,$y,$z,$v)=split(/\s+/,$_);
	$I=PostMfix::GetCoordIndex($x,\@xCoords);	
	$J=PostMfix::GetCoordIndex($y,\@yCoords);	
#	$K=GetCoordIndex($z,\@zCoords);	
	if($I>=0 and $J>=0)
	{
 		$Count++;
		$variables[$I][$J]=$v;
	}
	#print "(", $I,",",$J, ")=",$variables[$I][$J], "\n";
 }
 close(FILEIN);

 #these three lines are for pass the local arrays back to caller
 @$arrayx=@xCoords;
 @$arrayy=@yCoords;
 @$arrayz=@zCoords;
 @$arrayv=@variables;
 return @xCoords;
} #ReadFileXYZV()

#Read mfix input file and correesponding OUT file to get a specified BC information
#Input:
#	file, mfix.dat
#	bcId, 1,2,3,etc.
#OUTPUT:
#	$massflow_g
#	@gas_species
#	$massflow_s
#	@solid_species
#	@xCoords
#	@yCoords
# read from huge mfixOUT file?
# MFIX.OUT is more accurate for IC and BC: that is what actually simulated!
#
sub ReadBC
{
  my ($mfixFile, $bcId, $massflow_g, $gas_species, $massflow_s, $solid_species, $xCoords, $yCoords) = @_;
  PostMfix::GetInfoFromMfixInput($mfixFile, \$runname, \$IMAX, \$JMAX, \$KMAX);
  $outfile=$runname.".OUT";
  PostMfix::ReadMFIXOUT_and_Write($outfile,"BC","dummy.out");
  $outfile="dummy.out";
  #print $outfile;
  #print "for #bcId ", $bcId,"\n";
  if(-f $outfile) {
   open(FILEIN, $outfile);
   $foundIt=0;
   $foundGas=0;
   $foundSolid=0;
   while (<FILEIN>) {
	$_ = lc($_);
	if($_ =~ /boundary condition no/)
	{
		($dummy,$id)=split(":", $_);
		if($id==$bcId)
		{
   			$foundIt=1;
		}
		elsif($id>$bcId)
		{
   			$foundIt=0;
			#print "BC for ID ", $bcId, " does not exist?\n";
			last;
		}
	}
	if($foundIt==1)
	{
		if($_ =~ /bc_massflow_g/)
		{
		  	($dummy,$dummy2)=split("=", $_);
  			$$massflow_g=$dummy2;
			#print "inside function $dummy2 \n";
		}
		elsif($_ =~ /bc_massflow_s/)
		{
		  	($dummy,$dummy2)=split("=", $_);
  			$$massflow_s=$dummy2;
			#print "inside function $dummy2 \n";
		}
		elsif($_ =~ /bc_x_g/)
		{
			$foundGas=1;
			$foundSolid=0;
		}
		elsif($_ =~ /bc_x_s/)
		{
			$foundGas=0;
			$foundSolid=1;
		}
		elsif($foundGas>0)
		{
			if($_ =~ /gas/) #signal the end of "Gas species" block
			{
				$foundGas=0;
			}
			else
			{
				($gid,$gases[$foundGas-1])=split(" ",$_);
				#print "Gas $gases[$foundGas-1]\n";
				$foundGas++;
			}
		}
		elsif($foundSolid>0)
		{
			if($_ =~ /solid/) #signal the end of "Gas species" block
			{
				$foundSolid=0;
			}
			else
			{
				($gid,$solids[$foundSolid-1])=split(" ",$_);
				#print "Solid $solids[$foundSolid-1]\n";
				$foundSolid++;
			}
		}
		if($_ =~ /bc_x_w/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			($xw1,$xw2)=split(" ",$dummy2);
		}
		elsif($_ =~ /bc_x_e/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			($xe1,$xe2)=split(" ",$dummy2);
		}
		elsif($_ =~ /bc_y_n/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			($yn1,$yn2)=split(" ",$dummy2);
		}
		elsif($_ =~ /bc_y_s/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			($ys1,$ys2)=split(" ",$dummy2);
		}
	}
   }
   close(FILEIN);

#if specified BC_X_w=BC_X_e, pick X==BC_X_w specified
#   pick Y=BC_Y_s and BC_Y_n Simulated.
   if($xw1==$xe1)
   {
 	$xs[0]=$xw1;
	$xs[1]=$xw1;
	$ys[0]=$ys2;
	$ys[1]=$yn2;
   }
   elsif($ys1==$yn1)
   {
 	$xs[0]=$xw2;
	$xs[1]=$xe2;
	$ys[0]=$ys1;
	$ys[1]=$ys1;
   }
#if specified BC_Y_s=BC_Y_n, pick Y==BC_Y_s specified
#   pick X=BC_X_w and BC_X_e Simulated.
  }
  @$gas_species=@gases;
  @$solid_species=@solids;
  @$xCoords=@xs;
  @$yCoords=@ys;
}

#Read mfix input file and correesponding OUT file to get a specified BC information
#Copied from ReadBC(), added outputting @xIndexes, @yIndexes
#Input:
#	file, mfix.dat
#	bcId, 1,2,3,etc.
#OUTPUT:
#	$massflow_g
#	@gas_species
#	$massflow_s
#	@solid_species
#	@xCoords
#	@yCoords
#	@xIndexes
#	@yIndexes
# read from huge mfixOUT file?
# MFIX.OUT is more accurate for IC and BC: that is what actually simulated!
#
sub ReadBC2
{
  my ($mfixFile, $bcId, $massflow_g, $gas_species, $massflow_s, $solid_species, $xCoords, $yCoords, $xIndexes, $yIndexes) = @_;
  PostMfix::GetInfoFromMfixInput($mfixFile, \$runname, \$IMAX, \$JMAX, \$KMAX);
  $outfile=$runname.".OUT";
  PostMfix::ReadMFIXOUT_and_Write($outfile,"BC","dummy.out");
  $outfile="dummy.out";
  #print $outfile;
  #print "for #bcId ", $bcId,"\n";
  if(-f $outfile) {
   open(FILEIN, $outfile);
   $foundIt=0;
   $foundGas=0;
   $foundSolid=0;
   while (<FILEIN>) {
	chop($_);
	$_ = lc($_);
	if($_ =~ /boundary condition no/)
	{
		($dummy,$id)=split(":", $_);
		if($id==$bcId)
		{
   			$foundIt=1;
		}
		elsif($id>$bcId)
		{
   			$foundIt=0;
			#print "BC for ID ", $bcId, " does not exist?\n";
			last;
		}
	}
	if($foundIt==1)
	{
		if($_ =~ /bc_massflow_g/)
		{
		  	($dummy,$dummy2)=split("=", $_);
  			$$massflow_g=$dummy2;
			#print "inside function $dummy2 \n";
		}
		elsif($_ =~ /bc_massflow_s/)
		{
		  	($dummy,$dummy2)=split("=", $_);
  			$$massflow_s=$dummy2;
			#print "inside function $dummy2 \n";
		}
		elsif($_ =~ /bc_x_g/)
		{
			$foundGas=1;
			$foundSolid=0;
		}
		elsif($_ =~ /bc_x_s/)
		{
			$foundGas=0;
			$foundSolid=1;
		}
		elsif($foundGas>0)
		{
			if($_ =~ /gas/) #signal the end of "Gas species" block
			{
				$foundGas=0;
			}
			else
			{
				($gid,$gases[$foundGas-1])=split(" ",$_);
				#print "Gas $gases[$foundGas-1]\n";
				$foundGas++;
			}
		}
		elsif($foundSolid>0)
		{
			if($_ =~ /solid/) #signal the end of "Gas species" block
			{
				$foundSolid=0;
			}
			else
			{
				($gid,$solids[$foundSolid-1])=split(" ",$_);
				#print "Solid $solids[$foundSolid-1]\n";
				$foundSolid++;
			}
		}
		if($_ =~ /bc_x_w/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			($xw1,$xw2)=split(" ",$dummy2);
		}
		elsif($_ =~ /bc_x_e/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			($xe1,$xe2)=split(" ",$dummy2);
		}
		elsif($_ =~ /bc_y_n/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			($yn1,$yn2)=split(" ",$dummy2);
		}
		elsif($_ =~ /bc_y_s/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			($ys1,$ys2)=split(" ",$dummy2);
		}
		elsif($_ =~ /bc_i_e/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			$xei=$dummy2;
		}
		elsif($_ =~ /bc_i_w/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			$xwi=$dummy2;
		}
		elsif($_ =~ /bc_j_n/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			$ynj=$dummy2;
		}
		elsif($_ =~ /bc_j_s/)
		{
		  	($dummy,$dummy2)=split("=", $_);
			$ysj=$dummy2;
		}
	}
   }
   close(FILEIN);

#if specified BC_X_w=BC_X_e, pick X==BC_X_w specified
#   pick Y=BC_Y_s and BC_Y_n Simulated.
   if($xw1==$xe1)
   {
	#coordinates
 	$xs[0]=$xw1;
	$xs[1]=$xw1;
	$ys[0]=$ys2;
	$ys[1]=$yn2;
	#indexes
	if($xei ne $xwi)
	{
		print "ERROR, BC X index $xei != $xwi\n";
	}
	$xis[0]=$xwi;
	$xis[1]=$xei;
	$yjs[0]=$ysj;
	$yjs[1]=$ynj;
   }
   elsif($ys1==$yn1)
   {
	#coordinates
 	$xs[0]=$xw2;
	$xs[1]=$xe2;
	$ys[0]=$ys1;
	$ys[1]=$ys1;
	#indexes
	if($ysj ne $ynj)
	{
		print "ERROR, BC Y index $ysj != $ynj\n";
	}
	$xis[0]=$xwi;
	$xis[1]=$xei;
	$yjs[0]=$ysj;
	$yjs[1]=$ynj;
   }
   else
   {
	print "Cannot handle a BC that is neither vertical nor horizontal\n";
   }
#if specified BC_Y_s=BC_Y_n, pick Y==BC_Y_s specified
#   pick X=BC_X_w and BC_X_e Simulated.
  }
  @$gas_species=@gases;
  @$solid_species=@solids;
  @$xCoords=@xs;
  @$yCoords=@ys;
  
  @$xIndexes=@xis;
  @$yIndexes=@yjs;
}

#Read from MFIX.OUT, get the corresponding section and write to $writeTo
#INPUT
#	readFrom:	MFIX33.OUT
#	blockName:	INTERNAL SURFACES
# e.g., PostMfix::ReadMFIXOUT_and_Write("MFIX33.OUT","IC","dummy.out");
sub ReadMFIXOUT_and_Write
{
  my ($readFrom, $blockName, $writeTo) = @_;
  my(@blocks);
  $blocks[0]="RUN CONTROL";
  $blocks[1]="PHYSICAL AND NUMERICAL PARAMETERS";
  $blocks[2]="GEOMETRY AND DISCRETIZATION";
  $blocks[3]="GAS PHASE";
  $blocks[4]="SOLIDS PHASE";
  $blocks[5]="INITIAL CONDITIONS";
  $blocks[6]="BOUNDARY CONDITIONS";
  $blocks[7]="INTERNAL SURFACES";
  $blocks[8]="OUTPUT DATA FILES";
  $blocks[9]="TOLERANCES";
  $blocks[10]="INITIAL AND BOUNDARY CONDITION FLAGS";
  $blockName=uc($blockName);
  if($blockName eq "BC")
  {
	$blockName="BOUNDARY CONDITIONS";
  } 
  elsif($blockName eq "IC")
  {
	$blockName="INITIAL CONDITIONS";
  } 
  if(-f $readFrom) {
   open(FILEOUT, ">$writeTo");
   open(FILEIN, $readFrom);
   $foundIt=0;
   $count=0;
   while (<FILEIN>) {
	if($_ =~ /$blockName/)
	{
		$foundIt=1;
		($id,$rest)=split("\.",$_);
		#print $_, "id = $id\n";
		print FILEOUT $_;
	}
	elsif($foundIt==1)
	{
		$done=0;
		foreach $block (@blocks)
		{
			if($_ =~ /$block/)
			{
				$done=1;
			}
		}
		if($done==1)
		{
			last;
		}
		print FILEOUT $_;
	}
   }
   close(FILEIN);
   close(FILEOUT);
 }
}
 
#Create points (x,y) for a given BC #ID, in 2D
#INPUTs
#	mfixFile: mfix.dat
#	bcId	: e.g, BC#2
#	nNodes  : > 0, the number of nodes
#		  = 1, get the middle point
#		  = 2, get the two 
#	xCoords : the center of each BC section
#	yCoords : the center of each BC section
#OUTPUTs:
sub Set2DMFIXBCNodes
{
  my ($mfixFile, $bcId, $nNodes, $xCoords, $yCoords) = @_;
  PostMfix::GetInfoFromMfixInput($mfixFile, \$runname, \$IMAX, \$JMAX, \$KMAX);
  $outfile=$runname.".OUT";
  PostMfix::ReadMFIXOUT_and_Write($outfile,"BC","dummy.out");
#Assume 2D in X and Y
#Get BC_X_w, BC_X_e, BC_Y_s, BC_Y_n
#both specified and simulated
#Handle only straight BC?
#if specified BC_X_w=BC_X_e, pick X==BC_X_w specified
#   pick Y=BC_Y_s and BC_Y_n Simulated.

#if specified BC_Y_s=BC_Y_n, pick Y==BC_Y_s specified
#   pick X=BC_X_w and BC_X_e Simulated.
          
}

sub GetBedHeight
{
   my($mfixfile,$coord,$minValue,$time1,$time2) = @_;
   #print "minValue=$minValue\n";
   $me=`whoami`;
   chop($me);
   $myDir="/tmp/$me";
   $file1="$myDir/dummy.get";
   $file1out="$myDir/dummy.out";
   $qoi="EP_g";
   PostMfix::BuildPostMfixInputTAvg2($mfixfile,$file1,$file1out,$time1,$time2,$coord,$qoi);

   if(-e $file1out)
   {
       print "post_mfix output file ", $file1out, " already exists. Deleted!\n";
       `rm -f $file1out`;
   }
   `post_mfix<$file1`;
   open(FILEIN, $file1out);
   $start=0;
   $i=0;
   $bedHeight=0.0;
   my(@yy,@epg);
   while (<FILEIN>)
   {
      chop($_); #delete the ending \n
      $_ =~ s/^\s+|\s+$//g; #delete all starting white space
      ($x,$y)=split(/\s+/,$_);
      #print "x=$x END, y=$y END\n";
      if( ($y eq $qoi) and ($x eq $coord))
      {
        #print "starting the read $_\n";
        $start=1;
      }
      elsif($start==1)
      {
        $yy[$i]=$x;
        $epg[$i]=$y;
        #print "time vs variable: $times[$i], $variables[$j][$i], \n";
        $i++;
      }
   }
   close(FILEIN);
   $i1=$#yy/10;
   for $i ($i1..$#yy)
   {
	#print $yy[$i], ",", $epg[$i],"\n";
	if($epg[$i]>$minValue and $epg[$i-1]<$minValue)
	{
	   $bedHeight=$yy[$i-1]+($yy[$i]-$yy[$i-1])/($epg[$i]-$epg[$i-1])*($minValue-$epg[$i-1]);
	}
   }
   return $bedHeight;
}
1;
