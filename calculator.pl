#!/usr/bin/perl
# --------------------------------------------------------------------
# calculator.pl
#
# $Id: calculator.pl,v 1.3 2012/04/03 06:03:38 db2admin Exp db2admin $
#
# Description:
# Script to evaluate a infix calculation string
#
# Usage:
#   require calculator.pl
#   $x = evaluateInfix("1+2 + 3/ 45 * (4/5)";
#   This is a subroutine and not a stand alone program - it must be called from 
#   another program
#
# $Name:  $
#
# ChangeLog:
# $Log: calculator.pl,v $
# Revision 1.3  2012/04/03 06:03:38  db2admin
# Lots of changes correcting errors
# Added in Function processing
#
# Revision 1.2  2012/03/06 00:37:09  db2admin
# if it is an unknown token or a single value then just return that value
#
# Revision 1.1  2012/01/03 21:57:34  db2admin
# Initial revision
#
#
# --------------------------------------------------------------------"

sub calcVersion {

  $ID = '$Id: calculator.pl,v 1.3 2012/04/03 06:03:38 db2admin Exp db2admin $';
  @V = split(/ /,$ID);
  $nameStr=$V[1];
  ($name,$x) = split(",",$nameStr);
  $Version=$V[2];
  $Changed="$V[3] $V[4]";

  return "$name ($Version)  Last Changed on $Changed (UTC)";

}

sub getCalculateToken {
  # return the next space delimited token from the supplied parameter
  my $tLine = shift;
  my $tTok = "";
  # Skip whitespace
  while ( ($CALC_cPos <= length($tLine) ) && (substr($tLine,$CALC_cPos,1) eq " ") ) { 
    $CALC_cPos++;
  }
  # Set token value
  my $testToken = " ";
  if ( (substr($tLine,$CALC_cPos,1) eq "\'" ) || (substr($tLine,$CALC_cPos,1) eq "\"" ) ) { # it starts with a quote
    # special processing for strings
    $testToken = substr($tLine,$CALC_cPos,1);
    $CALC_cPos++; # skip the first quote
    while ( ($CALC_cPos <= length($tLine) ) && (substr($tLine,$CALC_cPos,1) ne $testToken) ) {
      $tTok = $tTok . substr($tLine,$CALC_cPos,1);
      $CALC_cPos++;
    }
    if ( $CALC_cPos <= length($tLine) ) {
      $CALC_cPos++; # skip the last quote
    }
  }
  else {
    while ( ($CALC_cPos <= length($tLine) ) && (substr($tLine,$CALC_cPos,1) ne $testToken) ) { # while still chars left and char is not space
      if ( $CALC_debugLevel > 0 ) { print "CALC_cPos = $CALC_cPos, char = " . substr($tLine,$CALC_cPos,1) . ", tLine = $tLine\n";  }
      $tTok = $tTok . substr($tLine,$CALC_cPos,1);
      if ( $CALC_debugLevel > 0  ) { print "0> Token = >$tTok<\n"; }
      $CALC_cPos++;
      if ( $CALC_cPos <= length($tLine) ) {
        if ( (CALC_isOperator(" " . $tTok . " ")) && (! CALC_isOperator($tTok . substr($tLine,$CALC_cPos,1)))) { print ">1:\n"; last; } # stop token if an operator finishes
        if ( (CALC_isOperator(" " . substr($tLine,$CALC_cPos,1) . " ")) ||
             (CALC_isOperator(" " . substr($tLine,$CALC_cPos,2) . " " )) ) { print ">2:\n"; last; } # stop token if the next character would be the start of an operator 
        if ( index(' ) , ( ', substr($tLine,$CALC_cPos,1)) > -1 ) { last; } # stop when you get to a any of ),( or ,
        if ( $tTok eq "\(" ) { last; } # parenthesis are always 
      }
    }
    if ( $CALC_cPos <= length($tLine) ) {
      if ( (CALC_isOperator(substr($tLine,$CALC_cPos,1))) || (index(' ) ( ', substr($tLine,$CALC_cPos,1)) > -1) )  { 
        # do nothing
      }
      elsif ( (CALC_isOperator($tTok)) && (! CALC_isOperator($tTok . substr($tLine,$CALC_cPos,1))) ) {
        # do nothing
      }
      elsif ( $tTok eq "\(" ) {
        # do nothing
      }
      else {
        $CALC_cPos++;
      }  
    }
  }
  if ( $CALC_debugLevel > 0  ) { print "Token = >$tTok<\n"; }
  return $tTok;
}

sub CALC_isNumeric {
# check if a variable is numeric
  my $var = shift;
  
  if ($var =~ /\D/)             { return 0; } # contains non-numeric characters
  if ( $CALC_debugLevel > 0 ) { print "Got to test 1\n"; }
  if ($var =~ /^\d+\z/)         { return 1; } # integer
  if ( $CALC_debugLevel > 0 ) { print "Got to test 2\n"; }
  if ($var =~ /^-?\d+\z/)       { return 1; } # +/- integer
  if ( $CALC_debugLevel > 0 ) { print "Got to test 3\n"; }
  if ($var =~ /^[+-]?\d+\z/)    { return 1; }
  if ( $CALC_debugLevel > 0 ) { print "Got to test 4\n"; }
  if ($var =~ /^-?\d+\.?\d*\z/) { return 1; } # decimal numbe
  if ( $CALC_debugLevel > 0 ) { print "Got to test 5\n"; }
  if ($var =~ /^-?(?:\d+(?:\.\d*)?&\.\d+)\z/) { return 1; }
  if ( $CALC_debugLevel > 0 ) { print "Got to test 6\n"; }
  if ($var =~ /^([+-]?)(?=\d&\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\z/) { return 1; }

  return 0;
}

sub CALC_isFunction {
# check if a variable is a function
  my $tok = shift;

  if ( index(" ABS SUBSTR LEFT RIGHT TRIM LTRIM RTRIM ", uc(" " . $tok . " ")) > -1 ) { return 1; }
  
  return 0;
}

sub CALC_isOperator {
# check if a variable is an operator
  my $tok = shift;

  if ( index(" + - * / % || ", uc($tok)) > -1 ) { return 1; }
  
  return 0;
}

sub evaluateInfix {

  my $infixString = shift;
  $infixString = trim($infixString);
  my $precedence;

  # precedence
  $precedence{'!'} = 2;
  $precedence{'*'} = 3;
  $precedence{'/'} = 3;
  $precedence{'%'} = 3;
  $precedence{'+'} = 4;
  $precedence{'-'} = 4;

  $CALC_cPos = 0;

  my $calc = 0;
  my @output = ();
  my @stack = ();
  push(@stack,"END_OF_STACK");

  if ( $CALC_debugLevel > 0  ) { print STDERR "Supplied infix string is: $infixString\n"; }

  my $token = getCalculateToken($infixString);
  if ( $token eq $infixString ) { # dont bother just return the string - nothing to do
    return $token;
  }

  #print STDERR "token = $token\n";
  while ($token ne "") {
    if ( CALC_isNumeric($token) ) { 
      push (@output, $token) ; 
      if ( $CALC_debugLevel > 1  ) { for ( my $i = 0; $i <= $#stack; $i++ ) { print "Stack $i : $stack[$i] [tot $#stack]\n"; } }
      if ( $CALC_debugLevel > 0  ) { print STDERR "Pushing numeric $token output size = $#output\n"; }
    }
    elsif ( CALC_isFunction($token) ) {
      push (@stack, $token) ; 
      if ( $CALC_debugLevel > 1  ) { for ( my $i = 0; $i <= $#stack; $i++ ) { print "Stack $i : $stack[$i] [tot $#stack]\n"; } }
      if ( $CALC_debugLevel > 0  ) { print STDERR "Stack size = $#stack\n"; }
    }
    elsif ( $token eq "," ) {
      my $retToken = pop(@stack);
      while ( ($retToken ne "END_OF_STACK") || ($retToken eq "\(") ) {
        push (@output, $token) ;
      }
      if ( $retToken ne "END_OF_STACK" ) {
        print STDERR "Parsing error missing (";
      }
    }
    elsif ( CALC_isOperator($token) ) {
      if ( $CALC_debugLevel > 0  ) { print "Operator on top of stack is: $stack[$#stack]\n"; }
      if ( CALC_isOperator($stack[$#stack]) ) {
        if( $precedence{$stack[$#stack]} <= $precedence{$token} ) {
       	  push(@output, pop(@stack)); # pop it off of the stack and put it to output
        }
      }
      if ( $CALC_debugLevel > 0  ) { print STDERR "Pushing operator $token stack size = $#stack\n"; }
      push (@stack, $token) ;
      #for ( my $i = 0; $i <= $#stack; $i++ ) { print "Stack $i : $stack[$i] [tot $#stack]\n"; }
    }
    elsif ( $token eq "\(" ) {
      push (@stack, $token) ;
      if ( $CALC_debugLevel > 0  ) { print "Pushing ( on to stack\n"; for ( my $i = 0; $i <= $#stack; $i++ ) { print "Stack $i : $stack[$i] [tot $#stack]\n"; } }
    }
    elsif ( $token eq "\)" ) {
      while ( ($stack[$#stack] ne "END_OF_STACK") && ($stack[$#stack] ne "\(" ) ) {
        if ( $CALC_debugLevel > 1  ) { for ( my $i = 0; $i <= $#stack; $i++ ) { print "Stack $i : $stack[$i] [tot $#stack]\n"; } }
        push(@output, pop(@stack)); # pop it off of the stack and put it to output
        if ( $CALC_debugLevel > 0  ) { print "added to output stack : $output[$#output]\n"; }
      }
      if ( $stack[$#stack] ne "END_OF_STACK" ) {  # just throw away the matching (
        pop(@stack); 
        if ( CALC_isFunction($stack[$#stack]) ) { # if it was a function pop the function call off as well
          push(@output, pop(@stack)); # pop it off of the stack and put it to output
        }
      } 
      else { # there's a problem
        print STDERR "Calculator Error: Parsing error mismatched parentheses\n";
      }
    }
    else { # token was none of the above - ie it was probably just a string
	   # abort the calculation and just return the originallly supplied string as the result
      push (@output, $token) ;
      if ( $CALC_debugLevel > 1  ) { for ( my $i = 0; $i <= $#stack; $i++ ) { print "Stack $i : $stack[$i] [tot $#stack]\n"; } }
      if ( $CALC_debugLevel > 0  ) { print STDERR "Pushing numeric $token output size = $#output\n"; }
    }
    # get the next token
    $token = getCalculateToken($infixString);
  }
  if ( $CALC_debugLevel > 0  ) { print "Started stack clear down\n"; }
  while ( $stack[$#stack] ne "END_OF_STACK" ) { # flush out the rest of the stack
    if ( $CALC_debugLevel > 0  ) { for ( my $i = 0; $i <= $#stack; $i++ ) { print "Stack $i : $stack[$i] [tot $#stack]\n"; } }
    $retToken = pop(@stack);
    if ( index(' ( ) ', $retToken) > -1 ) {
      print STDERR "Calculator Error: Parsing error mismatched parentheses\n";
    }
    else {
      push(@output, $retToken);
    }
  }
  if ( $CALC_debugLevel > 0  ) { print "Finished stack clear down\n"; }

  if ( $CALC_debugLevel > 1  ) { for ( my $i = 0; $i <= $#output; $i++ ) { print "Output Stack $i : $output[$i] [tot $#output]\n"; } }
  
  # Now evaluate the converted infix string!
  
  if ( $CALC_debugLevel > 0  ) {  print "Input: $infixString\n"; }
  my @operandStack = ();
  $rPolish = shift(@output);
  if ( $CALC_debugLevel > 1  ) { for ( my $i = 0; $i <= $#output; $i++ ) { print "Output Stack $i : $output[$i] [tot $#output]\n"; } }
  my $op1, $op2, $val;
  while ( (@output > 0) ) {
    if ( CALC_isOperator($rPolish) ) { # process the operator ....
      if ( $CALC_debugLevel > 1  ) { print "Token >$rPolish< is an Operator\n"; }
      $op2 =  pop(@operandStack);
      $op1 =  pop(@operandStack);
      if ( $CALC_debugLevel > 0  ) {  print "op1 = $op1, op2 = $op2 : operator is >$rPolish<\n"; }
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
      elsif ( $rPolish eq "||" ) { # division
        $val = $op1 . $op2;
        if ( $CALC_debugLevel > 1  ) { print "op1 = $op1, op2 = $op2, val = $val\n"; }
      }
      elsif ( $rPolish eq "%" ) { # modulo
        $val = $op1 % $op2;
      }
      push ( @operandStack, $val);
    }
    elsif ( CALC_isFunction($rPolish) ) { # process the function ....
      if ( $CALC_debugLevel > 1  ) { print "Token >$rPolish< is a function\n"; }
      $val = 0;
      # Functions supported:  ABS SUBSTR LEFT RIGHT TRIM LTRIM RTRIM
      if ( uc($rPolish) eq "ABS" ) {
        # only one parameter to be processed
        $op1 =  pop(@operandStack);
        if ( $CALC_debugLevel > 0  ) { print "Op1 = $op1 : operator is $rPolish\n"; }
        $val = abs($op1);
      }
      elsif ( uc($rPolish) eq "SUBSTR" ) {
        # three parameters to be processed (
        $op3 =  pop(@operandStack);
        $op2 =  pop(@operandStack);
        $op1 =  pop(@operandStack);
        if ( $CALC_debugLevel > 0  ) { print "Op1 = $op1, Op2 = $op2, Op3 = $op3 : operator is $rPolish\n"; }
        if ( ( $op3 eq "EOS" ) || ( $op3 == 0 ) ) { # if the third panel is throw away ....
          $val = substr($op1, $op2);
        }
        else {
          $val = substr($op1, $op2, $op3);
        }
        if ( $CALC_debugLevel > 0  ) { print "Calculated value is $val\n"; }
      }
      push ( @operandStack, $val) ; # put the value back on the operand stack
    }
    else { # must be an operand - save it for later use
      if ( $CALC_debugLevel > 1  ) { print "Token >$rPolish< is an operand\n"; }
      push ( @operandStack, $rPolish) ;
      if ( $CALC_debugLevel > 1  ) { print "Pushing >$rPolish< onto the operandStack\n"; }
    }
    # get the next element off of the Reverse Polish stack
    $rPolish = shift(@output);
  }

  if ( $CALC_debugLevel > 1  ) { for ( my $i = 0; $i <= $#operandStack; $i++ ) { print "Operand Stack $i : $operandStack[$i] [tot $#operandStack]\n"; } }
  
  if ( CALC_isOperator($rPolish) ) { # process the operator ....
    $op2 =  pop(@operandStack);
    $op1 =  pop(@operandStack);
    if ( $CALC_debugLevel > 0  ) { print "2> op1 = $op1, op2 = $op2 : operator is >$rPolish<\n"; }
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
    elsif ( $rPolish eq "||" ) { # division
      $val = $op1 . $op2;
      if ( $CALC_debugLevel > 1  ) { print ">>VAL=$val\n"; }
      if ( $CALC_debugLevel > 1  ) { print "op1 = $op1, op2 = $op2, val = $val\n"; }
    }
    elsif ( $rPolish eq "%" ) { # modulo
      $val = $op1 % $op2;
    }
    if ( $CALC_debugLevel > 1  ) { print "Pushing >$val< onto the operandStack\n"; }
    if ( $CALC_debugLevel > 1  ) { for ( my $i = 0; $i <= $#operandStack; $i++ ) { print "Operand Stack $i : $operandStack[$i] [tot $#operandStack]\n"; } }
    push ( @operandStack, $val);
  }
  elsif ( CALC_isFunction($rPolish) ) { # process the function ....
    # Functions supported:  ABS SUBSTR LEFT RIGHT TRIM LTRIM RTRIM 
    $val = 0;
    if ( uc($rPolish) eq "ABS" ) { 
      # only one parameter to be processed
      $op1 =  pop(@operandStack);
      if ( $CALC_debugLevel > 0  ) { print "Op1 = $op1 : operator is $rPolish\n"; }
      $val = abs($op1);
    }
    elsif ( uc($rPolish) eq "SUBSTR" ) {
      # three parameters to be processed (
      $op3 =  pop(@operandStack);
      $op2 =  pop(@operandStack);  
      $op1 =  pop(@operandStack);  
      if ( $CALC_debugLevel > 0  ) { print "Op1 = $op1, Op2 = $op2, Op3 = $op3 : operator is $rPolish\n"; }
      if ( ( $op3 eq "EOS" ) || ( $op3 == 0 ) ) { # if the third panel is throw away ....
        $val = substr($op1, $op2); 
      }
      else {
        $val = substr($op1, $op2, $op3);
      }
      if ( $CALC_debugLevel > 0  ) { print "Calculated value is $val\n"; }
    }
    elsif ( uc($rPolish) eq "LEFT" ) {
    }
    elsif ( uc($rPolish) eq "RIGHT" ) {
    }
    elsif ( uc($rPolish) eq "TRIM" ) {
    }
    elsif ( uc($rPolish) eq "LTRIM" ) {
    }
    elsif ( uc($rPolish) eq "RTRIM" ) {
    }
    push ( @operandStack, $val);
  }
  else {
    print STDERR "Calculator Error - Something wrong - Found $rPolish on the stack - it should be an operator!\n";
  }

  $val = pop(@operandStack);
  return $val;
}
1;
