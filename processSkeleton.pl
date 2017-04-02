#!/usr/bin/perl
# --------------------------------------------------------------------
# processSkeleton.pl
#
# $Id: processSkeleton.pl,v 1.36 2014/03/28 03:20:22 db2admin Exp db2admin $
#
# Description:
# Script to process a skeleton
#
# Usage:
#   ? Not determined yet
#   This is a subroutine and not a stand alone program - it must be called from 
#   another program
#
# $Name:  $
#
# ChangeLog:
# $Log: processSkeleton.pl,v $
# Revision 1.36  2014/03/28 03:20:22  db2admin
# correct bug in HTTPFILE mode
#
# Revision 1.35  2014/03/28 01:07:49  db2admin
# bring the UDB and the ODBC (SQLServer) version into line
#
# Revision 1.34  2014/03/28 00:44:48  db2admin
# convert $#92 characters (hex code for backslash) to actual backslashes in SQL statements
#
# Revision 1.1  2013/07/10 06:02:43  db2admin
# Initial revision
#
# Revision 1.32  2013/06/25 04:16:29  db2admin
# Blank out reference field for cursor when cursor is closed
#
# Revision 1.31  2013/06/25 02:42:43  db2admin
# dont close cursor even if it is empty
#
# Revision 1.30  2013/06/25 02:35:41  db2admin
# close cursor when removing a cursor ref
#
# Revision 1.29  2013/06/25 02:26:35  db2admin
# Improve debugging and correct code so that a reuse of a cursor name
# automatically reoves references to the old cursor
#
# Revision 1.28  2013/06/25 00:42:49  db2admin
# dont process )ENDSEL in a )DOT loop when no rows returned
#
# Revision 1.27  2013/06/11 06:37:49  db2admin
# Add in code to allow the turning off and on of the SHOWSQL flag (SKL_SHOWSQL)
# from within a skeleton
#
# Revision 1.26  2012/11/14 21:16:18  db2admin
# Substitute variables before evaluating expressions
# Add in some special processing for the # symbol in web addresses (not a very good solution)
#
# Revision 1.24  2012/10/09 00:48:09  db2admin
# Add in code to right align numeric fields when generating the HTML table for FTAB statements.
# This change does NOT affect FVTAB commands
#
# Revision 1.23  2012/04/03 06:47:07  db2admin
# Correct a couple of bugs
#
# Revision 1.22  2012/04/03 06:41:17  db2admin
# Add in code to automatically show used SQL
# Add in code to retrieve long columns
# Add CONTAINS operator for )SEL
# Add option to provide SQL in a file
# Correct bug with checking for NULL
# Add in version code
#
# Revision 1.18  2012/03/06 01:05:38  db2admin
# Add in ROWCNT variable to hold the number of rows returned from a cursor
# Improve debugging
#
# Revision 1.17  2012/02/22 00:46:09  db2admin
# Add in + and " as variable terminator chars
#
# Revision 1.16  2012/02/21 04:49:01  db2admin
# Add in < and > to terminator characters
#
# Revision 1.15  2012/01/30 01:57:29  db2admin
# Added in )XDOT. Initial very brief testing completed
#
# Revision 1.14  2012/01/29 21:58:15  db2admin
# Added )TRACE and )TRACEOFF skeleton commands
#
# Revision 1.13  2012/01/23 01:43:17  db2admin
# Code checkpoint - database connection working, substitution of bare variables works ok but not statement specific
# substitutions
#
# Revision 1.12  2012/01/19 01:35:58  db2admin
# substituteVariables modified to use cursors - coded, compiled but not tested
#
# Revision 1.11  2012/01/16 05:03:13  db2admin
# Added in the establishCursor code - compiles but not tested
#
# Revision 1.10  2012/01/16 03:58:31  db2admin
# Added in )LOGON and )LOGOFF statements - tested OK
#
# Revision 1.9  2012/01/09 21:04:09  db2admin
# code checkpoint - )DOF seems to be working
# delimited files also working
#
# Revision 1.8  2012/01/08 21:37:08  db2admin
# formatSQL working and )DOF testing started
#
# Revision 1.7  2012/01/05 22:14:46  db2admin
# Code checkpoint - all compiled )DEBUG added
#
# Revision 1.6  2012/01/04 22:08:44  db2admin
# Code Checkpoint - Base formatSQL in and running (not working though)
#
# Revision 1.5  2012/01/04 00:33:32  db2admin
# Code checkpoint
#
# Revision 1.4  2011/12/30 00:17:53  db2admin
# Code as is (no skeleton functionality) looks like it is working
#
# Revision 1.3  2011/12/29 22:43:35  db2admin
# Initial code errors fixed
#
# Revision 1.2  2011/12/29 22:22:36  db2admin
# Progress save - base structure defined
#
# Revision 1.1  2011/12/29 04:12:00  db2admin
# Initial revision
# --------------------------------------------------------------------"

# PERL modules that will be used to connect to databases (comment out if no database connections are required)
use DBI;
use DBD::DB2;

sub by_key {
  $a cmp $b ;
}

sub skelVersion {

  $ID = '$Id: processSkeleton.pl,v 1.36 2014/03/28 03:20:22 db2admin Exp db2admin $';
  @V = split(/ /,$ID);
  $nameStr=$V[1];
  ($name,$x) = split(",",$nameStr);
  $Version=$V[2];
  $Changed="$V[3] $V[4]";

  return "$name ($Version)  Last Changed on $Changed (UTC)";

}

sub removeCRLF {

  # Remove all line feeds from the string supplied as parameter to the sub

  my $tmpStr = shift;

  $tmpStr =~ s/\n/ /g;
  $tmpStr =~ s/\r/ /g;

  return $tmpStr;
}

sub removeUnnecessaryWhiteSpace {

  # Remove Unnecessary whitespace from the supplied string (whitespace is defined as spaces and tabs)
  # exclude white space that exists within quotes

  my $origStr = shift;
  my $tmpStr  = "";

  my $inSingleQuotes = "Yes";
  my $inDoubleQuotes = "Yes";
  my $inWhiteSpace = "Yes";

  for ( my $i =0 ; $i <= length($origStr) ; $i++ ) {
    if ( substr($origStr,$i,2) eq "\'\'" ) { # two single quotes found
      $tmpStr = $tmpStr . substr($origStr,$i,2);
      $i = $i + 1;
    }
    elsif ( substr($origStr,$i,2) eq "\"\"" ) { # two double quotes found
      $tmpStr = $tmpStr . substr($origStr,$i,2);
      $i = $i + 1;
    }
    elsif ( substr($origStr,$i,1) eq "\'" ) { # one single quote found
      if ( $inSingleQuotes eq "Yes" ) {
        $inSingleQuotes = "No";
      }
      else {
        $inSingleQuotes = "Yes";
      }
      $tmpStr = $tmpStr . substr($origStr,$i,1);
    }
    elsif ( substr($origStr,$i,1) eq "\"" ) { # one double quote found
      if ( $inDoubleQuotes eq "Yes" ) {
        $inDoubleQuotes = "No";
      }
      else {
        $inDoubleQuotes = "Yes";
      }
      $tmpStr = $tmpStr . substr($origStr,$i,1);
    }
    elsif ( index(" \t", substr($origStr, $i,1)) > -1 ) {  # whitespace character found
      if ( $inWhiteSpace eq "No" ) { # not currently in a whitespace block
        $inWhiteSpace = "Yes";
        $tmpStr = $tmpStr . " ";
      }
    }
    else { # is a non-whitespace character
      $inWhiteSpace = "No";
      $tmpStr = $tmpStr . substr($origStr, $i,1);
    }
  }

  return $tmpStr;
}

sub formatSQL {
  # Routine to roughly format SQL 

  my $SQLString = shift;
  my $tmpStr = "";

  my $FSQL_lEdge = 0;
  my $extraIndent = 0;
  my $FSQL_cPos = 0;
  my $inSelect = "No";

  my @stack = ();  # lEdge stack
  my @stack2 = (); # indent stack
  my @stack3 = (); # inSelect stack
  my @stack4 = (); # inFunction stack
  my @stack5 = (); # extraIndent stack

  my $FSQL_lastToken = "";
  my $FSQL_lastToken_endofToken = "Yes";
  my $inFunction = "No";
  my $cntSinceLastCRLF = 0;

  if ( length($SQLString) < 2 ) { return $SQLString ; } # not a lot to do

  $SQLString = removeCRLF($SQLString);                  # remove all line feeds
  $SQLString = removeUnnecessaryWhiteSpace($SQLString); # remove all unecessary whiteSpace and convert tabs to spaces

  for ( my $pos=0; $pos<=length($SQLString); $pos++ ) { # loop through the string
    # reset the last token if necessary
    if ( (substr($SQLString,$pos,1) =~ /[ ,]/) ) {
      $FSQL_lastToken_endofToken = "Yes";
    }

    if ( uc(substr($SQLString,$pos,4)) eq "WITH" ) { 
      $FSQL_lEdge = $FSQL_lEdge + 2;
      $tmpStr .=  substr($SQLString,$pos,1) ;
      if ( $FSQL_lastToken_endofToken eq "Yes" ) { $FSQL_lastToken = substr($SQLString,$pos,1); }
      else { $FSQL_lastToken .= substr($SQLString,$pos,1); }
      $extraIndent = 0;
    }
    elsif ( uc(substr($SQLString,$pos,6)) eq "SELECT" ) { 
      push(@stack,$FSQL_lEdge); # save the current left hand edge
      $inSelect = "Yes";
      $FSQL_lEdge = $cntSinceLastCRLF;
      $FSQL_indent = 2;
      $extraIndent = 1; 
      $tmpStr .=  substr($SQLString,$pos,1) ;
      if ( $FSQL_lastToken_endofToken eq "Yes" ) { $FSQL_lastToken = substr($SQLString,$pos,1); }
      else { $FSQL_lastToken .= substr($SQLString,$pos,1); }
      displayDebug("cntSinceLastCRLF=$cntSinceLastCRLF, FSQL_lEdge=$FSQL_lEdge, FSQL_indent=$FSQL_indent, extraIndent=$extraIndent, tmpStr=$tmpStr",3);
      $cntSinceLastCRLFi++;
      $extraIndent = 5;
    }
    elsif ( (uc(substr($SQLString,$pos,5)) eq "WHERE" ) ||
            (uc(substr($SQLString,$pos,5)) eq "ORDER" ) ||
            (uc(substr($SQLString,$pos,5)) eq "GROUP" ) ||
            (uc(substr($SQLString,$pos,6)) eq "HAVING" ) ||
            (uc(substr($SQLString,$pos,4)) eq "FROM" ) 
	   ) { 
      $inSelect = "No";
      $tmpStr .= "\n" . space($FSQL_lEdge) . space($FSQL_indent) . substr($SQLString,$pos,1) ;
      displayDebug("FSQL_lEdge=$FSQL_lEdge, FSQL_indent=$FSQL_indent, extraIndent=$extraIndent, tmpStr=$tmpStr",3);
      if ( $FSQL_lastToken_endofToken eq "Yes" ) { $FSQL_lastToken = substr($SQLString,$pos,1); }
      else { $FSQL_lastToken .= substr($SQLString,$pos,1); }
      $cntSinceLastCRLF = $FSQL_lEdge + $FSQL_indent + 1;
      if ( (uc(substr($SQLString,$pos,5)) eq "WHERE" ) ) { $extraIndent = 2; }
      if ( (uc(substr($SQLString,$pos,5)) eq "ORDER" ) ) { $extraIndent = 9; }
      if ( (uc(substr($SQLString,$pos,5)) eq "GROUP" ) ) { $extraIndent = 9; }
      if ( (uc(substr($SQLString,$pos,5)) eq "HAVING" ) ) { $extraIndent = 7; }
      if ( (uc(substr($SQLString,$pos,4)) eq "FROM" ) ) { $extraIndent = 4; }
    }
    elsif ( uc(substr($SQLString,$pos,1)) eq "(" ) { # Just print out the (but set a new indent level)
      push(@stack2,$FSQL_indent);
      push(@stack3,$inSelect);  # save the inSelect status
      push(@stack5,$extraIndent);  # save the extraIndent size
      push(@stack,$FSQL_lEdge); # save the current left hand edge
      $tmpStr = $tmpStr . substr($SQLString,$pos,1);
      if ( $FSQL_lastToken_endofToken eq "Yes" ) { $FSQL_lastToken = substr($SQLString,$pos,1); }
      else { $FSQL_lastToken .= substr($SQLString,$pos,1); }
      $cntSinceLastCRLF++;
      if ( $FSQL_lastToken eq "," ) { # probably a subslelect (or something needing formatting)
        $FSQL_lEdge = $cntSinceLastCRLF+1; # set how many spaces to indent
	$inFunction = "No";
      } 
      else { # was probably a function (or something not needing formatting)
	$inFunction = "Yes";
      }
      push(@stack4,$inFunction);
    }
    elsif ( uc(substr($SQLString,$pos,1)) eq ")" ) { # CR, indent and then )
      if ( $inFunction eq "Yes" ) { # dont throw a line feed
        $tmpStr .=  ")" ;
      }
      else {
        $tmpStr .=  "\n" . space($FSQL_lEdge) . space($FSQL_indent) . ")" ;
      }
      if ( $FSQL_lastToken_endofToken eq "Yes" ) { $FSQL_lastToken = substr($SQLString,$pos,1); }
      else { $FSQL_lastToken .= substr($SQLString,$pos,1); }
      $inSelect = pop(@stack3);
      $inFunction = pop(@stack4);
      $FSQL_indent = pop(@stack2);
      $FSQL_lEdge = pop(@stack);
      $extraIndent = pop(@stack5);
      $cntSinceLastCRLF = $FSQL_lEdge + $FSQL_indent + 1;
    }
    elsif ( uc(substr($SQLString,$pos,3)) eq "AND" ) { # print the comma, CR and then indent
      $tmpStr .=  "\n" . space($FSQL_lEdge) . space($FSQL_indent) . space($extraIndent) . substr($SQLString,$pos,1);
      if ( $FSQL_lastToken_endofToken eq "Yes" ) { $FSQL_lastToken = substr($SQLString,$pos,1); }
      else { $FSQL_lastToken .= substr($SQLString,$pos,1); }
      $cntSinceLastCRLF = $FSQL_lEdge + $FSQL_indent + $extraIndent;
    }
    elsif ( uc(substr($SQLString,$pos,1)) eq "," ) { # print the comma, CR and then indent
      $tmpStr .=  ",\n" . space($FSQL_lEdge) . space($FSQL_indent) . space($extraIndent);
      if ( $FSQL_lastToken_endofToken eq "Yes" ) { $FSQL_lastToken = substr($SQLString,$pos,1); }
      else { $FSQL_lastToken .= substr($SQLString,$pos,1); }
      $cntSinceLastCRLF = $FSQL_lEdge + $FSQL_indent + $extraIndent;
      displayDebug("cntSinceLastCRLF=$cntSinceLastCRLF, FSQL_lEdge=$FSQL_lEdge, FSQL_indent=$FSQL_indent, extraIndent=$extraIndent, tmpStr=$tmpStr",3);
    }
    else { # just a normal character
      $tmpStr = $tmpStr . substr($SQLString,$pos,1);
      if ( $FSQL_lastToken_endofToken eq "Yes" ) { $FSQL_lastToken = substr($SQLString,$pos,1); }
      else { $FSQL_lastToken .= substr($SQLString,$pos,1); }
      $cntSinceLastCRLF++;
    }
  }
  return $tmpStr;
}

sub establishCursor {

  my $currTable = shift, $i, $j;
  my $card = shift;

  if ( $SKL_tabName[$SKL_currentTable] eq "XDOT" ) { # the statement contains the whole SQL statement
    $SKL_sqlStatement = $SKL_tabWhere[$SKL_currentTable];
  }
  elsif ( $SKL_tabWhere[$SKL_currentTable] eq "" ) { # the statement contains the table name only
    $SKL_sqlStatement = "select * from " . $SKL_tabName[$SKL_currentTable];
  }
  else {
    $SKL_sqlStatement = "select * from " . $SKL_tabName[$SKL_currentTable] . " where " . $SKL_tabWhere[$SKL_currentTable];
  }

  displayDebug("HERE 1>>>>>>$SKL_sqlStatement<<<<<<",2);

  $SKL_sqlStatement = substituteVariables($SKL_sqlStatement);

  displayDebug( "HERE 2>>>>>>$SKL_sqlStatement<<<<<<",2);

  displayDebug("Establishing Cursor for sql \'$SKL_sqlStatement\' for \'$SKL_connRef[$currTable]\'",2);

  # check to make sure the database connection has been opened

  for ($i=0; $i < $SKL_maxConnections; $i++ ) {
    if ( $SKL_connRef[$currTable] eq $SKL_connectionName[$i] ) {
      last;
    }
  }

  displayDebug("After database connection check: \$currTable=$currTable, \$i=$i",2);

  $SKL_connOK[$currTable] = "No";
  if ( $SKL_connRef[$currTable] ne $SKL_connectionName[$i] ) { # Database connection is not open
    displayError("Connection for database reference $SKL_connRef[$currTable] has not been established");
    return 0;
  }

  # generate cursor name (this will also be the name of the array holding the returned rows)

  $SKL_cursorRef[$currTable] = $SKL_imbedName[$SKL_currentImbed] . "_" . $card; # this holds the name of the cursor to be created

  setVariable('LASTSQL',$SKL_sqlStatement);

  if ( $SKL_sqlStatement =~ /\&\#92/ ) { # SQL Contains back slashes
    $SKL_sqlStatement =~ s/\&\#92/\\/g; # convert the back slashes to double backslashes
  }

  if ( $SKL_ShowSQL eq "Yes" ) {
    if ( $mode eq "STDOUT" ) {
      outputLine("SQL:$SKL_sqlStatement");
    }
    else {
      outputLine("SQL:$SKL_sqlStatement<BR><HR>");
    }
  }

  # prepare the statement
  $SKL_cursor{$SKL_cursorRef[$currTable]} = $SKL_connection[$i]->prepare($SKL_sqlStatement);
  if ( $SKL_cursor{$SKL_cursorRef[$currTable]}->errstr() ne "" ) { # An error occurred
    displayDebug("Prepare error returned: " . $SKL_cursor{$SKL_cursorRef[$currTable]}->errstr(),2);
    $SKL_endOfCursor = "Yes";
    return 0;
  }

  # turn on trace
  # DBI->trace( 2 );

  # execute the statement
  if ( $SKL_cursor{$SKL_cursorRef[$currTable]}->execute ) {
    # displayError("Cursor returned a non-zero return code during prepare");
  }
  else {
    displayError("Error returned: " . $SKL_cursor{$SKL_cursorRef[$currTable]}->errstr());
    $SKL_endOfCursor = "Yes";
    return 0;
  }

  $SKL_connOK[$currTable] = "Yes"; # indicate that the cursor has been opened successfully (doesn't mean that rows were returned)

  # retrieve the first row
  my $tArr = $SKL_cursorRef[$currTable];
  $SKL_cursor{$tArr}->{'LongTruncOk'} = 1;
  $SKL_cursor{$tArr}->{'LongReadLen'} = 20000;
  if ( @$tArr = $SKL_cursor{$tArr}->fetchrow_array ) { 
    $SKL_endOfCursor = "No";
    $SKL_rowNumber[$currTable]++;
  }
  else {
    displayDebug("Error string : $SKL_cursor{$SKL_cursorRef[$currTable]}->errstr()",2);
    print join(", ", @$tArr), "\n";
    displayDebug("test string : $$tArr[0]",2);
    #closeCursor($SKL_currentTable);
    $SKL_endOfCursor = "Yes";
  } 
  
  return 1;

}

sub establishFTABCursor {

  my $SKL_sqlStatement = shift, $i, $j;
  my $SKL_database = shift;

  displayDebug("FTAB HERE 1>>>>>>$SKL_sqlStatement<<<<<<",2);

  $SKL_sqlStatement = substituteVariables($SKL_sqlStatement);

  displayDebug( "FTAB HERE 2>>>>>>$SKL_sqlStatement<<<<<<",2);

  displayDebug("Establishing Cursor for sql \'$SKL_sqlStatement\' for \'$SKL_connRef[$currTable]\'",2);

  # check to make sure the database connection has been opened

  for ($i=0; $i < $SKL_maxConnections; $i++ ) {
    if ( $SKL_database eq $SKL_connectionName[$i] ) {
      last;
    }
  }

  displayDebug("After FTAB database connection check: \$currTable=$currTable, \$i=$i",2);

  if ( $SKL_database ne $SKL_connectionName[$i] ) { # Database connection is not open
    displayError("Connection for database reference $SKL_database has not been established");
    return 0;
  }

  # generate cursor name (this will also be the name of the array holding the returned rows)

  # $SKL_FTAB_cursorRef = 'FTAB_Cursor'; # this is the name of the cursor to be created

  setVariable('LASTSQL',$SKL_sqlStatement);

  if ( $SKL_sqlStatement =~ /\&\#92/ ) { # SQL Contains back slashes
    $SKL_sqlStatement =~ s/\&\#92/\\/g; # convert the back slashes to double backslashes
  }

  if ( $SKL_ShowSQL eq "Yes" ) {
    if ( $mode eq "STDOUT" ) {
      outputLine("SQL:$SKL_sqlStatement");
    }
    else {
      outputLine("SQL:$SKL_sqlStatement<BR><HR>");
    }
  }

  # prepare the statement
  $SKL_FTAB_cursor = $SKL_connection[$i]->prepare($SKL_sqlStatement);
  if ( $SKL_FTAB_cursor->errstr() ne "" ) { # An error occurred
    displayDebug("Prepare error returned: " . $SKL_FTAB_cursor->errstr(),2);
    return 0;
  }

  $SKL_FTAB_rowNumber = 0;
  # turn on trace
  # DBI->trace( 2 );

  # execute the statement
  if ( $SKL_FTAB_cursor->execute ) {
    # displayError("Cursor returned a non-zero return code during prepare"); # so all ok (as it is returning a pointer to data)
  }
  else {
    displayError("FTAB Error returned: " . $SKL_FTAB_cursor->errstr());
    return 0;
  }

  # retrieve the first row
  $SKL_FTAB_cursor->{'LongTruncOk'} = 1;
  $SKL_FTAB_cursor->{'LongReadLen'} = 20000;

  if ( @SKL_FTAB_Cols = $SKL_FTAB_cursor->fetchrow_array ) {
    $SKL_FTAB_rowNumber++;
  }
  else {
    $SKL_tmp = $SKL_FTAB_cursor->errstr();
    displayDebug("FTAB Error string : $SKL_tmp",2);
    # closeCursor($SKL_FTAB_cursor); # if an error the cursor probably already closed
  }

  return 1;

}

sub closeCursor {
  my $currTable = shift, $i, $j;
  displayDebug("Closing Cursor $currTable",2);
  $SKL_cursor{$SKL_cursorRef[$currTable]}->finish(); # not really needed but tidier
  undef $SKL_cursor{$SKL_cursorRef[$currTable]}; # undefine the cursor

  # NOTE: this does not close the connection - just loses the SQL statement results 
 
} 

sub closeFTABCursor {
  displayDebug("Closing FTAB Cursor",2);
  $SKL_FTAB_cursor->finish(); # not really needed but tidier

  # NOTE: this does not close the connection - just loses the SQL statement results
}

sub getNextRecord {

  # read in the next row from the indicated cursor
  my $cursorName = shift; 
  my $currTable = shift;

  if ( @$cursorName = $SKL_cursor{$cursorName}->fetchrow_array ) { 
    $SKL_endOfCursor = "No";
    $SKL_rowNumber[$currTable]++;
    return 1; # data returned
  }
  else {
    $SKL_endOfCursor = "Yes";
    return 0; # end of cursor
  }
}

sub getNextFTABRecord {

  # read in the next row from the FTAB cursor

  if ( @SKL_FTAB_Cols = $SKL_FTAB_cursor->fetchrow_array ) {
    $SKL_FTAB_rowNumber++;
    displayDebug("Row returned",2);
    return 1; # data returned
  }
  else {
    displayDebug("No Data",2);
    return 0; # end of cursor
  }
}

sub getToken {
  # return the next space delimited token from the supplied parameter
  my $tLine = shift;
  my $tTok = "";
  displayDebug("Line: $tLine Start Pos: $SKL_cPos",2);
  # Skip whitespace
  while ( ($SKL_cPos <= length($tLine) ) && (substr($tLine,$SKL_cPos,1) eq " ") ) { 
    $SKL_cPos++;
  }
  # Set token value
  my $testToken = " ";
  if ( (substr($tLine,$SKL_cPos,1) eq "\'" ) || (substr($tLine,$SKL_cPos,1) eq "\"" ) ) { # it starts with a quote
    $testToken = substr($tLine,$SKL_cPos,1);
    $SKL_cPos++; # skip the first quote
  }
  displayDebug("Terminating character has been set as >$testToken<",2);
  while ( ($SKL_cPos <= length($tLine) ) && (substr($tLine,$SKL_cPos,1) ne $testToken) ) { 
    $tTok = $tTok . substr($tLine,$SKL_cPos,1);
    $SKL_cPos++;
  }
  displayDebug("Token returned was $tTok",2);
  $SKL_cPos++;
  return $tTok;
}

sub getDate {
  my $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings, $year;
  ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  $year = 1900 + $yearOffset;
  $month = $month + 1;
  $month = substr("0" . $month, length($month)-1,2);
  $day = substr("0" . $dayOfMonth, length($dayOfMonth)-1,2);
  return "$year.$month.$day";
}

sub getTime {
  my $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings, $year;
  ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  $hour = substr("0" . $hour, length($hour)-1,2);
  $minute = substr("0" . $minute, length($minute)-1,2);
  $second = substr("0" . $second, length($second)-1,2);
  return "$hour:$minute:$second"
}


sub displayStatus {

  # Display a passed message with timestamp if the SKL_statusLevel has been set

  if ( $SKL_statusLevel > 0 ) {
    my $tDate = getDate;
    my $tTime = getTime;

    if ( $#_ == -1) { # Nothing to display so just display the date and time 
      print STDERR "$tDate $tTime\n";
    }
    else {
      print STDERR "$tDate $tTime : $_[0]\n";
    }
  }

}

sub displayError {

  # Display a passed message with timestamp at all times

  my $tDate = getDate;
  my $tTime = getTime;

  if ( $#_ == -1) { # Nothing to display so just display the date and time
    print STDERR "$tDate $tTime\n";
  }
  else {
    print STDERR "$tDate $tTime : $_[0]\n";
  }

}

sub displayDebug {

  my $lit = shift;
  my $SKL_call_debugLevel = shift;

  # Display a passed message with timestamp if the SKL_debugLevel has been set

  if ( $SKL_call_debugLevel <= $SKL_debugLevel ) {
    my $tDate = getDate;
    my $tTime = getTime;

    if ( $lit eq "") { # Nothing to display so just display the date and time
      print STDERR "$tDate $tTime\n";
    }
    else {
      print STDERR "$tDate $tTime : $lit\n";
    }
  }

}

sub outputLine {

  my $line = shift;

  $SKL_outputLineCount++;

  if ( $mode eq "STDOUT" ) {
    if ( $SKL_debuglevel > 0 ) { # While debugging number the lines
      print "$SKL_outputLineCount: $line\n";
    }
    else {
      print "$line\n";
    }
  }
  elsif ( $mode eq "HTTPFILE" ) {
    $SKL_returnString .= "\n$line"
  }
  else {
    # dont do it for the first line ....
    if ( $SKL_outputLineCount == 1 ) {
      $SKL_returnString .= "$line"
    }
    else {
      $SKL_returnString .= "\n$line"
    }
  }

}

sub getFTABLong {
  my $colNum  = shift; # column number in cursor
  $colNum++; # Adjust column position

  my $offset = 0;
  my $buff = "";
  my $colValue = "";

  displayDebug("Starting to process long column $colNum",2);

  while ( $buff = $SKL_FTAB_cursor->blob_read( $colNum, $offset, 10000 )) {
    $colValue .= $buff;
    $offset += length($buff);
    $buff = "";
    displayDebug("value = " . $colValue,2);
  }

#  $colValue = $SKL_FTAB_Cols[$colNum];

  return $colValue;

}

sub getLong {
  my $csrREF  = shift; # cursor literal be read from
  my $colNum  = shift; # column number in cursor
  $colNum++; # Adjust column position

  my $offset = 0;
  my $buff = "";
  my $colValue = "";

  displayDebug("Starting to process long column",2);

  while ( $buff = $SKL_cursor{$csrREF}->blob_read( $colNum, $offset, 10000 )) {
    $colValue .= $buff;
    $offset += length($buff);
    $buff = "";
    displayDebug("value = " . $colValue,2);
  }

#  $colValue = $$csrREF[$colNum];

  return $colValue;

}


sub substituteVariables {
  my $tempLine = shift;
  my $tLine, $cPos, $tRef, $i , $j, $fldStart;
  my $fldEnd;
  # Subroutine to substitute variables
  #
  # A variable looks like <cursorRef>.:<fieldName>
  #
  $tLine = $tempLine;

  if ( $tempLine =~ /:/ ) { # there is a chance that a variable needs substituting
    displayDebug("Variables to replace in: \n$tempLine\n0....+....1....+....2....+....3....+....4....+....5....+....6....+....7....+....8....+....9....+....0....+....1....+....2....+....3....+....4....+....5",1);
    $tLine = "";
    $cPos = 0;
    $leftEdge = 0;
    $fldStart = 0 ;
    while ( ($cPos > -1 ) && ( $cPos < length($tempLine) )) {
      $tRef = "";
      $i = index($tempLine,':',$leftEdge);
      $cPos = $i + 1;
      # check if there is a cursor reference
      $fldStart = $i ;
      displayDebug("(at start) \$i=$i",2);
      if ( $i > 1 ) {
        if ( substr($tempLine,$i-1,1) eq '.' ) { # so we have a .: in the middle of the string
          displayDebug("\$i: $i" . ",char=" . substr($tempLine,$i-1,1),2);
          # loop backwards to find the cursor name until you come across a termination char
          $i = $i -2;
          displayDebug("termChar=$SKL_termChar, cmpChar=" . substr($tempLine, $i, 1) . ", \$i=$i",2);
          while ( index( $SKL_termChar, substr($tempLine, $i, 1) ) == -1 ) { # While character is not a termination character
            $tRef = substr($tempLine, $i, 1) . $tRef; # add the character to the from of the cursor name
            $i = $i - 1;
            displayDebug("tRef=$tRef, termChar=$SKL_termChar, cmpChar=" . substr($tempLine, $i, 1) . ", \$i=$i",2);
            if ( $i == -1 ) { last; } # stop of you get to the front of the line
          } 
          if ( $tRef ne "" ) { $fldStart = $i + 1; }
        }
      }
      # $tRef now contains the name of the cursor
      displayDebug("Cursor is:$tRef, fldStart=$fldStart, \$i=$i",2);
      my $varName = "";
      # now identify the variable name we are looking for
      my $tIndex = index( $SKL_termChar, substr($tempLine, $cPos, 1));
      my $tSubstr = substr($tempLine, $cPos, 1);
      displayDebug("termChar=$SKL_termChar, cmpChar=" . substr($tempLine, $cPos, 1),2);
      while ( ($cPos > -1 ) && (index( $SKL_termChar, substr($tempLine, $cPos, 1) ) == -1 ) ) {
        $varName = $varName . substr($tempLine, $cPos, 1);
        $cPos++;
        displayDebug("varName= $varName, termChar=$SKL_termChar, cmpChar=" . substr($tempLine, $cPos, 1),2);
      }
      displayDebug("Variable: $varName",1);
      if ( $varName eq "" ) { # no variable name so just a colon
        $tLine = $tLine . substr($tempLine, $leftEdge, $fldStart - $leftEdge + 1);
        $leftEdge = $cPos;
        displayDebug("\$leftEdge=$leftEdge, \$cPos=$cPos, \$tLine=$tLine",2);
        if ( index($tempLine,':',$leftEdge) == -1 ) { # no more colons in the string
          $cPos = -1;
          $tLine = $tLine . substr($tempLine, $fldStart+1);
          displayDebug("cPos set to -1",2);
        }
        next;
      }
      else {
        if ( substr($tempLine, $cPos, 1) eq '.' ) { $cPos++; } # skip periods terminating variables
      }
      $fldEnd = $cPos -1;

      $SKL_checkCursor = -1;
      # At this point $tRef contains cursor and $varName contains variable
      $WEB_Conv = "No";
      if ( substr($varName,0,7) eq "WEBCNV_" ) {
        $WEB_Conv = "Yes";
        $varName = substr($varName,7);
      }

      if ( $tRef eq "" ) { # no cursor was supplied - check against last cursor
        $SKL_checkCursor = $SKL_currentTable;
      }
      else { # check against the indicated cursor
        # check to see if one exists .....
        for ( $j=0; $j< $SKL_maxTables; $j++ ) {
          displayDebug("Checking $tRef against the currently established cursors: $SKL_tabRef[$j]",2);
          if ( uc($SKL_tabRef[$j]) eq uc($tRef) ) { # check if the name is known ...
            displayDebug("cursor $tRef found at $j",2);
            last;
          }
        }
        displayDebug(">>>>COMPARISON: SKL_tabRef[\$j])=" . uc($SKL_tabRef[$j]) . ", tRef=" . uc($tRef),2);
        if ( uc($SKL_tabRef[$j]) eq uc($tRef) ) { 
          displayDebug("Cursor $tRef found at $j in \$SKL_tabRef[$j]",2);
	  $SKL_checkCursor = $j;
	}
	else { # a reference was made but no cursor was found ....
	  # so dont replace the reference 
          $fldStart = $fldStart + length($tRef) +1;
	  $tRef = "";
	  $SKL_checkCursor = $SKL_currentTable;
        }
      }	
      # At this point the cursor has been identified (if it exists) ...
      $SKL_fieldFound = "No";
      # NOTE: These variables are ALWAYS case insensitive
      if ( $tRef eq "" ) { # no cursor supplied so check if it is a system or skeleton variable
        if ( uc($varName) eq "SYSDATE" ) { 
          $SKL_fieldFound = "Yes";
	   $SKL_tabValue = getDate;
	}
	elsif ( uc($varName) eq "SYSTIME" ) {
	   $SKL_fieldFound = "Yes";
	   $SKL_tabValue = getTime;
	}
	elsif ( uc($varName) eq "SKELETON" ) {
	   $SKL_fieldFound = "Yes";
	   $SKL_tabValue = $SKL_imbedName[$SKL_currentImbed];
	}
	# If still not found then check for a skeleton variable
	if ( $SKL_fieldFound eq "No" ) {
	  if ( defined($SKL_varArray{$varName}) ) { 
            $SKL_fieldFound = "Yes";		  
            $SKL_tabValue = $SKL_varArray{$varName}; 
          }
        }
      }
      # now we obey the case sensitive flag
      if ( $SKL_caseSensitiveColumns eq "No" ) {
        $varName = uc($varName);
      }

      # if still not found then check the previously identified cursor
      if ( $SKL_fieldFound eq "No" ) {
        if ( uc($varName) eq "ROWCNT" ) { # Special variable row count
          $SKL_tabValue = $SKL_rowNumber[$SKL_checkCursor];
          displayDebug("rowcnt=$SKL_tabValue",2);
          $SKL_fieldFound = "Yes";
        }
        else { # check the cursor to see if the column exists there
          # $SKL_cursorRef[$SKL_checkCursor] - this variable holds the generated array name holding the data
          # do the cursor stuff
          my $tArr = $SKL_cursorRef[$SKL_checkCursor];
          my $numCols = $SKL_cursor{$tArr}->{NUM_OF_FIELDS}; # this does a describe
          displayDebug("numCols=$numCols",2);
          for ($j=0; $j<=$numCols; $j++) { 
            displayDebug("Field Check: Checking >$varName< against >$SKL_cursor{$tArr}->{NAME}->[$j]<",2);
            if ( $SKL_caseSensitiveColumns eq "No" ) { # Case INSENSITIVE
              if ( uc($SKL_cursor{$tArr}->{NAME}->[$j]) eq $varName ) {
                $SKL_fieldFound = "Yes";
                last;
              }
            }
            else {  # Case SENSITIVE
              if ( $SKL_cursor{$tArr}->{NAME}->[$j] eq $varName ) {
                $SKL_fieldFound = "Yes";
                last;
              }
            }
            displayDebug("Column " . $SKL_cursor{$tArr}->{NAME}->[$j] . " not used as looking for $varName",2);
          }
          if ( $SKL_fieldFound eq "Yes" )  { # match found (the $j'th element in the returned array)
            displayDebug("Column " . $SKL_cursor{$tArr}->{NAME}->[$j] . " found",2);
            my $fieldType = $SKL_cursor{$tArr}->{TYPE}->[$j]; # $k is now the field type (CHAR, VARCHAR etc)
            # SQL_CHAR             1
            # SQL_NUMERIC          2
            # SQL_DECIMAL          3
            # SQL_INTEGER          4
            # SQL_SMALLINT         5
            # SQL_FLOAT            6
            # SQL_REAL             7
            # SQL_DOUBLE           8
            # SQL_DATE             9
            # SQL_TIME            10
            # SQL_TIMESTAMP       11
            # SQL_VARCHAR         12
            # SQL_LONGVARCHAR     -1
            # SQL_BINARY          -2
            # SQL_VARBINARY       -3
            # SQL_LONGVARBINARY   -4
            # SQL_BIGINT          -5
            # SQL_TINYINT         -6
            # SQL_BIT             -7
            # SQL_WCHAR           -8
            # SQL_WVARCHAR        -9
            # SQL_WLONGVARCHAR   -10
            $SKL_tabValue = "";
            if ( ($fieldType == -1) || ($fieldType == -4) || ($fieldType == -10) ) { # long field
              if ( defined($$tArr[$j]) ) {
                displayDebug("Long array field is defined",2);
                $SKL_tabValue = $$tArr[$j];
              }
              else { # the field needs to be retrieved
                $SKL_tabValue = getLong($tArr, $j, $varName);
                $$tArr[$j] = $SKL_tabValue;
              }
              #$SKL_tabValue = trim($$tArr[$j]);
            }
            else { # no special processing needs to be done
              if ( defined($$tArr[$j]) ) { # variable is not null
                if ( ( $fieldType == 1 ) || ( $fieldType == 12 ) || ( $fieldType == -8 ) || ( $fieldType == -9 )) { #
                  $SKL_tabValue = trim($$tArr[$j]);
                }
                else {
                  $SKL_tabValue = $$tArr[$j];
                }
              }
              else {
                $SKL_tabValue = "NULL";
              }
            }
          }
          else {
            $SKL_fieldFound = "No";
            displayDebug("Field not found in cursor",2);
          }
        }
      }
      # if still not found then recreate the entry
      if ( $SKL_fieldFound eq "No" ) {
        if ( $WEB_Conv eq "Yes" ) { # put it all back together again ....
          $WEB_Conv = "No";
          $varName = "WEBCNV_$varName";
        }

	if ( $tRef eq "" ) {
	 $SKL_tabValue = "\:$varName";
	}
	else {
	 $SKL_tabValue = "$tRef\.\:$varName";
	}
      }

      if ( $WEB_Conv eq "Yes" ) { # do the required conversions ......
        # $SKL_tabValue =~ s/#/%23/g;  # Convert # to %23 -- CANT get this to work!
        $SKL_tabValue =~ s/#/\%/g;  # Convert # to % - followup script will work with % instead 
      }
      
      # insert the variable into the line
      displayDebug("tLine=$tLine, tempLine=$tempLine, leftEdge=$leftEdge, fldStart=$fldStart, substr=" . substr($tempLine, $leftEdge, $fldStart - $leftEdge) . ", tabValue=>" . $SKL_tabValue . "<",2);
      $tLine = $tLine . substr($tempLine, $leftEdge, $fldStart - $leftEdge) . $SKL_tabValue;
      $leftEdge = $fldEnd + 1; 
      # check to see if there are any more variables to process
      if ( index($tempLine, ':', $leftEdge) == -1 ) { # no more variables
        displayDebug("AGAIN >>>>>>>$tempLine<<<<<<<<<<",2);
        displayDebug("AGAIN >>>>>>>$leftEdge<<<<<<<<<<",2);
        displayDebug("AGAIN >>>>>>>$tLine<<<<<<<<<<",2);
        $a = substr($tempLine, $leftEdge);
        displayDebug("AGAIN >>>>>>>$a<<<<<<<<<<",2);
        $tLine = $tLine . substr($tempLine, $leftEdge);
        $cPos = length($tempLine) + 1;
        last;
      }
    }
  }

  if ( $tLine eq "" ) {
    return "NULL";
  }
  else {
    return $tLine;
  }

}

sub space {
  # returns a string of a a specified length filled with an optional character.
  # If no character is specified then it is space filled
  my $spcCount = shift;
  my $retStr = "";

  my $fill = " ";

  if ( $#_ > 0 ) { # take the next parameter and use it as the fill
    $fill = substr($_[1],0,1);
  }

  for ( $spcCount ; $spcCount > 0 ; $spcCount-- ) { $retStr = $retStr . $fill; }

  return $retStr;

}

sub putInTabs {
  my $tLine = shift;
  my $i, $iPos, $jPos, $kPos, $pad;

  # note a ! will space fill to the next tab stop
  #      a ~ will get the next token and right justify it to the next tab stop

  if ( $SKL_maxTabEntries >= 0 ) { # tabs have been defined
    displayDebug("Adjusting tabs",1);
    $iPos = index($tLine, '!') ;
    $jPos = index($tLine, '~') ;
    displayDebug("! Pos: $iPos, ~ Pos: $jPos, Line: $tLine",2);

    while ( $iPos + $jPos > -2 ) {
      if ( (( $iPos < $jPos ) && ( $iPos > -1 )) || ( $jPos == -1 ) ) { # ! to process next
	$pad = "";
	# look for the tab stop that applies
	displayDebug("SKL_maxTabEntries=$SKL_maxTabEntries",2);
	for ( $i=0; $i <= $SKL_maxTabEntries; $i++ ) {
	  displayDebug("SKL_tabArray[$i]=$SKL_tabArray[$i],iPos=$iPos",2);
	  if ( $SKL_tabArray[$i] >= $iPos ) { # found the tab marker
            displayDebug("Tab stop found is $SKL_tabArray[$i], iPos: $iPos",2);
	    if ( $iPos == 0 ) { # special case
              $pad = space($SKL_tabArray[$i] - $iPos);
	    }
	    else {
              $pad = space($SKL_tabArray[$i] - $iPos + 1);
	    }
	    last;
	  }
	}	
	# replace the tab
	if ( $iPos == 0 ) {
	  $tLine = $pad . substr($tLine, $iPos + 1);
	}
	else {
	  $tLine = substr($tLine, 0, $iPos - 1) . $pad . substr($tLine, $iPos + 1);
        }  
	$iPos = index($tLine, '!') ;
	$jPos = index($tLine, '~') ;
        displayDebug("! Pos: $iPos, ~ Pos: $jPos, Line: $tLine",2);
      }
      else { # ~ must be next to process
	$pad = "";
	$kPos = $jPos + 1;
        # find the end of the token
	while ( index($SKL_termChar, substr($tLine,$kPos,1)) == -1 ) { $kPos++; } 
	$kPos--;
	# now find the tab stop that applies
	for ( $i; $i <= $SKL_maxTabEntries; $i++ ) {
	  if ( $SKL_tabArray[$i] >= $jPos ) { # found the tab marker
	    if ( $jPos == 0 ) { # special case
              $pad = space($SKL_tabArray[$i] - $kPos);
            }
            else {  
              $pad = space($SKL_tabArray[$i] - $kPos + 1);
            }  
	    last;
	  }
	}
	if ( $jPos == 0 ) {
	  $tLine = $pad . substr($tLine, $jPos + 1);
	}
	else {
	  $tLine = substr($tLine, 0, $jPos - 1) . $pad . substr($tLine, $jPos + 1);
	}
	$iPos = index($tLine, '!') ;
	$jPos = index($tLine, '~') ;
        displayDebug("! Pos: $iPos, ~ Pos: $jPos, Line: $tLine",2);
      }
    }
  }
  return $tLine;

}

sub isNumeric {
  # check if a variable is numeric
  my $var = shift;

  if ($var =~ /\D/)             { return 0; }
  if ( $SKL_debugLevel > 0) { print  STDERR "May be Digits\n"; }
  if ($var =~ /^\d+\z/)         { return 1; }
  if ( $SKL_debugLevel > 0) { print  STDERR "Not Only Digits\n"; }
  if ($var =~ /^-?\d+\z/)       { return 1; }
  if ( $SKL_debugLevel > 0) { print  STDERR "Doesn't have a leading minus\n"; }
  if ($var =~ /^[+-]?\d+\z/)    { return 1; }
  if ( $SKL_debugLevel > 0) { print  STDERR "Only Digits\n"; }
  if ($var =~ /^-?\d+\.?\d*\z/) { return 1; }
  if ( $SKL_debugLevel > 0) { print  STDERR "Only Digits\n"; }
  if ($var =~ /^-?(?:\d+(?:\.\d*)?&\.\d+)\z/) { return 1; }
  if ( $SKL_debugLevel > 0) { print  STDERR "Only Digits\n" ; }
  if ($var =~ /^([+-]?)(?=\d&\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\z/) { return 1; }
  if ( $SKL_debugLevel > 0) { print  STDERR "Not numeric\n"; }
  
  return 0;

}

sub evaluateSingleCondition {
  # Evaluate a simple condition
  my $condStr = shift;
  my $val1, $val2, $op;


  displayDebug("passed Condition is $condStr",2);
  $SKL_cPos = 0;
  $val1 = getToken($condStr);
  $val1 = substituteVariables($val1);
  displayDebug("Adjusted val1 is $val1",2);
  if ( $SKL_cPos > length($condStr) ) { # at end of card
    if ( $val1 eq "0" ) { return "False" ; } 
    else { return "True" ; }
  }
  # process the next parameter (should be an operator)
  $op = getToken($condStr);
  $op = substituteVariables($op);
  displayDebug("Adjusted op is $op",2);
  if ( $SKL_cPos > length($condStr) ) { # at end of card
    displayError("Having trouble evaluating $condStr will assume FALSE");
    return "False";
  }
  $val2 = trim(substr($condStr,$SKL_cPos));
  if ( uc($val2) eq ":SPACE_FILL" ) { 
    $val2 = space(length($val1));
  }
  else {
    $val2 = substituteVariables($val2);
  }
  displayDebug("Adjusted val2 is $val2",2);

  if ( uc($op) eq "CONTAINS" ) {
    displayDebug("Contains found - checking if $val2 exists in >$val1<",2);
    if ( $val1 =~ /$val2/ ) { return "True"; }
    else { return "False"; }
  }
  elsif ( isNumeric($val1) && isNumeric($val2) ) { # do comparisons as numbers ....
    displayDebug("Numeric comparison",2);
    if    ( $op eq "="  ) { if ( $val1 == $val2 ) { return "True"; } }
    elsif ( $op eq "<>" ) { if ( $val1 != $val2 ) { return "True"; } }
    elsif ( $op eq "<=" ) { if ( $val1 <= $val2 ) { return "True"; } }
    elsif ( $op eq ">=" ) { if ( $val1 >= $val2 ) { return "True"; } }
    elsif ( $op eq ">"  ) { if ( $val1 >  $val2 ) { return "True"; } }
    elsif ( $op eq "<"  ) { if ( $val1 <  $val2 ) { return "True"; } }
    else  { displayError("Unknown operator '$op' in condition ($condStr)"); }
  }
  else { # treat as character
    displayDebug("Character comparison",2);
    if    ( $op eq "="  ) { if ( $val1 eq $val2 ) { return "True"; } }
    elsif ( $op eq "<>" ) { if ( $val1 ne $val2 ) { return "True"; } }
    elsif ( $op eq "<=" ) { if ( $val1 le $val2 ) { return "True"; } }
    elsif ( $op eq ">=" ) { if ( $val1 ge $val2 ) { return "True"; } }
    elsif ( $op eq ">"  ) { if ( $val1 gt $val2 ) { return "True"; } }
    elsif ( $op eq "<"  ) { if ( $val1 lt $val2 ) { return "True"; } }
    else  { displayError("Unknown operator '$op' in condition ($condStr)"); }
  }
  return "False"; # default to false
}

sub evaluateCondition {
  # return a value of 0 "True" or "False" depending on the passed parameters

  my $evalStr = shift;
  my @condArray = ();
  my $conditionCount = -1;
  my $x = 0;
  my $sPos = 0;
  my $x1 = index(uc($evalStr)," OR ",$x);
  my $x2 = index(uc($evalStr)," AND ",$x);
  my $nextCond = "    ";

  displayDebug("Looking for OR or AND : x1 = $x1 and x2 = $x2",2);

  if ( $x1 + $x2 == -2 ) { # no ANDs or ORs
    $conditionCount++;
    $condArray[$conditionCount] = $evalStr;
  }
  else {
    # Gather the conditions ..
    while ( ($x1 > -1 ) || ($x2 > -1 ) ) { # count the OR and ANDs in the )SEL
      $conditionCount++;
      if ( $x1 == -1 ) { $x1 = length($evalStr); }
      if ( $x2 == -1 ) { $x2 = length($evalStr); }
  
      if ( $x2 < $x1) { 
        $condArray[$conditionCount] = $nextCond . substr($evalStr,$sPos,$x2 - $sPos + 1);
        $nextCond = "AND ";
        $x = $x2 + 5 ; 
      }
      else { 
        $condArray[$conditionCount] = $nextCond . substr($evalStr,$sPos,$x1 - $sPos + 1);
        $nextCond = "OR  ";
        $x = $x1 + 4 ; 
      } 
      $sPos = $x;

      $x1 = index(uc($evalStr)," OR ",$x);
      $x2 = index(uc($evalStr)," AND ",$x);
    }
  }

  # now we know how many comparisons need to be done
  
  my $runningCond = "False";
  for ( my $nCond = 0 ; $nCond <= $conditionCount; $nCond++ ) { # for each testA
    displayDebug("Conditon $nCond is: $condArray[$nCond]",2);
    my $eval = evaluateSingleCondition( $condArray[$nCond] ) ;
    displayDebug("evaluateluate returned returned $eval",2);
    displayDebug("condArray\[\$nCond\]=$condArray[$nCond]",2);
    if ( substr($condArray[$nCond],0,3) eq "OR " ) {
      if ( $eval eq "True" ) { # any OR condition that returns true means the whole SEL is true
        displayDebug("exiting via path 1",2);
	return "True";  
      }
      elsif ( $runningCond eq "True" ) { #
        displayDebug("exiting via path 2",2);
	return "True";
      }
    }  
    elsif ( substr($condArray[$nCond],0,3) eq "AND" ) {
      displayDebug("AND: \$eval=$eval, \$runningCond=$runningCond",2);
      if ( ($eval eq "False") or ($runningCond eq "False") ) { # any AND that has False to the left or 
	                                                       # evaluates False means the SEL is false
        displayDebug("exiting via path 3",2);
	return "False";
      }
    }  
    else { # should only be selected for the first condition
      displayDebug("runningCond set to $eval",2);
      $runningCond = $eval;
    }
  }
  displayDebug("exiting via path 4",2);
  return $runningCond;
}

sub processFunction {
  # Subroutine to provide a number of functions for se in
  # skeletons
  #
  my $function = shift;
  my $funcParms = shift;

  displayDebug("Function $function will process the following parms: $funcParms",1);

  if ( uc($function) eq "INT" ) { # INT function
    return int($funcParms);
  }
  elsif ( uc($function) eq "TRIM" ) { # TRIM function
    return trim($funcParms);
  }
  elsif ( uc($function) eq "LTRIM" ) { # Left TRIM function
    return ltrim($funcParms);
  }
  elsif ( uc($function) eq "RTRIM" ) { # Right TRIM function
    return rtrim($funcParms);
  }
  elsif ( uc($function) eq "LEN" ) { # length function
    return length($funcParms);
  }
  elsif ( uc($function) eq "LEN" ) { # length function
    return length($funcParms);
  }
  elsif ( uc($function) eq "INSTR" ) { # instr function
    $funcParms = trim($funcParms);
    my $i = index($funcParms,' '); # first space delimits parameters
    if ( $i == -1 ) {
      displayError("INSTR function format is:\n)FUNC INSTR xxx = <search string> <string>\nNote: the first space delimits arguments - Function will return -1");
      return -1;
    }
    my $p1Str = substr($funcParms, 0, $i);
    my $p2Str = substr($funcParms, $i + 1);

    displayDebug("i=$i, p1Str=$p1Str, p2Str=$p2Str, index is " . index($p2Str,$p1Str),2 );

    if ( $p1Str =~ /^SPC\d*.*/ ) { # convert to a space filled string of length xxx where xxx is a literal of the form SPCxxx
      my ($numSpaces) = ( $p1Str =~ /^SPC(\d*)[^\d]*/ ) ;
      displayDebug("$numSpaces space has been requested",2);
      $p1Str = space($numSpaces);
    }
    displayDebug("i=$i, p1Str=$p1Str, p2Str=$p2Str, index is " . index($p2Str,$p1Str),2 );

    return index($p2Str,$p1Str);
  }
  elsif ( uc($function) eq "LEFT" ) { # left function
    $funcParms = trim($funcParms);
    my $i = index($funcParms,' '); # first space delimits parameters
    if ( $i == -1 ) {
      displayError("LEFT function format is:\n)FUNC LEFT xxx = <number Of Characters> <string>\nNote: the first space delimits arguments - Function will return -1");
      return -1;
    }
    my $p1Str = substr($funcParms, 0, $i);
    my $p2Str = substr($funcParms, $i + 1);

    displayDebug("i=$i, p1Str=$p1Str, p2Str=$p2Str, left is " . substr($p2Str,0,$p1Str),2 );

    return substr($p2Str,0,$p1Str);
  }
  elsif ( uc($function) eq "RIGHT" ) { # right function
    $funcParms = trim($funcParms);
    my $i = index($funcParms,' '); # first space delimits parameters
    if ( $i == -1 ) {
      displayError("RIGHT function format is:\n)FUNC RIGHT xxx = <number Of Characters> <string>\nNote: the first space delimits arguments - Function will return -1");
      return -1;
    }
    my $p1Str = substr($funcParms, 0, $i); 
    my $p2Str = substr($funcParms, $i + 1);

    displayDebug("i=$i, p1Str=$p1Str, p2Str=$p2Str, left is " . substr($p2Str,($p1Str*-1),$p1Str),2 );

    return substr($p2Str,($p1Str*-1),$p1Str);0
  }
  elsif ( uc($function) eq "MID" ) { # right function
    $funcParms = trim($funcParms);
    my $i = index($funcParms,' '); # first space delimits parameters
    if ( $i == -1 ) {
      displayError("RIGHT function format is:\n)FUNC MID xxx = <start character>[,<length>] <string>\nNote: the second space delimits arguments - Function will return -1");
      return -1;
    }
    my $p1Str = substr($funcParms, 0, $i); 
    my $pLen = "";
    if ( $p1Str =~ /,/ ) { # it contains a comma and so there should be a length parm supplied as well
      my $j = index($p1Str, ",") ;
      $pLen = substr($p1Str,$j+1); 
      $p1Str = substr($p1Str,0,$j-1);
    }
    my $p2Str = substr($funcParms, $i + 1);

    if ( $pLen eq "" ) { # no length specified ...
      displayDebug("i=$i, p1Str=$p1Str, pLen=$pLen, p2Str=$p2Str, mid is " . substr($p2Str,$p1Str),2 );
      return substr($p2Str,$p1Str);
    }
    else { # apply the length parameter
      displayDebug("i=$i, p1Str=$p1Str, pLen=$pLen, p2Str=$p2Str, mid is " . substr($p2Str,$p1Str,$pLen),2 );
      return substr($p2Str,$p1Str,$pLen);
    }
  }
  elsif ( uc($function) eq "REMOVECRLF") { # remove CRLFs from the supplied string
    $funcParms = trim($funcParms);
    return removeCRLF($funcParms);
  }
  elsif ( uc($function) eq "REMOVEWHITESPACE") { # remove unnecessary whitespace from the supplied string
    $funcParms = trim($funcParms);
    return removeUnnecessaryWhiteSpace($funcParms);
  }
  elsif ( uc($function) eq "FORMATSQL") { # format the supplied string as SQL
    $funcParms = trim($funcParms);
    $funcParms = substituteVariables($funcParms);
    return formatSQL($funcParms);
  }

  return "";

}

sub readDataFileRecord {
  my $fh = shift;
  my $txt = <$fh>;
  chomp $txt;
  return $txt;
}

sub processControlCard {
  my $card = shift; # index into the current skeleton
  my $tempLine, $tmpTok, $i , $dispVar, $j;

  $SKL_cPos = 0;
  my $SKL_cardType = uc(getToken($$SKL_arrName[$card]));
  displayDebug("Control token: $SKL_cardType",1);

  if ( $SKL_cardType eq ")TB" ) {
    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      $tmpTok = getToken($$SKL_arrName[$card]);
      displayDebug("Token: $tmpTok",1);
      $i = 0;
      if ( $tmpTok ne "" ) {
        while ( $tmpTok ne "" ) { # loop through the )TB parms
          $SKL_tabArray[$i] = $tmpTok-1; # load them in less one to align them toi a start of 0
	  $i++;
	  $tmpTok = getToken($$SKL_arrName[$card]);
	}
      }
      $SKL_maxTabEntries = $i - 1;
      for ( $i = 0 ; $i <= $SKL_maxTabEntries ; $i ++ ) { displayDebug("Tab $i: $SKL_tabArray[$i]",1); }
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]",2);
    }
  }
  elsif ( $SKL_cardType eq ")RULER" ) {
    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      outputLine("....+....1....+....2....+....3....+....4....+....5....+....6....+....7....+....8....+....9....+....0....+....1....+....2....+....3....+....4....+....5");
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]",2);
    }
  }
  elsif ( $SKL_cardType eq ")SET" ) {
    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      my $varName = getToken($$SKL_arrName[$card]);
      my $varOp = getToken($$SKL_arrName[$card]);
      if ( $varOp ne "=" ) { 
	displayError("Operator for )SET must be '='. Operator found was $varOp");
	return;
      }
      displayDebug("\)SET string is " . substr($$SKL_arrName[$card],$SKL_cPos),1);
      my $varValue = evaluateInfix(substituteVariables(trim(substr($$SKL_arrName[$card],$SKL_cPos))));
      displayDebug("Result is = $varValue",1);
      setVariable($varName,$varValue);
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
    }
  }
  elsif ( $SKL_cardType eq ")LOGOFF" ) { # Close a connection to a database - of the form )LOGOFF DBLit
    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      my $DBConnection = getToken($$SKL_arrName[$card]); # Literal that defines the connection to close
      for ( $j=0; $j < $SKL_maxConnections; $j++) { # search for the connection
        if ( $SKL_connectionName[$j] eq $DBConnection ) { # found the slot
          last;
        }
      }
      if ( $SKL_connectionName[$j] ne $DBConnection ) { #  Connection not found
        displayError("Connection $DBConnection not found so )LOGOFF card ignored");
        return;
      }
      # Connection $j should be closed
      $SKL_connection[$j]=>disconnect; # Close the connection
      $SKL_connectionInUse[$j] = "No"; # Mark the slot as free
      $SKL_connectionName[$j] = "";
      displayDebug("Connection $DBConnection has now been closed",2);
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
    }
  }
  elsif ( $SKL_cardType eq ")LOGON" ) { # Open a connection to a database - of the form )LOGON DBLit DBType [User|PROMPT] [Password|PROMPT] DBName <connection String>
    displayDebug("SKL_selSkipCards=$SKL_selSkipCards, SKL_DOTSkipCards=$SKL_DOTSkipCards",2);
    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      # Process the )LOGON Card
      for ( $j=0; $j< $SKL_maxConnections; $j++ ) { # search for afree slot
        if ( $SKL_connectionInUse[$j] eq "No" ) {
          last; # found an available connection
        }
      }
      if ( $SKL_connectionName[$j] ne $DBConnection ) { # no more slots available
        displayError("Too many concurrent Connections open - maximum of " . $SKL_maxConnections . " )LOGON statements allowed - )LOGON ignored");
        return;
      }
      $SKL_currentConnection = $j;
      $SKL_connectionName[$j] = getToken($$SKL_arrName[$card]); # Literal that )DOT will refer to
      my $DBType = getToken($$SKL_arrName[$card]); # The PERL DBI database type
      my $DBUser = getToken($$SKL_arrName[$card]); # The user that will be used for the connection
      my $DBPwd = getToken($$SKL_arrName[$card]); # The password that will be used for the connection
      my $DBName = getToken($$SKL_arrName[$card]); # The database name that will be connected to
      my $connectionString = getToken($$SKL_arrName[$card]); # The database string that will be used (optional) 
 
      if ( uc($DBUser) eq "PROMPT" ) { # prompt for the user name
        print "Please input the value for the user that will be used to connect to $DBName:";
        my $x = <STDIN>;
        chomp $x;
        if ( trim($x) ne "" ) { 
          $DBUser = $x;
        }
      }
      if ( uc($DBPwd) eq "PROMPT" ) { # prompt for the password
        print "\nPlease input the value for the password for $DBUser:";
        system('stty','-echo');
        displayDebug("DBPwd=$DBPwd so prompting for input",2);
        my $x = <STDIN>;
        system('stty','echo');
        print "\n";
        chomp $x;
        if ( trim($x) ne "" ) {
          displayDebug("Password set to $x",2);
          $DBPwd = $x;
        }
      }

      displayDebug("\[$SKL_connectionName[$j]\] Connecting to $DBName with user $DBUser and password $DBPwd. The Connection will be made with the $DBType PerlDBI driver",2);
      
      if ( $SKL_connection[$SKL_currentConnection] = DBI->connect ("dbi:$DBType:$DBName", "$DBUser", "$DBPwd") ) { # A returned value means that all is OK
        $SKL_connection[$SKL_currentConnection]->{LongReadLen} = 0; # dont ever bring back data automatically for long fields [only used with BLOB_READ] 
        # ---------  if blob_read doesn't exist ------------------------------
        #$SKL_connection[$SKL_currentConnection]->{LongReadLen} = 5000; # limits BLOB reads to 5000 bytes
        #$SKL_connection[$SKL_currentConnection]->{ongTruncOk} = 1; # ignore truncation and dont throw an error
        # --------------------------------------------------------------------
        $SKL_connectionInUse[$j] = "Yes";
      }
      else {
        $SKL_connectionInUse[$j] = "No";
        $SKL_connectionName[$j] = "";
        displayError("Connection to $DBName failed with error $DBI::errstr");
      }
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
    }
  }
  elsif ( $SKL_cardType eq ")DOT" ) { # read in a table - of the form )DOT connRef tabRef Table <where clause>
    if ( $SKL_selSkipCards eq "No" ) { # not skipping cards because of a failed )SEL
      $SKL_DOTCount++;
      if ( $SKL_DOTSkipCards eq "No" ) { # Not within a )DOT being skipped
        for ( $j=0; $j< $SKL_maxTables; $j++ ) { # search for afree slot
          if ( $SKL_TableInUse[$j] eq "No" ) { 
            last;
          }
        }
        if ( $j == $SKL_maxTables ) { # no more slots available
          displayError("Too many concurrent cursors open - maximum of " . $SKL_maxTables . " allowed - )DOT ignored");
          return;
        }
        # so at this stage $j points to the free slot 
        $SKL_currentTable = $j;
        $SKL_TableInUse[$j] = "Yes";
        $SKL_connRef[$SKL_currentTable] = getToken($$SKL_arrName[$card]); # identifies the database connection to use
        $SKL_tabRef[$SKL_currentTable] = getToken($$SKL_arrName[$card]);  # provides the literal by which this cursor will be known
        for ( $k=0; $k< $SKL_maxTables; $k++ ) { # remove any existing entries with the same name
          if ( $SKL_TableInUse[$k] eq "No" ) { next; } # only process references that are in use
          if ( $k == $j ) { next; } # dont process the currently selected entry
          if ( $SKL_tabRef[$k] eq $SKL_tabRef[$SKL_currentTable] ) { # found an entry with the same name .... abort this )DOT with error
            displayError("Control Card invalid - Cursor reference >$SKL_tabRef[$SKL_currentTable]< already in use");
            $SKL_DOTSkipCards = "Yes";
            $SKL_DOT_resumeLevel = $SKL_DOTCount - 1;
            $SKL_TableInUse[$SKL_currentTable] = "No";
            $SKL_connRef[$SKL_currentTable] = "";
            $SKL_tabRef[$SKL_currentTable] = "";
          }
        }
        if ( $SKL_tabRef[$SKL_currentTable] ne "" ) { # it wasn't identified as a duplicate
          $SKL_tabName[$SKL_currentTable] = getToken($$SKL_arrName[$card]); # name of the table to query
          $SKL_tabWhere[$SKL_currentTable] = substr($$SKL_arrName[$card],$SKL_cPos);  # where clause to use (just take all the rest of the line)
          $SKL_tabDOT[$SKL_currentTable] = $card;
          $SKL_rowNumber[$SKL_currentTable] = -1;
          if ( substr($SKL_tabWhere[$SKL_currentTable],0,5) eq 'FILE:' ) { # Where clause is held in a file - retrieve it to build the clause
            $TMP_File = substr($SKL_tabWhere[$SKL_currentTable],5);
            if ( open ( TMPIN, "<$TMP_File" ) ) {
              $SKL_tabWhere[$SKL_currentTable] = "";
              while ( <TMPIN> ) {
                $SKL_tabWhere[$SKL_currentTable] .= " $_";
              }
              close TMPIN;
            } 
            else { # couldn't open the file
              outputLine("Unable to open $TMP_File");
              $SKL_tabWhere[$SKL_currentTable] = "";
            }
            displayDebug("Where clause from file is: $SKL_tabWhere[$SKL_currentTable]",2);
          }
          #
          # check to make sure that the card following the )DOT cards isn't an 
          # )ENDSEL or a )SELELSE statement - this should be ignored
          my $tempi = $card + 1;
          if ( uc(substr($$SKL_arrName[$tempi],0,8)) eq ")SELELSE" ) { # the next card is a SELELSE
            # skip to the next )ENDSEL
            while ( ($tempi <= $SKL_maxLines[$SKL_currentImbed]) && (uc(substr($$SKL_arrName[$tempi],0,7) ne ")ENDSEL")) ) {
              $tempi++;
            }
          }
          # skip to the next card if the current card is an ENDSEL
          while ( ($tempi <= $SKL_maxLines[$SKL_currentImbed]) && (uc(substr($$SKL_arrName[$tempi],0,7) eq ")ENDSEL")) ) {
            $tempi++;
          }
          if ($tempi > $SKL_maxLines[$SKL_currentImbed]) { # we have run out of cards in this skeleton
            displayError("Problems with the )DOT at card $card in skeleton $SKL_imbedName[$SKL_currentImbed]");
          }
          else {
            $SKL_tabDOT[$SKL_currentTable] = $tempi - 1; # This value if the point at which the DOT loop begins
            displayDebug("DOT_loop now set to $SKL_tabDOT[$SKL_currentTable]",2);
          }
          # now process the open
          if ( establishCursor($SKL_currentTable, $card) ) { # returns 1 if all is OK (also attempts to read the first row)
            if ( $SKL_endOfCursor eq "Yes" ) { # no rows returned (should be 1 at this point)
              displayDebug("Call to SQL returned 0 rows",2);
              $SKL_DOTSkipCards = "Yes";
              $SKL_DOT_EmptyLevel = $SKL_DOTCount;
              $SKL_DOT_resumeLevel = $SKL_DOTCount - 1;
              $SKL_tabRef[$SKL_currentTable] = ""; # free up the reference
            }
            else { # a row was returned
            }
          }
          else { # Problems in river city
            displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SKL_sqlStatement");
            $SKL_DOTSkipCards = "Yes";
            $SKL_DOT_resumeLevel = $SKL_DOTCount - 1;
            $SKL_tabRef[$SKL_currentTable] = ""; # free up the reference
          }
        }
        displayDebug("Processed: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
      }
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
    }
  }
  elsif ( $SKL_cardType eq ")XDOT" ) { # read in a table - of the form )XDOT connRef tabRef <SQL Statement>
    if ( $SKL_selSkipCards eq "No" ) { # not skipping cards because of a failed )SEL
      $SKL_DOTCount++;
      if ( $SKL_DOTSkipCards eq "No" ) { # Not within a )DOT being skipped
        for ( $j=0; $j< $SKL_maxTables; $j++ ) { # search for afree slot
          if ( $SKL_TableInUse[$j] eq "No" ) { 
            last;
          }
        }
        if ( $j == $SKL_maxTables ) { # no more slots available
          displayError("Too many concurrent cursors open - maximum of " . $SKL_maxTables . " allowed - )DOT ignored");
          return;
        }
        # so at this stage $j points to the free slot 
        # the reality is that the next slot should have been $SKL_currentTable + 1
        $SKL_currentTable = $j;
        $SKL_TableInUse[$j] = "Yes";
        $SKL_connRef[$SKL_currentTable] = getToken($$SKL_arrName[$card]); # identifies the database connection to use
        $SKL_tabRef[$SKL_currentTable] = getToken($$SKL_arrName[$card]);  # provides the literal by which this cursor will be known
        for ( $k=0; $k< $SKL_maxTables; $k++ ) { # remove any existing entries with the same name
          if ( $SKL_TableInUse[$k] eq "No" ) { next; } # only process references that are in use
          if ( $k == $j ) { next; } # dont process the currently selected entry
          if ( $SKL_tabRef[$k] eq $SKL_tabRef[$SKL_currentTable] ) { # found an entry with the same name .... abort this )DOT with error
            displayError("Control Card invalid - Cursor reference >$SKL_tabRef[$SKL_currentTable]< already in use");
            $SKL_DOTSkipCards = "Yes";
            $SKL_DOT_resumeLevel = $SKL_DOTCount - 1;
            $SKL_TableInUse[$SKL_currentTable] = "No";
            $SKL_connRef[$SKL_currentTable] = "";
            $SKL_tabRef[$SKL_currentTable] = "";
          }
        }
        if ( $SKL_tabRef[$SKL_currentTable] ne "" ) { # it wasn't identified as a duplicate
          $SKL_tabName[$SKL_currentTable] = 'XDOT'; # name of the table to query
          $SKL_tabWhere[$SKL_currentTable] = substr($$SKL_arrName[$card],$SKL_cPos);  # SQL Statement to use (just take all the rest of the line)
          $SKL_tabDOT[$SKL_currentTable] = $card;
          $SKL_rowNumber[$SKL_currentTable] = -1;
  
          if ( substr($SKL_tabWhere[$SKL_currentTable],0,5) eq 'FILE:' ) { # Where clause is held in a file - retrieve it to build the clause
            $TMP_File = substr($SKL_tabWhere[$SKL_currentTable],5);
            if ( open ( TMPIN, "<$TMP_File" ) ) {
              $SKL_tabWhere[$SKL_currentTable] = "";
              while ( <TMPIN> ) {
                $SKL_tabWhere[$SKL_currentTable] .= " $_";
              }
              close TMPIN;
            }
            else { # couldn't open the file
              outputLine("Unable to open $TMP_File");
              $SKL_tabWhere[$SKL_currentTable] = "";
            }
            displayDebug("Where clause from file is: $SKL_tabWhere[$SKL_currentTable]",2);
          }

          #
          # check to make sure that the card following the )DOT cards isn't an 
          # )ENDSEL or a )SELELSE statement - this should be ignored
          my $tempi = $card + 1;
          if ( uc(substr($$SKL_arrName[$tempi],0,8)) eq ")SELELSE" ) { # the next card is a SELELSE
            # skip to the next )ENDSEL
            while ( ($tempi <= $SKL_maxLines[$SKL_currentImbed]) && (uc(substr($$SKL_arrName[$tempi],0,7) ne ")ENDSEL")) ) {
              $tempi++;
            }
          }
          # skip to the next card if the current card is an ENDSEL
          while ( ($tempi <= $SKL_maxLines[$SKL_currentImbed]) && (uc(substr($$SKL_arrName[$tempi],0,7) eq ")ENDSEL")) ) {
            $tempi++;
          }
          if ($tempi > $SKL_maxLines[$SKL_currentImbed]) { # we have run out of cards in this skeleton
            displayError("Problems with the )DOT at card $card in skeleton $SKL_imbedName[$SKL_currentImbed]");
          }
          else {
            $SKL_tabDOT[$SKL_currentTable] = $tempi - 1; # This value if the point at which the DOT loop begins
            displayDebug("DOT_loop now set to $SKL_tabDOT[$SKL_currentTable]",2);
          }
          # now process the open
          if ( establishCursor($SKL_currentTable, $card) ) { # returns 1 if all is OK (also attempts to read the first row)
            if ( $SKL_endOfCursor eq "Yes" ) { # no rows returned (should be 1 at this point)
              displayDebug("Call to SQL returned 0 rows",2);
              $SKL_DOTSkipCards = "Yes";
              $SKL_DOT_resumeLevel = $SKL_DOTCount - 1;
              $SKL_tabRef[$SKL_currentTable] = ""; # Free up the reference
            }
            else { # a row was returned
            }
          }
          else { # Problems in river city
            displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SKL_sqlStatement");
            $SKL_DOTSkipCards = "Yes";
            $SKL_DOT_resumeLevel = $SKL_DOTCount - 1;
            $SKL_tabRef[$SKL_currentTable] = ""; # Free up the reference
          }
        }
        displayDebug("Processed: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
      }
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
    }
  }
  elsif ( $SKL_cardType eq ")FTAB" ) { # select and generate a formatted dump of a table
    if ( $SKL_selSkipCards eq "No" ) { # not skipping cards because of a failed )SEL
      if ( $SKL_DOTSkipCards eq "No" ) { # Not within a )DOT being skipped
        $SKL_FTAB_database = getToken($$SKL_arrName[$card]); # identifies the database connection to use
        $SKL_FTAB_Select = substr($$SKL_arrName[$card],$SKL_cPos);  # SQL Statement to use (just take all the rest of the line)

        if ( substr($SKL_FTAB_Select,0,5) eq 'FILE:' ) { # Where clause is held in a file - retrieve it to build the clause
          $TMP_File = substr($SKL_FTAB_Select,5);
          if ( open ( TMPIN, "<$TMP_File" ) ) {
            $SKL_FTAB_Select = "";
            while ( <TMPIN> ) {
              $SKL_FTAB_Select .= " $_";
            }
            close TMPIN;
          }
          else { # couldn't open the file
            outputLine("Unable to open $TMP_File");
            $SKL_FTAB_Select = "";
          }
          displayDebug("Where clause from file is: $SKL_FTAB_Select",2);
        }

        # now process the open
        if ( establishFTABCursor($SKL_FTAB_Select, $SKL_FTAB_database) ) { # returns 1 if all is OK (also attempts to read the first row)
          if ( $SKL_FTAB_rowNumber == 0 ) { # no rows returned (should be 1 at this point)
            displayDebug("Call to SQL returned 0 rows",2);
            outputLine("No Data Returned"); 
          }
          else { # a row was returned
            displayDebug("Rows returned",2);
            if ( $mode eq "HTTP" ) {  # output it as a html table
              outputLine("<table border=\"1\"><tr>\n");
              $num_of_fields = $SKL_FTAB_cursor->{NUM_OF_FIELDS};
              for ( $i=0; $i<$num_of_fields; $i++ ) {
                outputLine("<th>" . $SKL_FTAB_cursor->{NAME}->[$i] . "</th>");
              }
              outputLine("</tr>\n");
            }
            else {
              outputLine("\n");
              my $tStr = "";
              $num_of_fields = $SKL_FTAB_cursor->{NUM_OF_FIELDS};
              for ( $i=0; $i<$num_of_fields; $i++ ) {
                $tStr .= "!" . $SKL_FTAB_cursor->{NAME}->[$i];
              }
              outputLine("$tStr\n");
            }
            displayDebug("About to enter field loop",2);
            my $moreToProcess = "Yes";
            while ( $moreToProcess eq "Yes" ) { # A value of 1 indicates data was returned
              displayDebug("In enter field loop",2);
              my $tStr = "";
              if ( $mode eq "HTTP" ) {  # output it as a html table
                $tStr = "<tr>";
              }
              displayDebug("Number of fields = $num_of_fields\n",2);
              for ( $i=0; $i<$num_of_fields; $i++ ) {
                my $fieldType = $SKL_FTAB_cursor->{TYPE}->[$i]; # $fieldType is now the field type (CHAR, VARCHAR etc)
                # SQL_CHAR             1
                # SQL_NUMERIC          2
                # SQL_DECIMAL          3
                # SQL_INTEGER          4
                # SQL_SMALLINT         5
                # SQL_FLOAT            6
                # SQL_REAL             7
                # SQL_DOUBLE           8
                # SQL_DATE             9
                # SQL_TIME            10
                # SQL_TIMESTAMP       11
                # SQL_VARCHAR         12
                # SQL_LONGVARCHAR     -1
                # SQL_BINARY          -2
                # SQL_VARBINARY       -3
                # SQL_LONGVARBINARY   -4
                # SQL_BIGINT          -5
                # SQL_TINYINT         -6
                # SQL_BIT             -7
                # SQL_WCHAR           -8
                # SQL_WVARCHAR        -9
                # SQL_WLONGVARCHAR   -10
                $SKL_tabValue = "";
                if ( ($fieldType == -1) || ($fieldType == -4) || ($fieldType == -10) ) { # long field
                  if ( defined($SKL_FTAB_Cols[$i]) ) {
                    $SKL_tabValue = $SKL_FTAB_Cols[$i];
                  }
                  else {
                    $SKL_tabValue = getFTABLong($i);
                    $SKL_FTAB_Cols[$i] = $SKL_tabValue;
                  }
                }
                else { # no special processing needs to be done
                  if ( defined($SKL_FTAB_Cols[$i]) ) { # variable is not null
                    if ( ( $fieldType == 1 ) || ( $fieldType == 12 ) || ( $fieldType == -8 ) || ( $fieldType == -9 )) { #
                      $SKL_tabValue = trim($SKL_FTAB_Cols[$i]);
                      displayDebug("Column $i has a value of $SKL_FTAB_Cols[$i]\n",2);
                    }
                    else {
                      $SKL_tabValue = $SKL_FTAB_Cols[$i];
                      displayDebug("Column $i has a value of $SKL_FTAB_Cols[$i]\n",2);
                    }
                  }
                  else {
                    $SKL_tabValue = "NULL";
                  }
                }
  
                if ( $mode eq "HTTP" ) {  # output it as a html table
                  if ( ($fieldType >= 2) && ($fieldType <= 8) ) { # right align numeric fields
                    $tStr .= "<td align=\"right\">" . $SKL_tabValue . "</td> ";
                  }
                  else {
                    $tStr .= "<td>" . $SKL_tabValue . "</td> ";
                  }
                }
                else {
                  $tStr .= "!" . $SKL_tabValue;
                }
              }
              if ( $mode eq "HTTP" ) {  # output it as a html table
                outputLine("$tStr</tr>\n");
              }
              else {
                outputLine("$tStr\n");
              }
              if ( getNextFTABRecord ) { # more to process
                $moreToProcess = "Yes";
              }
              else {
                $moreToProcess = "No";
              }
            }
            # no more data
            if ( $mode eq "HTTP" ) {  # output it as a html table
              outputLine("</table>\n");
            }
            closeFTABCursor;
          }
        }
        else { # Problems in river city
          displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SKL_sqlStatement");
        }
        displayDebug("Processed: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
      }
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
    }
  }
  elsif ( $SKL_cardType eq ")FVTAB" ) { # select and generate a vertically formatted dump of a table
    if ( $SKL_selSkipCards eq "No" ) { # not skipping cards because of a failed )SEL
      if ( $SKL_DOTSkipCards eq "No" ) { # Not within a )DOT being skipped
        $SKL_FTAB_database = getToken($$SKL_arrName[$card]); # identifies the database connection to use
        $SKL_FTAB_Select = substr($$SKL_arrName[$card],$SKL_cPos);  # SQL Statement to use (just take all the rest of the line)

        if ( substr($SKL_FTAB_Select,0,5) eq 'FILE:' ) { # Where clause is held in a file - retrieve it to build the clause
          $TMP_File = substr($SKL_FTAB_Select,5);
          if ( open ( TMPIN, "<$TMP_File" ) ) {
            $SKL_FTAB_Select = "";
            while ( <TMPIN> ) {
              $SKL_FTAB_Select .= " $_";
            }
            close TMPIN;
          }
          else { # couldn't open the file
            outputLine("Unable to open $TMP_File");
            $SKL_FTAB_Select = "";
          }
          displayDebug("Where clause from file is: $SKL_FTAB_Select",2);
        }

        # now process the open
        if ( establishFTABCursor($SKL_FTAB_Select, $SKL_FTAB_database) ) { # returns 1 if all is OK (also attempts to read the first row)
          if ( $SKL_FTAB_rowNumber == 0 ) { # no rows returned (should be 1 at this point)
            displayDebug("Call to SQL returned 0 rows",2);
            outputLine("No Data Returned");
          }
          else { # a row was returned
            displayDebug("Rows returned",2);
            $num_of_fields = $SKL_FTAB_cursor->{NUM_OF_FIELDS};
            my $moreToProcess = "Yes";
            while ( $moreToProcess eq "Yes" ) {
              if ( $mode eq "HTTP" ) {  # output it as a html table
                outputLine("<table border=\"1\"><tr>\n");
              }
              for ( $i=0; $i<$num_of_fields; $i++ ) {
                my $fieldType = $SKL_FTAB_cursor->{TYPE}->[$i]; # $fieldType is now the field type (CHAR, VARCHAR etc)
                # SQL_CHAR             1
                # SQL_NUMERIC          2
                # SQL_DECIMAL          3
                # SQL_INTEGER          4
                # SQL_SMALLINT         5
                # SQL_FLOAT            6
                # SQL_REAL             7
                # SQL_DOUBLE           8
                # SQL_DATE             9
                # SQL_TIME            10
                # SQL_TIMESTAMP       11
                # SQL_VARCHAR         12
                # SQL_LONGVARCHAR     -1
                # SQL_BINARY          -2
                # SQL_VARBINARY       -3
                # SQL_LONGVARBINARY   -4
                # SQL_BIGINT          -5
                # SQL_TINYINT         -6
                # SQL_BIT             -7
                # SQL_WCHAR           -8
                # SQL_WVARCHAR        -9
                # SQL_WLONGVARCHAR   -10
                $SKL_tabValue = "";
                if ( ($fieldType == -1) || ($fieldType == -4) || ($fieldType == -10) ) { # long field
                  if ( defined($SKL_FTAB_Cols[$i]) ) {
                    $SKL_tabValue = $SKL_FTAB_Cols[$i]; # use the saved value
                  }
                  else { # retrieve the lob
                    $SKL_tabValue = getFTABLong($i);
                    $SKL_FTAB_Cols[$i] = $SKL_tabValue; # save it in case it is needed again
                  }
                }
                else { # no special processing needs to be done
                  if ( defined($SKL_FTAB_Cols[$i]) ) { # variable is not null
                    if ( ( $fieldType == 1 ) || ( $fieldType == 12 ) || ( $fieldType == -8 ) || ( $fieldType == -9 )) { #
                      $SKL_tabValue = trim($SKL_FTAB_Cols[$i]);
                      displayDebug("Column $i has a value of $SKL_FTAB_Cols[$i]\n",2);
                    }
                    else {
                      $SKL_tabValue = $SKL_FTAB_Cols[$i];
                      displayDebug("Column $i has a value of $SKL_FTAB_Cols[$i]\n",2);
                    }
                  }
                  else {
                    $SKL_tabValue = "NULL";
                  }
                }

                if ( $mode eq "HTTP" ) {  # output it as a html table
                  outputLine("<tr><td>" . $SKL_FTAB_cursor->{NAME}->[$i] . "</td><td>" . $SKL_tabValue . "</td></tr>");
                }
                else {
                  outputLine("!" . $SKL_FTAB_cursor->{NAME}->[$i] . " !" . $SKL_tabValue);
                }
              }

              if ( $mode eq "HTTP" ) {  # output it as a html table
                outputLine("</table>\n");
              }

              if ( getNextFTABRecord ) { # more to process
                $moreToProcess = "Yes";
              }
              else {
                $moreToProcess = "No";
              }
            }
            closeFTABCursor;
          }
        }
        else { # Problems in river city
          displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SKL_sqlStatement");
        }
        displayDebug("Processed: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
      }
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
    }
  }
  elsif ( $SKL_cardType eq ")DOF" ) { # read in a file - of the form )DOF [<fileName> [using <CTLFileName>]]
                                      #    defaults are inFile.txt for the fileName and inFile.ctl for the CTLFileName

    # NOTE: A file may NOT be read in through 2 DOF statements simultaneously as the variables will not be separated

    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      # Check to make sure the card following this one isn't an )ENDSEL or a )SELELSE statement - these should be ignored
      my $tempi = $card + 1;
      if ( uc(substr($$SKL_arrName[$tempi],0,8)) eq ")SELELSE" ) { # the next card is a SELELSE
        # skip to the next )ENDSEL
        while ( ($tempi <= $SKL_maxLines[$SKL_currentImbed]) && (uc(substr($$SKL_arrName[$tempi],0,7) ne ")ENDSEL")) ) {
          $tempi++;
        }
      }
      # skip to the next card if the current card is an ENDSEL
      while ( ($tempi <= $SKL_maxLines[$SKL_currentImbed]) && (uc(substr($$SKL_arrName[$tempi],0,7) eq ")ENDSEL")) ) {
        $tempi++;
      }
      if ($tempi > $SKL_maxLines[$SKL_currentImbed]) { # we have run out of cards in this skeleton
        displayError("Problems with the )DOF at card $card in skeleton $SKL_imbedName[$SKL_currentImbed]");
      }
      else {
        $temp_start_location = $tempi - 1; # This value if the point at which the DOF loop begins
        displayDebug("DOF_loop now set to $temp_start_location",2);
      }
      # process the )DOF statement and set parameters
      my $dataFile = getToken($$SKL_arrName[$card]);
      my $literal = getToken($$SKL_arrName[$card]);
      my $ctlFile = getToken($$SKL_arrName[$card]);
      $dataFile = substituteVariables($dataFile);
      $literal = substituteVariables($literal);
      $ctlFile = substituteVariables($ctlFile);
      if ( (uc($literal) ne "USING") && ($literal ne "") ) {
        displayError("USING literal missing it will be assumed to be the second parameter (which will now be ignored)");
        displayError("Format of the )DOF is  )DOF [<fileName> [using <CTLFileName>]]");
      }
      if ( $dataFile eq "" ) { $dataFile = "inFile.txt"; }
      if ( $ctlFile eq "" ) { $ctlFile = "inFile.ctl"; }
      # remember the start loop location
      $DOF_loopStart{$dataFile} = $temp_start_location ;
      # generate the full file name ....
      $SKL_DATA_dir = $ENV{'SKLDATADIR'};
      if ( $SKL_DATA_dir eq "" ) {
        $SKL_DATA_fullFileName = $dataFile;
        $SKL_CTL_fullFileName = $ctlFile;
      }
      elsif ( substr($SKL_DATA_dir,-1,1) eq $SKL_dirSep  ) { # has a terminating directory separator
        $SKL_DATA_fullFileName = "$SKL_DATA_dir$dataFile";
        $SKL_CTL_fullFileName = "$SKL_CTL_dir$ctlFile";
      }
      else { # no separator so add one
        $SKL_DATA_fullFileName = "$SKL_DATA_dir$SKL_dirSep$dataFile";
        $SKL_CTL_fullFileName = "$SKL_CTL_dir$SKL_dirSep$ctlFile";
      }

      displayDebug("Data file will be $SKL_DATA_fullFileName, CTL file will be $SKL_CTL_fullFileName",1);
      # now load the control file .....
      loadFileCTL($ctlFile, $SKL_CTL_fullFileName);

      $SKL_lastCTLFileUSed = $ctlFile;
      $SKL_lastDataFileUSed = $dataFile;
 
      # now open the file and read in the first record ....
      if ( !open ( $SKL_fileHandle{$dataFile}, "<$SKL_DATA_fullFileName" ) ) {
        # file not found (possibly)
        displayError("Unable to open $SKL_DATA_fullFileName.\nError: $?");
        displayError("One pass through the loop will be performed.");
	$SKL_dataFileOpenError = "Yes";
      }
      else { # The file does at least exist 
	$SKL_dataFileOpenError = "No";
        # save the file handle
        #$SKL_fileHandle{$dataFile} = *OPENFILE; # save the file handle
        #$SKL_fileRecord = <OPENFILE>;
        #$SKL_fileRecord = <*$SKL_fileHandle{$dataFile}>;
        $SKL_fileRecord = readDataFileRecord($SKL_fileHandle{$dataFile});
        if ( defined($SKL_fileRecord) )  { # not EOF
          setDefinedVariablesForFile($ctlFile, $SKL_fileRecord); # Set all of the variables
        } #EOF
        else {
          displayError("File $SKL_DATA_fullFileName is empty");
          displayError("One pass through the loop will be performed.");
          $DOF_loopStart{$dataFile} = -1;
          $SKL_fileHandle{$dataFile} = "";
        }
      }
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]",2);
    }
  }
  elsif ( $SKL_cardType eq ")ENDDOF" ) {
    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      # process the )ENDDOF statement and set parameters
      my $dataFile = getToken($$SKL_arrName[$card]);
      if ( $dataFile eq "" ) { # if no link is passed then just use the last file opened
        $dataFile = $SKL_lastDataFileUSed; 
        $ctlFile = $SKL_lastCTLFileUSed;
      }

      if ( ! defined($SKL_fileRecord) ) { # EOF so just pass on through 
        close $SKL_fileHandle{$dataFile} ;
        $SKL_fileHandle{$dataFile} = "";
      }
      elsif ( $SKL_dataFileOpenError eq "Yes" ) {
        $SKL_fileHandle{$dataFile} = "";
      }
      else {
        $SKL_fileRecord = readDataFileRecord($SKL_fileHandle{$dataFile}); # read in another record
        if ( defined($SKL_fileRecord) ) { # not EOF so process the record (otherwise just let it flow through)
          setDefinedVariablesForFile($ctlFile, $SKL_fileRecord); # Set all of the variables
          $SKL_currentImbedLine[$SKL_currentImbed] = $DOF_loopStart{$dataFile} ;
        }
      }
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]",2);
    }
  }
  elsif ( $SKL_cardType eq ")ENDDOT" ) {
    if ( $SKL_DOTCount == 0 ) { # no previous matching )DOT
      displayError("ENDDOT without DOT - card number $card - card ignored");
      return;
    }
    if ( $SKL_selSkipCards eq "No" ) { # not skipping cards because of SEL
      if ( $SKL_DOTSkipCards eq "No" ) { # not skipping cards because of DOT
        # $SKL_cursorRef[$SKL_currentTable] - this variable holds the generated array name holding the data
        if ( getNextRecord($SKL_cursorRef[$SKL_currentTable],$SKL_currentTable) ) { #  data returned
          displayDebug("Data returned and put in Array. Array name is $$SKL_cursorRef[$SKL_currentTable]",2);
          $SKL_currentImbedLine[$SKL_currentImbed] = $SKL_tabDOT[$SKL_currentTable]; # reset current skeleton line to the beginning of the loop
        }
        else { # no more data
          closeCursor($SKL_currentTable);
          $SKL_tabRef[$SKL_currentTable] = ""; # free up the cursor reference literal
          $SKL_TableInUse[$SKL_currentTable] = "No"; # Mark the slot as available
          $SKL_currentTable = $SKL_currentTable -1 ; 
          $SKL_DOTCount = $SKL_DOTCount -1;
        }
      }
      else { # Currently skipping within a DOT
        $SKL_DOTCount = $SKL_DOTCount -1;
        if ( $SKL_DOTCount == $SKL_DOT_resumeLevel ) { 
          $SKL_DOTSkipCards = "No";
          $SKL_currentTable = $SKL_currentTable -1 ; 
          $SKL_TableInUse[$SKL_currentTable] = "No";
        }
      }
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]",2);
    }
  }
  elsif ( $SKL_cardType eq ")DISNOTE" ) {
    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      my $disNote = substr($SKL_varArray{$dispVar},9);
      $disNote = substituteVariables($disNote);
      displayError($disNote,0);
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]",2);
    }
  }
  elsif ( $SKL_cardType eq ")CASE_SENS_COLS" ) {
    $SKL_caseSensitiveColumns = "Yes";
  }
  elsif ( $SKL_cardType eq ")TRACE" ) {
    $SKL_traceHOLD = $SKL_debugLevel;
    $SKL_debugLevel = evaluateInfix(trim(substr($$SKL_arrName[$card],$SKL_cPos)));
    displayDebug("Trace level $SKL_traceHOLD saved and reset to $SKL_debugLevel",0);
  }
  elsif ( $SKL_cardType eq ")TRACEOFF" ) {
    $SKL_debugLevel = $SKL_traceHOLD;
    displayDebug("Trace level $SKL_traceHOLD resumed",0);
  }
  elsif ( $SKL_cardType eq ")DEBUG" ) {
    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      displayDebug("DEBUG information listing:",0);
      displayDebug("Defined Variables:",0);
      # print out some global variables 
      foreach $dispVar (sort by_key keys %SKL_varArray) { 
        displayDebug("$dispVar = $SKL_varArray{$dispVar}",0);
      }
      displayDebug("Established Cursors:",0);
      for ( $j=0; $j<$SKL_maxTables; $j++ ) {
        displayDebug("  [$j]: $SKL_tabRef[$j]",0);
      }
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]",2);
    }
  }
  elsif ( $SKL_cardType eq ")FUNC" ) {
    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      my $funcName = getToken($$SKL_arrName[$card]);
      my $varName = getToken($$SKL_arrName[$card]);
      my $varOp = getToken($$SKL_arrName[$card]);
      if ( $varOp ne "=" ) { 
	displayError("Operator for )SET must be '='. Operator found was $varOp");
	return;
      }
      displayDebug("\)FUNC string is " . substr($$SKL_arrName[$card],$SKL_cPos),1);
      my $varValue = processFunction($funcName, trim(substr($$SKL_arrName[$card],$SKL_cPos)));
      displayDebug("Result = $varValue",1);
      setVariable($varName,$varValue);
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
    }
  }
  elsif ( $SKL_cardType eq ")SEL" ) {
    if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
      $SKL_SELCount++;
      my $tmpI = trim(substr($$SKL_arrName[$card],5));
      displayDebug("Passing the following condition (SEL) : $tmpI",2);
      if ( evaluateCondition(trim(substr($$SKL_arrName[$card],5))) eq "False" ) {
	displayDebug("Condition evaluated to False",2);
        $SKL_selSkipCards = "Yes";
	$SKL_SEL_resumeLevel = $SKL_SELCount - 1;
	$SKL_gotoENDSEL = "No";
      }
      else {
	displayDebug("Condition evaluated to True",2);
        $SKL_gotoENDSEL = "Yes";
      }
      displayDebug("Processed )SEL. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",1);
    }
    else {
      displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
    }
  }
  elsif ( $SKL_cardType eq ")SELELSE" ) {
    if ( ( $SKL_gotoENDSEL eq "No" ) ) { # no successful SELELSE yet
      if ( ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards 
	if ( ( $SKL_selSkipCards eq "Yes" ) ) { # skipping SEL cards
	  if ( trim($$SKL_arrName[$card]) eq ")SELELSE" ) { # the card has no conditions
	    if ( $SKL_SELCount == $SKL_SEL_resumeLevel + 1 ) { # not sure what this is testing for
	      $SKL_selSkipCards = "No";
	      $SKL_gotoENDSEL = "Yes";
	    }
	  }
	  else { # the SELELSE has a condition parameter
            my $tmpI = trim(substr($$SKL_arrName[$card],9));
            displayDebug("Passing the following condition (SELELSE) : $tmpI",2);
            if ( evaluateCondition(trim(substr($$SKL_arrName[$card],9))) eq "False" ) {
	      displayDebug("Condition evaluated to False",2);
              $SKL_selSkipCards = "Yes";
	      $SKL_SEL_resumeLevel = $SKL_SELCount -1;
	      $SKL_gotoENDSEL = "No";
            }
            else {
	      displayDebug("Condition evaluated to True",2);
	      $SKL_selSkipCards = "No";
              $SKL_gotoENDSEL = "Yes";
	    }
	  }
        }  
	else { # within existing SEL which has passed it's test so just skip till next )ENDSEL
          if ( $SKL_SELCount == 0 ) {
            displayError(")SELELSE without )SEL - Card number $card of $SKL_imbedName[$SKL_currentImbed]");
	  }
	  $SKL_SEL_resumeLevel = $SKL_SELCount -1;
          displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
	}
	if ( $SKL_SELCount < 0 ) { 
          displayError(")SELELSE without )SEL - Card number $card of $SKL_imbedName[$SKL_currentImbed]");
        }
        displayDebug("Processed )SEL. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",1);
      }
    }
    else { # keep skipping until we get to a )ENDSEL
      $SKL_SEL_resumeLevel = $SKL_SELCount -1;
      $SKL_selSkipCards = "Yes";
      displayDebug("Skipped: $$SKL_arrName[$card]. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",2);
    }
  }
  elsif ( $SKL_cardType eq ")ENDSEL" ) {
    if ( $SKL_DOTSkipCards eq "No" ) { # not skipping cards (caused when )DOT returns no rows .... we're waiting for a )ENDDOT
      $SKL_SELCount--;
      if ( ( $SKL_selSkipCards eq "Yes" ) ) { # skipping cards
        if ( $SKL_SELCount == $SKL_SEL_resumeLevel ) { 
       	  $SKL_selSkipCards = "No";
  	  $SKL_gotoENDSEL = "No";
        }
        displayDebug("Processed )ENDSEL. Sel Count = $SKL_SELCount, SEL Resume Level = $SKL_SEL_resumeLevel",1);
      }
      if ( $SKL_SELCount < 0 ) {
        displayError("ENDSEL without SEL - Card number $card of $SKL_imbedName[$SKL_currentImbed]");
      }
    }
  }
  elsif ( ($SKL_cardType eq ")CM") || ($SKL_cardType eq ")COMMENT") ) { # Ignore comment cards
  }
  else {
    if ( $SKL_UnknownCardMessageDisplayed eq "No" ) {
      displayError("Unknown control card : $$SKL_arrName[$card]. It will be ignored");
      $SKL_UnknownCardMessageDisplayed = "Yes";
    }
  }

  displayDebug("Start Processing Control Card ($card) : $$SKL_arrName[$card]",2);
  $tempLine = substituteVariables($$SKL_arrName[$card]); 
  $tempLine = putInTabs($tempLine);
  if ( $SKL_debugLevel > 0 ) { outputLine($tempLine); }
  
}

sub processLine {
  my $card = shift; # index into the current skeleton
  my $tempLine ;

  displayDebug("Start Processing Normal Card ($card) : $$SKL_arrName[$card]",2);
  if ( trim($$SKL_arrName[$card]) eq "" ) { # it is a blank line
    outputLine($$SKL_arrName[$card]);
  }
  else {
    $tempLine = substituteVariables($$SKL_arrName[$card]); 
    $tempLine = putInTabs($tempLine);
    outputLine($tempLine);
  }
}

sub pullImbed {
  # retrieve the current last number
  my $CImbed = shift; # this is the imbed now being discarded
  my $i;

  displayDebug("in pullImbed", 1);
  
  $SKL_lastImbedName = $SKL_imbedName[$CImbed];
  if ( $SKL_MaxImbed > -1 ) { # there are some entries in the stack 
    $SKL_imbedInUse[$CImbed] = "No";  
    # check to see if the current element still exists in the stack 
    # (and so will be reused at some point)
    for ( $i = 0 ; $i < $SKL_MaxImbed ; $i++ ) {
      if ( $SKL_Imbed[$SKL_MaxImbed] eq $CImbed ) {
        $SKL_imbedInUse[$CImbed] = "Yes";  
      }
    }
    # now we can just return the top entry
    $i = $SKL_Imbed[$SKL_MaxImbed];
    $SKL_MaxImbed = $SKL_MaxImbed - 1;  # discard the top element 
    return $i; # return the top element
  }
  else {
    return -1 ; # no entries left in the stack
  }  
}


sub pushImbed {
  # save the current imbed number 
  my $CImbed = shift;
  
  displayDebug("in pushImbed", 1);

  $SKL_MaxImbed++;
  $SKL_Imbed[$SKL_MaxImbed] = $CImbed;
}

sub loadSkel { 

  my $i;
  my $skel = shift; 

  # load a requested skeleton into the skeleton cache
  
  displayDebug("loading skeleton $skel", 1);
  $SKL_alreadyLoaded = "No";
  $SKL_dontCache = "Yes"; # this variable set so no real caching will occur - skeletons will always be reloaded

  # Check to see if the skeleton is already loaded 
  for ( $i = 0 ; $i < $SKL_maxImbeds ; $i++ ) {
    if ( $SKL_imbedName[$i] eq $skel ) { 
      # Skeleton is already loaded ...
      $SKL_imbedInUse[$i] = "Yes";
      pushImbed($SKL_currentImbed);
      $SKL_currentImbed = $i;
      $SKL_alreadyLoaded = "Yes";
      $SKL_currentImbedLine[$SKL_currentImbed] = 1; 
      displayDebug("reusing existing skel as it is already loaded at pos $i",1);
      last;
    }  
  }
  if ( $SKL_alreadyLoaded eq "No" ) { # skeleton not found in storage
    # search for a free slot 
    for ( $i = 0 ; $i < $SKL_maxImbeds ; $i++ ) {
      if ( $SKL_imbedInUse[$i] eq "No" ) {
        displayDebug("Imbed entry $i is not in use",1);
        if ( $SKL_currentImbed > -1 ) { # not the first imbed
          pushImbed($SKL_currentImbed);
        }
        last;
      }
    }
    if ( $SKL_imbedInUse[$i] eq "Yes" ) { # couldn't find a free entry 
      displayError("Too many currently used skeletons - maximum of $SKL_maxImbeds exceeded");
      return;
    }
    else { # found a slot
      $SKL_imbedInUse[$i] = "Yes";
      $SKL_currentImbed = $i;
    }
  }
  # $SKL_currentImbed now set 
  if ( ( $SKL_alreadyLoaded eq "No" ) || ( $SKL_dontCache eq "Yes" ) ) {
    # load the skeleton again 
    $SKL_dir = $ENV{'SKELDIR'}; 
    if ( $SKL_dir eq "" ) { 
      $SKL_fullFileName = $skel;
    }
    elsif ( substr($SKL_dir,-1,1) eq $SKL_dirSep  ) { # has a terminating directory separator
      $SKL_fullFileName = "$SKL_dir$skel";
    }
    else { # no separator so add one 
      $SKL_fullFileName = "$SKL_dir$SKL_dirSep$skel";
    }

    $SKL_imbedName[$SKL_currentImbed] = $skel;
    $SKL_arrName = "SKL_imbedArray$SKL_currentImbed"; # SKL_arrName holds the array holding the current skeleton
    if ( !open (INSKEL, "<$SKL_fullFileName") ) { # open has failed ...
      displayError("Open of $SKL_fullFileName has failed");
      $SKL_imbedName[$SKL_currentImbed] = "";
      $SKL_maxLines[$SKL_currentImbed] = 1;
      $SKL_currentImbedLine[$SKL_currentImbed] = 0;
      $SKL_currentImbed = pullImbed($SKL_currentImbed); # changed this - may not be correct !
      $SKL_arrName = "SKL_imbedArray$SKL_currentImbed";
      return;
    }
    else { # load it up
      $i = 0;
      while ( <INSKEL> ) {
        chomp $_;
        $$SKL_arrName[$i++] = $_;
      }
      $SKL_maxLines[$SKL_currentImbed] = $i;
      $SKL_currentImbedLine[$SKL_currentImbed] = 0;
      if ( $SKL_loadingImbed eq "Yes" ) { # called bacause of a )IMBED statement
        $SKL_currentImbedLine[$SKL_currentImbed] = 0;
      }
      $SKL_loadingImbed = "No";
    }
    close INSKEL;
    
  }
}

sub setDefinedVariablesForFile {
  my $ctlFile = shift;    # What CTL file we should use to decode the record
  my $FileRecord = shift; # the record being read in
  my $fldName, $fldStart, $fldLen, $condStart, $condLen, $condValue, $fldValue, $testValue;
  my $setVar, $i, $currCTLi, $delimiter, $delNull,$delimType;
  my $delimArr;

  $SKL_DOF_ignoreRecord = "No";
  displayDebug("Looking for $ctlFile in cache",1);

  # find the control file ....
  for ($currCTL=0 ; $currCTL<=$SKL_maxCTLFiles; $currCTL++ ) {
    if ( $SKL_CTLFileName[$currCTL] eq $ctlFile ) { # found a match 
      last;
    }
  }
  
  if ( $SKL_CTLFileName[$currCTL] ne $ctlFile ) { # no match found
    displayError("CTL File $ctlFile not found in memory - this shouldn't happen but is probably caused by a file not found");
    return; # unhappily
  }

  displayDebug("$ctlFile found in array entry $currCTL",1);
  $SKL_CTL_arrName = "SKL_CTLFileArray$currCTL"; # SKL_CTL_arrName holds the array holding the current file definition

  for ( $i=0 ; $i<=$SKL_CTL_maxLines[$currCTL]; $i++ ) {
    displayDebug("CTL Field Array Entry being Processed: $$SKL_CTL_arrName[$i]",1);
    $delimiter = substr($$SKL_CTL_arrName[$i],0,1); # first char is the delimiter
    $setVar = "No";
    ($delNull,$delimType,$fldName, $fldStart, $fldLen, $condStart, $condLen, $condValue) = split ($delimiter,$$SKL_CTL_arrName[$i],8); 
    displayDebug("delimType is $delimType, fldName is $fldName, fldStart is $fldStart, fldLen is $fldLen, condStart is >$condStart<",1);
    if ( $condStart ne "" ) { # condition was supplied
      if ( uc($condStart) eq "DELIMITED" ) { # delimited condition
	@delimArr = ();
	@delimArr = split($fldStart, $FileRecord);
	if ( defined($delimArr[$condLen]) ) {
  	  $testValue = $delimArr[$condLen];
        }
	else {
	  $testValue = "KCKCTESTFAILEDKCKC";
	  displayError("Conditional test on card $i in CTL File $ctlFile failed to identify a field - this field ($fldName) was not assigned a value");
	}
      }
      else {
        if ( $condStart > length($FileRecord)) { # field start outside record
          $testValue = "";
        }
        elsif ( $condStart + $condLen > length($FileRecord) ) { # field end outside record
          $testValue = substr($FileRecord, $fldStart);
        }
        else {
          $testValue = substr($FileRecord, $fldStart, $fldLen) ; 
        }
      }

      if ( $testValue eq "KCKCTESTFAILEDKCKC" ) {
        $setVar = "No";
      }
      else {
        if ( evaluateCondition($testValue . $condValue) eq "True" ) { # Check if the condition holds
          $setVar = "Yes";
	}
      }
    }
    else { # no condition so just set the variable
      $setVar = "Yes";
    }

    displayDebug("length(\$FileRecord) is " . length($FileRecord),1);
    if ( $setVar eq "Yes" ) {
      if ( uc($delimType) eq "FIXED" ) { # field is defined in fixed positions
        if ( $fldStart > length($FileRecord)) { # field start outside record
          $fldValue = "";
        }
        elsif ( $fldStart + $fldLen > length($FileRecord) ) { # field end outside record
          $fldValue = substr($FileRecord, $fldStart);
        }
        else {
          $fldValue = substr($FileRecord, $fldStart, $fldLen) ; 
        }
      }
      else { # it is a delimited field
	@delimArr = ();
	@delimArr = split($fldStart, $FileRecord);
	if ( defined($delimArr[$fldLen]) ) {
  	  $fldValue = $delimArr[$fldLen];
        }
	else {
	  $fldValue = "";
	  displayDebug("Delimited field on card $i in CTL File $ctlFile failed to identify a field - this field ($fldName) was nssigned the value blank",1);
	}
      }
      # and now just set the value for the variable ....
      displayDebug("Setting variable $fldName to a value of $fldValue",1);
      setVariable($fldName,$fldValue);
    } 
  }
}

sub loadFileCTL {

  my $i, $delimiter;
  my $ctlFile = shift;
  my $SKL_CTL_fullFileName = shift;

  # load a requested control file into the control file cache

  displayDebug("loading control file $ctlFile", 1);
  $SKL_CTLalreadyLoaded = "No";
  $SKL_CTLdontCache = "Yes"; # this variable set so no real caching will occur

  # Check to see if the controlfile is already loaded
  for ( $i = 0 ; $i < $SKL_maxCTLFiles ; $i++ ) {
    if ( $SKL_CTLFileName[$i] eq $ctlFile ) {
      # Control file is already loaded ...
      $SKL_CTLalreadyLoaded = "Yes";
      last;
    }
  }
  if ( $SKL_CTLalreadyLoaded eq "No" ) { # skeleton not found in storage
    # search for a free slot
    for ( $i = 0 ; $i < $SKL_maxCTLFiles ; $i++ ) {
      if ( $SKL_CTLFileInUse[$i] eq "No" ) {
        displayDebug("CTL File entry $i is not in use",1);
        last;
      }
    }
    if ( $SKL_CTLFileInUse[$i] eq "Yes" ) { # couldn't find a free entry
      displayError("Too many currently used Control Files - maximum of $SKL_maxCTLFiles exceeded");
      return;
    }
    else { # found a slot
      $SKL_CTLFileInUse[$i] = "Yes";
    }
  }
  # $i holds the slot to load ....
  if ( ( $SKL_CTLalreadyLoaded eq "No" ) || ( $SKL_CTLdontCache eq "Yes" ) ) {
    # load the control file again

    $SKL_CTLFileName[$i] = $ctlFile;
    $SKL_CTL_arrName = "SKL_CTLFileArray$i"; # SKL_CTL_arrName holds the array holding the current skeleton
    if ( !open (INCTL, "<$SKL_CTL_fullFileName") ) { # open has failed ...
      displayError("Open of $SKL_CTL_fullFileName has failed");
      $SKL_CTL_maxLines[$i] = 1;
      return;
    }
    else { # load it up
      $j = 0;
      while ( <INCTL> ) {
        chomp $_;
        # Validate the input
        # Should be of the form:
        # ---------------------------------------------------------------------------------------------------
        # FIXED,<fieldName>,<startPos>,<length>,<condition_pos>,<Condition_length>,<condition_Value>
        # or
        # DELIMITED,<fieldName>,<delimiter>,<occurrance>,<condition_pos>,<Condition_length>,<condition_Value>
        # or
        # DELIMITED,<fieldName>,<delimiter>,<occurrance>,DELIMITED,<occurrance>,<condition_Value>
        # ---------------------------------------------------------------------------------------------------
        #
        # The condition field indicates when the field will hold a value 
        # a sample record would be;
        # fixed,recKey,0,10,72,8,= 28
        #
        # delimited,recKey,:,1
        # Note: the first character after the FIXED or DELIMITED is the delimiter
        if ( uc($_) =~ /^FIXED/) { $delimiter = substr($_,5,1); }
        elsif ( uc($_) =~ /^DELIMITED/) { $delimiter = substr($_,9,1); }
        else { $delimiter = ',' } # delimiter defaults to comma

        @SKL_vals = split ($delimiter,$_,7);
        $$SKL_CTL_arrName[$j] = $delimiter . $SKL_vals[0]; # keep the def type (first char is now the delimiter)
        if ( " FIXED DELIMITED " =~ uc($SKL_vals[0]) ) { # first parm is correct
          
        }
        else { # parm is wrong ....
          displayError("CTL Card parameter should be FIXED or DELIMITED - will be ignored");
          next;
        }
        $$SKL_CTL_arrName[$j] = $$SKL_CTL_arrName[$j] . $delimiter . $SKL_vals[1]; # keep track of the field name
        # Validate Start pos
        my $tmpk = 0;
        if (defined($SKL_vals[2])) { 
          if ( uc($SKL_vals[0]) eq "FIXED" ) {
            $tmpk = $SKL_vals[2] * 1;
            if ( $tmpk ne $SKL_vals[2] ) { 
              displayError("Start Pos Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk);
            }
          }
          else { # Delimiter string
            $tmpk = $SKL_vals[2];
          }
        }
        else {
          displayError("Start Pos Field/Delimiter in card " . $j . " is missing - it will be adjusted to a numeric value of " . $tmpk);
        }
        $$SKL_CTL_arrName[$j] = $$SKL_CTL_arrName[$j] . $delimiter . $tmpk;

        # Validate Length/Position
        my $tmpk = 0;
        if (defined($SKL_vals[3])) { 
          $tmpk = $SKL_vals[3] * 1;
          if ( $tmpk ne $SKL_vals[3] ) { 
            displayError("Length Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk);
          }
        }
        else {
          displayError("Length Field in card " . $j . " is missing - it will be adjusted to a numeric value of " . $tmpk);
        }
        $$SKL_CTL_arrName[$j] = $$SKL_CTL_arrName[$j] . $delimiter . $tmpk;

        # Validate Condition Start
        my $tmpk = 0;
        if (defined($SKL_vals[4])) { 
          if ( uc($SKL_vals[4]) eq "DELIMITED" ) { # delimited condition
            $tmpk = $SKL_vals[4];
          }
          else { # Fixed location
            $tmpk = $SKL_vals[4] * 1;
            if ( $tmpk ne $SKL_vals[4] ) { 
              displayError("Condition Start Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk);
            }
          }
        }
        else {
          $tmpk = ""; # indicates that a condition was not supplied
          displayDebug("Condition Start Field in card " . $j . " is missing - it will be adjusted to a value of " . $tmpk,2);
        }
        $$SKL_CTL_arrName[$j] = $$SKL_CTL_arrName[$j] . $delimiter . $tmpk;

        if ( $tmpk ne "" ) { # i.e. Condition Start has been defined ....

          # Validate Condition Length 
          my $tmpk = 0;
          if (defined($SKL_vals[5])) { 
            $tmpk = $SKL_vals[5] * 1;
            if ( $tmpk ne $SKL_vals[5] ) { 
              displayError("Condition Length Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk);
            }
          }
          else {
            displayError("Condition Length Field in card " . $j . " is missing - it will be adjusted to a numeric value of " . $tmpk);
          }
          $$SKL_CTL_arrName[$j] = $$SKL_CTL_arrName[$j] . $delimiter . $tmpk;

          if ( defined($SKL_vals[6])) {
            $$SKL_CTL_arrName[$j] = $$SKL_CTL_arrName[$j] . $delimiter . $SKL_vals[6];
          }
          else {
            $$SKL_CTL_arrName[$j] = $$SKL_CTL_arrName[$j] . $delimiter;
          }
        }
        else { # Blank out the last bits
          $$SKL_CTL_arrName[$j] = $$SKL_CTL_arrName[$j] . $delimiter . $delimiter;
        }
        $j++;
      } # end of while
      $SKL_CTL_maxLines[$i] = $j - 1; 
    }
    close INCTL;

    if ( $SKL_debugLevel  > 0 ) {
      displayDebug("Max lines = $SKL_CTL_maxLines[$i] for $ctlFile", 1);
      for ( $k=0 ; $k <= $SKL_CTL_maxLines[$i] ; $k++) {
        displayDebug("CTL FILE - Line $k - $$SKL_CTL_arrName[$k]",1);
      }
    }
  }
}

sub setVariable {
  my $vName = shift;
  my $vValue = shift;

  $SKL_varArray{$vName} = $vValue;

  if ( $vName eq "SKL_SHOWSQL" ) {
    if ( uc($vValue) eq "YES" ) { 
      $SKL_ShowSQL = "Yes";
    }
    else {
      $SKL_ShowSQL = "No";
    }
  }

}

sub setBaseVariables {
  # Establish the variables that are always available to the skeletons

  if ( $^O eq "MSWin32") {
    setVariable("crlf", "\cM\cJ") ;
  }
  else {
    setVariable("crlf", "\cJ") ;
  }
  if ( defined($machine) ) { setVariable("machine", $machine); }
  if ( defined($SKL_viewQual) ) { setVariable("viewQual", $SKL_viewQual); }
  if ( defined($SKL_SID) ) { setVariable("SID", $SKL_SID); }
  if ( defined($SKL_TNS) ) { setVariable("TNS", $SKL_TNS); }
  if ( defined($SKL_userID) ) { setVariable("userID", $SKL_userID); }
  if ( defined($SKL_oraVers) ) { setVariable("oraVers", $SKL_oraVers); }
  $a = calcVersion();
  setVariable('calcVers', $a);
  $a = commonVersion();
  setVariable('commVers', $a);
  $a = skelVersion();
  setVariable('skelVers', $a);
}

# --------------------------------------------------------------------------------------
#
# The main process of the script - this is the called function. 
#
# It is called as processSkeleton('table.skl')
#
# If the file does not exist in the current working directory then the working directory 
# needs to be set as an environment variable called SKELDIR
#
# prior to being called the 'procLit' variable and the 'mode' should be set
# 'mode' defines how the result wll be returned :
#       STDOUT - output will be generated to STDOUT
#       FUNC   - output will be returned as the string returned from this sub
#
# --------------------------------------------------------------------------------------

sub processSkeleton {

  my $SKL_skel = shift; # the name of the skeleton to be processed MUST be passed
  my $parameter = shift; # these should be variable defs of the form A+1,B=2,C=3 etc

  #for ( $i = 0 ; $i <= length($parameter) ; $i++ ) {
  #  print "$i: " . substr($parameter, $i, 1) . "\n";
  #}

  $parameter =~ s/\\/&#92/g;

  my $i ;

  # Initialise some Constants

  $SKL_maxImbeds = 10;
  $SKL_maxCTLFiles = 10;
  $SKL_maxTables = 15;
  $SKL_maxConnections = 15;
  $SKL_termChar = " ()!,.;'~=<>+\"-/\\";
  $SKL_maxDefs = 80;
  $SKL_maxEnvStack = 30;
  $SKL_returnString = "";

  # Initialise some variables

  for ( $i = 0 ; $i < $SKL_maxTables ; $i++ ) { 
    $SKL_TableInUse[$i] = "No"; 
  }
  for ( $i = 0 ; $i < $SKL_maxConnections ; $i++ ) {
    $SKL_connectionInUse[$i] = "No";
    $SKL_connectionName[$i] = "";
    $SKL_connection[$i] = "";
  }
  for ( $i = 0 ; $i < $SKL_maxTables ; $i++ ) { 
    $SKL_rowNumber[$i] = -1; 
    $SKL_connOK[$i] = "No";
  }
  for ( $i = 0 ; $i < $SKL_maxCTLFiles ; $i++ ) { 
    $SKL_CTLFileName[$i] = ""; 
    $SKL_CTLFileInUse[$i] = "No"; 
  }
  for ( $i = 0 ; $i < $SKL_maxImbeds ; $i++ ) { 
    $SKL_imbedName[$i] = ""; 
    $SKL_imbedInUse[$i] = "No"; 
    $SKL_currentImbedLine[$i] = 1; 
  }
  $SKL_currentTable = -1;

  # prior to being called the 'procLit' variable and the 'mode' should be set
  # 'mode' defines how the result wll be returned 

  displayStatus($procLit);

  if ( $SKL_currentTable > -1) { # not a clean start ....
    displayError("Current Table is starting out at $SKL_currentTable");
  }

  # Initialise some variables before processing starts

  $SKL_DOFmessageDisplayed = "No";
  $SKL_ENDDOFmessageDisplayed = "No";
  $SKL_UnknownCardMessageDisplayed = "No";
  $SKL_MaxDDLLineLength= 0;

  # set up generic variables to be used by skeleton

  @SKL_varArray = (); # Clear out variable array
  setBaseVariables;

  # Variables for table processing

  @SKL_tabRef = ();    # Array of )DOT table reference literals
  @SKL_cursor = ();    # Array of cursors (associative)
  @SKL_cursorRef = (); # Array of generated Cursors names (Used as an index into $SKEL_cursors)
  @SKL_connRef = ();   # Array of database connections
  @SKL_tabName = ();   # Array of tables that are indicated on )DOT statements
  @SKL_tabWhere = ();  # Array of where clauses that are indicated on )DOT statements
  @SKL_tabDOT = ();

  # set up any passed parameters

  $SKL_ShowSQL = "No";
  my @fsplit = split(",",$parameter);
  my $tuple;

  foreach $tuple (@fsplit) {
    if ( $tuple =~ /=/ ) {
      my ($var,$val) = split("=",$tuple);
      displayDebug("Parameter $var has a value of $val",2);
      if ( $var eq "SKL_SHOWSQL" ) {
        $SKL_ShowSQL = "Yes";
      }
      else { # Set internal variable
        if ( trim($val) ne "" ) {
          setVariable($var, $val);
        }
      }
    }
    else { # parameter is just a flag
      if ( $tuple eq "SKL_SHOWSQL" ) {
        $SKL_ShowSQL = "Yes";
      }
      elsif ( uc($tuple) eq "VERSIONS" ) {
        $a = calcVersion();
        print "$a\n";
        $a = commonVersion();
        print "$a\n";
        $a = skelVersion();
        print "$a\n";
      }
    }
  }

  if ( $^O eq "MSWin32") {
    $SKL_dirSep = "\\";
  }
  else {
    $SKL_dirSep = "/";
  }

  $SKL_SEL_resumeLevel = 0;
  $SKL_DOT_resumeLevel = 0;
  $SKL_DOT_EmptyLevel = 0;
  $SKL_cPos = 0;
  $SKL_currentImbed = -1;
  $SKL_MaxImbed = -1;
  $SKL_gotoENDSEL = "No";
  $SKL_endOfCursor = "Yes";
  $SKL_selSkipCards = "No";
  $SKL_DOTSkipCards = "No";
  $SKL_SELCount = 0;
  $SKL_DOTCount = 0;
  $SKL_skipCount = 0;
  $SKL_currentTable = -1;
  $SKL_loadingImbed = "No";
  $SKL_outputLineCount = 0;
  $SKL_DOF_ignoreRecord = "No";
  $SKL_caseSensitiveColumns = "No";
  $SKL_traceHOLD = 0;

  # FTAB Variables

  $SKL_FTAB_cursor = "";
  $SKL_FTAB_database = "";
  $SKL_FTAB_Select = "";
  $SKL_FTAB_Cols = "";
  $SKL_FTAB_rowNumber = "";

  # Load up the initial skeleton

  loadSkel($SKL_skel); 

  # main processing loop - loops through the current skeleton

  while ( $SKL_currentImbed > -1 ) {
  
    displayDebug ("Skeleton $SKL_imbedName[$SKL_currentImbed] Max Lines = $SKL_maxLines[$SKL_currentImbed]", 1);
    while ( $SKL_currentImbedLine[$SKL_currentImbed] < $SKL_maxLines[$SKL_currentImbed] ) {
      
      displayDebug ("in loop= $SKL_currentImbedLine[$SKL_currentImbed], $$SKL_arrName[$SKL_currentImbedLine[$SKL_currentImbed]]", 2);
      if ( substr( $$SKL_arrName[$SKL_currentImbedLine[$SKL_currentImbed]],0,1) eq ')' )  { # it is a control card
        processControlCard($SKL_currentImbedLine[$SKL_currentImbed]);
      }
      else {
        if ( ( $SKL_selSkipCards eq "No" ) && ( $SKL_DOTSkipCards eq "No" ) ) { # not skipping cards
          processLine($SKL_currentImbedLine[$SKL_currentImbed]);
        } 
      }

      $SKL_currentImbedLine[$SKL_currentImbed]++;
      displayDebug("End of while loop : Current Line = $SKL_currentImbedLine[$SKL_currentImbed] , Max Lines =  $SKL_maxLines[$SKL_currentImbed]",2);

    }

    # retrieve the skeleton that was in use prior to the last )IMBED
    $SKL_currentImbed = pullImbed($SKL_currentImbed); 
    $SKL_arrName = "SKL_imbedArray$SKL_currentImbed";

    if ( $SKL_currentImbed > -1 ) { # still more to do
      # Check if )SELs were balanced in the last skeleton

      if ( $SKL_imbedStack{$SKL_currentImbed} != $SKL_SELCount ) {
        my $callLine = $SKL_currentImbedLine[$SKL_currentImbed] - 1;
        displayError ("\)SEL .. \)ENDSEL count not balanced in IMBED $SKL_lastImbedName");
        displayError ("On entry to the imbed the count was $SKL_imbedStack{$SKL_currentImbed}");
        displayError ("while on exit it was $SKL_SELCount. The IMBED was called on line $callLine.");
        displayError ("It is likely that this generation will not have completed correctly.");
        $SKL_SELCount = $SKL_imbedStack{$SKL_currentImbed}; # reset the count to what it should be 
      }

    }
 
  }  # end of $SKL_currentImbed > -1

  if ( $SKL_DOTCount > 0 ) { displayError ( "\)DOT not terminated within skelton"); }
  if ( $SKL_SELCount > 0 ) { displayError ( "\)SEL not terminated within skelton"); }

  return $SKL_returnString;
  
}

1;
