#!/usr/bin/perl
# --------------------------------------------------------------------
# calculator.pm
#
# $Id: calculator.pm,v 1.6 2016/06/24 01:53:54 db2admin Exp db2admin $
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
our @EXPORT_OK = qw(evaluateInfix calcVersion $calcDebugLevel $calcFunctions $calcOperators %opPrecedence calctestRoutine $calcTestRoutines $calcDebugModules) ;

our $calcDebugModules = 'All';
our $calcDebugLevel = 0;
our $calcFunctions = " ABS SUBSTR LEFT RIGHT TRIM LTRIM RTRIM "; # list of strings to be treated as function (can be modified)
our $calcOperators = ' + - * / % || > >= < <= <> = == OR AND GT GE LT LE NE EQ '; # list of strings to be treated as operators (can be modified)
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
$opPrecedence{'EQ'} = 1;
$opPrecedence{'='} = 1;
$opPrecedence{'!'} = 2;
$opPrecedence{'*'} = 3;
$opPrecedence{'/'} = 3;
$opPrecedence{'%'} = 3;
$opPrecedence{'+'} = 4;
$opPrecedence{'-'} = 4;

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

  if ( oct($testRoutines) & oct('0b0000000000000001') ) { # remove unnecessary whitespace test
  }

  if ( oct($testRoutines) & oct('0b0000000000000010') ) { # format SQL test

  }

  if ( oct($testRoutines) & oct('0b0000000000000100') ) { # loadSkeleton test
  }

  if ( oct($testRoutines) & oct('0b0000000000001000') ) { # getToken test
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

  my $ID = '$Id: calculator.pm,v 1.6 2016/06/24 01:53:54 db2admin Exp db2admin $';

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
      print STDERR "$sub - $tDate $tTime\n";
    }
    elsif ( $lit eq "DUMPSTACK" ) {
      for ( my $i = 0; $i <= $#stack; $i++ ) { print "$sub - $tDate $tTime : Stack $i : $stack[$i] [tot $#stack]\n"; }
    }
    elsif ( $lit eq "DUMPOUTPUT" ) {
      for ( my $i = 0; $i <= $#output; $i++ ) { print "$sub - $tDate $tTime : Output Stack $i : $output[$i] [tot $#output]\n"; }
    }
    elsif ( $lit eq "DUMPOPSTACK" ) {
      for ( my $i = 0; $i <= $#operandStack; $i++ ) { print "$sub - $tDate $tTime : Operand Stack $i : $operandStack[$i] [tot $#operandStack]\n"; }
    }
    else {
      print STDERR "$sub - $tDate $tTime : $lit\n";
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
  else { # just provide the next whitespace delimited token
    displayDebug("Token is not a string. Terminating character has been set as whitespace(ish) >>" . substr($tLine,$currentTokenPosition) ,2,$currentSubroutine);
    while ( ($currentTokenPosition <= length($tLine) ) && (substr($tLine,$currentTokenPosition,1) ne ' ') ) { # while still chars left and char is not space
      displayDebug(">>>>>>\$currentTokenPosition = $currentTokenPosition, char = " . substr($tLine,$currentTokenPosition,1) . ", tLine = $tLine, tTok = $tTok",2,$currentSubroutine);
      $tTok .= substr($tLine,$currentTokenPosition,1); # add the current character to the token
      $currentTokenPosition++;                         # move to the next character
      if ( $currentTokenPosition <= length($tLine) ) {
        # Stop if the token is the longest operator it can be (operators max out at 3 chars)
        if ( (isOperator(" " . $tTok . " ")) && 
             (! isOperator($tTok . substr($tLine,$currentTokenPosition,1))) &&
             (! isOperator($tTok . substr($tLine,$currentTokenPosition,2))) 
           ) { last; } 
        # Stop if the next chars are an operator # (unless it is part of a <> , etc operator)
        displayDebug("next byte = " . substr($tLine,$currentTokenPosition,1) . ", next 2 bytes = " . substr($tLine,$currentTokenPosition,2) . ",tTok = $tTok",2,$currentSubroutine);
        if ( (isOperator(" " . substr($tLine,$currentTokenPosition,1) . " ")) || 
             (isOperator(" " . substr($tLine,$currentTokenPosition,2) . " " )) ) { 
          if ( ! isOperator(" " . $tTok . substr($tLine,$currentTokenPosition,1) . " ")) { # isn't a 2 character operator
            displayDebug("In isOperator 1",2,$currentSubroutine);
            last; 
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
  # Returns: 0 - not operator , 1 operator
  # -----------------------------------------------------------

  my $currentSubroutine = 'isOperator';
  my $tok = shift;

  if ( index($calcOperators, uc($tok)) > -1 ) { return 1; }
  
  return 0;
} # end of isOperator

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

  displayDebug("Supplied infix string is: $infixString",1,$currentSubroutine); 

  my $token = getCalculateToken($infixString);
  if ( $token eq $infixString ) { # dont bother just return the string - nothing to do
    return $token;
  }

  # This first conversion converts the infix expression into a reverse polish expression  

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
      if ( $calcDebugLevel > 1  ) { for ( my $i = 0; $i <= $#stack; $i++ ) { displayDebug("   Stack $i : $stack[$i] [tot $#stack]",2,$currentSubroutine); } }
      displayDebug("Stack Size $#stack",1,$currentSubroutine); 
    }
    elsif ( $token eq "," ) {
      $retToken = pop(@stack);
      displayDebug("retToken: $retToken",1,$currentSubroutine); 
      while ( (defined($retToken)) && ($stack[$#stack] ne "\(") ) {# not end of the stack and top of stack <> '('
        displayDebug("retToken: $retToken",1,$currentSubroutine); 
        push (@output, $retToken) ;
        $retToken = pop(@stack);
        displayDebug("retToken: $retToken",1,$currentSubroutine); 
      }
      if ( ! defined($retToken) ) { # problem with parsing - should have come across a '(' first
        print STDERR "Parsing error. Missing (";
      }
    }
    elsif ( isOperator($token) ) {
      displayDebug("Operator on top of stack is: >$stack[$#stack]<, top of stack is $#stack, \$token is $token",1,$currentSubroutine); 
      while ( ($#stack > -1) && isOperator($stack[$#stack]) && ( $opPrecedence{$token} >= $opPrecedence{$stack[$#stack]} ) ) { # it's an operator on the top of stack and precendence of token is less or equal 
                                                                                                                               # than precedence of the operator on the top of the stack
        if( $opPrecedence{$stack[$#stack]} <= $opPrecedence{$token} ) {
          push(@output, pop(@stack)); # pop it off of the stack and put it to output
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
  
  displayDebug("Input: $infixString",1,$currentSubroutine);  
  my @operandStack = ();
  my $rPolish = shift(@output);
  displayDebug("DUMPOUTPUT",1,$currentSubroutine);  
  while ( (@output > 0) ) {
    if ( substr($rPolish . "  ",0,2) eq ':"' ) { # token is a string - so operand
      $rPolish = substr($rPolish,2);    # strip off the string indicator
      displayDebug("Token >$rPolish< is an operand",1,$currentSubroutine);
      push ( @operandStack, $rPolish) ;
      displayDebug("Pushing >$rPolish< onto the operandStack",2,$currentSubroutine);
    }
    elsif ( isOperator($rPolish) ) { # process the operator ....
      displayDebug("Token >$rPolish< is an Operator",1,$currentSubroutine);  
      $op2 =  pop(@operandStack);
      $op1 =  pop(@operandStack);
      displayDebug("op1 = $op1, op2 = $op2 : operator is >$rPolish<",1,$currentSubroutine);  
      if (    $rPolish eq "+" ) { # addition
        $val = $op1 + $op2;
      }
      elsif ( $rPolish eq "-" ) { # subtraction
        $val = $op1 - $op2;
      }
      elsif ( $rPolish eq "*" ) { # multiplication
        $val = $op1 * $op2;
      }
      elsif ( $rPolish eq "/" ) { # division
        $val = $op1 / $op2;
      }
      elsif ( ($rPolish eq ">") || ($rPolish eq "GT") ) { # greater than
        if ( $op1 > $op2 ) { # true
        $val = 1;
        }
        else { # false
          $val = 0;
        }
      }
      elsif ( ($rPolish eq ">=") || ($rPolish eq "GE") ) { # greater than or equal
        if ( $op1 >= $op2 ) { # true
        $val = 1;
        }
        else { # false
          $val = 0;
        }
      }
      elsif ( ($rPolish eq "<") || ($rPolish eq "LT")  ) { # less than
        if ( $op1 < $op2 ) { # true
        $val = 1;
        }
        else { # false
          $val = 0;
        }
      }
      elsif ( ($rPolish eq "<=") || ($rPolish eq "LE") ) { # less than or equal
        if ( $op1 <= $op2 ) { # true
        $val = 1;
        }
        else { # false
          $val = 0;
        }
      }
      elsif ( uc($rPolish) eq "AND" ) { # OR
        if ( isNumeric($op1) && ($op1 == 0) ) { # false
          $val = 0;
        }
        elsif ( isNumeric($op2) && ($op2 == 0) ) { # false
          $val = 0;
        }
        elsif ( $op1 eq '' ) { # false
          $val = 0;
        }
        elsif ( $op2 eq '' ) { # false
          $val = 0;
        }
        else { # false
          $val = 1;
        }
      }
      elsif ( uc($rPolish) eq "OR" ) { # OR
        if ( isNumeric($op1) && ($op1 != 0) ) { # true
          $val = 1;
        }
        elsif ( isNumeric($op2) && ($op2 != 0) ) { # true
          $val = 1;
        }
        elsif ( isNumeric($op1) && isNumeric($op2) ) { # if they are both numeric then they must have both been zero
          $val = 0;
        }
        elsif ( $op1 ne '' ) { # true
          $val = 1;
        }
      elsif ( $op2 ne '' ) { # true
          $val = 1;
        }
        else { # false
          $val = 0;
        }
      }
      elsif ( ($rPolish eq "<>") || ($rPolish eq "NE") ) { # not equal to
        if ( isNumeric($op1) && isNumeric($op2) ) { # if numeric
          if ( $op1 != $op2 ) { # true
            $val = 1;
          }
          else { # false
            $val = 0;
          }
        }
        else { # not numeric
          if ( "$op1" ne "$op2" ) { # true
            $val = 1;
          }
          else { # false
            $val = 0;
          }
        }
      }
      elsif ( ($rPolish eq "==") || ($rPolish eq "=") || ($rPolish eq "EQ") ) { # equals
        if ( isNumeric($op1) && isNumeric($op2) ) { # if numeric
          if ( $op1 == $op2 ) { # true
            $val = 1;
          }
          else { # false
            $val = 0;
          }
        }
        else { # not numeric
          if ( "$op1" eq "$op2" ) { # true
            $val = 1;
          }
          else { # false
            $val = 0;
          }
        }
      }
      elsif ( $rPolish eq "||" ) { # concatenation
        $val = $op1 . $op2;
        displayDebug("op1 = $op1, op2 = $op2, val = $val",1,$currentSubroutine);  
      }
      elsif ( $rPolish eq "%" ) { # modulo
        if ( isNumeric($op1) && isNumeric($op2) ) { # if numeric
          $val = $op1 % $op2;
        }
        else {
          return("ERROR: Parameters to % must be numeric - OP1=$op1, OP2=$op2");
        }
      }
      push ( @operandStack, $val);
    }
    elsif ( isFunction($rPolish) ) { # process the function ....
      displayDebug("Token >$rPolish< is a function",1,$currentSubroutine);  
      $val = 0;
      # Functions supported:  ABS SUBSTR LEFT RIGHT TRIM LTRIM RTRIM
      if ( uc($rPolish) eq "ABS" ) {
        # only one parameter to be processed
        $op1 =  pop(@operandStack);
        displayDebug("Op1 = $op1 : operator is $rPolish",1,$currentSubroutine);  
        $val = abs($op1);
      }
      elsif ( uc($rPolish) eq "SUBSTR" ) {
        # three parameters to be processed (
        $op3 =  pop(@operandStack);
        $op2 =  pop(@operandStack);
        $op1 =  pop(@operandStack);
        displayDebug("Op1 = $op1, Op2 = $op2, Op3 = $op3 : operator is $rPolish",1,$currentSubroutine);  
        if ( ( $op3 eq "EOS" ) || ( $op3 == 0 ) ) { # if the third panel is throw away ....
          $val = substr($op1, $op2);
        }
        else {
          $val = substr($op1, $op2, $op3);
        }
        displayDebug("Calculated value is $val",1,$currentSubroutine);  
      }
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
    $op2 =  pop(@operandStack);
    $op1 =  pop(@operandStack);
    displayDebug("2> op1 = $op1, op2 = $op2 : operator is >$rPolish<",1,$currentSubroutine);  
    if (    $rPolish eq "+" ) { # addition
      $val = $op1 + $op2;
    }
    elsif ( $rPolish eq "-" ) { # subtraction
      $val = $op1 - $op2;
    }
    elsif ( $rPolish eq "*" ) { # multiplication
      $val = $op1 * $op2;
    }
    elsif ( $rPolish eq "/" ) { # division
      $val = $op1 / $op2;
    }
    elsif ( $rPolish eq ">" ) { # greater than
      if ( $op1 > $op2 ) { # true
        $val = 1;
      }
      else { # false
        $val = 0;
      }
    }
    elsif ( $rPolish eq ">=" ) { # greater than or equal
      if ( $op1 >= $op2 ) { # true
        $val = 1;
      }
      else { # false
        $val = 0;
      }
    }
    elsif ( $rPolish eq "<" ) { # less than
      if ( $op1 < $op2 ) { # true
        $val = 1;
      }
      else { # false
        $val = 0;
      }
    }
    elsif ( $rPolish eq "<=" ) { # less than or equal
      if ( $op1 <= $op2 ) { # true
        $val = 1;
      }
      else { # false
        $val = 0;
      }
    }
    elsif ( uc($rPolish) eq "AND" ) { # OR
      if ( isNumeric($op1) && ($op1 == 0) ) { # false
        $val = 0;
      }
      elsif ( isNumeric($op2) && ($op2 == 0) ) { # false
        $val = 0;
      }
      elsif ( $op1 eq '' ) { # false
        $val = 0;
      }
      elsif ( $op2 eq '' ) { # false
        $val = 0;
      }
      else { # false
        $val = 1;
      }
    }
    elsif ( uc($rPolish) eq "OR" ) { # OR
      if ( isNumeric($op1) && ($op1 != 0) ) { # true
        $val = 1;
      }
      elsif ( isNumeric($op2) && ($op2 != 0) ) { # true
        $val = 1;
      }
      elsif ( isNumeric($op1) && isNumeric($op2) ) { # if they are both numeric then they must have both been zero
        $val = 0;
      }
      elsif ( $op1 ne '' ) { # true
        $val = 1;
      }
      elsif ( $op2 ne '' ) { # true
        $val = 1;
      }
      else { # false
        $val = 0;
      }
    }
    elsif ( $rPolish eq "<>" ) { # not equal to
      if ( isNumeric($op1) && isNumeric($op2) ) { # if numeric
        if ( $op1 != $op2 ) { # true
          $val = 1;
        }
        else { # false
          $val = 0;
        }
      }
      else { # not numeric
        if ( "$op1" ne "$op2" ) { # true
          $val = 1;
        }
        else { # false
          $val = 0;
        }
      }
    }
    elsif ( ($rPolish eq "==") || ($rPolish eq "=") ) { # equals
      if ( isNumeric($op1) && isNumeric($op2) ) { # if numeric
        if ( $op1 == $op2 ) { # true
          $val = 1;
        }
        else { # false
          $val = 0;
        }
      }
      else { # not numeric
        if ( "$op1" eq "$op2" ) { # true
          $val = 1;
        }
        else { # false
          $val = 0;
        }
      }
    }
    elsif ( $rPolish eq "||" ) { # division
      $val = $op1 . $op2;
      displayDebug(">>VAL=$val,op1 = $op1, op2 = $op2",1,$currentSubroutine);  
    }
    elsif ( $rPolish eq "%" ) { # modulo
      if ( isNumeric($op1) && isNumeric($op2) && ($op1 != '') && ($op2 != '')  ) { # if numeric
        $val = $op1 % $op2;
      }
      else {
        $val = "ERROR: Variables must be numeric for % operator. Op1 = $op1, Op2 = $op2\n";
      }
    }
    displayDebug("Pushing >$val< onto the operandStack",1,$currentSubroutine);  
    displayDebug("DUMPOPSTACK",2,$currentSubroutine);  
    push ( @operandStack, $val);
  }
  elsif ( isFunction($rPolish) ) { # process the function ....
    # Functions supported:  ABS SUBSTR LEFT RIGHT TRIM LTRIM RTRIM 
    $val = 0;
    if ( uc($rPolish) eq "ABS" ) { 
      # only one parameter to be processed
      $op1 =  pop(@operandStack);
      displayDebug("Op1 = $op1 : operator is $rPolish",1,$currentSubroutine);  
      $val = abs($op1);
    }
    elsif ( uc($rPolish) eq "SUBSTR" ) {
      # three parameters to be processed (
      $op3 =  pop(@operandStack);
      $op2 =  pop(@operandStack);  
      $op1 =  pop(@operandStack);  
      displayDebug("Op1 = $op1, Op2 = $op2, Op3 = $op3 : operator is $rPolish",1,$currentSubroutine);  
      if ( ( $op3 eq "EOS" ) || ( $op3 == 0 ) ) { # if the third panel is throw away ....
        $val = substr($op1, $op2); 
      }
      else {
        $val = substr($op1, $op2, $op3);
      }
      displayDebug("Calculated value is $val",1,$currentSubroutine);  
    }
    elsif ( uc($rPolish) eq "LEFT" ) {
      # two parameters to be processed (
      $op2 =  pop(@operandStack);  
      $op1 =  pop(@operandStack);  
      displayDebug("Op1 = $op1, Op2 = $op2 : operator is $rPolish",1,$currentSubroutine);  
      $val = substr($op1, $op2);
      displayDebug("Calculated value is $val",1,$currentSubroutine);  
    }
    elsif ( uc($rPolish) eq "RIGHT" ) {
      # two parameters to be processed (
      $op2 =  pop(@operandStack);  
      $op1 =  pop(@operandStack);  
      displayDebug("Op1 = $op1, Op2 = $op2 : operator is $rPolish",1,$currentSubroutine);  
      $val = substr($op1, -1*$op2);
      displayDebug("Calculated value is $val",1,$currentSubroutine);  
    }
    elsif ( uc($rPolish) eq "TRIM" ) {
      # only one parameter to be processed
      $op1 =  pop(@operandStack);
      displayDebug("Op1 = $op1 : operator is $rPolish",1,$currentSubroutine);  
      $val = $op1;
      $val =~ s/^\s+//;
      $val =~ s/\s+$//;
    }
    elsif ( uc($rPolish) eq "LTRIM" ) {
      # only one parameter to be processed
      $op1 =  pop(@operandStack);
      displayDebug("Op1 = $op1 : operator is $rPolish",1,$currentSubroutine);  
      $val = $op1;
      $val =~ s/^\s+//;
    }
    elsif ( uc($rPolish) eq "RTRIM" ) {
      # only one parameter to be processed
      $op1 =  pop(@operandStack);
      displayDebug("Op1 = $op1 : operator is $rPolish",1,$currentSubroutine);  
      $val = $op1;
      $val =~ s/\s+$//;
    }
    push ( @operandStack, $val);
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
  return $val;
} # end of evaluateInfix
1;

