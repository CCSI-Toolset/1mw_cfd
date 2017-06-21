#!/usr/bin/env perl
#Good for only UQ4, for new Jeff's mfix.dat format
#Make sure CO2+N2+H2O=1.0
#variables: flowrate, co2, n2, h2o, te3920, coil temperature, amine
#$sio2=1.0-$amine;
$curtFile="./UQ_351_design_32D_1MW.txt";
$myDir=`pwd`;
$myDir=substr($myDir,rindex($myDir,"Case")+4);
chop($myDir);
print $myDir,"END\n";
print "Directory=",$myDir,"END\n";
my(@Amine_pct,@partSize);
my(@Delta_H_x,@Delta_S_x,@Delta_H_xpp,@zeta_x);
my(@Delta_H_a,@Delta_S_a,@Delta_H_app,@zeta_a);
my(@Delta_H_b,@Delta_S_b,@Delta_H_bpp,@zeta_b);
if(-f $curtFile) {
  open(FILEIN, $curtFile);
  $i=0;
  while(<FILEIN>)
  {
	($t2,$t3,$t4,$t5,$t6,$t7,$t8,$t9,$t10,$t11,$t12,$t13,$t14,$t15)=split(" ");	
	$Amine_pct[$i]=$t2;
	$Delta_H_x[$i]=$t3;
	$Delta_S_x[$i]=$t4;
	$Delta_H_xpp[$i]=$t5;
	$zeta_x[$i]=$t6;
	$Delta_H_a[$i]=$t7;
	$Delta_S_a[$i]=$t8;
	$Delta_H_app[$i]=$t9;
	$zeta_a[$i]=$t10;
	$Delta_H_b[$i]=$t11;
	$Delta_S_b[$i]=$t12;
	$Delta_H_bpp[$i]=$t13;
	$zeta_b[$i]=$t14;
	$partSize[$i]=$t15;
	$i++;
  }
  close(FILEIN);
}
else
{
 die "File $curtFile does not exist";
}
print "There are $#Amine_pct+1 cases\n";

#skip the first one, which is the label row
for $i (1..351)
{
  $mfixDir="Case".sprintf("%.3d", $i);
  $RunName="Case".sprintf("%.3d", $i);
  print $mfixDir, "\n";
  `mkdir $mfixDir`;
  $RunFile=$mfixDir."/R".$RunName;
  `cp RunCase $RunFile`; 
  #Read mfix.mod and write the modified version to dummy0
  open(FILEIN,"mfix.mod");
  open(FILEOUT,">dummy0");
  $sio2=1.0-$Amine_pct[$i];
  while (<FILEIN>) {
      $_ =~ s/RunName/$RunName/g;
      $_ =~ s/VALUE_DH_x/$Delta_H_x[$i]/g;
      $_ =~ s/VALUE_DS_x/$Delta_S_x[$i]/g;
      $_ =~ s/VALUE_E_x/$Delta_H_xpp[$i]/g;
      $_ =~ s/VALUE_LOGZETA_x/$zeta_x[$i]/g;
      $_ =~ s/VALUE_DH_b/$Delta_H_b[$i]/g;
      $_ =~ s/VALUE_DS_b/$Delta_S_b[$i]/g;
      $_ =~ s/VALUE_E_b/$Delta_H_bpp[$i]/g;
      $_ =~ s/VALUE_LOGZETA_b/$zeta_b[$i]/g;
      $_ =~ s/VALUE_DH_a/$Delta_H_a[$i]/g;
      $_ =~ s/VALUE_DS_a/$Delta_S_a[$i]/g;
      $_ =~ s/VALUE_E_a/$Delta_H_app[$i]/g;
      $_ =~ s/VALUE_LOGZETA_a/$zeta_a[$i]/g;
      $_ =~ s/V_amine/$Amine_pct[$i]/g;
      $_ =~ s/V_sio2/$sio2/g;
      $_ =~ s/VALUE_partsize/$partSize[$i]/g;
      print FILEOUT;
  } 
  close(FILEIN);
  close(FILEOUT);
  `mv dummy0 $mfixDir/mfix.dat`;
}
