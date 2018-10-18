#!/usr/bin/perl
# --------------------------------------------------------------------
# commonFunctions.pm
#
# $Id: commonFunctions.pm,v 1.30 2018/10/15 05:01:01 db2admin Exp db2admin $
#
# Description:
# Package cotaining common code.
#   Subroutines included:
#     displayMinutes 
#     getCurrentTimestamp 
#     timeAdd 
#     timeAdj
#     timeDiff 
#     commonVersion 
#     getOpt 
#     getOpt_form 
#     trim 
#     ltrim 
#     rtrim
#     myDate 
#     processDirectory 
#     localDateTime 
#     convertToTimestamp 
#
# Usage:
#   trim()
#     $x = trim($y) # strip blanks from the start and end of a string
#
#   timeAdj(TS,minutes)
#     $x = timeAdj('2016.09.19 08:05:01','-15')   # returns a value of '2016.09.19 07:50:01'
#
#   ltrim()
#     $x = ltrim($y) # strip blanks from the start of a string
#
#   rtrim()
#     $x = rtrim($y) # strip blanks from the end of a string
#
#   myDate()
#     Usage: myDate [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]
#         and it will return an array containg the following elements:
#              $DD,$MM,$YY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW
#
#              i.e. a call of 
#
#                  @dateReturn = myDate('Date:20140728');
#                  for (my $i=0; $i <= $#dateReturn; $i++) {
#                    print "Returned Value for $myDate_ReturnDesc[$i] is: $dateReturn[$i]\n";
#                  }
#
#                  Returned Value for Day of Month is: 28
#                  Returned Value for Month is: 07
#                  Returned Value for Year is: 2014
#                  Returned Value for Day Suffix is: th
#                  Returned Value for Month Name is: July
#                  Returned Value for Number of days since Base Date is: 18105
#                  Returned Value for Base Date is: 1965
#                  Returned Value for EOM is: N
#                  Returned Value for EOY is: N
#                  Returned Value for EOFY is: N
#                  Returned Value for BOM is: N
#                  Returned Value for Day of Week is: MON
#                  Returned Value for Message is:
#
#                  Note the availability of the return value description array @myDate_ReturnDesc
# 
#     It can also be used to identify a date x days from a set base year. So to 
#     work out what day Julian date 10200 is we could use the function as :
#
#              @dateReturn = myDate("200 BASE:2010")
#              for (my $i=0; $i <= $#dateReturn; $i++) {
#                print "Returned Value for $myDate_ReturnDesc[$i] is: $dateReturn[$i]\n";
#              }
#
#              Returned Value for Day of Month is: 19
#              Returned Value for Month is: 07
#              Returned Value for Year is: 2014
#              Returned Value for Day Suffix is: th
#              Returned Value for Month Name is: July
#              Returned Value for Number of days since Base Date is: 200
#              Returned Value for Base Date is: 2014
#              Returned Value for EOM is: N
#              Returned Value for EOY is: N
#              Returned Value for EOFY is: N
#              Returned Value for BOM is: N
#              Returned Value for Day of Week is: SAT
#              Returned Value for Message is:
# 
#     As well it can be used to identify the number of days between 2 date by processing 
#     each date and then substracting their $T[5] elements.
#
#   getOpt()
#  
#   A standard use of getOpt would look like:
#
#   # Set up the environment to include the commonFunctions module ...
#
#     BEGIN {
#       if ( $^O eq "MSWin32") {
#         print "Windows is running ...\n";
#         $machine = `hostname`;
#         $OS = "Windows";
#         $scriptDir = 'c:\udbdba\scrxipts';
#         $tmp = rindex($0,'\\');
#         if ($tmp > -1) {
#           $scriptDir = substr($0,0,$tmp+1)  ;
#         }
#       }
#       else {
#         print "$^O is running ...\n";
#         $machine = `uname -n`;
#         $machine_info = `uname -a`;
#         @mach_info = split(/\s+/,$machine_info);
#         $OS = $mach_info[0] . " " . $mach_info[2];
#         $scriptDir = "scripts";
#         $tmp = rindex($0,'/');
#         if ($tmp > -1) {
#           $scriptDir = substr($0,0,$tmp+1)  ;
#         }
#       }
#     }
#      
#     use lib "$scriptDir";
#      
#     use commonFunctions qw(getOpt myDate trim $getOpt_optName $getOpt_optValue @myDate_ReturnDesc);
#
#     # Set default values for variables
#
#     $silent = "No";
#
#     # ----------------------------------------------------
#     # -- Start of Parameter Section
#     # ----------------------------------------------------
#
#     # Initialise vars for getOpt ....
#
#     $opt = ":?hsvtT:S:d:w";    # set up the valid parm values
#
#     while ( getOpt($opt) ) {
#       if (($getOpt_optName eq "h") || ($getOpt_optName eq "?") )  {
#         usage ("");   # call the usage routine display help
#         exit;
#       }
#       elsif (($getOpt_optName eq "s") )  { # turn on silent
#         $silent = "Yes";
#       }
#       elsif (($getOpt_optName eq "v"))  {  # set debug Level
#         $debugLevel++;
#         if ( $silent ne "Yes") {
#           print STDERR "Debug level now set to $debugLevel\n";
#         }
#       }
#       .
#       ..... insert other parameter option activities here
#       .
#       elsif ( $getOpt_optName eq ":" ) {
#         usage ("Parameter $getOpt_optValue requires a parameter");
#         exit;
#       }
#       else { # handle other entered values ....
#         if ( $parameter eq "" ) { # assume parameters if nothing is indicated
#           $directory = $getOpt_optValue;
#           if ( $silent ne "Yes") {
#             print STDERR "Directory $getOpt_optValue will be processed\n";
#           }
#         }
#         else {
#           usage ("Parameter $getOpt_optValue is invalid");
#           exit;
#         }
#       }
#     }
#
#     # ----------------------------------------------------
#     # -- End of Parameter Section
#     # ----------------------------------------------------
#
# $Name:  $
#
# ChangeLog:
# $Log: commonFunctions.pm,v $
# Revision 1.30  2018/10/15 05:01:01  db2admin
# add in getCurrentTimestamp routine
#
# Revision 1.29  2018/05/29 04:30:48  db2admin
# add in processing to cope with web supplied string parameters containing spaces
#
# Revision 1.28  2018/04/03 06:14:13  db2admin
# adjust getOpt routine to enforce hyphen identification of parameter names where specified
# .
#
# Revision 1.27  2018/03/21 05:27:32  db2admin
# Correct bug in processing of extended parameters (starting with --)
# Allow partial entry of parameter names for extended parameters
#
# Revision 1.26  2018/02/13 23:50:16  db2admin
# ensure that parameters to timeAdj and displayMinutes are integers
#
# Revision 1.25  2018/02/13 23:28:38  db2admin
# replace with working version from another machine
#
# Revision 1.23  2018/02/13 23:13:44  db2admin
# correct issue of non whole hours beingreturned from displayMinutes when less than 1 day run time
#
# Revision 1.22  2017/12/06 21:42:53  db2admin
# add in timeAdj function
#
# Revision 1.21  2017/09/25 04:32:31  db2admin
# add in convertToTimestamp function
#
# Revision 1.20  2017/04/24 02:14:43  db2admin
# change default for datediff to minutes difference
#
# Revision 1.19  2017/04/10 03:03:37  db2admin
# moved an upper case conversion to hopefully not reset the defiend flag
#
# Revision 1.18  2017/02/28 04:56:24  db2admin
# add new parameter to timeDiff to allowing varying return units of measure
#
# Revision 1.17  2016/11/28 23:51:54  db2admin
# modify getOpt to ignore passed parameters that are null
#
# Revision 1.16  2016/09/19 05:25:39  db2admin
# Added in new callable routines displayMinutes timeDiff timeAdd
#
# Revision 1.15  2016/08/25 06:29:50  db2admin
# improve debuggingmessages
# correct bug in script when script called multiple times
#
# Revision 1.14  2016/07/01 01:26:46  db2admin
# always process web parameters if they are there and if no line parameters are entered
#
# Revision 1.13  2016/06/03 05:24:29  db2admin
# correct processing of web parameters
#
# Revision 1.12  2015/11/11 22:03:54  db2admin
# remove webserer added chracters from getOpt_form processing
#
# Revision 1.11  2015/11/03 23:17:51  db2admin
# alter parm separators (exclude + as it is used as a space replacement in a POST request)
#
# Revision 1.10  2015/11/02 06:24:25  db2admin
# Add in new functions processDirectory and localDateTime
#
# Revision 1.9  2015/10/25 21:16:28  db2admin
# add in option to remove escape characters from string returned by getOpt
#
# Revision 1.7  2015/10/21 00:28:41  db2admin
# add in code to manage variables to getOpt_form supplied via POST
#
# Revision 1.5  2015/10/20 22:31:15  db2admin
# add in new getOpt_form function
#
# Revision 1.4  2015/07/29 00:24:08  db2admin
# Add in new functioinality to process parameters passed through QUERY_STRING variable (CGI 'GET' POST)
# Correct bug in checking parameter numbers
# Add in more diagnostic capability
# Add in new variables getOpt_debugLevel and getOpt_calledBy to improve diagnostics
# Modified error printing to go to STDERR (which then goes to apache2 log)
#
#
# Revision 1.3  2015/03/13 02:42:53  db2admin
# 1. Correct date generation for offset dates when multiple calls are made to the routine
# 2. Improve debugging output
#
# Revision 1.2  2014/08/04 04:51:52  db2admin
# Add in documentation
# Correct bug in myDate (day was wrong if base date was changed)
# NOTE: myDate doesn't function for dates before 1st Jan 1965
#
#
# --------------------------------------------------------------------

package commonFunctions;

use strict;

# export parameters ....
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(trim ltrim rtrim commonVersion getOpt myDate $getOpt_web $getOpt_optName $getOpt_min_match $getOpt_optValue getOpt_form @myDate_ReturnDesc $myDate_debugLevel $getOpt_diagLevel $getOpt_calledBy $parmSeparators processDirectory $maxDepth $fileCnt $dirCnt localDateTime $datecalc_debugLevel displayMinutes timeDiff timeAdd timeAdj convertToTimestamp getCurrentTimestamp);

# persistent variables

# processDircetory

our $maxDepth;        # maximum directory levels to descend in the tree
our $fileCnt;         # number of files encountered
our $dirCnt;          # number of directories encounterd (not including . and ..

my @PARGV;
my @QPARGV;
my $getOpt_prm;
my $getOpt_prm_flag;
our $getOpt_optName;         # contains the option currently being processed
our $getOpt_optValue;        # contains the value of the option currently being processed
our $getOpt_web;             # indicates that the result is for the web
our $getOpt_calledBy;        # indicates the routine calling the module
our $getOpt_diagLevel;       # debug level in getopt
our $getOpt_min_match = 2;   # minimum number of characters required for a parameter match (-1 => whole parameter equal)
our $datecalc_debugLevel;    # debug level for date calculation routines
our $parmSeparators = ' &';  # string contains characters to be used as separators in getOpt_form
my @monthName;
my %monthNumber;
my @monthDays;
our @myDate_ReturnDesc = ('Day of Month', 'Month', 'Year', 'Day Suffix', 'Month Name', 'Number of days since Base Date','Base Date', 'EOM','EOY','EOFY','BOM','Day of Week','Message');
our $myDate_debugLevel ;
my %getOpt_valid_parms;
my $search_valid_parms = '';
my %getOpt_caseinsens;   # 0 => case sensitive, 1 => case insensitive
my %getOpt_requiresDash;

BEGIN {
  $getOpt_prm = 0;
  $getOpt_optName = "";
  $getOpt_optValue = "";
  $getOpt_calledBy = "unknown module";
  $monthName[1] = "January";
  $monthDays[1] = "31";
  $monthName[2] = "February";
  $monthDays[2] = "28";
  $monthName[3] = "March";
  $monthDays[3] = "31";
  $monthName[4] = "April";
  $monthDays[4] = "30";
  $monthName[5] = "May";
  $monthDays[5] = "31";
  $monthName[6] = "June";
  $monthDays[6] = "30";
  $monthName[7] = "July";
  $monthDays[7] = "31";
  $monthName[8] = "August";
  $monthDays[8] = "31";
  $monthName[9] = "September";
  $monthDays[9] = "30";
  $monthName[10] = "October";
  $monthDays[10] = "31";
  $monthName[11] = "November";
  $monthDays[11] = "30";
  $monthName[12] = "December";
  $monthDays[12] = "31";
  %monthNumber = ( 'Jan' =>  '01', 'Feb' =>  '02', 'Mar' =>  '03', 'Apr' =>  '04', 'May' =>  '05', 'Jun' =>  '06',
                    'Jul' =>  '07', 'Aug' =>  '08', 'Sep' =>  '09', 'Oct' =>  '10', 'Nov' =>  '11', 'Dec' =>  '12',
                    'January' =>  '01', 'February' =>  '02', 'March' =>  '03', 'April' =>  '04', 'May' =>  '05', 'June' =>  '06',
                    'July' =>  '07', 'August' =>  '08', 'September' =>  '09', 'October' =>  '10', 'November' =>  '11', 'December' =>  '12' );
#  $myDate_debugLevel = 2; 
  if ( ! defined($getOpt_diagLevel) ) { $getOpt_diagLevel = 0; }
  if ( ! defined($datecalc_debugLevel) ) { $datecalc_debugLevel = 0; }
  # processDirectory
  $maxDepth = -1;
  $fileCnt = 0;
  $dirCnt = 0;
}

# -----------------------------------------------------------------
# displayMinutes - function to return a supplied minutes value as x days x hours x mins)
#                  (it will not break the days value into years)
#
# Usage: displayMinutes(89);
# Returns: '1 hour 29 minutes'
#
# -----------------------------------------------------------------

sub displayMinutes {

  my $elapsed = shift;
  $elapsed = int($elapsed); # make sure that the number of minutes is an integer
  my $currentRoutine = 'displayMinutes';

  if ( $datecalc_debugLevel > 1 ) { printDebug( "Total mins: $elapsed", $currentRoutine); }

  if ( $elapsed < 60 ) { return "$elapsed minute" . literalPlural($elapsed); } # under 60 minutes so just return the value

  if ( $elapsed < 1440 ) { # under one day so just return hours and minutes
    my $mins = $elapsed % 60;
    my $hours = int(($elapsed - $mins) / 60);
    return "$hours hour" . literalPlural($hours) . " $mins minute" . literalPlural($mins);
  }

  my $mins = $elapsed % 60;
  my $totalHours = ($elapsed - $mins) / 60;
  my $hours = $totalHours % 24;
  my $days = ($elapsed - (60 * $hours) - $mins)/1440;
  return "$days day" . literalPlural($days) . " $hours hour" . literalPlural($hours) . " $mins minute" . literalPlural($mins);

}

# -----------------------------------------------------------------
# literalPlural - function to return 's' if the parameter is not a 1
# -----------------------------------------------------------------

sub literalPlural {
  my $number = shift;
  if ($number == 1 ) { return ''; } # no s
  else { return 's'; }

}

# -----------------------------------------------------------------
# printDebug - function to print formatted input to STDOUT
#
# usage:    printDebug('test statement', 'testModule')
#           the parameters are:
#               1. message to be displayed
#               2. module that is doing the calling
# returns:  'testModule          test statement'  
#
# -----------------------------------------------------------------

sub printDebug {

  my $test = shift;
  my $routine = shift;
  $routine = substr("$routine                    ",0,20);

  print "$routine - $test\n";
}

# -----------------------------------------------------------------
# getCurrentTimestamp - function to return the current time as a timestamp
#
# usage:    getCurrentTimesatmp()
# returns:  '2016.09.19 08:20:00'
#
# -----------------------------------------------------------------

sub getCurrentTimestamp {

  my $currentRoutine = 'getCurrentTimestamp';

  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  my $year = 1900 + $yearOffset;
  $month = $month + 1;
  $hour = substr("0" . $hour, length($hour)-1,2);
  $minute = substr("0" . $minute, length($minute)-1,2);
  $second = substr("0" . $second, length($second)-1,2);
  $month = substr("0" . $month, length($month)-1,2);
  my $day = substr("0" . $dayOfMonth, length($dayOfMonth)-1,2);
  return "$year.$month.$day $hour:$minute:$second";

} # end of getCurrentTimestamp

# -----------------------------------------------------------------
# timeAdd - function to return a timestamp with a specified number of
#           minutes added
#
#           timeAdj takes the same parameters but allows a negative value for 
#           the adjustment minutes
# 
#           also timeAdd always returns 00 seconds
#
# usage:    timeAdd('2016.09.19 08:05:01','15')
#           the parameters are:
#               1. timestamp in the format yyyy.mm.dd hh:mm:ss
#               2. elapsed time in minutes
# returns:  '2016.09.19 08:20:00'  
#
# -----------------------------------------------------------------

sub timeAdd {

  my $currentRoutine = 'timeAdd';
  my $startTime = shift;
  my $elapsed = shift;
  my ($year, $mon, $day, $hr, $min, $sec) = ( $startTime =~ /(\d\d\d\d).(\d\d).(\d\d) (\d\d).(\d\d).(\d\d)/ );

  if ( $datecalc_debugLevel > 0 ) { printDebug( "Timestamp: $startTime (year: $year, month: $mon, day: $day, hour: $hr, min: $min, secs: $sec). Elapsed: $elapsed", $currentRoutine); }

  $min = $min + $elapsed;

  # break the minutes into number of hours and minute remainders
  my $nMin = $min % 60;                         # final minutes past the hour
  if ( $datecalc_debugLevel > 0 ) { printDebug( "total minutes: $min, new minute: $nMin", $currentRoutine); }
  my $tempHr = (($min - $nMin)/60) + $hr;       # this is the number of hours into the future

  my $nHr = $tempHr % 24;                # Final hour on the day
  $nMin = substr('00' . $nMin, length($nMin), 2); # pad out to 2 digits
  $nHr = substr('00' . $nHr, length($nHr), 2); # pad out to 2 digits
  if ( $datecalc_debugLevel > 0 ) { printDebug( "total hours: $tempHr, new hour: $nHr", $currentRoutine); }
  my @T = myDate("DATE\:$year$mon$day");   # convert date into number of days from the base date
  my $tempDay = (($tempHr - $nHr)/24) + $T[5]; # days from the base date
  if ( $datecalc_debugLevel > 0 ) { printDebug( "tempHr: $tempHr, hr: $hr, nHr: $nHr", $currentRoutine);}
  my @T1 = myDate($tempDay);                   # convert the number of days back to a gregorian day
  if ( $datecalc_debugLevel > 0 ) { printDebug( "Base Date Offset: $T[5], New offset: $tempDay, New Date: $T1[2].$T1[1].$T1[0]", $currentRoutine); }

  return "$T1[2].$T1[1].$T1[0] $nHr:$nMin:00";

}

# -----------------------------------------------------------------
# timeAdj - function to return a timestamp with a specified number of
#           minutes adjusted
#
# usage:    timeAdd('2016.09.19 08:05:01','15')
#           the parameters are:
#               1. timestamp in the format yyyy.mm.dd hh:mm:ss
#               2. elapsed time in minutes (negative or positive number)
# returns:  '2016.09.19 08:20:01'  
#
# -----------------------------------------------------------------

sub timeAdj {

  my $currentRoutine = 'timeAdj';
  my $startTime = shift;
  my $elapsed = shift;
  $elapsed = int($elapsed); # ensure that the elapsed time is an integer
  my ($year, $mon, $day, $hr, $min, $sec) = ( $startTime =~ /(\d\d\d\d).(\d\d).(\d\d) (\d\d).(\d\d).(\d\d)/ );

  if ( $datecalc_debugLevel > 0 ) { printDebug( "Timestamp: $startTime (year: $year, month: $mon, day: $day, hour: $hr, min: $min, secs: $sec). Elapsed: $elapsed", $currentRoutine); }
  
  # convert timestamp to number of minutes
  
  my @T = myDate("DATE\:$year$mon$day");   # convert date into number of days from the base date
  my $TS_Minutes = ($T[5] * 1440) + ($hr * 60) + $min;
  if ( $datecalc_debugLevel > 0 ) { printDebug( "Base Date Offset: $T[5], TS_Minutes: $TS_Minutes", $currentRoutine); }

  # adjust the value 
  $TS_Minutes = $TS_Minutes + $elapsed; # $elapsed may be positive or negative
  if ( $datecalc_debugLevel > 0 ) { printDebug( "Minutes after adjustment: $TS_Minutes", $currentRoutine); }
  
  # Convert the value back to a timestamp .....
  
  my $new_days = int($TS_Minutes / 1440) ;         # days past the base date
  $TS_Minutes = $TS_Minutes - ( $new_days * 1440); # now holds number of minutes past midnight
  my $new_hours = int($TS_Minutes / 60) ; 
  if ( $datecalc_debugLevel > 0 ) { printDebug( "New Days Offset: $new_days, Minutes after midnight: $TS_Minutes", $currentRoutine); }
  $new_hours = substr('00' . $new_hours, length($new_hours), 2); # pad out to 2 digits
  $TS_Minutes = $TS_Minutes - ( $new_hours * 60);  # now holds number of minutes past the hour
  $TS_Minutes = substr('00' . $TS_Minutes, length($TS_Minutes), 2); # pad out to 2 digits
  if ( $datecalc_debugLevel > 0 ) { printDebug( "New Hours Offset: $new_hours, Minutes after the hour: $TS_Minutes", $currentRoutine); }

  # convert the days count back to a gregorian date
  @T = myDate($new_days);   

  if ( $datecalc_debugLevel > 0 ) { printDebug( "Returned Date: $T[2].$T[1].$T[0] $new_hours:$TS_Minutes:$sec", $currentRoutine); }

  return "$T[2].$T[1].$T[0] $new_hours:$TS_Minutes:$sec";

}

# -----------------------------------------------------------------
# timeDiff - function to return the number of minutes between 2 supplied 
#            timestamps
#
# usage:    timeDiff('2016.09.19 08:05:01','2016.09.19 08:20:01'[,'M'])
#           the parameters are:
#               1. timestamp in the format yyyy.mm.dd hh:mm:ss
#               2. timestamp in the format yyyy.mm.dd hh:mm:ss
#               Note: option 3rd parameter S, M, H or D indicating the unit
#                     or measure of the returned value
# returns:  '15'
#
# -----------------------------------------------------------------

sub timeDiff {

  my $currentRoutine = 'timeDiff';
  my $startTime = shift;
  my $endTime = shift;
  my $UOM = shift;

  if ( ! defined($UOM) ) { $UOM = 'M'; } # when not supplied thedefault is minutes
  $UOM = uc($UOM);

  # start time is formatted yyyy.mm.dd hh:mm:ss

  my ($sYear, $sMon, $sDay, $sHr, $sMin, $sSec) = ( $startTime =~ /(\d\d\d\d).(\d\d).(\d\d) (\d\d).(\d\d).(\d\d)/ );
  my @T = myDate("DATE\:$sYear$sMon$sDay");
  my $startDayOffset = $T[5] ;
  if ( $datecalc_debugLevel > 1 ) { for ( my $j = 0 ; $j <= $#T; $j++) { print "$j: $T[$j]\n"; }}
  my $startMinsPastMidnight = ($sHr*60) + $sMin;

  # end time is formatted  yyyy.mm.dd hh:mm:ss

  my ($eYear, $eMon, $eDay, $eHr, $eMin, $eSec) = ( $endTime =~ /(\d\d\d\d).(\d\d).(\d\d) (\d\d).(\d\d).(\d\d)/ );
  @T = myDate("DATE\:$eYear$eMon$eDay");
  my $endDayOffset = $T[5] ;
  if ( $datecalc_debugLevel > 1 ) { for ( my $j = 0 ; $j <= $#T; $j++) { print "$j: $T[$j]\n"; }}
  my $endMinsPastMidnight = ($eHr*60) + $eMin;

  my $daysDiff = $endDayOffset - $startDayOffset;
  my $hrsDiff  = ($daysDiff * 24 ) + $eHr - $sHr;
  my $minsDiff = ($hrsDiff * 60  ) + $eMin - $sMin;
  my $secsDiff = ($minsDiff * 60  ) + $eSec - $sSec;

  if ( $datecalc_debugLevel > 0 ) { printDebug( "Start Time: $startTime, End Time: $endTime, Mins Diff: $minsDiff", $currentRoutine); }
  if ( $datecalc_debugLevel > 1 ) { printDebug( "Start Day Offset: $startDayOffset, Start Mins Past Midnight: $startMinsPastMidnight", $currentRoutine); }
  if ( $datecalc_debugLevel > 2 ) { printDebug( "Start Components: $sYear#$sMon#$sDay#$sHr#$sMin#$sSec", $currentRoutine); }
  if ( $datecalc_debugLevel > 1 ) { printDebug( "End Day Offset: $endDayOffset, End Mins Past Midnight: $endMinsPastMidnight", $currentRoutine); }
  if ( $datecalc_debugLevel > 2 ) { printDebug( "End Components: $eYear#$eMon#$eDay#$eHr#$eMin#$eSec", $currentRoutine); }

  if ( $UOM eq 'D' ) { return $daysDiff; }
  elsif ( $UOM eq 'H' ) { return $hrsDiff; }
  elsif ( $UOM eq 'S' ) { return $secsDiff; }
  else  { return $minsDiff; }

}

# -----------------------------------------------------------------
# commonVersion - function to return the version onumber of this 
#                 module
# -----------------------------------------------------------------

sub commonVersion {

  my $ID = '$Id: commonFunctions.pm,v 1.30 2018/10/15 05:01:01 db2admin Exp db2admin $';
  my @V = split(/ /,$ID);
  my $nameStr=$V[1];
  (my $name,my $x) = split(",",$nameStr);
  my $Version=$V[2];
  my $Changed="$V[3] $V[4]";

  return "$name ($Version)  Last Changed on $Changed (UTC)";

}

# -----------------------------------------------------------------
# setParameterIfNecessary - set the parameter if necessary and
# otherwise just sets it to space
# -----------------------------------------------------------------

sub setParameterIfNecessary {
  
  my $getOpt_prmName = shift;
  my $webParmSet = shift;
  my $origName = shift;    # if it was a partial match then this was the original parameter name

  if ( $getOpt_valid_parms{$getOpt_prmName} eq ":" ) {     # is a parameter required?
    if ( $webParmSet ne "" ) {                              # getOpt_web set and a parm has already been found
      $getOpt_optName = $getOpt_prmName;                   # set the returned option name
      $getOpt_optValue = $webParmSet;                       # set the returned parameter
      $getOpt_prm_flag = "Y";
    }
    else { # normal space delimited parameters
      $getOpt_optName = $getOpt_prmName;                     # set the option name
      if ( defined($PARGV[$getOpt_prm+1] ) ) {                # there is another parm
        if ( substr($PARGV[$getOpt_prm+1],0,1) eq "-" ) {     # check to see if it is another parameter
          $getOpt_optValue = $getOpt_prmName;                # Pass back the option name as the parameter (value)
          $getOpt_optName = ":";                              # name set to : to indicate error
          $getOpt_prm_flag = "Y";
        }
        else { # we have a winner
          $getOpt_optValue = $PARGV[$getOpt_prm+1];           # set the returned parameter
          $getOpt_prm_flag = "Y";
          $getOpt_prm++;
        }
      }
      else { # parm was required and there are no more parms!
        $getOpt_optValue = $getOpt_prmName;                  # Pass back the option name as the parameter
        $getOpt_optName = ":";                                # name set to : to indicate error
        $getOpt_prm_flag = "Y";
      }
    }
  }
  else { # Parameter is not required
    $getOpt_optValue = "";
    $getOpt_optName = $getOpt_prmName;
    $getOpt_prm_flag = "Y";
  }
  
  return;

} # end of setParameterIfNecessary

# -----------------------------------------------------------------
# getOpt - function to manage the processing of passed parameters
#
# Parameters are of the form 'ab[c]b[c]..[|[d][e]f[c]|[d][e]f[c]....]
#     where a - character to indicate parms are required (normally :)
#           b - option (single character)
#           c - (optional) indicator for parameters (will be the same as parm a). 
#               If there it indicates that option has parameters
#           d - (optional) indicator for multi character option: '--'
#           e - (optional) if ^ indicates that the option is case insensitive
#           f - (optional) long option name
#
#  so an example could be: ':h?d:|--database:|^db: and that would allow parameters like:
#                 test.pl -d testdb
#                 test.pl --database testdb
#                 test.pl dB testdb
#
# NOTE: All single character parameters are case sensitive
#       On the command line:
#           All parameters defined in the single character section must be preceded by '-'
#           All parameters defined in the multi character section must be preceded by either '--' or nothing
#
# Returns: $getOpt_optName : Parameter name if all ok
#                            : if parameter name was ok but required parameter not supplied
#                            * if parameter name was not defined
#          $getopt_optValue: Parameter value if parameter required a parameter
#                            Blank if no parameter required
#                            Parameter name/value if $getOpt_optName set to : or *
# -----------------------------------------------------------------

sub getOpt {

  my $case_insens = "";
  my $getOpt_parmInd = ":";
  my $webParmSet = "";   # initially set no web parm
  my $extendedParameter = 0; # initially parameter is assumed not to be extended

#  our $getOpt_web;
  if ( ! defined($getOpt_calledBy) ) { 
    $getOpt_calledBy = "unknown module";
  }

  if ( (! defined($getOpt_web)) || ($getOpt_web eq '') ) { 
    $getOpt_web = "N";
  }
  
  if ( $getOpt_prm eq "" ) { 
     $getOpt_prm = 0;
  }

  my $QUERY_STRING = $ENV{'QUERY_STRING'};

  if ( ($#_ < 0) && ($QUERY_STRING eq '') ) {
    print STDERR "[$getOpt_calledBy] No parameters passed\n";
    return 0;
  }
 
  $QUERY_STRING =~ s/%27/\'/g; 
  # Define the variables .....

  my $i;
  my $j;
  my $ch;
  my @getOpt_OptArr;
  my $getOpt_tmpKW;
  my $getOpt_KWLen;
  my $getOpt_prmChar;
  my $getOpt_prmName;
  my @webparm;   # used to split parameters by '=' for web use
  my $getOpt_schar;

  # Preparse the input parameters to process concatenated parms 

  if ( ($#PARGV == -1) ) { # Arguments havent been pre-processed yet
    # This is executed only for the first call
    if ( $#ARGV > -1 ) { # only do this bit if parameters are passed
      for ($i=0 ; $i <= $#ARGV ; $i++ ) {        # loop through the arguments
        if ( trim($ARGV[$i]) eq '' ) { next; }   # if the parameter is null then ignore it
        if ( substr($ARGV[$i],0,2) eq "--" ) {   # if it is an extended parameter (begins with --)
          $PARGV[$#PARGV + 1] = $ARGV[$i];
        }
        elsif ( substr($ARGV[$i],0,1) eq "-" ) { # if it starts with a "-"
          # then split up the parameters into separate parms .....
          # (but only if it is non-web and there is no = sign)
          if ( ( $getOpt_web eq "Y" ) && ( index($ARGV[$i],'=') > -1 ) ) {
            # do nothing to the parameter
            my @tmp = split ('=', $ARGV[$i]);
            $PARGV[$#PARGV + 1] = $tmp[0];
            $PARGV[$#PARGV + 1] = $tmp[1];
          }
          else { # space them out .....
            for ( $j=1 ; $j < length($ARGV[$i]) ; $j++ ) {
              $ch = substr($ARGV[$i],$j,1);
              $PARGV[$#PARGV + 1] = "-" . $ch;
            }
          }
        }
        else { # just a parameter
          $PARGV[$#PARGV + 1] = $ARGV[$i];
          if ( substr($PARGV[$#PARGV],0,2) eq "\\\'" ) { # if the parameter starts with \'
            $PARGV[$#PARGV] =~ s/^\\\'//g;  # get rid of the leading characters
            while ( ( $i <= $#ARGV ) && ( substr($ARGV[$i],-2,2) ne "\\\'" ) ) { # parameter is not terminated with a \'
              $i++;
              $PARGV[$#PARGV] .= " " . $ARGV[$i];
            }
            $PARGV[$#PARGV] =~ s/\\\'$//g;  # get rid of the trailing characters
          }
        }
      }
    }

    # now check to see if there are any web GET parameters ....... (but only if there were NO inline parameters)

    if ( $getOpt_diagLevel > 0 ) {
      print STDERR "[$getOpt_calledBy] \$getOpt_web: $getOpt_web, \$QUERY_STRING: $QUERY_STRING, \$\#PARGV: $#PARGV\n";
    }

    if ( ($QUERY_STRING ne '') && ($#PARGV == -1) ) { # there's web GET form input to process 
    
      my @QPARGV = (); # Query parm ARGV cleared
      # get rid of any 'web' spacing characters (i.e. replace + with ' ')
      $QUERY_STRING =~ s/\+/ /g;
      @QPARGV = split (" ", $QUERY_STRING);

      for ($i=0 ; $i <= $#QPARGV ; $i++ ) {        # loop through the arguments
        if ( substr($QPARGV[$i],0,2) eq "--" ) {   # if it is an extended parameter (begins with --)
          $PARGV[$#PARGV + 1] = $QPARGV[$i];
        }
        elsif ( substr($QPARGV[$i],0,1) eq "-" ) { # if it starts with a "-"
          # then split up the parameters into separate parms .....
          if ( index($QPARGV[$i],'=') > -1 ) { # the parm is of the form A=B so split it up
            # do nothing to the parameter
            my @tmp = split ('=', $QPARGV[$i]);
            for (my  $j=1 ; $j < length($tmp[0]) ; $j++ ) {
             $PARGV[$#PARGV + 1] = '-' . substr($tmp[0],$j,1);
            }
            $PARGV[$#PARGV + 1] = $tmp[1];
          }
          else { # space them out .....
            for ( $j=1 ; $j < length($QPARGV[$i]) ; $j++ ) {
              $ch = substr($QPARGV[$i],$j,1);
              $PARGV[$#PARGV + 1] = "-" . $ch;
            }
          }
        }
        else { # just a parameter
          $PARGV[$#PARGV + 1] = $QPARGV[$i];
          if ( substr($PARGV[$#PARGV],0,2) eq "\\\'" ) { # if the parameter starts with \'
            $PARGV[$#PARGV] =~ s/^\\\'//g;  # get rid of the leading characters
            while ( ( $i <= $#QPARGV ) && ( substr($QPARGV[$i],-2,2) ne "\\\'" ) ) { # parameter is not terminated with a \'
              $i++;
              $PARGV[$#PARGV] .= " " . $QPARGV[$i];
            }
            $PARGV[$#PARGV] =~ s/\\\'$//g;  # get rid of the trailing characters
          }
        }
      }
    }

    # Print out the new array if requested to
    if ( $getOpt_diagLevel > 0 ) {
      for ($i = 0 ; $i <= $#PARGV ; $i++ ) {
        print STDERR "[$getOpt_calledBy] (adjusted parms) $i: $PARGV[$i]\n";
      }
    }
  }

  # Process the parameters ......

  # Parameters are of the form 'ab[c]b[c]..[|[d][e][f][c]|[d][e][f][c]....]
  #     where a - character to indicate parms are required (normally :)
  #           b - option (single character)
  #           c - (optional) indicator for parameters (will be the same as parm a). 
  #               If there it indicates that option has parameters
  #           d - (optional) indicator for multi character option: '--'
  #           e - (optional) if ^ indicates that the option is case insensitive
  #           f - (optional) long option name
  #
  #  so an example could be: ':h?d:|--database:|^db: and that would allow parameters like:
  #                 test.pl -d testdb
  #                 test.pl --database testdb
  #                 test.pl dB testdb

  if (! defined($getOpt_valid_parms{'###'}) ) { # Check if the parm definitions have been read in
    $getOpt_valid_parms{'###'} = "Processed Extended Parms";            # flag that we have processed the parms on the first call in
    @getOpt_OptArr = split(/\|/,$_[0]);  # $_[0] is the single character parameters - split by |
    # Gather the 2nd and subsequent parameters
    $getOpt_parmInd = substr($getOpt_OptArr[0],0,1); # establish the parm indicator character
    for ($i=1 ; $i <= $#getOpt_OptArr ; $i++ ) { # Process the  multi character options (skip the first parameter for later processing)
      if ( substr($getOpt_OptArr[$i],0, 2) eq "--" ) {   # it is an extended parameter
        if ( substr($getOpt_OptArr[$i],2, 1) eq "^" ) {  # it is flagged case insensitive (first char is ^)
          $getOpt_tmpKW = uc(substr($getOpt_OptArr[$i],3));
          $case_insens = 1;
        }
        else { # it is not case insensitive
          $getOpt_tmpKW = substr($getOpt_OptArr[$i],2);
          $case_insens = 0;
        }
        $getOpt_KWLen = length($getOpt_tmpKW);
        if ( substr($getOpt_tmpKW,$getOpt_KWLen-1,1) eq $getOpt_parmInd ) { # it requires a parameter (last char is the parameter indicator)
          $getOpt_tmpKW = substr($getOpt_tmpKW,0,$getOpt_KWLen-1);          # get rid of the indicator
          $getOpt_valid_parms{$getOpt_tmpKW} = ":";                         # non blank indicates it requires a parameter
        }
        else { # it doesn't require a parameter
          $getOpt_valid_parms{$getOpt_tmpKW} = "";                          # flag it as case sensitive
        }
        $getOpt_caseinsens{$getOpt_tmpKW} = $case_insens;
        # only bother to set the flag if it hasn't already been set
        if (! defined($getOpt_requiresDash{$getOpt_tmpKW}) ) {  $getOpt_requiresDash{$getOpt_tmpKW} = 1; } # 
      }
      else { # process it as a keyword 
        $getOpt_tmpKW = $getOpt_OptArr[$i];
        # set up values for supplied parameter (or not)
        if ( substr($getOpt_OptArr[$i],-1,1) eq $getOpt_parmInd ) { # indicator set for provided parameter so alter the parameter name
          $getOpt_KWLen = length($getOpt_tmpKW);
          $getOpt_tmpKW = substr($getOpt_tmpKW,0,$getOpt_KWLen-1);          # get rid of the indicator
          $getOpt_valid_parms{$getOpt_tmpKW} = ':';
        }
        else {
          $getOpt_valid_parms{$getOpt_tmpKW} = ' ';
        }
        
        if ( substr($getOpt_OptArr[$i],0, 1) eq "^" ) {     # it is case insensitive 
          $getOpt_tmpKW = uc(substr($getOpt_OptArr[$i],1)); # parameter starts after 1st char
          $getOpt_caseinsens{$getOpt_tmpKW} = 1;          # flag it as case insensitive
        }
        else {
          $getOpt_caseinsens{$getOpt_tmpKW} = 0;
        }
      }
      $getOpt_requiresDash{$getOpt_tmpKW} = 0;
      $search_valid_parms .= " $getOpt_tmpKW ";
    }
  }
  
  # Process the 1st parameter separately ....
  $getOpt_schar = 0;
  if (! defined($getOpt_valid_parms{'####'}) ) { # Has this parm already been processed?
    $getOpt_valid_parms{'####'} = "Processed First Parm";            # flag that we have processed the parms on the first call in
    $getOpt_schar++;          # skip the first character as it is the parameter indicator
    # now process each of the character options .....
    while ( $getOpt_schar <= length($getOpt_OptArr[0])-1 ) {
      $getOpt_prmChar = substr($getOpt_OptArr[0],$getOpt_schar,1);   # set option
      $getOpt_valid_parms{$getOpt_prmChar} = "";                     # set it up as a valid option without parm
      $getOpt_caseinsens{$getOpt_prmChar} = 0;                       # set it up as case sensitive (note all single char options are case sensitive)
      # only bother to set the requiresDash flag if it hasn't already been set
      if (! defined($getOpt_requiresDash{$getOpt_prmChar}) ) {  $getOpt_requiresDash{$getOpt_prmChar} = 1; } # 
      $getOpt_schar++;
      if ( $getOpt_schar <= length($getOpt_OptArr[0])-1 ) { # if still more chars check if it is a flag       
        if ( substr($getOpt_OptArr[0],$getOpt_schar,1) eq $getOpt_parmInd ) { # Flagged as requiring parameters
          $getOpt_valid_parms{$getOpt_prmChar} = ":";                # set option as requiring parm
          $getOpt_schar++;
        }
      }
    }
  }
  $getOpt_prm_flag = "N";

  if ( $getOpt_diagLevel > 0 ) {
    print STDERR "[$getOpt_calledBy] ================================================<BR>\n";
    print STDERR "[$getOpt_calledBy] \$\#ARGV=$#ARGV<BR>\n";
    for ($i=0 ; $i <= $#ARGV ; $i++ ) {
      print STDERR "[$getOpt_calledBy] ARGS $i>$ARGV[$i]<BR>\n";
    }
    print STDERR "[$getOpt_calledBy] Query parms string: $QUERY_STRING<BR>\n";
    print STDERR "[$getOpt_calledBy] \$\#PARGV=$#PARGV<BR>\n";
    for ($i=0 ; $i <= $#PARGV ; $i++ ) {
      print STDERR "[$getOpt_calledBy] PARGS $i>$PARGV[$i]<BR>\n";
    }
    print STDERR "[$getOpt_calledBy] \$\#=$#_<BR>\n";
    for ($i=0 ; $i <= $#_ ; $i++ ) {
      print STDERR "[$getOpt_calledBy] PRM $i>$_[$i]<BR>\n";
    }
    if (defined($PARGV[$getOpt_prm]) ) {
      print STDERR "[$getOpt_calledBy] Current Parm:$PARGV[$getOpt_prm]<BR>\n";
    }
    print STDERR "[$getOpt_calledBy] \$getOpt_valid_parms ....<BR>\n";
    #foreach $key (sort by_key keys %getOpt_valid_parms ) {
    #  print "$key = $getOpt_valid_parms{$key}<BR>\n";
    #}
    print STDERR "[$getOpt_calledBy] ================================================<BR>\n";
  }

  # Now start processing the actual parameters
  
  my $parmDashInd = 0;                                              # indicates that the parameter is preceded by a dash (preceeded by - or --)
  my $parmDashes = '';

  while ($getOpt_prm_flag ne "Y") {                                 # We are still looking
    $parmDashInd = 0;
    if ( defined($PARGV[$getOpt_prm]) ) {                           # if a passed argument exists
      $getOpt_prmName = trim($PARGV[$getOpt_prm]);                  # strip whitespace from the parameter
      if ( substr($PARGV[$getOpt_prm],0,1) eq "-") {                # if it is a parameter (ie starts with a dash) then strip the leading -
        $parmDashes = '-';                                          # remember it is 1 dash
        $parmDashInd = 1;
        $getOpt_prmName = trim(substr("$getOpt_prmName  ",1));      # remove the first character
        if ( substr($getOpt_prmName,0,1) eq "-" ) {                 # if it is an extended parameter ....
          $getOpt_prmName = trim(substr("$getOpt_prmName  ",1));    # remove the first char again
          $extendedParameter = 1;                                   # flag that the parameter is extended
          $parmDashes = '--';                                        # remember it is 2 dashes
        }
      }

      # and now it gets interesting ......
      # If we are in HTML-land (ie $getOpt_web is "Y" ) then we can also also have parameters of
      # the form -p=A -d=database so a single entry may actually contain the option and
      # the parameter

      if ( $getOpt_web eq "Y" ) {                      # must cope with web parameter format as well
        if ( index($getOpt_prmName,'=') > -1 ) {      # the parm contains an = sign
          @webparm  = split('=',$getOpt_prmName);     # split it on the = sign
          if ( $getOpt_diagLevel > 0 ) {
            print "web initial: $getOpt_prmName<BR>\n";
            print "web option: $webparm[0] parm: $webparm[1]<BR>\n";
          }
          $getOpt_prmName = $webparm[0];              # establish a new parameter value
          $webParmSet = $webparm[1];                   # set the parameter value
        }
      }
      
      # construct the name to check against
      my $testParmName = $getOpt_prmName;
      if ( $getOpt_caseinsens{uc($getOpt_prmName)} ) { $testParmName = uc($getOpt_prmName); }

      if ( ( defined($getOpt_valid_parms{$testParmName} ) ) )  {  # is it a valid parameter? defined = yes
        if ( $getOpt_requiresDash{$testParmName} ) {              # check to see if the parm required a dash (and if it had one)
          if ( $parmDashInd ) {                                   # dash required and found so it is a paramter name
            $getOpt_prmName = $testParmName;                       # if it is case insensitive then make the option upper case
            setParameterIfNecessary($getOpt_prmName, $webParmSet, "");
          }
          else {                                                  # no dash so not a parameter name 
            $getOpt_optName = '*';                                # flag the fact that name isn't known
            $getOpt_optValue = $parmDashes . $testParmName;
            $getOpt_prm_flag = "Y";
          }
        }
        else {
          if ( $getOpt_caseinsens{uc($getOpt_prmName)} ) {
            $getOpt_prmName = uc($getOpt_prmName);                # if it is case insensitive then make the option upper case
          }
          setParameterIfNecessary($getOpt_prmName, $webParmSet, "");
        }
      }
      else { # it is not a valid parameter (or at least it wasn't defined)
        if ( $extendedParameter || ( length($getOpt_prmName) > 1) ) { # if it is an extended parameter (starts with -- or > 1 character in length) then a partial match may be valid
          if ( $getOpt_min_match == -1 ) { # match must be for whole parameter so it has failed
            $getOpt_optName = "*";
            $getOpt_optValue = $parmDashes . $getOpt_prmName;
            $getOpt_prm_flag = "Y";
          }
          else { # try progressive testing if the string is above or equal to the min match limit
            if ( length($getOpt_prmName) >= $getOpt_min_match ) { # big enough to try and match
              # first try case sensitive
              my $tmpIndex = index($search_valid_parms," " . $getOpt_prmName); # check to see if we can find the restricted parm name in the table
              my $tmpIndex2 = -1;     # this will hold the char position ofthe end ofthe parameter name
              my $tmpParmName = '';   # will hold the trial parameter name
              if ( $tmpIndex > -1 ) { # the string was found (so set up variables and exit loop)
                $tmpIndex2 = index($search_valid_parms," ", $tmpIndex+1); # search for the next space past the found string
                my $tmpParmName = substr($search_valid_parms, $tmpIndex+1, $tmpIndex2 - $tmpIndex - 1);
                $getOpt_prm_flag = "Y";
                $getOpt_optName = $tmpParmName;
                # Decide if a parameter is needed and get it if possible
                setParameterIfNecessary($tmpParmName, "", $getOpt_prmName);
              }
              else { # string not found so try case insensitive
                $tmpIndex = index($search_valid_parms," " . uc($getOpt_prmName)); # check to see if we can find the restricted parm name in the table
                if ( $tmpIndex > -1 ) { # the string was found , check if it is a case insensitve parameter
                  $tmpIndex2 = index($search_valid_parms," ", $tmpIndex+1); # search for the next space past the found string
                  my $tmpParmName = substr($search_valid_parms, $tmpIndex+1, $tmpIndex2 - $tmpIndex - 1);
                  if ( $getOpt_caseinsens{$tmpParmName} ) { # the parameter is case insensitive so it is a match
                    $tmpIndex2 = index($search_valid_parms," ", $tmpIndex+1); # search for the next space past the found string
                    $getOpt_prm_flag = "Y";
                    $getOpt_optName = $tmpParmName;
                    # Decide if a parameter is needed and get it if possible
                    setParameterIfNecessary($tmpParmName, "", $getOpt_prmName);
                  }
                  else { # it is not case sesitive so this isn't a match 
                    $getOpt_optName = "*";
                    $getOpt_optValue = $parmDashes . $getOpt_prmName;
                    $getOpt_prm_flag = "Y";
                  }
                }
                else { # string wasn't found 
                  $getOpt_optName = "*";
                  $getOpt_optValue = $parmDashes . $getOpt_prmName;
                  $getOpt_prm_flag = "Y";
                }
              }
            }
            else { # extended parameter but shorter then the minimum match length so fail
              $getOpt_optName = "*";
              $getOpt_optValue = $parmDashes . $getOpt_prmName;
              $getOpt_prm_flag = "Y";
            }
          }
        }
        else { # not extended parameter and not above minimum match limit
          $getOpt_optName = "*";
          $getOpt_optValue = $parmDashes . $getOpt_prmName;
          $getOpt_prm_flag = "Y";
        }
      }
      $getOpt_prm++;
    }
    else {
      $getOpt_optName = "";
      $getOpt_optValue = "";
      $getOpt_prm_flag = "Y";
      return 0;
    }
  }
  
  if ( $getOpt_web eq 'Y' ) { 
    $getOpt_optValue =~ s/\\\\/##DBS##/g  ;  # change all double backslashes to a special code
    $getOpt_optValue =~ s/\\//g  ;           # remove all surviving backslashes
    $getOpt_optValue =~ s/##DBS##/\\/g  ;    # convert special backslash code to single backslash
    $getOpt_optValue =~ s/\\'/'/g  ;    # convert special backslash code to single backslash
  }
  
  return $getOpt_optName;
}

# -----------------------------------------------------------------
# getOpt_form - function to manage the processing of passed parameters
#               similar to getOpt but no definitions. All parameters are 
#               either passed back as themselves or if there is an equals
#               sign then they are passed baclk with the element to the
#               right of the equals sign
# -----------------------------------------------------------------

sub getOpt_form {

  my $webParmSet = "";        # initially set no web parm
  my @tmpParms = ();          

  if ( ! defined($getOpt_calledBy) ) { 
    $getOpt_calledBy = "unknown module";
  }

  my $QUERY_STRING;

  if ( ! @QPARGV ) { # first pass
    # establish web input
    if ( $getOpt_web eq "Y" ) {                 # web input so check the web parameter string as well ....
      $QUERY_STRING = $ENV{'QUERY_STRING'};     # if the HTML method was GET then just preload this data 
      if ( $ENV{'REQUEST_METHOD'} eq "POST" ) { # make allowances for POST method of supplying parameters
        read(STDIN,$QUERY_STRING, $ENV{'CONTENT_LENGTH'});
      }
    }

    # check if any parms were passed on the first call
    if ( ($#_ < 0) && ($QUERY_STRING eq '')  && (! @QPARGV ) ) {
      if ( $getOpt_diagLevel > 0 ) { 
        print STDERR "[$getOpt_calledBy] No parameters passed on first pass\n";
      }
      return 0;
    }
    else { # there were parameters supplied
      if ( $#_ >= 0 ) {                   # parameters passed on the command line
          push @QPARGV, @ARGV;            # save the ARGV parameters away
      }

      # process the web parameters if any were supplied
      if ( $QUERY_STRING ne '' ) {      # there are web parameters
        @tmpParms = split (/[$parmSeparators]+/, $QUERY_STRING);
        push @QPARGV, @tmpParms;        # add the web parms to the held parm array
      }
    }
  }

  # Define the variables .....

  my $i;
  my $j;
  
  $getOpt_optName = '';                       # initialis the ename

  # process the parameter held in array entry $getOpt_prm (which holds which parm we are currently processing)
  
  if ( $#QPARGV > -1 ) { # there are parms
    if ( $getOpt_prm <= $#QPARGV ) { # we're processing an element that exists

      if ( $QPARGV[$getOpt_prm] =~ /=/ ) {                # if the parameter has an equals sign then find the vaslue
        ($getOpt_optName, $getOpt_optValue) = split ('=', $QPARGV[$getOpt_prm]); 
      }
      else {
        $getOpt_optName = $QPARGV[$getOpt_prm];
        $getOpt_optValue = $QPARGV[$getOpt_prm];
      }
    }
    $getOpt_prm++;                                       # prepare to process the next item
  }

  # replace web inserted characters
  $getOpt_optValue =~ s/\+/ /g;
  
  if ( $getOpt_optName eq '' ) { # no entry was found
    return 0;
  }
  else { # something has been found to process
    return 1;
  }

} # end of getopt_form

# -----------------------------------------------------------------
# trim - function to strip whitespace from the start and end of a 
#        string
# -----------------------------------------------------------------

sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

# -----------------------------------------------------------------
# ltrim - function to strip whitespace from the start of a string 
# -----------------------------------------------------------------

sub ltrim {
  my $string = shift;
  $string =~ s/^\s+//;
  return $string;
}

# -----------------------------------------------------------------
# rtrim - function to strip whitespace from the end of a string 
# -----------------------------------------------------------------

sub rtrim {
  my $string = shift;
  $string =~ s/\s+$//;
  return $string;
}

# -----------------------------------------------------------------
# leapYear - test if a date is a leap year 
# -----------------------------------------------------------------

sub leapYear {
  my $yr = shift;

  my $Rem = $yr % 4;
  if ( $Rem == 0 ) {
    if ( ($yr % 400) == 0) {
      return 0;
    }
    else {
      return 1;
    }
  }  
  else {
    return 0;
  }
}

# -----------------------------------------------------------------
# date - function to provide date related functions 
# -----------------------------------------------------------------

sub myDate {

  my $Base = "1965";
  my $GenDays = "N";
  my $EOY  = "N"; # End of Year
  my $EOFY = "N"; # End of Financial Year
  my $EOM  = "N"; # End of Month
  my $BOM  = "N"; # Beginning of Month Flag
  my $EDD = '';
  my $EMM = '';
  my $EYY = '';
  my $Suff = '';
  my $Month = '';
  my $NumDays = '';
  my $DOW = '';
  my $BaseDate = '';
  my $RetMSG = "";
  my @pv_pair; # array to hold parameter parm/value pair
  my $Date ; # parameter value date of the form YYYYMMDD
  my $genDays; # parameter value of the number of days since the base date
  my $BaseCentury ; # Century of the Base date
  my $BaseYear ; # Year of the base date
  my $Century ; # Will eventually be the century of the returned date
  my $Year ; # will eventually be the year of the returned date
  my $Rem ; # field use in calculating leap years
  my $LeapYear ; # indicator for a leap year
  my $DaysInYear ; #  
  my $Rem2 ; # field use in calculating leap years
  my $Tyear ; #
  my @cumDays ; # cummulative days
  my $i ; # loop variable
  my $j ; # loop variable
  my $DD ; # Day variable
  my $MM ; # month variable
  my $YY ; # year variable
  my $lastMonth;
  my $Last2Digit; # Used in establishing the date suffix
  my $LastDigit ; # Used in establishing the date suffix
  my $tmp;
  my $AddBit ; # date adjuster for date pre and post the end of February
  my $DOW19650101 = "FRI";
  my @DOWliterals = ("SUN","MON","TUE","WED","THU","FRI","SAT");
#  our $myDate_debugLevel;
  
  if ( $myDate_debugLevel > 0 ) { print "myDate Debug level set to $myDate_debugLevel\n"; }  
  
  if ($#_ == -1) {
    $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy] ";
    return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
  }

  my $prmInput = @_;
  my @parms = split(/ /,"@_");
  my $HoldDays = $parms[0];
  my $dateAdjust = 0;

  $monthDays[2] = 28;

  # so at least 1 parameter to get here ...

  if ( length($parms[0]) > 5 ) {
    if ( $parms[0] =~ /:/ ) { # of the form parm:value
      if ( uc(substr($parms[0],0,4)) eq "DATE" ) {
        @pv_pair = split(/\:/,$parms[0],2);
        $Date = $pv_pair[1];
        $GenDays = "Y";
      }
      else {
        $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\nYour Input: $prmInput ";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
    }
    elsif ($parms[0] =~ /=/) { # of the form parm=value
      if ( uc(substr($parms[0],0,4)) eq "DATE") {
        @pv_pair = split(/=/,$parms[0],2);
        $Date = $pv_pair[1];
        $GenDays = "Y";
      }
      else {
        $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\nYour Input: $prmInput ";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
    }
    else { # it is to be treated as a number of days from the base date of 01/01/1965
    }
  }

  if ($#parms > 0) { # At least 2 parameters (only the first two will be used )
    if ( length($parms[1]) > 5 ) {
      if ( $parms[1] =~ /:/ ) { # of the form parm:value
        if ( uc(substr($parms[1],0,4)) eq "BASE" ) {
          @pv_pair = split(/\:/,$parms[1],2);
          $Base = $pv_pair[1];
        }
        else {
          $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\nYour Input: $prmInput ";
          return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
        }
      }
      elsif ($parms[1] =~ /=/) { # of the form parm=value
        if ( uc(substr($parms[1],0,4)) eq "BASE") {
          @pv_pair = split(/=/,$parms[1],2);
          $Base = $pv_pair[1];
        }
        else {
          $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\nYour Input: $prmInput ";
          return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
        }
      }
      else { # it is to be treated as a number of days from the base date supplied
      }
    }
  }

  if ( length($Base) != 4 ) {
    $RetMSG = "Base date MUST be a four digit number\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\nYour Input: $prmInput ";
    return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
  }
  else {
    $BaseDate = $Base;
  }

  $BaseCentury = substr($BaseDate,0,2);
  $BaseYear = substr($BaseDate,2,2);

  if ( $GenDays eq "N" ) {
    $NumDays = $parms[0];
    $Century = $BaseCentury;
    $Year = $BaseYear;
    
    if ( $myDate_debugLevel > 0 ) { print "Processing Julian Date of $NumDays\n"; }

    # Calculate how many days between 01/01/1965 and the base date (for calculating the DOW)
    
    if ( $BaseDate ne '1965' ) { # a new base date has been set .....
      foreach my $yr  ('1965' .. $BaseDate) {
        if ( $yr ne $BaseDate ) { # only do it up to but not including the base date
          if ( leapYear($yr) ) { 
            $dateAdjust = $dateAdjust + 366;
          }
          else {
            $dateAdjust = $dateAdjust + 365;
          }
        }
      }
      if ( $myDate_debugLevel > 0 ) { print "Days between 01/01/1965 and 01/01/$BaseDate is $dateAdjust\n"; }
    }
    
    # Calculate how many full years have passed since the base date

    while ( $NumDays > 0 ) {
      $Rem = $Year % 4;
      if ( $Rem == 0 ) {
        if ( ($Year % 400) == 0) {
          $LeapYear = "No";
          $DaysInYear = 365;
        }
        else {
          $LeapYear = "Yes";
          $DaysInYear = 366;
        }
      }
      else {
        $LeapYear = "No";
        $DaysInYear = 365;
      }
      $NumDays = $NumDays - $DaysInYear;
      $Year = $Year + 1;
      if ( $Year == 100 ) {
        $Year = 0;
        $Century = $Century + 1;
      }
    }
    
    # Adjust date for the partial year

    $Year = $Year - 1;
    $Year = substr("0" . $Year, length($Year)-1,2);   # make it 2 digits
    if ( $myDate_debugLevel > 0 ) { print "The Year calculated for 01/01/$BaseDate + numDays is $Century$Year\n"; }
 
    $NumDays = $NumDays + $DaysInYear;          # NumDays is positive again and should now hold the number of days in the last year
    if ( $myDate_debugLevel > 0 ) { print "Number of days in the last year is $NumDays\n"; }

    # Adjust the array if it is a leap year
    $monthDays[2] = 28;
    $Tyear = "$Century$Year";
    $Rem = $Tyear % 4;
    if ( $Rem == 0 ) {
      $Rem2 = $Tyear % 400;
      if ( $Rem2 != 0 ) {
        $monthDays[2] = 29 ;  # it's a leap year so Feb has 29 days
      }
    }
    
    # Establish the cummulative counts .....
    $i = 2;
    $cumDays[0] = 0;
    $cumDays[1] = 0;
    for ($i ; $i < 13 ; $i++ ) {
      $lastMonth = $i - 1;
      $cumDays[$i] = $cumDays[$lastMonth] + $monthDays[$lastMonth];
    }
    
    if ( $myDate_debugLevel > 0 ) {
      print "Cummulative Month "; 
      for ( my $k = 0 ; $k <= 12 ; $k++ ) {
          print "$k value is $cumDays[$k] - "; 
      }
    }
    
    # work down through the cummulative counts until you get to the point where Numdays is greater than 
    # the cummlative day count for the year

    for ($i = 12; $i > 0 ; $i-- ) {
      if ($NumDays > $cumDays[$i]) {
        $MM = $i;
        $DD = $NumDays - $cumDays[$i];
        last;
      }
    }

    if ( $myDate_debugLevel > 0 ) { print "Calculated month is $MM as the cummulative day count was $cumDays[$i] and the number of days i the year was $NumDays\n"; }
    if ( $myDate_debugLevel > 0 ) { print "Calculated day is $DD as the difference of $NumDays and $cumDays[$i]\n"; }

    $Month = $monthName[$MM];

    # sort out the day suffix .....
    if ( length($DD) > 1 ) {
      $Last2Digit = substr($DD, length($DD) -2,2);
    }
    else {
      $Last2Digit = $DD;
    }

    $LastDigit = substr($DD, length($DD) -1,1);

    if    ($Last2Digit == 11) { $Suff = "th"; }
    elsif ($Last2Digit == 12) { $Suff = "th"; }
    elsif ($Last2Digit == 13) { $Suff = "th"; }
    elsif ($LastDigit == 1)   { $Suff = "st"; }
    elsif ($LastDigit == 2)   { $Suff = "nd"; }
    elsif ($LastDigit == 3)   { $Suff = "rd"; }
    else                      { $Suff = "th"; }

    $Year = substr("0" . $Year, length($Year)-1,2);
    $MM = substr("0" . $MM, length($MM)-1,2);
    $DD = substr("0" . $DD, length($DD)-1,2);

    if ($DD == 1) { $BOM = "Y" ; }
    if ($DD == $monthDays[$MM]) {
      $EOM = "Y";
      if ($MM == 12) {
        $EOY = "Y";
      }
      if ($MM == 6) {
        $EOFY = "Y";
      }
    }

    # work out the day of the week
    $tmp = ($HoldDays+5+$dateAdjust) % 7;
    $DOW = $DOWliterals[$tmp];

    return ($DD,$MM,$Century . $Year,$Suff,$Month,$HoldDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,'');
    if ( $myDate_debugLevel > 0 ) { print "Date is $DD$Suff of $Month, $Century$Year (NumDays=$HoldDays)\n"; }

  }
  else { # a date of the formet DATE: or DATE= was provided $Date holds that value

    if ( $myDate_debugLevel > 0 ) { print "Processing gregorian date of $Date\n"; }

    $EDD = substr($Date,6,2);
    $EMM = substr($Date,4,2);
    $EYY = substr($Date,0,4);
    $Rem = $EYY % 4;
    if ( ($EMM > 12) || ($EMM < 1) ) {
      $RetMSG = "Supplied date has an invalid month value : $EMM\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\n";
      return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
    }
    if ( $EMM == 2 ) {
      if ( ($EDD < 1) || ($EDD >29) ) {
        $RetMSG = "Supplied date has an invalid day value : $EDD (Month = $EMM -1)\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\n";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
      elsif ( ($EDD == 29) && ($Rem != 0) ) {
        $RetMSG = "Supplied date has an invalid day value : $EDD (Month = $EMM -2)\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\n";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
    }
    elsif ( ($EMM == 9) || ($EMM == 4) || ($EMM ==6) || ($EMM == 11) ) {
      if ( ($EDD < 1) || ($EDD > 30) ) {
        $RetMSG = "Supplied date has an invalid day value : $EDD (Month = $EMM -3)\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\n";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
    }
    else {
      if ( ($EDD < 1) || ($EDD > 31) ) {
        $RetMSG = "Supplied date has an invalid day value : $EDD (Month = $EMM -4)\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\n";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
    }

    $Year = "$BaseCentury$BaseYear";
    $NumDays = 0;
    while ( $Year != $EYY ) {
      $Rem = $Year % 4;
      if ( $Rem == 0 ) {
        if ( ($Year % 400) == 0) {
          $LeapYear = "No";
          $DaysInYear = 365;
        }
        else {
          $LeapYear = "Yes";
          $DaysInYear = 366;
        }
      }
      else {
        $LeapYear = "No";
        $DaysInYear = 365;
      }
     $NumDays = $NumDays + $DaysInYear;
     $Year = $Year + 1;
     if ( $myDate_debugLevel > 0 ) {  print "NumDays=$NumDays Year=$Year LeapYear=$LeapYear Days in Year=$DaysInYear\n"; }
    }
    $Rem = $EYY % 4;
    $AddBit = 0;
    if ( $Rem == 0 ) {
      $Rem2 = $EYY % 400;
      if ($Rem2 != 0) {
        $AddBit = 1;
      }
    }

    if ($AddBit == 1) { # adjust Feb days .....
      $monthDays[2] = $monthDays[2] + 1;
    }

    $i = 2;
    $cumDays[0] = 0;
    $cumDays[1] = 0;
    for ($i ; $i < 13 ; $i++ ) {
      $lastMonth = $i - 1;
      $cumDays[$i] = $cumDays[$lastMonth] + $monthDays[$lastMonth];
    }

    if ( $myDate_debugLevel > 0 ) { for ( my $k = 0 ; $k <= $#cumDays ; $k++ ) { print "Cummlative month $k: $cumDays[$k]\n"; } }

    $Month = $monthName[$EMM];
    $NumDays = $NumDays + $cumDays[$EMM] + $EDD;
    if ( $myDate_debugLevel > 0 ) { print "Total days to beginning of this month: $cumDays[$EMM], days this month: $EDD\n"; }

    if ($EDD == 1) { $BOM = "Y" ;}
    if ($EDD == $monthDays[$EMM]) {
      $EOM = "Y";
      if ($EMM == 12) {
        $EOY = "Y";
      }
      if ($EMM == 6) {
        $EOFY = "Y";
      }
    }

    if ( length($EDD) > 1 ) {
      $Last2Digit = substr($EDD, length($EDD) -2,2);
    }
    else {
      $Last2Digit = $EDD;
    }

    $LastDigit = substr($EDD, length($EDD) -1,1);

    if    ($Last2Digit == 11) { $Suff = "th"; }
    elsif ($Last2Digit == 12) { $Suff = "th"; }
    elsif ($Last2Digit == 13) { $Suff = "th"; }
    elsif ($LastDigit == 1)   { $Suff = "st"; }
    elsif ($LastDigit == 2)   { $Suff = "nd"; }
    elsif ($LastDigit == 3)   { $Suff = "rd"; }
    else                      { $Suff = "th"; }

    $tmp = ($NumDays+5) % 7;
    $DOW = $DOWliterals[$tmp];

    if ( $myDate_debugLevel > 0 ) { print "Date of $Date ($EDD$Suff of $Month, $EYY) has a value of $NumDays\n"; }
    return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,'');
  }
}

# -----------------------------------------------------------------
# processDirectory - function to traverse a directory tree
# -----------------------------------------------------------------

sub processDirectory { # routine to process a directory entry

  my $directory = shift;
  my $depth = shift;
  my $dirProc = shift;
  my $fileProc = shift;
  
  $depth++;
  
  if ( ($maxDepth == -1 ) || ($depth <= $maxDepth ) ) { 
  
    opendir(my $dh, $directory) || die;
    while(readdir $dh) {
  
      if ( ($_ eq '.') || ($_ eq '..') ) { next; } # skip directory elememnts . and ..
      if ( -l "$directory/$_" )  { next; }         # skip symlinks 
  
      if ( -d "$directory/$_" )  {                 # process the directory entry
        if ( defined($dirProc) ) {                 # if a subroutine has been passed 
          $dirProc -> ("$directory/$_",$depth);    # call the passed subroutine
        }
        processDirectory("$directory/$_", $depth,$dirProc,$fileProc);   # recursively call this routine rto process other directories
        $dirCnt ++;
      }
      else {                                       # it is a file
        if ( defined($fileProc) ) {                # if a subroutine has been passed 
          $fileProc -> ("$directory/$_",$depth);   # call the passed subroutine
        }
        $fileCnt++;
      }
    }
    closedir $dh; 
  }
  
  $depth--;
  
}

# -----------------------------------------------------------------
# localDateTime - convert a seconds since the epoch value to a local date/time
# -----------------------------------------------------------------

sub localDateTime {
  
  my $inDate = shift;
  
  my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = localtime $inDate;  # convert it
  
  $day = substr("0" . $day, length($day)-1,2);       # pad the day number to 2 digits
  $mon = $mon + 1;                                   # adjust the month value
  $mon = substr("0" . $mon, length($mon)-1,2);       # pad the month value to 2 digits
  $hour = substr("0" . $hour, length($hour)-1,2);       # pad the day number to 2 digits
  $min = substr("0" . $min, length($min)-1,2);       # pad the day number to 2 digits
  $sec = substr("0" . $sec, length($sec)-1,2);       # pad the day number to 2 digits
  if ( $year < 70) {                                    # epoch is at 1/1/1970 so dont let the date be any earlier
    $year = "70";
    $mon = "01";
    $day = "01";
  }
  my $yyyy_mm_dd = (1900 + $year) . '-' . $mon . '-' . $day;
  return ($yyyy_mm_dd . ' ' . $hour . ':' . $min . ':' . $sec);
}

# -----------------------------------------------------------------
# convertToTimestamp - convert a datetime to a standard timestamp format
# The script will attempt to figure out he format of the input date
# -----------------------------------------------------------------

sub convertToTimestamp {

  # Supported input formats:
  #      1. Sep 17, 2017 6:00:07 PM
  #
  # The output format will always be:
  #         2017.09.17 18:00:07
  
  my $inDate = shift;

  my ( $sec, $min, $hour, $day, $mon, $year);

  # check for quotes ..... (and remove them)

  if ( $inDate =~ /^".*"$/ ) {
    ($inDate) = ($inDate =~ /^"(.*)"$/);
  }

  my @part = split(" ", $inDate);

  if ( ! defined($part[4]) ) { # 4 parts not found - ignore call
    return '';
  }

  # process month
  if ( ! defined($monthNumber{$part[0]}) ) { # month not entered as the first parameter - return with no result
    return '';
  }
  else {
    $mon = $monthNumber{$part[0]};
  }
  
  my @tmp;
  # process the day .....
  if ( $part[1] =~ /,/ ) {
    @tmp = split(",", $part[1]); 
    $day = trim($tmp[0]); # just dropping the comma
  }
  else {
    $day = trim($part[1]);
  }
   
  # process the year .....
  $year = trim($part[2]); 

  # process the time .....
  @tmp = split(":", $part[3]); 
  $hour = trim($tmp[0]);
  $min = trim($tmp[1]);
  $sec = trim($tmp[2]);

  if ( ($part[4] eq 'PM') && ( $hour < 12 ) ) { $hour = $hour + 12; } # adjust to 24 hr clock
   
  # fill out numeric fields
  
  $day = substr("0" . $day, length($day)-1,2);       # pad the day number to 2 digits
  $mon = substr("0" . $mon, length($mon)-1,2);       # pad the month value to 2 digits
  $hour = substr("0" . $hour, length($hour)-1,2);    # pad the day number to 2 digits
  $min = substr("0" . $min, length($min)-1,2);       # pad the day number to 2 digits
  $sec = substr("0" . $sec, length($sec)-1,2);       # pad the day number to 2 digits
  
  return ($year . '.' . $mon . '.' . $day . ' ' . $hour . ':' . $min . ':' . $sec);
}

1;


