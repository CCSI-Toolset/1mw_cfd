#!/usr/bin/env perl
for $i (1..351)
{
  $case="Case".sprintf("%.3d", $i);
  print "Post-processing $case:  ";
  $result="result.".sprintf("%.3d", $i);
  $caseresult=$case."/".$result;
  $time=0;
  if(-f $caseresult)
  {
	$time=`egrep "Time from" $caseresult |cut -f3 -d'o'`;
  }
  $logtime=-100;
  @logfiles=`ls $case/*LOG`;
  if($#logfiles>-1)
  {
  	$logtime=`egrep -w t= $case/*LOG|tail -n 1|cut -f2 -d=|cut -f1 -d'.'`;
	print "logtime = $logtime\n";
  }
#need to have the two commands inside the same '', otherwise, ../ModifyMfixInput will not be executed there!
  if($time > 598)
  {
	print "$caseresult already done $time\n";
  }
  else
  {
	print "result time < 600, checking,  resulttime=$time, logtime=$logtime, ";
	if($logtime > ($time+5))
	{
		print "Regenerating ...\n";
  	#`cd $case; PP1MW.pl -o $result`;
  	}
	else
	{
		print "No doing it\n";
	}
  }
}
