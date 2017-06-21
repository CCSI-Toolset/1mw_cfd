#!/usr/bin/env perl
###!/usr/bin/perl
#Copied from PP32DReactingFlow.pl
#this works only for 2D cylindrical coordinates. k==1
#20140130: calculation on CO2 adsorption fixed. More or less okay
#20140902: add summary of 3 QOIs:
#	CO2 adsorption rate (norminal)
#	CO2 adsorption rate (BC4 side exit CO2 considered not adsorbed)
#	bed height: based on EP_g=0.95
#	amine % at the side exit, compared with inlet value
use lib "/pic/people/kevinlai/bin";
use PostMfix;
use Util;
use MyMath;

print "Usage: $thisCommand -f mfixInputfileName -t display_time1 display_time2 -o outputFile\n\n";

#PrtVarAtXYZAtTimes.pl
$me=`whoami`;
chop($me);
$index="";
$mfixfile="mfix.dat";
$varName="P_g";
$time1=0;
$time2=600;
$targetDir="";
$outFile="pp1mw.out";
$override=0;
$Total_Exp=-1; #optional, experimental total in moles. If given, at the end, give T_25, T_50, and T_75 
$T_25=0;
$T_50=0;
$T_75=0;

for $i (0..$#ARGV)
{
        if($ARGV[$i] eq "--help")
        {
		print "  -f mfixInputFileName. Default mfix.dat\n";
		print "  -t t1 t2 listing values from time=t1 to t2. Default t1=1, t2=300\n";
		die "  -o outputFileName. Default result.dat\n";
        }
        elsif($ARGV[$i] eq "-f")
        {
                $mfixfile=$ARGV[$i+1];
        }
        elsif($ARGV[$i] eq "-t")
        {
		$time1=$ARGV[$i+1];
		$time2=$ARGV[$i+2];
	}
        elsif($ARGV[$i] eq "-d")
	{
		$targetDir=$ARGV[$i+1];
		$targetDir=$targetDir."/";
	}
        elsif($ARGV[$i] eq "-oo")
	{
		$outFile=$ARGV[$i+1];
		$override=1;
	}
        elsif($ARGV[$i] eq "-o")
	{
		$outFile=$ARGV[$i+1];
	}
        elsif($ARGV[$i] eq "-est")
	{
		$Total_Exp=$ARGV[$i+1];
	}
}
open(FILEOUT, ">$outFile");
#GET BOUNDARY CONDITIONS
#Hard coded for now for gas species: 1=N2, 2=CO2, 3=H2O, 4=O2
#  to improve, can read SPECIES_g(1-4) from mfix.dat, or MFIX.OUT
#Hard coded for now for solid species: 1=SiO2, 2=R2NH, 3=R2NCO2-, 4=R2NH2+,5=HCO3-,6=H2O(abs)
#  to improve, read SPECIES_s(1,1-6)
#BC1: floor inlet gas, where CO2 comes from
PostMfix::ReadBC2($mfixfile,1,\$massflow_g1,\@gases1,\$massflow_s1,\@solids1, \@xs1, \@ys1, \@xis1, \@yjs1);
#BC2: solid inlet for downcomer, 
PostMfix::ReadBC2($mfixfile,2,\$massflow_g2,\@gases2,\$massflow_s2,\@solids2, \@xs2, \@ys2, \@xis2, \@yjs2);
#BC3: top outlet, measure CO2
PostMfix::ReadBC2($mfixfile,3,\$massflow_g3,\@gases3,\$massflow_s3,\@solids3, \@xs3, \@ys3, \@xis3, \@yjs3);
#BC4: side outlet, measure CO2, and solid
PostMfix::ReadBC2($mfixfile,4,\$massflow_g4,\@gases4,\$massflow_s4,\@solids4, \@xs4, \@ys4, \@xis4, \@yjs4);
print FILEOUT "Verify the following Inlet Flow parameters before using the result\n";
print "Verify the following Inlet Flow parameters before using the result\n";
$TotalMassFlow_g=$massflow_g1+$massflow_g2;
$N2=$massflow_g1*$gases1[0]+$massflow_g2*$gases2[0];
$CO2=$massflow_g1*$gases1[1]+$massflow_g2*$gases2[1];
$H2O=$massflow_g1*$gases1[2]+$massflow_g2*$gases2[2];
$O2=$massflow_g1*$gases1[3]+$massflow_g2*$gases2[3];
print "  Total Gas Inlet =$TotalMassFlow_g (kg/s)\n";
print "\tN2 =$N2 (kg/s)\n";
print "\tCO2=$CO2 (kg/s)\n";
print "\tH2O=$H2O (kg/s)\n";
print "\tO2=$O2 (kg/s)\n";
print FILEOUT "  Total Gas Inlet =$TotalMassFlow_g (kg/s)\n";
print FILEOUT "\tN2 =$N2 (kg/s)\n";
print FILEOUT "\tCO2=$CO2 (kg/s)\n";
print FILEOUT "\tH2O=$H2O (kg/s)\n";
print FILEOUT "\tO2=$O2 (kg/s)\n";
$TotalMassFlow_s=$massflow_s1+$massflow_s2;
$SiO2=$massflow_s1*$solids1[0]+$massflow_s2*$solids2[0];
$R2NH=$massflow_s1*$solids1[1]+$massflow_s2*$solids2[1];
$R2NCO2=$massflow_s1*$solids1[2]+$massflow_s2*$solids2[2];
$R2NH2=$massflow_s1*$solids1[3]+$massflow_s2*$solids2[3];
$HCO3=$massflow_s1*$solids1[4]+$massflow_s2*$solids2[4];
$H2O_abs=$massflow_s1*$solids1[5]+$massflow_s2*$solids2[5];
print "  Total Solid Inlet =$TotalMassFlow_s (kg/s)\n";
print "\tR2NH =$R2NH\n";
print FILEOUT "  Total Solid Inlet =$TotalMassFlow_s (kg/s)\n";
print FILEOUT "\tR2NH =$R2NH (kg/2)\n";
#$totalVolume=$N2/28.0+$CO2/44.0+$H2O/18.0;
#$CO2InletByVolume=$CO2/44.0/$totalVolume;
#$flowrate=$volflow*60*1000*293/$T_G;
#print "\tInlet CO2: by mass   ", sprintf("%.1f",$CO2Inlet*100.0),"%\n";
#print "\t           by volume ",sprintf("%.1f",$CO2InletByVolume*100),"%\n";
#print "\tTotal flow rate: ", sprintf("%.3f",$flowrate), " slpm\n";

#TEMPORARY FILES by postmfix utility
$myDir="/tmp/$me";
if(-d $myDir)
{
	print "$myDir exists\n";
}
else
{
	mkdir $myDir or die "cannot create $myDir\n";
}
$postmfixGet="$myDir/pp32.get";
$postmfixOut="$myDir/pp32.out";
$time1=1.0;
$varName="EP_g";
$index="";
PostMfix::BuildPostMfixXYZInput2($mfixfile,$postmfixGet,$postmfixOut,$time1,$varName,$index);
if(-f $postmfixOut)
{
	print "Warning: post_mfix output file ", $postmfixOut, " exists, delete it...\n";
	`rm $postmfixOut`;
}
`post_mfix < $postmfixGet`;
my(@xCoords,@yCoords,@zCoords);
#this establishes @xCoords, yCoords, zCoords which will be used later
PostMfix::ReadFileXYZ($postmfixOut,\@xCoords,\@yCoords,\@zCoords);
print "X $#xCoords, $xCoords[0],$xCoords[1],$xCoords[$#xCoords]\n";
print "Y $#yCoords, $yCoords[0],$yCoords[1],$yCoords[$#yCoords]\n";

$runname=PostMfix::GetRunNameFromMfixInput($mfixfile);
#check if the run actually exist
if(-f "$runname.RES")
{
	print "Simulation exist\n";
}
else
{
	print FILEOUT "Simulation result does not exist\n";
	close(FILEOUT);
	die "$runname Simulation result does not exist";
}
$maxTime=PostMfix::GetMaxTimeFromMfixInput($mfixfile);
if($time2>$maxTime)
{
	print "time2 is greater than simulation time, reduced to ", $maxTime,"\n";
	$time2=$maxTime;
}
#For UQ1 and UQ2 simulations
print FILEOUT "mfix input file: $mfixfile, run name: $runname\n";
print FILEOUT "\tInlet Gas Temperature: $T_G\n";
print FILEOUT "\tTotal flow rate: $flowrate slpm\n";
print FILEOUT "Time from : ", $time1, " to ", $time2, "\n";
if($time2<200)
{
   print FILEOUT "Total simulation time is $time2 < 200. Stop post-processing\n";
   close(FILEOUT);
   die "Simulation time $time2 is too short\n";
}

#post_mfix might not have print time=1
if($time1==1)
{
	$time1=0.8;
}
#print FILEOUT "For $casename \n";

#Common variables needed to do the interpolation for 
my($i1,$i2,$j1,$j2,$k1,$k2);
$i1=-1;
$i2=-1;
$j1=-1;
$j2=-1;
$k1=-1;
$k2=-1;

#first BC3, picking one point might NOT be good enough
$xx=0.5*($xs3[0]+$xs3[1]);
$yy=$ys3[0];
#So, using another way, GetTimedQOIAtBC
print "For BC3 center point: $xx, $yy\n";

$varName="ROP_s";
$index1="1";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@Rops3,$varName,$index1);
$varName="T_g";
$index="";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@Tg3,$varName);
$varName="EP_g";
$index="";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@Epg3,$varName);
$varName="P_g";
$index="";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@Pg3,$varName);
$varName="X_g";
$index1="1";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@N23,$varName,$index1);
$index1="2";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@CO23,$varName,$index1);
$index1="3";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@H2O3,$varName,$index1);
$index1="4";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@O23,$varName,$index1);
$varName="V_g";
$index1="";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@Vg3,$varName);
$varName="V_s";
$index1="1";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@Vs3,$varName,$index1);
#Get solid exit information
$varName="MFLOW_sx";
$index1="1";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times,\@mflowsx3,$varName,$index1);
#Note: X_g and X_s are all mass fraction, NOT mole fraction
$varName="X_s";
$index1="1";
$index2="2";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times, \@X_s_1_2,$varName,$index1,$index2); #R2NH
$index1="1";
$index2="3";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times, \@X_s_1_3,$varName,$index1,$index2); #R2NH2+
$index1="1";
$index2="4";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times, \@X_s_1_4,$varName,$index1,$index2); #R2NH2+
$index1="1";
$index2="5";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times, \@X_s_1_5,$varName,$index1,$index2); #HCO3-
$index1="1";
$index2="6";
GetTimedQOIAtBC($runname,$xis3[0],$xis3[1],$yjs3[0],$yjs3[1],\@Times, \@X_s_1_6,$varName,$index1,$index2); #H2O (abs)

$BC3Length=($xs3[1]-$xs3[0]);
#get 1.221=dz
$ZLENGTH=1.221;
print "BC3 xs3 $xs3[0], $xs3[1]\n";
print FILEOUT "BC#3, x=$xx, y=$yy\n";
print FILEOUT "Time\tEP_g\t       Pg\t        Tg\t        CO2\t        H2O\t         V_g\t        V_s\t        ROP_s\t        CO2(mole/s)\tCO2(kg/s)";
print FILEOUT "\tR2NH\t        R2NCO2-\t        R2NH2+\t        HCO3-\t        H2O(abs)\n";
for $i (0..$#Times)
{
	$MoleRate=$BC3Length*$ZLENGTH*$Vg3[$i]*$Epg3[$i]*($Pg3[$i]*273.15/$Tg3[$i]/101340)/0.0224; #mole/s
	$dummy=$N23[$i]+$CO23[$i]+$H2O3[$i]+$O23[$i];
	$TotalVolume=$N23[$i]/28.0+$CO23[$i]/44.0+$H2O3[$i]/18.0+$O23[$i]/32.0;
	$CO2ExitBC3[$i]=$MoleRate/$TotalVolume*$CO23[$i]/44.0; #mole/s, CO2 share of mole/s
	$H2OExitBC3[$i]=$MoleRate/$TotalVolume*$H2O3[$i]/18.0;
	$CO2ExitBC3Kg[$i]=$CO2ExitBC3[$i]*0.044; #kg/s
	$H2OExitBC3Kg[$i]=$H2OExitBC3[$i]*0.018; #kg/s

	$R2NHExitBC3[$i]=$BC3Length*$ZLENGTH*$Vs3[$i]*$Rops3[$i]*$X_s_1_2[$i]; #mole/s
	$R2NCO2ExitBC3[$i]=$BC3Length*$ZLENGTH*$Vs3[$i]*$Rops3[$i]*$X_s_1_3[$i]; #mole/s
	$R2NH2ExitBC3[$i]=$BC3Length*$ZLENGTH*$Vs3[$i]*$Rops3[$i]*$X_s_1_4[$i]; #mole/s
	$HCO3ExitBC3[$i]=$BC3Length*$ZLENGTH*$Vs3[$i]*$Rops3[$i]*$X_s_1_5[$i]; #mole/s
	$H2OabsExitBC3[$i]=$BC3Length*$ZLENGTH*$Vs3[$i]*$Rops3[$i]*$X_s_1_6[$i]; #mole/s
	if($Times[$i]>$maxTime-100)
	{
	#print FILEOUT "DELETE $H2OExitBC3[$i]=$BC3Length*$ZLENGTH*$Vg3[$i]*$Epg3[$i]*$H2O3[$i]*($Pg3[$i]*273.15/$Tg3[$i]/101340)/0.0224\n";
	}
	print FILEOUT sprintf("%.3f",$Times[$i]), 
		"\t",sprintf("%.4e",$Epg3[$i]), 
		"\t",sprintf("%.4e",$Pg3[$i]), 
		"\t",sprintf("%.4e",$Tg3[$i]), 
		"\t",sprintf("%.4e",$CO23[$i]), 
		"\t",sprintf("%.4e",$H2O3[$i]), 
		"\t",sprintf("%.4e",$Vg3[$i]), 
		"\t",sprintf("%.4e",$Vs3[$i]), 
		"\t",sprintf("%.4e",$Rops3[$i]), 
		"\t",sprintf("%.4e",$CO2ExitBC3[$i]), 
		"\t",sprintf("%.4e",$CO2ExitBC3Kg[$i]), 
		"\t",sprintf("%.4e",$R2NHExitBC3[$i]), 
		"\t",sprintf("%.4e",$R2NCO2ExitBC3[$i]), 
		"\t",sprintf("%.4e",$R2NH2ExitBC3[$i]), 
		"\t",sprintf("%.4e",$HCO3ExitBC3[$i]), 
		"\t",sprintf("%.4e",$H2OabsExitBC3[$i]), 
		"\n";
}
#Get the CO2 exit mole/s
#  read the document in PostProcessing1MW.docx

#BC4, side outlet, at about Y=4.77, picking one point might be good enough
$xx=$xs4[0];
$yy=0.5*($ys4[0]+$ys4[1]);
print "For BC4, cencer point: $xx, $yy\n";
#What post_mfix takes is 2-based numbers (1 is reserved for the ghost cell)
#so we need to +2 for all 6 numbers!

$varName="ROP_s";
$index="1";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@Rops4,$varName,1); 
$varName="T_g";
$index="";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@Tg4,$varName);
$varName="EP_g";
$index="";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@Epg4,$varName);
$varName="P_g";
$index="";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@Pg4,$varName);
$varName="X_g";
$index="1";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@N24,$varName,$index);
$index="2";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@CO24,$varName,$index);
$index="3";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@H2O4,$varName,$index);
$index="4";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@O24,$varName,$index);
$varName="U_g";
$index="";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@Ug4,$varName);
$varName="U_s";
$index="1";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@Us4,$varName,$index);
$varName="MFLOW_sx";
$index1="1";
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@mflowsx4,$varName,$index);
#now solids
$varName="X_s";
$index1="1";
$index2="2";
#R2NH
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@X_s_1_2,$varName,$index1,$index2);
$index1="1";
$index2="3";
#R2NCO2-
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@X_s_1_3,$varName,$index1,$index2);
$index1="1";
$index2="4";
#R2NH2_
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@X_s_1_4,$varName,$index1,$index2);
$index1="1";
$index2="5";
#HCO3-
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@X_s_1_5,$varName,$index1,$index2);
$index1="1";
$index2="6";
#H2O (abs)
GetTimedQOIAtBC($runname,$xis4[0],$xis4[1],$yjs4[0],$yjs4[1],\@Times, \@X_s_1_6,$varName,$index1,$index2);

$BC4Length=($ys4[1]-$ys4[0]);
print FILEOUT "BC#4, x=$xx, y=$yy, $BC4Length \n";
print FILEOUT "Time\tEP_g\t       Pg\t        Tg\t        CO2\t        H2O\t       U_g\t        U_s\t        ROP_s\t        CO2(mole/s)\tCO2(kg/s)";
print FILEOUT "\tR2NH\t        R2NCO2-\t        R2NH2+\t        HCO3-\t        H2O(abs)\n";
for $i (0..$#Times)
{
	$MoleRate=$BC4Length*$ZLENGTH*$Ug4[$i]*$Epg4[$i]*($Pg4[$i]*273.15/$Tg4[$i]/101340)/0.0224; #mole/s
	$dummy=$N24[$i]+$CO24[$i]+$H2O4[$i]+$O24[$i];
	$TotalVolume=$N24[$i]/28.0+$CO24[$i]/44.0+$H2O4[$i]/18.0+$O24[$i]/32.0;
	$CO2ExitBC4[$i]=$MoleRate/$TotalVolume*$CO24[$i]/44.0; #mole/s, CO2 share of mole/s
	$H2OExitBC4[$i]=$MoleRate/$TotalVolume*$H2O4[$i]/18.0;
	$CO2ExitBC4Kg[$i]=$CO2ExitBC4[$i]*0.044; #kg/s
	$H2OExitBC4Kg[$i]=$H2OExitBC4[$i]*0.018; #kg/s
	$R2NHExitBC4[$i]=$BC4Length*$ZLENGTH*$Us4[$i]*$Rops4[$i]*$X_s_1_2[$i]; #mole/s
	$dummy=$mflowsx4[$i]*$X_s_1_2[$i]; #mole/s
	$R2NHExitBC4[$i]=$dummy; #20140904, R2NHExitBC4 ~= dummy 
	$R2NCO2ExitBC4[$i]=$BC4Length*$ZLENGTH*$Us4[$i]*$Rops4[$i]*$X_s_1_3[$i]; #mole/s
	$R2NH2ExitBC4[$i]=$BC4Length*$ZLENGTH*$Us4[$i]*$Rops4[$i]*$X_s_1_4[$i]; #mole/s
	$HCO3ExitBC4[$i]=$BC4Length*$ZLENGTH*$Us4[$i]*$Rops4[$i]*$X_s_1_5[$i]; #mole/s
	$H2OabsExitBC4[$i]=$BC4Length*$ZLENGTH*$Us4[$i]*$Rops4[$i]*$X_s_1_6[$i]; #mole/s
	if($Times[$i]>$maxTime-100)
	{
	#print FILEOUT "DELETE $H2OExitBC4[$i]=$BC4Length*$ZLENGTH*$Ug4[$i]*$Epg4[$i]*$H2O4[$i]*($Pg4[$i]*273.15/$Tg4[$i]/101340)/0.0224\n";
	}
	print FILEOUT sprintf("%.3f",$Times[$i]), 
		"\t",sprintf("%.4e",$Epg4[$i]), 
		"\t",sprintf("%.4e",$Pg4[$i]), 
		"\t",sprintf("%.4e",$Tg4[$i]), 
		"\t",sprintf("%.4e",$CO24[$i]), 
		"\t",sprintf("%.4e",$H2O4[$i]), 
		"\t",sprintf("%.4e",$Ug4[$i]), 
		"\t",sprintf("%.4e",$Us4[$i]),
		"\t",sprintf("%.4e",$Rops4[$i]), 
		"\t",sprintf("%.4e",$CO2ExitBC4[$i]), 
		"\t",sprintf("%.4e",$CO2ExitBC4Kg[$i]), 
		"\t",sprintf("%.4e",$R2NHExitBC4[$i]), 
		"\t",sprintf("%.4e",$R2NCO2ExitBC4[$i]), 
		"\t",sprintf("%.4e",$R2NH2ExitBC4[$i]), 
		"\t",sprintf("%.4e",$HCO3ExitBC4[$i]), 
		"\t",sprintf("%.4e",$H2OabsExitBC4[$i]), 
		"\n";
}
print FILEOUT "Gas and Solid Exit at Combined BCs\n";
print FILEOUT "Time\t   CO2(mole/s)\tCO2(kg/s)\tR2NH\t        R2NCO2-\t        R2NH2+\t        HCO3-\t        H2O(abs)\n";
for $i (0..$#Times)
{
	$CO2ExitBC=$CO2ExitBC3[$i]+$CO2ExitBC4[$i];
	$CO2ExitBCKg=$CO2ExitBC3Kg[$i]+$CO2ExitBC4Kg[$i];
	$H2OExitBC=$H2OExitBC3[$i]+$H2OExitBC4[$i];
	$H2OExitBCKg=$H2OExitBC3Kg[$i]+$H2OExitBC4Kg[$i];
	$R2NHExitBC= $R2NHExitBC3[$i]+ $R2NHExitBC4[$i];
	$R2NCO2ExitBC= $R2NCO2ExitBC3[$i]+ $R2NCO2ExitBC4[$i];
	$R2NH2ExitBC= $R2NH2ExitBC3[$i]+ $R2NH2ExitBC4[$i];
	$HCO3ExitBC= $HCO3ExitBC3[$i]+ $HCO3ExitBC4[$i];
	$H2OabsExitBC= $H2OabsExitBC3[$i]+ $H2OabsExitBC4[$i];
	print FILEOUT sprintf("%.3f",$Times[$i]), 
		"\t",sprintf("%.4e",$CO2ExitBC), 
		"\t",sprintf("%.4e",$CO2ExitBCKg), 
		"\t",sprintf("%.4e",$R2NHExitBC), 
		"\t",sprintf("%.4e",$R2NCO2ExitBC), 
		"\t",sprintf("%.4e",$R2NH2ExitBC), 
		"\t",sprintf("%.4e",$HCO3ExitBC), 
		"\t",sprintf("%.4e",$H2OabsExitBC), 
		"\n";
}
print FILEOUT "------------------------------------------------------------\n";
print FILEOUT "QOIs for UQ study\n";
$ts1=$maxTime-100;
$ts2=$maxTime;
$coord="Y";
if($ts1<0)
{
	$ts1=0;
}
if($ts1<150) #if ts2<200 already kicked out
{
	$ts1=150;
}
$AmineAvg=0.0;
$AminePctAvg=0.0;
$AvgCount=0;
$AvgCO2ExitBC3Kg=0;
$AvgCO2ExitBC4Kg=0;
$AvgH2OExitBC3Kg=0;
$AvgH2OExitBC4Kg=0;
for $i (0..$#Times)
{
	if($Times[$i]>$ts1)
	{
		$AvgCount++;
		$AmineAvg+=$R2NHExitBC4[$i];
		$AminePctAvg+=$X_s_1_2[$i];
		$AvgCO2ExitBC3Kg+=$CO2ExitBC3Kg[$i];
		$AvgCO2ExitBC4Kg+=$CO2ExitBC4Kg[$i];
		$AvgH2OExitBC3Kg+=$H2OExitBC3Kg[$i];
		$AvgH2OExitBC4Kg+=$H2OExitBC4Kg[$i];
	}
}
$AmineAvg=$AmineAvg/$AvgCount;
$AminePctAvg=$AminePctAvg/$AvgCount;
$AvgCO2ExitBC3Kg/=$AvgCount;
$AvgCO2ExitBC4Kg/=$AvgCount;
$AvgH2OExitBC3Kg/=$AvgCount;
$AvgH2OExitBC4Kg/=$AvgCount;

$CO2AdsRate=$CO2-$AvgCO2ExitBC3Kg;
$CO2AdsFraction=$CO2AdsRate/$CO2;
$CO2AdsRate2=$CO2-$AvgCO2ExitBC3Kg-$AvgCO2ExitBC4Kg;
$CO2AdsFraction2=$CO2AdsRate2/$CO2;

$H2OAdsRate=$H2O-$AvgH2OExitBC3Kg;
$H2OAdsFraction=$H2OAdsRate/$H2O;
$H2OAdsRate2=$H2O-$AvgH2OExitBC3Kg-$AvgH2OExitBC4Kg;
$H2OAdsFraction2=$H2OAdsRate2/$H2O;

#print FILEOUT "DELETE, H2OAdsRate2=$H2OAdsRate2, = H2O $H2O, - BC3 $AvgH2OExitBC3Kg- BC4 $AvgH2OExitBC4Kg\n";

$bedHeight=PostMfix::GetBedHeight($mfixfile,$coord,0.95,$ts1,$ts2);
print FILEOUT " Counting CO2 leaving side exit\n";
print FILEOUT "\tCO2 adsorption rate (kg/s) $CO2AdsRate\n";
print FILEOUT "\tCO2 adsorption fraction $CO2AdsFraction\n";
print FILEOUT "\tH2O adsorption rate (kg/s) $H2OAdsRate\n";
print FILEOUT "\tH2O adsorption fraction $H2OAdsFraction\n";
print FILEOUT " Not counting CO2 leaving side exit\n";
print FILEOUT "\tCO2 adsorption rate (kg/s) $CO2AdsRate2\n";
print FILEOUT "\tCO2 adsorption fraction $CO2AdsFraction2\n";
print FILEOUT "\tH2O adsorption rate (kg/s) $H2OAdsRate2\n";
print FILEOUT "\tH2O adsorption fraction $H2OAdsFraction2\n";
print FILEOUT "\tAmine leaving side exit $AmineAvg (kg/s)\n";
print FILEOUT "\tAmine molar fraction at side exit $AminePctAvg\n";
print FILEOUT "\tBed height (EP_g<=0.95) is $bedHeight\n";
print FILEOUT "$runname\t$CO2AdsRate\t$CO2AdsFraction\t$CO2AdsRate2\t$CO2AdsFraction2\t$AmineAvg\t$AminePctAvg\t$bedHeight\n";
print FILEOUT "------------------------------------------------------------\n";
close(FILEOUT);
#Get time averaging variable vs. Y for a few QOIs
my(@QOINames);
my(@QOIs);
my(@QOIIndex1);
my(@QOIIndex2);
$QOINames[0]="CO2";
$QOIs[0]="X_g";
$QOIIndex1[0]="2";
$QOIIndex2[0]="";
$QOINames[1]="H2O";
$QOIs[1]="X_g";
$QOIIndex1[1]="3";
$QOIIndex2[1]="";
$QOINames[2]="GasTemperature";
$QOIs[2]="T_g";
$QOIIndex1[2]="";
$QOIIndex2[2]="";
$QOINames[3]="VoidageFraction";
$QOIs[3]="EP_g";
$QOIIndex1[3]="";
$QOIIndex2[3]="";
#Solids
$QOINames[4]="R2NH";
$QOIs[4]="X_s";
$QOIIndex1[4]="1";
$QOIIndex2[4]="2";
$QOINames[5]="R2NCO2-";
$QOIs[5]="X_s";
$QOIIndex1[5]="1";
$QOIIndex2[5]="3";
$QOINames[6]="R2NH2+";
$QOIs[6]="X_s";
$QOIIndex1[6]="1";
$QOIIndex2[6]="4";
$QOINames[7]="HCO3-";
$QOIs[7]="X_s";
$QOIIndex1[7]="1";
$QOIIndex2[7]="5";
$QOINames[8]="H2O(abs)";
$QOIs[8]="X_s";
$QOIIndex1[8]="1";
$QOIIndex2[8]="6";
GetTimeAvgQOIs_OneCoord($mfixfile,$coord,\@QOINames,\@QOIs,\@QOIIndex1,\@QOIIndex2,$ts1,$ts2,$outFile);
die "For now";

$TotalCO2Adsorb=0.0;
	
$TimeAvgTemp=0;
$TimeAvgPDT3820=0;
$TimeAvgPDT3860=0;
$TimeAvgCount=0;

print FILEOUT "For All points:\n";
print FILEOUT "Time\tTe3965\t        Te3962\t        CO2_exit_mass\tCO2_exit_volume\tCO2_Ads(slpm)\tCO2_Ads(mole)\tP1\t        P2\t        P3\t        P3820\t        P3860";
print FILEOUT "\t        Avg_GasTemp";
print FILEOUT "\tTs3965\t        Ts3962\t        Avg_SolidTemp\tTemp-Diff\n";
for $i (0..$#Times)
{
	$dt=1.0;
	if($i>0)
	{
		$dt=$Times[$i]-$Times[$i-1];
	}
	print FILEOUT $Times[$i];
	for $pp (0..1) #temperature
	{
		print FILEOUT "\t", sprintf("%.5e",$pg[$pp][$i]);
	}
	$AvgTemp=0.5*($pg[0][$i]+$pg[1][$i]);
	print FILEOUT "\t", sprintf("%.5e",$pg[3][$i]); #3=CO2 by mass
	$totalVolume=$pg[2][$i]/28.0+$pg[3][$i]/44.0+$pg[4][$i]/18.0;
	if($totalVolume<=0)
	{
		print "$i, $Times[$i], $pg[2][$i], $pg[3][$i], $pg[4][$i]\n";
		next;
	}
	$CO2byVolume=$pg[3][$i]/44.0/$totalVolume;
	$CO2AdsorptionRate=$flowrate*($CO2InletByVolume-$CO2byVolume);
	$CO2AdsorptionRate=$CO2AdsorptionRate/(1.0-$CO2byVolume); #20140130 fix?
	print FILEOUT "\t", sprintf("%.5e",$CO2byVolume);
	print FILEOUT "\t", sprintf("%.5e",$CO2AdsorptionRate);
	$TotalCO2Adsorb=$TotalCO2Adsorb+$CO2AdsorptionRate*$dt;
	$TotalCO2Moles=$TotalCO2Adsorb/60/22.711*(101340/100000)*(273.15/293.0);
	print FILEOUT "\t", sprintf("%.5e",$TotalCO2Moles);
	#pressure and pressure drop
	for $pp (5..7)
	{
		print FILEOUT "\t", sprintf("%.5e",$pg[$pp][$i]);
	}
	$dp3820=$pg[5][$i]-$pg[6][$i];
	$dp3860=$pg[6][$i]-$pg[7][$i];
	print FILEOUT "\t", sprintf("%.5e",$dp3820);
	print FILEOUT "\t", sprintf("%.5e",$dp3860);
	print FILEOUT "\t", sprintf("%.5e",$AvgTemp);
	$AvgSolidTemp=0.5*($pg[8][$i]+$pg[9][$i]);
	for $pp (8..9) #solid temperature
	{
		print FILEOUT "\t", sprintf("%.5e",$pg[$pp][$i]);
	}
	print FILEOUT "\t", sprintf("%.5e",$AvgSolidTemp);
	print FILEOUT "\t", sprintf("%.5e",$AvgSolidTemp-$AvgTemp);
	print FILEOUT "\n";
	if($Times[$i]<$TimeExp)
	{
		$TotalCO2MolesAtExpTime=$TotalCO2Moles;
		$TimeAvgTemp+=$AvgTemp;
		$TimeAvgPDT3820+=$dp3820;
		$TimeAvgPDT3860+=$dp3860;
		$TimeAvgCount++;
	}	
	if($Total_Exp>0)
	{
		if($TotalCO2Moles>0.25*$Total_Exp and $T_25==0)
		{
			$T_25=$Times[$i];
		}
		if($TotalCO2Moles>0.5*$Total_Exp and $T_50==0)
		{
			$T_50=$Times[$i];
		}
		if($TotalCO2Moles>0.75*$Total_Exp and $T_75==0)
		{
			$T_75=$Times[$i];
		}
	}
}

$TimeAvgTemp/=$TimeAvgCount;
$TimeAvgPDT3820/=$TimeAvgCount;
$TimeAvgPDT3860/=$TimeAvgCount;
print FILEOUT "-------------------------------------------------------------------------------\n";
print FILEOUT "At Experiment end time T=$TimeExp, CO2 adsorption in moles $TotalCO2MolesAtExpTime\n";
print FILEOUT "At 110% Experiment end time, CO2 adsorption in moles ", $TotalCO2Moles, "\n"; 
print FILEOUT "Average: bed temperature $TimeAvgTemp, PDT3820 $TimeAvgPDT3820, PDT3860 $TimeAvgPDT3860\n";
if($Total_Exp>0) {
	print FILEOUT "---------------------------------------------------------------------------------\n";
	print FILEOUT "CO2_E_Mole\tCO2_S_Mole\tT_25%\tT_50%\tT_75%\tBedTemp\tPDT3820\tPDT3860\n";
	print FILEOUT sprintf("%.3f", $Total_Exp);
	print FILEOUT "\t        ",sprintf("%.3f", $TotalCO2MolesAtExpTime);
	print FILEOUT "\t        ", sprintf("%.2f", $T_25),  "\t", sprintf("%.2f", $T_50),  "\t", sprintf("%.2f", $T_75);  
	print FILEOUT "\t", sprintf("%.2f",$TimeAvgTemp), "\t",sprintf("%.2f",$TimeAvgPDT3820);
	print FILEOUT "\t",sprintf("%.2f",$TimeAvgPDT3860), "\n";
}
close(FILEOUT);
1;

#This is for 2D: $k1==1
#  Taking an averaged value in spatial term: i=(i1,i2), j=(j1,j2)
#  Good for getting the QOI value of a position where it does not fall in any specific cell (i, j).
#Input
#  mfixfile
#  varName
#  index
#  i1,i2,j1,j2,cx1,cx2,cy1,cy2
#Output
#  @Times
#  @QOIs
#Does not work for Solid Phase Species because it asks one more index: solid phase index  
# BuildPostMfixVarAtPointTimes2() does not work for extra parameter 
sub GetTimedQOI
{
  my ($mfixfile,$varName,$index,$i1,$i2,$j1,$j2,$cx1,$cx2,$cy1,$cy2,$TIMES, $QOIS) = @_;
 $me=`whoami`;
 chop($me);
 $myDir="/tmp/$me";
#now get all 4 output
 $postmfixFile="$myDir/pp32v11.get";
 $outputFile11="$myDir/pp32v11.out";
 $k1=1;
 PostMfix::BuildPostMfixVarAtPointTimes2($mfixfile,$postmfixFile,$outputFile11,$time1,$time2,$i1,$j1,$k1,$varName,$index); 
 if(-e $outputFile11)
 {
	`rm $outputFile11`;
 }	 
 `post_mfix < $postmfixFile`;

 $postmfixFile="$myDir/pp32v12.get";
 $outputFile12="$myDir/pp32v12.out";
 PostMfix::BuildPostMfixVarAtPointTimes2($mfixfile,$postmfixFile,$outputFile12,$time1,$time2,$i1,$j2,$k1,$varName,$index); 
 if(-e $outputFile12)
 {
	`rm $outputFile12`;
 } 
 `post_mfix < $postmfixFile`;

 $postmfixFile="$myDir/pp32v21.get";
 $outputFile21="$myDir/pp32v21.out";
 PostMfix::BuildPostMfixVarAtPointTimes2($mfixfile,$postmfixFile,$outputFile21,$time1,$time2,$i2,$j1,$k1,$varName,$index); 
 if(-e $outputFile21)
 {
 	`rm $outputFile21`;
 } 
 `post_mfix < $postmfixFile`;
 $postmfixFile="$myDir/pp32v22.get";
 $outputFile22="$myDir/pp32v22.out";
 PostMfix::BuildPostMfixVarAtPointTimes2($mfixfile,$postmfixFile,$outputFile22,$time1,$time2,$i2,$j2,$k1,$varName,$index); 
 if(-e $outputFile22)
 {
 	`rm $outputFile22`;
 } 
 `post_mfix < $postmfixFile`;
  #now process the 4 files
 my(@v11,@v12,@v21,@v22);
 PostMfix::ReadFile2($outputFile11,\$varName1, \$varName2, \@Times, \@v11);
 PostMfix::ReadFile2($outputFile12,\$varName1, \$varName2, \@Times, \@v12);
 PostMfix::ReadFile2($outputFile21,\$varName1, \$varName2, \@Times, \@v21);
 PostMfix::ReadFile2($outputFile22,\$varName1, \$varName2, \@Times, \@v22);
 #print "Time\tv11\t        v12\t        v21\t        v22\t        Var\n";
 $c11=$cx1*$cy1;
 $c12=$cx1*$cy2;
 $c21=$cx2*$cy1;
 $c22=$cx2*$cy2;
 $csum=$c11+$c12+$c21+$c22;
 #print "\t", sprintf("%.5e",$c11);
 for $i (0..$#Times)
 {
 	$var=0.0;
 	$var+=$v11[$i]*$c11;
	$var+=$v12[$i]*$c12;
	$var+=$v21[$i]*$c21;
	$var+=$v22[$i]*$c22;
	#print $Times[$i];
	$varAtTime[$i]=$var;
 }
 @$TIMES=@Times;
 @$QOIS=@varAtTime;
}

#  Taking an averaged value at a specified BC for a 2D simulation
#Input
#  mfixfile
#  i1,i2,j1,j2
#  if(i1=i2), the BC is vertical, at a given X_i=i1
#  if(j1=j2), the BC is horizontal, at a given Y_j=j1
#  varName
#  index1, optional
#  index2, optional
#Output
#  @Times
#  @QOIs

#For X_s, solid phase #1, species #1
#Input
#  mfixfile
#  varName
#  index1
#  index2
#  i1,i2,j1,j2,cx1,cx2,cy1,cy2
#Output
#  @Times
#  @QOIs
#Does not work for Solid Phase Species because it asks one more index: solid phase index  
# BuildPostMfixVarAtPointTimes2() does not work for extra parameter 
sub GetTimedQOI2Index
{
  my ($mfixfile,$varName,$index1,$index2,$i1,$i2,$j1,$j2,$cx1,$cx2,$cy1,$cy2,$TIMES, $QOIS) = @_;
 $me=`whoami`;
 chop($me);
 $myDir="/tmp/$me";
#now get all 4 output
 $postmfixFile="$myDir/pp32v11.get";
 $outputFile11="$myDir/pp32v11.out";
 $k1=1;
 PostMfix::BuildPostMfixVarAtPointTimes2Index2($mfixfile,$postmfixFile,$outputFile11,$time1,$time2,$i1,$j1,$k1,$varName,$index1, $index2); 
 if(-e $outputFile11)
 {
	`rm $outputFile11`;
 }	 
 `post_mfix < $postmfixFile`;

 $postmfixFile="$myDir/pp32v12.get";
 $outputFile12="$myDir/pp32v12.out";
 PostMfix::BuildPostMfixVarAtPointTimes2Index2($mfixfile,$postmfixFile,$outputFile12,$time1,$time2,$i1,$j2,$k1,$varName,$index1, $index2); 
 if(-e $outputFile12)
 {
	`rm $outputFile12`;
 } 
 `post_mfix < $postmfixFile`;

 $postmfixFile="$myDir/pp32v21.get";
 $outputFile21="$myDir/pp32v21.out";
 PostMfix::BuildPostMfixVarAtPointTimes2Index2($mfixfile,$postmfixFile,$outputFile21,$time1,$time2,$i2,$j1,$k1,$varName,$index1, $index2); 
 if(-e $outputFile21)
 {
 	`rm $outputFile21`;
 } 
 `post_mfix < $postmfixFile`;
 $postmfixFile="$myDir/pp32v22.get";
 $outputFile22="$myDir/pp32v22.out";
 PostMfix::BuildPostMfixVarAtPointTimes2Index2($mfixfile,$postmfixFile,$outputFile22,$time1,$time2,$i2,$j2,$k1,$varName,$index1, $index2); 
 if(-e $outputFile22)
 {
 	`rm $outputFile22`;
 } 
 `post_mfix < $postmfixFile`;
  #now process the 4 files
 my(@v11,@v12,@v21,@v22);
 PostMfix::ReadFile2($outputFile11,\$varName1, \$varName2, \@Times, \@v11);
 PostMfix::ReadFile2($outputFile12,\$varName1, \$varName2, \@Times, \@v12);
 PostMfix::ReadFile2($outputFile21,\$varName1, \$varName2, \@Times, \@v21);
 PostMfix::ReadFile2($outputFile22,\$varName1, \$varName2, \@Times, \@v22);
 #print "Time\tv11\t        v12\t        v21\t        v22\t        Var\n";
 $c11=$cx1*$cy1;
 $c12=$cx1*$cy2;
 $c21=$cx2*$cy1;
 $c22=$cx2*$cy2;
 $csum=$c11+$c12+$c21+$c22;
 #print "\t", sprintf("%.5e",$c11);
 for $i (0..$#Times)
 {
 	$var=0.0;
 	$var+=$v11[$i]*$c11;
	$var+=$v12[$i]*$c12;
	$var+=$v21[$i]*$c21;
	$var+=$v22[$i]*$c22;
	#print $Times[$i];
	$varAtTime[$i]=$var;
 }
 @$TIMES=@Times;
 @$QOIS=@varAtTime;
}

#  Taking an averaged value at a specified BC for a 2D simulation
#Input
#  mfixfile
#  i1,i2,j1,j2
#  if(i1=i2), the BC is vertical, at a given X_i=i1
#  if(j1=j2), the BC is horizontal, at a given Y_j=j1
#  varName
#  index1, optional
#  index2, optional
#Output
#  @Times
#  @QOIs
sub GetTimedQOIAtBC
{
  my ($mfixfile,$i1,$i2,$j1,$j2,$TIMES, $QOIS,$varName,$index1,$index2) = @_;
  print "GetTimedQOIAtBC for $varName, Index=$index1,$index2, ";
  $me=`whoami`;
  chop($me);
  $myDir="/tmp/$me";
  $postmfixFile="$myDir/pp32v11.get";
  $outputFile11="$myDir/pp32v11.out";
  if($i1 eq $i2)
  {
     print "for a vertical BC at X_index=$i1, Y_index=$j1 to $j2\n";
  }
  elsif($j1 eq $j2)
  {
     print "for a horizontal BC at Y_index=$j1, X_index=$i1 to $i2\n";
  }
  else
  {
	print "ERROR $i1 != $i2, and $j1 != $j2\n";
  }

  PostMfix::BuildPostMfixVarAvgSpatialAtTimes($mfixfile,$postmfixFile,$outputFile11,$time1,$time2,$i1,$i2,$j1,$j2,1,1,$varName,$index1,$index2); 
  if(-e $outputFile11)
  {
	`rm $outputFile11`;
  }	 
  `post_mfix < $postmfixFile`;
  my(@v11);
  PostMfix::ReadFile2($outputFile11,\$varName1, \$varName2, \@Times, \@varAtTime);
  `rm $outputFile11`;
  @$TIMES=@Times;
  @$QOIS=@varAtTime;
}

#what is this for
#Get QOI vs. Y, averaged over X and time
#Input:
#	outputFile:	append to the file
sub GetTimeAvgQOIs_OneCoord
{
  my($mfixfile,$coord,$qoinames,$qois,$qoi_index1,$qoi_index2,$time1,$time2, $outputFile) = @_;
  my @QOINames=@$qoinames;
  my @QOIs=@$qois;
  my @QOIIndex1=@$qoi_index1;
  my @QOIIndex2=@$qoi_index2;
  print "GetTimeAvgQOIs vs $coord\n";
  print "mfixfile=$mfixfile, for the following QOIs:\n";
  for $i (0..$#QOIs)
  {
	print "     $QOIs[$i], index $QOIIndex1[$i], $QOIIndex2[$i]\n";
  }
  print "Time: $time1 to $time2\n";
  if($time1<0)
  {
	$time1=0;
  }
  print "Output file: $outputFile\n";
 
  my(@variables);
  my(@times);

  $me=`whoami`;
  chop($me);
  $myDir="/tmp/$me";
  $file1="$myDir/dummy.get";
  $file1out="$myDir/dummy.out";
  for $j (0..$#QOIs)
  {
    print "For $QOIs[$j]\n";
    if(length($QOIIndex2[$j])>0)
    {
    PostMfix::BuildPostMfixInputTAvg2Index($mfixFile,$file1,$file1out,$time1,$time2,$coord,$QOIs[$j],$QOIIndex1[$j],$QOIIndex2[$j]);
    }
    else
    {
    PostMfix::BuildPostMfixInputTAvg2($mfixFile,$file1,$file1out,$time1,$time2,$coord,$QOIs[$j],$QOIIndex1[$j]);
    }
    if(-e $file1out)
    {
        print "post_mfix output file ", $file1out, " already exists. Deleted!\n";
	`rm -f $file1out`;
    }
    `post_mfix<$file1`;
    open(FILEIN, $file1out);
    $start=0;
    $i=0;
    while (<FILEIN>)
    {
      chop($_); #delete the ending \n
      $_ =~ s/^\s+|\s+$//g; #delete all starting white space
      ($x,$y)=split(/\s+/,$_);
      #print "x=$x END, y=$y END\n";
      if( ($y eq $QOIs[$j]) and ($x eq $coord))
      {
	#print "starting the read $_\n";
	$start=1;
      } 
      elsif($start==1)
      {
	$times[$i]=$x;
	$variables[$j][$i]=$y;
	#print "time vs variable: $times[$i], $variables[$j][$i], \n";
	$i++;
      } 
    }
    close(FILEIN);
  }

  open(FILEOUT,">>$outputFile");
  print FILEOUT "\nSelected QOIs distribution along $coord, averaged over X and averaged over time=$time1 to $time2\n";
  print FILEOUT "$coord\t";
  for $j (0..$#QOIs)
  {
     if($j==0)
     {
	print FILEOUT "        ";
     }
     if($j>0 and length($QOINames[$j-1])<8)
     {
	print FILEOUT "        ";
     }
     print FILEOUT $QOINames[$j], "\t";
  } 
  print FILEOUT "\n";
  for $i (0..$#times)
  {
    print FILEOUT sprintf("%.4e", $times[$i]), "\t";
    for $j (0..$#QOIs)
    {
       print FILEOUT sprintf("%.4e", $variables[$j][$i]), "\t";
    }
    print FILEOUT "\n";
  }
  close(FILEOUT);
}
