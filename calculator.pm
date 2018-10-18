#!/usr/bin/perl
# --------------------------------------------------------------------
# calculator.pm
#
# $Id: calculator.pm,v 1.14 2018/05/29 04:22:42 db2admin Exp db2admin $
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
# Revision 1.4  2015/09/28 01:17:56  db2admin
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
our $testRoutines = 0;   # variable containing which tests to run in the testRoutine sub
# export parameters ....
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(evaluateInfix calcVersion $calcDebugLevel $calcFunctions $calcOperators %opPrecedence calcTestRoutine $calcTestRoutines $calcDebugModules $calcOperatorsAlpha) ;

our $calcDebugModules = 'All';
our $calcDebugLevel = 0;
our $calcFunctions = " ABS SUBSTR LEFT RIGHT TRIM LTRIM RTRIM ";                # list of strings to be treated as function (can be modified)
our $calcOperatorsAlpha = ' OR AND GT GE LT LE NE EQ ';                         # list of strings to be treated as alpha operators (can be modified)
our $possibleUnaryOperators = ' ! - + ';                                        # possible unary operators (i.e only one operand).
our $unaryOperators = ' ! U- U+ ';                                              # unary operators (i.e only one operand). Note u- is - and u+ is + (adjusted)
our $calcOperators = ' + - * / % || > >= < <= <> = == =~ ! ' . $calcOperatorsAlpha;  # list of strings to be treated as token terminators (can be modified)
our %opPrecedence;

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

sub calcTestRoutine {
  # -----------------------------------------------------------
  # routine to test the subroutines/functions in this package
  # -----------------------------------------------------------

  my $currentSubroutine = 'calcTestRoutine';
  my $testString = "";

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

 
} # end of calcTestRoutine

sub getDate {
  # -----------------------------------------------------------
  #  Routine to return a formatted Date in YYYY.MM.DD format
  #
  # Usage: getDate()
  # Returns: YYYY.MM.DD
  # -----------------------------------------------------------

  my $currentSubroutine = 'getDate';
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  my $year = 1900 + $yearOffset;
  $month = $month + 1;
  $month = substr("0" . $month, length($month)-1,2);
  my $day = substr("0" . $dayOfMonth, length($dayOfMonth)-1,2);
  return "$year.$month.$day";
} # end of getDate

sub getTime {
  # -----------------------------------------------------------
  # Routine to return a formatted time in HH:MM:SS format
  #
  # Usage: getTime()
  # Returns: HH:MM:SS
  # -----------------------------------------------------------

  my $currentSubroutine = 'getTime';
  #my $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings, $year;
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  $hour = substr("0" . $hour, length($hour)-1,2);
  $minute = substr("0" . $minute, length($minute)-1,2);
  $second = substr("0" . $second, length($second)-1,2);
  return "$hour:$minute:$second"
} # end of getTime

sub calcVersion {
  # --------------------------------------------------------------------"
  # Routine to return the version number of the calculator package
  #
  # Usage: calcVersion();
  # Returns: a string like .... "$name ($Version)  Last Changed on $Changed (UTC)"
  # --------------------------------------------------------------------"

  my $ID = '$Id: calculator.pm,v 1.14 2018/05/29 04:22:42 db2admin Exp db2admin $';

  my @V = split(/ /,$ID);
  my $nameStr=$V[1];
  my ($name,$x) = split(",",$nameStr);
  my $Version=$V[2];
  my $Changed="$V[3] $V[4]";

  return "$name ($Version)  Last Changed on $Changed (UTC)";

} # end of calcVersion

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
    my $tDate = getDate();
    my $tTime = getTime();

    if ( $lit eq "") { # Nothing to display so just display the date and time
      print "$sub - $tDate $tTime\n";
    }
    elsif ( $lit eq "DUMPSTACK" ) {
      print "Dumping STACK ($#stack entries) \n";
      for ( my $i = 0; $i <= $#stack; $i++ ) { print "$sub - $tDate $tTime : Stack $i : $stack[$i] [tot $#stack]\n"; }
    }
    elsif ( $lit eq "DUMPOUTPUT" ) {
      print "Dumping OUTPUT STACK ( $#output entries) \n";
      for ( my $i = 0; $i <= $#output; $i++ ) { print "$sub - $tDate $tTime : Output Stack $i : $output[$i] [tot $#output]\n"; }
    }
    elsif ( $lit eq "DUMPOPSTACK" ) {
      print "Dumping OPERAND STACK ( $#operandStack entries) \n";
      for ( my $i = 0; $i <= $#operandStack; $i++ ) { print "$sub - $tDate $tTime : Operand Stack $i : $operandStack[$i] [tot $#operandStack]\n"; }
    }
    else {
      print "$sub - $tDate $tTime : $lit\n";
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

  my $currentSubroutine = 'getCalculateToken';
  my $tLine = shift;
  my $tTok = "";

  my $currChar = '';

  displayDebug("Line: $tLine Start Pos: $currentTokenPosition",2,$currentSubroutine);

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
      displayDebug("\$myChar: $myChar",1,$currentSubroutine);
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
    displayDebug("Token is not a string. Terminating character has been set as whitespace(ish) >>" . substr($tLine,$currentTokenPosition) ,2,$currentSubroutine);
    while ( ($currentTokenPosition <= length($tLine) ) && (substr($tLine,$currentTokenPosition,1) ne ' ') ) { # while still chars left and char is not space
      displayDebug(">>>>>>\$currentTokenPosition = $currentTokenPosition, char = " . substr($tLine,$currentTokenPosition,1) . ", tLine = $tLine, tTok = $tTok",2,$currentSubroutine);
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
        displayDebug("next byte = " . substr($tLine,$currentTokenPosition,1) . ", next 2 bytes = " . substr($tLine,$currentTokenPosition,2) . ",tTok = $tTok",2,$currentSubroutine);
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
              displayDebug("Token terminated as following token is a non alpha operator",2,$currentSubroutine);
              last;
            }
          }
        }
        # Stop if the next char to be processed would be a one of ')', ',' or '('
        if ( index(' ) , ( ', substr($tLine,$currentTokenPosition,1)) > -1 ) {
          displayDebug("Next character is one of \), \( or \,",2,$currentSubroutine);
          last;
        }
        # Stop if the current token is a comma
        if ( $tTok eq ',' ) {
          displayDebug("Token is a comma",1,$currentSubroutine);
          last;
        }
        # stop if the token is an opening parethesis
        if ( $tTok eq "\(" ) {
          displayDebug("Token is \(",2,$currentSubroutine);
          last;
        }
      }
    }
  }

  displayDebug("Token identified was: $tTok",2,$currentSubroutine);
  return $tTok;

} # end of getCalculateToken

sub isNumeric {
  # -----------------------------------------------------------
  # Routine to check if a supplied parameter is a number or not
  #
  # Usage: isnumeric('123');
  # Returns: 0 - not numeric , 1 numeric
  # -----------------------------------------------------------

  my $currentSubroutine = 'isNumeric';

  my $var = shift;
  displayDebug("var is: $var",1,$currentSubroutine);

  if ($var =~ /^\d+\z/)         { return 1; } # only contains digits between the start and the end of the bufer
  displayDebug("Not Only Digits",5,$currentSubroutine);
  if ($var =~ /^-?\d+\z/)       { return 1; } # may contain a leading minus sign
  displayDebug("Doesn't have a leading minus followed by digits",5,$currentSubroutine);
  if ($var =~ /^[+-]?\d+\z/)    { return 1; } # may have a leading minus or plus
  displayDebug("No leading minus or plus followed by digits",5,$currentSubroutine);
  if ($var =~ /^-?\d+\.?\d*\z/) { return 1; } # may have a leading minus , digits , decimal point and then digits
  displayDebug("Not a negative decimal number",5,$currentSubroutine);
  if ($var =~ /^[+-]?(?:\d*\.\d)?\d*(?:[Ee][+-]?\d+)\z/) { return 1; }
  displayDebug("Not scientific notation",5,$currentSubroutine);

  return 0;

} # end of isNumeric

sub isFunction {
  # -----------------------------------------------------------
  # Routine to check if a supplied parameter is a function
  #
  # Usage: isFunction('LEFT');
  # Returns: 0 - not function , 1 function
  # -----------------------------------------------------------

  my $currentSubroutine = 'isFunction';
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

  my $currentSubroutine = 'isOperator';
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

  my $currentSubroutine = 'isPossibleUnaryOperator';
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

  my $currentSubroutine = 'isUnaryOperator';
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

  my $currentSubroutine = 'isAlphaOperator';
  my $tok = shift;

  if ( index($calcOperatorsAlpha, uc($tok)) > -1 ) { return 1; }

  return 0;
} # end of isAlphaOperator

sub trim {
  # -----------------------------------------------------------
  # Routine to strip off leading and training blanks
  #
  # Usage: trim("  test  ");
  # Returns: the supplied parm trimmed of spaces
  # -----------------------------------------------------------

  my $currentSubroutine = 'trim';

  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
} # end of trim

sub evaluateFunction {
  # -----------------------------------------------------------
  # Routine to evaluate a function
  #
  # Usage: $x = evaluateFunction($functionName, \$parmArray);
  # Returns: the calculated value
  # -----------------------------------------------------------

  my $currentSubroutine = 'evaluateFunction';

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
    displayDebug("Operand = $parms[0] : operator is $function",1,$currentSubroutine);
    return abs($parms[0]);
  }
  elsif ( uc($function) eq "SUBSTR" ) {
    if ( $#parms == 0 ) { # only 1 parameter so just return it
      displayDebug("$#parms parameter passed to $function (string just returned",1,$currentSubroutine);
      return $parms[0];
    }
    elsif ( $#parms == 1 ) { # 2 parms so dont pass length
      displayDebug("$#parms parameters passed to $function (processed as 2)",1,$currentSubroutine);
      return substr($parms[1],$parms[0]); 
    }
    else { # only use the first 3 parameters
      displayDebug("$#parms parameters passed to $function (processed as 3)",1,$currentSubroutine);
      return substr($parms[2],$parms[1],$parms[0]); 
    }
  }
  elsif ( uc($function) eq "LEFT" ) {
    if ( $#parms == 0 ) { # only 1 parameter so just return it
      displayDebug("$#parms parameter passed to $function (string just returned",1,$currentSubroutine);
      return $parms[0];
    }
    else { # only use the first 2 parameters
      displayDebug("$#parms parameters passed to $function (processed as 2)",1,$currentSubroutine);
      return left($parms[1],$parms[0]); 
    }
  }
  elsif ( uc($function) eq "RIGHT" ) {
    if ( $#parms == 0 ) { # only 1 parameter so just return it
      displayDebug("$#parms parameter passed to $function (string just returned",1,$currentSubroutine);
      return $parms[0];
    }
    else { # only use the first 2 parameters
      displayDebug("$#parms parameters passed to $function (processed as 2)",1,$currentSubroutine);
      return right($parms[1],$parms[0]); 
    }
  }
  elsif ( uc($function) eq "TRIM" ) {
    # only one parameter to be processed
    displayDebug("Operand = $parms[0] : operator is $function",1,$currentSubroutine);
    my $val = $parms[0];
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    return $val;
  }
  elsif ( uc($function) eq "LTRIM" ) {
    # only one parameter to be processed
    displayDebug("Operand = $parms[0] : operator is $function",1,$currentSubroutine);
    my $val = $parms[0];
    $val =~ s/^\s+//;
    return $val;
  }
  elsif ( uc($function) eq "RTRIM" ) {
    # only one parameter to be processed
    displayDebug("Operand = $parms[0] : operator is $function",1,$currentSubroutine);
    my $val = $parms[0];
    $val =~ s/\s+$//;
    return $val;
  }   
}

sub evaluateBinaryOperator {
  # -----------------------------------------------------------
  # Routine to evaluate a binary operator
  #
  # Usage: $x = evaluateBinaryOperator($operator, $op1, $op2);
  # Returns: the calculated value
  # -----------------------------------------------------------

  my $currentSubroutine = 'evaluateBinaryOperator';

  my $operator = shift;
  my $op1 = shift;
  my $op2 = shift;

  if ( $operator eq "+" ) { return $op1 + $op2; }       # addition
  elsif ( $operator eq "-" ) { return $op1 - $op2; }    # subtraction
  elsif ( $operator eq "*" ) { return $op1 * $op2; }    # multiplication
  elsif ( $operator eq "/" ) { # division
    if ( $op2 == 0 ) { 
      return 0;
      print STDERR "ERROR: Divisor must not be zero - OP1=$op1, OP2=$op2";
    }
    else {
      return $op1 / $op2; 
    }
  }    
  elsif ( ($operator eq ">") || ($operator eq "GT") ) { # greater than
    if ( $op1 > $op2 ) { return 1; }     # true
    else { return 0; }                   # false
  }
  elsif ( ($operator eq ">=") || ($operator eq "GE") ) { # greater than or equal
    if ( $op1 >= $op2 ) { return 1; } # true
    else { return 0; }                # false
  }
  elsif ( ($operator eq "<") || ($operator eq "LT")  ) { # less than
    if ( $op1 < $op2 ) { return 1; }  # true
    else { return 0; }                # false
  }
  elsif ( ($operator eq "<=") || ($operator eq "LE") ) { # less than or equal
    if ( $op1 <= $op2 ) { return 1; } # true
    else { return 0; }                # false
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
    else { return("ERROR: Parameters to % must be numeric - OP1=$op1, OP2=$op2"); }
  }

} # end of evaluateBinaryOperator

sub evaluateUnaryOperator {
  # -----------------------------------------------------------
  # Routine to evaluate a unary operator
  #
  # Usage: $x = evaluateUnaryOperator($operator, $op1);
  # Returns: the calculated value
  # -----------------------------------------------------------

  my $currentSubroutine = 'evaluateUnaryOperator';

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
  # Usage: evaluateInfix('1+1');
  # Returns: the result of the calculation
  # -----------------------------------------------------------

  my $currentSubroutine = 'evaluateInfix';

  my $infixString = shift;
  $infixString = trim($infixString);

  $currentTokenPosition = 0;

  my $op1 = '';
  my $op2 = '';
  my $op3 = '';
  my $val = '';
  my $retToken = '';
  my $calc = 0;
  my $lastToken ;

  displayDebug("Supplied infix string is: $infixString",1,$currentSubroutine);

  my $token = getCalculateToken($infixString);
  if ( $token eq $infixString ) { # dont bother just return the string - nothing to do
    return $token;
  }

  # This first conversion converts the infix expression into a reverse polish expression

  displayDebug("===== Converting Infix to PostFix =====",1,$currentSubroutine);

  while ($token ne "") {
    displayDebug("Token = $token",2,$currentSubroutine);
    if ( $currentTokenIsString ) { # and thus it is an operand
      push (@output, $token) ;
      displayDebug("DUMPSTACK",2,$currentSubroutine);
      displayDebug("Pushing operand $token output size = $#output",1,$currentSubroutine);
    }
    elsif ( isNumeric($token) ) {
      push (@output, $token) ;
      if ( $calcDebugLevel > 1  ) { for ( my $i = 0; $i <= $#stack; $i++ ) { displayDebug("   Stack $i : $stack[$i] [tot $#stack]",2,$currentSubroutine); } }
      displayDebug("DUMPOUTPUT",2,$currentSubroutine);
      displayDebug("Pushing numeric $token output size = $#output",1,$currentSubroutine);
    }
    elsif ( isFunction($token) ) {
      push (@stack, $token) ;
      if ( $calcDebugLevel > 1  ) { for ( my $i = 0; $i <= $#stack; $i++ ) { displayDebug("DUMPSTACK",2,$currentSubroutine); } }
      push (@output, ')') ;
      if ( $calcDebugLevel > 1  ) { for ( my $i = 0; $i <= $#output; $i++ ) { displayDebug("DUMPOUTPUT",2,$currentSubroutine); } }
      displayDebug("Pushing function $token onto stack, Stack Size $#stack",1,$currentSubroutine);
    }
    elsif ( $token eq "," ) { # a comma is a function parm delimiter - if a comma is required it should be in quotes
     
      # clear out any other operators for this parameter (an opening bracket signifies the beginning for this parm)
      while ( ($#stack > -1 ) && ( $stack[$#stack] ne "\(" ) ) {      # not at tthe end of the operators for this parm
        displayDebug("ret operator: $stack[$#stack]",1,$currentSubroutine);
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
      displayDebug("Operator on top of stack is: >$stack[$#stack]<, top of stack is $#stack, \$token is $token",1,$currentSubroutine);
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
      displayDebug("Pushing operator $token stack size = $#stack",1,$currentSubroutine);
      push (@stack, $token) ; # place the current token onto the stack
      displayDebug("DUMPSTACK",2,$currentSubroutine);
    }
    elsif ( $token eq "\(" ) {
      push (@stack, $token) ;
      displayDebug("Pushing ( on to stack",1,$currentSubroutine);
    }
    elsif ( $token eq "\)" ) {
      while ( (defined($stack[$#stack])) && ($stack[$#stack] ne "\(" ) ) {
        displayDebug("DUMPSTACK",2,$currentSubroutine);
        push(@output, pop(@stack)); # pop it off of the stack and put it to output
        displayDebug("added to output stack : $output[$#output]",1,$currentSubroutine);
      }
      displayDebug("DUMPOUTPUT",2,$currentSubroutine);
      if ( defined($stack[$#stack]) ) {  # top of stack is a '('
        pop(@stack);  # pop and discard the (
        if ( ($#stack > -1) && isFunction($stack[$#stack]) ) { # if it is a function on top of the stack, pop the function call off as well
          push(@output, pop(@stack)); # pop it off of the stack and put it to output
          displayDebug("added to output stack : $output[$#output]",1,$currentSubroutine);
        }
      }
      else { # there's a problem
        print STDERR "Calculator Error: Parsing error - mismatched parentheses\n";
      }
    }
    else { # token was none of the above - ie it was probably just a string - so treat it as an operand
      push (@output, $token) ;
      displayDebug("DUMPSTACK",2,$currentSubroutine);
      displayDebug("Pushing operand $token output size = $#output",1,$currentSubroutine);
    }
    # get the next token
    $lastToken = $token;    # save the token in case it was needed
    $token = getCalculateToken($infixString);
  }
  displayDebug("Started stack clear down",1,$currentSubroutine);
  $retToken = pop(@stack);
  while ( defined($retToken) ) { # flush out the rest of the stack
    if ( index(' ( ) ', $retToken) > -1 ) { # if the returned token is a bracket then something has gone wrong .....
      print STDERR "Calculator Error: Parsing error mismatched parentheses\n";
      last;
    }
    push(@output, $retToken);
    displayDebug("DUMPSTACK",1,$currentSubroutine);
    $retToken = pop(@stack);
  }
  displayDebug("Finished stack clear down",1,$currentSubroutine);
  displayDebug("DUMPOUTPUT",2,$currentSubroutine);

  # Now evaluate the converted infix string (which is now a reverse polish expression)!

  displayDebug("===== Evaluating PostFix =====",1,$currentSubroutine);

  displayDebug("Input: $infixString",1,$currentSubroutine);
  my @operandStack = ();
  displayDebug("DUMPOUTPUT",1,$currentSubroutine);
  my $rPolish = shift(@output);
  while ( (@output > 0) ) {
    if ( substr($rPolish . "  ",0,2) eq ':"' ) { # token is a string - so operand
      $rPolish = substr($rPolish,2);    # strip off the string indicator
      displayDebug("Token >$rPolish< is an operand",1,$currentSubroutine);
      push ( @operandStack, $rPolish) ;
      displayDebug("Pushing >$rPolish< onto the operandStack",2,$currentSubroutine);
    }
    elsif ( isOperator($rPolish) || isUnaryOperator($rPolish) ) { # process the operator ....
      displayDebug("Token >$rPolish< is an Operator",1,$currentSubroutine);
      if ( isUnaryOperator($rPolish) ) { # it's a unary operator so only needs one operand
        $op2 =  '';
        $op1 =  pop(@operandStack);
        displayDebug("op1 = $op1 : operator is >$rPolish<",1,$currentSubroutine);
        $val = evaluateUnaryOperator($rPolish, $op1);
        displayDebug("val = $val",1,$currentSubroutine);
        push ( @operandStack, $val);
      }
      else { # assuming it needs 2 parameters
        $op2 =  pop(@operandStack);
        $op1 =  pop(@operandStack);
        displayDebug("op1 = $op1, op2 = $op2 : operator is >$rPolish<",1,$currentSubroutine);
        $val = evaluateBinaryOperator($rPolish, $op1, $op2);
        displayDebug("val = $val",1,$currentSubroutine);
        push ( @operandStack, $val);
      }
    }
    elsif ( isFunction($rPolish) ) { # process the function ....
      displayDebug("Token >$rPolish< is a function",1,$currentSubroutine);
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
      displayDebug("Token >$rPolish< is an operand",1,$currentSubroutine);
      push ( @operandStack, $rPolish) ;
      displayDebug("Pushing >$rPolish< onto the operandStack",2,$currentSubroutine);
    }
    # get the next element off of the Reverse Polish stack
    $rPolish = shift(@output);
  }

  # now just process the entries still on the stack

  displayDebug("DUMPOPSTACK",2,$currentSubroutine);

  if ( isOperator($rPolish) ) { # process the operator ....
    displayDebug("Token >$rPolish< is an Operator",1,$currentSubroutine);
    if ( isUnaryOperator($rPolish) ) { # it's a unary operator so only needs one operand
      $op2 =  '';
      $op1 =  pop(@operandStack);
      displayDebug("op1 = $op1 : operator is >$rPolish<",1,$currentSubroutine);
      $val = evaluateUnaryOperator($rPolish, $op1);
      displayDebug("val = $val",1,$currentSubroutine);
      push ( @operandStack, $val);
    }
    else { # assuming it needs 2 parameters
      $op2 =  pop(@operandStack);
      $op1 =  pop(@operandStack);
      displayDebug("op1 = $op1, op2 = $op2 : operator is >$rPolish<",1,$currentSubroutine);
      $val = evaluateBinaryOperator($rPolish, $op1, $op2);
      displayDebug("val = $val",1,$currentSubroutine);
      push ( @operandStack, $val);
    }
  }
  elsif ( isFunction($rPolish) ) { # process the function ....
     displayDebug("Token >$rPolish< is a function",1,$currentSubroutine);
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
    displayDebug( ">>>>>> $#operandStack",1,$currentSubroutine);
    if ( $#operandStack == -1 ) {
      if ( substr($rPolish,0,2) eq ':"' ) {  # there is a string indicator
        $rPolish = substr($rPolish,2);       # get rid of the string indiactor
      }
      push (@operandStack, $rPolish);  # push the result back onto the stack
    }
    else {
      print STDERR "Calculator Error - Something wrong - Found $rPolish on the stack - it should be an operator!\n";
    }
  }

  $val = pop(@operandStack);
  displayDebug( ">>>>>> returned $val",1,$currentSubroutine);
  return $val;
} # end of evaluateInfix
1;


