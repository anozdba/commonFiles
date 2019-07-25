#!/usr/bin/perl
# --------------------------------------------------------------------
# calculator.pm
#
# $Id: calculator.pm,v 1.22 2019/07/16 23:52:27 db2admin Exp db2admin $
#
# Description:
# Package to evaluate a infix calculation string
#
# Usage:
#   use calculator.pm
#   $x = evaluateInfix("1+2 + 3/ 45 * (4/5)";
#   This is a subroutine and not a stand alone program - it must be called from
#   another program
#
# $Name:  $
#
# ChangeLog:
# $Log: calculator.pm,v $
# Revision 1.22  2019/07/16 23:52:27  db2admin
# move debug messages to STDERR
#
# Revision 1.21  2019/02/13 05:00:07  db2admin
# 1. Timestamp subtraction now allows duration, time and timestamp subtraction
# 2. Added in extra tests in the calcTestRoutine to test new functionality
#
# Revision 1.20  2019/02/07 04:17:33  db2admin
# remove timeAdd from the use list as the module is no longer provided
#
# Revision 1.19  2019/02/05 22:46:56  db2admin
# 1. move performDateAddition,performDateSubtraction,performTimestampAddition and performTimestampSubtraction to commonFunctions.pm
# 2. correct bug in subtraction for non-date/timestamps
# 3. remove myDate and myTime and replace with getCurrentTimestamp
# 4. remove isNumeric and replace with the commonFunctions.pm version
# 5. remove isTimestamp as it is not used
#
# Revision 1.18  2019/02/02 05:02:53  db2admin
# 1. Add in timestamp/date subtraction
# 2. extend calTestRoutine to include tests for timestamp/date subtractio
#
# Revision 1.17  2019/02/01 02:41:41  db2admin
# 1. change all currentSubroutine to currentRoutine
# 2. add in performDateAddition fro doing date addition
# 3. add in performTimestampAddition for doing timestamp addition
# 4. modify addition section to validate and cope with date/timestamp addition
# 5. alter the way that the test routines to run are selected
#
# Revision 1.16  2019/01/25 03:20:00  db2admin
# 1. adjust commonFunctions.pm parameter importing to match module definition
# 2. preliminary changes fro timestamp arithmetic
#
# Revision 1.15  2019/01/22 23:21:19  db2admin
# 1. Add in a displayERRROR routine to standardise output
# 2. Allow the passing of a calling routine token to be displayed alongside the error
#    to simplify debugging
# 3. Add in parameter to switch errors between STDOUT and STDERR
# 4. Display the current equation being processed when errors are encountered.
#
# Revision 1.14  2018/05/29 04:22:42  db2admin
# modify code to return an error rather than divide by zero
#
# Revision 1.13  2018/03/23 00:10:59  db2admin
# correct handling of multi character operators
#
# Revision 1.12  2018/01/11 20:25:20  db2admin
# correct an issue with unary operators
#
# Revision 1.11  2018/01/10 00:18:12  db2admin
# 1. Corrected function processing
# 2. improved tests
# 3. continued overhaul of code
# 4. implemented 1 operator (not)
#
# Revision 1.10  2018/01/08 20:41:41  db2admin
# change the name back to calculator
#
# Revision 1.9  2018/01/08 20:39:25  db2admin
# majoroverhaul of code
# added in processing for unary operators
#
# Revision 1.8  2018/01/04 00:16:37  db2admin
# 1. Add in some calculator tests to the calcTestRoutine
# 2. correct a parsing bug that would split skeleton into 3 tokens
#
# Revision 1.7  2017/06/13 09:48:10  db2admin
# make NE and EQ also valid comparison operators
#
# Revision 1.6  2016/06/24 01:53:54  db2admin
# modify to ensure that input strings are always treated as operands and never as operators
#
# Revision 1.5  2015/10/25 21:15:08  db2admin
# add in comparison operators GT, GE, LT, LE, EQ and NE
#
# Revision 1.4  2015/09/28 01:wait:17:56  db2admin
# correct issue when there is only one thing on the stack
#
# Revision 1.3  2015/04/15 22:33:29  db2admin
# correct displayDebug so that it works
# correct calculate function to work with 2 character operators
#
# Revision 1.2  2014/10/14 05:26:13  db2admin
# make sure debug output is written to debug
#
# Revision 1.1  2014/10/09 02:07:11  db2admin
# Initial revision
#
# --------------------------------------------------------------------"

package calculator;

use strict;

use commonFunctions qw(trim ltrim rtrim commonVersion getOpt isNumeric isValidDate isValidTimestamp isValidTimestampFormat myDate $getOpt_web $getOpt_optName $getOpt_min_match $getOpt_optValue getOpt_form @myDate_ReturnDesc $cF_debugLevel $getOpt_calledBy $parmSeparators processDirectory $maxDepth $fileCnt $dirCnt localDateTime displayMinutes timeDiff  timeAdj convertToTimestamp getCurrentTimestamp isValidDate processDuration performDateAddition performDateSubtraction performTimestampAddition performTimestampSubtraction isValidTime performTimeAddition performTimeSubtraction convertTimestampDuration);

# export parameters ....
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(evaluateInfix calcVersion $calcDebugLevel $calcFunctions $calcOperators %opPrecedence calcTestRoutine $calcTestRoutines $calcDebugModules $calcOperatorsAlpha $calc_errorToSTDOUT) ;

our $calcDebugModules = 'All';
our $calcDebugLevel = 0;
our $calcFunctions = " ABS SUBSTR LEFT RIGHT TRIM LTRIM RTRIM ";                # list of strings to be treated as function (can be modified)
our $calcOperatorsAlpha = ' OR AND GT GE LT LE NE EQ ';                         # list of strings to be treated as alpha operators (can be modified)
our $possibleUnaryOperators = ' ! - + ';                                        # possible unary operators (i.e only one operand).
our $unaryOperators = ' ! U- U+ ';                                              # unary operators (i.e only one operand). Note u- is - and u+ is + (adjusted)
our $calcOperators = ' + - * / % || > >= < <= <> = == =~ ! ' . $calcOperatorsAlpha;  # list of strings to be treated as token terminators (can be modified)
our %opPrecedence;
our $calc_errorToSTDOUT = 0;

# initialise precedence
$opPrecedence{'OR'} = 1;
$opPrecedence{'AND'} = 1;
$opPrecedence{'GT'} = 1;
$opPrecedence{'>'} = 1;
$opPrecedence{'>='} = 1;
$opPrecedence{'GE'} = 1;
$opPrecedence{'<'} = 1;
$opPrecedence{'LT'} = 1;
$opPrecedence{'<='} = 1;
$opPrecedence{'LE'} = 1;
$opPrecedence{'<>'} = 1;
$opPrecedence{'NE'} = 1;
$opPrecedence{'=='} = 1;
$opPrecedence{'=~'} = 1;
$opPrecedence{'EQ'} = 1;
$opPrecedence{'='} = 1;
$opPrecedence{'*'} = 4;
$opPrecedence{'/'} = 4;
$opPrecedence{'%'} = 4;
$opPrecedence{'+'} = 3;
$opPrecedence{'-'} = 3;
# unary operators
$opPrecedence{'!'} = 4;
$opPrecedence{'u-'} = 4;
$opPrecedence{'u+'} = 4;

our $calcTestRoutines = oct'0b11111111';   # variable containing which tests to run in the testRoutine sub

# Global defs

my @stack ; # evaluation stack
my @output ; # output stack
my @operandStack ; # operand stack used when evaluating reverse polish expression
my $currentTokenPosition = -1; # current parsing position in string being evaluated
my $currentTokenIsString = 0; # current token type
my $sourceLiteral = ''; # source literal to be used in error messages
my $infixString = '';       # the statement being processed

sub calcTestRoutine {
  # -----------------------------------------------------------
  # routine to test the subroutines/functions in this package
  # -----------------------------------------------------------

  my $currentRoutine = 'calcTestRoutine';
  $calcTestRoutines = shift;
  my $testString = "";
  my $test = '';
  my $expectedRes = '';

  print "Starting Calulator test (" . oct($calcTestRoutines) . ")\n";

  if ( oct($calcTestRoutines) & oct('0b000000000000001') ) { # check easy math
    print "Testing : 1+2+3+4+5 (answer should be 15)\n";
    my $result = evaluateInfix('1+2+3+4+5');
    if ( $result != 15 ) { print "FAIL - returned $result when the answer should have been 15)\n"; }
    else { print "OK   - returned $result\n"; }
  }

  if ( oct($calcTestRoutines) & oct('0b000000000000010') ) { # check more complicated math
    print "Testing : 1 - (15+3)*16/8 + 1 (answer should be -34)\n";
    my $result = evaluateInfix('1 - (15+3)*16/8 + 1');
    if ( $result != -34 ) { print "FAIL - returned $result when the answer should have been -34)\n"; }
    else { print "OK   - returned $result\n"; }
  }

  if ( oct($calcTestRoutines) & oct('0b000000000000100') ) { # loadSkeleton test
    print "Testing : skeleton || bone (answer should be 'skeletonbone')\n";
    my $result = evaluateInfix('skeleton || bone');
    if ( $result ne 'skeletonbone' ) { print "FAIL - returned $result when the answer should have been skeletonbone)\n"; }
    else { print "OK   - returned $result\n"; }
  }

  if ( oct($calcTestRoutines) & oct('0b000000000001000') ) { # unary operator test
    print "Testing : (1 - (15+3)*16/8 + (-1)) * -2 (answer should be 72)\n";
    my $result = evaluateInfix('(1 - (15+3)*16/8 + (-1)) * -2');
    if ( $result != 72 ) { print "FAIL - returned $result when the answer should have been 72)\n"; }
    else { print "OK   - returned $result\n"; }
  }
  
  if ( oct($calcTestRoutines) & oct('0b000000000010000') ) { # testing functions
    print "Testing : substr(\"teSt\",2,1) (answer should be S)\n";
    my $result = evaluateInfix('substr("teSt",2,1)');
    if ( $result ne "S" ) { print "FAIL - returned $result when the answer should have been S)\n"; }
    else { print "OK   - returned $result\n"; }
    print "Testing : substr(\"teSt\",2) (answer should be St)\n";
    $result = evaluateInfix('substr("teSt",2)');
    if ( $result ne "St" ) { print "FAIL - returned $result when the answer should have been St)\n"; }
    else { print "OK   - returned $result\n"; }
    print "Testing : substr(\"teSting\",(2+4)*2/3-2,3) (answer should be Sti)\n";
    $result = evaluateInfix('substr("teSting",(2+4)*2/3-2,3)');
    if ( $result ne "Sti" ) { print "FAIL - returned $result when the answer should have been Sti)\n"; }
    else { print "OK   - returned $result\n"; }
    print "Testing : substr(\"teSting\",4,-2) (answer should be i)\n";
    $result = evaluateInfix('substr("teSting",4,-2)');
    if ( $result ne "i" ) { print "FAIL - returned $result when the answer should have been i)\n"; }
    else { print "OK   - returned $result\n"; }
  }

  if ( oct($calcTestRoutines) & oct('0b000000000100000') ) { # testing date/time arithmertic

    print "\n***** Testing Date/Time arithmetic tests ....\n";
    print "***** Simple timestamp/durations arithmetic .... \n\n";

    $test = "'2018-12-01 23:49:01' + '22 minutes'";
    $expectedRes = "2018-12-02 00:11:01";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2016-02-28 23:49:01' + '22 minutes 4 days 1 year'";
    $expectedRes = "2017-03-04 00:11:01";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2018-12-01 00:19:01' + '-22 minutes'";
    $expectedRes = "2018-12-01 00:41:01";
    print "Testing : \"$test\" ( Testing the ignoring of negative values in duration - answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2016-03-01 00:19:01' - '22 minutes 4 days 1 year'";
    $expectedRes = "2015-02-25 23:57:01";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2018-12-01 00:19:01' - '22 minutes'";
    $expectedRes = "2018-11-30 23:57:01";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    print "\n***** Simple date/durations arithmetic .... \n\n";

    $test = "'2016-02-28' + '4 days 1 year'";
    $expectedRes = "2017-03-03";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2016-02-28' + '4 days 1 year +6 minute'";
    $expectedRes = "2017-03-03 00:06:00";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2016-03-01' - '4 days 1 year'";
    $expectedRes = "2015-02-26";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2016-03-01' - '4 days 1 year 6 minute'";
    $expectedRes = "2015-02-25 23:54:00";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    print "\n***** Simple date/durations arithmetic .... \n\n";

    $test = "'23:23:04' + '1 hour 58 seconds'";
    $expectedRes = "0000-00-01 00:24:02";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    print "\n***** Timestamp subtraction .... \n\n";

    $test = "'2016-03-01 00:19:01' - '2016-02-27 00:18:01'";
    $expectedRes = "4321";
    print "Testing : \"$test\" converted to minutes (answer should be '$expectedRes')\n";
    my $result = convertTimestampDuration(evaluateInfix( $test ),'M');
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2016-03-01 00:19:01' - '2016-02-27 00:18:01'";
    $expectedRes = "0000-00-03 00:01:00";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2016-03-01 00:19:01' - '0000-00-03 00:01:00'";
    $expectedRes = "2016-02-27 00:18:01";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2016-03-01 00:19:01' - '00:22:05'";
    $expectedRes = "2016-02-29 23:56:56";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    print "\n***** Time Arithmetic .... \n\n";

    $test = "'09:23:04' - '10 hours 6 minute'";
    $expectedRes = "0000-00-01 23:17:04";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'09:23:04' - '10:25:06'";
    $expectedRes = "0000-00-01 22:57:58";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'23:23:04' + '01:39:57'";
    $expectedRes = "0000-00-01 01:03:01";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    print "\n***** Date Subtraction .... \n\n";

    $test = "'2019-09-18' - '2018-09-18'";
    $expectedRes = "365";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2016-09-18' - '2015-09-18'";
    $expectedRes = "366";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

    $test = "'2016-09-18' - '2016-07-18'";
    $expectedRes = "62";
    print "Testing : \"$test\" (answer should be '$expectedRes')\n";
    my $result = evaluateInfix( $test );
    if ( $result ne $expectedRes ) { print "FAIL - returned $result when the answer should have been '$expectedRes')\n"; }
    else { print "OK   - returned $result\n"; }

  }

 
} # end of calcTestRoutine

sub calcVersion {
  # --------------------------------------------------------------------"
  # Routine to return the version number of the calculator package
  #
  # Usage: calcVersion();
  # Returns: a string like .... "$name ($Version)  Last Changed on $Changed (UTC)"
  # --------------------------------------------------------------------"

  my $currentRoutine = 'calcVersion';
  my $ID = '$Id: calculator.pm,v 1.22 2019/07/16 23:52:27 db2admin Exp db2admin $';

  my @V = split(/ /,$ID);
  my $nameStr=$V[1];
  my ($name,$x) = split(",",$nameStr);
  my $Version=$V[2];
  my $Changed="$V[3] $V[4]";

  return "$name ($Version)  Last Changed on $Changed (UTC)";

} # end of calcVersion

sub displayError {
  # -----------------------------------------------------------
  # This routine will display the error passed to it
  #
  # usage: displayError("<message>");
  # returns: nothing
  # -----------------------------------------------------------

  my $lit  = shift;
  my $sub = shift;
  my $TS = getCurrentTimestamp();
  my $sourceDisplay = '';
  
  if ( $sourceLiteral ne '' ) { $sourceDisplay = "- [$sourceLiteral] "; }
  
  if ( ! defined($sub) ) { $sub = "Unknown Subroutine" } # if nothing passed then default

  if ( ! defined( $lit ) ) { # Nothing to display so just display the date and time
    if ( $calc_errorToSTDOUT ) {
      print "$sub - $TS - $sourceDisplay- ERROR\n";
      print "$sub - $TS - $sourceDisplay: ERROR : Statement being processed was: $infixString\n";
    }
    else {
      print STDERR "$sub - $TS - $sourceDisplay- ERROR\n";
      print STDERR "$sub - $TS - $sourceDisplay: ERROR : Statement being processed was: $infixString\n";
    }
  }
  else {
    if ( $calc_errorToSTDOUT ) {
      print "$sub - $TS - $sourceDisplay: ERROR : $lit\n";
      print "$sub - $TS - $sourceDisplay: ERROR : Statement being processed was: $infixString\n";
    }
    else {
      print STDERR "$sub - $TS - $sourceDisplay: ERROR : $lit\n";
      print STDERR "$sub - $TS - $sourceDisplay: ERROR : Statement being processed was: $infixString\n";
    }
  }
} # end of displayError

sub displayDebug {
  # -----------------------------------------------------------
  # this routine will display the debug information as required
  # based on the passed debugLevel
  #
  # usage: displayDebug("<message>",<debugLevel at which to display>);
  # returns: nothing
  # -----------------------------------------------------------

  my $lit = shift;
  my $call_debugLevel = shift;
  my $sub = shift;
  my $uc_sub = uc($sub);

  if ( uc($calcDebugModules) ne 'ALL') {          # check if the default all is being used
    if ( uc("$calcDebugModules") !~ /$uc_sub/ ) { # check if the module is one the ones selected
      return;                                     # dont print anything
    }
  }


  if ( ! defined($lit) ) { $lit = "" } # if nothing passed then default to empty string
  if ( ! defined($sub) ) { $sub = "Unknown Subroutine" } # if nothing passed then default

  if ( ! defined($call_debugLevel) ) { # if debug level not specified then set it to 1
    $call_debugLevel = 1;
  }

  # Display a passed message with timestamp if the skelDebugLevel has been set

  if ( $call_debugLevel <= $calcDebugLevel ) {
    my $TS = getCurrentTimestamp();

    if ( $lit eq "") { # Nothing to display so just display the date and time
      print STDERR "$sub - $TS\n";
    }
    elsif ( $lit eq "DUMPSTACK" ) {
      print STDERR "Dumping STACK ($#stack entries) \n";
      for ( my $i = 0; $i <= $#stack; $i++ ) { print STDERR "$sub - $TS : Stack $i : $stack[$i] [tot $#stack]\n"; }
    }
    elsif ( $lit eq "DUMPOUTPUT" ) {
      print STDERR "Dumping OUTPUT STACK ( $#output entries) \n";
      for ( my $i = 0; $i <= $#output; $i++ ) { print STDERR "$sub - $TS : Output Stack $i : $output[$i] [tot $#output]\n"; }
    }
    elsif ( $lit eq "DUMPOPSTACK" ) {
      print STDERR "Dumping OPERAND STACK ( $#operandStack entries) \n";
      for ( my $i = 0; $i <= $#operandStack; $i++ ) { print STDERR "$sub - $TS : Operand Stack $i : $operandStack[$i] [tot $#operandStack]\n"; }
    }
    else {
      print STDERR "$sub - $TS : $lit\n";
    }
  }
} # end of displayDebug

sub getCalculateToken {
  # --------------------------------------------------------------------"
  # Routine to return the next token from the string being processed
  #
  # Usage: getCalculateToken("Input String");
  # Returns: <next space delimited token>
  # --------------------------------------------------------------------"

  my $currentRoutine = 'getCalculateToken';
  my $tLine = shift;
  my $tTok = "";

  my $currChar = '';

  displayDebug("Line: $tLine Start Pos: $currentTokenPosition",2,$currentRoutine);

  # Skip whitespace
  while ( ($currentTokenPosition <= length($tLine)) && (substr($tLine,$currentTokenPosition,1) =~ /\s/) ) {
    $currentTokenPosition++;
  }

  $currentTokenIsString = 0;
  # Set token value
  if ( (substr($tLine,$currentTokenPosition,1) eq "\'" ) || (substr($tLine,$currentTokenPosition,1) eq "\"" ) ) { # it starts with a quote
    $currentTokenIsString = 1;
    my $tmpTerm = substr($tLine,$currentTokenPosition,1); # set the value being looked for
    my $j = 0;                                           # have to define it outside the for loop so it can be tested after the loop
    for ( $j = $currentTokenPosition+1; $j <= length($tLine); $j++ ) { # loop through the string ....
      my $myChar = substr($tLine,$j,1);                  # myChar now contains the character being tested
      displayDebug("\$myChar: $myChar",1,$currentRoutine);
      if ( ($myChar eq $tmpTerm) && (substr($tLine,$j+1,1) ne $tmpTerm) ) { # found a matching quote (that hasn't been escaped)
        #$tTok .=  substr($tLine,$j,1);
        $j++; # skip the trailing quote
        last; # finish up checking
      }
      elsif ( ($myChar eq $tmpTerm) && (substr($tLine,$j+1,1) eq $tmpTerm) ) { # 2 quotes in a row so add them both ...
        $tTok .=  substr($tLine,$j,2);
        $j++; # skip processing the second quote
      }
      else { # just keep looking ...
        $tTok .= substr($tLine,$j,1);
      }
    }
    $tTok = ':"' . $tTok ;    # indicates that this is a string
    $currentTokenPosition = $j;
  }
  else { # just provide the next whitespace or operator delimited token
    displayDebug("Token is not a string. Terminating character has been set as whitespace(ish) >>" . substr($tLine,$currentTokenPosition) ,2,$currentRoutine);
    while ( ($currentTokenPosition <= length($tLine) ) && (substr($tLine,$currentTokenPosition,1) ne ' ') ) { # while still chars left and char is not space
      displayDebug(">>>>>>\$currentTokenPosition = $currentTokenPosition, char = " . substr($tLine,$currentTokenPosition,1) . ", tLine = $tLine, tTok = $tTok",2,$currentRoutine);
      $currChar = substr($tLine,$currentTokenPosition,1);
      $tTok .= $currChar;                              # add the current character to the token
      $currentTokenPosition++;                         # move to the next character
      if ( $currentTokenPosition <= length($tLine) ) {
        # Stop if the token is the longest operator it can be (operators max out at 3 chars)
        if ( (isOperator($tTok)) &&
             (! isOperator($tTok . substr($tLine,$currentTokenPosition,1))) &&   # not a 2 character operator
             (! isOperator($tTok . substr($tLine,$currentTokenPosition,2)))      # not a 3 character operator
           ) {
          last;
        }
        # check if the next chars are an operator
        displayDebug("next byte = " . substr($tLine,$currentTokenPosition,1) . ", next 2 bytes = " . substr($tLine,$currentTokenPosition,2) . ",tTok = $tTok",2,$currentRoutine);
        if ( (isOperator(substr($tLine,$currentTokenPosition,1))) ||              # next char is an operator
             (isOperator(substr($tLine,$currentTokenPosition,2))) ) {             # next 2 chars are an operator
          # so at this stage the next 1 or 2 characters are an operator ....
          # an operator will terminate a token (unless it is an alpha token and the last token char was alpha too)
          if ( isNumeric($currChar) ) { last; }        # the last character processed was a number so it terminates the token
          elsif ( (   isOperator($tTok) ) &&              # current token is an operator
                  ( ! isAlphaOperator($tTok) ) )  {
            # do nothing ...... it is a non alpha operator and may be multi character
          }
          else {                                       # the last character was an alpha character
            # now we need to check to see if the next characters weren't alpha operators (in which case we dont class them as such)
            if ( (! isAlphaOperator(substr($tLine,$currentTokenPosition,1))) &&      # was not a single char alpha operator
                 (! isAlphaOperator(substr($tLine,$currentTokenPosition,2))) ) {     # wasnot a 2 char alpha operator
              displayDebug("Token terminated as following token is a non alpha operator",2,$currentRoutine);
              last;
            }
          }
        }
        # Stop if the next char to be processed would be a one of ')', ',' or '('
        if ( index(' ) , ( ', substr($tLine,$currentTokenPosition,1)) > -1 ) {
          displayDebug("Next character is one of \), \( or \,",2,$currentRoutine);
          last;
        }
        # Stop if the current token is a comma
        if ( $tTok eq ',' ) {
          displayDebug("Token is a comma",1,$currentRoutine);
          last;
        }
        # stop if the token is an opening parethesis
        if ( $tTok eq "\(" ) {
          displayDebug("Token is \(",2,$currentRoutine);
          last;
        }
      }
    }
  }

  displayDebug("Token identified was: $tTok",2,$currentRoutine);
  return $tTok;

} # end of getCalculateToken



sub isFunction {
  # -----------------------------------------------------------
  # Routine to check if a supplied parameter is a function
  #
  # Usage: isFunction('LEFT');
  # Returns: 0 - not function , 1 function
  # -----------------------------------------------------------

  my $currentRoutine = 'isFunction';
  my $tok = shift;

  if ( index($calcFunctions, uc(" " . $tok . " ")) > -1 ) { return 1; }

  return 0;
} # end of isFunction

sub isOperator {
  # -----------------------------------------------------------
  # Routine to check if a supplied parameter is an operator
  #
  # Usage: isOperator('+');
  # Returns: 0 - not operator , 1 - is operator
  # -----------------------------------------------------------

  my $currentRoutine = 'isOperator';
  my $tok = shift;

  if ( index($calcOperators, uc(" " . $tok . " ")) > -1 ) { return 1; }

  return 0;
} # end of isOperator

sub isPossibleUnaryOperator {
  # -----------------------------------------------------------
  # Routine to check if a supplied parameter is a possible unary operator
  #
  # Usage: isPossibleOperator('+');
  # Returns: 0 - not a possible unary operator , 1 - is possibly a unary operator
  # -----------------------------------------------------------

  my $currentRoutine = 'isPossibleUnaryOperator';
  my $tok = shift;

  if ( index($possibleUnaryOperators, uc(" " . $tok . " ")) > -1 ) { return 1; }

  return 0;
} # end of isPossibleUnaryOperator

sub isUnaryOperator {
  # -----------------------------------------------------------
  # Routine to check if a supplied parameter is an unary operator
  #
  # Usage: isOperator('+');
  # Returns: 0 - not unary operator , 1 - is unary operator
  # -----------------------------------------------------------

  my $currentRoutine = 'isUnaryOperator';
  my $tok = shift;

  if ( index($unaryOperators, uc(" " . $tok . " ")) > -1 ) { return 1; }

  return 0;
} # end of isUnaryOperator

sub isAlphaOperator {
  # -----------------------------------------------------------
  # Routine to check if a supplied parameter is an alpha operator
  #
  # Usage: isAlphaOperator('+');
  # Returns: 0 - not alpha operator , 1 - is alpha operator
  # -----------------------------------------------------------

  my $currentRoutine = 'isAlphaOperator';
  my $tok = shift;

  if ( index($calcOperatorsAlpha, uc($tok)) > -1 ) { return 1; }

  return 0;
} # end of isAlphaOperator

sub evaluateFunction {
  # -----------------------------------------------------------
  # Routine to evaluate a function
  #
  # Usage: $x = evaluateFunction($functionName, \$parmArray);
  # Returns: the calculated value
  # -----------------------------------------------------------

  my $currentRoutine = 'evaluateFunction';

  my $function = shift;
  my $arrayRef = shift;
  my @parms = @{$arrayRef};
  
  if ( $#parms == -1 ) { return ; } # if no parameters are passed then just return

  my $op1 = '';
  my $op2 = '';
  my $op3 = '';

  if ( $calcDebugLevel > 2 ) { for ( my $i = 0 ; $i <= $#parms ; $i++ ) {  print "Param Array #### $i ..... $parms[$i]\n"; } } 
  
  if ( uc($function) eq "ABS" ) {
    # only one parameter to be processed
    displayDebug("Operand = $parms[0] : operator is $function",1,$currentRoutine);
    return abs($parms[0]);
  }
  elsif ( uc($function) eq "SUBSTR" ) {
    if ( $#parms == 0 ) { # only 1 parameter so just return it
      displayDebug("$#parms parameter passed to $function (string just returned",1,$currentRoutine);
      return $parms[0];
    }
    elsif ( $#parms == 1 ) { # 2 parms so dont pass length
      displayDebug("$#parms parameters passed to $function (processed as 2)",1,$currentRoutine);
      return substr($parms[1],$parms[0]); 
    }
    else { # only use the first 3 parameters
      displayDebug("$#parms parameters passed to $function (processed as 3)",1,$currentRoutine);
      return substr($parms[2],$parms[1],$parms[0]); 
    }
  }
  elsif ( uc($function) eq "LEFT" ) {
    if ( $#parms == 0 ) { # only 1 parameter so just return it
      displayDebug("$#parms parameter passed to $function (string just returned",1,$currentRoutine);
      return $parms[0];
    }
    else { # only use the first 2 parameters
      displayDebug("$#parms parameters passed to $function (processed as 2)",1,$currentRoutine);
      return left($parms[1],$parms[0]); 
    }
  }
  elsif ( uc($function) eq "RIGHT" ) {
    if ( $#parms == 0 ) { # only 1 parameter so just return it
      displayDebug("$#parms parameter passed to $function (string just returned",1,$currentRoutine);
      return $parms[0];
    }
    else { # only use the first 2 parameters
      displayDebug("$#parms parameters passed to $function (processed as 2)",1,$currentRoutine);
      return right($parms[1],$parms[0]); 
    }
  }
  elsif ( uc($function) eq "TRIM" ) {
    # only one parameter to be processed
    displayDebug("Operand = $parms[0] : operator is $function",1,$currentRoutine);
    my $val = $parms[0];
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    return $val;
  }
  elsif ( uc($function) eq "LTRIM" ) {
    # only one parameter to be processed
    displayDebug("Operand = $parms[0] : operator is $function",1,$currentRoutine);
    my $val = $parms[0];
    $val =~ s/^\s+//;
    return $val;
  }
  elsif ( uc($function) eq "RTRIM" ) {
    # only one parameter to be processed
    displayDebug("Operand = $parms[0] : operator is $function",1,$currentRoutine);
    my $val = $parms[0];
    $val =~ s/\s+$//;
    return $val;
  }   
} # end of evaluateFunction

sub evaluateBinaryOperator {
  # -----------------------------------------------------------
  # Routine to evaluate a binary operator
  #
  # Usage: $x = evaluateBinaryOperator($operator, $op1, $op2);
  # Returns: the calculated value
  # -----------------------------------------------------------

  my $currentRoutine = 'evaluateBinaryOperator';

  my $operator = shift;
  my $op1 = shift;
  my $op2 = shift;
  my $isDuration = 0;  # flag indicating that the variable is a valid duration
  my $duration = 0;    # the duration of a supplied parameter

  if ( $operator eq "+" ) {        # addition 
    displayDebug( "Doing an addition. op1=$op1, op2=$op2", 1, $currentRoutine);
    if ( isValidTimestamp($op1) ) { # timestamp addition (perhaps)
      ($isDuration, $duration) = processDuration($op2,'T'); # check if the duration is valid and convert it to a timestamp format
      if ( $isDuration ) { # add the duration
        return performTimestampAddition($op1, $duration);
      }
      else { # not a valid timestamp addition
        displayError("Looks like timestamp addition but you can only add duratons to timestamps",$currentRoutine);
        return $op1 + $op2;
      }
    }
    elsif ( isValidDate($op1) ) { # date addition (perhaps)
      ($isDuration, $duration) = processDuration($op2,'T'); # check if the duration is valid and convert it to a timestamp format
      if ( $isDuration ) { # add the duration
        return performDateAddition($op1, $duration);
      }
      else { # not a valid date addition
        displayError("Looks like date addition but you can only add duratons to dates",$currentRoutine);
        return $op1 + $op2;
      }
    }
    elsif ( isValidTime($op1) ) { # time addition (perhaps)
      ($isDuration, $duration) = processDuration($op2,'T'); # check if the duration is valid and convert it to a timestamp format
      if ( $isDuration ) { # add the duration
        return performTimeAddition($op1, $duration);
      }
      elsif ( isValidTime($op2) ) { # adding a time to a time
        return performTimeAddition($op1, "0000-00-00 $op2");
      }
      else { # not a valid time addition
        displayError("Looks like time addition but you can only add duratons or times to times",$currentRoutine);
        return $op1 + $op2;
      }
    }
    else { # just treat it as normal addition
      return $op1 + $op2; 
    }
  }
  elsif ( $operator eq "-" ) { 
    displayDebug( "Doing a subtraction. op1=$op1, op2=$op2", 1, $currentRoutine);
    if ( isValidTimestamp($op1) ) { # timestamp addition 
      ($isDuration, $duration) = processDuration($op2,'T'); # check if the duration is valid and convert it to a timestamp format
      if ( $isDuration ) { # subtract the duration
        return performTimestampSubtraction($op1, $duration);
      }
      elsif ( isValidTimestampFormat($op2) ) { # subtract the timestamp
        # the timestamp may be a duration in a timestamp's format or a real timestamp
        # a year less than 1000 indicates that it is a duration in timestamp's clothing
        return performTimestampSubtraction($op1, $duration);
      }
      elsif ( isValidTime($op2) ) { # subtract the timestamp
        return performTimestampSubtraction($op1, "0000-00-00 $duration");
      }
      else { # not a valid timestamp subtraction
        displayError("Looks like timestamp subtraction but you can only subtract durations, times or timestamps from timestamps",$currentRoutine);
        return $op1 - $op2;
      }
    }
    elsif ( isValidDate($op1) ) { # date subtraction
      ($isDuration, $duration) = processDuration($op2,'T'); # check if the duration is valid and convert it to a timestamp format
      if ( $isDuration ) { # subtract the duration
        return performDateSubtraction($op1, $duration, 'T');
      }
      elsif ( isValidDate($op2) ) { # subtract the date (which will return the number of days between the dates)
        return performDateSubtraction($op1, "$op2 00:00:00", 'D');
      }
      else { # not a valid date subtraction
        displayError("Looks like date subtraction but you can only subtract durations from dates",$currentRoutine);
        return $op1 - $op2;
      }
    }
    elsif ( isValidTime($op1) ) { # time subtraction (perhaps)
      ($isDuration, $duration) = processDuration($op2,'T'); # check if the duration is valid and convert it to a timestamp format
      if ( $isDuration ) { # subtract the duration
        return performTimeSubtraction($op1, $duration);
      }
      elsif ( isValidTime($op2) ) { # subtracting a time from a time
        return performTimeSubtraction($op1, "0000-00-00 $op2");
      }
      else { # not a valid time subtraction
        displayError("Looks like time subtraction but you can only subtract durations or times from times",$currentRoutine);
        return $op1 - $op2;
      }
    }
    else { # just treat it as normal subtraction
      return $op1 - $op2; 
    }
  }    # subtraction
  elsif ( $operator eq "*" ) { return $op1 * $op2; }    # multiplication
  elsif ( $operator eq "/" ) { # division
    if ( $op2 == 0 ) { 
      displayError("Divisor must not be zero - OP1=$op1, OP2=$op2",$currentRoutine) ;
      return 0;
    }
    else {
      return $op1 / $op2; 
    }
  }    
  elsif ( ($operator eq ">") || ($operator eq "GT") ) { # greater than
    if ( isNumeric($op1) && isNumeric($op2) ) { # if both operands are numeric 
      if ( $op1 > $op2 ) { return 1; }     # true
      else { return 0; }                   # false
    }
    else { # do a character compare
      if ( $op1 gt $op2 ) { return 1; }     # true
      else { return 0; }                   # false
    }
  }
  elsif ( ($operator eq ">=") || ($operator eq "GE") ) { # greater than or equal
    if ( isNumeric($op1) && isNumeric($op2) ) { # if both operands are numeric 
      if ( $op1 >= $op2 ) { return 1; }     # true
      else { return 0; }                   # false
    }
    else { # do a character compare
      if ( $op1 ge $op2 ) { return 1; }     # true
      else { return 0; }                   # false
    }
  }
  elsif ( ($operator eq "<") || ($operator eq "LT")  ) { # less than
    if ( isNumeric($op1) && isNumeric($op2) ) { # if both operands are numeric 
      if ( $op1 < $op2 ) { return 1; }     # true
      else { return 0; }                   # false
    }
    else { # do a character compare
      if ( $op1 lt $op2 ) { return 1; }     # true
      else { return 0; }                   # false
    }
  }
  elsif ( ($operator eq "<=") || ($operator eq "LE") ) { # less than or equal
    if ( isNumeric($op1) && isNumeric($op2) ) { # if both operands are numeric 
      if ( $op1 <= $op2 ) { return 1; }     # true
      else { return 0; }                   # false
    }
    else { # do a character compare
      if ( $op1 le $op2 ) { return 1; }     # true
      else { return 0; }                   # false
    }
  }
  elsif ( uc($operator) eq "AND" ) { # AND
    if ( isNumeric($op1) && ($op1 == 0) ) { return 0; }     # false - first op is zero
    elsif ( isNumeric($op2) && ($op2 == 0) ) { return 0; }  # false - second op is zero
    elsif ( $op1 eq '' ) { return 0; }                      # false - first op is empty string
    elsif ( $op2 eq '' ) { return 0; }                      # false - second op is empty string
    else { return 1; }                                      # true otherwise
  }
  elsif ( uc($operator) eq "OR" ) { # OR
    if ( isNumeric($op1) && ($op1 != 0) ) { return 1; }        # true - first op is not zero
    elsif ( isNumeric($op2) && ($op2 != 0) ) { return 1; }     # true - second op is not zero
    elsif ( isNumeric($op1) && isNumeric($op2) ) { return 0; } # false - if they are both numeric then they must have both been zero
    elsif ( $op1 ne '' ) { return 1; }                         # true - first op is non-zero and non-blank
    elsif ( $op2 ne '' ) { return 1; }                         # true - second op is non-zero and non-blank
    else { return 0; }                                         # false otherwise (both operands are one of zero or blank)
  }
  elsif ( ($operator eq "<>") || ( uc($operator) eq "NE") ) { # not equal to
    if ( isNumeric($op1) && isNumeric($op2) ) { # if numeric
      if ( $op1 != $op2 ) { return 1; }                        # true - both numeric and they are not equal
      else { return 0; }                                       # false - both numeric and they are equal
    }
    else { # not numeric
      if ( "$op1" ne "$op2" ) { return 1; }                    # true - not numeric and they are not equal
      else { return 0; }                                       # false - not numeric and they are equal
    }
  }
  elsif ( ($operator eq "==") || ($operator eq "=") || ( uc($operator) eq "EQ") ) { # equals
    if ( isNumeric($op1) && isNumeric($op2) ) { # if numeric
      if ( $op1 == $op2 ) { return 1; }                        # true - numeric and they are equal
      else { return 0; }                                       # false - numeric and they are not equal
    }
    else { # not numeric
      if ( "$op1" eq "$op2" ) { return 1; }                    # true - not numeric and they are equal
      else { return 0; }                                       # false - not numeric and they are not equal
    }
  }
  elsif ( $operator eq "||" ) { return $op1 . $op2; }          # concatenation
  elsif ( $operator eq "=~" ) { return ($op1 =~ /$op2/); }     # contains
  elsif ( $operator eq "%" ) {                                 # modulo
    if ( isNumeric($op1) && isNumeric($op2) ) { return $op1 % $op2; }
    else { 
      displayError("Parameters to % must be numeric - OP1=$op1, OP2=$op2",$currentRoutine) ;
      return(""); }
  }

} # end of evaluateBinaryOperator

sub evaluateUnaryOperator {
  # -----------------------------------------------------------
  # Routine to evaluate a unary operator
  #
  # Usage: $x = evaluateUnaryOperator($operator, $op1);
  # Returns: the calculated value
  # -----------------------------------------------------------

  my $currentRoutine = 'evaluateUnaryOperator';

  my $operator = shift;
  my $op1 = shift;

  if ( $operator eq "!" ) {                         # Not
    if ( isNumeric($op1) ) {
      if ( $op1 == 0 ) { return 1; }                    # if it is a numeric and it is zero then return 1
      else { return 0; }                                # non-zero value so return 0
    }
    else { # it is a string
      if ( trim($op1) eq '' ) { return 1; }             # a null or space filled string is consider empty
      else { return 0; }                                # non empty string so return 0
    }
  }
  elsif ( $operator eq "u-" ) {                     # Unary minus
    if ( isNumeric($op1) ) { return -1 * $op1 ; }       # if it is a numeric then return the negative value of the operand
    else { return "- $op1"; }                               # it is a string - just return the string with a minus at the front
  }
  elsif ( $operator eq "u+" ) {                     # Unary plus
    if ( isNumeric($op1) ) { return $op1 ; }            # if it is a numeric then return just return the $op1
    else { return "+ $op1"; }                           # it is a string - just return the string with a plus at the front
  }

} # end of evaluateUnaryOperator

sub evaluateInfix {
  # -----------------------------------------------------------
  # Routine to evaluate a supplied infix calculation
  #
  # Usage: evaluateInfix('1+1'[,'literal']);
  # Returns: the result of the calculation
  # -----------------------------------------------------------

  my $currentRoutine = 'evaluateInfix';

  $infixString = shift;
  $sourceLiteral = shift;
  if ( ! defined($sourceLiteral) ) { $sourceLiteral = ''; }
  $infixString = trim($infixString);

  $currentTokenPosition = 0;

  my $op1 = '';
  my $op2 = '';
  my $op3 = '';
  my $val = '';
  my $retToken = '';
  my $calc = 0;
  my $lastToken ;

  displayDebug("Supplied infix string is: $infixString",1,$currentRoutine);

  my $token = getCalculateToken($infixString);
  if ( $token eq $infixString ) { # dont bother just return the string - nothing to do
    return $token;
  }

  # This first conversion converts the infix expression into a reverse polish expression

  displayDebug("===== Converting Infix to PostFix =====",1,$currentRoutine);

  while ($token ne "") {
    displayDebug("Token = $token",2,$currentRoutine);
    if ( $currentTokenIsString ) { # and thus it is an operand
      push (@output, $token) ;
      displayDebug("DUMPSTACK",2,$currentRoutine);
      displayDebug("Pushing operand $token output size = $#output",1,$currentRoutine);
    }
    elsif ( isNumeric($token) ) {
      push (@output, $token) ;
      if ( $calcDebugLevel > 1  ) { for ( my $i = 0; $i <= $#stack; $i++ ) { displayDebug("   Stack $i : $stack[$i] [tot $#stack]",2,$currentRoutine); } }
      displayDebug("DUMPOUTPUT",2,$currentRoutine);
      displayDebug("Pushing numeric $token output size = $#output",1,$currentRoutine);
    }
    elsif ( isFunction($token) ) {
      push (@stack, $token) ;
      if ( $calcDebugLevel > 1  ) { for ( my $i = 0; $i <= $#stack; $i++ ) { displayDebug("DUMPSTACK",2,$currentRoutine); } }
      push (@output, ')') ;
      if ( $calcDebugLevel > 1  ) { for ( my $i = 0; $i <= $#output; $i++ ) { displayDebug("DUMPOUTPUT",2,$currentRoutine); } }
      displayDebug("Pushing function $token onto stack, Stack Size $#stack",1,$currentRoutine);
    }
    elsif ( $token eq "," ) { # a comma is a function parm delimiter - if a comma is required it should be in quotes
     
      # clear out any other operators for this parameter (an opening bracket signifies the beginning for this parm)
      while ( ($#stack > -1 ) && ( $stack[$#stack] ne "\(" ) ) {      # not at tthe end of the operators for this parm
        displayDebug("ret operator: $stack[$#stack]",1,$currentRoutine);
        push (@output, pop(@stack)) ;
      }
      
    }
    elsif ( isOperator($token) ) {
      # check to see if it is a unary operator .....
      # unary operators are -, + and !
      if ( isPossibleUnaryOperator($token) ) { # it is so now check that it is in the right place to be a unary operator
        if ( ($lastToken eq '' ) ||       # first token in the equation
             ($lastToken eq '(' ) ||      # previous token is an opening bracket
             ($lastToken eq ',' ) ||      # previous token is a comma
             (isOperator($lastToken)) ) { # previous token is an operator
          # convert the token if necessary (only really necessary for - and +)
          if ( $token eq '-' ) { $token = 'u-'; }
          elsif ( $token eq '+' ) { $token = 'u+'; }
        }
      }
      displayDebug("Operator on top of stack is: >$stack[$#stack]<, top of stack is $#stack, \$token is $token",1,$currentRoutine);
      while ( ($#stack > -1) && isOperator($stack[$#stack]) && ( $stack[$#stack] ne "\(" ) && ( $opPrecedence{$stack[$#stack]} >= $opPrecedence{$token} ) ) { # it's an operator on the top of stack and precendence of token is less or equal
                                                                                                                               # than precedence of the operator on the top of the stack
        if( $opPrecedence{$stack[$#stack]} > $opPrecedence{$token} ) { # pop all operators on the stack with a lower precedence
          push(@output, pop(@stack)); # pop it off of the stack and put it to output
        }
        elsif ( (! isUnaryOperator($token)) && ($opPrecedence{$token} == $opPrecedence{$stack[$#stack]})  ) { # if it has an equal precedence and it is not a unary operator then pop it
          push(@output, pop(@stack)); # pop it off of the stack and put it to output
        }
        else {
          last; # we're done here
        }
      }
      displayDebug("Pushing operator $token stack size = $#stack",1,$currentRoutine);
      push (@stack, $token) ; # place the current token onto the stack
      displayDebug("DUMPSTACK",2,$currentRoutine);
    }
    elsif ( $token eq "\(" ) {
      push (@stack, $token) ;
      displayDebug("Pushing ( on to stack",1,$currentRoutine);
    }
    elsif ( $token eq "\)" ) {
      while ( (defined($stack[$#stack])) && ($stack[$#stack] ne "\(" ) ) {
        displayDebug("DUMPSTACK",2,$currentRoutine);
        push(@output, pop(@stack)); # pop it off of the stack and put it to output
        displayDebug("added to output stack : $output[$#output]",1,$currentRoutine);
      }
      displayDebug("DUMPOUTPUT",2,$currentRoutine);
      if ( defined($stack[$#stack]) ) {  # top of stack is a '('
        pop(@stack);  # pop and discard the (
        if ( ($#stack > -1) && isFunction($stack[$#stack]) ) { # if it is a function on top of the stack, pop the function call off as well
          push(@output, pop(@stack)); # pop it off of the stack and put it to output
          displayDebug("added to output stack : $output[$#output]",1,$currentRoutine);
        }
      }
      else { # there's a problem
        displayError("Calculator Error: Parsing error - mismatched parentheses",$currentRoutine) ;
      }
    }
    else { # token was none of the above - ie it was probably just a string - so treat it as an operand
      push (@output, $token) ;
      displayDebug("DUMPSTACK",2,$currentRoutine);
      displayDebug("Pushing operand $token output size = $#output",1,$currentRoutine);
    }
    # get the next token
    $lastToken = $token;    # save the token in case it was needed
    $token = getCalculateToken($infixString);
  }
  displayDebug("Started stack clear down",1,$currentRoutine);
  $retToken = pop(@stack);
  while ( defined($retToken) ) { # flush out the rest of the stack
    if ( index(' ( ) ', $retToken) > -1 ) { # if the returned token is a bracket then something has gone wrong .....
      displayError("Calculator Error: Parsing error mismatched parentheses",$currentRoutine) ;
      last;
    }
    push(@output, $retToken);
    displayDebug("DUMPSTACK",1,$currentRoutine);
    $retToken = pop(@stack);
  }
  displayDebug("Finished stack clear down",1,$currentRoutine);
  displayDebug("DUMPOUTPUT",2,$currentRoutine);

  # Now evaluate the converted infix string (which is now a reverse polish expression)!

  displayDebug("===== Evaluating PostFix =====",1,$currentRoutine);

  displayDebug("Input: $infixString",1,$currentRoutine);
  my @operandStack = ();
  displayDebug("DUMPOUTPUT",1,$currentRoutine);
  my $rPolish = shift(@output);
  while ( (@output > 0) ) {
    if ( substr($rPolish . "  ",0,2) eq ':"' ) { # token is a string - so operand
      $rPolish = substr($rPolish,2);    # strip off the string indicator
      displayDebug("Token >$rPolish< is an operand",1,$currentRoutine);
      push ( @operandStack, $rPolish) ;
      displayDebug("Pushing >$rPolish< onto the operandStack",2,$currentRoutine);
    }
    elsif ( isOperator($rPolish) || isUnaryOperator($rPolish) ) { # process the operator ....
      displayDebug("Token >$rPolish< is an Operator",1,$currentRoutine);
      if ( isUnaryOperator($rPolish) ) { # it's a unary operator so only needs one operand
        $op2 =  '';
        $op1 =  pop(@operandStack);
        displayDebug("op1 = $op1 : operator is >$rPolish<",1,$currentRoutine);
        $val = evaluateUnaryOperator($rPolish, $op1);
        displayDebug("val = $val",1,$currentRoutine);
        push ( @operandStack, $val);
      }
      else { # assuming it needs 2 parameters
        $op2 =  pop(@operandStack);
        $op1 =  pop(@operandStack);
        displayDebug("op1 = $op1, op2 = $op2 : operator is >$rPolish<",1,$currentRoutine);
        $val = evaluateBinaryOperator($rPolish, $op1, $op2);
        displayDebug("val = $val",1,$currentRoutine);
        push ( @operandStack, $val);
      }
    }
    elsif ( isFunction($rPolish) ) { # process the function ....
      displayDebug("Token >$rPolish< is a function",1,$currentRoutine);
      # load up the function parameters until you get to a closing bracket .....
      my @funcParms = ();
      my $tmpParm = pop(@operandStack);
      if ( $tmpParm ne ')' ) { push ( @funcParms, $tmpParm) ; }
      while ( ($#output > -1) && ($tmpParm ne ')') ) {
        my $tmpParm = pop(@operandStack);
        if ( $tmpParm ne ')' ) { push ( @funcParms, $tmpParm) ; }
      }
      
      $val = evaluateFunction($rPolish, \@funcParms);
      push ( @operandStack, $val) ; # put the value back on the operand stack
    }
    else { # must be an operand - save it for later use
      displayDebug("Token >$rPolish< is an operand",1,$currentRoutine);
      push ( @operandStack, $rPolish) ;
      displayDebug("Pushing >$rPolish< onto the operandStack",2,$currentRoutine);
    }
    # get the next element off of the Reverse Polish stack
    $rPolish = shift(@output);
  }

  # now just process the entries still on the stack

  displayDebug("DUMPOPSTACK",2,$currentRoutine);

  if ( isOperator($rPolish) ) { # process the operator ....
    displayDebug("Token >$rPolish< is an Operator",1,$currentRoutine);
    if ( isUnaryOperator($rPolish) ) { # it's a unary operator so only needs one operand
      $op2 =  '';
      $op1 =  pop(@operandStack);
      displayDebug("op1 = $op1 : operator is >$rPolish<",1,$currentRoutine);
      $val = evaluateUnaryOperator($rPolish, $op1);
      displayDebug("val = $val",1,$currentRoutine);
      push ( @operandStack, $val);
    }
    else { # assuming it needs 2 parameters
      $op2 =  pop(@operandStack);
      $op1 =  pop(@operandStack);
      displayDebug("op1 = $op1, op2 = $op2 : operator is >$rPolish<",1,$currentRoutine);
      $val = evaluateBinaryOperator($rPolish, $op1, $op2);
      displayDebug("val = $val",1,$currentRoutine);
      push ( @operandStack, $val);
    }
  }
  elsif ( isFunction($rPolish) ) { # process the function ....
     displayDebug("Token >$rPolish< is a function",1,$currentRoutine);
      # load up the function parameters until you get to a closing bracket .....
      my @funcParms = ();
      my $tmpParm = pop(@operandStack);
      if ( $tmpParm ne ')' ) { push ( @funcParms, $tmpParm) ; }
      while ( ( $#operandStack > -1 ) && ( $tmpParm ne ')' ) ) {
        my $tmpParm = pop(@operandStack);
        if ( $tmpParm ne ')' ) { push ( @funcParms, $tmpParm) ; }
      }
      
      $val = evaluateFunction($rPolish, \@funcParms);
      push ( @operandStack, $val) ; # put the value back on the operand stack
  }
  else {
    # neither a function or an operator ..... if it is the only thing on the stack then there was no processing to do .....
    displayDebug( ">>>>>> $#operandStack",1,$currentRoutine);
    if ( $#operandStack == -1 ) {
      if ( substr($rPolish,0,2) eq ':"' ) {  # there is a string indicator
        $rPolish = substr($rPolish,2);       # get rid of the string indiactor
      }
      push (@operandStack, $rPolish);  # push the result back onto the stack
    }
    else {
      displayError("Calculator Error - Something wrong - Found $rPolish on the stack - it should be an operator!",$currentRoutine) ;
    }
  }

  $val = pop(@operandStack);
  displayDebug( ">>>>>> returned $val",1,$currentRoutine);
  return $val;
} # end of evaluateInfix
1;
