#!/usr/bin/perl
# --------------------------------------------------------------------
# commonFunctions.pl
#
# $Id: commonFunctions.pl,v 1.16 2013/07/02 02:05:48 db2admin Exp db2admin $
#
# Description:
# Stub cotaining common code.
#   Subroutines included:
#     getOpt
#     trim
#     rtrim
#     ltrim
#     date
#
# Usage:
#   trim()
#     $x = trim($y) # strip blanks from the start and end of a string
#
#   ltrim()
#     $x = ltrim($y) # strip blanks from the start of a string
#
#   rtrim()
#     $x = rtrim($y) # strip blanks from the end of a string
#
#   date()
#     Usage: date [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]
#         and it will return an array containg the following elements:
#              $DD,$MM,$YY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW
#
#              i.e. a call of @T = date("DATE\:20100918");
#
#                  $T[0] = 18     	(day of month)
#                  $T[1] = 09     	(month number)
#                  $T[2] = 2010   	(year)
#                  $T[3] = th     	(suffix for day number - st, nd, rd or th)
#                  $T[4] = September 	(month name)
#                  $T[5] = 16696	(number of days since 1/1/1965)
#                  $T[6] = 1965		(base date from which calcs are done)
#                  $T[7] = N		(Is it end of month? (Y or N))
#                  $T[8] = N		(Is it end of year? (Y or N))
#                  $T[9] = N		(Is it end of financial year? (Y or N))
#                  $T[10] = N		(Is it the beginning of the month? (Y or N))
#                  $T[11] = SAT 	(Day of Week)
#                  $T[12] = return str 	(Returned error string if any - a value of '' implies no errors)
# 
#     It can also be used to identify a date x days from a set base year. So to 
#     work out what day Julian date 10200 is we could use the function as :
#
#              @T = date("200 BASE:2010")
#                   0 = 19
#                   1 = 07
#                   2 = 2010
#                   3 = th
#                   4 = July
#                   5 = 200
#                   6 = 2010
#                   7 = N
#                   8 = N
#                   9 = N
#                  10 = N
#                  11 = TUE
# 
#     As well it can be used to identify the number of days between 2 date by processing 
#     each date and then substracting their $T[5] elements.
#
#   getOpt()
#  
#   A standard use of getOpt would look like:
#
#   # Set up the enironment to include the commonFunctions module ...
#
#   if ( $^O eq "MSWin32") {
#     $machine = `hostname`;
#     $OS = "Windows";
#     use lib 'c:\udbdba\scripts';
#   }
#   else {
#     $machine = `uname -n`;
#     $machine_info = `uname -a`;
#     @mach_info = split(/\s+/,$machine_info);
#     $OS = $mach_info[0] . " " . $mach_info[2];
#     BEGIN {
#       $scriptDir = "c:\udbdba\scripts";
#       $tmp = rindex($0,'/');
#       if ($tmp > -1) {
#         $scriptDir = substr($0,0,$tmp+1)  ;
#       }
#     }
#     use lib "$scriptDir";
#   }
#   require "commonFunctions.pl";
#
#   # Set default values for variables
#
#   $silent = "No";
#
#   # ----------------------------------------------------
#   # -- Start of Parameter Section
#   # ----------------------------------------------------
#
#   # Initialise vars for getOpt ....
#
#   $getOpt_prm = 0;
#   $getOpt_opt = ":?hsvtT:S:d:w";    # set up the valid parm values
#
#   $getOpt_optName = "";
#   $getOpt_optValue = "";
#
#   while ( getOpt($getOpt_opt) ) {
#     if (($getOpt_optName eq "h") || ($getOpt_optName eq "?") )  {
#       usage ("");   # call the usage routine display help
#       exit;
#     }
#     elsif (($getOpt_optName eq "s") )  { # turn on silent
#       $silent = "Yes";
#     }
#     elsif (($getOpt_optName eq "v"))  {  # set debug Level
#       $debugLevel++;
#       if ( $silent ne "Yes") {
#         print STDERR "Debug level now set to $debugLevel\n";
#       }
#     }
#     .
#     ..... insert other parameter option activities here
#     .
#     elsif ( $getOpt_optName eq ":" ) {
#       usage ("Parameter $getOpt_optValue requires a parameter");
#       exit;
#     }
#     else { # handle other entered values ....
#       if ( $parameter eq "" ) { # assume parameters if nothing is indicated
#         $directory = $getOpt_optValue;
#         if ( $silent ne "Yes") {
#           print STDERR "Directory $getOpt_optValue will be processed\n";
#         }
#       }
#       else {
#         usage ("Parameter $getOpt_optValue is invalid");
#         exit;
#       }
#     }
#   }
#
#   # ----------------------------------------------------
#   # -- End of Parameter Section
#   # ----------------------------------------------------
#
# $Name:  $
#
# ChangeLog:
# $Log: commonFunctions.pl,v $
# Revision 1.16  2013/07/02 02:05:48  db2admin
# modify debug statements to cope with web and screen output
#
# Revision 1.15  2013/07/01 05:31:46  db2admin
# set the option name properly for web parameters
#
# Revision 1.14  2013/07/01 04:36:11  db2admin
# adjust parameter sub getOpt to cope with web like parameters A=B
# improved comments a bit
#
# Revision 1.13  2012/04/03 06:47:29  db2admin
# Add in version function
#
# Revision 1.12  2012/03/06 00:39:15  db2admin
# get rid of parameter checking on the functions
#
# Revision 1.11  2011/01/04 03:22:30  db2admin
# Modify date() to return information on errors rather than just die'ing
#
# Revision 1.10  2010/01/19 00:49:11  db2admin
# Add in more comments on uses of the date function
#
# Revision 1.9  2010/01/04 02:31:35  db2admin
# Correct formatting of usage information
#
# Revision 1.8  2010/01/04 02:27:31  db2admin
# improve usage information
#
# Revision 1.7  2009/04/27 03:43:26  db2admin
# updated date() routine to latest version
# (this version includes EOM, EOY, EOFY, BOM and DOW values)
#
# Revision 1.6  2009/04/26 23:17:05  db2admin
# Add in date() function
#
# Revision 1.5  2009/01/09 02:25:10  db2admin
# this time initialise it to a numeric
#
# Revision 1.4  2009/01/09 02:22:06  db2admin
# initialise debug variable
#
# Revision 1.3  2008/11/24 22:23:37  m08802
# Add in support for --long-file-names
#
# Revision 1.2  2008/11/06 02:27:35  db2admin
# Comment out sample function calling code
#
# Revision 1.1  2008/11/05 23:42:02  db2admin
# Initial revision
#
#
# --------------------------------------------------------------------

sub commonVersion {

  $ID = '$Id: commonFunctions.pl,v 1.16 2013/07/02 02:05:48 db2admin Exp db2admin $';
  @V = split(/ /,$ID);
  $nameStr=$V[1];
  ($name,$x) = split(",",$nameStr);
  $Version=$V[2];
  $Changed="$V[3] $V[4]";

  return "$name ($Version)  Last Changed on $Changed (UTC)";

}

sub getOpt() {

  my $getOpt_diagLevel = 0;
  my $case_insens = "";
  my $getOpt_parmInd = ":";
  my $webParmSet = "";   # initially set no web parm

  if ( ! defined($getOpt_web) ) { 
    $getOpt_web = "N";
  }

  $getOpt_numKeyWords=-1;
  $getOpt_numNonKeyWords=-1;

  if ( $#_ != 0 ) {
    print "Not enough parameters passed\n";
    return 0;
  }

  # Preparse the input parameters to process concatenated parms 


  if ( $#PARGV == -1 ) { # Arguments havent been pre-processed yet
    # This is executed only for the first call
    for ($i=0 ; $i <= $#ARGV ; $i++ ) {        # loop through the arguments
      if ( substr($ARGV[$i],0,2) eq "--" ) {   # if it is an extended parameter (begins with --)
        $PARGV[$#PARGV + 1] = $ARGV[$i];
      }
      elsif ( substr($ARGV[$i],0,1) eq "-" ) { # if it starts with a "-"
        # then split up the parameters into separate parms .....
        # (but only if it is non-web and there is no = sign)
        if ( ( $getOpt_web eq "Y" ) && ( index($ARGV[$i],'=') > -1 ) ) { 
          # do nothing to the parameter
          $PARGV[$#PARGV + 1] = $ARGV[$i];
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

  @getOpt_OptArr = split(/\|/,$_[0]);  # $_[0] is the single character parameters - split by |
  # Gather the 2nd and subsequent parameters
  $getOpt_parmInd = substr($getOpt_OptArr[0],0,1); # establish the parm indicator character
  for ($i=1 ; $i <= $#getOpt_OptArr ; $i++ ) { # Process the  multi character options
    if ( substr($getOpt_OptArr[$i],0, 2) eq "--" ) {   # If it is an extended parameter
      if ( substr($getOpt_OptArr[$i],2, 1) eq "^" ) {  # If it is flagged case insensitive
        $getOpt_tmpKW = uc(substr($getOpt_OptArr[$i],3));
        $case_insens = "^";
      }
      else { # it is not case insensitive
        $getOpt_tmpKW = substr($getOpt_OptArr[$i],2);
        $case_insens = " ";
      }
      $getOpt_KWLen = length($getOpt_tmpKW);
      if ( substr($getOpt_tmpKW,$getOpt_KWLen-1,1) eq $getOpt_parmInd ) { # it requires a parameter
        $getOpt_tmpKW = substr($getOpt_tmpKW,0,$getOpt_KWLen-1);          # get rid of the indicator
        $getOpt_valid_parms{$getOpt_tmpKW} = ":";                         # non blank indicates it requires a parameter
      }
      else { # it doesn't require a parameter
        $getOpt_valid_parms{$getOpt_tmpKW} = "";                          # flag it as case sensitive
      }
      $getOpt_caseinsens{$getOpt_tmpKW} = $case_insens;
    }
    else { # process it as a keyword
      $getOpt_numKeyWords++;
      $getOpt_KWLen = length($getOpt_OptArr[$i]);
      if ( substr($getOpt_OptArr[$i],0, 1) eq "^" ) { # first char may be flag for case insensitive
        $getOpt_tmpKW = substr($getOpt_OptArr[$i],1); # parameter starts after 1st char
        $KeyWords{$getOpt_tmpKW} = "^";               # mark it as case insensitive
      }
      else {
        $KeyWords{$getOpt_OptArr[$i]} = "";           # mark it as case sensitive
      }
    }
  }

  # Process the 1st parameter separately ....
  $getOpt_schar = 0;
  if (! defined($getOpt_valid_parms{'####'}) ) { # Has this parm already been processed?
    $getOpt_valid_parms{'####'} = "";            # flag that we have processed the parms
    $getOpt_silent="N";
    if ( substr($getOpt_OptArr[0],0,1) eq ":" ) {   # getOpt_silent does nothing as yet
      $getOpt_silent="Y";
      $getOpt_schar++;
    }
    # now process each of the character options .....
    while ( $getOpt_schar <= length($getOpt_OptArr[0])-1 ) {
      $getOpt_prmChar = substr($getOpt_OptArr[0],$getOpt_schar,1);   # set option
      $getOpt_valid_parms{$getOpt_prmChar} = "";                     # set it up as a valid option without parm
      $getOpt_caseinsens{$getOpt_prmChar} = "";                      # set it up as case sensitive (note all single char options are case sensitive)
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
    print "================================================<BR>\n";
    print "\$\#ARGV=$#ARGV<BR>\n";
    for ($i=0 ; $i <= $#ARGV ; $i++ ) {
      print "ARGS $i>$ARGV[$i]<BR>\n";
    }
    print "\$\#PARGV=$#PARGV<BR>\n";
    for ($i=0 ; $i <= $#PARGV ; $i++ ) {
      print "PARGS $i>$PARGV[$i]<BR>\n";
    }
    print "\$\#=$#_<BR>\n";
    for ($i=0 ; $i <= $#_ ; $i++ ) {
      print "PRM $i>$_[$i]<BR>\n";
    }
    if (defined($PARGV[$getOpt_prm]) ) {
      print "Current Parm:$PARGV[$getOpt_prm]<BR>\n";
    }
    print "\$getOpt_valid_parms ....<BR>\n";
    #foreach $key (sort by_key keys %getOpt_valid_parms ) {
    #  print "$key = $getOpt_valid_parms{$key}<BR>\n";
    #}
    print "================================================<BR>\n";
  }

  # Now start processing the actual parameters

  while ($getOpt_prm_flag ne "Y") {                                 # We are still looking
    if ( defined($PARGV[$getOpt_prm]) ) {                           # if something exists
      if ( substr($PARGV[$getOpt_prm],0,1) eq "-") {                # if it is a parameter (ie starts with a dash)
        $getOpt_prmValue = trim(substr("$PARGV[$getOpt_prm]  ",1)); # remove the first character
        if ( substr($getOpt_prmValue,0,1) eq "-" ) {                # if it is an extended parameter ....
          $getOpt_prmValue = trim(substr("$getOpt_prmValue  ",1));  # remove the first char again
        }
        # and now it gets interesting ......
        # If we are in HTML-land (ie $getOpt_web is "Y" ) then we can also also have parameters of
        # the form -p=A -d=database so a single entry may actually contain the option and
        # the parameter

        if ( $getOpt_web eq "Y" ) {                      # must cope with web parameter format as well
          if ( index($getOpt_prmValue,'=') > -1 ) {      # the parm contains an = sign
            @webparm  = split('=',$getOpt_prmValue);     # split it on the = sign
            if ( $getOpt_diagLevel > 0 ) {
              print "web initial: $getOpt_prmValue<BR>\n";
              print "web option: $webparm[0] parm: $webparm[1]<BR>\n";
            }
            $getOpt_prmValue = $webparm[0];              # establish a new parameter value
            $webParmSet = $webparm[1];                   # set the parameter value
          }
        }

        if ( (defined($getOpt_valid_parms{$getOpt_prmValue} ) )  ||
             ( (defined($getOpt_valid_parms{uc($getOpt_prmValue)} )) && ($getOpt_caseinsens{uc($getOpt_prmValue)} eq "^") )
           ) {                                                      # is it a valid parameter?
          if ($getOpt_caseinsens{uc($getOpt_prmValue)} eq "^" ) {
            $getOpt_prmValue = uc($getOpt_prmValue);                # if it is case insensitive then make the option upper case
          }
          if ( $getOpt_valid_parms{$getOpt_prmValue} eq ":" ) {     # is a parameter required?
            if ( $webParmSet ne "" ) {                              # getOpt_web set and a parm has already been found
              $getOpt_optName = $getOpt_prmValue;                   # set the returned option name
              $getOpt_optValue = $webParmSet;                       # set the returned parameter
              $getOpt_prm_flag = "Y";
            }
            else { # normal space delimited parameters
              $getOpt_optName = $getOpt_prmValue;                     # set the option name
              if ( defined($PARGV[$getOpt_prm+1] ) ) {
                if ( substr($PARGV[$getOpt_prm+1],0,1) eq "-" ) {     # check to see if it is another parameter
                  $getOpt_optValue = $getOpt_prmValue;                # Pass back the option name as the parameter 
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
                $getOpt_optValue = $getOpt_prmValue;                  # Pass back the option name as the parameter
                $getOpt_optName = ":";                                # name set to : to indicate error
                $getOpt_prm_flag = "Y";
              }
            }
          }
          else { # Parameter is not required
            $getOpt_optValue = "";
            $getOpt_optName = $getOpt_prmValue;
            $getOpt_prm_flag = "Y";
          }
        }
        else { # it is not a valid parameter (or at least it wasn't defined
          $getOpt_optName = "*";
          $getOpt_optValue = $getOpt_prmValue;
          $getOpt_prm_flag = "Y";
        }
      }
      else { # is it a keyword? (no leading -)
        if ( defined( $KeyWords{$PARGV[$getOpt_prm]} ) ) { # it is a keyword and matches on case
          $getOpt_optName = uc($PARGV[$getOpt_prm]);
          $getOpt_optValue = $PARGV[$getOpt_prm];
          $getOpt_prm_flag = "Y";
        }
        elsif ( defined( $KeyWords{uc($PARGV[$getOpt_prm])} ) ) { # it is a keyword and matches on upper case
          if ( $KeyWords{uc($PARGV[$getOpt_prm])} eq "^" ) { # case insensitive so all ok ....
            $getOpt_optName = uc($PARGV[$getOpt_prm]);
            $getOpt_optValue = $PARGV[$getOpt_prm];
            $getOpt_prm_flag = "Y";
          }
          else { # must match on case
            $getOpt_optName = "*";
            $getOpt_optValue = $PARGV[$getOpt_prm];
            $getOpt_prm_flag = "Y";
          }
        }
        else { # no then just add treat it as an unknown parameter
          $getOpt_optName = "*";
          $getOpt_optValue = $PARGV[$getOpt_prm];
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
  return 1;
}

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
# date - function to provide date related functions 
# -----------------------------------------------------------------

sub date {

  $Base = "1965";
  $GenDays = "N";
  $EOY  = "N"; # End of Year
  $EOFY = "N"; # End of Financial Year
  $EOM  = "N"; # End of Month
  $BOM  = "N"; # Beginning of Month Flag
  $EDD = '';
  $EMM = '';
  $EYY = '';
  $Suff = '';
  $Month = '';
  $NumDays = '';
  $DOW = '';
  $BaseDate = '';

  # set up tables as necessary ...
  if (defined($monthname{1})) { # do nothing
  }
  else { # set up the tables ...
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
  }
  $DOW19650101 = "FRI";
  @DOWliterals = ("SUN","MON","TUE","WED","THU","FRI","SAT");

  if ($#_ == -1) {
    $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy] ";
    return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
  }

  $prmInput = @_;
  @parms = split(/ /,"@_");
  $HoldDays = $parms[0];

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
    # print "NumDays=$NumDays Year=$Year LeapYear=$LeapYear Days in Year=$DaysInYear\n";

    # Adjust date for the partial year

    $Year = $Year - 1;
    $NumDays = $NumDays + $DaysInYear;

    # Adjust the array if it is a leap year
    $Year = substr("0" . $Year, length($Year)-1,2);
    $Tyear = "$Century$Year";
    $Rem = $Tyear % 4;
    if ( $Rem == 0 ) {
      $Rem2 = $Tyear % 400;
      if ( $Rem2 != 0 ) {
        $monthDays[2]++ ;
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

    $i = 12;
    for ($i ; $i > 0 ; $i-- ) {
      if ($NumDays > $cumDays[$i]) {
        $j = $i -1;
        $MM = $i;
        $DD = $NumDays - $cumDays[$i];
        last;
      }
    }

    $Month = $monthName[$MM];

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

    $tmp = ($HoldDays+5) % 7;
    $DOW = $DOWliterals[$tmp];

    return ($DD,$MM,$Century . $Year,$Suff,$Month,$HoldDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,'');
    #print "Date is $DD$Suff of $Month, $Century$Year (NumDays=$HoldDays)\n";

  }
  else { # a date of the formet DATE: or DATE= was provided $Date holds that value
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
     # print "NumDays=$NumDays Year=$Year LeapYear=$LeapYear Days in Year=$DaysInYear\n";
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

    $Month = $monthName[$EMM];
    $NumDays = $NumDays + $cumDays[$EMM] + $EDD;

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

    return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,'');
    #print "Date of $Date ($EDD$Suff of $Month, $EYY) has a value of $NumDays\n";

  }
}

1;
