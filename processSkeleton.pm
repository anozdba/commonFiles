#!/usr/bin/perl
# --------------------------------------------------------------------
# processSkeleton.pm
#
# $Id: processSkeleton.pm,v 1.127 2018/12/14 04:09:41 db2admin Exp db2admin $
#
# Description:
# Script to process a skeleton
#
# Usage:
#
#   # include the routine and define all of the exported variables
#   use processSkeleton qw(processSkeleton skelVersion formatSQL $skelDebugLevel $skelCache $ctlCache $execCtlCache testRoutine $testRoutines $outputMode $skelShowSQL $DBIModule $skelDebugModules $skelDelimiter $skelVerboseSQLErrors);
#
#   # set the output type (can be HTTP, HTTPFILE or STDOUT)
#   $outputMode = "HTTP";
#   
#   # establish the database type to be connected to
#   $DBIModule = "DB2";
#   
#   # call processSkeleton to generate the output
#   my $a = processSkeleton('skeletons/DBR_AllocatedSpace.skl',"SKL_SHOWSQL=YES");
#   
#   This is a subroutine and not a stand alone program - it must be called from
#   another program
#
# NOTE: $skelCache, $ctlCache and $execCtlCache are all flags indicating that entries are to be cached
#
# $Name:  $ 
#
# ChangeLog:
#
# $Log: processSkeleton.pm,v $
# Revision 1.127  2018/12/14 04:09:41  db2admin
# update LASTFDOFCount progressively as the file is read
#
# Revision 1.126  2018/12/14 01:09:19  db2admin
# 1. Added in )CONVERTHEADERS processing to convert FDOF column names into more friendly headers
# 2. Added in LEAVEHEADERS processing to turn off CONVERTHEADER processing
# 3. Added in )SELECTCOND processing to provide record selection for )FDOF processing
# 4. Added in )CLEARSELECTCOND processing to remove record selection in FDOF processing
# 5. Altered the processing of CELLSTYLE and ROWSTYLE statements to ensure that they are
#    evaluated in the order that they are encountered in the skeleton file
#
# Revision 1.125  2018/12/12 04:01:55  db2admin
# add STYLE information from )ROWSTYLE and )CELLSTYLE into the FDOF statement
#
# Revision 1.124  2018/12/11 00:35:26  db2admin
# 1. Add in processing for )CELLSTYPE to define a style for a cell (<TD> element)
# 2. Add in processing for )ROWSTYLE to define a style for a row (<TR> element)
# 3. Modify )FTAB processing to utilise the styles specified by the new cards if applicable
#
# Revision 1.123  2018/12/03 21:03:02  db2admin
# add in scope dump to )DEBUG statement
#
# Revision 1.122  2018/12/03 03:48:42  db2admin
# ensure scope is always set as lower case
#
# Revision 1.121  2018/11/30 05:03:21  db2admin
# add in code to ensure that scope variables are not removed until the last referencing skeleton is closed
#
# Revision 1.120  2018/11/30 01:03:33  db2admin
# allow a scope label to be applied in for the )SET and )ASET commands
# so a valid statement could now be:
#    )SET main.var1 = 'test'
# which will set the variable var1 in scope main
#
# Revision 1.119  2018/11/29 01:18:11  db2admin
# add in code to allow imbeded skeletons to reference variables in calling skeletons
#
# Revision 1.118  2018/11/22 02:57:11  db2admin
# dont strip off quotes from supplied imbed name if it is the only supplied parameter
#
# Revision 1.117  2018/11/22 02:36:48  db2admin
# Add in code to allow IMBED to store their variables in a separate scope.
# The scope will be cleared when the IMBED is finished
# Possibly a requirement to be able to override scope for things like LAST_ERROR (but not sure)
#
# Revision 1.116  2018/11/20 22:33:57  db2admin
# establish a 'global' scope for all variables
#
# Revision 1.115  2018/11/20 22:11:00  db2admin
# reformat code to isolate variable setting and retrieval in preparation for scoping variables
#
# Revision 1.114  2018/11/14 00:13:37  db2admin
# Add in )VHEAD statement to define vertical headings in FTAB displays
# Reconfigured code to isolate the generation and printing of headers (initially for FTAB)
#
# Revision 1.113  2018/11/11 20:59:28  db2admin
# ignore imbed statements with blank arguments
#
# Revision 1.112  2018/10/30 23:46:31  db2admin
# 1. Correct a bug in testRoutine which meant that output was lost if outputMode was changed in the test skeleton
# 2. Add in unique IDs for all of the automatically created table objects (to allow tables to be individually identified in CSS)
# 3. Allow the use of the following variables (reflecting the current internal variable values):
#    SKELDELIMITER SKELDEBUGMODULES SKELSHOWSQL SKELVERBOSESQLERRORS OUTPUTMODE
#    SKELMAXOUTPUT SKELMAXROWS SKELMAXTABLEOUT SKELDEBUGLEVEL TESTROUTINES INDEXCASEINSENSITIVE
# 4. Rewrite the routine to allow the setting of vaiables from internal variables to ease
#    maintenance
# 5. Allow outputMode to be set on the )SET or )ASET commands
#
# Revision 1.111  2018/10/26 04:12:30  db2admin
# Various modifications:
# 1. make indexing optionally case insensitive (defaults to acse insensitive)
# 2. add in coding to allow skeleton updating of passed in variables
# 3. Allow the use of literals to define index keys (LOWER_ALPHABET, UPPER_ALPHABET and NUMBERS)
# 4. Add )INDEXTEST command to allow the manual generation of index entries (good for use in )DOT)
# 5. Add in )INDEXCLEAR command to dump out all unused index entries
# 6. Add in auto-indexing to FTAB
#
# Revision 1.110  2018/10/23 21:04:42  db2admin
# initial )INDEX code implementation (not fully implemented)
#
# Revision 1.109  2018/10/16 22:30:13  db2admin
# add in the ability to call the PERLDBI ODBC module
#
# Revision 1.108  2018/10/10 02:30:03  db2admin
# correct bug in assign
#
# Revision 1.107  2018/10/10 02:27:05  db2admin
# create a synonym for ASET called ASSIGN
#
# Revision 1.106  2018/10/09 21:43:52  db2admin
# A couple of changes:
# 1. Added in a new statement )ASET. Same as )SET but no statement evaluation is done
# 2. Corrected issued with a variable being preceded by a backslash
#
# Revision 1.105  2018/10/09 03:04:19  db2admin
# 1. add in new SPLIT function
# )FUNC SPLIT x = "string" "delimiter" <element to return> <max elements>
# 2. Modify INSTR function to include start pos or Occurence
# )FUNX INSTR x = 'string to search for> <string to search in> [<start pos>|OCC:<occurence>]
#
# Revision 1.104  2018/09/06 08:27:04  db2admin
# 1. Correct an issue looping in DOF definitions when wrong control type entered
# 2. Allow regex control characters to be entered as delimiters in CTL records
#
# Revision 1.103  2018/08/27 04:17:47  db2admin
# correct bug in variable substitution
#
# Revision 1.102  2018/08/26 23:50:15  db2admin
# correct issue when XDOT doesn't have enough parameters
#
# Revision 1.101  2018/08/24 05:56:14  db2admin
# 1. Add in UPPER and LOWER functions
# 2. Correct issue with )SEL/)ENDSEL matching counts
#
# Revision 1.100  2018/08/15 06:15:05  db2admin
# Automatically calulate field length for FIXED CTL records where it has been ommitted
#
# Revision 1.99  2018/08/15 02:22:28  db2admin
# add in INLINE CTL cards to )PARSE, )FDOF, )DOEXEC
# correct bug that occurs when using )LEAVE within a )SEL within a )DOEXEC
#
# Revision 1.98  2018/08/14 22:01:20  db2admin
# add inline CTL cards to the )DOF statement
#
# Revision 1.97  2018/08/14 00:44:44  db2admin
# correct comments around NOT_EMPTY function
#
# Revision 1.96  2018/08/13 22:41:07  db2admin
# when reading in INLINE code preserve the CRLF's. This will allow
# inline comments to be processed correctly
#
# Revision 1.95  2018/08/07 22:10:41  db2admin
# 1. adjust the )SEL/)ENDSEL balancing count processing
#
# Revision 1.94  2018/08/06 05:49:14  db2admin
# add in the ability to put multi line SQL in the skeleton
#
# Revision 1.93  2018/08/06 01:02:45  db2admin
# move check for )DOT/)XDOT existenece to after the check for )SEL to
# ensure that the )ENDDOTs within a failed )SEL aren't flagged as
# orphan
#
# Revision 1.92  2018/06/14 00:04:39  db2admin
# correct a bug in file name scanning
#
# Revision 1.91  2018/06/06 00:11:46  db2admin
# 1. Add in new )FILE command
# 2. alter )DOF command to populate DOF_ variables with file information
#
# Revision 1.90  2018/05/29 04:38:03  db2admin
# add in EMPTY and NOT_EMPTY functions to test variables for content
#
# Revision 1.89  2018/05/21 05:42:56  db2admin
# add in )RESETOUTPUT
# add in message on )STOP statement
#
# Revision 1.88  2018/05/21 04:29:51  db2admin
# add in new commands )STOP and )EXIT
# )STOP will halt the skeleton immediately
# )EXIT will either skip to the end of the current imbed or exit the skeleton if no imbed is found
#
# Revision 1.87  2018/05/10 23:33:07  db2admin
# add in )NEXT statement definition to skip tothe next loop iteration
#
# Revision 1.86  2018/05/10 07:48:39  db2admin
# Add in intial )LAST or )LEAVE processing - not tested a lot
#
# Revision 1.85  2018/05/09 04:34:12  db2admin
# clean up file processing code and remove duplication
# close the file after being processed
#
# Revision 1.84  2018/04/30 21:55:51  db2admin
# expand the definition of a numeric field type and make processing more consistent
#
# Revision 1.83  2018/04/24 02:06:35  db2admin
# add in variables to manage returning error messages back to the guiding
# skeleton - :lastError and :lastStatementError - lastStatementError is
# cleared for every control statement
#
# Revision 1.82  2018/04/23 23:41:34  db2admin
# comment out the 'substituteVariables' call in evaluateCondition because the substitutions
# were being done twice. This was causing any escaped :'s to be treated as variables
# as the escape character is removed by the time the second substitute occurs
#
# Revision 1.81  2018/04/23 05:57:51  db2admin
# escape out the leading ) of commands on )WHEN statements
#
# Revision 1.80  2018/04/23 04:41:49  db2admin
# close cursor when finished with it in processCHECKFORROWS
#
# Revision 1.79  2018/04/23 03:58:35  db2admin
# replace condition checking in )SEL and SELELSE with processing in processCondition
# to ensure that it is consistent
#
# Revision 1.78  2018/04/23 01:36:28  db2admin
# Made the following changes:
# 1. corrected references to )OPEN - replaced with )LOGON
# 2. implemented new statements -
#      )SETLEFTJUSTTAB to set the left justification tab character
#      )SETRIGHTJUSTTAB to set the right justification tab character
# 3. implemented new ROW_EXISTS and NO_ROW_EXISTS functions (usable on )SEL, )SELELSE and )WHEN statements
#    to check to see if any rows are returned for a provided SQL statement
#
# Revision 1.77  2018/04/22 00:30:16  db2admin
# processCondition added but not linked to other code
#
# Revision 1.76  2018/04/19 23:29:20  db2admin
# 1. Correct a number of spelling mistakes in the code comments
# 2. Remove unused variable TMP_File
# 3. Add in new command )DOSEL to populate variables based on a select statement
#
# Revision 1.75  2018/04/18 01:26:02  db2admin
# allow the escaping of the : character to allow strings beginning with : to not be confused with variables
#
# Revision 1.74  2018/04/17 04:39:25  db2admin
# Add in )WHEN command
# Simplify displayDebug code to speed up the display and reduce checks
# Modify default value of debugLevel to -1 and change code to preemptively return if the default debug value is found
#
# Revision 1.73  2018/04/16 05:45:08  db2admin
# allow delimited control records to use defaulted occurrence positions
#
# Revision 1.72  2018/04/16 02:06:36  db2admin
# adjust ctl file allocation for FDOF requests to be more memory efficient
#
# Revision 1.71  2018/04/16 01:30:58  db2admin
# modify the way control files are added to the array to correct a bug in array allocation
#
# Revision 1.70  2018/04/12 05:51:01  db2admin
# Add in a )PARSE command to allow the easy break up of variables into components
#
# Revision 1.69  2018/04/12 02:39:11  db2admin
# correct bug that occurs when file delimiters are special characters
#
# Revision 1.68  2018/03/28 20:51:44  db2admin
# Set a default limit of 2000 rows to be returned by FTAB (can be user modified)
#
# Revision 1.67  2018/03/28 01:10:20  db2admin
# 1. Maximum default generated HTML string set to 5Mb characters
# 2. maximum default generated HTML table set to 60Kb characters
# 3. added in limiting for FTAB generated data
#
# Revision 1.65  2018/01/04 00:49:12  db2admin
# add in code to allow the implicit specification of a variable in a )FUNC command
# i.e. )FUNC int :a = :a could be written as )FUNC int :a
# also improved the error message for operator not found to specify the function type
#
# Revision 1.64  2017/12/27 01:18:17  db2admin
# Add in REPL and WEBSAFE functions
#
# Revision 1.63  2017/08/08 23:44:26  db2admin
# add code to allow variable names to be enclosed by braces {} to simplify variable identification
#
# Revision 1.62  2017/08/08 23:13:15  db2admin
# Allow variable substitution on the )DMPHDR card
#
# Revision 1.61  2017/08/08 06:00:39  db2admin
# initialise the loop count variables to zero at start of loop
#
# Revision 1.60  2017/07/19 01:13:06  db2admin
# allow SQL= and FILE= as alternatives to SQL: and FILE: (all have identical meaning)
#
# Revision 1.59  2017/04/05 22:50:48  db2admin
# only do decimal places if there is a decimal point
#
# Revision 1.58  2017/04/05 22:48:29  db2admin
# change the selection criteria for truncating and decimal places
#
# Revision 1.57  2017/04/05 05:56:43  db2admin
# Add in functionality that allows the setting of displayed decimal places
# Allow the setting of decimal places on the TRUNCZEROES card
# add in )DECIMALPLACES control card
#
# Revision 1.56  2017/01/05 23:23:14  db2admin
# add in )GRAPHLABEL command
#
# Revision 1.55  2016/07/14 04:01:03  db2admin
# centralise SQL loads so that common processing can be done
# When loading SQL dont load lines that are prefixed with -- (comments)
#
# Revision 1.53  2016/07/06 23:40:02  db2admin
# add in new control cards )TRUNCZEROES and )LEAVEZEROES to control processing of trailing zeroes
# on numeric fields (only affects numbers with a decimal point)
#
# Revision 1.52  2016/07/06 01:08:07  db2admin
# Allow the button statement to contain parameters
#
# Revision 1.51  2016/07/01 03:37:36  db2admin
# modify where the graph framing occurs so that SQL display doesn't affect the generation of the graph
#
# Revision 1.50  2016/06/26 06:52:14  db2admin
# allow SQL: to be used as well as FILE: when specifying SQL files
#
# Revision 1.49  2016/06/06 01:55:06  db2admin
# Add in alternate graphing package plotly
#
# Revision 1.48  2016/05/24 23:26:05  db2admin
# correct FILE: processing in )FXTAB command
#
# Revision 1.47  2016/05/16 00:26:27  db2admin
# correct comments
#
# Revision 1.46  2016/05/16 00:10:16  db2admin
# Add in processing to manage new GRAPHSTART and GRAPHFINISH cards
#
# Revision 1.45  2016/05/15 23:41:08  db2admin
# modify to remove file created as part of DOEXEC at end of command
#
# Revision 1.44  2016/05/15 23:29:47  db2admin
# Add in the following commands to implement a graphing capability:
# )GRAPHLIB
# )GRAPHGROUP
# )GRAPHGROUPCLEAR
# )GRAPH
# )GRAPHSTART
# )GRAPHFINISH
#
# Revision 1.43  2016/05/03 04:50:50  db2admin
# use a temporary filesystem for temp files
#
# Revision 1.42  2016/05/03 00:52:50  db2admin
# 1. Correctsome small coding errors in the processing of CTL files
# 2. Add in )DOEXEC and )DOENDEXEC commands
#
# Revision 1.41  2016/02/04 05:33:49  db2admin
# add in extra variables to hold counts for database loops
#
# Revision 1.24  2015/11/12 00:12:39  db2admin
# align with standard script
#
# Revision 1.40  2015/11/09 20:27:22  db2admin
# add in code to FXTAB to allow literal placement
#
# Revision 1.39  2015/11/03 21:41:44  db2admin
# alter CTAB to allow multiple checkbox generation
# Alter def to allow no heading for check box column
# Alter def to allow the setting of a column heading for the checkbox column
#
# Revision 1.38  2015/10/30 04:45:57  db2admin
# Vary SBOX and CTAB processing to allow more flexability in what HTML elements are written out
# This will allow these tabs to overlap and include each other as well as other defined
# HTML elements
#
# Revision 1.37  2015/10/29 03:58:53  db2admin
# Add in SBOX command
#
# Revision 1.36  2015/10/28 00:45:45  db2admin
# correct heading generation in processCTAB
#
# Revision 1.35  2015/10/28 00:15:59  db2admin
# Add in the ability to pre-check generated check boxes
#
# Revision 1.34  2015/10/25 21:18:32  db2admin
# improve getCookie code
# alter the way parameters are derived for the )SET command
#
# Revision 1.32  2015/10/21 08:13:16  db2admin
# rename ITAB to CTAB
#
# Revision 1.30  2015/10/21 00:27:30  db2admin
# make the form method variable
#
# Revision 1.29  2015/10/20 23:49:16  db2admin
# make the form button target a supplied parameter
#
# Revision 1.28  2015/10/20 21:47:31  db2admin
# add in new ITAB skeleton command
# standardise open processing
#
# Revision 1.27  2015/10/14 01:03:25  db2admin
# improve error displays
#
# Revision 1.26  2015/10/12 21:27:38  db2admin
# check for an open connection before processing FTAB, FVTAB and FXTAB statements
#
# Revision 1.25  2015/10/12 03:57:23  db2admin
# Add in )DOCMD skeleton statement to issue DBI commands with no returned output
# By default only INSERT, UPDATE and DELETE statements are allowed
#
# Revision 1.24  2015/10/08 00:53:03  db2admin
# Add in functional operators to the FXTAB statement
#
# Revision 1.23  2015/10/07 01:42:28  db2admin
# Add in new )FXTAB skeleton command
# correct variable substitution bug
#
# Revision 1.22  2015/09/23 21:47:05  db2admin
# Add in | to the characters that will terminate a token
# Modify function processing to allow no parm to be passed (required by GDATE)
#    Note though that the format is still )FUNC xxxx var =
#
# Revision 1.21  2015/09/09 01:09:05  db2admin
# add in calculator debugging to processIMBED
#
# Revision 1.19  2015/07/29 02:23:56  db2admin
# synching with main cpy
#
# Revision 1.20  2015/07/29 02:21:45  db2admin
# inprove error reporting
# Add new flag 'skelVerboseSQLErrors' to minimise logging
# turned off by default
# Note: 'DB2 No Rows Returned' Errors will now be reported differently from a SQL Error
#
# Revision 1.19  2015/04/20 21:24:36  db2admin
# Add in PAD function to pad out strings
#
# Revision 1.18  2015/04/16 10:07:46  db2admin
# add in new )SEL functions called DEFINED() and NOT_DEFINED()
#
# Revision 1.17  2015/04/15 01:07:28  db2admin
# correct bug in skelVers assignment
#
# Revision 1.16  2015/04/15 00:15:33  db2admin
# add in )SKELVERS statement to set internal variable skelVers
#
# Revision 1.15  2015/04/14 23:51:24  db2admin
# change skeleton variable from skelVers to prSkelVers
# (skelVersion will be used for the version of the last skeleton processed)
#
# Revision 1.14  2015/03/13 02:37:43  db2admin
# 1. Added in CRLF to token terminator
# 2. modified DBI error processing to avoid not defined messages for $DBI::errstr
# 3. Added in subroutine getDate2 to return today's date in format YYYYMMDD
# 4. Adjust DBI column process to allow for character field types NUMERIC and TEXT)
# 5. Added in subroutine getTabValue to centralise processing of column data from DBI
# 6. modified SQL processing to allow variable substitution in SQL loaded from files
# 7. Added new function GDATE to process gregorian dates (used on )FUNC)
# 8. added new function JDATE to process julian dates (or offset counts from specified dates) (used on )FUNC)
# 9. Minor changes to cope with DBD::SQLite (mainly the use of NUMERIC and TEXT field types0
#
# Revision 1.13  2015/03/02 03:45:46  db2admin
# Add in )BUTTON control card
#
# Revision 1.12  2015/03/02 03:02:21  db2admin
# Add in HTMLHDR and DMPHDR control cards
#
# Revision 1.11  2015/03/01 22:20:10  db2admin
# added in )DMP command to simplify the extracting of data
# corrected the )VERSION command to be web aware
#
# Revision 1.10  2015/02/26 05:50:06  db2admin
# correct variable initialisation
#
# Revision 1.9  2015/02/25 10:03:53  db2admin
# Put in usage information and correct versioning
#
# Revision 1.8  2015/02/25 08:46:31  db2admin
# correct the processing of FILE: for XDOT and DOT
#
# Revision 1.7  2015/02/25 02:47:35  db2admin
# mark shown SQL as preformatted
# ensure HTTP output has <BR> as CRLF
#
# Revision 1.6 
# remove Windows CRLF
#
# Revision 1.5  2014/11/11 22:12:40  kevin
# add in ProcessVersion command
#
# Revision 1.4  2014/11/06 00:57:49  db2admin
# Add in )FDOF
#
# Revision 1.2  2014/11/02 23:06:28  kevin
# Multiple changes:
# 1. Change default for SHOWSQL from YES to NO
# 2. Change some incorrect comments
# 3. Correct a couple of bugs with variable substitution
# 4. Include routine to allow parameters to be passed in
# 5. When in HTTP mode return the generated output as a string
# 6. Add in new control card )FDOF tp provide a formatted dump of a file
#
# Revision 1.2  2014/10/26 23:09:49  kevin
# adjust skeleton start position on first skeleton loaded
#
# Revision 1.1  2014/10/26 22:16:19  kevin
# Initial revision
#
# --------------------------------------------------------------------
#
# Package Header:
#
package processSkeleton;
use strict;
use warnings;
use Data::Dumper qw(Dumper);
use User::pwent; # for getpwuid and getgrnam
use commonFunctions qw(commonVersion getOpt myDate trim $getOpt_optName $getOpt_optValue @myDate_ReturnDesc);
use calculator qw(calcVersion evaluateInfix $calcDebugLevel $calcDebugModules);
use Exporter;
# use Data::UUID;           # only useful if package installed
my $ug;
# my $ug    = Data::UUID->new;

our @ISA = 'Exporter';
our @EXPORT_OK = qw(processSkeleton skelVersion formatSQL $skelDebugLevel $skelCache $ctlCache $execCtlCache testRoutine $testRoutines $outputMode $skelShowSQL $DBIModule $skelDebugModules $skelDelimiter $skelVerboseSQLErrors $DOCMD_allowedStatements $skelMaxOutput $skelMaxTableOut $skelMaxRows $indexCaseInsensitive);

# published variables
our $skelDelimiter = ',';   # delimiter to be used when generating dump file using )DMP
our $skelMaxOutput = 5000000; # max string length length to be returned - this isnot an absolute value - output will be not be added to the string once it 
                            # exceeds this limit but the string wont be truncated to this length
our $skelMaxRows = 2000;     # max number of rows to be displayed by the FTAB Command
our $skelMaxTableOut = 60000; # max length length of the output generated by a FTAB command - output will be not be added to the string once it 
                            # exceeds this limit but the string wont be truncated to this length
our $skelDebugModules = 'All';  # variable indicating which modules debug messages should be produced for
our $skelShowSQL = 'No';    # variable indicating if generated SQL should be displayed (defaults to NO)
our $skelDebugLevel = -1;   # by default dont list any debug information 
our $skelVerboseSQLErrors = 'No';    # by default dont print out verbose SQL erros details (i.e. dont print out when no rows found and dont print SQL)
our $skelCache = 1;         # by default always cache skeletons (i.e reuse already loaded skeletons)
our $ctlCache = 1;          # by default always cache CTL files (i.e reuse already loaded skeletons)
our $execCtlCache = 1;      # by default always cache Exec CTL files (i.e reuse already loaded skeletons)
our $testRoutines = 0;      # variable containing which tests to run in the testRoutine sub
our $outputMode = 'STDOUT'; # variable defining the target environment for the generated skeleton
                            # values can be STDOUT : output just going to STDOUT (default)
                            #               HTTP   : output is going to a web screen (basically CRLF replaced by <BR>
                            #               HTTPFILE : not sure why but basically prefix the first string with CRLF
our $DBIModule = '';        # DBI module to use for database connectivity
our $DOCMD_allowedStatements = ' INSERT UPDATE DELETE '; # default allowed statements for )DOCMD
our $indexCaseInsensitive = 1;  # default to case insensitive indexes

# Bring across any environment variables that may exist

my $skelViewQual;
if (exists($ENV{'SKL_VIEWQUAL'}) ) { $skelViewQual = $ENV{'SKL_VIEWQUAL'}; }
my $skelSID;
if (exists($ENV{'ORACLE_SID'}) ) { $skelSID = $ENV{'ORACLE_SID'}; }
my $skelTNS;
if (exists($ENV{'TNS_ADMIN'}) ) { $skelTNS = $ENV{'TNS_ADMIN'}; }
my $skelUserID;
if (exists($ENV{'SKL_USERID'}) ) { $skelUserID = $ENV{'SKL_USERID'}; }

# private global variables

my $scriptDir;
my $OS;
my %skelArray = ();                       # associative array holding the array number where lines are held
my @skelLines = ();                       # 2 dimensional array holding the skeleton lines (referenced as $skelLines[$skelArray{<Name>}][<line number>]
my @imbedStack = ();                      # stack variable used to hold position in skeletons while processing IMBED statements
my %skelVarArray = ();                    # Array holding skeleton variables
my $dirSep = '';                          # directory level separator (varies by operating system)
my $currentActiveSkel = "";               # skeleton currently being processed
my $currentSkelLine = -1 ;                # line in current skeleton being processed
my $currentLinePosition = 0 ;             # current scan position in the line being processed in a skeleton
my $outputLineCount = 0 ;                 # count of the number of lines that have been output
my $skelReturnString = '' ;               # string to hold the generated output
my $skelTermChar = " ()!,.;'~=<>+\|\"-/\\\n"; # characters that will terminate a token within a skeleton
my $numericFieldTypes = ' 2 3 4 5 6 7 8 -5 -6 NUMERIC'; # field types that define numeric values
my $machine = '';                         # server the script is running on
my @traceLevelStack = ();                 # stack to manage trace levels
my $SQLError = 1;                         # flag indicating that the open cursor returned no rows (worked but couldn't find anything)
my %weekDays = ( "MON", "Monday", "TUE", "Tuesday", "WED", "Wednesday", "THU", "Thursday", "FRI", "Friday", "SAT", "Saturday", "SUN", "Sunday");
my $truncateTrailingZeroes = 0;           # flag indicating if trailing zeroes should be removed from returned database values
my $cursorDecimalPlaces = -1;             # Number of decimal places to retain after truncating zeroes
my $currentVariable = '';                 # this holds the name of the variable to be assigned the return value from a )FUNC statement 
my $leftJustTab = '!';                    # character to be used as left justified tab stop
my $rightJustTab = '~';                   # character to be used as right justified tab stop
my $statementError = '';                  # variable to hold the last error message
my @scopeStack = ('global');              # establish the variable domain stack (this is used when searching for variables)
my $currentScope = 'global';              # set the initial domain

# Database connection detail arrays ....

my $skelCurrentConnection;                # variable holding the name of the current conenction
my %skelConnection;                       # assiative array that will hold the DB connection pointers for the open DB connections. Keyed by connRef
my $currentCursorConnection;              # most recent cursor that was opened
my %skelCursor;                           # associative array containing open cursors. Keyed by tabRef
my %skelCursorRow;                        # associative array containing the last returned row for the cursor. Keyed by tabRef
my %cursorSQL;                            # associative array that specifies the SQL for a cursor. Keyed by tabRef
my %DOTLocation;                          # associative array that specifies the position in the skeleton where a )ENDDOT should loop back to. Keyed by tabRef
my %cursorRowNumber;                      # associative array holding the number of rows read from each cursor
my $skelCaseSensitiveColumns = 0;         # if set then cursor column name will be considered case sensitive (default - not case sensitive)
my @cursorStack = ();                     # stack of cursors to enable a )DOT to be within a )DOT

# flow control variables (SEL and DOT)

my $skelSelSkipCards = "No";              # variable indicating if we are skipping cards because a surrounding )SEL has evaluated false
my $skelDOTSkipCards = "No";              # variable indicating if we are skipping cards because a )DOT has found no rows to process
my $skelGotoENDSEL = "No";                # variable indiacting if we have a successful )SEL or )ENDSEL and should procede to the )ENDSEL now
my $skelSELCount=0;                       # How deep the _SEL stack is
my $maxSubroutineLen= 15;                 # holds the maximum length of encountered subroutine names in displayDEBUG
my $skelSEL_resumeLevel = 0;              # SEL stack Value when processing will continue
my $skelDOT_resumeLevel = 0;              # DOT stack Value when processing will continue
my $skelDOTCount=0;                       # Count of )DOTs found. )DOT increments this and )ENDDOT decrements - should be zero at end
my @controlStack;                         # stack that will contain the values of skelSELCount, skelDOTCount and skelDOFCount at entry to )DOT, )DOF and )SEL clauses
                                          # This will be used in )ENDSEL/)ENDDOT/)ENDDOF processing to ensure that control structures aren't incorrect ()SEls spanning )DOTs etc)
my $lastFlagSet = 0;                      # Indicates that a )LAST has been encountered and has skipped to the )END... card
                                          
# DOF Variables
my %DOFLocation;                          # associative array that specifies the position in the skeleton where a )ENDDOF should loop back to. Keyed by fileRef
my $currentFileRef = '';                  # current file ref being used
my %skelFileHandle;                       # file handles of all files opened (keyed by fileRef)
my %skelFileStatus;                       # current status of the file (keyed by fileRef)
my $skelFileRecord;                       # last record returned when reading a Data file in a )DOF loop
my $skelDOFCount=0;                       # Count of )DOFs found. )DOF increments this and )ENDDOF decrements - should be zero at end
my %ctlArray = ();                        # associative array holding the array number where ctl lines are held
my @ctlLines = ();                        # 2 dimensional array holding the ctl file lines (referenced as $ctlLines[$ctlArray{<ctlRef>}][<line number>]
my @fileStack = ();                       # stack to hold the value of currentFileRef as new )DOFs encountered
my $condNULLisMatch = 0;                  # indicates that if a conditional field isn't defined it is considered a match        

# DOEXEC Variables
my %DOEXECLocation;                       # associative array that specifies the position in the skeleton where a )ENDDOF should loop back to. Keyed by fileRef
my $currentExecRef = '';                  # current file ref being used
my $currentExecFile = '';                 # current file being used to hold the exec output
my %skelExecHandle;                       # file handles of all files opened for DOEXEC (keyed by execRef)
my %skelExecStatus;                       # current status of the file (keyed by execRef)
my $skelExecRecord;                       # last record returned when reading a Data file in a )DOF loop
my $skelDOEXECCount=0;                    # Count of )DOEXECs found. )DOEXEC increments this and )ENDDOEXEC decrements - should be zero at end
#my %execCtlArray = ();                   # associative array holding the array number where ctl lines are held
#my @execCtlLines = ();                   # 2 dimensional array holding the exec ctl file lines (referenced as $execCtlLines[$execCtlArray{<execCtlRef>}][<line number>]
my @execStack = ();                       # stack to hold the value of currentExecRef as new )DOEXECs encountered

# Variables for tab processing
my $CTABNumber = 0;                       # CTAB table number generated in this skeleton
my $FTABNumber = 0;                       # FTAB table number generated in this skeleton
my $FTAB_output_len = 0;                  # length of the current FTAB table
my %vertHeader = ();                      # array indicating which columns have vertical headings
my $someVerticalHeaders = 0;              # indicates that a )VHEAD has been processed

my @tabEntries;                           # array holding tab stop entries
my $checkAllWritten = 0;                  # flag indicating that javascript routine has already been written 
my $CTAB_form_name = 'Form';              # form name 
my $FORM_has_been_opened = 0;             # flag to control closing/opening of HTML FORM elements
my $FIELDSET_has_been_opened = 0;         # flag to control closing/opening of HTML FIELDSET elements
my %cellStyle = ();                       # matches a cell style to a cell (this is a 2 key array {colimn}{condition}
my %rowStyle = ();                        # matches a cell style to a cell
my $currentRowStyle = '';                 # row style defined for the current row
my $currentCellStyle = '';                # row style defined for the current cell
my $convertHeaders = 1;                   # flag indicating if FDOF headers should be adjusted
my $selectCond = '';                      # selection condition to be applied to loops 
my $styleCount = 0;                       # incrementing count of style cards processed

# variables for GRAPH processing
my $graphLibrary = 'plotly';              # specifies the default javascript graphs library
my %graphLibraryName = (); 
$graphLibraryName{'plotly'} = 'plotly-latest.min.js'; # name of the library    
$graphLibraryName{'vis'} = 'vis.js'; # name of the library    
my $graphIncludesWritten = 0;             # indicates if the include libraries for vis.js and vis.csss have been included in output
my $graphScriptOpened = 0;                # flag to control opening and closing of vis.js <script> tags
my $currentGraphNum= 0;                   # current label for the graph location
my $graphStarted = 0;                     # flag indicating that the first part of the vis.js script has been written
my %graphGroupOptions = ();               # empty out the group array
my %graphGroupName = ();                  # empty out the group name array
my %graphLabel = ();                      # empty out the graph label array
my @YAxisValues = ();                     # Y axis values for the graph 
my $graphOptions = '';                    # graph options set with the )GRAPHOPT statement
my $graphType = 'LINE';                   # type of graph to produce
my $graphVariableNames = '';              # contains a list of the variables being created

# Variables for INDEX processing
my $provideIndex = 0;
my $indexType = '';                       # (INDEXTYPE) EVERY, EXACT or PREFIX
my $EV_interval = 10;                     # for EVERY - interval (default 10)
my $EV_max = 20;                          # for EVERY - max entries (default 20)
my $EV_type = 'DOT';                      # for EVERY - type of index marks (default DOT)
my @indexLiteral = ();                    # array of the index labels to use
my @indexLiteralUsed = ();                # array of indicator signifying if this index entry has been satisfied
my $indexEntry = 0;                       # entry in the table that is to be indexed                    
my $indexKey = 0;                         # unique number grouping the index entries
my $indexCount = 0;                       # count of the number of times that )INDEXTEST has been called
  
BEGIN {
  if ( $^O eq "MSWin32") {
    $dirSep = "\\";
    $machine = `hostname`;
    $OS = "Windows";
    $scriptDir = 'c:\udbdba\scrxipts';
    my $tmp = rindex($0,'\\');
    if ($tmp > -1) {
      $scriptDir = substr($0,0,$tmp+1)  ;
    }
  }
  else {
    $dirSep = "\/";
    $machine = `uname -n`;
    my $machine_info = `uname -a`;
    my @mach_info = split(/\s+/,$machine_info);
    $OS = $mach_info[0] . " " . $mach_info[2];
    $scriptDir = "scripts";
    my $tmp = rindex($0,'/');
    if ($tmp > -1) {
      $scriptDir = substr($0,0,$tmp+1)  ;
    }
  }
}

sub testRoutine {
  # -----------------------------------------------------------
  # routine to test the subroutines/functions in this package
  # -----------------------------------------------------------

  my $currentSubroutine = 'testRoutine'; 
  my $testString = "";

  if ( oct($testRoutines) & oct('0b0000000000000001') ) { # remove unnecessary whitespace test
    my $b = "test  of the     whitespace '    '' '   remover\t\t\ttest";
    my $c = removeUnnecessaryWhiteSpace($b);

    displayDebug ("Before: $b|",0,$currentSubroutine);
    displayDebug ("After : $c|",0,$currentSubroutine);

    if ( $c eq 'test of the whitespace \'    \'\' \' remover test' ) { displayResult("Test of removeUnnecessaryWhiteSpace","OK"); }
    else { displayResult("Test of removeUnnecessaryWhiteSpace",'FAIL'); }

    displayDebug("Testing the space subroutine - should print 12 spaces between the brackets",0,$currentSubroutine);
    $c = space(12);
    displayDebug ("    \[$c\]",0,$currentSubroutine);

    if ( $c eq '            ' ) { displayResult("Test of space","OK"); }
    else { displayResult("Test of space",'FAIL'); }

    displayDebug("Checking on the isNumeric function",0,$currentSubroutine);
    $testString = '1234';
    if ( isNumeric($testString) ) { displayResult("Test of isNumeric($testString)","OK"); displayDebug("$testString has tested as numeric",0,$currentSubroutine);} 
    else { displayDebug("Test of isNumeric($testString)","FAIL") ; displayDebug("$testString has tested as not numeric",0,$currentSubroutine);}

    $testString = '1234a';
    if ( ! isNumeric($testString) ) { displayResult("Test of isNumeric($testString)","OK"); displayDebug("$testString has tested as not numeric",0,$currentSubroutine);} 
    else { displayDebug("Test of isNumeric($testString)","FAIL") ; displayDebug("$testString has tested as numeric",0,$currentSubroutine);}

    $testString = '1234.34';
    if ( isNumeric($testString) ) { displayResult("Test of isNumeric($testString)","OK"); displayDebug("$testString has tested as numeric",0,$currentSubroutine);} 
    else { displayDebug("Test of isNumeric($testString)","FAIL") ; displayDebug("$testString has tested as not numeric",0,$currentSubroutine);}

  }

  if ( oct($testRoutines) & oct('0b0000000000000010') ) { # format SQL test
    my $SQLIn;
    if (! open ($SQLIn,"<","test.sql") ) { die "test.sql doesn't exist\n"; }

    while (<$SQLIn>) {
      chomp;
      $testString .= $_;
    }

    close $SQLIn;

    displayError ( "SQL Before: $testString",$currentSubroutine);

    $a = formatSQL($testString);
    displayError( "Formatted SQL: \n$a",$currentSubroutine);
  }

  if ( oct($testRoutines) & oct('0b0000000000000100') ) { # loadSkeleton test
    my $skelName = 'testProcessSkeleton.skl';
    loadSkel('global',$skelName);

    displayDebug("Array being Used for $skelName is $skelArray{$skelName}",0,$currentSubroutine);

    # display what was loaded into the skel arrays .....
    for ( my $i= 0 ; $i <= $#skelLines ; $i++) {
      displayDebug("$i>> $skelLines[$i]",0,$currentSubroutine); ;
      my @row = @{$skelLines[$i]};
      for ( my $j= 0 ; $j <= $#row ; $j++) {
        displayDebug( "     .... $j>> $row[$j]",0,$currentSubroutine);
      }
    };
  }

  if ( oct($testRoutines) & oct('0b0000000000001000') ) { # getToken test
    $testString = "the quick brown dog tripped over the lazy frog";
    displayDebug( "Checking getToken. Showing 4 tokens after position 12 in >$testString<",0,$currentSubroutine);
    $currentLinePosition = 12;
    my $token = "";
    for (0 .. 3 ) { # loop 4 times
      $token = getToken($testString);
      displayDebug( "Token: $token",0,$currentSubroutine);
    }
  }

  setBaseVariables();

  $DBIModule = "DB2";

  if ( $outputMode eq "STDOUT" ) {
    my $a = processSkeleton('testProcessSkeleton.skl');
    if ( $outputMode ne "STDOUT" ) { # mode changed in skeleton ...
      print "==========================================\n";
      print "output mode changed in skeleton .....\nReturned string is:\n$a\n";
    }
  }
  else {
    my $a = processSkeleton('testProcessSkeleton.skl');
    print $a;
  }

} # end of testRoutine


sub by_key {
  # -----------------------------------------------------------
  # routine called from within a for loop to return values in the order of their key
  # -----------------------------------------------------------
  $a cmp $b ; 
} # end of by_key

sub skelVersion {
  # -----------------------------------------------------------
  # routine to return the RCS version of this program
  # -----------------------------------------------------------

  my $currentSubroutine = 'skelVersion'; 
  my $ID = '$Id: processSkeleton.pm,v 1.127 2018/12/14 04:09:41 db2admin Exp db2admin $';
  my @V = split(/ /,$ID);
  my $nameStr=$V[1];
  my @N = split(",",$nameStr);
  return "$N[0] ($V[2])  Last Changed on $V[3] $V[4] (UTC)";
 
} # end of skelVersion

sub removeCRLF {
  # -----------------------------------------------------------
  # routine to reremove all line feeds from the supplied parameter
  # -----------------------------------------------------------

  my $currentSubroutine = 'removeCRLF'; 
  my $tmpStr = shift;
  $tmpStr =~ s/\n/ /g; # get rid of line feeds
  $tmpStr =~ s/\r/ /g; # get rid of carriage returns

  return $tmpStr;
  
} # end of removeCRLF

sub removeUnnecessaryWhiteSpace {
  # -----------------------------------------------------------
  # Remove Unnecessary whitespace from the supplied string (whitespace
  # is defined as spaces and tabs) exclude white space that exists within quotes
  # -----------------------------------------------------------

  my $currentSubroutine = 'removeUnnecessaryWhiteSpace'; 
  my $origStr = shift; # origStr is the string to be adjusted
  my $tmpStr = ""; # string to build the new adjusted string

  my $inSingleQuotes = 0; # default is not in single quotes
  my $inDoubleQuotes = 0; # default is not in double quotes
  my $inWhiteSpace = 0; # default is not in white space

  # loop through the string looking for blocks of whitespace characters 
  # that can be replaced by a single space

  for ( my $i = 0 ; $i < length($origStr); $i++ ) {

    if ( substr($origStr,$i,2) eq "\'\'" ) { # two single quotes found
      $tmpStr .= substr($origStr,$i,2);
      $i = $i + 1; # only one as it will also be incremented at the bottom of the loop
    }
    elsif ( substr($origStr,$i,2) eq "\"\"" ) { # two double quotes found
      $tmpStr .= substr($origStr,$i,2);
      $i = $i + 1; # only one as it will also be incremented at the bottom of the loop
    }
    elsif ( substr($origStr,$i,1) eq "\'" ) { # one single quote found
      if ( $inSingleQuotes ) {
        $inSingleQuotes = 0;
      }
      else {
        $inSingleQuotes = 1;
        $inWhiteSpace = 0; # turn off whitespace flag
      }
      $tmpStr .= substr($origStr,$i,1);
    }
    elsif ( substr($origStr,$i,1) eq "\"" ) { # one double quote found
      if ( $inDoubleQuotes  ) {
        $inDoubleQuotes = 0;
      }
      else {
        $inDoubleQuotes = 1;
        $inWhiteSpace = 0; # turn off whitespace flag
      }
      $tmpStr .= substr($origStr,$i,1);
    }
    elsif ( index(" \t", substr($origStr, $i,1)) > -1 ) {  # whitespace character found
      if ( $inSingleQuotes || $inDoubleQuotes ) { # between quotes so trat as a normal character
        $tmpStr .= substr($origStr, $i,1);
      }
      else { # not in a string ....
        if ( ! $inWhiteSpace ) { # not currently in a whitespace block (if in whitespace already
                                 # then just skip this one
          $inWhiteSpace = 1;
          $tmpStr .= " "; # add a space to the string
        }
      }
    }
    else { # is a non-whitespace character
      $inWhiteSpace = 0;
      $tmpStr .= substr($origStr, $i,1);
    }
  }

  # return the generated string
  return $tmpStr;
} # end of removeUnnecessaryWhiteSpace

sub getNextSQLToken {
  # -----------------------------------------------------------
  # Routine to return the next SQL token. Leading whitespace is ignored
  #
  # usage: getNextSQLToken("test sql" [,starting pos:defaults to 0]);
  # returns: token, char pos after the token in string
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'getNextSQLToken'; 
  my $SQL = shift;
  my $tokenPos = shift;
  
  my $tokenTerminators = " ,\(\)\'\"";
  
  displayDebug(">>>> $SQL",1,$currentSubroutine);
  
  if (! defined($tokenPos) )  { # position not passed
    $tokenPos = 0;
  }
  
  # skip leading whitespace
  my $tmpSQL = substr($SQL,$tokenPos);
  my $leadSpace = "";
  ($leadSpace,$tmpSQL) = ( $tmpSQL =~ /^(\s*)(.*)/ ); # strip out the leading whitespace
  
  $tokenPos = $tokenPos + length($leadSpace); # adjust the position based on the number of removed whitespace characters
  
  # if the token is a single character token then just return it ....
  my $tmpToken = substr($tmpSQL,0,1);
  if ( index("\(\).",$tmpToken) > -1 ) { # single char token
    $tokenPos++; # just return the single character and increment the pointer
  }
  elsif ( index("\'\"",$tmpToken) > -1 ) { # start of a string ... loop through until you get to a terminating string
    my $tmpTerm = $tmpToken; # set the value being looked for
    my $j = 0; # have to define it outside the for loop so it can be tested
    for ( $j = $tokenPos+1; $j <= length($SQL); $j++ ) { # keep checking 
      my $myChar = substr($SQL,$j,1);
      displayDebug("+++++ \$myChar: $myChar , Terminators: $tokenTerminators",1,$currentSubroutine);
      if ( ($myChar eq $tmpTerm) && (substr($SQL,$j+1,1) ne $tmpTerm) ) { # found a matching quote (that hasn't been escaped)
        $tmpToken .=  substr($SQL,$j,1);
        $j++;
        last; # finish up checking
      }
      elsif ( ($myChar eq $tmpTerm) && (substr($SQL,$j+1,1) eq $tmpTerm) ) { # 2 quotes in a row so add them both ... 
        $tmpToken .=  substr($SQL,$j,2);
        $j++; # skip processing the second quote
      }
      else { # just keep looking ...
        $tmpToken .= substr($SQL,$j,1);
      }
    } 
    $tokenPos = $j;
  }
  else { # search for a token terminating character
    my $i = 0; # have to define it outside the for loop so it can be tested
    for ( $i = $tokenPos+1; $i <= length($SQL); $i++ ) { # keep checking 
      my $myChar = substr($SQL,$i,1);
      displayDebug("+++++ \$myChar: $myChar , Terminators: $tokenTerminators",1,$currentSubroutine);
      if ( index($tokenTerminators,$myChar) > -1 ) { # token terminator?
        last; # finish up checking
      }
      else {
        $tmpToken .= substr($SQL,$i,1);
      }
    } 
    $tokenPos = $i;
  }
  
  displayDebug(">>>> $tmpToken",1,$currentSubroutine);

  return ($tmpToken, $tokenPos);
  
} # end of getNextSQLToken

sub multiChar {
  # -----------------------------------------------------------
  # this routine will return a string consisting of a number of repetitions of the 
  # supplied string
  #
  # usage: multiChar(char ,number of occurrances);
  # returns: a string of <number of occurrances> <char>s 
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'multiChar'; 
  my $inChar = shift; 
  my $inNumber = shift; 
  
  if ( ! defined($inChar) ) { $inChar = " " ; }  
  if ( ! defined($inNumber) ) { $inNumber = 1 ; }  
  
  my $tmp = $inChar x $inNumber;
  
  return $tmp
    
} # end of multiChar

sub printLastLine {
  # -----------------------------------------------------------
  # print out the last line of the passed string
  # -----------------------------------------------------------

  my $currentSubroutine = 'printLastLine'; 
  my $inStr = shift; 
  my $indent = shift; 
  my $lineStart = rindex($inStr,"\n");
  print "Pos: $lineStart/" . length($inStr) . " Indent: $indent Last Line: " . substr($inStr,$lineStart+1) . "<\n";

} # end of printLastLine

sub lengthOfCurrentLine {
  # -----------------------------------------------------------
  # return the length of the last line in the supplied string
  # -----------------------------------------------------------

  my $currentSubroutine = 'lengthOfCurrentLine'; 
  my $inStr = shift;

  my $lineStart = rindex($inStr,"\n");
  return length($inStr) - $lineStart;

} # end of lengthOfCurrentLine

sub formatSQL {
  # -----------------------------------------------------------
  # this routine will be passed the SQL to parse and the indent level it is at
  #
  # usage: formatSQL("test sql" [,indent level : defaults to 0]);
  # returns: formatted SQL as string
  # -----------------------------------------------------------

  my $currentSubroutine = 'formatSQL'; 
  my @indentStack = (); # stack containing indentation values
  
  my $parseSQL = shift;
  my $indentLevel = shift;
  if ( ! defined($indentLevel) ) {
    $indentLevel = 0; # indentLevel not set
  }

  my $spaces = "";        # string holding the number of spaces of indent
  my $formattedSQL = "";  # string that is returned
  my $SQLToken = "";      # token currently being processed (returned from getNextSQLToken)
  my $pos = 0;            # Current parsing position in the SQL
  my $displayPos = 0;     # number of characters since the last new line
  my $betweenOnLine = 0;  # flag indiacting that a between token is on this line
  my $newLine = 0;        # flag indicating that nothing has been put on this line yet
  my $lastToken = "";     # last token processed
  my $displayPosBeforeClose = 0; # display position before ) token actioned
  
  while ( $pos <= length($parseSQL) )  {
    if ( $skelDebugLevel > 0 ) { printLastLine($formattedSQL, $indentLevel); }
    ($SQLToken,$pos) = getNextSQLToken($parseSQL, $pos);
    displayDebug("Token: $SQLToken Position: $pos",1,$currentSubroutine);
    if ( index(" FROM WHERE ORDER GROUP INNER LEFT RIGHT ", uc($SQLToken) . " " ) > -1 ) { # CR and indent
      displayDebug("indentLevel = $indentLevel",1,$currentSubroutine);
      $spaces = multiChar(" ",$indentLevel + 2);
      if ( $newLine ) { # if empty line then dont bother throwing a CRLF
        $formattedSQL .= $spaces . $SQLToken ." ";
      }
      else {
        $formattedSQL .= "\n" . $spaces . $SQLToken ." ";
      }
      $betweenOnLine = 0; # new line - turn off between flag
      $newLine = 1;
    }
    elsif ( $SQLToken eq ',' ) { # comma - CR and indent
      displayDebug("indentLevel = $indentLevel",1,$currentSubroutine);
      $spaces = multiChar(" ",$indentLevel + 5);
      $formattedSQL .= "\n" . $spaces . $SQLToken ." ";
      $betweenOnLine = 0; # new line - turn off between flag
      $newLine = 1;
    }
    elsif ( uc($SQLToken) eq "AND" ) { # AND!
      if ( $betweenOnLine ) { # its a between statement so dont CRLF
        $formattedSQL .= $SQLToken . " ";
        $betweenOnLine = 0; # one and for the between so turn it off now
        $newLine = 0;
      }
      else { # should start on a new line
        displayDebug("In AND processing",1,$currentSubroutine);
        $spaces = multiChar(" ",$indentLevel + 4);
        if ( $newLine ) {
          $formattedSQL .= $spaces . $SQLToken ." ";
        }
        else {
          $formattedSQL .= "\n" . $spaces . $SQLToken ." ";
        }
        $betweenOnLine = 0; # new line - turn ff between flag
        $newLine = 1;
      }
    }
    elsif ( $SQLToken eq "(" ) { # maybe start of something
      if ( index ( " , AS IN FROM ", uc($lastToken) ) > -1 ) { # should be new line and indent 
        displayDebug("Pushing $indentLevel on to the stack",1,$currentSubroutine);
        push( @indentStack, $indentLevel);
        $indentLevel = $displayPos;
        $formattedSQL .= $SQLToken . "\n" . multiChar(" ", $indentLevel);
        $betweenOnLine = 0; # new line - turn off between flag
        $newLine = 1;
      }
      else { # probably just a function
        $formattedSQL .= $SQLToken . " ";
        $newLine = 0;
      }
    }
    elsif ( $SQLToken eq ")" ) { # end of something
      # check to see if there is a preceding unmatched bracket on this line ....
      my $bracketCount = 0;
      $displayPosBeforeClose = -1; 
      for ( my $j = length($formattedSQL) ; $j >= 0 ; $j-- ) {
        if ( substr($formattedSQL, $j, 1) eq "\n" ) { # we're finished (we've reached the beginning of the current line
          last;
        }
        elsif ( substr($formattedSQL, $j, 1) eq "\(" ) {
          $bracketCount++;
        }
        elsif ( substr($formattedSQL, $j, 1) eq "\)" ) {
          $bracketCount--;
        }
      }
      if ( $bracketCount > 0 ) { # there IS an unmatched bracket (just print the token)
        $formattedSQL .= $SQLToken . " ";
        $newLine = 0;
      }
      else { # treat it as an indented SQL block ....
        $formattedSQL .= "\n" . multiChar(" ", $indentLevel) . $SQLToken . " \n"; 
        displayDebug("Taking \$indentLevel $indentLevel off of the stack",1,$currentSubroutine);
        $indentLevel = pop ( @indentStack );
        if ( ! defined($indentLevel) ) { $indentLevel = 0 }; # initialise the variable if we have gone too far
        $displayPosBeforeClose = $displayPos;
        $betweenOnLine = 0; # new line - turn ff between flag
        $newLine = 1;
      }
    }
    elsif ( uc($SQLToken) eq "ELSE" ) { # end statement ....
      $formattedSQL .= "\n" . multiChar(" ", $indentLevel) . "$SQLToken "; 
      $betweenOnLine = 0; # new line - turn ff between flag
      $newLine = 0;
    }
    elsif ( ($SQLToken eq "=") && ( uc($lastToken) eq "END" ) ) { # likely to be a case statement in a where clause
      $formattedSQL .= multiChar(" ", $displayPosBeforeClose) . "$SQLToken ";
      $newLine = 0;
    }
    elsif ( uc($SQLToken) eq "END" ) { # end statement ....
      $formattedSQL .= "\n" . multiChar(" ", $indentLevel-2) . "$SQLToken\n"; 
      $displayPosBeforeClose = $indentLevel-2;
      displayDebug("Taking \$indentLevel $indentLevel off of the stack",1,$currentSubroutine);
      $indentLevel = pop ( @indentStack );
      $betweenOnLine = 0; # new line - turn ff between flag
      $newLine = 1;
    }
    elsif ( uc($SQLToken) eq "CASE" ) { # case statement ....
      displayDebug("Pushing \$indentLevel $indentLevel on to the stack",1,$currentSubroutine);
      push( @indentStack, $indentLevel);
      $indentLevel = $displayPos+2;
      $formattedSQL .= $SQLToken ;
      if ( $skelDebugLevel > 0 ) { printLastLine($formattedSQL, $indentLevel); }
      $formattedSQL .= "\n" . multiChar(" ", $indentLevel);
      $betweenOnLine = 0; # new line - turn off between flag
      $newLine = 1;
    }
    else { # no formatting required
      displayDebug(">>>>>> CurrentToken: $SQLToken, \$lastToken: $lastToken, \$newLine: $newLine",1,$currentSubroutine);
      if ( ( $lastToken eq  "\)" ) && ( $newLine ) && ( index(" SELECT INSERT DELETE REPLACE ", " " . uc($SQLToken) . " ") == -1 ) ) { # in all likelihood this token is an alias
        # remove the CR
        # $formattedSQL = substr($formattedSQL, $length($formattedSQL) - $indentLevel - 2); 
        chomp $formattedSQL ;
        # if ( $displayPosBeforeClose > -1 ) { # adjust the displayPos back to where it was
        #   $displayPos = $displayPosBeforeClose ;
        # }
      }
      $newLine = 0;
      $formattedSQL .= $SQLToken . " ";
      if ( uc($SQLToken) eq "BETWEEN" ) { $betweenOnLine = 1; } # set a flag indiacting there has been a 'between' 
    }
    $lastToken = $SQLToken;
    $displayPos = lengthOfCurrentLine($formattedSQL); # set the current display pos to end of the line
  }
  return $formattedSQL;
} # end of formatSQL

sub displayResult {
  # -----------------------------------------------------------
  # this routine will display the result of a tes
  #
  # usage: displayResult("<test>",<OK|FAIL>);
  # returns: nothing
  # -----------------------------------------------------------

  my $lit = shift;
  my $result = shift;

  if ( ! defined($lit) ) { $lit = "" } # if nothing passed then default to empty string
  if ( ! defined($result) ) { $result = "FAIL" } # if nothing passed then assume it failed

  # Display a passed message with timestamp if the skelDebugLevel has been set

  my $tDate = getDate();
  my $tTime = getTime();

  if ( uc($result) eq "OK" ) { # passed test
    if ( $lit eq "") { # Nothing to display so just display the date and time
      print "Test Result : $tDate $tTime - No test specified but whatever it was it passed - Test Passed\n";
    }
    else {
      print "Test Result : $tDate $tTime - $lit - Test Passed\n";
    }
  }
  else { # it failed 
    if ( $lit eq "") { # Nothing to display so just display the date and time
      print "Test Result : $tDate $tTime - No test specified but whatever it was it failed - Test FAIL\n";
    }
    else {
      print "Test Result : $tDate $tTime - $lit - Test Fail\n";
    }
  }
} # end of displayResult

sub displayDebug {
  # -----------------------------------------------------------
  # this routine will display the debug information as required
  # based on the passed debugLevel
  #
  # usage: displayDebug("<message>",<debugLevel at which to display>);
  # returns: nothing
  # -----------------------------------------------------------

  if ( $skelDebugLevel == -1 ) { return; }    # by default dont do any debug processing

  my $lit = shift;
  my $call_debugLevel = shift;
  my $sub = shift;                            # get the subroutine name of the calling 

  if ( ! defined($call_debugLevel) ) { $call_debugLevel = 1; } # if debug level not specified then set it to 1
  
  # Display a passed message with timestamp if the skelDebugLevel has been set and is the same or exceeded
  if ( $call_debugLevel <= $skelDebugLevel ) {
      
    my $uc_sub = uc($sub);
    if ( ! defined($sub) ) { $sub = "Unknown Subroutine" } # if nothing passed then default
    # only print messages if the message comes from a specified subroutine, processDEBUG or the modules to check var is 'ALL'
    if ( (uc($skelDebugModules) eq 'ALL') || ( $sub eq 'processDEBUG') || ( uc("$skelDebugModules") =~ /$uc_sub/ ) ) {  # check if ok to print

      if ( ! defined($lit) ) { $lit = "" } # if nothing passed then default to empty string

      if ( length($sub) > $maxSubroutineLen ) { $maxSubroutineLen = length($sub) ; }       # reset length as necessary
      $sub = substr($sub . '                                                                 ',0,$maxSubroutineLen);  # pad out subroutine name as necessary
   
      my $tDate = getDate();
      my $tTime = getTime();

      if ( $lit eq "") { # Nothing to display so just display the date and time
        print STDERR "$sub - $tDate $tTime - DEBUG\n";
      }
      else {
        print STDERR "$sub - $tDate $tTime : DEBUG : $lit\n";
      }
    }
  }
  
} # end of displayDebug

sub displayError {
  # -----------------------------------------------------------
  # This routine will display the error passed to it
  #
  # usage: displayError("<message>");
  # returns: nothing
  # -----------------------------------------------------------

  my $lit  = shift;
  my $sub = shift;
  my $tDate = getDate();
  my $tTime = getTime();
  my $tmpLine = $currentSkelLine + 1;
  
  if ( ! defined($sub) ) { $sub = "Unknown Subroutine" } # if nothing passed then default

  if ( ! defined( $lit ) ) { # Nothing to display so just display the date and time
    print STDERR "$sub - $tDate $tTime - $currentActiveSkel($tmpLine) - ERROR\n";
  }
  else {
    print STDERR "$sub - $tDate $tTime - $currentActiveSkel($tmpLine) : ERROR : $lit\n";
    setVariable('lastError',$lit);
    $statementError = $lit;
  }
} # end of displayError

sub loadInlineCards {
  # -----------------------------------------------------------
  # this routine will load a string from inline statements
  #
  # usage: loadInlineCards(<calling routine>);
  # returns: the inline string
  # -----------------------------------------------------------
  
  my $callingRoutine = shift;
  my $currentSubroutine = 'loadInlineCards'; 

  my $cards = "";
  $currentSkelLine++;
    
  while ( defined($skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]) ) { # if the next line exists then keep on processing
    displayDebug("Card# $currentSkelLine is $skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]",2,$currentSubroutine);
    if ( uc(substr(trim($skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]),0,14)) eq ")END_OF_INLINE" ) { # reached the inline cards terminator
      $cards = substituteVariables($cards);                      # Substitute variables as necessary
      return ($cards);
    }
    $cards .= " " . trim($skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]) . "\n";
    $currentSkelLine++;
  }
  
  # really should never get here - to be here you have hit the end of the skeleton
  $cards = ''; 
  displayError("[loadInlineCards] Did not find a )END_OF_INLINE card", $callingRoutine);
  
  return $cards;

} # end of loadInlineCards

sub loadSQL {
  # -----------------------------------------------------------
  # this routine will load SQL from a file
  #
  # usage: loadSQL(<file name>,<calling routine>);
  # returns: the SQL string
  # -----------------------------------------------------------
  
  my $fileName = shift;
  my $callingRoutine = shift;
  
  displayDebug("[loadSQL] SQL file is: $fileName",2,$callingRoutine);

  my $SQL = "";
  if ( open ( my $tmpIn, "<", "$fileName" ) ) {
    while ( <$tmpIn> ) {
      if ( $_ =~ /^--/) { # comment so ignore
      }
      else {
        $SQL .= " $_";
      }
    }
    close $tmpIn;
  }
  else { # couldn't open the file
    outputLine("Unable to open $fileName");
  }
  $SQL = substituteVariables($SQL);                      # Substitute variables as necessary
  displayDebug("[loadSQL] Content of file is: $SQL",2,$callingRoutine);
  
  return $SQL;

} # end of loadSQL

sub loadSkel {
  # -----------------------------------------------------------
  # this routine will be passed the name of a skeleton to load.
  # It will read the skeleton into an array (based on a caching flag)
  #
  # usage: loadSkel('global', "update.skl");
  # returns: nothing
  # Not passed back but the following global variables will be changed:
  #   $currentSkelLine
  #   $currentActiveSkel
  #   @skelArray 
  #   @skelLines
  #   @scopeStack
  # -----------------------------------------------------------

  my $currentSubroutine = 'loadSkel'; 
  my $scope = shift;
  my $skel = shift;
  my $skelDir ;              # directory where the skeletons reside - sourced from environment var SKELDIR
  my $skelFullFileName;      # fully qualified directory location/name of the skeleton
  
  # load the requested skeleton into the skeleton cache

  displayDebug("Loading skeleton $skel", 1, $currentSubroutine);

  # Check to see if the skeleton is already loaded
  if ( defined($skelArray{$skel}) ) { # if it is defined see if it should be removed
    if ( ! $skelCache ) { # if dont cache skeleton then it needs to be cleared
      displayDebug("Removing old cached version of skeleton $skel", 1, $currentSubroutine);
      $skelLines[$skelArray{$skel}] = ''; # get rid of the existing skeleton lines
      undef $skelArray{$skel}; # remove the skel name referrer
    }
    else { # the skeleton already is there ....
      # set up the variable scope 
      displayDebug("Using old cached version of skeleton $skel", 1, $currentSubroutine);
      push (@imbedStack,($currentActiveSkel,$currentSkelLine,$currentScope)); # save off the current environment
      push (@scopeStack,$currentScope);                                       # save the new scope on the stack
      $currentScope = $scope;
      $currentActiveSkel = $skel;                   # initialise the skeleton variable
      setVariable('currentSkeleton',$skel);         # set the currentSkeleton variable
      $currentSkelLine = -1;                        # start at the first line (this will be incremented to zero when it gets back to processSkeleton)
      return;                                       # having reset the active variables just return
    }
  }

  # save off the current environment if necessary (-1 indicates that this is the first call to loadSkel)
  if ( $currentSkelLine > -1 ) { 
    push (@imbedStack,($currentActiveSkel,$currentSkelLine,$currentScope)); # save off the current environment
    push (@scopeStack,$scope);                                       # save the new scope on the stack
    $currentSkelLine = -1;                        # start at -1 as this will be incremented to zero when it gets back to processSkeleton
  }
  else {
    displayDebug("Skeleton environment not pushed as it is the first time through", 1, $currentSubroutine);
    $currentSkelLine = 0;                         # start at the first line as this value is not incremented on the first load
  }

  $currentScope = $scope;
  $currentActiveSkel = $skel;                   # initialise the skeleton variables
  setVariable('currentSkeleton',$skel);         # set the currentSkeleton variable
  

  if ( ! defined($skelArray{$skel}) ) {         # if not defined at this stage then load/reload it .....
    $skelArray{$skel} = keys(%skelArray);       # allocate the next array entry

    # create the filename containing the skeleton
    $skelDir = $ENV{'SKELDIR'};
    if ( ! defined ($skelDir) ) {
      $skelFullFileName = $skel;
    }
    elsif ( substr($skelDir,-1,1) eq $dirSep  ) { # has a terminating directory separator
      $skelFullFileName = "$skelDir$skel";
    }
    else { # no separator so add one
      $skelFullFileName = "$skelDir$dirSep$skel";
    }

    my $inSkel;
    if ( !open ($inSkel, "<", "$skelFullFileName") ) { # open has failed so reset to state on input
      displayError("Open of $skelFullFileName has failed", $currentSubroutine);
      $currentScope = pop(@imbedStack);
      $currentSkelLine = pop(@imbedStack);
      $currentActiveSkel = pop(@imbedStack);
      my $tempScope = pop(@scopeStack);
      setVariable('currentSkeleton',$currentActiveSkel);         # set the currentSkeleton variable
      undef $skelArray{$skel};
      return;
    }
    else { # load it up
      my $i = 0;
      while ( <$inSkel> ) {
        #remove all linebreak information
        $_ =~ s/\r//g;     #just to cater for Windows and Unix input
        $_ =~ s/\n//g;     #just to cater for Windows and Unix input
        $skelLines[$skelArray{$skel}][$i++] = $_;
      }
    }
    close $inSkel;
  }
} # end of loadSkel

sub establishCursor {
  # -----------------------------------------------------------
  # Routine to take connection details and open a cursor to a database
  #
  # Usage: establishCursor(<DB Connection>,<cursor ref>) 
  # -----------------------------------------------------------

  my $currentSubroutine = 'establishCursor'; 

  my $DBConnectionRef = shift;   # database connection to use
  my $cursorRef = shift;
  my $SQL = substituteVariables($cursorSQL{$cursorRef});    # take the SQL and substitute variables as necessary

  displayDebug("Establishing cursor for $cursorRef using SQL statement \'$SQL\'",1,$currentSubroutine);

  # We should not be here if the database connection has not been verified already

  setVariable('LASTSQL',$SQL);       # save SQL as a variable

  if ( $SQL =~ /\&\#92/ ) { # SQL Contains back slashes
    $SQL =~ s/\&\#92/\\/g;  # convert the back slashes to double backslashes
  }

  if ( $skelShowSQL eq "Yes" ) { # print out the SQL being run ...
    if ( $outputMode eq "STDOUT" ) { # just print it ...
      outputLine ("SQL:\n $SQL");
    }
    else { # assume it is directed to something web aware
      outputLine("SQL:<BR>\n<PRE>$SQL</PRE><BR>\n<HR>");
    }
  }

  $cursorRowNumber{$cursorRef} = 0;

  # prepare the statement

  $skelCursor{$cursorRef} = $skelConnection{$DBConnectionRef}->prepare($cursorSQL{$cursorRef});
  if ( defined($skelConnection{$DBConnectionRef}->errstr) ) { #  cursor was established
    displayError("Prepare error returned: " . $skelConnection{$DBConnectionRef}->errstr,$currentSubroutine);
    return 0;
  }

  # cursor has been successfully prepared ..... execute the statement 

  if ( $skelCursor{$cursorRef}->execute ) {  
    # non zero return code means it all worked ok
  }
  else { # errors on the execute ...
    displayError("Execute error returned: " . $DBI::errstr,$currentSubroutine);
    return 0;
  }

  # fetch the first row ....

  $SQLError = 0;
  $skelCursor{$cursorRef}->{'LongTruncOk'} = 1;
  $skelCursor{$cursorRef}->{'LongReadLen'} = 20000;

  my @tArr;     # temporary array to hold the information being returned

  if ( @tArr = $skelCursor{$cursorRef}->fetchrow_array ) { 
    $skelCursorRow{$cursorRef} = [@tArr];
    $cursorRowNumber{$cursorRef} = 1;
    push (@cursorStack, $currentCursorConnection); # save the current Cursor Ref
    $currentCursorConnection = $cursorRef;         # keep track of the last cursor opened
  }
  else { # problems returning the data
    if ( defined($skelCursor{$cursorRef}->errstr()) ) { # an error occurred
      if ( $skelCursor{$cursorRef}->errstr() =~ 'SQL0100W' ) { # no row found so only print if requested
        if ( $skelVerboseSQLErrors eq "Yes" ) { # print error for no row found
          displayError("Execute returned no rows: " . $skelCursor{$cursorRef}->errstr(),$currentSubroutine);
        }
      }
      else {
        $SQLError = 1;
        displayError("Execute error returned: " . $skelCursor{$cursorRef}->errstr(),$currentSubroutine);
      }
    }
    elsif ( defined($DBI::errstr) ) {
      $SQLError = 1;
      displayDebug("Error string returned from fetchrow_array: $DBI::errstr",2,$currentSubroutine);
    }
    else {
      $SQLError = 1;
      displayDebug("An error occurred but I'm not sure what when I tried to read the first row",2,$currentSubroutine);
    }
    return 0;
  } 

  return 1;    # indicate that all is ok

} # end of establishCursor

sub establishCursor_NoReturnedRows {
  # -----------------------------------------------------------
  # Routine to take connection details and execute a supplied SQL
  #
  # Usage: establishCursor_NoReturnedRows(<DB Connection>,<cursor ref>) 
  #
  # Return codes:
  #     undef: Error when executing the statement
  #         0: no rows were affected
  #        nn: number of rows that were affected
  # -----------------------------------------------------------

  my $currentSubroutine = 'establishCursor'; 

  my $DBConnectionRef = shift;   # database connection to use
  my $cursorRef = shift;
  my $SQL = substituteVariables($cursorSQL{$cursorRef});    # take the SQL and substitute variables as necessary

  displayDebug("Executing SQL using SQL statement \'$SQL\'",1,$currentSubroutine);

  # We should not be here if the database connection has not been verified already

  setVariable('LASTSQL',$SQL);       # save SQL as a variable

  if ( $SQL =~ /\&\#92/ ) { # SQL Contains back slashes
    $SQL =~ s/\&\#92/\\/g;  # convert the back slashes to double backslashes
  }

  if ( $skelShowSQL eq "Yes" ) { # print out the SQL being run ...
    if ( $outputMode eq "STDOUT" ) { # just print it ...
      outputLine ("SQL:\n $SQL");
    }
    else { # assume it is directed to something web aware
      outputLine("SQL:<BR>\n<PRE>$SQL</PRE><BR>\n<HR>");
    }
  }

  $cursorRowNumber{$cursorRef} = 0;
  
  # execute the statement
  
  my $rows = $skelConnection{$DBConnectionRef}->do($SQL);

  if ( ! defined($rows) ) { # an error occurred
    displayError("Error when executing statement $SQL\nExecute error returned: " . $DBI::errstr,$currentSubroutine);
    return undef;    # indicates an error
  }

  return $rows;    # return the number of rows affected

} # end of establishCursor_NoReturnedRows

sub closeCursor {
  # -----------------------------------------------------------
  # This routine just releases some storage and reverts to 
  # previous variables
  #
  # Usage: closeCursor(<Cursor reference>)
  # Returns: Nothing
  # -----------------------------------------------------------

  my $currentSubroutine = 'closeCursor'; 
  
  my $cursorRef = shift;    # get the cursor ref
  
  displayDebug("Closing Cursor $cursorRef",2,$currentSubroutine);
  $skelCursor{$cursorRef}->finish();                # not really needed but tidier
  undef $skelCursor{$cursorRef};                    # undefine the cursor
  # NOTE: this does not close the connection - just loses the SQL statement results 
  
  $currentCursorConnection = pop (@cursorStack);    # restore the previous cursor Ref
  
} # end of closeCursor

sub getNextRecord {
  # -----------------------------------------------------------
  # Routine to read the next record from the current cursor
  #
  # Usage: getNextRecord(<cursor Ref>)
  # Returns the 
  # -----------------------------------------------------------

  my $currentSubroutine = 'getNextRecord'; 
  
  my $cursorRef = shift; 
  my @tArr;     # temporary array to hold the information being returned

  if ( @tArr = $skelCursor{$cursorRef}->fetchrow_array ) { 
    $skelCursorRow{$cursorRef} = [@tArr];         # establish the data to be passed back
    $cursorRowNumber{$cursorRef}++;               # increment the row count
    return 1;                                     # data returned
  }
  else {
    undef $skelCursorRow{$cursorRef};             # remove the old data from the data array
    return 0;                                     # end of cursor
  }
  
} # end of getNextRecord

sub getToken {
  # -----------------------------------------------------------
  # Routine to return the next space delimited token in a supplied parameter
  #
  # Current position is held in a global variable as it may be used in other routines
  #
  # Usage: getToken("input string")   # current line pos is held in global $currentLinePosition
  # Returns: <next space delimited token>
  # -----------------------------------------------------------

  my $currentSubroutine = 'getToken'; 
  my $tLine = shift;
  my $tTok = "";

  displayDebug("Line: $tLine Start Pos: $currentLinePosition",2,$currentSubroutine);
  # Skip whitespace
  while ( ($currentLinePosition <= length($tLine) ) && (substr($tLine,$currentLinePosition,1) =~ /\s/) ) {
    $currentLinePosition++;
  }

  if ( $currentLinePosition > length($tLine) ) { # reached the end of the line so no more tokens
    return '';
  }

  # Set token value
  if ( (substr($tLine,$currentLinePosition,1) eq "\'" ) || (substr($tLine,$currentLinePosition,1) eq "\"" ) ) { # it starts with a quote
    my $termQuote = substr($tLine,$currentLinePosition,1);
    displayDebug("Token is a string. Terminating character has been set as >$termQuote<",2,$currentSubroutine);
    $currentLinePosition++;
    while ( ($currentLinePosition <= length($tLine) ) && (substr($tLine,$currentLinePosition,1) ne $termQuote) ) {
      $tTok .= substr($tLine,$currentLinePosition,1);
      $currentLinePosition++;
    }
  }
  else { # just provide the next whitespace delimited token
    displayDebug("Token is not a string. Terminating character has been set as whitespace",2,$currentSubroutine);
    while ( ($currentLinePosition <= length($tLine) ) && (substr($tLine,$currentLinePosition,1) !~ /\s/) ) { # not at end of line and not whitespace
      $tTok .= substr($tLine,$currentLinePosition,1);
      $currentLinePosition++;
    }
  }
  
  displayDebug("Token identified was: $tTok",2,$currentSubroutine);
  $currentLinePosition++; # move to the next position
  return $tTok;

} # end of getToken

sub getFileInformation {
  # -----------------------------------------------------------
  # Gather information about the passed file name
  #
  # Will create/update the following variables:
  #
  #   {suffix}_mode 
  #   {suffix}_uid 
  #   {suffix}_gid
  #   {suffix}_size
  #   {suffix}_accessed
  #   {suffix}_modified 
  #   {suffix}_chginode
  #   {suffix}_user
  #   {suffix}_group
  #
  # Usage: getFileInformation(filename,suffix)
  # Returns: nothing but sets a number of internal variables
  # -----------------------------------------------------------

  my $currentSubroutine = 'getFileInformation'; 
  my $file = shift;
  my $suff = shift;
  
  if ( ! defined($suff) ) { $suff = 'DOF' } ;
  
  # stat the file  ....

  my ($a, $m, $c) ;
  my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($file);

  if ( defined($size) ) { # stat worked
    $a = scalar localtime $atime;
    $m = scalar localtime $mtime;
    $c = scalar localtime $ctime;
  }
  else { # stat failed
    $dev = 'Not Found';
    $ino = 'Not Found';
    $mode = 'Not Found';
    $nlink = 'Not Found';
    $uid = 'Not Found';
    $gid = 'Not Found';
    $rdev = 'Not Found';
    $size = 'Not Found';
    $blksize = 'Not Found';
    $blocks = 'Not Found';
    $atime = 'Not Found';
    $mtime = 'Not Found';
    $ctime = 'Not Found';
    $a = 'Not Found';
    $m = 'Not Found';
    $c = 'Not Found';
  }
  
  setVariable($suff . '_mode', $mode);
  setVariable($suff . '_uid', $uid);
  setVariable($suff . '_gid', $gid);
  setVariable($suff . '_size', $size);
  setVariable($suff . '_accessed', $a);
  setVariable($suff . '_modified', $m);
  setVariable($suff . '_chginode', $c);

  if ( $size ne 'Not Found' ) { # stat worked
    my $userName = '';
    my $x = getpwuid($uid);
#print "Ref: " . ref($x) . "\n"; 
    if ( ref($x) eq 'User::pwent' ) { # an array was returned
      $userName = $$x[0];
    }
    else {
      $userName = $x;
    }
    setVariable($suff . '_user', $userName ) ; 
    setVariable($suff . '_group', getgrgid($gid));
  }
  else {
    setVariable($suff . '_user', 'Not Found');
    setVariable($suff . '_group', 'Not Found');
  }
  
  my $directory = '';
  my $fname = '';
  if ( $file =~ /[\/\\]/ ) { # it contains one of / or \
    ($directory, $fname) = ($file =~ /(.*)[\/\\](.*)/);
  }
  else {  
    $fname = $file;
  }  
  
  setVariable($suff . '_directory',$directory);
  setVariable($suff . '_file',$fname);

} # end of getFileInformation

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

sub getDate2 {
  # -----------------------------------------------------------
  #  Routine to return a formatted Date in YYYYMMDD format
  #
  # Usage: getDate2()
  # Returns: YYYYMMDD
  # -----------------------------------------------------------

  my $currentSubroutine = 'getDate'; 
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  my $year = 1900 + $yearOffset;
  $month = $month + 1;
  $month = substr("0" . $month, length($month)-1,2);
  my $day = substr("0" . $dayOfMonth, length($dayOfMonth)-1,2);
  return "$year$month$day";
} # end of getDate2

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

sub outputLine {
  # -----------------------------------------------------------
  # This routine is the main conduit for output from processSkeleton
  # 
  # Usage: outputLine('text');
  # Returns : nothing
  # Outputs: Either prints to STDOUT or appends to a string (which will be returned  
  #          at the end of the routine.
  # -----------------------------------------------------------

  my $currentSubroutine = 'outputLine'; 

  my $line = shift;
  $line = putInTabs($line); 

  if ( length($skelReturnString) > $skelMaxOutput ) { return; } # once the limit is exceeded add no more

  $outputLineCount++;

  if ( $outputMode eq "STDOUT" ) {
    if ( $skelDebugLevel > 0 ) { # While debugging number the lines
      print "$outputLineCount: $line\n";
    }
    else {
      print "$line\n";
    }
  }
  elsif ( $outputMode eq "HTTPFILE" ) {
    $skelReturnString .= "\n$line"
  }
  else { # just add it to the return string (the mode should be HTTP)
    # dont do it for the first line ....
    if ( $outputLineCount == 1 ) {
      $skelReturnString .= "$line"
    }
    else {
      $skelReturnString .= "\n$line"
    }
  }

  # check if we have now exceeded the limit
  if ( length($skelReturnString) > $skelMaxOutput ) {
    $skelReturnString .= "\n\nOutput Terminated as it has exceeded the limit of $skelMaxOutput characters\n";
    if ( $outputMode eq "HTTP" ) {
      $skelReturnString .= "</BODY></HTML>"; # put HTML termination strings in just in case
    }
  }

  my $tmpLen = length($skelReturnString);
  displayDebug("\$newString=$line",2,$currentSubroutine);
  displayDebug("ret string length=$tmpLen",2,$currentSubroutine);
  displayDebug("\$skelReturnString=$skelReturnString",3,$currentSubroutine);

} # end of outputLine

sub outputLineNT {
  # -----------------------------------------------------------
  # This routine is the main conduit for output from processSkeleton
  # it is basically the same as outputLine but with no tab replacemnent
  #
  # Usage: outputLineNT('text');
  # Returns : nothing
  # Outputs: Either prints to STDOUT or appends to a string (which will be returned
  #          at the end of the routine.
  # -----------------------------------------------------------

  my $currentSubroutine = 'outputLine';

  my $line = shift;

  $outputLineCount++;

  if ( $outputMode eq "STDOUT" ) {
    if ( $skelDebugLevel > 0 ) { # While debugging number the lines
      print "$outputLineCount: $line\n";
    }
    else {
      print "$line\n";
    }
  }
  elsif ( $outputMode eq "HTTPFILE" ) {
    $skelReturnString .= "\n$line"
  }
  else { # just add it to the return string (the mode should be HTTP)
    # dont do it for the first line ....
    if ( $outputLineCount == 1 ) {
      $skelReturnString .= "$line"
    }
    else {
      $skelReturnString .= "\n$line"
    }
  }

  displayDebug("\$skelReturnString=$skelReturnString",2,$currentSubroutine);

} # end of outputLineNT

sub displayNote {
  # -----------------------------------------------------------
  # This routine outputs some text in a highlighted fashion
  # 
  # Usage: displayNote(<text>)
  # Returns : nothing
  # Outputs: Either prints to STDERR or outputs the string to STDOUT
  #          but brackets it with <BR><b>.....</b><BR>
  # -----------------------------------------------------------

  my $currentSubroutine = 'displayNote'; 

  my $line = shift;
  $line = putInTabs(substituteVariables($line)); 

  if ( $outputMode eq "STDOUT" ) {
    if ( $skelDebugLevel > 0 ) { # While debugging number the lines
      print STDERR "$outputLineCount: $line\n";
    }
    else {
      print STDERR "$line\n";
    }
  }
  elsif ( $outputMode eq "HTTPFILE" ) {
    $skelReturnString .= "\n<BR><B>$line</B><BR>"
  }
  else { # just add it to the return string (the mode should be HTTP)
    # dont do it for the first line ....
    if ( $outputLineCount == 1 ) {
      $skelReturnString .= "$line"
    }
    else {
      $skelReturnString .= "<BR>\n$line"
    }
  }

} # end of displayNote

sub getLong {
  # -----------------------------------------------------------
  # Routine to read a logn value from a DB cursor
  # 
  # Usage: getLong(<cursor ref>,column#);
  # Returns: the long column from the row pointed to by the cursor
  # -----------------------------------------------------------

  my $currentSubroutine = 'getLong'; 

  my $csrREF  = shift; # cursor literal be read from
  my $colNum  = shift; # column number in cursor
  $colNum++; # Adjust column position (not sure why this is done but perhaps blob_read counts from 1)

  my $offset = 0;
  my $buff = "";
  my $colValue = "";

  displayDebug("Starting to process long column",2,$currentSubroutine);

  while ( $buff = $csrREF->blob_read( $colNum, $offset, 10000 )) {
    $colValue .= $buff;
    $offset += length($buff);
    $buff = "";
    displayDebug("value = " . $colValue,2,$currentSubroutine);
  }

  return $colValue;

} # end of getLong

sub generateUnique {
  # -----------------------------------------------------------
  # This routine will return a 20 byte unique (ish) string
  # It will attempt to use the Data::UUID package but if not available
  # it will generate a string of random characters starting with an alpha character
  #
  # Usage: generateUnique()
  # Returns: A 20 byte random character string 
  # -----------------------------------------------------------
  
  my $u_string = '';
  
  if ( defined($ug) ) { # the Data::UUID package has been installed and uncommented above
    $u_string = $ug->create_str();
  }
  else { # just make up a psuedo unique value
    my @a = ('a'..'z','A'..'Z'); # printable ASCII chars
    
    $u_string = $a[rand(@a)]; # make the 1st character an alpha char
    
    @a = ('a'..'z','A'..'Z','0'..'9'); # printable ASCII chars
              
    $u_string .= $a[rand(@a)] for 1..19;
  }
  return $u_string;

} # end of generateUnique

sub substituteVariables {
  # -----------------------------------------------------------
  # This routine will perform variable substition. It will find variables
  # in the skeleton variable table and in operned cursors
  #
  # A variable will look like [<cursor ref>.]:<fieldname>
  #
  # The search for variables will be:
  #    1. if a cursor ref is specified,  only that cursor will be checked, no further searches will be done
  #    2. If no cursor is specified then the last used cursor will be checked 
  #       and if not found there then the sekelton variables will be checked
  #    3. If no cursor is specified and no cursors have been opened then 
  #       the sekelton variables will be checked
  #
  # Usage: substituteVariables(<string to have variables substituted>)
  # Returns: A string with all substitutions made
  # -----------------------------------------------------------

  my $currentSubroutine = 'substituteVariables'; 
  my $inputString = shift;           # retrieve the string to process
  my $convString = '';               # this variable will contain the converted string
  my $origRef = '';                  # This will hold the reference as obtained from the line
  my $origVar = '';                  # This will hold the variable name as obtained from the line
  my $varTerminatedByPeriod = 0;     # flag indicating if variable terminated by period

  if ( $inputString =~ /:/ ) { # there is a chance that a variable is in the line 
    displayDebug("Variables to replace in: \n$inputString\n0....+....1....+....2....+....3....+....4....+....5....+....6....+....7....+....8....+....9....+....0....+....1....+....2....+....3....+....4....+....5",2,$currentSubroutine);
    
    my $linePos = 0;                 # current posiiton in the original string 
    my $leftEdge = 0;                # contains the point in the string following the last variable found
    my $fieldEnd = 0;                # temp field indicating the end pos of a field in the input string
    my $fieldStart = 0;              # temp field indicating the start pos of a field in the input string
    my $i = 0 ;                      # position of the : char currently being investigated
    my $tRef = '';                   # holds the cursor reference for a field

    while ( ($linePos > -1) && ( $linePos <= length($inputString)) ) { # while current position is in the string
      $tRef = '';                    
      $i = index($inputString,':',$leftEdge);    # search for the next ':'
      $linePos = $i + 1;                         # skip to the next char
      $fieldStart = $i ;                         # establish the beginning of the field name (if no cursor ref is supplied)
      displayDebug("(at start) \$i=$i",1,$currentSubroutine);

      # check if the : is preceded by a backslash (in which case it is NOT a variable)
      if ( $i > 1 ) {                                # cant have a cursor ref it is less than 1
        # processSkeleton only allows the escaping of a : character or in the event that a \ validly precedes a : then that single \ can be escaped
        # this means that the only situations that can arise are:
        #    1. test\:VAR meaning test:VAR (no variable substitution)
        #    2. test\\:VAR meaning test\:VAR (variable substitution)A
        #    3. test:VAR meaning test:VAR (variable substitution)
        if ( substr($inputString,$i-1,1) eq '\\' ) { # May be case 1 or case 2
          if ( substr($inputString,$i-2,2) eq '\\\\' ) { # it is case 2
            # we just need to remove one of the \s and then treat as a normal variable substitution
            displayDebug("Colon will be treated as a variable as it is not escaped \$linepos=$linePos, \$i: $i" . ",char=" . substr($inputString,$i-1,1),1,$currentSubroutine);
            my $tmpString = substr($inputString, 0, $i-1) . substr($inputString, $i);   # just move the string left 1 char
            $inputString = $tmpString;
            $i--;              # adjust the pointer to the colon
            $fieldStart = $i;  # adjust the start of the field being tested
            $linePos = $i + 1; # adjust the start of the variable name
          }
          else { # the : is being escaped and so isn't a variable indicator (case 1)
            displayDebug("Colon will not be treated as a variable as it is escaped \$linepos=$linePos, \$i: $i" . ",char=" . substr($inputString,$i-1,1),1,$currentSubroutine);
            $convString .= substr($inputString, $leftEdge, $fieldStart - $leftEdge - 1) . ":";   # just move across the text from the end of the last field to just after the ':' character
            $leftEdge = $linePos;                      # Reset the leftedge to be just after the ':' character just worked with
            if ( index($inputString,':',$leftEdge) == -1 ) {                             # no more colons in the string
              $linePos = -1;                                                             # set line position off    
              $convString .= substr($inputString, $fieldStart+1);                        # copy across the remaining string bit
              displayDebug("No more \: to process in input string",3,$currentSubroutine);
              last;                                                                      # leave the while loop as nothing more to process
            }
            next;
          }
        }
      }
      
      # check if there is a cursor reference (defined as a '.' preceding the ':')
      if ( $i > 1 ) {                               # cant have a cursor ref it is less than 1
        if ( substr($inputString,$i-1,1) eq '.' ) { # there should be a cursor reference as we have a .: in the middle of the string 
          displayDebug("\$i: $i" . ",char=" . substr($inputString,$i-1,1),3,$currentSubroutine);
          # loop backwards to find the cursor name until you come across a termination char
          $i = $i - 2;                              # skip basck over the .: characters - should now be pointing at the char before the '.'
          displayDebug("termChar=$skelTermChar, cmpChar=" . substr($inputString, $i, 1) . ", \$i=$i",3,$currentSubroutine);

          while ( ( $i > -1 ) && index( $skelTermChar, substr($inputString, $i, 1) ) == -1 ) { # While character is not a termination character
            $tRef = substr($inputString, $i, 1) . $tRef;    # add the character to the front of the cursor name
            $i = $i - 1;
            if ( $i > -1 ) { # if not past the beginning of the line then print out the characters being compared
              displayDebug("tRef=$tRef, termChar=$skelTermChar, cmpChar=" . substr($inputString, $i, 1) . ", \$i=$i",3,$currentSubroutine);
            }
          } 
          if ( $tRef ne "" ) {              # if a cursor reference has been found
            $fieldStart = $i + 1;             # reset the start of field (i.e we are going to replace the string from this point to the end of the field name)
          }
        }
      }

      # $tRef now contains the name of the cursor
      displayDebug("Cursor is:$tRef, fieldStart=$fieldStart, \$i=$i",2,$currentSubroutine);
      # now identify the variable name we are looking for
      my $varName = "";
      $varTerminatedByPeriod = 0;
      my $varEnclosedInBrackets = 0;

      if ( $linePos <= length($inputString) ) {displayDebug("termChar=$skelTermChar, cmpChar=" . substr($inputString, $linePos, 1),3,$currentSubroutine); }
 
      # $linePos is pointing to the start of the variable name 
      if ( substr($inputString, $linePos, 1) eq '{' ) { # variable name is enclosed in brackets ... so just look for closing bracket
        $varEnclosedInBrackets = 1;
        $linePos++;     # move to the next char
        while ( ($linePos <= length($inputString) ) && (substr($inputString, $linePos, 1) ne '}' ) ) {
          $varName = $varName . substr($inputString, $linePos, 1);
          $linePos++;     # move to the next char
        }
        if ($linePos <= length($inputString) ) { $linePos++; }    # move to the next char (skip the terminating bracket
      }
      else { # normal variable identification
        while ( ($linePos <= length($inputString) ) && (index( $skelTermChar, substr($inputString, $linePos, 1) ) == -1 ) ) {
          $varName = $varName . substr($inputString, $linePos, 1);
          $linePos++;
          if ( $linePos <= length($inputString) ) { displayDebug("varName= $varName, termChar=$skelTermChar, cmpChar=" . substr($inputString, $linePos, 1),3,$currentSubroutine); }
        }
      }

      displayDebug("Variable: $varName, \$linePos=$linePos",1,$currentSubroutine);
      if ( $varName eq "" ) {               # no variable name so just a colon
        $convString .= substr($inputString, $leftEdge, $fieldStart - $leftEdge + 1); # just move across the text from the end of the last field to just after the ':' character
        $leftEdge = $linePos;                                                        # Reset the leftedge to be just after the ':' character just worked with
        displayDebug("\$leftEdge=$leftEdge, \$linePos=$linePos, \$convString=$convString",3,$currentSubroutine);
        if ( index($inputString,':',$leftEdge) == -1 ) {                             # no more colons in the string
          $linePos = -1;                                                             # set line position off    
          $convString .= substr($inputString, $fieldStart+1);                        # copy across the remaining string bit
          displayDebug("No more \: to process in input string",3,$currentSubroutine);
          last;                                                                      # leave the while loop as nothing more to process
        }
        next;                                                                        # loop aroud to get to the next variable
      }
      else { #var name has been identified
        if ( $varEnclosedInBrackets ) { # period not terminating variable
          # treat any subsequent periods as just characters
        }
        else {
          if ( substr($inputString, $linePos, 1) eq '.' ) { # skip periods terminating variables
            $linePos++; 
            $varTerminatedByPeriod = 1;
          } 
        }
      }
      $fieldEnd = $linePos -1;

      # At this point $tRef contains cursor and $varName contains the variable name

      $origRef = $tRef;
      $origVar = $varName;
      if ( $tRef eq '' ) { # no cursor supplied so try the last cursor opened .....
        if ( defined($currentCursorConnection) && defined($skelCursor{$currentCursorConnection}) ) { # only assign the most recent if it still exists
          $tRef = $currentCursorConnection; 
        }
      } 
      else { # check to see if the supplied cursor exists ....
        if ( ! defined($skelCursor{$tRef} ) ) { # the cursor doesn't exist so dont replace the reference
          $fieldStart = $fieldStart + length($tRef) + 1;      # ignore the cursor name - just try for the field
          $tRef = '';
        }
      }
      # If $tRef is not null then the cursor exists (doesn't mean the field does though)

      # Before we go too far there are some variables that are always set by the system (SYSDATE, SYSTIME, SKELETON)

      my $skelFieldValue = '';        # value of the variable
      my $skelFieldFound = 'No';      # flag indicating if the variable had been found

      if ( $tRef ne "" ) { # cursor supplied (or defaulted) so check if it is a system or skeleton variable
        if ( uc($varName) eq 'ROWNUM' ) { # will return the count of rows read from cursor
          $skelFieldValue = $cursorRowNumber{$tRef};
          $skelFieldFound = "Yes";
          displayDebug("ROWNUM identified and returned a value of $skelFieldValue",2,$currentSubroutine);
        }
        else { # check the cursor to see if the variable name exists there
          if ( ! $skelCaseSensitiveColumns ) { # if not case sensitive then do all comparisons in upper case
            $varName = uc($varName);
          }
          # $skelCursor{$tRef} contains the active cursor
          my $numCols = $skelCursor{$tRef}->{NUM_OF_FIELDS}; # get the number of columns in the cursor
          displayDebug("Number of columns in cursor $tRef is $numCols",2,$currentSubroutine);

          my $j;        # $j will hold the column being used

          $skelFieldFound = 'No';              # establish the default value
          for ( $j=0; $j < $numCols; $j++ ) { # loop through the column names to see if there is a match
            displayDebug("Column Checking ($varName in $tRef):" ,2,$currentSubroutine);
            displayDebug("Column Checking ($varName): >$skelCursor{$tRef}->{NAME}->[$j]<",2,$currentSubroutine);
            if ( $skelCaseSensitiveColumns ) { # Case sensitive
              if ( $varName eq $skelCursor{$tRef}->{NAME}->[$j]) { # field found
                $skelFieldFound = "Yes";
                last; # skip to the end of the for loop
              }
            }
            else { # Case Insensitive
              if ( $varName eq uc($skelCursor{$tRef}->{NAME}->[$j]) ) { # field found
                $skelFieldFound = "Yes";
                last; # skip to the end of the for loop
              }
            }
          } # end of for loop
          if ( $skelFieldFound eq "Yes" ) { # field found in the cursor, $j points to the column 
            displayDebug("Column " . $varName . " found",2,$currentSubroutine);
            my $fieldType = $skelCursor{$tRef}->{TYPE}->[$j];
            # -------------------------------------------------------------------------
            # Field types are:
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
            #                     93    Timestamp
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
            # -------------------------------------------------------------------------

            $skelFieldValue = '';           # initialise it to empty
            $skelFieldValue = getTabValue($fieldType, ${$skelCursorRow{$tRef}}[$j], $tRef,  $j);   # pass field type and the field across
          }
          else { # $skelFieldFound = 'No'
            $skelFieldFound = "No";
            displayDebug("Field not found in cursor",2,$currentSubroutine);
          }
        }
      }

      if ( $skelFieldFound eq 'No') { # if variable not set yet
        if ( ($tRef eq "") || ($origRef eq '')  ) { # no cursor supplied originally so check local variables
          $varName = $origVar;                      # for the moment local variables are always case sensitive
          displayDebug("Field being searched for as a local variable is '$varName'",2,$currentSubroutine);
          if ( uc($varName) eq "SYSDATE" ) {
            $skelFieldFound = "Yes";
            $skelFieldValue = getDate;
          }
          elsif ( uc($varName) eq "SYSTIME" ) {
            $skelFieldFound = "Yes";
            $skelFieldValue =  getTime;
          }
          elsif ( uc($varName) eq "SKELETON" ) {
            $skelFieldFound = "Yes";
            $skelFieldValue = $currentActiveSkel;
          }
          elsif ( uc($varName) eq "UNIQUE_STR" ) {
            $skelFieldFound = "Yes";
            $skelFieldValue = generateUnique();
          }
          elsif ( uc($varName) eq 'SKELDELIMITER' ) { 
            $skelFieldValue = $skelDelimiter; 
            $skelFieldFound = "Yes";
          }
          elsif ( uc($varName) eq 'SKELDEBUGMODULES' ) { 
            $skelFieldValue = $skelDebugModules;
            $skelFieldFound = "Yes";
          }
          elsif ( uc($varName) eq 'SKELSHOWSQL' ) { 
            $skelFieldValue = $skelShowSQL;
            $skelFieldFound = "Yes";      
          }
          elsif ( uc($varName) eq 'SKELVERBOSESQLERRORS' ) { 
            $skelFieldValue = $skelVerboseSQLErrors;
            $skelFieldFound = "Yes";      
          }
          elsif ( uc($varName) eq 'OUTPUTMODE' ) { 
            $skelFieldValue = $outputMode;
            $skelFieldFound = "Yes";      
          }
          elsif ( uc($varName) eq 'SKELMAXOUTPUT' ) { 
            $skelFieldValue = $skelFieldValue;
            $skelFieldFound = "Yes";      
          }
          elsif ( uc($varName) eq 'SKELMAXROWS' ) { 
            $skelFieldValue = $skelMaxRows; 
            $skelFieldFound = "Yes";
          }
          elsif ( uc($varName) eq 'SKELMAXTABLEOUT' ) { 
            $skelFieldValue = $skelMaxTableOut; 
          }
          elsif ( uc($varName) eq 'SKELDEBUGLEVEL' ) { 
            $skelFieldValue = $skelDebugLevel; 
            $skelFieldFound = "Yes";
          }
          elsif ( uc($varName) eq 'TESTROUTINES' ) { 
            $skelFieldValue = $testRoutines; 
            $skelFieldFound = "Yes";
          }
          elsif ( uc($varName) eq 'INDEXCASEINSENSITIVE' ) { 
            $skelFieldValue = $indexCaseInsensitive; 
            $skelFieldFound = "Yes";
          }

          # If still not found then check for a skeleton variable
          elsif ( defined(getVariable($varName)) ) {
            $skelFieldFound = "Yes";
            $skelFieldValue = getVariable($varName);
          }
        }
      }

      # done all of the looking we'll do .....
      # if still not found then recreate the entry 
      if ( $skelFieldFound eq 'No') {
        displayDebug("Recreating variable entry as value not found for >$varName<",2,$currentSubroutine);
        if ( $varTerminatedByPeriod) { # add the period back to the end of the string ....
          $varName .= '.';
        } 
        if ( $origRef eq "" ) { # no cursor ref supplied
          $skelFieldValue = "\:$varName";
        }
        else { # add in the cursor ref
          $skelFieldValue = "$tRef\.\:$varName";
        }
      }
      
      # replace the variable into the line 
      displayDebug("++convString=$convString, inputString=$inputString, leftEdge=$leftEdge,fieldStart=$fieldStart,fieldEnd=$fieldEnd, substr=" . substr($inputString, $leftEdge, $fieldStart - $leftEdge) . ",skelFieldValue=>" . $skelFieldValue . "<",2,$currentSubroutine);
          
      $convString .= substr($inputString, $leftEdge, $fieldStart - $leftEdge) . $skelFieldValue;
      $leftEdge = $fieldEnd + 1;
 
      # check to see if there are any more variables to process

      if ( index($inputString, "\:", $leftEdge) == -1 ) {    # no more variables
        displayDebug("convString=$convString, inputString=$inputString, leftEdge=$leftEdge",2,$currentSubroutine);
        my $a = substr($inputString, $leftEdge);            # gather the stuff to right of the last field found
        displayDebug("substr(\$inputString, \$leftEdge)=$a\n",2,$currentSubroutine);
        $convString = $convString . $a;                     # add it to the converted string
        last;                                               # finish up
      }  
    } # end of while loop
  } 
  else { # no variables to substitute
    $convString = $inputString;
  }

  if ( ($convString eq '') && (trim($inputString) ne '') ) { # if it is a null string and there was something there to start with then return NULL
    return 'NULL';
  }
  else { # return the substituted string
    return $convString;
  }
  
} # end of substituteVariables

sub space {
  # -----------------------------------------------------------
  # This routine will return a string of space of a specified length
  # 
  # Usage: space(<length of return string>);
  # returns: a string of space of a defined length
  # -----------------------------------------------------------

  my $currentSubroutine = 'space'; 

  my $strLength = shift;
  return multiChar(" ",$strLength);

} # end of space

sub putInTabs {
  # -----------------------------------------------------------
  # Routine to convert ! characters to enough spaces to match tab marks
  # specified using a )TAB command
  #
  # note by default: a ! will space fill to the next tab stop
  #                  a ~ will get the next token and right justify it to the next tab stop
  #
  # Usage: putInTabs(<string>)
  # Returns: a variable with tabs characters space filled to tab stops
  # -----------------------------------------------------------

  my $currentSubroutine = 'putInTabs'; 
  my $convString = shift;     # retrieve the string to process

  my $pad = "";               # variable used to hold the string padding

  if ( $#tabEntries > 0 ) {   # tabs have been defined
    displayDebug("Adjusting tabs",1,$currentSubroutine);
    my $iPos = index($convString, $leftJustTab) ;                    # check if a left justify tab stop in the string
    my $jPos = index($convString, $rightJustTab) ;                    # check if a right justify tab stop is in the string
    displayDebug("$leftJustTab Pos: $iPos, $rightJustTab Pos: $jPos, Line: $convString",2,$currentSubroutine);

    # if both iPos and jPos were -1 (i.e. neither string found) then their sum would be -2
    while ( $iPos + $jPos > -2 ) {                                               # tab stops found in string
      if ( (( $iPos < $jPos ) && ( $iPos > -1 )) || ( $jPos == -1 ) ) {          # if no ~ found OR a ! was found before the ~ then ! to process next
        $pad = " ";
        # look for the tab stop that applies
        displayDebug("tabEntries=$#tabEntries",2,$currentSubroutine);
    
        for ( my $i=0; $i <= $#tabEntries; $i++ ) {                               # for each tab stop entry
          displayDebug("tabEntries[$i]=$tabEntries[$i],iPos=$iPos",2,$currentSubroutine);
          if ( $tabEntries[$i] >= $iPos ) {                                      # found first tab marker past the ! character 
          displayDebug("Tab stop found is $tabEntries[$i], iPos: $iPos",2,$currentSubroutine);
          if ( $iPos == 0 ) { # special case as it is the first character
            $pad = space($tabEntries[$i] - $iPos);
          }
          else { 
            $pad = space($tabEntries[$i] - $iPos);
          }
          last;                               
        }
      }   
      # replace the tab
      if ( $iPos == 0 ) { # special case as it is the first character - just pad the front and skip the 1st character
        $convString = $pad . substr($convString, 1);
      }
      else {
        $convString = substr($convString, 0, $iPos) . $pad . substr($convString, $iPos + 1);
      }  
      # rescan for tab stops as the positions will have changed
      $iPos = index($convString, $leftJustTab) ;
      $jPos = index($convString, $rightJustTab) ;
      displayDebug("$leftJustTab Pos: $iPos, $rightJustTab Pos: $jPos, Line: $convString",2,$currentSubroutine);
    }
    else { # $rightJustTab must be next to process (the $rightJustTab means that the next token will be right justified to the tab stop)
      $pad = " ";
      my $kPos = $jPos + 1;
      # find the end of the token
      while ( index($skelTermChar, substr($convString,$kPos,1)) == -1 ) { $kPos++; } 
        $kPos--;   # adjust pos to the last char
        # now we know how long the token is to right justify (kpos - jpos - 1) 
        # now find the tab stop that applies
        for ( my $i=0; $i <= $#tabEntries; $i++ ) {                    # loop through each tab stop  
          if ( $tabEntries[$i] >= $jPos ) {                          # found first tab marker past the ~ character 
            if ( $jPos == 0 ) {                                      # special case as it is the first character
              $pad = space($tabEntries[$i] - $kPos);
            }
            else {  
              $pad = space($tabEntries[$i] - $kPos + 1);
            }  
            last;                                                    # finish the loop
          }
        }
        # now put the padding in 
        if ( $jPos == 0 ) {                                          # special case as it is the first character
          $convString = $pad . substr($convString, $jPos + 1);
        }
        else {                                                       # just insert it into the string
          $convString = substr($convString, 0, $jPos) . $pad . substr($convString, $jPos + 1);
        }
        # rescan for tab stops as the positions will have changed
        $iPos = index($convString, $leftJustTab) ;
        $jPos = index($convString, $rightJustTab) ;
        displayDebug("$leftJustTab Pos: $iPos, $rightJustTab Pos: $jPos, Line: $convString",2,$currentSubroutine);
      }
    }
  }
  return $convString;

} # end of putInTabs

sub isNumeric {
  # -----------------------------------------------------------
  # Routine to check if a supplied parameter is a number or not
  #
  # Usage: isnumeric('123');
  # Returns: 0 - not numeric , 1 numeric
  # -----------------------------------------------------------

  my $currentSubroutine = 'isNumeric'; 

  my $var = shift;
  displayDebug("var is: $var",2,$currentSubroutine);

  if ($var =~ /^\d+\z/)         { return 1; } # only contains digits between the start and the end of the bufer
  displayDebug("Not Only Digits",1,$currentSubroutine);
  if ($var =~ /^-?\d+\z/)       { return 1; } # may contain a leading minus sign
  displayDebug("Doesn't have a leading minus",1,$currentSubroutine);
  if ($var =~ /^[+-]?\d+\z/)    { return 1; } # may have a leading minus or plus
  displayDebug("No leading minus or plus",1,$currentSubroutine);
  if ($var =~ /^-?\d+\.?\d*\z/) { return 1; } # may have a leading minus , digits , decimal point and then digits 
  displayDebug("Not a negative decimal number",1,$currentSubroutine);
  if ($var =~ /^[+-]?(?:\d*\.\d)?\d*(?:[Ee][+-]?\d+)\z/) { return 1; }
  displayDebug("Not scientific notation",1,$currentSubroutine);

  return 0;

} # end of isNumeric

sub evaluateSingleCondition {
  # -----------------------------------------------------------
  # This routine will take 
  # -----------------------------------------------------------

  my $currentSubroutine = 'evaluateSingleCondition'; 
} # end of 

sub evaluateCondition {
  # -----------------------------------------------------------
  # This routine will take a string of the form <expression> <condtion> <expression>
  # and evaluate it for true or false. The string may be multiple comparisons joined 
  # by OR or AND
  #
  # Usage: evaluateCondition(<string>)
  # Returns: 0 for false and 1 for true
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'evaluateCondition'; 
  my $evalStr = shift;
  #my $substitutedStr = substituteVariables(trim($evalStr));
  my $substitutedStr = trim($evalStr);
  $calcDebugLevel = $skelDebugLevel;
  $calcDebugModules = $skelDebugModules;
  my $answer = evaluateInfix($substitutedStr);
  
  displayDebug("The evaluation of $evalStr ($substitutedStr) is $answer",2,$currentSubroutine);
  
  return $answer;

} # end of evaluateCondition

sub evaluateConditionOLD {
  # -----------------------------------------------------------
  # This routine will take an string of the form <expression> <condtion> <expression>
  # and evaluate it for true or false. The string may be multiple comparisons joined 
  # by OR or AND
  #
  # Usage: evaluateCondition(<string>)
  # Returns: 0 for false and 1 for true
  # -----------------------------------------------------------

  my $currentSubroutine = 'evaluateCondition'; 
  
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
} # end of evaluateCondition

sub readDataFileRecord {
  # -----------------------------------------------------------
  # This routine will read te next record from an open file handle
  # Note that it does remove CR before returning the data
  #
  # Usage:  $rec = readDataFileRecord($fh);
  # Return: the next record from the open file handle
  # -----------------------------------------------------------

  my $currentSubroutine = 'readDataFileRecord'; 
  
  my $fh = shift;
  my $fileRef = shift;
  my $ctlCard = shift;
  my $txt = <$fh>;
  if ( defined($txt) ) { 
    if ( $ctlCard eq 'F' ) { 
      $skelFileStatus{$fileRef}++;  # if a record was returned then increment the record count
    }
    else { # should be a value of 'E'
      $skelExecStatus{$fileRef}++;  # if a record was returned then increment the record count
    }
    chomp $txt;
  }
  return $txt;
  
} # end of readDataFileRecord

sub establishDOTLoopPosition {
  # -----------------------------------------------------------
  # Routine to look though the skeleton and identify where the)DOT loop starts
  #
  # a special condition exists where you can have a form like .....
  #
  # CARD 1: )SEL x = 1
  # CARD 2: )DOT .......
  # CARD 3: )SELELSE X = 2
  # CARD 4: )DOT .......
  # CARD 5: )ENDSEL
  # CARD 6->N-1: lots of statements
  # CARD N: )ENDDOT .... this )ENDDOT actually terminates either the first or second )DOT depending on which )SEL is selected
  #              in this case the )DOT loop will loop through 6 -> N
  #
  # Usage: establishDOTLoopPosition(<cursor ref>)
  # Returns: the variable $DOTLocation{$cursorRef} will be set
  # -----------------------------------------------------------

  my $currentSubroutine = 'establishDOTLoopPosition'; 
  
  my $cursorRef = shift;                                                        # get the cursor reference literal
  my $nextSkelLine = $currentSkelLine + 1;
  my $nextCard;
  
  if ( defined( $skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) ) { # the next line exists ....
    $DOTLocation{$cursorRef} = $currentSkelLine;                                # establish where the )DOT looping will return to
    $nextCard = $skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine];      # check out the next card ......
    if ( uc(substr($nextCard,0,8)) eq ')SELELSE' ) {                            # .... special case ... need to find the )ENDSEL
      while ( defined($skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) && (uc(substr($nextCard,0,7)) ne ')ENDSEL') ) { # skip till an )ENDSEL is found
        $nextSkelLine++;
        if ( defined($skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) ) { # next card exists 
          $nextCard = $skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine]; 
        }
      }
      if ( ! defined($skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) ) { # came to the end of the skeleton before finding )ENDSEL
        displayError("Problems with the )DOT. Cant find the )ENDSEL",$currentSubroutine);
        $skelDOTSkipCards = "Yes";                                                   # skip cards till we get to a )ENDDOT at the same level
        $skelDOT_resumeLevel = $skelDOTCount - 1;                                    # level at which processing will be resumed (will be tested for each )ENDDOT encountered)
      }
      else { # found the )ENDSEL so can get on with our life
        $DOTLocation{$cursorRef} = $nextSkelLine - 1;   # establish where the )DOT looping will return to
        displayDebug("Top of DOT loop set to $DOTLocation{$cursorRef}",2,$currentSubroutine);
      }
    } 
  }
  else { # problems ... we've come to the end of the skeleton before finding the )ENDDOT
    displayError("Problems with the )DOT. Cant find the )ENDDOT",$currentSubroutine);
    $skelDOTSkipCards = "Yes";                  # skip cards till we get to a )ENDDOT at the same level
    $skelDOT_resumeLevel = $skelDOTCount - 1;   # level at which processing will be resumed (will be tested for each )ENDDOT encountered)
  }
} # end of establishDOTLoopPosition

sub establishDOFLoopPosition {
  # -----------------------------------------------------------
  # Routine to look though the skeleton and identify where the)DOF loop starts
  #
  # a special condition exists where you can have a form like .....
  #
  # CARD 1: )SEL x = 1
  # CARD 2: )DOF .......
  # CARD 3: )SELELSE X = 2
  # CARD 4: )DOF .......
  # CARD 5: )ENDSEL
  # CARD 6->N-1: lots of statements
  # CARD N: )ENDDOF .... this )ENDDOF actually terminates either the first or second )DOF depending on which )SEL is selected
  #              in this case the )DOF loop will loop through 6 -> N
  #
  # Usage: establishDOFLoopPosition(<cursor ref>)
  # Returns: the variable $DOFLocation{$cursorRef} will be set
  # -----------------------------------------------------------

  my $currentSubroutine = 'establishDOFLoopPosition'; 
  
  my $fileRef = shift;                                                        # get the file reference literal
  my $nextSkelLine = $currentSkelLine ;
  my $nextCard;
  
  if ( defined( $skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) ) { # the next line exists ....
    $DOFLocation{$fileRef} = $currentSkelLine;                              # establish where the )DOF looping will return to (default to the line after the )DOF
    $nextCard = $skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine];      # check out the next card ......
    if ( uc(substr($nextCard,0,8)) eq ')SELELSE' ) {                            # .... special case ... need to find the )ENDSEL
      while ( defined($skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) && (uc(substr($nextCard,0,7)) ne ')ENDSEL') ) { # skip till an )ENDSEL is found
        $nextSkelLine++;
        if ( defined($skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) ) { # next card exists 
          $nextCard = $skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine]; 
        }
      }
      if ( ! defined($skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) ) { # came to the end of the skeleton before finding )ENDSEL
        displayError("Problems with the )DOF. Cant find the )ENDSEL",$currentSubroutine);
      }
      else { # found the )ENDSEL so can get on with our life
        $DOFLocation{$fileRef} = $nextSkelLine + 1;   # establish where the )DOT looping will return to  ... the card after the )ENDSEL
        displayDebug("Top of DOF loop set to $DOFLocation{$fileRef}",2,$currentSubroutine);
      }
    } 
  }
  else { # problems ... we've come to the end of the skeleton before finding the )ENDDOF
    displayError("Problems with the )DOF. Cant find the )ENDDOF",$currentSubroutine);
  }
  displayDebug("DOFLocation set to $DOFLocation{$fileRef}",1,$currentSubroutine);
  
} # end of establishDOFLoopPosition

sub establishDOEXECLoopPosition {
  # -----------------------------------------------------------
  # Routine to look though the skeleton and identify where the)DOEXEC loop starts
  #
  # a special condition exists where you can have a form like .....
  #
  # CARD 1: )SEL x = 1
  # CARD 2: )DOEXEC .......
  # CARD 3: )SELELSE X = 2
  # CARD 4: )DOEXEC .......
  # CARD 5: )ENDSEL
  # CARD 6->N-1: lots of statements
  # CARD N: )ENDDOEXEC .... this )ENDDOEXEC actually terminates either the first or second )DOF depending on which )SEL is selected
  #              in this case the )DOEXEC loop will loop through 6 -> N
  #
  # Usage: establishDOEXECLoopPosition(<cursor ref>)
  # Returns: the variable $DOEXECLocation{$cursorRef} will be set
  # -----------------------------------------------------------

  my $currentSubroutine = 'establishDOEXECLoopPosition'; 
  
  my $fileRef = shift;                                                        # get the file reference literal
  my $nextSkelLine = $currentSkelLine ;
  my $nextCard;
  
  if ( defined( $skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) ) { # the next line exists ....
    $DOEXECLocation{$fileRef} = $currentSkelLine;                              # establish where the )DOF looping will return to (default to the line after the )DOF
    $nextCard = $skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine];      # check out the next card ......
    if ( uc(substr($nextCard,0,8)) eq ')SELELSE' ) {                            # .... special case ... need to find the )ENDSEL
      while ( defined($skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) && (uc(substr($nextCard,0,7)) ne ')ENDSEL') ) { # skip till an )ENDSEL is found
        $nextSkelLine++;
        if ( defined($skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) ) { # next card exists 
          $nextCard = $skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine]; 
        }
      }
      if ( ! defined($skelLines[$skelArray{$currentActiveSkel}][$nextSkelLine] ) ) { # came to the end of the skeleton before finding )ENDSEL
        displayError("Problems with the )DOEXEC. Cant find the )ENDSEL to match the encompassing )SEL",$currentSubroutine);
      }
      else { # found the )ENDSEL so can get on with our life
        $DOEXECLocation{$fileRef} = $nextSkelLine + 1;   # establish where the )DOEXEC looping will return to  ... the card after the )ENDSEL
        displayDebug("Top of DOEXEC loop set to $DOEXECLocation{$fileRef}",2,$currentSubroutine);
      }
    } 
  }
  else { # problems ... we've come to the end of the skeleton before finding the )ENDDOF
    displayError("Problems with the )DOEXEC. Cant find the )ENDDOEXEC",$currentSubroutine);
  }
  displayDebug("DOEXECLocation set to $DOEXECLocation{$fileRef}",1,$currentSubroutine);
  
} # end of establishDOEXECLoopPosition

sub verifyControlCounts {
  # -----------------------------------------------------------
  # Routine to verify that control counts are travelling fine 
  #
  # Usage: verifyControlCounts()
  # Returns: nothing but will issue error messages as necessary
  # -----------------------------------------------------------
  my $currentSubroutine = 'verifyControlCounts';

  my $a = 0;
  my $b = 0;
  my $c = 0;
  my $d = 0;
  my $stackEntries = $#controlStack+1;
  if ( $stackEntries == 0 ) { # no more entries left on the stack
    displayDebug("No more entries on stack",2,$currentSubroutine);
    $a = -2; # set held SEL count to unknown
    $b = -2; # set held DOT count to unknown
    $c = -2; # set held DOF count to unknown
    $d = -2; # set held DOEXEC count to unknown
  }
  else { # pop away
    $a = pop(@controlStack);               # should be SELCount
    $b = pop(@controlStack);               # should be DOTCount
    $c = pop(@controlStack);               # should be DOFCount
    $d = pop(@controlStack);               # should be DOEXECCount
    displayDebug("POPPING off of stack - #entries $stackEntries",2,$currentSubroutine);
    displayDebug("Pulling control counts: \$a=$a,\$b=$b,\$c=$c,\$d=$d,\$skelSELCount=$skelSELCount,\$skelDOTCount=$skelDOTCount,\$skelDOFCount=$skelDOFCount,\$skelDOEXECCount=$skelDOEXECCount",1,$currentSubroutine);
  }  
    
  if ( ($a != $skelSELCount ) ) { # Mismatch in )SEL/EMDSEL identified at this line
    displayError("Mismatch in )SEL/)ENDSELs ($a Vs $skelSELCount) identified",$currentSubroutine);
  }
  if ( ($b != $skelDOTCount ) ) { # Mismatch in )DOT/ENDDOT identified at this line
    displayError("Mismatch in )DOT/)ENDDOTs ($b Vs $skelDOTCount) identified",$currentSubroutine);
  }
  if ( ($c != $skelDOFCount ) ) { # Mismatch in )DOF/ENDDOF identified at this line
    displayError("Mismatch in )DOF/)ENDDOFs ($c Vs $skelDOFCount) identified",$currentSubroutine);
  }
  if ( ($d != $skelDOEXECCount ) ) { # Mismatch in )DOEXEC/ENDDOEXEC identified at this line
    displayError("Mismatch in )DOEXEC/)ENDDOEXECs ($d Vs $skelDOEXECCount) identified",$currentSubroutine);
  }

} # end of verifyControlCounts

sub displayDataHorizontally {
  # -----------------------------------------------------------
  # Routine to print out a row of data horizontally from a file 
  #
  # Usage: displayDataHorizontally(<file ref>, <data record>)
  # Returns: nothing but will print out a horizontally formatted dump of a record
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'displayDataHorizontally';
  
  my $fileRef = shift;              # file reference to use
  my $fileRecord = shift;           # data record to print
  
  my $tStr = '';                    # initialise theoutput String
  
  my @delimArr;                     # dont confuse it with anything else
  
  displayDebug('Data goes here, ' . $fileRef . ' = ' . $fileRecord,2,$currentSubroutine );     # display what is available
  
  my $numCTLLines = $#{$ctlLines[$ctlArray{$fileRef}]} + 1;                   # set the number of lines in the array slice for this fileRef
  for ( my $i=0 ; $i<$numCTLLines; $i++ ) {                                   # for each control line (which should equate to a field)
    displayDebug("CTL Field Array Entry being Processed: $ctlLines[$ctlArray{$fileRef}][$i]",1,$currentSubroutine);
    my $ctlCard = $ctlLines[$ctlArray{$fileRef}][$i];                         # place the card into a variable for easier typing
    my $delimiter = substr($ctlCard,0,1);                                     # first char is the delimiter
    
    # break the preparse ctl line into it's parts (maximum of 8 parts)
    my ($delNull,$delimType,$fldName, $fldStart, $fldLen, $condStart, $condLen, $condValue) = split (/[$delimiter]/,$ctlCard,8); 
    displayDebug("delimType is $delimType, fldName is $fldName, fldStart is $fldStart, fldLen is $fldLen, condStart is >$condStart<",1,$currentSubroutine);
    
    if ( uc($delimType) eq "DELIMITED" ) {                                     # it is a delimited control record .... split up the data record to save time
      $fldStart = '\\' . $fldStart;
      @delimArr = ();                                                          # initialise an array to hold the delimiter conditions
      @delimArr = split("$fldStart", $fileRecord);                               # for a delimited record the 4th parm is the delimiter so split the data record based on that
    }

    my $setVar = "No";                                                         # defaults to NOT processing the record
    my $testValue = '';                                                        # value obtained to be tested against a condition
    
    if ( $condStart ne "" ) {                                                  # condition was supplied so check if we want to process this data card
      if ( uc($condStart) eq "DELIMITED" ) {                                   # delimited condition
        if ( defined($delimArr[$condLen]) ) {                                  # If the condition field exists ....
          $testValue = $delimArr[$condLen];                                    # assign the value to the test field
        }
        else { # test field doesn't exist
          $testValue = "KCKCTESTFAILEDKCKC";                                   # make up a value for the test value
        }
      }
      else { # not a delimited value ....
        if ( $condStart > length($fileRecord)) {                               # field start outside record
          $testValue = "KCKCTESTFAILEDKCKC";                                   # make up a value for the test value
        }
        elsif ( $condStart + $condLen > length($fileRecord) ) {                # field end outside record
          $testValue = substr($fileRecord, $fldStart);
        }
        else { # all looks good
          $testValue = substr($fileRecord, $fldStart, $fldLen) ;               # assign the value to the test field
        }
      }

      if ( $testValue eq "KCKCTESTFAILEDKCKC" ) {                              # check if the test value was set
        if ( $condNULLisMatch ) {                                              # indicates that a 'not found' is a match
          $setVar = "Yes";                                                     # process this record
        }
      }
      else {                                                                   # it was a valid value
        if ( evaluateCondition($testValue . $condValue) eq "True" ) {          # Check if the condition holds
          $setVar = "Yes";
        }
      }
    }
    else { # no condition so just set the variable
      $setVar = "Yes";
    }

    displayDebug("length(\$fileRecord) is " . length($fileRecord),1,$currentSubroutine);
    
    my $fldValue = 'NULL';                                    # variable holds the value of the defined field
    if ( $setVar eq "Yes" ) {                                 # the variable has passed all conditional processing
      if ( uc($delimType) eq "FIXED" ) {                      # field is defined in fixed positions
        if ( $fldStart > length($fileRecord)) {               # field starts outside record
          $fldValue = "NULL";                                 # assign it a null string
        }
        elsif ( $fldStart + $fldLen > length($fileRecord) ) { # field end outside record
          $fldValue = substr($fileRecord, $fldStart);         # assign it a truncated value
        }
        else {
          $fldValue = substr($fileRecord, $fldStart, $fldLen) ;  # assign it the right value
        }
      }
      else { # it is a delimited field
    if ( defined($delimArr[$fldLen]) ) {                     # Note: the data record has previously been split
      $fldValue = $delimArr[$fldLen];                        # assign it the right value
        }
    else { # not enough values in the record
      $fldValue = "NULL";
    }
      }
      # and now just set the value for the variable ....
      displayDebug("Displaying variable $fldName which has a value of $fldValue",1,$currentSubroutine);
    } 
    
    # now print out the value returned
    
    if ( $outputMode eq "HTTP" ) {                          # output it as a html table cell
      # check if special styling is required for this cell
      $currentCellStyle = checkCellStyleSetting($fldName);      # see what style should be used
      if ( isNumeric($fldValue) ) { # right align numeric fields
        $tStr .= "<td $currentCellStyle align=\"right\">" . $fldValue . "</td> ";
      }
      else { # character field ... just normal left alignment
        $tStr .= "<td  $currentCellStyle>" . $fldValue . "</td> ";
      }
    }
    else { # just write it out to normal output
      $tStr .= "!" . $fldValue;
    }

  } # end of for
  
  if ( $outputMode eq "HTTP" ) {                              # output it as a html table
    $currentRowStyle = checkRowStyleSetting();
    outputLine("<tr $currentRowStyle> " . $tStr . " </tr>");                   # output the row information surrounded by the row tags
  }
  else {
    outputLine($tStr);                                        # print out the values for the record
  }
  
} # end of displayDataHorizontally

sub processPARSE {
  # -----------------------------------------------------------
  # Routine to parse a variable/string into other variables
  #
  # The PARSE control statement looks like:
  #        )PARSE <variable> [using <CTLFileName>]]
  #     
  #        where variable   : string to parse
  #              CTLFileName: the control file defining the structure of the file       
  #
  #        defaults are: CTLFileName: inFile.ctl 
  #
  # Usage: processPARSE(<control Card>)
  # Returns: nothing but will establish variables as defined in the ctl file
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processPARSE';
  my $card = shift;                                            # establish the card being processed
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
    
      # ok to process the card .....

      my $fileRef;           
      my $variable = getToken($card);                          # string to parse
      my $lit = getToken($card);                               # should be the literal 'USING'
      my $CTLFileName = getToken($card);                       # (CTLFILENAME) The file name holding the control information describing the file
      if ( $CTLFileName =~ /\./ ) {                            # the file name contains a period
        ($fileRef) = ($CTLFileName =~ /.*[\/\\](.*)\..*/);  
      }
      else {
        ($fileRef) = ($CTLFileName =~ /.*[\/\\](.*)/);
      }
      if ( $fileRef eq '' ) { $fileRef = 'PARSERef' ; } 
      displayDebug("File=$CTLFileName,fileRef=$fileRef",1,$currentSubroutine);

      if ( uc($lit) ne 'USING' ) { # USING is missing from where it should be
        displayError("USING literal missing. It will be assumed to be the second parameter (which will now be ignored)",$currentSubroutine);
        displayError("Format of the )PARSE is  )PARSE <variable> [using <CTLFileName>]",$currentSubroutine);
      }
      
      # set default values if necessary
      if ( $CTLFileName eq '' ) { $CTLFileName = 'inFile.ctl' };
      
      # process the )PARSE statement and set parameters
      # generate the full file name ....
      my $skelCTLFullName = '';                            # Will contain the full CTL file name
      
      # load the control cards
      if ( (uc($CTLFileName) =~ "^INLINE\:|^INLINE\=") || ( uc($CTLFileName) eq 'INLINE') ) {    # does the ctl file start with either INLINE: or INLINE= or is just the word INLINE
        loadInlineFileCTL($fileRef);             # load the CTL file
      }
      else { # it is a real file
        # generate the CTL File full name
        my $skelCTLDir = $ENV{'SKLCTLDIR'};
        if ( ! defined($skelCTLDir) ) { $skelCTLDir = ''; }
        if ( $skelCTLDir eq "" ) {                          # just use the supplied names
          $skelCTLFullName = $CTLFileName;
        }
        elsif ( substr($skelCTLDir,-1,1) eq $dirSep  ) {    # has a terminating directory separator
          $skelCTLFullName = "$skelCTLDir$CTLFileName";
        }
        else { # no separator so add one
          $skelCTLFullName = "$skelCTLDir$dirSep$CTLFileName";
        }
  
        displayDebug("CTL file will be $skelCTLFullName",1,$currentSubroutine);
        # now load the control file .....
        loadFileCTL($fileRef, $skelCTLFullName);
  
      }

      if ( defined ($ctlArray{$fileRef} ) ) {              # control file was loaded

        my $tStr = "";                                       # Initialise the output line for non http output

        my $numCTLLines = $#{$ctlLines[$ctlArray{$fileRef}]} + 1;     # set the number of lines in the array slice for this fileRef
        for ( my $i=0 ; $i<$numCTLLines; $i++ ) {                     # for each control line
  
          displayDebug("CTL Field Array Entry being Processed: $ctlLines[$ctlArray{$fileRef}][$i]",1,$currentSubroutine);
          my $ctlCard = $ctlLines[$ctlArray{$fileRef}][$i];           # place the card into a variable for easier typing                    
          my $delimiter = substr($ctlCard,0,1);                       # first char is the delimiter
    
          # break the preparse ctl line into it's parts (maximum of 8 parts)
          my ($delNull,$delimType,$fldName, $fldStart, $fldLen, $condStart, $condLen, $condValue) = split (/[$delimiter]/,$ctlCard,8);  # at this point only concerned about field name
            
        }
          
        # Split the variable and assign variables .....
        setDefinedVariablesForFile($fileRef, $variable); 

      }
      else { # control file wasn't loaded so nothing can be done ... just skip the card
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }

} # end of processPARSE

sub processCONVERTHEADERS {
  # -----------------------------------------------------------
  # Routine to process the )CONVERTHEADERS statement
  #
  # Usage: processCONVERTHEADERS()
  # Returns: sets the convertHeaders variable to 1
  # -----------------------------------------------------------  
  
  $convertHeaders = 1;
  
}

sub processLEAVEHEADERS {
  # -----------------------------------------------------------
  # Routine to process the )LEAVEHEADERS statement
  #
  # Usage: processLEAVEHEADER()
  # Returns: sets the convertHeaders variable to 0
  # -----------------------------------------------------------  
  
  $convertHeaders = 0;
  
}

sub headerise {
  # -----------------------------------------------------------
  # Routine to convert a string to a standard format
  #
  # The formatting will:
  #     1. Convert all _ to spaces
  #     2. Capitalise the first letter of every word
  #     3. Capitalise characters after periods
  #     4. set all other letters to lower case
  #
  # Usage: headerise(<header>)
  # Returns: a string in header format
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'headerise';
  my $header = shift;                                            # establish the card being processed
  
  $header =~ s/_/ /g;       # convert '_' to spaces
  $header = lc($header);    # convert all chars to lower case
  my $cchar = '';
  my $lchar = '';
  
  for ( my $i = 0; $i <= length($header); $i++ ) { # loop through all of the characters 
    $cchar  = substr($header,$i,1);
    if ( $i == 0 ) { substr($header,$i,1) = uc($cchar); } # make the first char upper case
    else {
      if ( ' .' =~ $lchar ) { substr($header,$i,1) = uc($cchar); } # first character so make it lower case
    }
    $lchar = $cchar;    # save it
  }  

  return $header;

} # end of headerise

sub processFDOF {
  # -----------------------------------------------------------
  # Routine to print out a formatted dump of a file 
  #
  # The FDOF control statement looks like:
  #        )FDOF [<fileName> [using <CTLFileName>]]
  #     
  #        where filename   : the file to be read
  #              CTLFileName: the control file defining the structure of the file       
  #
  #        defaults are: file ref   : inFile
  #                      filename   : inFile.txt 
  #                      CTLFileName: inFile.ctl 
  #
  # Usage: processFDOF(<control Card>)
  # Returns: nothing but will print out a horizontally formatted dump of a table
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processFDOF';
  my $card = shift;                                            # establish the card being processed
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
    
      # ok to process the card .....

      setVariable('LASTFDOFCount','0');                        # initialise variable
      my $fileRef = 'FDOFRef';                                 # file ref for a FDOF is fixed as FDOFRef    
      my $fileName = getToken($card);                          # (FILENAME) nameof the file to be opened
      my $lit = getToken($card);                               # should be the literal 'USING'
      my $CTLFileName = getToken($card);                       # (CTLFILENAME) The file name holding the control information describing the file

      if ( uc($lit) ne 'USING' ) { # USING is missing from where it should be
        displayError("USING literal missing it will be assumed to be the second parameter (which will now be ignored)",$currentSubroutine);
        displayError("Format of the )FDOF is  )FDOF [<fileName> [using <CTLFileName>]]",$currentSubroutine);
      }
      
      # set default values if necessary
      if ( $fileName eq '' ) { $fileName = 'inFile.txt' };
      if ( $CTLFileName eq '' ) { $CTLFileName = 'inFile.ctl' };
      
      # process the )FDOF statement and set parameters
      # generate the full file name ....
      my $skelCTLFullName = '';                            # Will contain the full CTL file name
      my $skelDataFullName = '';                           # Will contain the full Data file name
      
      # generate the Data File full name
      my $skelDataDir = $ENV{'SKLDATADIR'};
      if ( ! defined($skelDataDir) ) { $skelDataDir = ''; } 
      if ( $skelDataDir eq "" ) {                          # just use the supplied names
        $skelDataFullName = $fileName;
      }
      elsif ( substr($skelDataDir,-1,1) eq $dirSep  ) {    # has a terminating directory separator
        $skelDataFullName = "$skelDataDir$fileName";
      }
      else { # no separator so add one
        $skelDataFullName = "$skelDataDir$dirSep$fileName";
      }

      # load the control cards
      if ( (uc($CTLFileName) =~ "^INLINE\:|^INLINE\=") || ( uc($CTLFileName) eq 'INLINE') ) {    # does the ctl file start with either INLINE: or INLINE= or is just the word INLINE
        loadInlineFileCTL($fileRef);             # load the CTL file
      }
      else { # it is a real file
        # generate the CTL File full name
        my $skelCTLDir = $ENV{'SKLCTLDIR'};
        if ( ! defined($skelCTLDir) ) { $skelCTLDir = ''; }
        if ( $skelCTLDir eq "" ) {                          # just use the supplied names
          $skelCTLFullName = $CTLFileName;
        }
        elsif ( substr($skelCTLDir,-1,1) eq $dirSep  ) {    # has a terminating directory separator
          $skelCTLFullName = "$skelCTLDir$CTLFileName";
        }
        else { # no separator so add one
          $skelCTLFullName = "$skelCTLDir$dirSep$CTLFileName";
        }
  
        displayDebug("Data file will be $skelDataFullName, CTL file will be $skelCTLFullName",1,$currentSubroutine);
        # now load the control file .....
        loadFileCTL($fileRef, $skelCTLFullName);
  
      }
    
      # save the current file ref
      $currentFileRef = $fileRef;
    
      if ( defined ($ctlArray{$fileRef} ) ) {              # control file was loaded

        # now open the file and read in the first record ....
        if ( !open ( $skelFileHandle{$fileRef}, "<", "$skelDataFullName" ) ) {
          # file not found (possibly)
          displayError("Unable to open $skelDataFullName.\nError: $?",$currentSubroutine);
        }
        else { # The file does at least exist 
          # print out the heading ....
          
          my $tStr = "";                                       # Initialise the output line for non http output

          if ( $outputMode eq "HTTP" ) {  # output it as a html table
            $FTABNumber++;
            outputLine("<table border=\"1\" id=\"FTAB$FTABNumber\"><tr>\n");                   # output the start of table information
          }
          else {
            outputLine("\n");                                           # just doa new line
          }
         
          my $numCTLLines = $#{$ctlLines[$ctlArray{$fileRef}]} + 1;     # set the number of lines in the array slice for this fileRef
          for ( my $i=0 ; $i<$numCTLLines; $i++ ) {                     # for each control line
  
            displayDebug("CTL Field Array Entry being Processed: $ctlLines[$ctlArray{$fileRef}][$i]",1,$currentSubroutine);
            my $ctlCard = $ctlLines[$ctlArray{$fileRef}][$i];           # place the card into a variable for easier typing                    
            my $delimiter = substr($ctlCard,0,1);                       # first char is the delimiter
    
            # break the preparse ctl line into it's parts (maximum of 8 parts)
            my ($delNull,$delimType,$fldName, $fldStart, $fldLen, $condStart, $condLen, $condValue) = split (/[$delimiter]/,$ctlCard,8);  # at this point only concerned about field name
            my $headerName = $fldName;
            if ( $convertHeaders ) {
              $headerName = headerise($headerName);
            }
            
            if ( $outputMode eq "HTTP" ) {  # output it as a html table
              outputLine("<th>" . $headerName . "</th>");
            }
            else { # just write it out to normal output
              $tStr .= "!" . $fldName;
            }
          }
          
          # close off the row 
          if ( $outputMode eq "HTTP" ) {                                # close off the html table row
            outputLine("</tr>\n");
          }
          else {                                                        # if not HTTP then write out the line
            outputLine("$tStr");
          }
          
          # print out the data .....
          
          $skelFileStatus{$fileRef} = 0;                         # initialise the row counter (if it stays 0 it will mean the file is empty, otherwise it will be incremented by readDataFileRecord)
          # save the file handle
          my $skelFileRecord = readDataFileRecord($skelFileHandle{$fileRef}, $fileRef, 'F');
          while ( defined($skelFileRecord) ) {                   # there is data to process
            setVariable('LASTFDOFCount',$skelFileStatus{$fileRef});
            setDefinedVariablesForFile($fileRef, $skelFileRecord); # Set all of the variables
            
            # check if the row is selected for processing
            if ( $selectCond eq '' ) { # no selection so print data
              displayDataHorizontally($fileRef, $skelFileRecord);  # display all of the variables
            }
            elsif ( evaluateCondition(substituteVariables($selectCond)) ) { # condition returned true
              displayDataHorizontally($fileRef, $skelFileRecord);  # display all of the variables
            }
            $skelFileRecord = readDataFileRecord($skelFileHandle{$fileRef}, $fileRef, 'F'); # read the next record
          } 
          # print out the trailing stuff ....

          if ( $outputMode eq "HTTP" ) {  # output it as a html table
            outputLine("</table>\n");         # terminate the HTML table
          }
          else {
            outputLine("\n");                                           # just doa new line
          }
          setVariable('LASTFDOFCount',$skelFileStatus{$fileRef});
          
          undef $skelFileHandle{$fileRef};                       # undefine the file handle to free it up
          undef $skelFileStatus{$fileRef};                       # undefine the status entry
        }
# leave the ctl files loaded in cache in case they are reused
#        undef $ctlLines[$ctlArray{$fileRef}];              # clear out the array holding the control cards
#        delete $ctlArray{$fileRef};                        # clear out the control file reference number
      }
      else { # control file wasn't loaded so nothing can be done ... just skip the card
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }

} # end of processFDOF

sub processGRAPHLIB {
  # -----------------------------------------------------------
  # Routine to generate the statements that specify the javascript graphics libraries
  # the card is of the form )GRAPHLIB <JAVASCRIPT MODULE> SCRIPT=<script location> LINK=<link location>
  #
  # Note that the currently supported graphics libraries are VIS.JS and PLOTLY.JS and the values to be 
  # provided on the )GRAPHLIB card are PLOTLY and VIS. If no GRAPHLIB direction is given then PLOTLY will be assumed
  # and all of the script decalratives will need to be manually provided
  #
  # Usage: processGRAPHLIB
  # Returns: output the script and link statements in the output
  # NOTE: only one HRAPHLIB statement will be processed per skeleton
  # -----------------------------------------------------------

  my $currentSubroutine = 'processGRAPHLIB'; 
  my $card = shift;                                                      # establish the card being processed
  
  my $scriptLoc = 'scripts/';
  my $linkLoc = 'css/';
  
  if ( $card ne '' ) {                                                   # parameters passed so check them out
    my $targetParm = getToken($card);                                    # see what the first parameter is (if any)  
    my $tmp;
    $graphLibrary = 'plotly';                                          # defaults to plotly
  
    while ( $targetParm ne '' ) {
      # the first parameter specifies the graphics library being used .....
      if ( uc($targetParm) eq 'VIS' ) {
        $graphLibrary = 'vis';
      }
      elsif ( uc($targetParm) eq 'PLOTLY' ) {
        $graphLibrary = 'plotly';
      }
      elsif ( uc($targetParm) eq 'SCRIPT') {                                # SCRIPT parameter found
        $tmp = getToken($card);
        if ( $tmp eq '=' ) {                                             # next parm is an assignment character
          $tmp = getToken($card);                                        # script value is the next character
        }
        $scriptLoc = $tmp;
      }
      elsif ( uc($targetParm) eq 'LINK') {                               # LINK parameter found
        $tmp = getToken($card);
        if ( $tmp eq '=' ) {                                             # next parm is an assignment character
          $tmp = getToken($card);                                        # link value is the next character
        }
        $linkLoc = $tmp;
      }
      else { # unknown parameter
        displayError ("Unknown parameter '$targetParm' found on )GRAPHLIB card",$currentSubroutine);
      }
      $targetParm = getToken($card);                                     # get next parameter
    }
  }
  
  # tidy the values up
  
  if ( trim($scriptLoc) ne '' ) {                                        # script loc is a value
    if ( substr( $scriptLoc,-1 ) ne $dirSep ) { $scriptLoc .= $dirSep }  # make sure the location is terminated with a level separator
  }

  if ( trim($linkLoc) ne '' ) {                                          # link loc is a value
    if ( substr( $linkLoc,-1 ) ne $dirSep ) { $linkLoc .= $dirSep }      # make sure the location is terminated with a level separator
  }

  # print out the cards
  
  if ($graphIncludesWritten ) {
    displayError (")GRAPHLIB statenment ignored as script/link statements already generated - perhaps automatically by a previous )GRAPH statement",$currentSubroutine);
  }
  else {
    outputLine('<script src="' . $scriptLoc . $graphLibraryName{$graphLibrary} . '"></script>');
    if ( $graphLibrary eq 'vis' ) { 
      outputLine('<link href="' . $linkLoc . 'vis.css" rel="stylesheet" type="text/css" />');
    }
  }
  
  $graphIncludesWritten = 1;                                              # flag that the includes have been done for this skeleton

} # end of processGRAPHLIB


sub processBUTTON {
  # -----------------------------------------------------------
  # Routine to print out the HTML info to inject a BUTTON
  #
  # The BUTTON control statement looks like )BUTTON <label> <cgi program>
  #
  # Usage: processBUTTON(<control Card>)
  # Returns: nothing but will print out HTML commands
  # -----------------------------------------------------------

  my $currentSubroutine = 'processBUTTON';

  my $card = shift;                                            # get the card information
  displayDebug("current line position = $currentLinePosition",2,$currentSubroutine);
  my $label = getToken($card);                                 # label on button
  displayDebug("current line position = $currentLinePosition",2,$currentSubroutine);
  my $target = "unknownTarget.cgi";
  if ( $currentLinePosition < length($card) ) { # 2nd parameter exists
    $target = trim(substr($card,$currentLinePosition));       # target of button action is rest of line
  }
  displayDebug("Button label is: $label",2,$currentSubroutine);
  displayDebug("Button target is: $label",2,$currentSubroutine);

  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      if ( $target =~ /\?/ ) {  # form target contains parameters so use post rather than get
        outputLine("<form method=\"post\" action=\"$target\">");
      }
      else { # no parms so get is easier 
        outputLine("<form method=\"get\" action=\"$target\">");
      }
      outputLine("    <input type=\"submit\" value=\"$label\">");
      outputLine("</form>");
    }
  }

} # end of processBUTTON

sub processVHEAD {
  # -----------------------------------------------------------
  # Routine to establish which columns should have vertical 
  # headings
  #
  # The VHEAD establishes which headings will be vertical and 
  # this will stay in force until the next VHEAD command. A VHEAD card
  # with no parameters clears all values
  #
  # eg. )VHEAD Y N Y N Y
  # would set columns 1, 3 and 5 as vertical headings
  #
  # Usage: processVHEAD(<control Card>)
  # Returns: nothing but will set values in $vertHeader
  # -----------------------------------------------------------

  my $currentSubroutine = 'processVHEAD';

  my $card = shift;                                            # get the card information
  my $columnCnt = 0;
  %vertHeader = ();       # clear the array
    
  displayDebug("Setting the vertical heading array",0,$currentSubroutine);
  
  my $parm = getToken($card);
  while ( $parm ne "" ) {
    if ( uc($parm) eq 'Y') { # this column does have a vertical heading
      $vertHeader{$columnCnt} = 1;
      displayDebug("Column $columnCnt has been set as vertical",0,$currentSubroutine);
    }
    $parm = getToken($card);
    $columnCnt++;
  }

} # end of processVHEAD

sub processHTMLHDR {
  # -----------------------------------------------------------
  # Routine to print out the HTML Header
  #
  # The HTMLHDR control statement looks like )HTMLHDR 
  #
  # Usage: processHTMLHDR
  # Returns: nothing but will print out HTML header information
  # -----------------------------------------------------------

  my $currentSubroutine = 'processHTMLHDR';

  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      outputLine("Content-type: text/html\r\n\r\n");
    }
  }

} # end of processHTMLHDR

sub processDMPHDR {
  # -----------------------------------------------------------
  # Routine to print out the HTML Header required to export data
  #
  # The DMPHDR control statement looks like )DMPHDR <Filename> 
  #
  # Usage: processDMPHDR(<control Card>)
  # Returns: nothing but will print out HTML command to dump a file
  # -----------------------------------------------------------

  my $currentSubroutine = 'processDMPHDR';

  my $card = shift;                                            # get the card information
  my $file = trim(substituteVariables(substr($card,$currentLinePosition)));         # (SQL Statement) SQL to be used
  displayDebug("File to be downloaded to is: $file",2,$currentSubroutine);

  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      outputLine("Content-Disposition: Attachment; filename=$file");
      outputLine("Content-type: text/text");
    }
  }

} # end of processDMPHDR

sub processDMP {
  # -----------------------------------------------------------
  # Routine to dump the output of a returned SQL query
  #
  # The DMP control statement looks like )DMP <DB Ref> <SQL Statement>
  #
  # Usage: processDMP(<control Card>)
  # Returns: nothing but will print out a comma delimited dump of the SQL output
  # -----------------------------------------------------------

  my $currentSubroutine = 'processDMP';
  my $num_of_fields = 0;                                       # field containing the number of columns returned
  my $tStr = "";                                               # this string will hold the generated output line
  my $skelTabValue = '';                                       # value of the column

  my $card = shift;                                            # get the card information
  my $DBConnectionRef = getToken($card);                       # (CONNREF) this is the database ref that a )LOGON should have created
  my $SQL = trim(substr($card,$currentLinePosition));          # (SQL Statement) SQL to be used

  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped

      setVariable('LASTDMPCount','0');                         # initialise variable
      if ( uc($SQL) =~ "^FILE\:|^SQL\:|^SQL\=|^FILE\=" ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
        $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
      }
      elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {                    # does the sql start with either INLINE: or INLINE= or is just the word INLINE
        $SQL = loadInlineCards($currentSubroutine);             # load the SQL
      }

      $cursorSQL{'DMP'} = $SQL;                                # set up the SQL

      # now process the open
      if ( establishCursor( $DBConnectionRef, 'DMP' ) ) {      # returns 1 if all is ok (and attempts to read the first row)

        if ( $cursorRowNumber{'DMP'} == 0 ) {                 # no rows returned (should be 1 at this point)
          displayDebug("Call to SQL returned 0 rows",2,$currentSubroutine);
          outputLine("No Data Returned");
        }
        else { # a row was returned
          displayDebug("Rows returned",2,$currentSubroutine);
          $num_of_fields = $skelCursor{'DMP'}->{NUM_OF_FIELDS};
          displayDebug("Number of fields = $num_of_fields\n",2,$currentSubroutine);

          # Write out headings ......

          outputLine("\n");
          $tStr = "";                                       # Initialise the output line
          for ( my $i=0; $i<$num_of_fields; $i++ ) {
            if ( $i == 0 ) {            # dont need a comma
              $tStr = $skelCursor{'DMP'}->{NAME}->[$i];
            }
            else {                      # need a comma to separate the headings
              $tStr .= $skelDelimiter . $skelCursor{'DMP'}->{NAME}->[$i];
            }
          }
          outputLine("$tStr");

          # write out the data .....

          displayDebug("About to enter row loop",2,$currentSubroutine);
          my $moreToProcess = 1;                              # initialise the stop flag

          while ( $moreToProcess ) {                          # A value of 1 indicates data was returned
            displayDebug("In cursor loop",2,$currentSubroutine);
            $tStr = "";                                       # Initialise the output line
            for ( my $i=0; $i<$num_of_fields; $i++ ) {
              my $fieldType = $skelCursor{'DMP'}->{TYPE}->[$i]; # $fieldType is now the field type (CHAR, VARCHAR etc)
              $skelTabValue = "";
              $skelTabValue = getTabValue($fieldType, ${$skelCursorRow{'DMP'}}[$i], 'DMP',  $i);   # pass field type and the field across

              # commas as necessary
              if ( $i > 0 ) { # all fields bar the first should be preceded by a comma
                $tStr .= $skelDelimiter ;
              }

              # put quotes around character fields ....
              if ( isNumeric($fieldType) ) { # probably DB2
                if ( $numericFieldTypes =~ $fieldType ) { # numeric fields
                  $tStr .= $skelTabValue ;
                }
                else { # character field ... just normal left alignment
                  $tStr .= '"' . $skelTabValue . '"';
                }
              }
              else { # $fieldType not numeric so probably SQLite
                if ( $fieldType eq "NUMERIC" ) { # numeric fields
                  $tStr .= $skelTabValue ;
                }
                else { # character field ... just normal left alignment
                  $tStr .= '"' . $skelTabValue . '"';
                }
              }
            }
            outputLine("$tStr");

            # move on to the next row now .....

            $moreToProcess = getNextRecord('DMP'); # 1 is returned if more data to process, 0 if at end of cursor

          } # end of while loop

          # no more data
          setVariable('LASTDMPCount',$cursorRowNumber{'DMP'});
          closeCursor('DMP');                # close the DMP cursor
        }
      }
      else { # Problems in river city - open cursor failed
        if ( $skelVerboseSQLErrors eq 'Yes' ) {
          if ( $SQLError ) { # SQL Error (not just no rows found)
            displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SQL",$currentSubroutine);
          } 
          else {
            displayError("No Rows found for SQL:\n $SQL",$currentSubroutine);
          }
        }
        else { # not verbose - dont mention it if no rows found and if SQL error dont print SQL
          if ( $SQLError ) { # SQL Error (not just no rows found)
            displayError("Call to SQL failed - will pretend no records found\n",$currentSubroutine);
          } 
        }
      }
      displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processDMP

sub checkIndexEntries {

  # -----------------------------------------------------------
  # Routine to see if there are any key words in the index entries that need replacing
  #
  # Keywords processed are:
  #   1.  LOWER_ALPHABET .... a -> b
  #   2.  UPPER_ALPHABET .... A -> B
  #   3.  NUMBERS ... 0 -> 9
  #       
  # Usage: checkIndexEntries(<index entries>)
  # Returns: the suppllied index entries with certain keywords replaced
  # -----------------------------------------------------------

  my $indexEntries = shift;

  $indexEntries =~ s/LOWER_ALPHABET/a b c d e f g h i j k l m n o p q r s t u v w x y z/gi;  
  $indexEntries =~ s/UPPER_ALPHABET/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/gi;  
  $indexEntries =~ s/NUMBERS/0 1 2 3 4 5 6 7 8 9/gi;  
  
  if ( $indexEntries =~ /CASE_INSENSITIVE/i ) { # make it a case insenstive index
    $indexCaseInsensitive = 1;
    $indexEntries =~ s/CASE_INSENSITIVE//gi;  
  }
  elsif ( $indexEntries =~ /CASE_SENSITIVE/i ) { # make it a case sensitive index
    $indexCaseInsensitive = 0;
    $indexEntries =~ s/CASE_SENSITIVE//gi;  
  }
  
  return $indexEntries;
  
}

sub processINDEX {
  # -----------------------------------------------------------
  # Routine to establish the indexing requiremtns for an
  # automated table display like FTAB
  #
  # The INDEX control statement looks like:
  #   1.  )INDEX EVERY <# rows> [MAX <limit of elements>] [TYPE <DOT|NUM>]
  #   2.  )INDEX EXACT <list of index entries to exactly match> [ON <tab entry to check>]
  #   3.  )INDEX PREFIX <list of index entries to partially match match> [ON <tab entry to check>]
  #       
  #       Note: Lists are space delimited
  #
  # Usage: processINDEX(<control Card>)
  # Returns: nothing but will set up control variables and write out index entries
  # -----------------------------------------------------------

  my $currentSubroutine = 'processINDEX';

  my $card = shift;                                            # get the card information
  $indexType = getToken($card);                                # (INDEXTYPE) EVERY, EXACT or PREFIX
  my $indexEntries;
  $EV_interval = 10;                                              # for EVERY - interval (default 10)
  $EV_max = 20;                                                # for EVERY - max entries (default 20)
  $EV_type = 'DOT';                                            # for EVERY - type of index marks (default DOT)
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      $provideIndex = 1;
      $indexCount = 0;                                         # reset the count
      $indexKey++;                                             # create the unique number marking this index
      if (uc($indexType) eq 'EVERY' ) {
        my $tmp = getToken($card);                             # should be the interval number 
        if ( $tmp ne '' ) {                                    # a value exists     
          if (isNumeric($tmp) ) { 
            $EV_interval = $tmp;          
            $tmp = getToken($card);                            # should be a literal MAX
            if ( uc($tmp) eq 'MAX') { 
              $tmp = getToken($card);                          # should be the max entries value
              if (isNumeric($tmp) ) { 
                $EV_max = $tmp;
                $tmp = getToken($card);                        # should be a literal TYPE
                if ( uc($tmp) eq 'TYPE') { 
                  $tmp = getToken($card);                      # should be one of DOT or NUM
                  if (uc($tmp) eq 'DOT' ) { 
                    $EV_type = 'DOT';
                  }
                  elsif (uc($tmp) eq 'NUM' ) { 
                    $EV_type = 'NUM';
                  }
                  else { # invalid value
                    displayError(")INDEX EVERY - type value is not one of DOT or NUM - it will be defaulted to DOT",$currentSubroutine);
                  }
                }
              }
              else { # invalid value
                displayError(")INDEX EVERY - max value is not numeric will be defaulted to 20 and rest of card ignored",$currentSubroutine);
              }
            }
            else { # invalid value
              displayError(")INDEX EVERY - literal MAX is missing - rest of card ignored",$currentSubroutine);
            }
          }
          else { # invalid value
            displayError(")INDEX EVERY - interval is not numeric will be defaulted to 10 and rest of card ignored",$currentSubroutine);
          }
        }
        # at this point all $EV_ values set so construct the indexEntries variable 
        $indexEntries = '';
        for ( my $cnt = 1 ; $cnt <= $EV_max; $cnt++ ) {
          if ( $EV_type eq 'DOT' ) {
            $indexEntries .= '. ';
          }
          else {
            $indexEntries .= "$cnt ";
          }
        }
      }
      elsif ( uc($indexType) eq 'EXACT' ) {
        $indexEntries = trim(substr($card,$currentLinePosition));  # (INDEX Elements)
        $indexEntries = checkIndexEntries($indexEntries);
        if ( uc($indexEntries) =~ / ON / ) { # there is an ON parameter
          my ($tmp1, $tmp2) = ($indexEntries =~ /(.*) [oO][nN] (.*)/);
          if ( isNumeric($tmp2) ) {          # this should be the table entry to be indexed
            $indexEntry = $tmp2;
            $indexEntries = $tmp1;
          }
          else {
            displayError(")INDEX EXACT - Table entry value to be indexed not numeric - will default to 0",$currentSubroutine);
            $indexEntry = 0;
          }
        }
      }
      elsif ( uc($indexType) eq 'PREFIX' ) {
        $indexEntries = trim(substr($card,$currentLinePosition));  # (INDEX Elements)
        $indexEntries = checkIndexEntries($indexEntries);
        if ( uc($indexEntries) =~ / ON / ) { # there is an ON parameter
          my ($tmp1, $tmp2) = ($indexEntries =~ /(.*) [oO][nN] (.*)/);
          if ( isNumeric($tmp2) ) {          # this should be the table entry to be indexed
            $indexEntry = $tmp2;
            $indexEntries = $tmp1;
          }
          else {
            displayError(")INDEX PREFIX - Table entry value to be indexed not numeric - will default to 0",$currentSubroutine);
            $indexEntry = 0;
          }
        }
      }
      else { # unknown type
        displayError("Index type $indexType unknown. )INDEX card will be skipped",$currentSubroutine);
        return;
      }
      # at this point all variables have been set from the control card
      # time to print out the HTML index entries
      @indexLiteral = split(" ", $indexEntries);
      # turn off all of the used indicators
      for ( my $ent = 0; $ent < $#indexLiteral; $ent++) { $indexLiteralUsed[$ent] = 0; }
      
      outputLine('<BR>');
      if ( $indexType eq 'EVERY' ) {
        # <a href="#CMDBValidation.pl" title="">CMDBValidation.pl</a>
        for ( my $i = 1; $i <= $EV_max; $i++ ) {
          outputLine("<a href=\"#IDX${indexKey}_$i\" title=\"\">[$indexLiteral[$i-1]]</a>");
        }
      }
      else { # must be EXACT or PREFIX
        foreach my $i (@indexLiteral) {
          outputLine("<a href=\"#IDX${indexKey}_$i\" title=\"\">[$i]</a>");
        }
      }
      outputLine('<BR>');
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processINDEX

sub checkForIndexReq {
  # -----------------------------------------------------------
  # Routine to test if an index target entry is required
  #
  # Usage: checkForIndexReq(<value being tested>)
  # Returns: a null string if no index required otherwise returns 
  # the indexing element (normally a <span> construct)
  # -----------------------------------------------------------

  my $currentSubroutine = 'checkForIndexReq';

  my $indexValue = shift;                                  # Value to be tested
  my $returnValue = '';
  my $compIndexLiteral;
  
  if ( $indexValue =~ /^<a / ) { # if it starts with an <a then strip that bit off before checking
    $indexValue =~ s/^<a .*?>//;  
  }
  
  if ( $indexCaseInsensitive ) { $indexValue = uc($indexValue); } # for case insensitve make it upper case
  
  if ( $provideIndex ) {                                   # has an )INDEX card preceded this?
    $indexCount++;                                         # increment the count of index points checked
    if (uc($indexType) eq 'EVERY' ) {
      # produce an index entry if we are at an interval boundary
      if ( $indexCount % $EV_interval == 0 ) {    # we are at a point to do a index point
        my $arrayIdx = $indexCount / $EV_interval;
        if ( ! $indexLiteralUsed[$arrayIdx-1] ) { # this index hasn't been generated before
          $indexLiteralUsed[$arrayIdx-1] = 1;     # flag it as used
          $returnValue = "<span id=\"IDX${indexKey}_$arrayIdx\"><\/span>";
        }
      }
    }
    else { # index type is not EVERY (note that this loop may produce multiple entries)
      for ( my $ent = 0; $ent <= $#indexLiteral; $ent++ ) { # loop through the entries 
        # adjust the comparison value based on case insensitivity
        if ( $indexCaseInsensitive ) { # case insenstive comparison
          $compIndexLiteral = uc($indexLiteral[$ent]);
        }
        else {
          $compIndexLiteral = $indexLiteral[$ent];
        }
        
        if ( ! $indexLiteralUsed[$ent] ) {                  # this index has not been used
          if (uc($indexType) eq 'EXACT' ) {
            if ( $compIndexLiteral eq $indexValue ) {     # match on values
              $indexLiteralUsed[$ent] = 1;                  # flag it as used
              $returnValue .= "<span id=\"IDX${indexKey}_$indexLiteral[$ent]\"><\/span>";
            }
          }  
          elsif (uc($indexType) eq 'PREFIX' ) { 
            my $indlen = length($indexLiteral[$ent]);
            if ( $compIndexLiteral le substr($indexValue,0,$indlen) ) {   # match on prefix
              $indexLiteralUsed[$ent] = 1;                     # flag it as used
              $returnValue .= "<span id=\"IDX${indexKey}_$indexLiteral[$ent]\"><\/span>";
            }
          }  
        }
      }
    }
  }
    
  return $returnValue;
    
} # end of checkForIndexReq

sub checkForIndexNotUsed {
  # -----------------------------------------------------------
  # Routine to generate a list of index targets that have not been created
  #
  # Usage: checkForIndexReq(<value being tested>)
  # Returns: a null string if no index required otherwise returns 
  # the indexing element (normally a <span> construct)
  # -----------------------------------------------------------

  my $currentSubroutine = 'checkForIndexNotUsed';

  my $indexValue = shift;                                  # Value to be tested
  my $returnValue = '';
  
  if ( $provideIndex ) {                                   # has an )INDEX card preceded this?
    $indexCount=0;                                         # clear down the count of index checks made
    
    for ( my $ent = 0; $ent <= $#indexLiteral; $ent++ ) { # loop through the entries 
      if ( ! $indexLiteralUsed[$ent] ) {                  # this index has not been used
        $returnValue .= "<span id=\"IDX${indexKey}_$indexLiteral[$ent]\"><\/span>";
      }
      else {
        $indexLiteralUsed[$ent] = 0;                      # mark the used entries unused
      }
    }  
    
  }
    
  return $returnValue;
    
} # end of checkForIndexNotUsed

sub processINDEXTEST {
  # -----------------------------------------------------------
  # Routine to test if the passed value requires an index entry
  #
  # The INDEXTEST control statement looks like )INDEXTEST <value>
  #
  # Usage: processINDEXTEST(<control Card>)
  # Returns: nothing but will output an index entry if it is required
  # -----------------------------------------------------------

  my $currentSubroutine = 'processINDEXTEST';

  my $card = shift;                                            # get the card information
  my $indexValue = getToken($card);                            # Value to be tested
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      my $indexTest = checkForIndexReq($indexValue);
      if ( $indexTest ne '' ) {                                # index entry is needed here
        outputLine($indexTest);
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processINDEXTEST

sub processINDEXCLEAR {
  # -----------------------------------------------------------
  # Routine to produce index targets for all entries that have not been used
  #
  # The INDEXCLEAR control statement looks like )INDEXCLEAR 
  #
  # Usage: processINDEXCLEAR()
  # Returns: nothing but will output an index target entry for each unused index entry
  # -----------------------------------------------------------

  my $currentSubroutine = 'processINDEXCLEAR';

  my $card = shift;                                            # get the card information
  my $indexValue = getToken($card);                            # Value to be tested
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      my $indexTest = checkForIndexNotUsed();
      if ( $indexTest ne '' ) {                                # index entry is needed here
        outputLine($indexTest);
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processINDEXCLEAR

sub processINDEXOFF {
  # -----------------------------------------------------------
  # Routine to turn off any index creation until the next )INDEX card
  #
  # Usage: processINDEXOFF()
  # Returns: nothing but will turn off index processing
  # -----------------------------------------------------------

  my $currentSubroutine = 'processINDEXOFF';
  my $card = shift;       

  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      $provideIndex = 0;                                       # index turned off
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processINDEXOFF

sub getTabValue {
  # -----------------------------------------------------------
  # Routine to get and process cursor values
  #
  # Usage: getTabeValue(<fieldType>, <cursor value>, <cursor ref>, <column index>)
  # Returns: a formatted cursor value
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'getTabValue';
  my $fieldType = shift;
  my $fieldValue = shift;
  my $cursorRef = shift;
  my $columnIndex = shift; 
  
  my $formattedValue = "";      # string to be returned
  
  if ( isNumeric($fieldType) ) { # the fieldType is numeric - DB2 returns a numeric field type
    if ( ($fieldType == -1) || ($fieldType == -4) || ($fieldType == -10) ) { # long field
      if ( defined($fieldValue) ) {       # is the field defined? (if it isn't then perhaps it needs to be retrieved
        $formattedValue = $fieldValue;      # just move the data across
      }
      else { # it's not defined so retrieve it
        $formattedValue = getLong($skelCursor{$cursorRef},$columnIndex);    # retrieve the data from the DB
      }
    } 
    else { # no special processing needs to be done as it is not a long field
      if ( ! defined($fieldValue) ) { return 'NULL' ; } # if the field isn't defined then set it's value to NULL
      if ( ( $fieldType == 1 ) || ( $fieldType == 12 ) || ( $fieldType == -8 ) || ( $fieldType == -9 )) { # char, varchar or wchar field
        $formattedValue = trim($fieldValue);         # trim spaces from the front and end of the field  
        displayDebug("Column has a value of $formattedValue [char, vchar or wchar field]\n",2,$currentSubroutine);
      }
      else { # no need to trim - not a varchar, check for trunc or decimal places
        if ( ' 3 ' =~ / $fieldType / ) { # it is decimal so do truncating
          if ( $truncateTrailingZeroes && ($fieldValue =~ /\./) ) { # if there are trailing zeroes then remove them (but only if there is a decimal point)
            displayDebug("Before Tr: $fieldValue<\n",2,$currentSubroutine);
            $fieldValue =~ s/0*$//g;  
            if ( $fieldValue =~ /\.$/ ) { # last char is a period
              ($fieldValue) = ($fieldValue =~ /(.*)\.$/);   # drop the last character
            }
            displayDebug("After  Tr: $fieldValue<\n",2,$currentSubroutine);
          }
          if ( $cursorDecimalPlaces != -1 ) { # decimal places has been set
            if ( $fieldValue =~ /\./ ) { # it is not an integer value
              displayDebug("Before DP: $fieldValue<\n",2,$currentSubroutine);
              $fieldValue = sprintf("%." . $cursorDecimalPlaces . "f", $fieldValue);
              displayDebug("After  DP: $fieldValue<\n",2,$currentSubroutine);
            }
          }
        }
        if ( $skelDebugLevel > 0 ) { 
          $formattedValue = "($fieldType) $fieldValue";
        }
        else {
          $formattedValue = $fieldValue;
        }
        displayDebug("Column has a value of $formattedValue [not char]\n",2,$currentSubroutine);
      }
    }
  }
  else { # fieldType is not numeric  (put in for DBMS's that supply character strings - i.e. SQLITE)
    if ( ! defined($fieldValue) ) { return 'NULL' ; } # if the field isn't defined then set it's value to NULL
    
    if ( $fieldType eq "TEXT" ) {         # character field
      $formattedValue = trim($fieldValue);  # trim spaces from the front and end of the field
      displayDebug("Column has a value of $formattedValue [TEXT]\n",2,$currentSubroutine);
    }
    else { # no need to trim - not a varchar
      if ( $truncateTrailingZeroes  && ($fieldValue =~ /\./) ) { # if there are trailing zeroes then remove them (but only if there is a decimal point)
        $fieldValue =~ s/0*$//g;  
      }
      if ( ($cursorDecimalPlaces != -1) && ($fieldValue =~ /\./) ) { # decimal places has been set
        displayDebug("Before: $fieldValue<\n",2,$currentSubroutine);
        $fieldValue = sprintf("%." . $cursorDecimalPlaces . "f", $fieldValue);
        displayDebug("After: $fieldValue<\n",2,$currentSubroutine);
      }
      $formattedValue = $fieldValue;
      displayDebug("Column has a value of $formattedValue [not TEXT]\n",2,$currentSubroutine);
    }
  }
  
  return $formattedValue;

} # end of getTabValue

sub processGRAPHLABEL {
  # -----------------------------------------------------------
  # Routine to establish the labels for graphs
  #
  # The GRAPHLABEL control statement looks like )GRAPHLOCAL <label Ref> <label caption> 
  #
  # so a sample card would be:
  #
  #    )GRAPHLABEL testdata test data introduced here
  #
  # Usage: processGRAPHLABEL(<control Card>)
  # Returns: nothing but will store the label information for later processing
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processGRAPHLABEL';

  my $card = shift;                                            # get the card information
  my $labelRef = getToken($card);                              # (GROUPREF) this is the group ID assigned (should match a group ID in the data)
  my $labelCaption = '';
  if ( $currentLinePosition < length($card)) {                 # there is a caption
    $labelCaption = trim(substr($card,$currentLinePosition));  # the caption is the rest of the line
  }
  
  if ($labelCaption eq '' )  { # no caption so ignore the card
    displayDebug("No caption on )GRAPHLABEL control card so card ignored\n",2,$currentSubroutine);
    return;
  }
  
  $graphLabel{$labelRef} = $labelCaption;                               # put name on stackA
  
} # end of processGRAPHLABEL

sub processGRAPHGROUP {
  # -----------------------------------------------------------
  # Routine to establish the formatting (and existence) of a graph group
  #
  # The GRAPHGROUP control statement looks like )GRAPHGROUP <group Ref> <name> parameters
  #
  # so a sample card would be:
  #
  #    )GRAPHGROUP 1 'test 1' options: { drawPoints: { style: 'square' // square, circle }, shaded: { orientation: 'bottom' // top, bottom } }
  #
  # Usage: processGRAPHGROUP(<control Card>)
  # Returns: nothing but will store the graph grouping details for later use
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processGRAPHGROUP';

  my $card = shift;                                            # get the card information
  my $groupRef = getToken($card);                              # (GROUPREF) this is the group ID assigned (should match a group ID in the data)
  
  $graphGroupName{$groupRef} = getToken($card);                               # put name on stackA
  $graphGroupOptions{$groupRef} = trim(substr($card,$currentLinePosition));          # save the formatting for this group
  
} # end of processGRAPHGROUP

sub processGRAPHGROUPCLEAR {
  # -----------------------------------------------------------
  # Routine to clear out the graph grouping details
  #
  # The GRAPHGROUPCLEAR control statement looks like )GRAPHGROUPCLEAR
  #
  # so a sample card would be:
  #
  #    )GRAPHGROUPCLEAR
  #
  # Usage: processGRAPHGROUPCLEAR()
  # Returns: nothing but will clear out the vis.js graph grouping records
  # -----------------------------------------------------------  
  
  %graphGroupOptions = ();
  %graphGroupName = ();
  $graphVariableNames = '';
  
} # end of processGRAPHGROUPCLEAR

sub processGRAPH {
  # -----------------------------------------------------------
  # Routine to print out a graph of generated data
  #
  # The GRAPH control statement looks like )GRAPH <DB Ref> <SQL Statement>
  #
  # so a sample card would be:
  #
  #    )GRAPH dbconn1 select 'x: ''' || date || ''', y: ' || char(value) || ',1' from database from dba.dbowner
  #
  # The SQLStatement must provide x and y values as well as a grouping literal. All entries for the one group MUST be sorted together
  #
  # Usage: processGRAPH(<control Card>)
  # Returns: nothing but will print out a graph of the generated data based on supplied information
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processGRAPH';
  my $num_of_fields = 0;                                       # field containing the number of columns returned
  my $tStr = "";                                               # this string will hold the generated output line
  my $skelTabValue = '';                                       # value of the column

  my $card = shift;                                            # get the card information
  my $DBConnectionRef = getToken($card);                       # (CONNREF) this is the database ref that a )LOGON should have created
  
  my $graphType = '';                                          # graph type default to line (which is the vis.js default)
  my $newSQL;
  
  my $SQL = trim(substr($card,$currentLinePosition));          # (SQL Statement) SQL to be used
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      
      setVariable('LASTGRAPHCount','0');                       # initialise variable
      # process the supplied SQL
  
      if ( uc($SQL) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                    # does the sql start with either SQL: or FILE: or FILE= or SQL=
        $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
      }
      elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
        $SQL = loadInlineCards($currentSubroutine);             # load the SQL
      }
      
      # all the parameters have now been processed
      
      if ( trim($SQL) ne '' ) { # if some SQL was supplied then ......
      
        $cursorSQL{'GRAPH'} = $SQL;                               # set up the SQL
        
        my $firstLine = 1;

        if ( ! defined($skelConnection{$DBConnectionRef}) ) { # A )LOGON hasn't created the database connection yet - fail this statement
          displayError("A previous )LOGON statement has not created a connection for $DBConnectionRef\nThis )GRAPH will be ignored",$currentSubroutine);
        }
        else {
          # now process the open
          if ( establishCursor( $DBConnectionRef, 'GRAPH' ) ) {     # returns 1 if all is ok (and attempts to read the first row)
      
            if ( $cursorRowNumber{'GRAPH'} == 0 ) {                 # no rows returned (should be 1 at this point)
              displayDebug("Call to SQL returned 0 rows",2,$currentSubroutine);
              outputLine("No Data Returned"); 
            }
            else { # a row was returned
            
              displayGraph_start();                                    # write out the start of the routine
      
              displayDebug("Rows returned",2,$currentSubroutine);
              $num_of_fields = $skelCursor{'GRAPH'}->{NUM_OF_FIELDS};
              displayDebug("Number of fields = $num_of_fields\n",2,$currentSubroutine);

              # write out the data .....
          
              displayDebug("About to enter row loop",2,$currentSubroutine);
              my $moreToProcess = 1;                              # initialise the stop flag
              my $rowNumber = 1;
              my $currentGraphName = '';
          
              while ( $moreToProcess ) {                          # A value of 1 indicates data was returned
              
                if ( $graphLibrary eq 'vis' ) { # do vis.js processing ......
                  if ( $firstLine ) { 
                    outputLine("  var items = [{${$skelCursorRow{'GRAPH'}}[0]}");
                    $firstLine = 0;   
                  }               
                  else { # not the first line so need to prefix with a comma
                    outputLine(",{${$skelCursorRow{'GRAPH'}}[0]}");
                  }
                }
                elsif ( $graphLibrary eq 'plotly' ) { # it is plotly
                  my $graphName = "Unknown";
                  if ( ! defined(${$skelCursorRow{'GRAPH'}}[2]) ) { # 3rd parameter not supplied so pretend it is Unknown
                    $graphGroupName{'Unknown'} = "Unknown_1";
                    $graphGroupOptions{'Unknown'} = "";
                  }
                  else { 
                    $graphName = ${$skelCursorRow{'GRAPH'}}[2]; 
                  }
                  if ( $currentGraphName ne $graphName ) { # change of graph
                    if ( $currentGraphName ne '' ) { # not the first graph so previous graph needs to be terminated
                      displayGraph_terminate($currentGraphName);    
                    } 
                    $firstLine = 1;
                    $currentGraphName = $graphName;
                  }
                  
                  if ( $firstLine ) { # first line so set up the variable .....
                    # create a list of the variables for later use
                    if ( $graphVariableNames eq '' ) { $graphVariableNames = "var_$currentGraphName"; }
                    else { $graphVariableNames .= ",var_$currentGraphName"; }
                    
                    outputLine("var_$currentGraphName = {x: [ ${$skelCursorRow{'GRAPH'}}[0]");
                    push (@YAxisValues, ${$skelCursorRow{'GRAPH'}}[1]);     # save the Y axis value for later processing
                    $firstLine = 0;
                  }
                  else { # not the first line so need to prefix with a comma
                    outputLine(",${$skelCursorRow{'GRAPH'}}[0]");
                    push (@YAxisValues, ${$skelCursorRow{'GRAPH'}}[1]);     # save the Y axis value for later processing
                  }
                }
            
                # move on to the next row now .....
            
                $moreToProcess = getNextRecord('GRAPH'); # 1 is returned if more data to process, 0 if at end of cursor
                $rowNumber++;

              } # end of while loop 
              
              if ( $graphLibrary eq 'plotly' ) {
                displayGraph_terminate($currentGraphName);    
              }
          
              setVariable('LASTGRAPHCount',$cursorRowNumber{'GRAPH'});       
              closeCursor('GRAPH');                # close the GRAPH cursor
              
              displayGraph_finish($graphOptions);                      # write out the end of the routine
            
            } # end of a row was returned
          }  # end of cursor open failed
          else { # Problems in river city - open cursor failed
            if ( $skelVerboseSQLErrors eq 'Yes' ) {
              if ( $SQLError ) { # SQL Error (not just no rows found)
                displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SQL",$currentSubroutine);
              }
              else {
                displayError("No Rows Found for SQL: \n $SQL",$currentSubroutine);
              }
            }
            else { # not verbose - dont mention it if no rows found and if SQL error dont print SQL
              if ( $SQLError ) { # SQL Error (not just no rows found)
                displayError("Call to SQL failed - will pretend no records found\n",$currentSubroutine);
              }
            }
          }
        }
        displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
      }
    }  
  }  
 
} # end of processGRAPH

sub processGRAPHSTART {
  # -----------------------------------------------------------
  # Routine to print out a the start of the graph formatting up to the 
  # point where the data should be defined
  #
  # The GRAPHSTART control statement looks like )GRAPHSTART
  #
  # so a sample card would be:
  #
  #    )GRAPHSTART 
  #
  # Usage: processGRAPHSTART()
  # Returns: nothing but will print out the start part of the javascrfipt code to display a graph
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processGRAPHSTART';
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      
      displayGraph_start();                                    # write out the start of the routine
      
    }
    displayDebug("Processed: )GRAPHSTART. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
 
} # end of processGRAPHSTART

sub processGRAPHFINISH {
  # -----------------------------------------------------------
  # Routine to print out a the end of the graph formatting 
  #
  # The GRAPHFINISH control statement looks like )GRAPHFINISH [<graph options>] 
  #
  # so a sample card would be:
  #
  #    )GRAPHFINISH {BAR,start: '2016-05-01', end: '2016-05-05'} 
  #
  # Usage: processGRAPHFINISH(<control Card>)
  # Returns: nothing but will print out the end part of the javascrfipt code to display a graph
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processGRAPHFINISH';
  my $card = shift;                                            # get the card information
  
  $graphOptions = trim(substr($card,$currentLinePosition));          # options to be used
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      
      if ( trim($graphOptions) ne "") {                        # something has been passed
        my $tmp = getToken($card); 
        if ( ' BAR LINE ' =~ uc($tmp) ) {                      # known chart type 
          $graphType = $tmp;
          $graphOptions = trim(substr($card,$currentLinePosition));    #  reset the options to the next bit of the card
        }
      }
      
      # all the parameters have now been processed
      
      displayGraph_finish($graphOptions);                                    # write out the start of the routine
      
    }
    displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
 
} # end of processGRAPHFINISH

sub processGRAPHOPT {
  # -----------------------------------------------------------
  # Routine to set the options for a GRAPH object
  #
  # The GRAPHOPT control statement looks like )GRAPHOPT [graph type] <Graph options>
  #
  # so a sample card would be:
  #
  #    )GRAPHOPT BAR {paper_bgcolor: 'rgba(0,0,0,0)'}
  #
  # or
  #
  #    )GRAPHOPT {paper_bgcolor: 'rgba(0,0,0,0)'}
  #
  # Usage: processGRAPHOPT(<control Card>)
  # Returns: nothing but will set a variable holding the oprions
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processGRAPHOPTIONS';
  my $card = shift;                                            # get the card information
  
  $graphOptions = trim(substr($card,$currentLinePosition));    # 
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      
      if ( trim($graphOptions) ne "") {                        # something has been passed
        my $tmp = uc(getToken($card)); 
        if ( (length($tmp) == 3) && ($tmp eq 'BAR')) { 
          $graphType = $tmp;
          $graphOptions = trim(substr($card,$currentLinePosition));    #  reset the options to the next bit of the card
        }
        elsif ( (length($tmp) == 4) && ($tmp eq 'LINE')) { 
          $graphType = $tmp;
          $graphOptions = trim(substr($card,$currentLinePosition));    #  reset the options to the next bit of the card
        }
      }
      
    }
    displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
 
} # end of processGRAPHOPT

sub displayGraph_start {
  # -----------------------------------------------------------
  # Routine to print out the start part of a vis.js display routine
  #
  # Usage: displayGraph_start
  # Returns: nothing but will print out the start part of a vis.js routine
  # -----------------------------------------------------------  

  my $currentSubroutine = 'displayGraph_start';
  
  # If libraries not written (script and link) then write them out now ......
  
  if ( $graphIncludesWritten == 0 ) {   # graph includes not yet written so do it now
    processGRAPHLIB('');                # call the )GRAPHLIB routine to just set the defaults
  }
    
  if ( $graphStarted > 0 ) { # already printed out a start .... ignore this request
    displayERROR("The start code for a graph ($graphLibrary) routine has already been output with no terminating code. \nThis request to print it again will be ignored");
  }
  else {
    outputLine('<div id="graphArea' . $currentGraphNum . '" style="width:90%;"></div>');
    outputLine('<script type="text/javascript">');

    if ( $graphLibrary eq 'vis' ) {     # check for vis.js options and output them    
      if ( %graphGroupOptions ) { # groups have been defined and options set
        displayDebug("VIS.JS Groups have been defined",2,$currentSubroutine);
        outputLine('  var names = [');
        my $firstGroup = 1;
        foreach my $i (sort by_key keys %graphGroupName) {
          if ( $firstGroup ) {
            $firstGroup = 0;
            outputLine("  '$graphGroupName{$i}' ");
          }
          else {
            outputLine("  ,'$graphGroupName{$i}' ");
          }
        }
        outputLine('  ];');
        outputLine('  var groups = new vis.DataSet();');

        foreach my $i (sort by_key keys %graphLabel) {
          outputLine('      var ' . $i . ' = { content: "' . $graphLabel{$i} . '" }' );
        }

        my $arrayCount = 0;                                    # this should mirrow the order that the NAMES array was built
        foreach my $i (sort by_key keys %graphGroupName) {
          outputLine('      groups.add({ id: ' . $i . ', content: names[' . $arrayCount . '] , ' . $graphGroupOptions{$i} . ' });' );
          $arrayCount++;                                       # increment the array location
        }
      }
    }
    
    outputLine('  var container = document.getElementById(\'graphArea' . $currentGraphNum . '\');');
    if ( $graphLibrary eq 'vis' ) {
      # moved to the processGRAPH subroutine to make it consitent with PLOTLY 
      # outputLine('  var items = [');
    }
    else { # it must be plotly
      # dont output anything as data description will all be done in the processGRAPH routine
      # outputLine('  var items = [{');
    }
    $currentGraphNum++;                                 # increment the count so that the next )GRAPH will generate a new area to link to
    $graphStarted++;                                    # flag the fact that the start portion has been written
  }

} # end of displayGraph_start

sub displayGraph_terminate {
  # -----------------------------------------------------------
  # Routine to print out the end part of a graph data variable section
  #
  # Usage: displayGraphTerminate(<name of the graph being terminated>)
  # Returns: nothing but will print out the end part of a graph data variable section
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'displayGraph_terminate';
  my $tmpGraphName = shift;
  
  outputLine('], y: [');                        # terminate the x values array and start the y value array .....
  for ( my $i=0; $i<= $#YAxisValues; $i++) {    # loop throught the saved Y values
    if ( $i == 0 ) {                            # first entry so no leading comma
      outputLine($YAxisValues[$i]);
    }
    else {
      outputLine(",$YAxisValues[$i]");
    }
  }
  if ( $graphGroupOptions{$tmpGraphName} eq '' ) { # no options have been set
    outputLine(" ] , name: '$graphGroupName{$tmpGraphName}'}; ");                           # close out the Y array
  }
  else { # options for this graph have been set 
    outputLine("], name: '$graphGroupName{$tmpGraphName}', $graphGroupOptions{$tmpGraphName} }; ");                           # close out the Y array
  } 
    
  @YAxisValues = ();       # clear out the array  
      
} # end of displayGraph_terminate

sub displayGraph_finish {
  # -----------------------------------------------------------
  # Routine to print out the end part of a graph display routine
  #
  # Usage: displayGraph_finish(<graph options>)
  # Returns: nothing but will print out the end part of a vis.js routine
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'displayGraph_finish';
  my $options = shift;                   
  
  if ( $graphStarted == 0 ) { # no start section written  
    displayERROR("The start code for a graph ($graphLibrary) routine has not been written. \nThis request to print out the terminating code will be ignored");
  }
  else {
    if ( $graphLibrary eq 'vis' ) {
      outputLine('  ];');
      outputLine('  var dataset = new vis.DataSet(items);');       
      outputLine('  var options = {' . $options . '};');       
      if ( %graphGroupName ) { # groups have been defined
        outputLine('  var graph2d = new vis.Graph2d(container, dataset, groups, options);');       
      }
      else { # no groups have been defined
        outputLine('  var graph2d = new vis.Graph2d(container, dataset, options);');       
      }
    }
    else { # assume it is a plotly graph
      # output the data array definition 
      
      outputLine("  var data = [$graphVariableNames];");       
            
      if ( $options ne '' ) {
        if ( substr($options,0,1) eq '{' ) {   # already in braces so dont put more in
          outputLine('  var options = ' . $options . ';');       
        }
        else { # enclose in braces
          outputLine('  var options = {' . $options . '};');       
        } 
      }
      else { # just put in a dummy
        outputLine('  var options = {};');       
      }
        
      outputLine('  Plotly.plot( container, data, options, {showLink: false, displaylogo: false}); '); # dont show the edit graph link
    }
    outputLine('</script>');       
            
    $graphStarted = 0;
  }

} # end of displayGraph_finish

sub processCTAB {
  # -----------------------------------------------------------
  # Routine to print out a formatted selection table with checkboxes 
  #
  # The CTAB control statement looks like )CTAB <DB Ref> [(<ID>[,<Button Name>][,<Form Components to Generate[,Field Target[,form method[,field set Label]]]])] <SQL Statement>
  #
  # so a sample card would be:
  #
  #    )CTAB dbconn1 (DB,Select Database To Process,SEF,test.cgi,POST,Databases Available for selection) select database, 0, database from dba.dbowner
  #
  # Usage: processCTAB(<control Card>)
  # Returns: nothing but will print out a horizontally formatted dump of a table
  #          with check boxes and a select button
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processCTAB';
  my $num_of_fields = 0;                                       # field containing the number of columns returned
  my $tStr = "";                                               # this string will hold the generated output line
  my $skelTabValue = '';                                       # value of the column

  my $card = shift;                                            # get the card information
  my $DBConnectionRef = getToken($card);                       # (CONNREF) this is the database ref that a )LOGON should have created
  my $SQL = trim(substr($card,$currentLinePosition));          # (SQL Statement) SQL to be used
  
  my $parms  = '';                                             # parms being passed to control what is generated
  my $buttonName = '';                                         # button name if supplied
  my $newSQL = ''; 
  my $form = '';                                               # flag indicating what form entries should be generated
  my $form_target = 'test.cgi';                                # target to use if button is selected
  my $form_method = 'POST';                                    # method to use on the form 
  my $fieldLegend = '';                                        # fieldset legend
  my $checked = 0;                                             # indicates if checkbox is pre-checked
  my @checkBox_names;
  my @checkBox_labels;
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
            
      setVariable('LASTCTABCount','0' );                       # initialise variable
      if ( substr($SQL,0,1) eq '(' ) {
        ($parms, $newSQL) = ($SQL =~ /\((.*?)\)(.*)/);
        $SQL = trim($newSQL);
        $parms = trim($parms);
        if ( $parms =~ /,/ ) { # if the parm contains a comma then it includes multiple parameters. A # parameter ends the string of checkbox names
          my @tmpParm = split(',',$parms);
          @checkBox_names = ();  # array of checkbox names
          @checkBox_labels = ();  # array of checkbox labels
          my $startParms = 0;  # indicates where the non-checkbox parms start
          for (my $i=0 ; $i <= $#tmpParm ; $i++ ) {
            $startParms++;               # adjust the start position of non checkbox parms forward
            if ( $tmpParm[$i] eq '#' ) { # end of checkbox names
              last;  
            }
            $checkBox_names[$i] = $tmpParm[$i];
            $checkBox_labels[$i] = $tmpParm[$i];
            if ( $checkBox_names[$i] =~ /:/ ) { # if there is a colon then there is a separate label to use as the header
              ($checkBox_names[$i] , $checkBox_labels[$i]) = ( $checkBox_names[$i] =~ /(.*?)\:(.*)/);
            }
          }
          if ( defined($tmpParm[$startParms + 0]) ) { $buttonName  = $tmpParm[$startParms + 0]; }
          if ( defined($tmpParm[$startParms + 1]) ) { $form        = $tmpParm[$startParms + 1]; }          # form: S - put in <form>, E - put in </form>, F - put in <fieldset>
          if ( defined($tmpParm[$startParms + 2]) ) { $CTAB_form_name = $tmpParm[$startParms + 2]; }     # form name
          if ( defined($tmpParm[$startParms + 3]) ) { $form_target = $tmpParm[$startParms + 3]; }   # script the button will call
          if ( defined($tmpParm[$startParms + 4]) ) { $form_method = $tmpParm[$startParms + 4]; }   # method to use on form
          if ( defined($tmpParm[$startParms + 5]) ) { $fieldLegend = $tmpParm[$startParms + 5]; }
        }
        displayDebug("Extracted button name is: $buttonName, form is: $form, SQL is: $SQL",1,$currentSubroutine);
      }
            
      if ( uc($SQL) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                         # does the sql start with either SQL: or FILE: or SQL= or FILE=
        $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
      }
      elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
        $SQL = loadInlineCards($currentSubroutine);             # load the SQL
      }

      if ( ! $checkAllWritten ) { # if we haven';t written out the check all javascript function then do it now
        outputLineNT('<script type="text/javascript">');
        outputLineNT('function SetAllCheckBoxes(FormName, FieldName, CheckValue)');
        outputLineNT('{');
        outputLineNT('  if(!document.forms[FormName])');
        outputLineNT('      return;');
        outputLineNT('    var objCheckBoxes = document.forms[FormName].elements[FieldName];');
        outputLineNT('  if(!objCheckBoxes)');
        outputLineNT('      return;');
        outputLineNT('  var countCheckBoxes = objCheckBoxes.length;');
        outputLineNT('  if(!countCheckBoxes)');
        outputLineNT('      objCheckBoxes.checked = CheckValue;');
        outputLineNT('    else');
        outputLineNT('      // set the check value for all check boxes');
        outputLineNT('      for(var i = 0; i < countCheckBoxes; i++)');
        outputLineNT('          objCheckBoxes[i].checked = CheckValue;');
        outputLineNT('}');
        outputLineNT('</script>');
        $checkAllWritten = 1;     # make sure this isn't written twice
      }

      if ( trim($SQL) ne '' ) { # if some SQL was supplied then ......
      
        $cursorSQL{'CTAB'} = $SQL;                               # set up the SQL

        if ( ! defined($skelConnection{$DBConnectionRef}) ) { # A )LOGON hasn't created the database connection yet - fail this statement
          displayError("A previous )LOGON statement has not created a database connection for $DBConnectionRef\nThis )CTAB will be ignored",$currentSubroutine);
        }
        else {
          # now process the open
          if ( establishCursor( $DBConnectionRef, 'CTAB' ) ) {     # returns 1 if all is ok (and attempts to read the first row)
      
            if ( $cursorRowNumber{'CTAB'} == 0 ) {                 # no rows returned (should be 1 at this point)
              displayDebug("Call to SQL returned 0 rows",2,$currentSubroutine);
              outputLine("No Data Returned"); 
            }
            else { # a row was returned
              displayDebug("Rows returned",2,$currentSubroutine);
              $num_of_fields = $skelCursor{'CTAB'}->{NUM_OF_FIELDS};
              displayDebug("Number of fields = $num_of_fields\n",2,$currentSubroutine);
          
              # Write out headings ...... only done as HTML code - doesn't make sens e as non-HTML

              if ( uc($form) =~ /S/ ) { # form start should be included
                outputLine("<form name=\"$CTAB_form_name\" action=\"$form_target\" method=\"$form_method\" accept-charset=\"UTF-8\" autocomplete=\"off\" novalidate>");
                $FORM_has_been_opened = 1;
      
                if ( uc($form) =~ /F/ ) { # fieldset should be used
                  outputLine("<fieldset>");
                  $FIELDSET_has_been_opened = 1;
                  if ( $fieldLegend ne '' ) { outputLine("<legend>$fieldLegend</legend>"); }
                }
              }
          
              $CTABNumber++;
              outputLine("<table id=\"CTAB$CTABNumber\" border=\"1\"><tr>");
              if ( $#checkBox_names == -1 ) {  # if no ID was supplied then just make one up
                outputLine("<th> <input type=\"checkbox\" name=\"checkAll_ID\" onclick=\"SetAllCheckBoxes('$CTAB_form_name', 'ID', document.forms['$CTAB_form_name'].elements['checkAll_ID'].checked);\"/></th>");
              }
              else {
                for ( my $i = 0 ; $i <= $#checkBox_names; $i++) {
                  my $ID = $checkBox_names[$i];
                  if ( substr($ID,0,1) eq '*' ) { # if the field name starts with an asterix dont put it in the heading
                    $ID = substr($ID,1);     # drop the first character
                    outputLine("<th> <input type=\"checkbox\" name=\"checkAll_$ID\" onclick=\"SetAllCheckBoxes('$CTAB_form_name', '$ID', document.forms['$CTAB_form_name'].elements['checkAll_$ID'].checked);\"/></th>");
                  }
                  else {
                    outputLine("<th> <input type=\"checkbox\" name=\"checkAll_$ID\" onclick=\"SetAllCheckBoxes('$CTAB_form_name', '$ID', document.forms['$CTAB_form_name'].elements['checkAll_$ID'].checked);\"/><br>$checkBox_labels[$i]</th>");
                  }
                }
              }
              
              # Loop through column headings 2->  [heading 0 and 1 are for control fields]
              for ( my $i=2; $i<$num_of_fields; $i++ ) { # skip the first column as that is the row key 
                outputLine("<th>" . $skelCursor{'CTAB'}->{NAME}->[$i] . "</th>");
              } 
              outputLine("</tr>\n");
          
              # write out the data .....
          
              displayDebug("About to enter row loop",2,$currentSubroutine);
              my $moreToProcess = 1;                              # initialise the stop flag
              my $rowNumber = 1;
          
              while ( $moreToProcess ) {                          # A value of 1 indicates data was returned
                $checked = '';                                       # by default dont check the check box
                $skelTabValue = ${$skelCursorRow{'CTAB'}}[1];
                if ( $skelTabValue eq '1' ) { $checked = 'checked' ; } 
                
                displayDebug("In cursor loop",2,$currentSubroutine);
                my $fieldType = $skelCursor{'CTAB'}->{TYPE}->[0];                                    # $fieldType is now the field type (CHAR, VARCHAR etc)
                $skelTabValue = getTabValue($fieldType, ${$skelCursorRow{'CTAB'}}[0], 'CTAB',  0);   # pass field type and the field across
                displayDebug("Key is: $skelTabValue",2,$currentSubroutine);
                $tStr = "<tr>";   # set new table row tag
                if ( $#checkBox_names == -1 ) {  # if no ID was supplied then just make one up
                      $tStr .= "<td valign=\"top\"> <input type=\"checkbox\" id=\"ID\.$rowNumber\" name=\"ID\" value=\"$skelTabValue\" $checked /></td>\n";   # set new table row tag
                }
                else {
                  foreach my $ID (@checkBox_names) {
                    if ( substr($ID,0,1) eq '*' ) { # if the field name starts with an asterix then ignore the first character
                      $ID = substr($ID,1);     # drop the first character
                      $tStr .= "<td valign=\"top\"> <input type=\"checkbox\" id=\"$ID\.$rowNumber\" name=\"$ID\" value=\"$skelTabValue\" $checked /></td>\n";   # set new table row tag
                    }
                    else {
                      $tStr .= "<td valign=\"top\"> <input type=\"checkbox\" id=\"$ID\.$rowNumber\" name=\"$ID\" value=\"$skelTabValue\" $checked /></td>\n";   # set new table row tag
                    }
                  }
                }
                
                for ( my $i=2; $i<$num_of_fields; $i++ ) {      # loop through all of the display fields
                  my $fieldType = $skelCursor{'CTAB'}->{TYPE}->[$i]; # $fieldType is now the field type (CHAR, VARCHAR etc)
              
                  $skelTabValue = ${$skelCursorRow{'CTAB'}}[$i];
                  if ( defined($skelTabValue) ) { 
                    displayDebug("Column $i has a type of $fieldType and a value of $skelTabValue\n",2,$currentSubroutine);
                  }
                  else {
                    displayDebug("Column $i has a type of $fieldType and has no value\n",2,$currentSubroutine);
                  }

                  $skelTabValue = getTabValue($fieldType, ${$skelCursorRow{'CTAB'}}[$i], 'CTAB',  $i);   # pass field type and the field across
  
                  if ( isNumeric($fieldType) ) { # field type is a numeric (DB2 field types are numeric)
                    if ( $numericFieldTypes =~ $fieldType ) { # right align numeric fields
                      $tStr .= "<td align=\"right\">" . $skelTabValue . "</td> ";
                    }
                    else { # character field ... just normal left alignment
                      $tStr .= "<td>" . $skelTabValue . "</td> ";
                    }
                  }
                  else { # the field types are not numeric (SQLite uses character strings)
                    if ( $fieldType eq "NUMERIC" ) { # right align numeric fields
                      $tStr .= "<td align=\"right\">" . $skelTabValue . "</td> ";
                    }
                    else { # dont right align the value ... just normal left alignment
                      $tStr .= "<td>" . $skelTabValue . "</td> "; 
                    }
                  }
                }
                outputLine("$tStr</tr>");
            
                # move on to the next row now .....
            
                $moreToProcess = getNextRecord('CTAB'); # 1 is returned if more data to process, 0 if at end of cursor
                $rowNumber++;

              } # end of while loop 
          
              # no more data
              outputLine("</table>");         # terminate the HTML table
              if ( $buttonName ne '' ) { # if button name has been provided
                outputLine("<input type=\"submit\" value=\"$buttonName\" class=\"CTAB Button\">");         # terminate the HTML table
              }
          
              if ( uc($form) =~ /E/ ) { # form end should be included
                if ( $FIELDSET_has_been_opened ) { # if it has been opened then close it
                  outputLine("</fieldset>");
                  $FIELDSET_has_been_opened = 0;
                }
                if ( $FORM_has_been_opened ) { # if a <FORM> has been opened then close it
                  outputLine("</form>");
                  $FORM_has_been_opened = 0;
                }
                else {
                  displayError ("</FORM> not generated as no initial <FORM> generated",$currentSubroutine);
                }
              }
          
              setVariable('LASTCTABCount',$cursorRowNumber{'CTAB'});       
              closeCursor('CTAB');                # close the CTAB cursor
            } # end of a row was returned
          }  # end of cursor open failed
          else { # Problems in river city - open cursor failed
            if ( $skelVerboseSQLErrors eq 'Yes' ) {
              if ( $SQLError ) { # SQL Error (not just no rows found)
                displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SQL",$currentSubroutine);
              }
              else {
                displayError("No Rows Found for SQL: \n $SQL",$currentSubroutine);
              }
            }
            else { # not verbose - dont mention it if no rows found and if SQL error dont print SQL
              if ( $SQLError ) { # SQL Error (not just no rows found)
                displayError("Call to SQL failed - will pretend no records found\n",$currentSubroutine);
              }
            }
          }
        }
        displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
      }
      else { # SQL not supplied so dont do any 'data' things
        # START flag (S)
        if ( uc($form) =~ /S/ ) { # form start should be included
          outputLine("<form name=\"$CTAB_form_name\" action=\"$form_target\" method=\"$form_method\" accept-charset=\"UTF-8\" autocomplete=\"off\" novalidate>");
          $FORM_has_been_opened = 1;
      
          if ( uc($form) =~ /F/ ) { # fieldset should be used
            outputLine("<fieldset>");
            $FIELDSET_has_been_opened = 1;
            if ( $fieldLegend ne '' ) { outputLine("<legend>$fieldLegend</legend>"); }
          }
        }
      
        # Process BUTTON if Button Name supplied
        if ( $buttonName ne '' ) { # if button name has been provided
          outputLine("<input type=\"submit\" value=\"$buttonName\" class=\"CTAB Button\">");         # terminate the HTML table
        }
              
        # END flag (E)
        if ( uc($form) =~ /E/ ) { # form end should be included
          if ( $FIELDSET_has_been_opened ) { # if it has been opened then close it
            outputLine("</fieldset>");
            $FIELDSET_has_been_opened = 0;
          }
          if ( $FORM_has_been_opened ) { # if a <FORM> has been opened then close it
            outputLine("</form>");
            $FORM_has_been_opened = 0;
          }
          else {
            displayError ("</FORM> not generated as no initial <FORM> generated",$currentSubroutine);
          }
        }
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processCTAB

sub processSBOX {
  # -----------------------------------------------------------
  # Routine to print out a selection box derived form a database query
  #
  # The SBOX control statement looks like )SBOX <DB Ref> [(<ID>,<Form Name>, <Button Name>, <Form Components to Generate>, <Form Target>[,form method])] <SQL Statement>
  #
  # The HTML generated will look like (for a value of SE in <form components to generate>):
  # <form name="{form name}" action="{form target}" method="{form method - defaults to GET}"> 
  #   <select name="{Form Name} id="{ID}""> 
  #     <option value="{1st column of select query}">{2nd column of select query}</option>
  #   </select>
  #   <input type="submit" value="{Button Name}"> 
  # </form>
  #
  # so a sample card would be:
  #
  #    )SBOX dbconn1 (DB,DBSelect,Select Database,test.cgi,POST) select database, database from dba.dbowner
  #
  # Usage: processSBOX(<control Card>)
  # Returns: nothing but will print output a drop down select button 
  # -----------------------------------------------------------  
  
  my $card = shift;                                            # get the card information

  my $currentSubroutine = 'processSBOX';
  my $num_of_fields = 0;                                       # field containing the number of columns returned
  my $tStr = "";                                               # this string will hold the generated output line
  my $skelTabValue = '';                                       # value of the column

  my $DBConnectionRef = getToken($card);                       # (CONNREF) this is the database ref that a )LOGON should have created
  my $SQL = trim(substr($card,$currentLinePosition));          # (SQL Statement) SQL to be used
  
  my $parms  = '';                                             # parms being passed to control what is generated
  my $ID  = 'A';                                               # ID name to use for the checkboxes
  my $buttonName = '';                                         # button name if supplied
  my $newSQL = ''; 
  my $formName = 'SelectForm';                                 # form name 
  my $form_target = 'test.cgi';                                # target to use if button is selected
  my $form_method = 'GET';                                     # method to use on the form 
  my $form_components = '';                                    # form components to generate
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      
      setVariable('LASTSBOXCount', '0');                       # initialise variable
      if ( substr($SQL,0,1) eq '(' ) {
        ($parms, $newSQL) = ($SQL =~ /\((.*?)\)(.*)/);
        $SQL = trim($newSQL);
        $parms = trim($parms);
        if ( $parms =~ /,/ ) { # if the parm contains a comma then it includes a button name
          my @tmpParm = split(',',$parms);
          if ( defined($tmpParm[0]) ) { $ID = $tmpParm[0]; }
          if ( defined($tmpParm[1]) ) { $formName = $tmpParm[1]; }        
          if ( defined($tmpParm[2]) ) { $buttonName = $tmpParm[2]; }
          if ( defined($tmpParm[3]) ) { $form_components = $tmpParm[3];}    # form: S - put in <form>, E - put in </form>
          if ( defined($tmpParm[4]) ) { $form_target = $tmpParm[4]; }       # script the button will call
          if ( defined($tmpParm[5]) ) { $form_method = $tmpParm[5]; }       # method to use on form
        }
        displayDebug("Extracted ID is: $ID, button name is: $buttonName, form is: $formName, SQL is: $SQL",1,$currentSubroutine);
      }

      if ( uc($SQL) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
        $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
      }
      elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
        $SQL = loadInlineCards($currentSubroutine);             # load the SQL
      }

      if ( trim($SQL) ne '' ) { # if some SQL was supplied then ......
      
        $cursorSQL{'SBOX'} = $SQL;                               # set up the SQL

        if ( ! defined($skelConnection{$DBConnectionRef}) ) { # A )LOGON hasn't created the database connection yet - fail this statement
          displayError("A previous )LOGON statement has not created a database connection for $DBConnectionRef\nThis )SBOX will be ignored",$currentSubroutine);
        }
        else {
          # now process the open
          if ( establishCursor( $DBConnectionRef, 'SBOX' ) ) {     # returns 1 if all is ok (and attempts to read the first row)
      
            if ( $cursorRowNumber{'SBOX'} == 0 ) {                 # no rows returned (should be 1 at this point)
              displayDebug("Call to SQL returned 0 rows",2,$currentSubroutine);
              outputLine("No Data Returned"); 
            }
            else { # a row was returned
              displayDebug("Rows returned",2,$currentSubroutine);
              $num_of_fields = $skelCursor{'SBOX'}->{NUM_OF_FIELDS};
              displayDebug("Number of fields = $num_of_fields\n",2,$currentSubroutine);
            
              if ( $form_components =~ /S/ ) { # put in the form start
                outputLine("<form name=\"$formName\" action=\"$form_target\" method=\"$form_method\" accept-charset=\"UTF-8\" autocomplete=\"off\" novalidate>");
              }
            
              outputLine("<select id=\"$ID\" name=\"$formName\" border=\"1\">");
          
              # write out the data .....
          
              displayDebug("About to enter row loop",2,$currentSubroutine);
              my $moreToProcess = 1;                              # initialise the stop flag
              my $rowNumber = 1;
          
              while ( $moreToProcess ) {                          # A value of 1 indicates data was returned
                # no loop on columns as only the fisrt will be used (ond only then if there are 2 supplied)
                my $SBOX_Value = ${$skelCursorRow{'SBOX'}}[0];
                my $SBOX_Option = '';
                if ( $num_of_fields > 1 ) { # but really only interested in the 2nd
                  $SBOX_Option = ${$skelCursorRow{'SBOX'}}[1];
                }
                else {
                  $SBOX_Option = ${$skelCursorRow{'SBOX'}}[0];
                }
                outputLine("<option value=\"$SBOX_Value\">$SBOX_Option</opton>");
            
                # move on to the next row now .....
            
                $moreToProcess = getNextRecord('SBOX'); # 1 is returned if more data to process, 0 if at end of cursor
                $rowNumber++;

              } # end of while loop 
          
              # no more data
              outputLine("</select>");         # terminate the HTML select
              if ( $buttonName ne '' ) { # if the button doesn't have a name dont put it in
                outputLine("<input type=\"submit\" value=\"$buttonName\">");         # write out the submit button
              }
              if ( $form_components =~ /E/ ) {
                outputLine("</form>");           # terminate the HTML form
              }
          
              setVariable('LASTSBOXCount',$cursorRowNumber{'SBOX'});
              closeCursor('SBOX');                # close the SBOX cursor
            }
          }
          else { # Problems in river city - open cursor failed
            if ( $skelVerboseSQLErrors eq 'Yes' ) {
              if ( $SQLError ) { # SQL Error (not just no rows found)
                displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SQL",$currentSubroutine);
              }
              else {
                displayError("No Rows Found for SQL: \n $SQL",$currentSubroutine);
              }
            }
            else { # not verbose - dont mention it if no rows found and if SQL error dont print SQL
              if ( $SQLError ) { # SQL Error (not just no rows found)
                displayError("Call to SQL failed - will pretend no records found\n",$currentSubroutine);
              }
            }
          }
          displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
        }
      }
      else { # no SQL supplied so dont do any 'DATA' activities
        # Process START flag (S)
        if ( $form_components =~ /S/ ) { # put in the form start
          outputLine("<form name=\"$formName\" action=\"$form_target\" method=\"$form_method\" accept-charset=\"UTF-8\" autocomplete=\"off\" novalidate>");
        }

        # Process Button if required
        if ( $buttonName ne '' ) { # if the button doesn't have a name dont put it in
          outputLine("<input type=\"submit\" value=\"$buttonName\">");         # write out the submit button
        }
        
        # Process END Flag (E)      
        if ( $form_components =~ /E/ ) {
          outputLine("</form>");           # terminate the HTML form
        }
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processSBOX

sub processSetCookie {
  # -----------------------------------------------------------
  # Routine to set a cookie
  #
  # The SETCOOKIE control statement looks like )SETCOOKIE [time to expire in secs] <value pairs>
  #
  # so a sample card would be:
  #
  #    )SETCOOKIE [300] client=0001234628
  #
  # Usage: processSetCookie(<control Card>)
  # Returns: nothing but will set a cookie on the client
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processSetCookie';
  my $card = shift;                                            # get the card information
  my $parms = trim(substr($card,$currentLinePosition));          # the whole control card should consist of name/value pairs
  my $timeInSecs = 0;
  my $cookieExpire ;
  my $nameValuePairs;

  if ( $parms =~ /^\[.*\]/ ) { # an expiry date has bene supplied
    ($timeInSecs, $nameValuePairs) = ( $parms =~ /^\[(\d*)\](.*)/ );
    $nameValuePairs = trim($nameValuePairs);
    $timeInSecs = trim($timeInSecs);
    $cookieExpire = cookieDate($timeInSecs);
  }
  else {
    $nameValuePairs = $parms;
  }
  
  if ( $timeInSecs == 0 ) {
    outputLine("Set-Cookie: $nameValuePairs; ");
  }
  else { # an expiry time has been set
    outputLine("Set-Cookie: $nameValuePairs;  expires=$cookieExpire;");
  }

} # end of processSetCookie

sub cookieDate {
  # -----------------------------------------------------------
  # Routine togenerate a date/time given a seconds offset from the current date/time
  #
  # Usage : ( number of seconds) ;
  # Returns: a date/time value representing the current date/time + the 
  # number of seconds supplied  as a parameter
  # -----------------------------------------------------------

  my ($seconds) = @_;
  my $sydate=gmtime(time+$seconds);
  my ($day, $month, $num, $time, $year) = split(/\s+/,$sydate);
  my $zl=length($num);
  if ($zl == 1) { 
    $num = "0$num";
  }

  return "$day $num-$month-$year $time GMT";

} # end of cookie_date

sub processGetCookie {
  # -----------------------------------------------------------
  # Routine to get a cookie
  #
  # The GETCOOKIE control statement looks like )GETCOOKIE
  #
  # so a sample card would be:
  #
  #    )GETCOOKIE 
  #
  # Usage: processGetCookie(<control Card>)
  # Returns: nothing but will set skeleton variables to the values returned
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processGetCookie';
  my $name;     # parameter name
  my $value;    # parameter value
  
  my $temp=$ENV{'HTTP_COOKIE'};
  
  if ( defined($temp) ) { 
    if ( length($temp) > 0 ) { # some data was there
      my @cookieParms = split (';', $temp);
    
      foreach my $parm ( @cookieParms ) { # for each name/value pair
        if ( $parm =~ /\=/ ) { # parm contains an equals character
          ($name, $value) = split('=',$parm);
          $name = trim($name);
          setVariable($name, $value);
        }
        else { # no eaquals in string
          setVariable($parm, $parm);     # set the variable name and the variable value to the parm
        }
      }
    }
  }
  
} # end of processGetCookie

sub processHeading {
  # -----------------------------------------------------------
  # Routine to print out c$the headings for a FTAB statement
  #
  # Usage: processHeading(<control Card>)
  # Returns: nothing but will print out a horizontally formatted dump of a table
  # -----------------------------------------------------------  
  
  my $num_of_fields = shift;
  
  my $currentSubroutine = 'processHeading';
  my $tmpHeader;   
  my $tStr;        # variable holding the header string
  my $offset;      # difference between the length of the header and the max header size
  my $maxHeaderHeight = 1;

  # is it HTML or TEXT?
  if ( $outputMode eq "HTTP" ) {  # output it as a html table
    $tStr = "<table border=\"1\" id=\"FTAB$FTABNumber\"><tr>\n";
    # loop through the returned columns and generate the headers
    # Calculate the longest vertical header (note %vertHeaders identifies which are vertical)
    $maxHeaderHeight = 1;
    for ( my $i=0; $i<$num_of_fields; $i++ ) { 
      if ( defined($vertHeader{$i}) ) { # this header is vertical  
        if ( length($skelCursor{'FTAB'}->{NAME}->[$i]) > $maxHeaderHeight ) { 
          $maxHeaderHeight = length($skelCursor{'FTAB'}->{NAME}->[$i]);
        }
      }
    }
    # put out the header lines .... loop through then and break vertical headers
    for ( my $i=0; $i<$num_of_fields; $i++ ) { 
      if ( defined($vertHeader{$i}) ) { # this header is vertical  
        # insert a break between every chracter
        $tmpHeader = $skelCursor{'FTAB'}->{NAME}->[$i];
        $tmpHeader = substr(' ' x $maxHeaderHeight . $tmpHeader, -$maxHeaderHeight, $maxHeaderHeight);
        $tmpHeader =~ s/(.)/$1<BR>/g;
        $tmpHeader =~ s/<BR>$//g;
        $tStr .= "<th>$tmpHeader</th>";
      }
      else { # horizontal header
        $tStr .= '<th>' . $skelCursor{'FTAB'}->{NAME}->[$i] . '</th>';
      }
    }
    $tStr .= "</tr>\n";
    $FTAB_output_len += length($tStr);
  }
  else { # text output ....
    $tStr = '';
    # loop through the returned columns and generate the headers
    # Calculate the longest vertical header (note %vertHeaders contains which are vertical)
    $maxHeaderHeight = 1;
    for ( my $i=0; $i<$num_of_fields; $i++ ) { 
      if ( defined($vertHeader{$i}) ) { # this header is vertical  
        if ( length($skelCursor{'FTAB'}->{NAME}->[$i]) > $maxHeaderHeight ) { 
          $maxHeaderHeight = length($skelCursor{'FTAB'}->{NAME}->[$i]);
        }
      }
    }
    # we now have how many lines of header that need to be generated $maxHeaderLength
    # put out the header lines .... loop through 
    for ( my $j = 0 ; $j < $maxHeaderHeight; $j++ ) { # loop the number of header lines there are
      for ( my $i=0; $i<$num_of_fields; $i++ ) { 
        if ( defined($vertHeader{$i}) ) { # this header is vertical  
          # print off the character at this line
          $offset = $maxHeaderHeight - length($skelCursor{'FTAB'}->{NAME}->[$i]);
          if ( $offset >= $i ) { # characters to print
            $tStr .= "!". substr($skelCursor{'FTAB'}->{NAME}->[$i],$i - $offset,1);
          }
        }
        else { # horizontal header
          if ( $j == $maxHeaderHeight - 1 ) { # last line
            $tStr .= "!" . $skelCursor{'FTAB'}->{NAME}->[$i]
          }
        }
      }
      $tStr .= "\n"; # end the line
    }
    $tStr .= "\n";
  }

  outputLine($tStr);

} # end of processHeading

sub checkCellStyleSetting {
  # -----------------------------------------------------------
  # Routine to check out if any special style should be invoked for this row
  #
  # Usage: checkStyleSetting()
  # Returns: will return the applicable styl;e of a null string
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'checkCellStyleSetting';
  my $substitutedTest = '';
  my $column = shift;
  
  if ( ! keys %cellStyle ) { return '' } ; # if no tests at all then just return
  
  if ( ! exists $cellStyle{$column} ) { # no styles defined for that column
    return '';
  }
  
  foreach my $key (sort by_key keys %{ $cellStyle{$column} } ) {
    my $test = substr($key,3);        # strip off the sequence number
    $substitutedTest = substituteVariables($test);
    displayDebug("Checking condition '$substitutedTest'",1,$currentSubroutine);
    
    if ( evaluateCondition($substitutedTest) ) { # condition was true  
      displayDebug("Condition true. Setting style $cellStyle{$column}{$key}",1,$currentSubroutine);
      return ' style="' . $cellStyle{$column}{$key} . '" ';
    }
  }
  
  return '';   # if nothing found return an empty string
  
} # end of checkCellStyleSetting

sub checkRowStyleSetting {
  # -----------------------------------------------------------
  # Routine to check out if any special style should be invoked for this row
  #
  # Usage: checkStyleSetting()
  # Returns: will return the applicable styl;e of a null string
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'checkRowStyleSetting';
  my $substitutedTest = '';
  
  if ( ! keys %rowStyle ) { return '' } ; # if no tests then just return
  
  foreach my $key ( sort by_key keys %rowStyle ) {  # for each test ....
    my $test = substr($key,3);        # strip off the sequence number
    $substitutedTest = substituteVariables($test);
    displayDebug("Checking condition '$substitutedTest' (key: $key)",1,$currentSubroutine);

    if ( evaluateCondition($substitutedTest) ) { # condition was true  
      displayDebug("Condition true. Setting style $rowStyle{$key}",1,$currentSubroutine);
      return ' style="' . $rowStyle{$key} . '" ' ;
    }
  }
  
  return '';   # if nothing found return an empty string
  
} # end of checkRowStyleSetting

sub processFTAB {
  # -----------------------------------------------------------
  # Routine to print out a formatted dump of a returned SQL query 
  #
  # The FTAB control statement looks like )FTAB <DB Ref> <SQL Statement>
  #
  # Usage: processFTAB(<control Card>)
  # Returns: nothing but will print out a horizontally formatted dump of a table
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processFTAB';
  my $num_of_fields = 0;                                       # field containing the number of columns returned
  my $tStr = "";                                               # this string will hold the generated output line
  my $skelTabValue = '';                                       # value of the column

  my $card = shift;                                            # get the card information
  my $DBConnectionRef = getToken($card);                       # (CONNREF) this is the database ref that a )LOGON should have created
  my $SQL = trim(substr($card,$currentLinePosition));          # (SQL Statement) SQL to be used
  
  $FTAB_output_len = 0;                                        # note that the count needs to be kept in the routine as it is only for FTAB generated output

  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      
      setVariable('LASTFTABCount','0');                            # Initialise the count in case of failure
      if ( uc($SQL) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                         # does the sql start with either SQL: or FILE: or SQL= or FILE=
        $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
      }
      elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
        $SQL = loadInlineCards($currentSubroutine);                                # load the SQL
      }
      
      $cursorSQL{'FTAB'} = $SQL;                               # set up the SQL

      if ( ! defined($skelConnection{$DBConnectionRef}) ) { # A )LOGON hasn't created the database connection yet - fail this statement
        displayError("A previous )LOGON statement has not created a database connection for $DBConnectionRef\nThis )FTAB will be ignored",$currentSubroutine);
      }
      else {
        # now process the open
        if ( establishCursor( $DBConnectionRef, 'FTAB' ) ) {     # returns 1 if all is ok (and attempts to read the first row)
        
          if ( $cursorRowNumber{'FTAB'} == 0 ) {                 # no rows returned (should be 1 at this point)
            displayDebug("Call to SQL returned 0 rows",2,$currentSubroutine);
            outputLine("No Data Returned"); 
          }
          else { # a row was returned
            displayDebug("Rows returned",2,$currentSubroutine);
            $num_of_fields = $skelCursor{'FTAB'}->{NUM_OF_FIELDS};
            displayDebug("Number of fields = $num_of_fields\n",2,$currentSubroutine);
            
            # Write out headings ......
            
            processHeading($num_of_fields);
          
            # write out the data .....
          
            displayDebug("About to enter row loop",2,$currentSubroutine);
            my $moreToProcess = 1;                              # initialise the stop flag
            my $indexTarget = '';
          
            while ( $moreToProcess ) {                          # A value of 1 indicates data was returned
              displayDebug("In cursor loop",2,$currentSubroutine);
              my $fType = $skelCursor{'FTAB'}->{TYPE}->[$indexEntry]; # $fieldType is now the field type (CHAR, VARCHAR etc)
              displayDebug("fType: $fType",1,$currentSubroutine);
              $indexTarget = checkForIndexReq(getTabValue($fType, ${$skelCursorRow{'FTAB'}}[$indexEntry], 'FTAB',  $indexEntry));   # pass field type and the field across
              displayDebug("indexTarget: $indexTarget: $fType",1,$currentSubroutine);
              $tStr = "";                                       # Initialise the output line 
              if ( $outputMode eq "HTTP" ) {                    # output it as a html table
                $currentRowStyle = checkRowStyleSetting();      # see what style should be used
                $tStr = "<tr $currentRowStyle>";    # set new table row tag
                $FTAB_output_len += length($tStr);
              }
              for ( my $i=0; $i<$num_of_fields; $i++ ) {
                if ( $i == 1 ) { $indexTarget = ''; }           # only put an index target in once
                my $fieldType = $skelCursor{'FTAB'}->{TYPE}->[$i]; # $fieldType is now the field type (CHAR, VARCHAR etc)
                
                $skelTabValue = ${$skelCursorRow{'FTAB'}}[$i];
                if ( defined($skelTabValue) ) { 
                  displayDebug("Column $i has a type of $fieldType and a value of $skelTabValue\n",2,$currentSubroutine);
                }
                else {
                  displayDebug("Column $i has a type of $fieldType and has no value\n",2,$currentSubroutine);
                }
                
                # check if special styling is required for this cell
                $currentCellStyle = '';                           # reset this for every cell
                if ( $outputMode eq "HTTP" ) {                    # output it as a html table
                  $currentCellStyle = checkCellStyleSetting($skelCursor{'FTAB'}->{NAME}->[$i]);      # see what style should be used
                }
  
                $skelTabValue = getTabValue($fieldType, ${$skelCursorRow{'FTAB'}}[$i], 'FTAB',  $i);   # pass field type and the field across
  
                if ( $outputMode eq "HTTP" ) {                          # output it as a html table cell
                  if ( isNumeric($fieldType) ) { # field type is a numeric (DB2 field types are numeric)
                    if ( $numericFieldTypes =~ $fieldType ) { # right align numeric fields
                      $tStr .= "<td $currentCellStyle align=\"right\">" . $indexTarget . $skelTabValue . "</td> ";
                    }
                    else { # character field ... just normal left alignment
                      $tStr .= "<td $currentCellStyle>" . $indexTarget . $skelTabValue . "</td> ";
                    }
                  }
                  else { # the field types are not numeric (SQLite uses character strings)
                    if ( $fieldType eq "NUMERIC" ) { # right align numeric fields
                      $tStr .= "<td $currentCellStyle align=\"right\">" . $indexTarget . $skelTabValue . "</td> ";
                    }
                    else { # dont right align the value ... just normal left alignment
                      $tStr .= "<td $currentCellStyle>" . $indexTarget . $skelTabValue . "</td> "; 
                    }
                  }
                }
                else { # just write it out to normal output ($outputMode is not HTTP)
                    $tStr .= "!" . $skelTabValue;
                }
              }
              if ( $outputMode eq "HTTP" ) {  # output it as a html table
                outputLine("$tStr</tr>\n");
                $FTAB_output_len += length("$tStr</tr>\n");
              }
              else {
                outputLine("$tStr");
              }

              if ( $FTAB_output_len > $skelMaxTableOut ) { # check to see if we have broken the output limit for tables
                outputLine("<BR><BR><b>Not All data returned</b> - Table output limited to $skelMaxTableOut characters<BR><BR>\n");
                last; # finish the data collection
              }

              if ( $cursorRowNumber{'FTAB'} >= $skelMaxRows ) { 
                outputLine("<BR><BR><b>Not All data returned</b> - Table output limited to $skelMaxRows rows<BR><BR>\n");
                last; # finish the data collection
              }

              # move on to the next row now .....
            
              $moreToProcess = getNextRecord('FTAB'); # 1 is returned if more data to process, 0 if at end of cursor

            } # end of while loop 
          
            # no more data
            if ( $outputMode eq "HTTP" ) {            # output it as a html table
              outputLine("</table>\n");         # terminate the HTML table
            }
            setVariable('LASTFTABCount',$cursorRowNumber{'FTAB'}); 
            closeCursor('FTAB');                # close the FTAB cursor
          }
        }
        else { # Problems in river city - open cursor failed
          if ( $skelVerboseSQLErrors eq 'Yes' ) {
            if ( $SQLError ) { # SQL Error (not just no rows found)
              displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SQL",$currentSubroutine);
            }
            else {
              displayError("No Rows Found for SQL: \n $SQL",$currentSubroutine);
            }
          }
          else { # not verbose - dont mention it if no rows found and if SQL error dont print SQL
            if ( $SQLError ) { # SQL Error (not just no rows found)
              displayError("Call to SQL failed - will pretend no records found\n",$currentSubroutine);
            }
          }
        }
        displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processFTAB

sub processFXTAB {
  # -----------------------------------------------------------
  # Routine to print out a formatted cross tabulation of the returned data 
  #
  # The FXTAB control statement looks like )FVTAB <DB Ref> [action] <SQL Statement>
  #
  # Action basically defines how the crosstabulated data will be handled. It is either
  #
  #     1. SUM, AVG, MIN, MAX or CNT
  #     2. MRK:XY  (where X and Y are the characters to be used to indicate a value or (0 or NULL ) respoectively)
  #     3. CHK:<target CGI script>
  #
  # The SQL Statement should return 3 columns.
  #
  # The first column returns the heading under which the data should be displayed
  # The second column returns the row label against which this data should be displayed
  # The third column returns the data to be cross tabulated
  #
  # Usage: processFXTAB(<control Card>)
  # Returns: nothing but will print out a cross tabulated version of the returned data
  #         
  # Note: Maily useful for small amounts of data 
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processFXTAB';
  my $num_of_fields = 0;                                       # field containing the number of columns returned
  my $tStr = "";                                               # this string will hold the generated output line
  my $skelTabValue = '';                                       # value of the column

  my $card = shift;                                            # get the card information
  my $DBConnectionRef = getToken($card);                       # (CONNREF) this is the database ref that a )LOGON should have created
  my $SQL = trim(substr($card,$currentLinePosition));          # (SQL Statement) SQL to be used
  my $actionType = 'SUM';                                      # defines how duplicates will be handled
  my $MRKEntry = 'X';
  my $MRKEmpty = ' ';
  
  my %colData = ();                                            # initialise the array to hold the table data
  my %colDataCount = ();                                       # array to old the count of the number of entries
  my %revColData = ();                                         # initialise the reverse array
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      
      setVariable('LASTFXTABCount','0');                       # initialise variable
      # check to see if an action type has been set .....
      
      my @typeCheck = split(" ",$SQL);
      if ( " SUM AVG MIN MAX CNT " =~ uc($typeCheck[0]) ) { # if the first word in the string is a known action type
        $actionType = uc($typeCheck[0]);
        $SQL = trim(substr($SQL,length($typeCheck[0])));      # remove the action type from the SQL string
      }
      elsif ( uc(substr($SQL,0,3)) eq 'MRK' ) { # probably of the form MRK[:....] SELECT ......
        $actionType = 'MRK';
        if ( length($typeCheck[0]) == 5 ) { # one parameters
          $MRKEntry = substr($typeCheck[0],4,1);
          $MRKEmpty = ' ';
        }
        elsif ( length($typeCheck[0]) > 5 ) { # two parameters
          $MRKEntry = substr($typeCheck[0],4,1);
          $MRKEmpty = substr($typeCheck[0],5,1);
        }
        $SQL = trim(substr($SQL,length($typeCheck[0])));      # remove the action type from the SQL string
      }
      
      # load up the SQL if it is in a file
      
      if ( uc($SQL) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
        $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
      }
      elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
        $SQL = loadInlineCards($currentSubroutine);                                # load the SQL
      }
      
      $cursorSQL{'FXTAB'} = $SQL;                               # set up the SQL

      if ( ! defined($skelConnection{$DBConnectionRef}) ) { # A )LOGON hasn't created the database connection yet - fail this statement
        displayError("A previous )LOGON statement has not created a database connection for $DBConnectionRef\nThis )FXTAB will be ignored",$currentSubroutine);
      }
      else {
        # now process the open
        if ( establishCursor( $DBConnectionRef, 'FXTAB' ) ) {     # returns 1 if all is ok (and attempts to read the first row)
      
          if ( $cursorRowNumber{'FXTAB'} == 0 ) {                 # no rows returned (should be 1 at this point)
            displayDebug("Call to SQL returned 0 rows",2,$currentSubroutine);
            outputLine("No Data Returned"); 
          }
          else { # a row was returned
            displayDebug("Rows returned",2,$currentSubroutine);
            $num_of_fields = $skelCursor{'FXTAB'}->{NUM_OF_FIELDS};   # establish the number of columns returned
            displayDebug("Number of fields = $num_of_fields\n",2,$currentSubroutine);
          
            if ( $num_of_fields < 3 ) { # must have at least 3 returned columns
              displayError("Supplied SQL only returns $num_of_fields columns - must have at least 3",$currentSubroutine);
            }  
            else {
          
              # write out the data .....
           
              displayDebug("About to enter row loop",2,$currentSubroutine);
              my $moreToProcess = 1;                              # initialise the stop flag
          
              while ( $moreToProcess ) {                          # A value of 1 indicates data was returned
                my $val0 = '';
                my $val1 = '';
                my $val2 = '';
                displayDebug("In cursor loop",2,$currentSubroutine);
                my $fieldType = $skelCursor{'FXTAB'}->{TYPE}->[0]; # $fieldType is now the field type (CHAR, VARCHAR etc)
                $val0 = getTabValue($fieldType, ${$skelCursorRow{'FXTAB'}}[0], 'FXTAB',  0);   # pass field type and the field across
                $fieldType = $skelCursor{'FXTAB'}->{TYPE}->[1]; # $fieldType is now the field type (CHAR, VARCHAR etc)
                $val1 = getTabValue($fieldType, ${$skelCursorRow{'FXTAB'}}[1], 'FXTAB',  1);   # pass field type and the field across
                $fieldType = $skelCursor{'FXTAB'}->{TYPE}->[2]; # $fieldType is now the field type (CHAR, VARCHAR etc)
                $val2 = getTabValue($fieldType, ${$skelCursorRow{'FXTAB'}}[2], 'FXTAB',  2);   # pass field type and the field across
              
                if ( defined( $colData {$val0} { $val1} )) { 
                  $colDataCount {$val0} { $val1} ++;
                  if ($actionType eq 'SUM') { # add in a reourrance ......
                    $colData {$val0} { $val1} += $val2;
                  }
                  elsif ($actionType eq 'CNT') { # just count the entries .....
                    $colData {$val0} { $val1} ++;
                  }
                  elsif ($actionType eq 'AVG') { # just count the entries .....
                    my $tmp_avg = ($colData {$val0} { $val1}) * ( $colDataCount {$val0} { $val1} - 1); # establish the total value
                    $tmp_avg += $val2 ;
                    $colData {$val0} { $val1} = $tmp_avg / ($colDataCount {$val0} { $val1});
                  }
                  elsif ($actionType eq 'MIN') { # just count the entries .....
                    if ( $colData {$val0} { $val1} > $val2 ) { # new value is smaller so remember it
                      $colData {$val0} { $val1} = $val2;
                    }
                  }
                  elsif ($actionType eq 'MAX') { # just count the entries .....
                    if ( $colData {$val0} { $val1} < $val2 ) { # new value is larger so remember it
                      $colData {$val0} { $val1} = $val2;
                    }
                  }
                }
                else {
                  $colDataCount {$val0} { $val1} = 1;
                  if ($actionType eq 'CNT') { # just count the entries .....
                    $colData {$val0} { $val1} = 1;
                  }
                  else { # all others initialise with the value
                  $colData {$val0} { $val1} = $val2;
                  }
                }
            
                # move on to the next row now .....
                $moreToProcess = getNextRecord('FXTAB'); # 1 is returned if more data to process, 0 if at end of cursor

              } # end of while loop 
            }
          
            # no more data - now just output it all
          
            if ( $outputMode eq "HTTP" ) {  # output it as a html table
              $FTABNumber++;
              outputLine("<table border=\"1\" id=\"FTAB$FTABNumber\"><tr><td></td>\n");
              foreach my $key1 ( sort keys %colData ) {
              outputLine("<th>$key1</th>");
                foreach my $key2 (keys %{ $colData {$key1}} ) {
                  $revColData {$key2} { $key1} = $colData {$key1} {$key2};
                }
              }     
              outputLine("</tr>\n");
            
              # heading now output so now dump the data .....
              
              foreach my $rowKey ( sort keys %revColData ) { # for each row element
                outputLine("<tr><td>$rowKey</td>\n");
                foreach my $headKey ( sort keys %colData ) { # loop through available columns
                  if ( defined ($revColData {$rowKey} {$headKey} ) ) { # element exists
                    my $tmpRCD = $revColData {$rowKey} {$headKey};
                    if ( $actionType eq 'MRK' ) { 
                      outputLine("<td>$MRKEntry</td>");
                    }
                    else {
                      outputLine("<td>$tmpRCD</td>");
                    }
                  }
                  else { # element doesn't existA
                    if ( $actionType eq 'MRK' ) { 
                      outputLine("<td>$MRKEmpty</td>");
                    }
                    else {
                      outputLine("<td>-</td>");
                    }
                  }
                }
                outputLine("</tr>\n");
              }
              
              outputLine("</table>\n");
            }
            else { # just put out data to the terminal
              my $a =  Dumper \%colData;
              displayDebug($a,2,$currentSubroutine);
              my $outLine = '!';
              outputLine("");
              foreach my $key1 ( sort keys %colData ) {
                $outLine .= "\!$key1";
                foreach my $key2 (keys %{ $colData {$key1}} ) {
                  $revColData {$key2} { $key1} = $colData {$key1} {$key2};
                }
              }
              outputLine("$outLine");

              # heading now output so now dump the data .....
              $a = Dumper \%revColData;
              displayDebug($a,2,$currentSubroutine);
              $outLine = '';

              foreach my $rowKey ( sort keys %revColData ) { # for each row element
                $outLine .= "$rowKey";
                foreach my $headKey ( sort keys %colData ) { # loop through available columns
                  if ( defined ($revColData {$rowKey} {$headKey} ) ) { # element exists
                    my $tmpRCD = $revColData {$rowKey} {$headKey};
                    $outLine .= "\!$tmpRCD";
                  }
                  else { # element doesn't existA
                    $outLine .= "\!-";
                  }
                }
                outputLine("$outLine");
                $outLine = '';     #initialise the output line
              }
            }
            setVariable('LASTFXTABCount',$cursorRowNumber{'FXTAB'});
            closeCursor('FXTAB');                # close the FXTAB cursor
          }
        }
        else { # Problems in river city - open cursor failed
          if ( $skelVerboseSQLErrors eq 'Yes' ) {
            if ( $SQLError ) { # SQL Error (not just no rows found)
              displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SQL",$currentSubroutine);
            }
            else {
              displayError("No Rows Found for SQL:\n $SQL",$currentSubroutine);
            }
          }
          else { # not verbose - dont mention it if no rows found and if SQL error dont print SQL
            if ( $SQLError ) { # SQL Error (not just no rows found)
              displayError("Call to SQL failed - will pretend no records found\n",$currentSubroutine);
            }
          }
        }
        displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processFXTAB

sub processDOCMD {
  # -----------------------------------------------------------
  # Routine to execute a command to the DBI module - INSERT, UPDATE, DELETE
  #
  # The DOCMD control statement looks like )DOCMD <DB Ref> <SQL Statement>
  #
  # The SQLStatement will be executed against the indicated database connection
  # 
  # By default the command will only process INSERT, DELETE and UPDATE statements
  # but this can be varied through use of the exported DOCMD_allowedStatements variable
  #
  # Usage: processDOCMD(<control Card>)
  # Returns: the number of rows affected (undefined if there is an error)
  #         
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processDOCMD';
  my $num_of_rows_affected = 0;                                # field containing the number of columns returned
  my $tStr = "";                                               # this string will hold the generated output line
  my $skelTabValue = '';                                       # value of the column

  my $card = shift;                                            # get the card information
  my $DBConnectionRef = getToken($card);                       # (CONNREF) this is the database ref that a )LOGON should have created
  my $SQL = trim(substr($card,$currentLinePosition));          # (SQL Statement) SQL to be used
  
  my $actionType = '';
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
    
      setVariable('rowsAffected',0);                           # reset the internal variable
      
      if ( uc($SQL) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
        $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
      }
      elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
        $SQL = loadInlineCards($currentSubroutine);             # load the SQL
      }
      
      # check to see if an action type has been set .....
      
      my @typeCheck = split(" ",$SQL);
      if ( $DOCMD_allowedStatements =~ uc($typeCheck[0]) ) { # if the first word in the string is a known action type
        $actionType = uc($typeCheck[0]);
      }
      else {
        displayError("Only INSERT, UPDATE and DELETE are currently supported by )DOCMD. Card found: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",$currentSubroutine);
        return;
      }
      
      $cursorSQL{'DOCMD'} = $SQL;                               # set up the SQL

      if ( ! defined($skelConnection{$DBConnectionRef}) ) { # A )LOGON hasn't created the database connection yet - fail this statement
        my $tmpLine = $currentSkelLine +1;
        displayError("A previous )LOGON statement has not created a database connection for $DBConnectionRef\nThis )DOCMD will be ignored",$currentSubroutine);
      }
      else {
        # now process the open
        $num_of_rows_affected = establishCursor_NoReturnedRows( $DBConnectionRef, 'DOCMD' );
        if ( defined ( $num_of_rows_affected ) ) {     # if $rows is defined then the statement ran ok
          displayDebug("Rows returned: $num_of_rows_affected",2,$currentSubroutine);
          setVariable('rowsAffected',$num_of_rows_affected);                # set the internal variable
        }
        else { # Problems in river city - open cursor failed
          if ( $skelVerboseSQLErrors eq 'Yes' ) {
            displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SQL",$currentSubroutine);
          }
          else { # not verbose - dont mention it if no rows found and if SQL error dont print SQL
            displayError("Call to SQL failed - will pretend no records found\n",$currentSubroutine);
          }
        }
        displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processDOCMD

sub processFVTAB {
  # -----------------------------------------------------------
  # Routine to print out a formatted dump of a returned SQL query 
  #
  # The FVTAB control statement looks like )FVTAB <DB Ref> <SQL Statement>
  #
  # Usage: processFVTAB(<control Card>)
  # Returns: nothing but will print out a vertically formatted dump of a table
  #          mainly of use when only printing one row
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processFVTAB';
  my $num_of_fields = 0;                                       # field containing the number of columns returned
  my $tStr = "";                                               # this string will hold the generated output line
  my $skelTabValue = '';                                       # value of the column

  my $card = shift;                                            # get the card information
  my $DBConnectionRef = getToken($card);                       # (CONNREF) this is the database ref that a )LOGON should have created
  my $SQL = trim(substr($card,$currentLinePosition));          # (SQL Statement) SQL to be used
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      
      setVariable('LASTFVTABCount','0');                       # initialise variable
      if ( uc($SQL) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
        $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
      }
      elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
        $SQL = loadInlineCards($currentSubroutine);             # load the SQL
      }
      
      $cursorSQL{'FVTAB'} = $SQL;                               # set up the SQL

      if ( ! defined($skelConnection{$DBConnectionRef}) ) { # A )LOGON hasn't created the database connection yet - fail this statement
        displayError("A previous )LOGON statement has not created a database connection for $DBConnectionRef\nThis )FTAB will be ignored",$currentSubroutine);
      }
      else {
        # now process the open
        if ( establishCursor( $DBConnectionRef, 'FVTAB' ) ) {     # returns 1 if all is ok (and attempts to read the first row)
        
          if ( $cursorRowNumber{'FVTAB'} == 0 ) {                 # no rows returned (should be 1 at this point)
            displayDebug("Call to SQL returned 0 rows",2,$currentSubroutine);
            outputLine("No Data Returned"); 
          }
          else { # a row was returned
            displayDebug("Rows returned",2,$currentSubroutine);
            $num_of_fields = $skelCursor{'FVTAB'}->{NUM_OF_FIELDS};   # establish the number of columns returned
            displayDebug("Number of fields = $num_of_fields\n",2,$currentSubroutine);
          
            # write out the data .....
          
            displayDebug("About to enter row loop",2,$currentSubroutine);
            my $moreToProcess = 1;                              # initialise the stop flag
          
            while ( $moreToProcess ) {                          # A value of 1 indicates data was returned
              displayDebug("In cursor loop",2,$currentSubroutine);
              $tStr = "";                                       # Initialise the output line 
              if ( $outputMode eq "HTTP" ) {                    # output it as a html table
                $FTABNumber++;
                outputLine("<table border=\"1\" id=\"FTAB$FTABNumber\"><tr>");        # set new table row tag
              }
              for ( my $i=0; $i<$num_of_fields; $i++ ) {
                my $fieldType = $skelCursor{'FVTAB'}->{TYPE}->[$i]; # $fieldType is now the field type (CHAR, VARCHAR etc)
                $skelTabValue = "";
                $skelTabValue = getTabValue($fieldType, ${$skelCursorRow{'FVTAB'}}[$i], 'FVTAB',  $i);   # pass field type and the field across
  
                if ( $outputMode eq "HTTP" ) {                          # output it as a html table cell
                    outputLine("<tr><td>" . $skelCursor{'FVTAB'}->{NAME}->[$i] . "</td><td>" . $skelTabValue . "</td></tr>");
                }
                else { # character field ... just normal left alignment
                  outputLine("!" . $skelCursor{'FVTAB'}->{NAME}->[$i] . " !" . $skelTabValue);
                }
              } # end of for loop processing columns
              
              # move on to the next row now .....
            
              $moreToProcess = getNextRecord('FVTAB'); # 1 is returned if more data to process, 0 if at end of cursor

            } # end of while loop 
          
            # no more data
            if ( $outputMode eq "HTTP" ) {  # output it as a html table
              outputLine("</table>\n");
            }
            setVariable('LASTFVTABCount',$cursorRowNumber{'FVTAB'});
            closeCursor('FVTAB');                # close the FVTAB cursor
          }
        }
        else { # Problems in river city - open cursor failed
          if ( $skelVerboseSQLErrors eq 'Yes' ) {
            if ( $SQLError ) { # SQL Error (not just no rows found)
              displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SQL",$currentSubroutine);
            }
            else {
              displayError("No Rows Found for SQL:\n $SQL",$currentSubroutine);
            }
          }
          else { # not verbose - dont mention it if no rows found and if SQL error dont print SQL
            if ( $SQLError ) { # SQL Error (not just no rows found)
              displayError("Call to SQL failed - will pretend no records found\n",$currentSubroutine);
            }
          }
        }
        displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processFVTAB

sub processDOSEL {
  # -----------------------------------------------------------
  # Routine to populateinternal variables with values from a SQL statement
  #
  # The DOSEL control statement looks like )DOSEL <DB Ref> <Var Qualifier> <SQL Statement>
  #
  # Usage: processDOSEL(<control Card>)
  # Returns: nothing but will update various internal variables as 
  #          indicated by the SQL being executed
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processDOSEL';
  my $num_of_fields = 0;                                       # field containing the number of columns returned
  my $skelTabValue = '';                                       # value of the column

  my $card = shift;                                            # get the card information
  my $DBConnectionRef = getToken($card);                       # (CONNREF) this is the database ref that a )LOGON should have created
  my $varQualifier = getToken($card);                          # (VARQUAL) this value will be prefixed to the returned column names (if NONE specified then 
                                                               # variable name wont be qualified
  my $SQL = trim(substr($card,$currentLinePosition));          # (SQL Statement) SQL to be used
  
  if ( $skelSelSkipCards eq "No" ) {                           # not skipping cards because of a failed )SEL
    if ( $skelDOTSkipCards eq "No" ) {                         # Not within a )DOT being skipped
      
      if ( uc($SQL) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
        $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
      }
      elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
        $SQL = loadInlineCards($currentSubroutine);             # load the SQL
      }

      $cursorSQL{'DOSEL'} = $SQL;                               # set up the SQL

      if ( ! defined($skelConnection{$DBConnectionRef}) ) { # A )LOGON hasn't created the database connection yet - fail this statement
        displayError("A previous )LOGON statement has not created a database connection for $DBConnectionRef\nThis )DOSEL will be ignored",$currentSubroutine);
      }
      else {
        # now process the open
        if ( establishCursor( $DBConnectionRef, 'DOSEL' ) ) {     # returns 1 if all is ok (and attempts to read the first row)
        
          if ( $cursorRowNumber{'DOSEL'} == 0 ) {                 # no rows returned (should be 1 at this point)
            displayDebug("Call to SQL returned 0 rows",2,$currentSubroutine);
            outputLine("No Data Returned"); 
          }
          else { # a row was returned
            displayDebug("Rows returned",2,$currentSubroutine);
            $num_of_fields = $skelCursor{'DOSEL'}->{NUM_OF_FIELDS};   # establish the number of columns returned
            displayDebug("Number of fields = $num_of_fields\n",2,$currentSubroutine);
            
            if ( uc($varQualifier) eq 'NONE' ) { $varQualifier = ''; } # if NONE is specified then dont qualifier the variable names
            else { $varQualifier .= '_'; }                            # construct the qualifier
          
            # write out the data .....
          
            displayDebug("Reading from Cursor",2,$currentSubroutine);
            for ( my $i=0; $i<$num_of_fields; $i++ ) { # loop through the columns returned
              my $fieldType = $skelCursor{'DOSEL'}->{TYPE}->[$i]; # $fieldType is now the field type (CHAR, VARCHAR etc)
              displayDebug("Field number $i ($skelCursor{'DOSEL'}->{NAME}->[$i]) has a field type of $fieldType",2,$currentSubroutine);
              $skelTabValue = "";
              $skelTabValue = getTabValue($fieldType, ${$skelCursorRow{'DOSEL'}}[$i], 'FVTAB',  $i);   # pass field type and the field across
              
              displayDebug("Assigning variable $varQualifier$skelCursor{'DOSEL'}->{NAME}->[$i] the value of $skelTabValue",2,$currentSubroutine);
              setVariable("$varQualifier$skelCursor{'DOSEL'}->{NAME}->[$i]", $skelTabValue);
  
            } # end of for loop processing columns
            
            # only read the first row - discard all other data  
            
            closeCursor('DOSEL');                # close the FVTAB cursor
          }
        }
        else { # Problems in river city - open cursor failed
          if ( $skelVerboseSQLErrors eq 'Yes' ) {
            if ( $SQLError ) { # SQL Error (not just no rows found)
              displayError("Call to SQL failed - will pretend no records found\nSQL in error: $SQL",$currentSubroutine);
            }
            else {
              displayError("No Rows Found for SQL:\n $SQL",$currentSubroutine);
            }
          }
          else { # not verbose - dont mention it if no rows found and if SQL error dont print SQL
            if ( $SQLError ) { # SQL Error (not just no rows found)
              displayError("Call to SQL failed - will pretend no records found\n",$currentSubroutine);
            }
          }
        }
        displayDebug("Processed: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
      }
    }
    else { # Skipped because within a failed or empty  )DOT
      displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
    }
  }
  else { # Skipped because within a failed )SEL
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processDOSEL

sub processCHECKFORROW {
  # -----------------------------------------------------------
  # Routine to check if the supplied SQL will return a row
  #
  # Usage: processCHECKFORROW(<control Card>)
  # Returns: 1 if rows found and 0 for no rows or error
  # -----------------------------------------------------------  
  
  my $currentSubroutine = 'processCHECKFORROWS';
  my $skelTabValue = '';                                       # value of the column

  my $DBConnectionRef = shift;                                 # (CONNREF) this is the database ref that a )LOGON should have created
  my $SQL = shift;                                             # (SQL Statement) SQL to be used
  
  if ( uc($SQL) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
    $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
  }
  elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
    $SQL = loadInlineCards($currentSubroutine);             # load the SQL
  }
      
  $cursorSQL{'CHECKFORROWS'} = $SQL;                               # set up the SQL

  if ( ! defined($skelConnection{$DBConnectionRef}) ) { # A )LOGON hasn't created the database connection yet - fail this statement
  foreach my $tmpX (keys %skelConnection ) { print STDERR "Connection for $tmpX exists\n"; }
    displayError("A previous )LOGON statement has not created a database connection for '$DBConnectionRef'\nThis test will return 0",$currentSubroutine);
  }
  else {
    # now process the open
    if ( establishCursor( $DBConnectionRef, 'CHECKFORROWS' ) ) {     # returns 1 if all is ok (and attempts to read the first row)
        
      if ( $cursorRowNumber{'CHECKFORROWS'} == 0 ) {                 # no rows returned (should be 1 at this point)
        displayDebug("Call to SQL returned 0 rows",2,$currentSubroutine);
      }
      else { # a row was returned
        displayDebug("Rows returned",2,$currentSubroutine);
        return 1;
      }
      closeCursor('CHECKFORROWS');
    }
  }
  return 0;
} # end of processCHECKFORROW

sub processRESETOUTPUT { 
  # -----------------------------------------------------------
  # Routine to process the )RESETOUTPUT card
  # a )RESETOUTPUT card clears any saved output
  #
  # Usage: processRESETOUTPUT(<message>)
  # Returns: modifies the current saved output
  # -----------------------------------------------------------

  my $message = shift;             # will hold card type (not the full input card)
  my $currentSubroutine = 'processRESETOUTPUT';
  my $tempLine = '';

  if ( ( $skelSelSkipCards eq "No" ) ) { # not excluded because of a failed )SEL
    if ( ( $skelDOTSkipCards eq "No" ) ) { # not excluded because of a )DOT that returned zero rows
    
      # sort out any message ....
      if ( defined($message) && ( trim($message) ne '' ) ) { # something has been put on the )RESETOUTPUT Card
        $skelReturnString = $message;
      }
      else {  # nothing on the card so just get rid of the output
        $skelReturnString = '';
      }
    }  
  }
    
} # end of processRESETOUTPUT

sub processSTOP { 
  # -----------------------------------------------------------
  # Routine to process the )STOP card
  # a )STOP card terminates the skeleton now
  #
  # Usage: processSTOP(<control card>)
  # Returns: modifies the current card pointer in the skeleton
  # -----------------------------------------------------------

  my $card = shift;             # will hold card type (not the full input card)
  my $currentSubroutine = 'processSTOP';
  my $tempLine = '';

  if ( ( $skelSelSkipCards eq "No" ) ) { # not excluded because of a failed )SEL
    if ( ( $skelDOTSkipCards eq "No" ) ) { # not excluded because of a )DOT that returned zero rows
    
      my @cardParts = split(" ", $card,2);
      
      # sort out any message ....
      if ( defined($cardParts[1]) && ( trim($cardParts[1]) ne '' ) ) { # something has been put on the )STOP Card
        if ( substr($cardParts[1],0,1) ne '+' ) { # if the string doesn't start with a plus then clear all output
          $skelReturnString = '';
        }
        else {
          $cardParts[1] = substr($cardParts[1],1);    # lose the first character
        }
        
        $tempLine = substituteVariables($cardParts[1]); 
        displayDebug("Adding the )STOP comment to the output >$tempLine<",1,$currentSubroutine);
        outputLine($tempLine);
      }
  
      # check to see if we are in an imbed
      if ( $#imbedStack > -1 ) { # stuff on the stack to process
        while ( $#imbedStack > -1 ) { # more imbeds to discard
          # clear out the old variable sciope asnecessary 
          my $tempScope = pop(@scopeStack);
          clearVariableScope($currentScope);
          $currentScope = pop(@imbedStack);      # reset the variable scope 
          $currentSkelLine = pop(@imbedStack);   # holds the position in the skel of the imbed statement
          $currentActiveSkel = pop(@imbedStack); # holds the name of the new active skeleton
          displayDebug("Values pulled from imbedStack: \$currentSkelLine = $currentSkelLine, \$currentActiveSkel = $currentActiveSkel",1,$currentSubroutine);
          displayDebug(")STOP Continuing to process skeleton $currentActiveSkel",1,$currentSubroutine);
        }
        setVariable('currentSkeleton',$currentActiveSkel);         # set the currentSkeleton variable
      }
      # at this point the imbed stack is empty and currentActiveSkel should point to the initial skeleton
      $currentSkelLine = $#{$skelLines[$skelArray{$currentActiveSkel}]};     # set the current line to the last line of the skel 
      displayDebug("CurrentSkelLine set to $currentSkelLine",1,$currentSubroutine);
      $skelSELCount = 0;
      $skelDOTCount = 0;
    }
  }
    
} # end of processSTOP

sub processEXIT { 
  # -----------------------------------------------------------
  # Routine to process the )EXIT card
  # a )EXIT card terminates the current skeleton or IMBED (but only goes back 1 level)
  #
  # Usage: processEXIT(<control card>)
  # Returns: modifies the current card pointer in the skeleton
  # -----------------------------------------------------------

  my $card = shift;             # will hold card type (not the full input card)
  my $currentSubroutine = 'processEXIT';
  my $UC_cardType; 
  my @cardParts = ();

  if ( ( $skelSelSkipCards eq "No" ) ) { # not excluded because of a failed )SEL
    if ( ( $skelDOTSkipCards eq "No" ) ) { # not excluded because of a )DOT that returned zero rows

      # skip to the end of the skeleton adjusting counts as necessary  
      my $skelLine = $currentSkelLine++;    # point to the next line in the skeleton
      while ( defined($skelLines[$skelArray{$currentActiveSkel}][$skelLine]) ) { # while there are still lines in the array
        @cardParts = split(" ", $skelLines[$skelArray{$currentActiveSkel}][$skelLine]); # break the card into pieces
        $UC_cardType = 'NONESET';
        if ( defined($cardParts[0]) ) { 
          $UC_cardType = uc(trim($cardParts[0]));
        }
        if ( $UC_cardType eq ')ENDDOF' ) { # check to see if it the matching one
          $skelDOFCount--;            # adjust the DOF count
        }
        elsif ( $UC_cardType eq ')ENDDOT' ) { # check to see if it the matching one
          $skelDOTCount--;            # adjust the DOT count
        }
        elsif ( $UC_cardType eq ')ENDDOEXEC' ) { # check to see if it the matching one
          $skelDOEXECCount--;            # adjust the DOEXEC count
        }
        elsif ( $UC_cardType eq ')SEL' ) { # adjust the SEL count
          $skelSELCount++;
        }
        elsif ( $UC_cardType eq ')ENDSEL' ) { # adjust the SEL count
          $skelSELCount--;
        }
        elsif ( ($UC_cardType eq ')DOT') || ($UC_cardType eq ')XDOT') ) { # adjust the DOT count
          $skelDOTCount++;
        }
        elsif ( $UC_cardType eq ')DOF') { # adjust the DOF count
          $skelDOFCount++;
        }
        elsif ( $UC_cardType eq ')DOEXEC' ) { # adjust the DOEXEC count
          $skelDOEXECCount++;
        }
        $skelLine++;
      }
  
      # at the last line of the current skel - check to see if we are in an imbed
      if ( $#imbedStack > -1 ) { # stuff on the stack to process
        # clear out the old variable scope asnecessary
        my $tempScope = pop(@scopeStack);
        clearVariableScope($currentScope);
        $currentScope = pop(@imbedStack);      # reset the variable scope
        $currentSkelLine = pop(@imbedStack);   # holds the position in the skel of the imbed statement
        $currentSkelLine++;                    # move to line after )IMBED
        $currentActiveSkel = pop(@imbedStack); # holds the name of the new active skeleton
        displayDebug("Values pulled from imbedStack: \$currentSkelLine = $currentSkelLine, \$currentActiveSkel = $currentActiveSkel",1,$currentSubroutine);
        displayDebug(")EXIT Continuing to process skeleton $currentActiveSkel from line $currentSkelLine",1,$currentSubroutine);
        setVariable('currentSkeleton',$currentActiveSkel);         # set the currentSkeleton variable
      }
      else { # not an imbed so treat like )STOP
        # at this point the imbed stack will beempty and currentActiveSkel should point to the initial skeleton
        $currentSkelLine = $#{$skelLines[$skelArray{$currentActiveSkel}]};        # set to last line of skel
        displayDebug("CurrentSkelLine set to $currentSkelLine",1,$currentSubroutine);
      }
    }
  }
  
} # end of processEXIT

sub processFILE { 
  # -----------------------------------------------------------
  # Routine to process the )FILE card
  # a  )FILE card retrieves information about a file
  #
  # Usage: processFILE(<control card>)
  # Returns: nothign but sets a number of internal variables
  # -----------------------------------------------------------

  my $card = shift;             # will hold card type (not the full input card)
  my $currentSubroutine = 'processFILE';

  if ( ( $skelSelSkipCards eq "No" ) ) { # not excluded because of a failed )SEL
    if ( ( $skelDOTSkipCards eq "No" ) ) { # not excluded because of a )DOT that returned zero rows
    
      my $filename = getToken($card);       
      getFileInformation($filename, 'FILE');
    
    }
  }
  
} # end of processFILE

sub processLAST { 
  # -----------------------------------------------------------
  # Routine to process the )LAST or)LEAVE card
  # a )LEAVE card takes no parameters and will just skip to the next end loop card (ENDDOT, ENDDOF or ENDDOEXEC card
  #
  # Usage: processLAST(<control card>)
  # Returns: modifies the current card pointer in the skeleton
  # -----------------------------------------------------------

  my $card = shift;             # will hold card type (not the full input card)
  my $searchEnd = ' ';          # this contains the list of termination strings
  my $currentSubroutine = 'processLAST';

  my $lastValue = 1;
  if ( $card eq ')NEXT' ) { $lastValue = 0; }    # if it is next then dont exit the loop just jump to next iteration

  if ( ( $skelSelSkipCards eq "No" ) ) { # not excluded because of a failed )SEL
    if ( ( $skelDOTSkipCards eq "No" ) ) { # not excluded because of a )DOT that returned zero rows
      # all ok to be processed
      if ( defined ( $currentFileRef ) && ( $currentFileRef ne '' ) ) { # within an active )DOF
        $searchEnd .= ')ENDDOF ';
      }
      if ( defined ( $currentExecRef ) && ( $currentExecRef ne '' ) ) { # within an active )DOEXEC
        $searchEnd .= ')ENDDOEXEC ';
      }
      if ( defined ( $currentCursorConnection ) ) { # within an active )DOT
        $searchEnd .= ')ENDDOT ';
      }
      
      if ( $searchEnd eq ' ') { # not in any loop so just ignore the )LAST
        displayError("This $card card exists outside of a )DOF, )DOT, )XDOT or )DOEXEC loop.\nThis $card will be ignored",$currentSubroutine);
      }
      else {
        # remember the current state
        my $C_DoExecCount = $skelDOEXECCount;
        my $C_DOFCount = $skelDOFCount;
        my $C_DOTCount = $skelDOTCount;
        my $C_SelCount = $skelSELCount;
        # find the next termination card .....
        my $skelLine = $currentSkelLine++;   # start at the next card
        my @cardParts;
        my $UC_cardType;
        my $UC_cardType_srch;
    
        while ( defined($skelLines[$skelArray{$currentActiveSkel}][$skelLine]) ) { # while there are still lines in the array
          @cardParts = split(" ", $skelLines[$skelArray{$currentActiveSkel}][$skelLine]); # break the card into pieces
          $UC_cardType = 'NONESET';
          $UC_cardType_srch = 'NONESET';
          if ( defined($cardParts[0]) ) { 
            $UC_cardType = uc(trim($cardParts[0]));
            $UC_cardType_srch = $UC_cardType;
            $UC_cardType_srch =~ s/\)/\\\)/; # escape out the leading )
          }
          if ( "$searchEnd" =~ "$UC_cardType_srch" ) { # found a terminating card
            # create a condition to look like the end of the loop
            # print "skelDOFCount=$skelDOFCount, C_DOFCount=$C_DOFCount, UC_cardType=$UC_cardType<\n"; 
            if ( $UC_cardType eq ')ENDDOF' ) { # check to see if it the matching one
              if ( $skelDOFCount == $C_DOFCount ) { # is the matching )ENDDOF so set things up and skip to that card
                $lastFlagSet = $lastValue;             # set the value based on $card
                $currentSkelLine = $skelLine - 1;      # reset the current Line to the card before the terminating card
                # print "CurrentSkelLine changed to $currentSkelLine - $skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]\n";
                last;
              }
              else { # ignore the )END card as it isn't the right one
                $skelDOFCount--;            # adjust the DOF count
              }
            }
            elsif ( $UC_cardType eq ')ENDDOT' ) { # check to see if it the matching one
              if ( $skelDOTCount == $C_DOTCount ) { # is the matching )ENDDOT so set things up and skip to that card
                $lastFlagSet = $lastValue;             # set the value based on $card
                $currentSkelLine = $skelLine - 1;      # reset the current Line to the card before the terminating card
                last;
              }
              else { # ignore the )END card as it isn't the right one
                $skelDOTCount--;            # adjust the DOT count
              }
            }
            else { # check to see if it the matching )ENDDOEXEC
              if ( $skelDOEXECCount == $C_DoExecCount ) { # is the matching )ENDDOEXEC so set things up and skip to that card
                $lastFlagSet = $lastValue;             # set the value based on $card
                $currentSkelLine = $skelLine - 1;      # reset the current Line to the card before the terminating card
                last;
              }
              else { # ignore the )END card as it isn't the right one
                $skelDOEXECCount--;            # adjust the DOEXEC count
              }
            }
          } 
          elsif ( $UC_cardType eq ')SEL' ) { # adjust the SEL count
            $skelSELCount++;
          }
          elsif ( $UC_cardType eq ')ENDSEL' ) { # adjust the SEL count
            if ( $skelSELCount == $C_SelCount ) { # we have reached the)ENDSEL of a )SEL that we are currently in so we need to pop stuff off of the stack
              $skelSELCount--;
              verifyControlCounts();
            }
            else { # otherwise just keep the count going down
              $skelSELCount--;
            }
          }
          elsif ( ($UC_cardType eq ')DOT') || ($UC_cardType eq ')XDOT') ) { # adjust the DOT count
            $skelDOTCount++;
          }
          elsif ( $UC_cardType eq ')ENDDOT' ) { # adjust the DOT count
            $skelDOTCount--;
          }
          elsif ( $UC_cardType eq ')DOF') { # adjust the DOF count
            $skelDOFCount++;
          }
          elsif ( $UC_cardType eq ')ENDDOF' ) { # adjust the DOF count
            $skelDOFCount--;
          }
          elsif ( $UC_cardType eq ')DOEXEC' ) { # adjust the DOEXEC count
            $skelDOEXECCount++;
          }
          elsif ( $UC_cardType eq ')ENDDOEXEC' ) { # adjust the DOEXEC count
            $skelDOEXECCount--;
          }
          $skelLine++;
        } # end of the while loop looking for an end loop card
        if ( ! defined($skelLines[$skelArray{$currentActiveSkel}][$skelLine]) ) { # at the end of the skeleton and no end in sight
          displayDebug("Have not found a $searchEnd card following this $card card.\nThis $card will be ignored",1,$currentSubroutine);
        }
      }
    }
  }
} # end of processLAST

sub processDOT { 
  # -----------------------------------------------------------
  # Routine to process the )DOT card
  # a )DOT is of the form:   )DOT <DB Connection Reference> <Cursor Ref> <Table Name> <where clause>
  # where:
  #    DB Connection Reference : This identifies the database connection to use. this literal must match the literal on the )LOGON card
  #    Cursor Ref              : This identifies the cursor opened by this )DOT. It is used to refer to columns
  #    Table Name              : The Table name to select from
  #    Where Clause            : The condition to apply to the select
  #
  # The SQL to be used will be generated as 'SELECT * FROM <Table Name> WHERE <Where Clause>'
  #
  # Usage: processDOT(<control card>)
  # Returns: establishes a cursor for the )DOT loop and sets up control variables
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processDOT';
  
  my $where = ''; 
  
  my $card = shift;                                        # get the card information
  my $DBConnectionRef = getToken($card);                   # (CONNREF) this is the database ref that a )LOGON should have created
  my $cursorRef = getToken($card);                         # (TABREF) this is the key through which all cursor parts will be collected
  my $table = getToken($card);                             # (Table) the table name to query
  if ( $currentLinePosition < length($card)) {             # there is a where clause
    $where = trim(substr($card,$currentLinePosition));     # the where clause is just the rest of the line - not tokenised 
  }
  
  # qualify the table if necessary
  
  if ( defined(getVariable('viewQual')) ) { # a view/table qualifier has been set .... if the tablename hasn't already been qualified then qualify it
    if ( $table !~ /\./ ) { # table name does not include a period so add in the qualifier
      $table = getVariable('viewQual') . '.' . $table;
    }
  }

  # read in data if it is held in a file

  if ( $where ne '' ) {                        # only bother if there is a where clause
    if ( uc($where) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
      $where = loadSQL(trim(substr($where,$+[0])) , $currentSubroutine);             # load the SQL
    }
    elsif ( (uc($where) =~ "^INLINE\:|^INLINE\=") || ( uc($where) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
      $where = loadInlineCards($currentSubroutine);             # load the SQL
    }
  }

  # Construct the SQL to use
  
  $cursorSQL{$cursorRef} = "select * from $table";    # Set up the base SQL
  if ( trim($where) ne '' ) { # the where clause actually has characters in it
    $cursorSQL{$cursorRef} .= " where $where";
  }
  displayDebug("Constructed SQL is: $cursorSQL{$cursorRef}",1,$currentSubroutine);
  
  establishDOTLoop($card,$DBConnectionRef,$cursorRef);                                 # establish the cursor and loop variables

} # end of processDOT

sub processXDOT {
  # -----------------------------------------------------------
  # Routine to process the )XDOT card
  # a )DOT is of the form:   )XDOT <DB Connection Reference> <Cursor Ref> <SQL statement>
  # where:
  #    DB Connection Reference : This identifies the database connection to use. this literal must match the literal on the )LOGON card
  #    Cursor Ref              : This identifies the cursor opened by this )DOT. It is used to refer to columns
  #    SQL Statement           : SQL to use
  #
  # Usage: processXDOT(<control card>)
  # Returns: establishes a cursor for the )DOT loop and sets up control variables
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processDOT';
  
  my $card = shift;                                        # get the card information
  my $DBConnectionRef = getToken($card);                   # (CONNREF) this is the database ref that a )LOGON should have created
  my $cursorRef = getToken($card);                         # (TABREF) this is the key through which all cursor parts will be collected
  if ( $currentLinePosition > length($card) ) { # something has gone wrong ....
    displayError(")XDOT doesn't have enough parameters )XDOT will be ignored",$currentSubroutine);
    $skelDOTSkipCards = "Yes";              # skip cards till we get to a )ENDDOT at the same level
    my $cnt = push(@controlStack,($skelDOEXECCount,$skelDOFCount,$skelDOTCount,$skelSELCount));      # save counts on entry
    $skelDOTCount++;
    $skelDOT_resumeLevel = $skelDOTCount - 1;   # level at which processing will be resumed (will be tested for each )ENDDOT encountered)
  }
  else {
    my $SQL = trim(substr($card,$currentLinePosition));      # (SQL Statement) SQL to be used
  
    # read in data if it is held in a file

    if ( uc($SQL) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
      $SQL = loadSQL(trim(substr($SQL,$+[0])) , $currentSubroutine);             # load the SQL
    }
    elsif ( (uc($SQL) =~ "^INLINE\:|^INLINE\=") || ( uc($SQL) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
      $SQL = loadInlineCards($currentSubroutine);             # load the SQL
    }

    # Construct the SQL to use
  
    $cursorSQL{$cursorRef} = $SQL;    # Set up the base SQL
    displayDebug("SQL is: $cursorSQL{$cursorRef}",1,$currentSubroutine);
  
    establishDOTLoop($card,$DBConnectionRef,$cursorRef);                                 # establish the cursor and loop variables
  }

} # end of processXDOT

sub establishDOTLoop {
  # -----------------------------------------------------------
  # Routine to establish the variables and connection for DOT loops
  #
  # The select clause for the query will be in $cursorSQL{$cursorRef}
  #
  # Usage: establishDOTLoop(<original control card>,<DB Connection Ref>,<cursor Ref>)
  # Returns: establishes a cursor for the )DOT/XDOT loop and sets up control variables
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'establishDOTLoop';

  my $card = shift;
  my $DBConnectionRef = shift;    
  my $cursorRef = shift;

  if ( ( $skelSelSkipCards eq "No" ) ) { # not excluded because of a failed )SEL
    if ( ( $skelDOTSkipCards eq "No" ) ) { # not excluded because of a )DOT that returned zero rows
      setVariable('LASTDOTCount','0');               # initialise variable
      my $cnt = push(@controlStack,($skelDOEXECCount,$skelDOFCount,$skelDOTCount,$skelSELCount));      # save counts on entry
      displayDebug("PUSHING onto stack - #entries $cnt",2,$currentSubroutine);
      displayDebug("Pushing control counts: \$skelDOFCount=$skelDOFCount,\$skelDOTCount=$skelDOTCount,\$skelSELCount=$skelSELCount",1,$currentSubroutine);
      $skelDOTCount++;                     # Keep track of )DOT control cards encountered
      if ( ! defined($skelConnection{$DBConnectionRef}) ) { # A )LOGON hasn't created the database connection yet - fail this statement
        displayError("A previous )LOGON statement has not created a database connection for $DBConnectionRef\nThis )DOT will be ignored",$currentSubroutine);
        $skelDOTSkipCards = "Yes";              # skip cards till we get to a )ENDDOT at the same level
        $skelDOT_resumeLevel = $skelDOTCount - 1;   # level at which processing will be resumed (will be tested for each )ENDDOT encountered) 
      }
      else { # DB Connection exists and is OK to use
        if ( defined($skelCursor{$cursorRef}) ) { # this cursor name has already been defined :-( - ignore it 
          displayError("This cursor ref ($cursorRef) has already been used by a previous )DOT or )XDOT\nThis )DOT will be ignored",$currentSubroutine);
          $skelDOTSkipCards = "Yes";              # skip cards till we get to a )ENDDOT at the same level
          $skelDOT_resumeLevel = $skelDOTCount - 1;   # level at which processing will be resumed (will be tested for each )ENDDOT encountered)
        }
        else { # cursor reference unused so right to go ...

          establishDOTLoopPosition($cursorRef);            # identify the spot that the )DOT will loop from

          if ( ( $skelDOTSkipCards eq "No" ) ) { # skelDOTSkipCards will be set to Yes if errors were found in establishDOTLoopPosition()
            # )DOT loop position now set ...... construct the SQL
    
            # open the cursor now ....

            if ( establishCursor( $DBConnectionRef, $cursorRef ) ) { # returns 1 if all is ok (and attempts to read the first row)
              if ( $skelDebugLevel > 1 ) { # if debug >1 then print out the data as well
                foreach (@{$skelCursorRow{$cursorRef}} ) {
                 displayDebug("$_",2,$currentSubroutine);
                }
              }
            }
            else { # failed to open the cursor ....
              if ( $skelVerboseSQLErrors eq 'Yes' ) {
                if ( $SQLError ) { # SQL Error (not just no rows found)
                  displayError("Unable to open cursor using SQL:\n $cursorSQL{$cursorRef} - treat as if no rows were returned",$currentSubroutine);
                }
                else {
                  displayError("No Rows Returned using SQL:\n $cursorSQL{$cursorRef} - treat as if no rows were returned",$currentSubroutine);
                }
              }
              else { # not verbose - dont mention it if no rows found and if SQL error dont print SQL
                if ( $SQLError ) { # SQL Error (not just no rows found)
                  displayError("No rows returned",$currentSubroutine);
                }
              }
              $skelDOTSkipCards = 'Yes';         # skip cards between )DOT and )ENDDOT
              $skelDOT_resumeLevel = $skelDOTCount - 1;   # level at which processing will be resumed (will be tested for each )ENDDOT encountered)
              undef $skelCursor{$cursorRef};              # free up the cursor array entry
            }
          }
        }
      }
    }
    else { # skipping because of DOT skip cards
        $skelDOTCount++;                     # Keep track of )DOT control cards encountered
        displayDebug("Skipped: $card. DOT Count = $skelDOTCount, DOT Resume Level = $skelDOT_resumeLevel",2,$currentSubroutine);
    }
  }
  else { #skipping because of skip sel cards
      displayDebug("Skipped: $card. SEL Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
 
} # end of establishDOTLoop

sub processENDDOT {
  # -----------------------------------------------------------
  # Routine to process the )ENDDOT command
  # an )ENDDOT is of the form:    )ENDDOT
  #
  # Usage: processENDDOT(<control card>)
  # Returns: sets control variables that affect program flow
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processENDDOT';
  
  my $card = shift;  

  if ( $skelSelSkipCards eq "No" ) {              # not skipping cards because of SEL
    if ( $skelDOTSkipCards eq "No" ) {            # not skipping cards because of DOT

      # only check for preceding )DOT's and )XDOT's if you aren't skipping cards
      if ( $skelDOTCount == 0 ) { # no previous matching )DOT
        displayError("Problems with the )ENDDOT at card $currentSkelLine in skeleton $currentActiveSkel. No matching )DOT",$currentSubroutine);
        return;
      }

      if ( $lastFlagSet ) {                       # )LAST has sent processing this way so treat as end of cursor
        displayDebug(")LAST statement has skipped to )ENDDOT.",2,$currentSubroutine);
        $skelDOTCount--;                          # only decrement the )DOT count when passing through the card
        displayDebug("Processed )ENDDOT. DOT Count = $skelDOTCount, DOT Resume Level = $skelDOT_resumeLevel",1,$currentSubroutine);
        verifyControlCounts();
        setVariable('LASTDOTCount',$cursorRowNumber{$currentCursorConnection});
        closeCursor($currentCursorConnection);
        $lastFlagSet = 0;
      }
      elsif ( getNextRecord($currentCursorConnection) ) { #  data returned
        displayDebug("Data returned and put in Array. ",2,$currentSubroutine);
        $currentSkelLine = $DOTLocation{$currentCursorConnection};        # reset current skeleton line to the beginning of the loop
      }
      else { # no more data
        $skelDOTCount--;                          # only decrement the )DOT count when passing through the card
        displayDebug("Processed )ENDDOT. DOT Count = $skelDOTCount, DOT Resume Level = $skelDOT_resumeLevel",1,$currentSubroutine);
        verifyControlCounts();
        setVariable('LASTDOTCount',$cursorRowNumber{$currentCursorConnection});
        closeCursor($currentCursorConnection);
      }
    }
    else { # Currently skipping within a DOT
      $skelDOTCount--;
      if ( $skelDOTCount == $skelDOT_resumeLevel ) {    # check if it is time to resume processing
        # pop the saved entries off of the stack
        displayDebug("Processed )ENDDOT. DOT Count = $skelDOTCount, DOT Resume Level = $skelDOT_resumeLevel",1,$currentSubroutine);
        verifyControlCounts();
        $skelDOTSkipCards = "No";                       # stop skipping because of the )DOT failure
      }
    }
  }
  else { # skipped because within a )SEL section being skipped
    displayDebug("Skipped: $card. SEL Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processENDDOT

sub processWHEN { 
  # -----------------------------------------------------------
  # Routine to process the )WHEN card 
  # a )WHEN is of the form:    )WHEN <condition> THEN <statement>
  #
  # Note that the following control statements are not allowed on a WHEN command:
  #
  # )SEL 
  # )IF 
  # )SELELSE 
  # )ENDSEL 
  # )DOEXEC
  # )ENDDOEXEC
  # )DOF 
  # )ENDDOF 
  # )DOT 
  # )XDOT 
  # )ENDDOT 
  #
  # Usage: processWHEN(<control card>)
  # Returns: Conditionally executes a limited set of non-flow control commands
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processWHEN';
  
  my $card = shift;  
  
  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
  
    # check for the existence of the THEN parameter .... if it doesn't exist skip the card with error message
    my ($condition, $statement) = split (/[Tt][Hh][Ee][Nn]/, $card);   
    
    if ( defined($statement) ) { # THEN was there so continue on
      my $tmpI = trim(substr($condition,6));                  # strip off the )WHEN at the start
      displayDebug("condition=$condition, adjusted cond=$tmpI, statement=$statement",1, $currentSubroutine);    
      displayDebug("Parsing the following statement (WHEN) : $tmpI",2,$currentSubroutine);
      if ( processCondition($tmpI) ) {             # returns 1 if condition is true
        $statement = trim($statement);             # remove leading and trailing spaces
        if ( substr( $statement,0,1) eq ')' )  {   # it is a control card the check that it is a valid one to process
          my @bits = split (" ", $statement);
          my $tmpSrch = $bits[0];
          $tmpSrch =~ s/\)/\\\)/g;      # escape otu the leading )
          if ( ' )SEL )IF )SELELSE )ENDSEL )DOF )DOT )XDOT )ENDDOT )ENDDOF )ENDDOEXEC )DOEXEC ' =~ uc($tmpSrch) ) { # it is a control card that isn't allowed in a WHEN
            displayError("Problems with the )WHEN at card $currentSkelLine in skeleton $currentActiveSkel. Control card used - $bits[0] - is not allowed on a WHEN card",$currentSubroutine);
          } 
          else { # all good to go
            processControlCard($statement);
          }
        }
        else { # it's not a control card ....
          processLine($statement);
        } 
      }
    }
    else { # then doesn't exist so just skip the statement
      displayError("Problems with the )WHEN at card $currentSkelLine in skeleton $currentActiveSkel. No THEN parameter",$currentSubroutine);
    }
  
    displayDebug("Processed )SEL ($currentSkelLine). Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",1,$currentSubroutine);
  }
  else {
    displayDebug("Skipped: $card, Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processWHEN

sub processCELLSTYLE { 
  # -----------------------------------------------------------
  # Routine to process the )CELLSTYLE card 
  # a )CELLSTYLE is of the form:    )CELLSTYLE <style> FOR <column name> WHEN <condition>
  #
  # This statement establishes cell style commands to be used when certain conditions are met
  #
  # Usage: processCELLSTYLE(<control card>)
  # Returns: Establish conditions when a certain stle will be used
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processCELLSTYLE';
  
  my $card = shift; 
  $card = trim($card);
  my $condition;  
  
  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards

    my $style = getToken($card);
    my $lit1 = getToken($card);
    
    if ( $lit1 eq '' ) { # only one parameter (must be CLEAR)
      if ( uc($style) eq 'CLEAR' ) { # erase existing entries
        displayDebug("Clearing out all cell styles",0,$currentSubroutine);
        %cellStyle = ();
      }
      else { # if only 1 parameter is supplied it must be CLEAR
        displayError("Error at card $currentSkelLine in skeleton $currentActiveSkel. If only one parameter is supplied on )CELLSTYLE it MUST be CLEAR",$currentSubroutine);
      }
      return; # no need to do any more processing
    }
    elsif ( uc($lit1) ne 'FOR' ) { # must be FOR
      displayError("Error at card $currentSkelLine in skeleton $currentActiveSkel. FOR missing from )CELLSTYLE",$currentSubroutine);
      displayError("FORMAT: )CELLSTYLE <style> [FOR <column> [WHEN <condition>]]",$currentSubroutine);
      return;
    }
    
    my $column = getToken($card);
    
    if ( $column eq '' ) { # no column information
      displayError("Error at card $currentSkelLine in skeleton $currentActiveSkel. column name missing from )CELLSTYLE",$currentSubroutine);
      displayError("FORMAT: )CELLSTYLE <style> [FOR <column> [WHEN <condition>]]",$currentSubroutine);
      return;
    }
    
    if ( uc($style) eq 'CLEAR' ) { # erase existing entries for the column
      displayDebug("Clearing out cell styles for column $column",0,$currentSubroutine);
      foreach my $test (keys %{ $cellStyle{$column} } ) {
        delete $cellStyle{$column}{$test};
      }
      return; 
    }
    
    my $lit2 = getToken($card);
    
    if ( $lit2 eq '' ) { # no when condition so defaults to always
      $condition = 1;
      $styleCount++;
      $styleCount = substr("000" . $styleCount,length($styleCount)); # pad out to 3 chars
      $cellStyle{$column}{$styleCount . $condition} = $style; 
      displayDebug("Processed )CELLSTYLE ($currentSkelLine). Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",0,$currentSubroutine);
      displayDebug("style = $style, column = $column, condition = $condition, styleCount = $styleCount",0,$currentSubroutine);
      return;
    }
    
    if ( uc($lit2) ne 'WHEN' ) { # must be WHEN
      displayError("Error at card $currentSkelLine in skeleton $currentActiveSkel. WHEN missing from )CELLSTYLE",$currentSubroutine);
      displayError("FORMAT: )CELLSTYLE <style> [FOR <column> [WHEN <condition>]]",$currentSubroutine);
      return;
    }
    
    if ( $currentLinePosition < length($card) ) { 
      $condition = trim(substr($card,$currentLinePosition)); 
    }
    else { 
      displayError("Error at card $currentSkelLine in skeleton $currentActiveSkel. WHEN condition missing from )CELLSTYLE",$currentSubroutine);
      displayError("FORMAT: )CELLSTYLE <style> [FOR <column> [WHEN <condition>]]",$currentSubroutine);
      return;
    }
    
    # save the values for later testing
    $styleCount++;
    $styleCount = substr("000" . $styleCount,length($styleCount)); # pad out to 3 chars
    $cellStyle{$column}{$styleCount . $condition} = $style; 
      
    displayDebug("Processed )CELLSTYLE ($currentSkelLine). Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",0,$currentSubroutine);
    displayDebug("style = $style, column = $column, condition = $condition",0,$currentSubroutine);
  }
  else {
    displayDebug("Skipped: $card, Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processCELLSTYLE

sub processROWSTYLE { 
  # -----------------------------------------------------------
  # Routine to process the )ROWSTYLE card 
  # a )ROWSTYLE is of the form:    )ROWSTYLE <style> FOR <column name> WHEN <condition>
  #
  # This statement establishes row style commands to be used when certain conditions are met
  #
  # Usage: processROWSTYLE(<control card>)
  # Returns: Establish conditions when a certain stle will be used
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processROWSTYLE';
  
  my $card = shift;  
  my $condition;
  
  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
  
    my $style = getToken($card);
    my $lit = getToken($card);

    if ( uc($style) eq 'CLEAR' ) { # erase existing entries
      displayDebug("Clearing out all row styles",0,$currentSubroutine);
      %rowStyle = ();              # clear out all row styles
      return;
    }
    
    if ( $lit eq '' ) { # no condition set
      $condition = 1;
      $styleCount++;
      $styleCount = substr("000" . $styleCount,length($styleCount)); # pad out to 3 chars
      $rowStyle{$styleCount . $condition} = $style;                  # defaults to always use this style
    }
    elsif ( uc($lit) ne 'WHEN' ) {
      displayError("Error at card $currentSkelLine in skeleton $currentActiveSkel. When missing from )ROWSTYLE",$currentSubroutine);
      displayError("FORMAT: )ROWSTYLE <style> [WHEN <condition>]",$currentSubroutine);
      return; 
    }
    else { # condition set
      if ( $currentLinePosition < length($card) ) { 
        $condition = trim(substr($card,$currentLinePosition)); 
      }
      else { 
        displayError("Error at card $currentSkelLine in skeleton $currentActiveSkel. When condition missing from )ROWSTYLE",$currentSubroutine);
        displayError("FORMAT: )ROWSTYLE <style> [WHEN <condition>]",$currentSubroutine);
        return; 
      }
    
      # save the values for later testing
      $styleCount++;
      $styleCount = substr("000" . $styleCount,length($styleCount)); # pad out to 3 chars
      $rowStyle{$styleCount . $condition} = $style; 
    }
      
    displayDebug("Processed )ROWSTYLE ($currentSkelLine). Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",0,$currentSubroutine);
    displayDebug("style = $style, condition = $condition, styleCount = $styleCount",0,$currentSubroutine);
    
  }
  else {
    displayDebug("Skipped: $card, Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
} # end of processROWSTYLE

sub processCondition { 
  # -----------------------------------------------------------
  # Routine to process condition part of the )SEL, SELELSE or )WHEN card 
  #
  # It will process the DEFINED, NOT_DEFINED, EMPTY, NOT_EMPTY,  ROWS_EXIST and NO_ROWS_EXIST 
  # functions itself but use evaluateCondition to evaluate all other checks
  #
  # Usage: processCondition(<conndition>)
  # Returns: 1 or zero depending on the result of checking the condition
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processCondition';
  
  my $card = shift;  

  displayDebug("Condition being tested is '$card'",2,$currentSubroutine);
  if ( uc(substr($card,0,8)) eq "DEFINED(" ) {       # special function DEFINED ....
    my $tmpVar = substr($card,8,length($card)-9);    # assume that there is a trailing )
    if ( defined(getVariable($tmpVar)) ) {         # variable is defined  so evaluates true
      return 1; 
    }
    else { # variable is not defined so evaluates false
      return 0;
    }
  }
  elsif ( uc(substr($card,0,12)) eq "NOT_DEFINED(" ) { # special function ....
    my $tmpVar = substr($card,12,length($card)-13);    # assume that there is a trailing )
    if ( defined(getVariable($tmpVar)) ) {           # variable is defined  so evaluates false
      return 0;
    }
    else { # variable is not defined so evaluates true
      return 1;
    }
  }
  elsif ( uc(substr($card,0,6)) eq "EMPTY(" ) { # special function ....
    my $tmpVar = substr($card,6,length($card)-7);    # assume that there is a trailing )
    if ( length($tmpVar) == 0 ) {                # variable has no information in it
      return 1;
    }
    else { # variable contains something
      return 0;
    }
  }
  elsif ( uc(substr($card,0,10)) eq "NOT_EMPTY(" ) { # special function ....
    my $tmpVar = substr($card,10,length($card)-11);    # assume that there is a trailing )
    if ( length($tmpVar) == 0 ) {                # variable has no information in it
      return 0;
    }
    else { # variable contains something
      return 1;
    }
  }
  elsif ( uc(substr($card,0,11)) eq "ROWS_EXIST(" ) { # special function ....
    my $tmpSQL = substr($card,11,length($card)-12);   # assumes the function is terminated with a )
    my $dbConnection = '';
    for ( my $i = 0; $i < length($tmpSQL); $i++ ) {
      if ( substr($tmpSQL,$i,1) eq ' ' ) { $tmpSQL = substr($tmpSQL, $i+1) ; last; } # stop when you get to the first space
      $dbConnection .= substr($tmpSQL,$i,1);
    }
    $tmpSQL = trim($tmpSQL);        # trim leading and trailing spaces
    return processCHECKFORROW("$dbConnection", $tmpSQL)  # will return1 if a row is found and 0 if no row is found or error
  }
  elsif ( uc(substr($card,0,14)) eq "NO_ROWS_EXIST(" ) { # special function ....
    my $tmpSQL = substr($card,14,length($card)-15);      # assumes the function is terminated with a )
    my $dbConnection = '';
    for ( my $i = 0; $i < length($tmpSQL); $i++ ) {
      if ( substr($tmpSQL,$i,1) eq ' ' ) { $tmpSQL = substr($tmpSQL, $i+1) ; last; } # stop when you get to the first space
      $dbConnection .= substr($tmpSQL,$i,1);
    }
    $tmpSQL = trim($tmpSQL);        # trim leading and trailing spaces
    if ( processCHECKFORROW("$dbConnection", $tmpSQL) ) { # will return1 if a row is found and 0 if no row is found or error
      return 0;
    }
    else { # there were no rows
      return 1;
    }
  }
  else { # evaluate it as logical or numeric condition
    return evaluateCondition($card) ;  # evaluate returns 1 for true and 0 for false
  }
  
} # end of processCondition

sub processSEL { 
  # -----------------------------------------------------------
  # Routine to process the )SEL or )IF card 
  # a )SEL is of the form:    )SEL <expression> <condition> <expression>
  #
  # Usage: processSEL(<control card>)
  # Returns: sets control variables that affect program flow
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processSEL';
  
  my $card = shift;  

   if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
    my $cnt = push(@controlStack,($skelDOEXECCount,$skelDOFCount,$skelDOTCount,$skelSELCount));      # save counts on entry
    displayDebug("PUSHING onto stack - #entries $cnt",2,$currentSubroutine);
    displayDebug("Pushing control counts: \$skelDOFCount=$skelDOFCount,\$skelDOTCount=$skelDOTCount,\$skelSELCount=$skelSELCount",1,$currentSubroutine);
    $skelSELCount++;                                                      # keep track ofthe )SEL level we are at
    my $tmpI = trim(substr($card,5));                                     # tmpI now holds the condition
    displayDebug("Passing the following condition (SEL) : $tmpI",2,$currentSubroutine);
 
    if ( processCondition($tmpI) ) { # returns 1 if condition is true
      displayDebug("Condition evaluated to True",2,$currentSubroutine);
      $skelGotoENDSEL = "Yes";                                          # indicates that after the next ENDSEL we need to skip to the )ENDSEL for this )SEL                  
    }
    else { # condition evaluated to false
      displayDebug("Condition evaluated to False",2,$currentSubroutine);
      $skelSelSkipCards = "Yes";                                        # )sel is false so skip cards until the next )SELELSE or )ENDSEL
      $skelSEL_resumeLevel = $skelSELCount - 1;                         # indicator to show at what stack level the processing should restart (to copy with )SEL within )SEL
      $skelGotoENDSEL = "No";                                           # indicates that we haven't finished with this )SEL as yet - there may be a )SELELSE that will be true
    }
    displayDebug("Processed )SEL ($currentSkelLine). Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",1,$currentSubroutine);
  }
  else {
    $skelSELCount++;                                                      # keep track ofthe )SEL level we are at
    displayDebug("Skipped: $card, Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }

} # end of processSEL

sub processSELELSE { 
  # -----------------------------------------------------------
  # Routine to process the )SELELSE or )ELSEIF card
  # a )SELELSE is of the form:    )SELELSE [<expression> <condition> <expression>]
  # the parameters are optional 
  #
  # Usage: processSELELSE(<control card>)
  # Returns: sets control variables that affect program flow
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processSELELSE';
  
  my $card = shift;  
  my $tmpI ;                    # will contain the )SELELSE conditions
  
  if ( ( $skelGotoENDSEL eq "No" ) ) {                         # no successful SEL/SELELSE yet so need to keep checking
    if ( ( $skelDOTSkipCards eq "No" ) ) {                     # not skipping cards because we are within a )DOT
      if ( ( $skelSelSkipCards eq "Yes" ) ) {                  # skipping SEL cards because previouse check failed so keep checking
    if ( trim($card) eq ")SELELSE" ) {                     # the card has no conditions so is a catch all
      if ( $skelSELCount == $skelSEL_resumeLevel + 1 ) {   # check to see if we are back in play doing checks
        $skelSelSkipCards = "No";                          # process the cards in this )SELELSE group
        $skelGotoENDSEL = "Yes";                           # after processing goto the )ENDSEL
      }
    }
    else { # the SELELSE has a condition parameter
          $tmpI = trim(substr($card,9));
          displayDebug("Passing the following condition (SELELSE) : $tmpI",2,$currentSubroutine);
          
          if ( processCondition($tmpI) ) { # returns 1 if condition is true
            displayDebug("Condition evaluated to True",2,$currentSubroutine);
        $skelSelSkipCards = "No";                        # process the cards in this )SELELSE group
            $skelGotoENDSEL = "Yes";                         # indicates that after the next ENDSEL we need to skip to the )ENDSEL for this )SEL                  
          }
          else { # evaluated false
            displayDebug("Condition evaluated to False",2,$currentSubroutine);
            $skelSelSkipCards = "Yes";                                        # )sel is false so skip cards until the next )SELELSE or )ENDSEL
            $skelSEL_resumeLevel = $skelSELCount - 1;                         # indicator to show at what stack level the processing should restart (to copy with )SEL within )SEL
            $skelGotoENDSEL = "No";                                           # indicates that we haven't finished with this )SEL as yet - there may be a )SELELSE that will be true
          }
    }
      }  
      else { # SELSkipCards was false which means that pervious SEL/SELELSE was satisfied
        $skelSelSkipCards = "Yes";                           # start skipping cards
    $skelSEL_resumeLevel = $skelSELCount -1;             # set the resume level as we will be skipping cards now
        if ( $skelSELCount == 0 ) { # if true then there is a problem as there is an unmatch )SELELSE
          displayError(")SELELSE without )SEL. Card will be ignored",$currentSubroutine);
          $skelSelSkipCards = "No";
    }
        displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
      }
      displayDebug("Processed )SELELSE. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",1,$currentSubroutine);
    }
  }
  else { # keep skipping until we get to a )ENDSEL
    $skelSEL_resumeLevel = $skelSELCount -1;     # dont think this is right          
    $skelSelSkipCards = "Yes";                                # start skipping cards
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
  
} # end of processSELELSE

sub processENDSEL { 
  # -----------------------------------------------------------
  # Routine to process the )ENDSEL or )ENDIF card
  # a )ENDSEL is of the form:    )ENDSEL 
  #
  # Usage: processENDSEL(<control card>)
  # Returns: sets control variables that affect program flow
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processENDSEL';
  
  my $card = shift;  
  
  displayDebug(")ENDSEL: \$skelDOTSkipCards=$skelDOTSkipCards, \$skelSelSkipCards=$skelSelSkipCards, \$skelSELCount=$skelSELCount, \$skelSEL_resumeLevel=$skelSEL_resumeLevel\n",1,$currentSubroutine);
  if ( $skelDOTSkipCards eq "No" ) {   # not skipping cards (caused when )DOT returns no rows .... we're waiting for a )ENDDOT
    if ( $skelSelSkipCards eq "No" ) { # not skipping cards because of a failed )SEL
      $skelSELCount--;                                                        # Reduce the count of unmatched )DOTs
      $skelGotoENDSEL = "No";                                           # reset the goto )ENDSEL flag        
      verifyControlCounts();
      displayDebug("Processed )ENDSEL ($currentSkelLine). Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",1,$currentSubroutine);
    }
    else { # skipping cards because of )SEL - check if time to restart
      $skelSELCount--;
      if ( $skelSELCount == $skelSEL_resumeLevel ) {               # if we are at a matching )ENDSEL level                  
        $skelSelSkipCards = "No";                                         # stop skipping cards
        $skelGotoENDSEL = "No";                                           # reset the goto )ENDSEL flag        
        verifyControlCounts();
        displayDebug("Processed )ENDSEL ($currentSkelLine) .... Processing of cards resumed. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",1,$currentSubroutine);
      }
    }
    if ( $skelSELCount < 0 ) {
      displayError("ENDSEL without SEL. SelCount = $skelSELCount",$currentSubroutine);
    }
  }
  else { # just adjust the count (as we would have incremented the count on the )SEL
    $skelSELCount--;
  }
} # end of processENDSEL

sub processASET { 
  # -----------------------------------------------------------
  # Routine to process the )ASET card
  # a )ASET is of the form:    )SET <var> = <value>
  #
  #   Notes: 1. the var does not have a preceding :
  #          2. var may be of the form <scope>.<varname> but the scope
  #             must exist
  #
  # Usage: processASET(<control card>)
  # Returns: sets a variable value (it does no evaluation)
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processASET';
  
  my $card = shift;                    # get the card information
  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
    my ( $varName, $varOp, $varValue ) = ( $card =~ /.*? ([^=]*)(=)(.*)/ ) ; 
    if ( ! defined($varOp) ) { # check if it is an equals sign (if it is not defined then an = was not found)
      displayError("Operator for )ASET must be '='.",$currentSubroutine);
      return;
    }
    displayDebug("\)ASET string is " . substr($card,$currentLinePosition),1,$currentSubroutine);
    $varName = trim($varName);
    
    if ( $varName =~ /\./ ) {                 #if it has a period check if it is a scope name  
      my ( $scope, $tmpName ) = ( $varName =~ /(.*)\.(.*)/ ) ; # split out the scope
   
      for ( my $i = $#scopeStack; $i >= 0 ; $i-- ) { # look back through the scope stack to see if the variable can be found
        if ( $scopeStack[$i] eq $scope ) {  # the scope is valid
          # NOTE: check for special values does not need to be checked here as special variables dont contain periods
          my $tempScope = $currentScope;      # save the current scope
          $currentScope = lc($scope);             # temporarily set the scope
          $varValue = substituteVariables(trim($varValue));
          displayDebug("Result is = $varValue",1,$currentSubroutine);
          setVariable($tmpName, $varValue);
          $currentScope = $tempScope;         # return the scope back
          displayDebug("Value $varValue assigned to $tmpName in scope $scope",1,$currentSubroutine);
          return;
        }
      }
      
      # if here then scope doesn't exist so treat the whole thing as a variable name
      
    }
   
    $varValue = substituteVariables(trim($varValue));
    displayDebug("Value is = $varValue",1,$currentSubroutine);

    if ( ! checkForSpecialVariables($varName, $varValue) ) { # will return 0 if not special
      setVariable($varName,$varValue);    # set the variable
      displayDebug("Value $varValue assigned to $varName",0,$currentSubroutine);
    }
  }
  else { # skip this card
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }  
} # end of processASet

sub checkForSpecialVariables {
  # -----------------------------------------------------------
  # Routine to process special variables supplied on a )SET or 
  # )ASET command
  # 
  # Special variables are:
  #
  # skelDelimiter         # delimiter to be used when generating dump file using )DMP
  # skelMaxOutput         # max string length length to be returned -  his is not an absolute value - output will be not be added to the string once it  
  #                       # exceeds this limit but the string wont be truncated to this length
  # skelMaxRows           # max number of rows to be displayed by the FTAB Command
  # skelMaxTableOut       # max length length of the output generated by a FTAB command - output will be not be added to the string once it    
  # skelDebugModules      # variable indicating which modules debug messages should be produced for    
  # skelShowSQL           # variable indicating if generated SQL should be displayed (defaults to NO)
  # skelDebugLevel        # by default dont list any debug information  
  # skelVerboseSQLErrors  # by default dont print out verbose SQL erros details (i.e. dont print out when no rows found and dont print SQL)        
  # testRoutines          # variable containing which tests to run in the testRoutine sub
  # indexCaseInsensitive  # default to case insensitive indexes       
  #
  # Usage: checkForSpecialVariables(<variable name>, <value>)
  # Returns: sets special variables, returns 1 if it was a special variabloe, 0 otherwise
  # -----------------------------------------------------------

  my $currentSubroutine = 'checkForSpecialVariables';
  my $varName = shift;
  my $varValue = shift;
  
  my $returnValue = 0;
  my $searchName = " " . uc($varName) . " ";
  
  my $charSpecialVariables = " SKELDELIMITER SKELDEBUGMODULES SKELSHOWSQL SKELVERBOSESQLERRORS OUTPUTMODE ";
  my $numSpecialVariables  = " SKELMAXOUTPUT SKELMAXROWS SKELMAXTABLEOUT SKELDEBUGLEVEL TESTROUTINES INDEXCASEINSENSITIVE ";
  
  displayDebug("Starting $varName <> $varValue",1,$currentSubroutine);
  
  if ( $charSpecialVariables =~ /$searchName/ ) { # it is a special variable that takes characters  

    displayDebug("0 $varName = $varValue",0,$currentSubroutine);
    
    if ( uc($varName) eq 'SKELDELIMITER' ) { $skelDelimiter = $varValue; }
    elsif ( uc($varName) eq 'SKELDEBUGMODULES' ) { $skelDebugModules  = $varValue; }
    elsif ( uc($varName) eq 'SKELSHOWSQL' ) { $skelShowSQL  = $varValue; }
    elsif ( uc($varName) eq 'SKELVERBOSESQLERRORS' ) { $skelVerboseSQLErrors  = $varValue; }
    elsif ( uc($varName) eq 'OUTPUTMODE' ) { 
      displayDebug("outputMode set to $varValue",0,$currentSubroutine);
      $outputMode  = $varValue; 
    }
    $returnValue = 1;
    
  }
  elsif ( $numSpecialVariables =~ /$searchName/) { # these entries only take numeric values
    if ( isNumeric($varValue) ) {
      displayDebug("2 $varName = $varValue",1,$currentSubroutine);
      if ( uc($varName) eq 'SKELMAXOUTPUT' ) { $skelMaxOutput  = $varValue; }
      elsif ( uc($varName) eq 'SKELMAXROWS' ) { $skelMaxRows  = $varValue; }
      elsif ( uc($varName) eq 'SKELMAXTABLEOUT' ) { $skelMaxTableOut  = $varValue; }
      elsif ( uc($varName) eq 'SKELDEBUGLEVEL' ) { $skelDebugLevel  = $varValue; }
      elsif ( uc($varName) eq 'TESTROUTINES' ) { $testRoutines  = $varValue; }
      elsif ( uc($varName) eq 'INDEXCASEINSENSITIVE' ) { $indexCaseInsensitive = $varValue; }
      $returnValue = 1;
    }
    else {
      displayError("Value must be numeric ($varName = $varValue) - will not be treated as special character",$currentSubroutine);
      $returnValue = 0;    
    }
    
  }
  
  return $returnValue;
  
} # end of checkForSpecialVariables

sub processSET { 
  # -----------------------------------------------------------
  # Routine to process the )SET card
  # a )SET is of the form:    )SET <var> = <expression>
  #
  #   Notes: 1. the var does not have a preceding :
  #          2. var may be of the form <scope>.<varname> but the scope
  #             must exist
  #
  # Usage: processSET(<control card>)
  # Returns: sets a variable value
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processSET';
  
  my $card = shift;                    # get the card information
  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
    my ( $varName, $varOp, $varValue ) = ( $card =~ /.*? ([^=]*)(=)(.*)/ ) ; 
    if ( ! defined($varOp) ) { # check if it is an equals sign (if it is not defined then an = was not found)
      displayError("Operator for )SET must be '='.",$currentSubroutine);
      return;
    }
    displayDebug("\)SET string is " . substr($card,$currentLinePosition),1,$currentSubroutine);
    $varName = trim($varName);
    
    if ( $varName =~ /\./ ) {                 # if it has a period check if it is a scope name  
      my ( $scope, $tmpName ) = ( $varName =~ /(.*)\.(.*)/ ) ; # split out the scope
   
      for ( my $i = $#scopeStack; $i >= 0 ; $i-- ) { # look back through the scope stack to see if the variable can be found
        if ( $scopeStack[$i] eq $scope ) {  # the scope is valid
          # NOTE: check for special values does not need to be checked here as special variables dont contain periods
          my $tempScope = $currentScope;      # save the current scope
          $currentScope = lc($scope);         # temporarily set the scope (scope is case insensitive)
          $varValue = evaluateInfix(substituteVariables(trim($varValue)));
          displayDebug("Result is = $varValue",1,$currentSubroutine);
          setVariable($tmpName, $varValue);
          $currentScope = $tempScope;         # return the scope back
          displayDebug("Value $varValue assigned to $tmpName in scope $scope",1,$currentSubroutine);
          return;
        }
      }
      
      # if here then scope doesn't exist so treat the whole thing as a variable name
      
    }

    $varValue = evaluateInfix(substituteVariables(trim($varValue)));
    displayDebug("Result is = $varValue",1,$currentSubroutine);
    if ( ! checkForSpecialVariables($varName, $varValue) ) { # will return 0 if not special
      setVariable($varName,$varValue);    # set the variable
      displayDebug("Value $varValue assigned to $varName",1,$currentSubroutine);
    }

  }
  else { # skip this card
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }  
} # end of processSet

sub processTAB {
  # -----------------------------------------------------------
  # Routine to process the )TAB (Tab set) control card
  #
  # Usage: processTAB(<control card>)
  # Returns: nothing but establishes the tab control array @tabEntries
  # -----------------------------------------------------------

  my $currentSubroutine = 'processTAB'; 
  my $card = shift;                    # get the card information
  
  my @tmpArray;                        # temporary array to load the tabstops into
  @tabEntries = ();                    # clear out any pre-existing tab entries
  
  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards

    my $tmpTok = getToken($card);
    
    displayDebug("Token: $tmpTok",3,$currentSubroutine);
    my $i = 0;
    if ( $tmpTok ne "" ) {                        # there are soime tabstops to define
      while ( $tmpTok ne "" ) {                   # loop through the )TAB parms
        if ( isNumeric($tmpTok) ) {               # only load in numeric values
          $tmpArray[$i] = $tmpTok-1;              # load them in less one to align them to a start of 0
      $i++;
    }
    else { # non-numeric tab entry
      displayError("Tab entry of $tmpTok ignored as it is not numeric",$currentSubroutine);
    }
    $tmpTok = getToken($card);
        displayDebug("Token: $tmpTok",3,$currentSubroutine);
      }
    }
    
    # array is in but unsorted .... sort it (very ugly sort)
    
    for ( 0 .. $#tmpArray ) {                      # for each array element 
      my $largest = 0;                             # initialise largest as the first entry
      for ( my $k = 0 ; $k <= $#tmpArray ; $k++ ) { # loop through the array and determine the greatest value
        displayDebug("Comparing $tmpArray[$largest] ($largest) and $tmpArray[$k] ($k)",3,$currentSubroutine);
        if ( $tmpArray[$largest] < $tmpArray[$k] ) { 
          displayDebug("\$largest now set to $largest, $tmpArray[$largest] is less than $tmpArray[$k]",3,$currentSubroutine);
          $largest = $k; 
        } 
      }
      unshift (@tabEntries, $tmpArray[$largest]);  # push the current largest onto the fromt of the array
      $tmpArray[$largest] = -1;                    # remove the element from the temp array
    }
    
    # @tabEntries should now contain a sorted list of elements
    
    if ( $skelDebugLevel > 0 ) { # print out the array 
      for ( my $i = 0 ; $i <= $#tabEntries ; $i ++ ) { displayDebug("Tab $i: $tabEntries[$i]",1,$currentSubroutine); }
    }
    
  }
  else {
    displayDebug("Skipped: $card",2,$currentSubroutine);
  }
} # end of processTAB 

sub processDOEXEC {
  # -----------------------------------------------------------
  # Routine to process a )DOEXEC control card
  # The )DOEXEC control card is of the form:  
  #
  #        )DOEXEC <exec Ref> [[using <CTLFileName>] <command>
  #     
  #        where exec ref   : a reference used to isolate this command output
  #              CTLFileName: the control file defining the structure of the file       
  #              command    : the command to be executed
  #
  #        defaults are: exec ref   : inExec
  #                      CTLFileName: no default as such but a genereric input will be asssumed that just creates a single 
  #                                   variable called inExec that will be 255 chars long
  #
  # NOTES: 1. Field names in a control file MUST be unique and differentiated from normal variables as they are held in the 
  #           same array
  #        2. A command may NOT be executed through 2 DOEXEC statements simultaneously 
  #           as the variables will not be separated (unless the files are managed by different control files that
  #           allocate the fields different names)
  #        3. If a command returns an empty result set the )DOEXEC section will still be processed 1 time.
  #           Variable $skelExecStatus{$execRef} will indicate the status:
  #                        File not opened = -1
  #                        File Empty      = 0
  #                        OK to read      > 0 [should actually be the sequence number of the record being read] 
  #
  # Usage: processDOEXEC(<ctl card>)
  # Returns: nothing but establishes the control variables for a loop through the output of an executed command
  # -----------------------------------------------------------

  my $currentSubroutine = 'processDOEXEC'; 
  my $lit;
  my $card = trim(shift);                                        # get the card information

  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards

    my $cnt = push (@execStack, $currentExecRef, $currentExecFile) ;      # save the current )DOEXEC execRef/execFile for later use
    displayDebug("Execref $currentExecRef has been pushed on to the stack. There are now $cnt elements on the DOEXEC stack",1, $currentSubroutine);
    
    my $posHold = 0;
    my $execRef = 'inExec';
    my $execCTLFileName = ''; 
    my $execDataFileName = 'exec_' . generateUnique() . '.txt';
    my $execCMD = '';

    if ( (substr($card,$currentLinePosition,1) eq "\"") || (substr($card,$currentLinePosition,1) eq "\'")) {                   # first character is a quote so all a command
      $execCMD = substr($card,$currentLinePosition+1,length($card)-2-$currentLinePosition)
    }
    else { # treat the first parameter as the reference literal
      $execRef = getToken($card);                           # (EXECREF) this is how this file will be referred to
      $posHold = $currentLinePosition;
      $lit = uc(getToken($card));                        # may be the literal 'USING'
      if ( $lit eq 'USING' ) { 
        $execCTLFileName = getToken($card);                 # (EXECCTLFILENAME) The file name holding the control information describing the file
        $execCMD = trim(substr($card,$currentLinePosition)) # (EXECCMD) 
      } 
      else { # no control file supplied
        $execCMD = trim(substr($card,$posHold))             # (EXECCMD) 
      }
    }
    displayDebug("Command entered ($card): $execCMD",1,$currentSubroutine);

    $cnt = push(@controlStack,($skelDOEXECCount,$skelDOFCount,$skelDOTCount,$skelSELCount));      # save counts on entry
    displayDebug("PUSHING onto stack - #entries $cnt",2,$currentSubroutine);
    displayDebug("Pushing control counts: \$skelDOEXECCount=$skelDOEXECCount,\$skelDOFCount=$skelDOFCount,\$skelDOTCount=$skelDOTCount,\$skelSELCount=$skelSELCount",2,$currentSubroutine);

    $skelDOEXECCount++;                                     # increment )DOEXEC count
   
    if ( defined($DOEXECLocation{$execRef}) ) { # the comamnd ref has already been used (and is still in use)
      displayError("execRef $execRef is already in use. Duplicate found at card number $currentSkelLine of $currentActiveSkel",$currentSubroutine);
      return;
    } 
      
    if ( uc($lit) ne 'USING' ) { # USING is missing from where it should be so just generate dummy control records (space delimited)
      if ( defined($ctlArray{$execRef}) ) {        # if it is defined then remove it
        displayDebug("Removing old cached version of ctlfile $execRef", 1, $currentSubroutine);
        $ctlLines[$ctlArray{$execRef}] = '';        # get rid of the existing control lines
        delete $ctlArray{$execRef};                 # remove the skel name referrer
      }
  
      $ctlArray{$execRef} = keys(%ctlArray);         # allocate the next array entry
      
      $ctlLines[$ctlArray{$execRef}][0]  = ',fixed,inExec,0,255';
    }
      
    # process the )DOEXEC statement and set parameters
    # generate the full file name ....
    my $skelExecCTLFullName = '';                            # Will contain the full CTL file name
    $currentExecFile = '';                           # Will contain the full Data file name
      
    # generate the Data File full name
    my $skelExecDataDir = $ENV{'SKLDATADIR'};
    if ( ! defined($skelExecDataDir) ) { $skelExecDataDir = ''; } 
    if ( $skelExecDataDir eq "" ) {                          # just use the supplied names
      if ( $OS eq "Windows") {
        $currentExecFile = 'c:\temp/' . $execDataFileName;
      }
      else {
        $currentExecFile = '/tmp/' . $execDataFileName;
      }
    }
    elsif ( substr($skelExecDataDir,-1,1) eq $dirSep  ) {    # has a terminating directory separator
      $currentExecFile = "$skelExecDataDir$execDataFileName";
    }
    else { # no separator so add one
      $currentExecFile = "$skelExecDataDir$dirSep$execDataFileName";
    }
    displayDebug("Data file will be $currentExecFile",1,$currentSubroutine);

    if ( $execCTLFileName ne '' ) { # CTL file name supplied so load it up
      # load the control cards
      if ( (uc($execCTLFileName) =~ "^INLINE\:|^INLINE\=") || ( uc($execCTLFileName) eq 'INLINE') ) {    # does the ctl file start with either INLINE: or INLINE= or is just the word INLINE
        loadInlineFileCTL($execRef);             # load the CTL file
      }
      else { # it is a real file
        # generate the CTL File full name
        my $skelExecCTLDir = $ENV{'SKLCTLDIR'};
        if ( ! defined($skelExecCTLDir) ) { $skelExecCTLDir = ''; }
        if ( $skelExecCTLDir eq "" ) {                          # just use the supplied names
          $skelExecCTLFullName = $execCTLFileName;
        }
        elsif ( substr($skelExecCTLDir,-1,1) eq $dirSep  ) {    # has a terminating directory separator
          $skelExecCTLFullName = "$skelExecCTLDir$execCTLFileName";
        }
        else { # no separator so add one
          $skelExecCTLFullName = "$skelExecCTLDir$dirSep$execCTLFileName";
        }

        displayDebug("CTL file will be $skelExecCTLFullName",1,$currentSubroutine);
        # now load the control file .....
        loadFileCTL($execRef, $skelExecCTLFullName);

      }
    }
    
    # establish the loop position for the )DOF statement
    establishDOEXECLoopPosition($execRef);                  # sort out where the looping will occur

    if ( ! defined($DOEXECLocation{$execRef}) ) {           # couldn't find a loop position ... ignore this card (errors would have been thrown)
      return ; 
    }
      
    # create the data file to be processed .....
    
    if (! open (outExec, ">",$currentExecFile) ) { 
      displayError ("Unable to open $currentExecFile\n%ERRNO",$currentSubroutine); 
    }
    else { # file has been opened for output
      if (! open (inExec, "$execCMD |") ) { 
        displayError ("Command $execCMD failed to run successfully\n$?",$currentSubroutine); 
      }
      else {
        while (<inExec>) {      # loop through the output of the command
          print outExec $_;     # save it in a file
        }
        close inExec;
      }
      close outExec;
    }    
    
    # save the current file ref (pointer to the command output)
    $currentExecRef = $execRef;
    
    if ( defined ($ctlArray{$execRef} ) ) {              # control file was loaded

      # now open the file and read in the first record ....
      if ( !open ( $skelExecHandle{$execRef}, "<", "$currentExecFile" ) ) {
        # file not found (possibly)
        displayError("Unable to open $currentExecFile.\nError: $?",$currentSubroutine);
        displayError("One pass through the loop will be performed.",$currentSubroutine);
        $skelExecStatus{$execRef} = -1                               # set flag to indicate open error
      }
      else { # The file does at least exist 
        $skelExecStatus{$execRef} = 0;                               # either it will stay 0 which will mean the file is empty or it will be incremented by readDataFileRecord
        # save the file handle
        $skelExecRecord = readDataFileRecord($skelExecHandle{$execRef}, $execRef, 'E');
        if ( defined($skelExecRecord) )  { # not EOF
          setDefinedVariablesForFile($execRef, $skelExecRecord); # Set all of the variables
        } 
        else { #EOF
          displayError("File $currentExecFile is empty. One pass through the loop will be performed.",$currentSubroutine);
          undef $DOEXECLocation{$execRef};                          # undefine the loop start pos to free it up
          undef $skelExecHandle{$execRef};                       # undefine the file handle to free it up
        }
      }
    }
    else { # control file wasn't loaded so nothing can be done
      $skelExecStatus{$currentExecRef} = -1;                     # indicate that the file couldn't be opened
    }
  }
  else {
    displayDebug("Skipped: $card",2,$currentSubroutine);
  }
  
} # end of processDOEXEC

sub processDOF {
  # -----------------------------------------------------------
  # Routine to process a )DOF control card
  # The )DOF control card is of the form:  
  #
  #        )DOF <file Ref> [<fileName> [using <CTLFileName>]]
  #     
  #        where file ref   : a reference used to isolate this open file
  #              filename   : the file to be read
  #              CTLFileName: the control file defining the structure of the file       
  #
  #        defaults are: file ref   : inFile
  #                      filename   : inFile.txt 
  #                      CTLFileName: inFile.ctl 
  #
  # NOTES: 1. Field names in a control file MUST be unique and differentiated from normal variables as they are held in the 
  #           same array
  #        2. A file may NOT be read in through 2 DOF statements simultaneously 
  #           as the variables will not be separated (unless the files are managed by different control files that
  #           allocate the fields different names)
  #        3. If a file is empty or doesn't exist the )DOF section will still be processed 1 time.
  #           Variable $skelFileStatus{$fileRef} will indicate the status:
  #                        File not opened = -1
  #                        File Empty      = 0
  #                        OK to read      > 0 [should actually be the sequence number of the record being read] 
  #
  # Usage: processDOF(<ctl card>)
  # Returns: nothing but establishes thecontrol variables for a file loop
  # -----------------------------------------------------------

  my $currentSubroutine = 'processDOF'; 
  
  my $card = shift;                                        # get the card information

  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards

    my $cnt = push (@fileStack, $currentFileRef) ;                             # save the current )DOF fileRef for later use
    displayDebug("Fileref $currentFileRef has been pushed on to the stack. There are now $cnt elements on the DOF stack",1, $currentSubroutine);

    my $fileRef = getToken($card);                           # (FILEREF) this is how this file will be referred to
    my $fileName = getToken($card);                          # (FILENAME) nameof the file to be opened
    my $lit = getToken($card);                               # should be the literal 'USING'
    my $CTLFileName = getToken($card);                       # (CTLFILENAME) The file name holding the control information describing the file

    $cnt = push(@controlStack,($skelDOEXECCount,$skelDOFCount,$skelDOTCount,$skelSELCount));      # save counts on entry
    displayDebug("PUSHING onto stack - #entries $cnt",2,$currentSubroutine);
    displayDebug("Pushing control counts: \$skelDOFCount=$skelDOFCount,\$skelDOTCount=$skelDOTCount,\$skelSELCount=$skelSELCount",2,$currentSubroutine);

    $skelDOFCount++;                                     # increment )DOF count
   
    if ( uc($lit) ne 'USING' ) { # USING is missing from where it should be
      displayError("USING literal missing it will be assumed to be the second parameter (which will now be ignored)",$currentSubroutine);
      displayError("Format of the )DOF is  )DOF [<file Ref>] [<fileName> [using <CTLFileName>]]",$currentSubroutine);
    }
      
    # set default values if necessary
    if ( $fileRef eq '' ) { $fileRef = 'inFile' };
    if ( $fileName eq '' ) { $fileName = 'inFile.txt' };
    if ( $CTLFileName eq '' ) { $CTLFileName = 'inFile.ctl' };

    if ( defined($DOFLocation{$fileRef}) ) { # the file ref has already been used (and is still in use)
      displayError("fileRef $fileRef is already in use. Duplicate found at card number $currentSkelLine of $currentActiveSkel",$currentSubroutine);
      return;
    } 
      
    # process the )DOF statement and set parameters
    # generate the full file name ....
    my $skelCTLFullName = '';                            # Will contain the full CTL file name
    my $skelDataFullName = '';                           # Will contain the full Data file name
      
    # generate the Data File full name
    my $skelDataDir = $ENV{'SKLDATADIR'};
    if ( ! defined($skelDataDir) ) { $skelDataDir = ''; } 
    if ( $skelDataDir eq "" ) {                          # just use the supplied names
      $skelDataFullName = $fileName;
    }
    elsif ( substr($skelDataDir,-1,1) eq $dirSep  ) {    # has a terminating directory separator
      $skelDataFullName = "$skelDataDir$fileName";
    }
    else { # no separator so add one
      $skelDataFullName = "$skelDataDir$dirSep$fileName";
    }

    if ( (uc($CTLFileName) =~ "^INLINE\:|^INLINE\=") || ( uc($CTLFileName) eq 'INLINE') ) {    # does the ctl file start with either INLINE: or INLINE= or is just the word INLINE
      loadInlineFileCTL($fileRef);             # load the CTL file
    }
    else { # it is a real file
      # generate the CTL File full name
      my $skelCTLDir = $ENV{'SKLCTLDIR'};
      if ( ! defined($skelCTLDir) ) { $skelCTLDir = ''; } 
      if ( $skelCTLDir eq "" ) {                          # just use the supplied names
        $skelCTLFullName = $CTLFileName;
      }
      elsif ( substr($skelCTLDir,-1,1) eq $dirSep  ) {    # has a terminating directory separator
        $skelCTLFullName = "$skelCTLDir$CTLFileName";
      }
      else { # no separator so add one
        $skelCTLFullName = "$skelCTLDir$dirSep$CTLFileName";
      }
  
      displayDebug("Data file will be $skelDataFullName, CTL file will be $skelCTLFullName",1,$currentSubroutine);
      # now load the control file .....
      loadFileCTL($fileRef, $skelCTLFullName);
    
    }

    # establish the loop position for the )DOF statement
    establishDOFLoopPosition($fileRef);                  # sort out where the looping will occur

    if ( ! defined($DOFLocation{$fileRef}) ) {           # couldn't find a loop position ... ignore this card (errors would have been thrown)
      return ;
    }

    # save the current file ref
    $currentFileRef = $fileRef;
      
    if ( defined ($ctlArray{$fileRef} ) ) {              # control file was loaded
  
      # now open the file and read in the first record ....
      if ( !open ( $skelFileHandle{$fileRef}, "<", "$skelDataFullName" ) ) {
        # file not found (possibly)
        displayError("Unable to open $skelDataFullName.\nError: $?",$currentSubroutine);
        displayError("One pass through the loop will be performed.",$currentSubroutine);
        $skelFileStatus{$fileRef} = -1                               # set flag to indicate open error
      }
      else { # The file does at least exist 
        getFileInformation($skelDataFullName, 'DOF');                # get file information
        $skelFileStatus{$fileRef} = 0;                               # either it will stay 0 which will mean the file is empty or it will be incremented by readDataFileRecord
        # save the file handle
        $skelFileRecord = readDataFileRecord($skelFileHandle{$fileRef}, $fileRef, 'F');
        if ( defined($skelFileRecord) )  { # not EOF
          setDefinedVariablesForFile($fileRef, $skelFileRecord); # Set all of the variables
        } #EOF
        else {
          displayError("File $skelFileRecord is empty. One pass through the loop will be performed.",$currentSubroutine);
          undef $DOFLocation{$fileRef};                          # undefine the loop start pos to free it up
          undef $skelFileHandle{$fileRef};                       # undefine the file handle to free it up
        }
      }
    }
    else { # control file wasn't loaded so nothing can be done
      $skelFileStatus{$currentFileRef} = -1;                     # indicate that the file couldn't be opened
    }
  }
  else {
    displayDebug("Skipped: $card",2,$currentSubroutine);
  }

} # end of processDOF 

sub processENDDOEXEC {
  # -----------------------------------------------------------
  # Routine to finish a )DOEXEC loop 
  # The )ENDDOEXEC control card is of the form:  
  #
  #        )ENDDOEXEC 
  #
  # This card terminates the LAST )DOEXEC statement executed
  #
  # Usage: processENDDOEXEC
  # Returns: nothing nut will alter some control variables
  # -----------------------------------------------------------

  my $currentSubroutine = 'processENDDOEXEC'; 
  my $card = shift;                                                         # establish the card being processed

  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards      
  
    if ( $lastFlagSet ) {                                      # )LAST has sent processing this way so treat as end of file containing exec output
      displayDebug(")LAST statement has skipped to )ENDDOEXEC.",2,$currentSubroutine);
      undef $skelFileStatus{$currentExecRef};
      if ( defined( $DOEXECLocation{$currentExecRef}) ) { undef $DOEXECLocation{$currentExecRef}; }
      if ( defined( $skelExecHandle{$currentExecRef}) ) { undef $skelExecHandle{$currentExecRef}; }
      if ( defined($ctlArray{$currentExecRef}) ) { undef $ctlLines[$ctlArray{$currentExecRef}]; } # clear out the array holding the control cards
      undef $skelExecHandle{$currentExecRef} ;                 # clear out the file handle for the file
      undef $skelExecStatus{$currentExecRef} ;                 # clear out the file status
      delete $ctlArray{$currentExecRef};                       # clear out the control file reference number
      $currentExecFile = pop(@execStack);                      # reinstate the old file name 
      my $removed = unlink($currentExecFile);
      close $currentExecRef;                                   # close the file holding the output
      $currentExecRef = pop(@execStack);                       # reinstate the old fileRef

      $skelDOEXECCount--;                                           # decrement )DOF count
      displayDebug("Processed )ENDDOEXEC. DOEXEC Count = $skelDOEXECCount",1,$currentSubroutine);
      verifyControlCounts();
      $lastFlagSet = 0;
    }
    elsif ( $skelExecStatus{$currentExecRef} == -1) {            # the file was unable to be opened so treat as end of file
      displayDebug("File $currentExecRef  wasn't opened so treated as EOF.",2,$currentSubroutine);
      undef $skelFileStatus{$currentExecRef};
      if ( defined( $DOEXECLocation{$currentExecRef}) ) { undef $DOEXECLocation{$currentExecRef}; }
      if ( defined( $skelExecHandle{$currentExecRef}) ) { undef $skelExecHandle{$currentExecRef}; }
      if ( defined($ctlArray{$currentExecRef}) ) { undef $ctlLines[$ctlArray{$currentExecRef}]; } # clear out the array holding the control cards
      undef $skelExecHandle{$currentExecRef} ;                 # clear out the file handle for the file
      undef $skelExecStatus{$currentExecRef} ;                 # clear out the file status
      delete $ctlArray{$currentExecRef};                       # clear out the control file reference number
      $currentExecFile = pop(@execStack);                      # reinstate the old file name 
      my $removed = unlink($currentExecFile);
      close $currentExecRef;                                   # close the file holding the output
      $currentExecRef = pop(@execStack);                       # reinstate the old fileRef

      $skelDOEXECCount--;                                           # decrement )DOF count
      displayDebug("Processed )ENDDOEXEC. DOEXEC Count = $skelDOEXECCount",1,$currentSubroutine);
      verifyControlCounts();
    
    }
    elsif ( $skelExecStatus{$currentExecRef} == 0 ) {          # file was empty so just treat as end of file
      displayDebug("File $currentExecRef was empty.",2,$currentSubroutine);
      undef $skelExecStatus{$currentExecRef};
      if ( defined( $DOEXECLocation{$currentExecRef}) )   { undef $DOEXECLocation{$currentExecRef}; }
      if ( defined( $skelExecHandle{$currentExecRef}) )   { undef $skelExecHandle{$currentExecRef}; }
      undef $skelExecHandle{$currentExecRef} ;                 # clear out the file handle for the file
      undef $skelExecStatus{$currentExecRef} ;                 # clear out the file status
      undef $ctlLines[$ctlArray{$currentExecRef}];             # clear out the array holding the control cards
      delete $ctlArray{$currentExecRef};                       # clear out the control file reference number
      $currentExecFile = pop(@execStack);                      # reinstate the old file name 
      my $removed = unlink($currentExecFile);
      close $currentExecRef;                                   # close the file holding the output
      $currentExecRef = pop(@execStack);                       # reinstate the old fileRef

      $skelDOEXECCount--;                                           # decrement )DOF count
      displayDebug("Processed )ENDDOEXEC. DOEXEC Count = $skelDOEXECCount",1,$currentSubroutine);
      verifyControlCounts();
    
    }
    else { # file was opened and used the last time data was read from it ..... try and read more data
      displayDebug("File $currentExecRef  being read",2,$currentSubroutine);
      my $skelExecRecord = readDataFileRecord($skelExecHandle{$currentExecRef}, $currentExecRef, 'E');
      if ( defined($skelExecRecord) ) { # not EOF so process the record (otherwise just let it flow through)
        displayDebug("Record returned from file $currentExecRef ",2,$currentSubroutine);
        setDefinedVariablesForFile($currentExecRef, $skelExecRecord);            # Set all of the variables
        $currentSkelLine = $DOEXECLocation{$currentExecRef} ;
      }
      else { # end of file so close up shop
        displayDebug("No more records in $currentExecRef",2,$currentSubroutine);
        undef $skelExecStatus{$currentExecRef};
        if ( defined( $DOEXECLocation{$currentExecRef}) ) { undef $DOEXECLocation{$currentExecRef}; }
        if ( defined( $skelExecHandle{$currentExecRef}) ) { undef $skelExecHandle{$currentExecRef}; }
        undef $skelExecHandle{$currentExecRef} ;                 # clear out the file handle for the file
        undef $skelExecStatus{$currentExecRef} ;                 # clear out the file status
        undef $ctlLines[$ctlArray{$currentExecRef}];             # clear out the array holding the control cards
        delete $ctlArray{$currentExecRef};                       # clear out the control file reference number
        close $currentExecRef;                                   # close the file holding the output
        $currentExecFile = pop(@execStack);                      # reinstate the old file name 
        my $removed = unlink($currentExecFile);
        $currentExecRef = pop(@execStack);                       # reinstate the old fileRef
  
        $skelDOEXECCount--;                                           # decrement )DOF count
        displayDebug("Processed )ENDDOEXEC. DOEXEC Count = $skelDOEXECCount",1,$currentSubroutine);
        verifyControlCounts();
    
      }
    }
  }
  else {
    displayDebug("Skipped: $card",2,$currentSubroutine);
  }      

} # end of processENDDOEXEC

sub processENDDOF {
  # -----------------------------------------------------------
  # Routine to finish a )DOF loop 
  # The )ENDDOF control card is of the form:  
  #
  #        )ENDDOF 
  #
  # This card terminates the LAST )DOF statement executed
  #
  # Usage: processENDDOF
  # Returns: nothing nut will alter some control variables
  # -----------------------------------------------------------

  my $currentSubroutine = 'processENDDOF'; 
  my $card = shift;                                                         # establish the card being processed

  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards      
  
    if ( $lastFlagSet ) {                                      # )LAST has sent processing this way so treat as end of file
      displayDebug(")LAST statement has skipped to )ENDDOF.",2,$currentSubroutine);
      undef $skelFileStatus{$currentFileRef} ;                 # clear out the file status
      if ( defined( $DOFLocation{$currentFileRef}) )    { undef $DOFLocation{$currentFileRef}; }
      if ( defined( $skelFileHandle{$currentFileRef}) ) { undef $skelFileHandle{$currentFileRef}; } # clear out the file handle for the file
      undef $ctlLines[$ctlArray{$currentFileRef}];             # clear out the array holding the control cards
      delete $ctlArray{$currentFileRef};                       # clear out the control file reference number
      close $currentFileRef;                                   # close the file
      $currentFileRef = pop(@fileStack);                       # reinstate the old fileRef

      $skelDOFCount--;                                           # decrement )DOF count
      displayDebug("Processed )ENDDOF. DOF Count = $skelDOFCount",1,$currentSubroutine);
      verifyControlCounts();
      $lastFlagSet = 0;    
    }
    elsif ( $skelFileStatus{$currentFileRef} == -1) {            # the file was unable to be opened so treat as end of file
      displayDebug("File $currentFileRef  wasn't opened so treated as EOF.",2,$currentSubroutine);
      undef $skelFileStatus{$currentFileRef};                                                         # clear out the file status
      if ( defined( $DOFLocation{$currentFileRef}) )    { undef $DOFLocation{$currentFileRef}; }
      if ( defined( $skelFileHandle{$currentFileRef}) ) { undef $skelFileHandle{$currentFileRef}; }   # clear out the file handle for the file
      if ( defined($ctlArray{$currentFileRef}) ) { 
        undef $ctlLines[$ctlArray{$currentFileRef}];           # clear out the array holding the control cards
      }
      delete $ctlArray{$currentFileRef};                       # clear out the control file reference number
      close $currentFileRef;                                   # close the file
      $currentFileRef = pop(@fileStack);                       # reinstate the old fileRef

      $skelDOFCount--;                                           # decrement )DOF count
      displayDebug("Processed )ENDDOF. DOF Count = $skelDOFCount",1,$currentSubroutine);
      verifyControlCounts();
    
    } # 
    elsif ( $skelFileStatus{$currentFileRef} == 0 ) {          # file was empty so just treat as end of file
      displayDebug("File $currentFileRef was empty.",2,$currentSubroutine);
      undef $skelFileStatus{$currentFileRef} ;                 # clear out the file status
      if ( defined( $DOFLocation{$currentFileRef}) )    { undef $DOFLocation{$currentFileRef}; }
      if ( defined( $skelFileHandle{$currentFileRef}) ) { undef $skelFileHandle{$currentFileRef}; } # clear out the file handle for the file
      undef $ctlLines[$ctlArray{$currentFileRef}];             # clear out the array holding the control cards
      delete $ctlArray{$currentFileRef};                       # clear out the control file reference number
      close $currentFileRef;                                   # close the file
      $currentFileRef = pop(@fileStack);                       # reinstate the old fileRef

      $skelDOFCount--;                                           # decrement )DOF count
      displayDebug("Processed )ENDDOF. DOF Count = $skelDOFCount",1,$currentSubroutine);
      verifyControlCounts();
    
    }
    else { # file was opened and used the last time data was read from it ..... try and read more data
      displayDebug("File $currentFileRef  being read",2,$currentSubroutine);
      my $skelFileRecord = readDataFileRecord($skelFileHandle{$currentFileRef}, $currentFileRef, 'F');
      if ( defined($skelFileRecord) ) { # not EOF so process the record (otherwise just let it flow through)
        displayDebug("Record returned from file $currentFileRef ",2,$currentSubroutine);
        setDefinedVariablesForFile($currentFileRef, $skelFileRecord);            # Set all of the variables
        $currentSkelLine = $DOFLocation{$currentFileRef} ;
      }
      else { # end of file so close up shop
        displayDebug("No more records in $currentFileRef",2,$currentSubroutine);
        undef $skelFileStatus{$currentFileRef} ;                 # clear out the file status
        if ( defined( $DOFLocation{$currentFileRef}) )    { undef $DOFLocation{$currentFileRef}; }
        if ( defined( $skelFileHandle{$currentFileRef}) ) { undef $skelFileHandle{$currentFileRef}; } # clear out the file handle for the file
        undef $ctlLines[$ctlArray{$currentFileRef}];             # clear out the array holding the control cards
        delete $ctlArray{$currentFileRef};                       # clear out the control file reference number
        close $currentFileRef;                                   # close the file
        $currentFileRef = pop(@fileStack);                       # reinstate the old fileRef
  
        $skelDOFCount--;                                           # decrement )DOF count
        displayDebug("Processed )ENDDOF. DOF Count = $skelDOFCount",1,$currentSubroutine);
        verifyControlCounts();
    
      }
    }
  }
  else {
    displayDebug("Skipped: $card",2,$currentSubroutine);
  }      

} # end of processENDDOF 

sub processDISNOTE {
  # -----------------------------------------------------------
  # Routine to 
  #
  # Usage:
  # Returns:
  # -----------------------------------------------------------

  my $currentSubroutine = 'processDISNOTE'; 
  my $card = shift;                                                         # establish the card being processed
  
  displayNote(substr($card,9));                                             # display the message

} # end of processDISNOTE 

sub processSETLEFTJUSTTAB {
  # -----------------------------------------------------------
  # Routine to set the left justify tab stop (the value defaults to !)
  #
  # Usage:
  # Returns:
  # -----------------------------------------------------------

  my $currentSubroutine = 'processSETLEFTJUSTTAB'; 
  my $card = shift;                                                         # establish the card being processed
  
  if ( trim($card) eq '' ) { # no character on statement so just display the character in both debug and output
    displayDebug("No character set on )SETLEFTJUSTTAB so displaying value: $leftJustTab",1,$currentSubroutine);
    outputLineNT("No character set on )SETLEFTJUSTTAB so displaying value: $leftJustTab");
  }
  else {
    $leftJustTab = substr(trim($card),0,1);    # set the character
  }

} # end of processSETLEFTJUSTTAB

sub processSETRIGHTJUSTTAB {
  # -----------------------------------------------------------
  # Routine to set the right justify tab stop (the value defaults to ~)
  #
  # Usage:
  # Returns:
  # -----------------------------------------------------------

  my $currentSubroutine = 'processSETRIGHTJUSTTAB'; 
  my $card = shift;                                                         # establish the card being processed
  
  if ( trim($card) eq '' ) { # no character on statement so just display the character in both debug and output
    displayDebug("No character set on )SETRIGHTJUSTTAB so displaying value: $rightJustTab",1,$currentSubroutine);
    outputLineNT("No character set on )SETRIGHTJUSTTAB so displaying value: $rightJustTab");
  }
  else {
    $rightJustTab = substr(trim($card),0,1);    # set the character
  }

} # end of processSETLEFTJUSTTAB

sub clearVariableScope {
  # -----------------------------------------------------------
  # Routine clear out all variables in a specified scope (global will never be processed)
  #
  # Usage: clearVariableScope(<scope>)
  # Returns: Nothing, just empies the array
  # -----------------------------------------------------------

  my $currentSubroutine = 'clearVariableScope'; 
  my $scope = shift;                                 # establish the scope being processed
  
  if ( $scope eq 'global' ) { return; }              # dont touch global variables

  # check that the scope is not in use  
  for ( my $i = $#scopeStack; $i >= 0 ; $i-- ) { # look back through the scope stack to see if the variable can be found
    if ( $scopeStack[$i] eq $scope ) {  # the scope is stil in use
      # scope is still in use ina skeleton somewhere so no variables can be removed
      displayDebug("Scope $scope is still in use and can not yet be removed",1,$currentSubroutine);
      return;
    }
  }  
  
  foreach my $b (keys %{ $skelVarArray{$scope} } ) {
    delete $skelVarArray{$scope}{$b};
  }
  
} # end of clearVariableScope

sub processIMBED {
  # -----------------------------------------------------------
  # Routine to load upa new skeleton if necessary and start processing it
  #
  # Usage: processIMBED(<IMBED card>)
  # Returns: Nothing, just sets loads the skeleton and set some 
  #          processing flags
  # -----------------------------------------------------------

  my $currentSubroutine = 'processIMBED'; 
  my $card = shift;                                 # establish the card being processed
  my $scope = getToken($card);
  my $newSkel = ''; 

  # establish debugging levels as necessary
  $calcDebugLevel = $skelDebugLevel;
  $calcDebugModules = $skelDebugModules;

  if ( $currentLinePosition <= length($card) ) { # there looks to be a 2nd parameter
    $newSkel = evaluateInfix(trim(substr($card,$currentLinePosition)));       # set the debug level to the evaluated string provided on the )TRACE card
  }    
  if ( $newSkel eq '' ) { # no variable scope was supplied (we assume)
    $newSkel = evaluateInfix(trim(trim(substr($card,7))));
    $scope = $currentScope; # default the scope to the current scope
  }
  if ( trim($newSkel) eq '' ) { return; }                                   # if the skeleton evaluates to blank then just ignore the statement
  $scope = lc($scope);                         # scope is case insensitive
  displayDebug("IMBED of skeleton $newSkel being processed. Variable scope set to $scope",1,$currentSubroutine);
  loadSkel($scope,$newSkel);                                                       # load the skeleton and set the control variables

} # end of processIMBED 

sub processTRACE {
  # -----------------------------------------------------------
  # Routine to set the trace level to a certain value
  #
  # Usage: )TRACE <string>
  # Returns: nothing, but evaluates the passed string and assigns the debug level to taht value
  # -----------------------------------------------------------

  my $currentSubroutine = 'processTRACE'; 
  my $card = shift;                                                         # establish the card being processed
  
  my $depth = push(@traceLevelStack,$skelDebugLevel);                       # save off the current level
  $skelDebugLevel = evaluateInfix(trim(substr($card,7)));                   # set the debug level to the evaluated string provided on the )TRACE card
  setVariable('traceLevel',$skelDebugLevel);                                # update the internal variable
  displayDebug("Trace level set to $skelDebugLevel",0,$currentSubroutine);

} # end of processTRACE 

sub processDECIMALPLACES {
  # -----------------------------------------------------------
  # Routine to set the decimal places value 
  #
  # Usage: )DECIMALPLACES [number of decimal places]
  # Returns: nothing, but sets the cursorDecimalPlaces value 
  # -----------------------------------------------------------

  my $currentSubroutine = 'processDECIMALPLACES';
  my $card = shift;                                                         # establish the card being processed
  my $precision = getToken($card);

  if ( $precision eq '' ) {
    $cursorDecimalPlaces = -1;
  }
  else {
    if (isNumeric($precision)) { # parameter on the card is numeric
      $cursorDecimalPlaces = int($precision);
    }
    else {
      displayError ("Precision $precision is not numeric on the supplied )DECIMALPLACES control card");
    }
  }

  displayDebug("cursorDecimalPlaces set to $cursorDecimalPlaces",0,$currentSubroutine);

} # end of processDECIMALPLACES 

sub processTRUNCZEROES {
  # -----------------------------------------------------------
  # Routine to set the truncatetrailingzeroes flag
  #
  # Usage: )TRUNCZEROES [number of decimal places]
  # Returns: nothing, but sets the truncatetrailingzeroes flag
  # -----------------------------------------------------------

  my $currentSubroutine = 'processTRUNCZEROES'; 
  my $card = shift;                                                         # establish the card being processed
  my $precision = getToken($card);
  
  $truncateTrailingZeroes = 1;

  if ( $precision ne '' ) {
    if (isNumeric($precision)) { # parameter on the card is numeric
      $cursorDecimalPlaces = int($precision);
      displayDebug("cursorDecimalPlaces set to $cursorDecimalPlaces",2,$currentSubroutine);
    }
    else {
      displayError ("Precision $precision is not numeric on the supplied )TRUNCZEROES control card");
    }
  }
  
  displayDebug("truncateTrailingZeroes flag set",2,$currentSubroutine);

} # end of processTRUNCZEROES

sub processLEAVEZEROES {
  # -----------------------------------------------------------
  # Routine to reset the truncatetrailingzeroes flag
  #
  # Usage: )LEAVEZEROES
  # Returns: nothing, but resets the truncatetrailingzeroes flag
  # -----------------------------------------------------------

  my $currentSubroutine = 'processLEAVEZEROES'; 
  
  $truncateTrailingZeroes = 0;
  displayDebug("truncateTrailingZeroes flag reset",0,$currentSubroutine);

} # end of processTRUNCZEROES

sub processTRACEOFF {
  # -----------------------------------------------------------
  # Routine to revert the trace level to the level at the time the last )TRACE was found
  #
  # Usage: )TRACEOFF
  # Returns: nothing but restores the trace level to the previous value
  # -----------------------------------------------------------

  my $currentSubroutine = 'processTRACEOFF'; 

  if ($#traceLevelStack == -1) {                                            # nothing on the stack 
    $skelDebugLevel = 0                                                     # just set the debug level to zero
  }
  else {                                                                    # otherwise restore it from the stack
    $skelDebugLevel = pop(@traceLevelStack);                                # restore the last debug level
    displayDebug("Trace level restored to $skelDebugLevel",0,$currentSubroutine);
  }
  setVariable('traceLevel',$skelDebugLevel);                                # update the internal variable

} # end of processTRACEOFF 

sub processDEBUG {
  # -----------------------------------------------------------
  # Routine to dump out internal tables
  #
  # Usage: processDEBUG(<control card>)
  # Returns: prints out the following internal stuff ...
  #     Variables
  #     Cursors
  # -----------------------------------------------------------
  
  my $card = shift;
  my $currentSubroutine = 'processDEBUG';
  
  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) {     # not skipping cards
      displayDebug("DEBUG information listing:",0,$currentSubroutine);
      displayDebug("Defined Variables:",0,$currentSubroutine);                # zero will mean it always prints
      # print out some internal variables
      displayDebug("Variable \$outputMode has a value of $outputMode",0,$currentSubroutine);
      # print out the scopes currently in play
      displayDebug("Current Scope: $currentScope",0,$currentSubroutine);
      for ( my $i = $#scopeStack; $i >= 0 ; $i-- ) { # look back through the scope stack to see if the variable can be found
        displayDebug("Entry $i, variable scope=$scopeStack[$i]",0,$currentSubroutine);
      }  
      # print out some global variables 
      foreach my $dispScope (sort by_key keys %skelVarArray) { 
        foreach my $dispVar (sort by_key keys %{ $skelVarArray{$dispScope} } ) { 
          displayDebug("$dispScope: $dispVar = $skelVarArray{$dispScope}{$dispVar}",0,$currentSubroutine);
        }
      }
      
      displayDebug("Established Database Connections:",0,$currentSubroutine); # zero will mean it always prints
      foreach my $dispVar (sort by_key keys %skelConnection) {
        displayDebug("$dispVar",0,$currentSubroutine);
      }
      displayDebug("Established Cursors:",0,$currentSubroutine);              # zero will mean it always prints
      foreach my $dispVar (sort by_key keys %skelCursor) { 
        displayDebug("$dispVar",0,$currentSubroutine);
      }
      displayDebug("Defined Tab Marks:",0,$currentSubroutine);              # zero will mean it always prints
      for ( my $i = 0 ; $i <= $#tabEntries ; $i ++ ) { 
        displayDebug("Tab $i: $tabEntries[$i]",0,$currentSubroutine); 
      }
      displayDebug("Control Variables:",0,$currentSubroutine);              # zero will mean it always prints
      displayDebug("DOT Stack Count: $skelDOTCount",0,$currentSubroutine); 
      displayDebug("DOF Stack Count: $skelDOFCount",0,$currentSubroutine); 
      displayDebug("SEL Stack Count: $skelSELCount",0,$currentSubroutine); 
      displayDebug("DOT Resume level: $skelDOT_resumeLevel",0,$currentSubroutine); 
      displayDebug("SEL Resume level: $skelSEL_resumeLevel",0,$currentSubroutine); 
      displayDebug("DOT skip cards flag: $skelDOTSkipCards",0,$currentSubroutine); 
      displayDebug("SEL skip cards flag: $skelSelSkipCards",0,$currentSubroutine); 
      displayDebug("SEL goto ENDSEL flag: $skelGotoENDSEL",0,$currentSubroutine); 
    }
    else {
      displayDebug("Skipped: $card",2,$currentSubroutine,$currentSubroutine);
    }
} # end of processDEBUG

sub processSKELVERS {
  # -----------------------------------------------------------
  # Routine to process the SKELVERS statemnent. The format of the statement is:
  #
  # )SKELVERS  $Id: processSkeleton.pm,v 1.127 2018/12/14 04:09:41 db2admin Exp db2admin $
  #
  # Usage: processVERSION(<control card>)
  # Returns: sets the internal variable skelVers
  # -----------------------------------------------------------

  my $card = shift;
  my $currentSubroutine = 'processSKELVERS';
  my $ID = trim(substr($card,9));
  my @V = split(/ /,$ID);
  my $nameStr=$V[1];
  my @N = split(",",$nameStr);
  if ( defined($V[4]) ) { # the version has been supplied properly
    setVariable("skelVers", "$N[0] ($V[2])  Last Changed on $V[3] $V[4] (UTC)")
  }

} # end of processSKELVERS

sub processVERSION {
  # -----------------------------------------------------------
  # Routine to display the version numbers for all modules
  #
  # Usage: processVERSION(<control card>)
  # Returns: prints out the version numbers of:
  #               current Skeleton Version (if defined)
  #               processSkeleton.pm
  #               calculator.pm
  #               commonFunctions.pm
  # -----------------------------------------------------------

  my $card = shift;
  my $currentSubroutine = 'processVERSION';

  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) {     # not skipping cards

    my $calcVers = calcVersion();
    my $commFuncVers = commonVersion();
    my $skelVers = skelVersion();

    if ( $outputMode eq "HTTP" ) { # pushing it out to a web front end
      outputLine("<BR>processSkeleton Version: $skelVers<BR>");
      outputLine("calculator Version: $calcVers<BR>");
      outputLine("commonFunction Version: $commFuncVers<BR>");
      if ( defined(getVariable('skelVers'))) { 
        outputLine("Current Skeleton Version: " . getVariable('skelVers') . "<BR>");
      }
    }
    else {
      outputLine("\nprocessSkeleton Version: $skelVers");
      outputLine("calculator Version: $calcVers");
      outputLine("commonFunction Version: $commFuncVers");
      if ( defined(getVariable('skelVers'))) { 
        outputLine("Current Skeleton Version: " . getVariable('skelVers'));
      }
    }

  }
  else {
    displayDebug("Skipped: $card",2,$currentSubroutine,$currentSubroutine);
  }
}

sub processLOGOFF { 
  # -----------------------------------------------------------
  # Routine to process the )LOGOFF card
  # a )LOGOFF is of the form:  )LOGOFF <Connection Reference> 
  # where:
  #     Connection Reference: A literal that this connection will be referred to as
  #
  # Usage: processLOGOFF(<control card>)
  # Returns: closes off a database connection
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processLOGOFF';
  my $card = shift;                               # get the control card being processed
  my $j;
  
  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
    my $DBConnection = getToken($card);                 # Literal that defines the connection to close
    
    if ( ! defined($skelConnection{$DBConnection}) ) { #  Connection not found
      displayError("Connection $DBConnection not found so )LOGOFF card ignored");
      return;
    }
    # Connection should be closed
    $skelConnection{$DBConnection}->disconnect;     # Close the DB connection

    if ( defined($skelConnection{$DBConnection}->errstr) ) {
      displayError("Disconnect Error: $skelConnection{$DBConnection}->errstr",$currentSubroutine);
    }
    elsif ( defined($DBI::errstr) ) {
      if ( $DBI::errstr ne '' ) {
        displayError ("Disconnect Error: $DBI::errstr",$currentSubroutine);
      }
    }
    else {
      delete $skelConnection{$DBConnection};    # remove the connection reference
    }

    displayDebug("Connection $DBConnection has now been closed",2,$currentSubroutine);
  }
  else {
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2);
  }  

}

sub processLOGON { 
  # -----------------------------------------------------------
  # Routine to process the )LOGON card
  # a )LOGON is of the form:  )LOGON <Connection Reference> <DBTYPE> <DBUser> <DBPassword> <DBName> <optional connection string>
  # where:
  #     Connection Reference: A literal that this connection will be referred to as
  #     DBTYPE      :  DBI module to use for the connection i.e. DB2 , ODBC, etc
  #     DBUser      :  User to connect as (If PROMPT then user will be prompted for)
  #     DBPassword  :  Password that will be used (If PROMPT then password will be prompted for)
  #     DBName      :  Name of the database to connect to 
  #     Connection String    : Not sure what this will be used for
  #
  # Usage: processLOGON(<control card>)
  # Returns: establishes a connection to the database in a global variable
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'processLOGON';
  
  my $card = shift;     # get the card information
  my $connectionString;
  
  displayDebug("\$skelSelSkipCards=$skelSelSkipCards, \$skelDOTSkipCards=$skelDOTSkipCards",2,$currentSubroutine);
  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
    # Process the )LOGON Card
    $skelCurrentConnection = getToken($card);          # (connRef) Literal that )DOT will refer to
    my $DBType = getToken($card);                      # (DBType) The PERL DBI database type (i.e. DB2)
    my $DBUser = getToken($card);                      # (User) The user that will be used for the connection
    my $DBPwd = getToken($card);                       # (Password) The password that will be used for the connection
    my $DBName = getToken($card);                      # (DBName) The database name that will be connected to
    if ( $currentLinePosition < length($card) ) {
      $connectionString = trim(substr($card,$currentLinePosition));  # (<connection string>) The database string that will be used (optional) 
    }
    else { # no extra stuff
      $connectionString = '';
    }
 
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
      displayDebug("DBPwd=$DBPwd so prompting for input",2,$currentSubroutine);
      my $x = <STDIN>;
      system('stty','echo');
      print "\n";
      chomp $x;
      if ( trim($x) ne "" ) {
        displayDebug("Password set to $x",2,$currentSubroutine);
        $DBPwd = $x;
      }
    }

    displayDebug("\[$skelCurrentConnection\] Connecting to $DBName with user $DBUser and password $DBPwd. The Connection will be made with the $DBType PerlDBI driver",2,$currentSubroutine);
      
    if ( defined($skelConnection{$skelCurrentConnection}) ) { # the connection for $skelCurrentConnection has already been made
      displayError ("The connection for $skelCurrentConnection has already been made. Perhaps a )LOGOFF has been missed. This card has been ignored:\n$card",$currentSubroutine);
    }
    else { # all ok to proceed ....
      if ( $skelConnection{$skelCurrentConnection} = DBI->connect ("DBI:$DBType:$DBName", "$DBUser", "$DBPwd") ) { # A returned value means that all is OK
        $skelConnection{$skelCurrentConnection}->{LongReadLen} = 0; # dont ever bring back data automatically for long fields [only used with BLOB_READ] 
        displayDebug("Connection to $DBName using $DBType and user $DBUser was completed successfully",2,$currentSubroutine);
        # ---------  if blob_read doesn't exist ------------------------------
        #$skelConnection{$skelCurrentConnection}->{LongReadLen} = 5000; # limits BLOB reads to 5000 bytes
        #$skelConnection{$skelCurrentConnection}->{ongTruncOk} = 1; # ignore truncation and dont throw an error
        # --------------------------------------------------------------------
      }
      else { # open failed for some reason
        displayError("Connection to $DBName failed with error $DBI::errstr");
      }
    }
  }
  else {
    displayDebug("Skipped: $card, Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
  
} # end of processLOGON

sub processControlCard {
  # -----------------------------------------------------------
  # Routine to process a skeleton control card 
  #
  # Usage: processControlCard(<skeleton line to process>)
  # Returns: nothing (just does what the control acrd directs it to)
  # ----------------------------------------------------------- 

  my $currentSubroutine = 'processControlCard'; 

  my $card = shift; # get the line to process - will be $skelLines[$skelArray{$currentActiveSkel}][$currentLinePosition]

  # check to see if the control card is a )FUNC statement so that the variable can be saved
  $currentVariable = '';
  $currentLinePosition = 0;
  my $skelCardType = uc(getToken($card));
  if ( $skelCardType eq ')FUNC' ) { # the statement is a )FUNC statement 
    # this processing needs to be done here before any variable substitution
    if ( $card !~ /=/ ) { # doesn't contain an = sign
      my $a = getToken($card); # get the function name
      if ( " FORMATSQL GDATE JDATE " !~ $a ) { # the function isn't one of FormatSQL, GDate or JDate
        $a = getToken($card); # get the first parameter (this will be the name of the variable to be updated (with the colon)
        if ( $a =~ /^\:/ ) { # ensure first character is a colon
          $currentVariable = substr($a, 1); # lose the first character (which will be a :)
        }
      }
    }
  }
  elsif ( $skelCardType eq ')CELLSTYLE' ) { # the statement is a )CELLSTYLE statement 
    # pre-emptive processing of this card to avoid the variable substitution
    $currentLinePosition = 0;
    processCELLSTYLE(substr($card,11));
    return;
  }
  elsif ( $skelCardType eq ')ROWSTYLE' ) { # the statement is a )ROWSTYLE statement 
    # pre-emptive processing of this card to avoid the variable substitution
    $currentLinePosition = 0;
    processROWSTYLE(substr($card,10));
    return;
  }
  elsif ( $skelCardType eq ')SELECTCOND' ) { # the statement is a )SELECTCOND statement 
    # pre-emptive processing of this card to avoid the variable substitution
    $selectCond = trim(substr($card . " ",11));
    return;
  }
     
  displayDebug("Control Card Processing Started - $card",2,$currentSubroutine);
  $card = substituteVariables($card); 
  displayDebug(">>> Card after substitution: $card",1,$currentSubroutine);
  $currentLinePosition = 0;
  $skelCardType = uc(getToken($card));
  displayDebug("Control token: $skelCardType",2,$currentSubroutine);

  if ( ($skelCardType eq ")TAB") || ($skelCardType eq ")TB" )  ) {   # TAB control card - set tab stops
    processTAB($card);
  }
  elsif ( $skelCardType eq ")RULER" ) {    # RULER control card - displays character ruler
    if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
      outputLine("....+....1....+....2....+....3....+....4....+....5....+....6....+....7....+....8....+....9....+....0....+....1....+....2....+....3....+....4....+....5");
    }
    else {
      displayDebug("Skipped: $card",2,$currentSubroutine);
    }
  }
  elsif ( $skelCardType eq ")SET" ) {      # SET control card - assign a value to a skeleton variable (do any computations before assignment)
    processSET($card);
  }
  elsif ( ($skelCardType eq ")ASET" ) || ($skelCardType eq ")ASSIGN" ) ) {     # ASET/ASSIGN control card - assign a value to a skeleton variable (do NO computation)
    processASET($card);
  }
  elsif ( $skelCardType eq ")LOGOFF" ) {   # LOGOFF control Card - Close a connection to a database - of the form )LOGOFF connRef
    processLOGOFF($card);
  }
  elsif ( $skelCardType eq ")LOGON" ) {    # LOGON control Card - Open a connection to a database - of the form )LOGON connRef DBType [User|PROMPT] [Password|PROMPT] DBName <connection String>
    processLOGON($card);
  }
  elsif ( $skelCardType eq ")DOT" ) {      # DOT COntrol Card - read in a table - of the form )DOT connRef tabRef Table <where clause excluding WHERE>
    processDOT($card);
  }
  elsif ( $skelCardType eq ")XDOT" ) {     # XDOT Control Card - read in a table - of the form )XDOT connRef tabRef <SQL Statement>
    processXDOT($card);  
  }
  elsif ( $skelCardType eq ")FTAB" ) {     # FTAB Control Card - generate a formatted dump of a table
    processFTAB($card);
  }
  elsif ( $skelCardType eq ")CTAB" ) {     # CTAB Control Card - generate a formatted input table with check boxes
    processCTAB($card);
  }
  elsif ( $skelCardType eq ")SBOX" ) {     # SBOX Control Card - generate a formatted input table with check boxes
    processSBOX($card);
  }
  elsif ( ($skelCardType eq ")LAST" ) || ($skelCardType eq ")LEAVE" ) ) {     # LAST Control Card - skip to the end of the loop
    processLAST($skelCardType);
  }
  elsif ( $skelCardType eq ")NEXT" ) {     # NEXT Control Card - skip to the next loop iteration
    processLAST($skelCardType);
  }
  elsif ( $skelCardType eq ")STOP" ) {     # STOP Control Card - stop all processing and return what has been generated so far
    processSTOP($card);
  }
  elsif ( $skelCardType eq ")EXIT" ) {     # EXIT Control Card - stop all processing in the current skeleton and return to the next higher level
    processEXIT($skelCardType);
  }
  elsif ( $skelCardType eq ")DMP" ) {     # DMP Control Card - generate a file for diwnloading
    processDMP($card);
  }
  elsif ( $skelCardType eq ")FXTAB" ) {    # FXTAB Control Card - generate a cross tab formatted dump of a table
    processFXTAB($card);
  }
  elsif ( $skelCardType eq ")DOCMD" ) {    # DOCMD Control Card - execute a database command i.e. insert , delete, update)
    processDOCMD($card);
  }
  elsif ( $skelCardType eq ")FVTAB" ) {    # FVTAB Control Card - generate a vertically formatted dump of a table
    processFVTAB($card);
  }
  elsif ( $skelCardType eq ")DOSEL" ) {    # DOSEL Control Card - populate internal variables from a select statement
    processDOSEL($card);
  }
  elsif ( $skelCardType eq ")DOF" ) {      # DOF Control Card - read in a file - of the form )DOF [fileRef] [<fileName> [using <CTLFileName>]]
    processDOF($card);
  }
  elsif ( $skelCardType eq ")DOEXEC" ) {      # DOF Control Card - read in a file - of the form )DOF [fileRef] [<fileName> [using <CTLFileName>]]
    processDOEXEC($card);
  }
  elsif ( $skelCardType eq ")PARSE" ) {      # PARSE Control Card - break a string into variables
    processPARSE($card);
  }
  elsif ( $skelCardType eq ")FDOF" ) {      # FDOF Control Card - display a file - of the form )FDOF [<fileName> [using <CTLFileName>]]
    processFDOF($card);
  }
  elsif ( $skelCardType eq ")ENDDOF" ) {   # ENDDOF Control Card - terminate a DOF control loop
    processENDDOF($card);
  }
  elsif ( $skelCardType eq ")ENDDOEXEC" ) {   # ENDDOF Control Card - terminate a DOF control loop
    processENDDOEXEC($card);
  }
  elsif ( $skelCardType eq ")ENDDOT" ) {   # ENDDOT Control Card - Terminate a DOT or XDOT control loop
    processENDDOT($card);
  }
  elsif ( $skelCardType eq ")DISNOTE" ) {  # DISNOTE Control Card - Show a message
    processDISNOTE($card);
  }
  elsif ( $skelCardType eq ")IMBED" ) {    # IMBED Control Card - Start processing a different skeleton
    processIMBED($card);
  }
  elsif ( $skelCardType eq ")CASE_SENS_COLS" ) { # CASE_SENS_COLS Control Card - Set a flag indicating that case is to be ignored when selecting columns
    $skelCaseSensitiveColumns = 1;
  }
  elsif ( $skelCardType eq ")TRACE" ) {    # TRACE Control Card - set a trace level for ProcessSkeleton
    processTRACE($card);
  }
  elsif ( $skelCardType eq ")DECIMALPLACES" ) {    # DECIMALPLACES Control Card - set the number of decimal places to display for cursor variables
    processDECIMALPLACES($card);
  }
  elsif ( $skelCardType eq ")TRUNCZEROES" ) {    # TRUNCZEROES Control Card - set the truncateTrailingZeroes flag
    processTRUNCZEROES($card);
  }
  elsif ( $skelCardType eq ")LEAVEZEROES" ) {    # LEAVEZEROES Control Card - reset the truncateTrailingZeroes flag
      processLEAVEZEROES($card);
  }
  elsif ( $skelCardType eq ")TRACEOFF" ) { # TRACEOFF Control Card - Resume trace level that existed when last TRACE command set
    processTRACEOFF($card);  
  }
  elsif ( $skelCardType eq ")DEBUG" ) {    # DEBUG Control Card - Dump out internal skeleton information
    processDEBUG($card);
  }
  elsif ( $skelCardType eq ")FUNC" ) {     # FUNC Control Card - Apply a function to a variable
    processFUNC($card);
  }
  elsif ( $skelCardType eq ")WHEN" ) {     # WHEN Control Card - Optionally process a command
    processWHEN($card);
  }
  elsif ( ($skelCardType eq ")SEL") || ($skelCardType eq ")IF") ) {          # SEL Control Card - Optionally process a group of cards (similar to an IF statement)
    processSEL($card);
  }
  elsif ( ($skelCardType eq ")SELELSE") || ($skelCardType eq ")ELSEIF") ) {  # SELELSE Control Card - Optionally process a group of cards (similar to an ELSEIF statement)
    processSELELSE($card);
  }
  elsif ( ($skelCardType eq ")ENDSEL") || ($skelCardType eq ")ENDIF") ) {    # ENDSEL Control Card - Terminate a )SEL Command
    processENDSEL($card);
  }
  elsif ( ($skelCardType eq ")VERSION") ) {    # VERSION Control Card - Display the versions of all of the modules
    processVERSION($card);
  }
  elsif ( ($skelCardType eq ")SKELVERS") ) {   # SKELVERS Control Card - Set the internal version skelVers to the version of the current skeleton
    processSKELVERS($card);
  }
  elsif ( ($skelCardType eq ")DMPHDR") ) {    # DMPHDR Control Card - Display the HTML control information to export a file
    processDMPHDR($card);
  }
  elsif ( ($skelCardType eq ")HTMLHDR") ) {    # HTMLHDR Control Card - Display the HTML control information
    processHTMLHDR($card);
  }
  elsif ( ($skelCardType eq ")GETCOOKIE") ) {    # GETCOOKIE Control Card - Retrieve and process supplied cookies 
    processGetCookie($card);
  }
  elsif ( ($skelCardType eq ")INDEX") ) {    # INDEX Control Card - Create index element and set index variables
    processINDEX($card);
  }
  elsif ( ($skelCardType eq ")INDEXTEST") ) {  # INDEXTEST Control Card - Check to see if an index element is required
    processINDEXTEST($card);
  }
  elsif ( ($skelCardType eq ")INDEXCLEAR") ) {  # INDEXCLEAR Control Card - Flush out any unused index entries
    processINDEXCLEAR($card);
  }
  elsif ( ($skelCardType eq ")INDEXOFF") ) {  # INDEXOFF Control Card - Turn off index processing
    processINDEXOFF($card);
  }
  elsif ( ($skelCardType eq ")SETCOOKIE") ) {    # SETCOOKIE Control Card - Set the cookie values
    processSetCookie($card);
  }
  elsif ( ($skelCardType eq ")BUTTON") ) {    # BUTTON Control Card - Display the HTML button code
    processBUTTON($card);
  }
  elsif ( ($skelCardType eq ")GRAPH") ) {    # GRAPH Control Card - Print out a graph 
    processGRAPH($card);
  }
  elsif ( ($skelCardType eq ")GRAPHOPT") ) {    # GRAPHOPT Control Card - Print out a graph 
    processGRAPHOPT($card);
  }
  elsif ( ($skelCardType eq ")GRAPHLABEL") ) {    # GRAPHLABEL Control Card - Establish a label definition
    processGRAPHLABEL($card);
  }
  elsif ( ($skelCardType eq ")GRAPHSTART") ) {    # GRAPHSTART Control Card - Print out the start of a GRAPH section
    processGRAPHSTART($card);
  }
  elsif ( ($skelCardType eq ")GRAPHFINISH") ) {    # GRAPHFINISH Control Card - Print out the end of a GRAPH section
    processGRAPHFINISH($card);
  }
  elsif ( ($skelCardType eq ")GRAPHGROUP") ) {    # GRAPHGROUP Control Card - Set Grouping formatting data for a graph
    processGRAPHGROUP($card);
  }
  elsif ( ($skelCardType eq ")GRAPHGROUPCLEAR") ) {    # GRAPHGROUPCLEAR Control Card - Clear the Graph Grouping data
    processGRAPHGROUPCLEAR($card);
  }
  elsif ( ($skelCardType eq ")GRAPHLIB") ) {    # GRAPHLIB Control Card - Set the Graph library locations
    processGRAPHLIB($card);
  }
  elsif ( ($skelCardType eq ")CM") || ($skelCardType eq ")COMMENT") ) { # CM Control Card - Ignore comment cards
  }
  elsif ( $skelCardType eq ")LEAVEHEADERS" ) { # LEAVEHEADERS control card - dont modify FDOF headers
    processLEAVEHEADERS();
  }
  elsif ( $skelCardType eq ")CONVERTHEADERS" ) { # CONVERTHEADERS control card - dont modify FDOF headers
    processCONVERTHEADERS();
  }
  elsif ( $skelCardType eq ")CLEARSELECTCOND" ) { # CLEARSELECTCOND control card - clear the codition
    $selectCond = '';
  }
  elsif ( ($skelCardType eq ")SETLEFTJUSTTAB") ) {    # Set the left justified tab stop
    processSETLEFTJUSTTAB(substr($card,15));
  }
  elsif ( ($skelCardType eq ")FILE") ) {    # Get file information
    processFILE($card);
  }
  elsif ( ($skelCardType eq ")RESETOUTPUT") ) {    # Clear all saved output (doesn't affect STDOUT output)
    processRESETOUTPUT(substr($card,12));
  }
  elsif ( ($skelCardType eq ")VHEAD") ) {          # Set new vertical headings
    processVHEAD($card);
  }
  elsif ( ($skelCardType eq ")SETRIGHTJUSTTAB") ) {    # Set the right justified tab stop
    processSETRIGHTJUSTTAB(substr($card,16));
  }
  else { # it wasn't a control card so treat is as a normal card
    if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
      processLine($card);
    } 
    else { # card was skipped
      displayDebug("Skipped: $card. Sel Skip = $skelSelSkipCards, SEL Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel, Dot Skip = $skelDOTSkipCards, DOT Count = $skelDOTCount, DOT Resume Level = $skelDOT_resumeLevel",2,$currentSubroutine);
    }
  }

  displayDebug("Control Card Processing Completed",2,$currentSubroutine);
  
} # end of processControlCard

sub processFUNC {
  # -----------------------------------------------------------
  # Routine to process control card )FUNC
  # a )FUNC is of the form:   )FUNC <Function Name> <Var Name> = <parameters for function>
  # 
  # For details on the functions supported see processFunctions
  #
  # Usage: processFUNC(<skeleton line to process>)
  # Returns: sets the indicated variable to the result of applying the function
  # -----------------------------------------------------------

  my $currentSubroutine = 'processFUNC'; 
  
  my $card = shift; # get the line to process - will be $skelLines[$skelArray{$currentActiveSkel}][$currentLinePosition]
  
  my $varName;   # name of the variable to update
  my $varOp;     # should be = if it is an assignment 

  if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
    my $funcName = getToken($card);                      # function name
    
    if ( $currentVariable ne '' ) {    # there is no equals and the first character of the first parm is a :
      $varName = $currentVariable;     # set the variable to update
      $varOp = '=';
    }
    else {
      $varName = getToken($card);      # variable name
      $varOp = getToken($card);        # should be =
    }
      
    if ( $varOp ne "=" ) { # assignment must be =
      displayError("Operator for )FUNC $funcName must be '='. Operator found was $varOp\nAll functions without a leading variable and functions FORMATSQL, GDATE and JDATE require = ",$currentSubroutine);
      return;
    }
    my $varValue = '';
    if ( $currentLinePosition <= length($card) ) { # there is a parameter
      displayDebug("\)FUNC string is " . substr($card,$currentLinePosition),1,$currentSubroutine);
      $varValue = processFunction($card, $funcName, trim(substr($card,$currentLinePosition)));         # perform the function
    }
    else { # no parameter supplied - not necessarily a problem
      displayDebug("\)FUNC string is <NULL>",1,$currentSubroutine);
      $varValue = processFunction($card, $funcName, '' );         # perform the function
    }
    displayDebug("Result = $varValue",1,$currentSubroutine);
    setVariable($varName,$varValue);                                                             # assign the result
  }
  else {
    displayDebug("Skipped: $card. Sel Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel",2,$currentSubroutine);
  }
  
} # end of  processFUNC

sub processFunction {
  # -----------------------------------------------------------
  # Routine to process Functions
  # The functions supported are: 
  #     INT              - returns integer portion of the number
  #     TRIM             - remove whitespace from the front and end of a string
  #     LTRIM            - remove leading whitespace from a string
  #     RTRIM            - remove trailing whitespace from a string
  #     LEN              - return the length of the supplied parameter
  #     SPLIT            - returns the xth value in the string delimted by the supplied delimiter ('' if not found)
  #                        )FUNC SPLIT RET = <string to split> <string to be split on> [<entry to return>]
  #     INSTR            - returns the position of one string in another (-1 if not found)
  #                        )FUNC INSTR RET = <string to search for> <string to be searched> [<start pos|OCC:occurence>]
  #     LEFT             - return a number of characters from the left hand side of a string
  #     RIGHT            - return a number of characters from the right hand side of a string
  #     MID              - return a number of characters from the middle of a a string
  #     REMOVECRLF       - remove CR and LF from a string
  #     REMOVEWHITESPACE - remove unnecessary (padding) whitespace from a supplied string.
  #                        spaces within a string will be preserved
  #     FORMATSQL        - return formatted SQL
  #     PAD              - Pad a string with characters
  #     REPL             - REPLACE a string with another string
  #                        )FUNC REPL RET = <string to search> <string to be replaced> <String to replace with>
  #     WEBSAFE          - Returns a string with all special characters converted to HTML equivalents
  #     LOWER            - Returns the string transformed to all lower case
  #     UPPER            - Returns the string transformed to all upper case
  #     
  # Usage: processFunction(<Function>,<Parameters>)
  # Returns: the result of the function applied to the parameters
  # -----------------------------------------------------------  
  my $currentSubroutine = 'processFunction'; 
  
  my $card = shift;            # original control card
  my $function = shift;        # function to perform
  my $funcParm = shift;        # parameters to perform the function on (note thsi is not getToken - getToken is still pointing to the 1st parm)
  
  my $i;

  displayDebug("Function $function will process the following parms: $funcParm",2,$currentSubroutine);

  if ( uc($function) eq "INT" ) { # INT function
    return int($funcParm);
  }
  elsif ( uc($function) eq "TRIM" ) { # TRIM function
    return trim($funcParm);
  }
  elsif ( uc($function) eq "LTRIM" ) { # Left TRIM function
    return ltrim($funcParm);
  }
  elsif ( uc($function) eq "RTRIM" ) { # Right TRIM function
    return rtrim($funcParm);
  }
  elsif ( (uc($function) eq "LOWER") || (uc($function) eq 'LC') ) { # lower case
    return lc($funcParm);
  }
  elsif ( (uc($function) eq "UPPER") || (uc($function) eq 'UC') ) { # upper case
    return uc($funcParm);
  }
  elsif ( uc($function) eq "LEN" ) { # length function
    return length($funcParm);
  }
  elsif ( uc($function) eq "PAD" ) { # pad function .... pad
    my $baseString = getToken($card);                       # string to be searched
    my $paddingString = getToken($card);                    # string to use to pad
    my $finalLength = getToken($card);                      # length the string will end up at
    my $paddingEnd = getToken($card);                       # which end of the string the padding should occur at
    my $returnString = '';

    if ( ($baseString =~ /^'/) || ($baseString =~ /^"/) ) {     # it is a quoted string ....
      $baseString = substr($baseString,1,length($baseString)-2); # strip off the quotes
    }

    if ( ($paddingString =~ /^'/) || ($paddingString =~ /^"/) ) {     # it is a quoted string ....
      $paddingString = substr($paddingString,1,length($paddingString)-2); # strip off the quotes
    }

    # PAD MUST have at least 3 parms

    if ( $finalLength eq "" ) { # 2 parameters haven't been supplied
      displayError("PAD function format is:\n)FUNC PAD xxx = <string> <Pad String> <Final Length> <Padding Side (L or R)>\nNote: It MUST have 3 parameters - Function will return original string",$currentSubroutine);
      return $baseString;
    }

    # 3rd parameter MUST be numeric

    if ( ! isNumeric($finalLength)) { # 3rd parameter is not numeric
      displayError("PAD function format is:\n)FUNC PAD xxx = <string> <Pad String> <Final Length> <Padding Side (L or R)>\nNote: 3rd parameter must be nnumeric - Function will return original string",$currentSubroutine);
      return $baseString;
    }

    displayDebug("baseString=$baseString,paddingString=$paddingString,finalLength=$finalLength,paddingEnd=$paddingEnd",2,$currentSubroutine);

    my $lengthOfExtra = $finalLength - length($baseString);
    my $numberOfPaddingStrings = ( $lengthOfExtra / length($paddingString) ) + 1;
    my $padString = $paddingString x $numberOfPaddingStrings;

    if ( uc($paddingEnd) eq "L" ) { # pad on the left .....
      $returnString = substr($padString . $baseString, -1 * $finalLength);
    }
    elsif ( uc($paddingEnd) eq "R" ) { # pad on the right .....
      $returnString = substr($baseString . $padString, $finalLength);
    }
    else { # the end is not specified correctly so default it
      if ( isNumeric($baseString) ) { # not L or R but numeric so pad on the left .....
        $returnString = substr($padString . $baseString, -1 * $finalLength);
      }
      else {  # pad on the right .....
        $returnString = substr($baseString . $padString, $finalLength);
      }
    }

    displayDebug("returnString=>$returnString<",2,$currentSubroutine);

    return $returnString;
  }  # end of PAD function
  elsif ( uc($function) eq "INSTR" ) { # instr function
    my $srchString = getToken($card);                       # search string
    my $baseString = getToken($card);                       # string to be searched
    my $thirdParm = getToken($card);                        # third parameter ; either starting pos or OCCxxx where then it becomes the string occurence
    
    if ( ($srchString =~ /^'/) || ($srchString =~ /^"/) ) {     # it is a quoted string ....
      $srchString = substr($srchString,1,length($srchString)-2); # strip off the quotes
    }

    if ( ($baseString =~ /^'/) || ($baseString =~ /^"/) ) {     # it is a quoted string ....
      $baseString = substr($baseString,1,length($baseString)-2); # strip off the quotes
    }
    
    # INSTR MUST have at least 2 parms 
    
    if ( $baseString eq "" ) { # 2 parameters haven't been supplied
      displayError("INSTR function format is:\n)FUNC INSTR xxx = <search string> <string> [startpos|OCC:occurence]\nNote: It MUST have 2 parameters - Function will return -1",$currentSubroutine);
      return -1;
    }
    
    if ( $thirdParm eq '' ) { $thirdParm = 0 } # set a default value of zero for the third parm
    elsif ( ! isNumeric($thirdParm) ) { # parameter is not numeric so may be occurence 
      if ( uc(substr( $thirdParm . "   ", 0,4)) eq "OCC:" ) { # check if we are looking for an occurence value
        my $occ = substr($thirdParm,4);
        if ( ! isNumeric($occ) ) {
          displayError("INSTR function format is:\n)FUNC INSTR xxx = <search string> <string> [startpos|OCC:occurence]\nNote: Third parm must be either numeric or start with OCC: - 3rd parm will be assumed 1",$currentSubroutine);
          $thirdParm = 0;
        }
        else { # we need to find an occurence of the string
          my $spot = index($baseString,$srchString,0); # first occurence
          my $occCount = 1;
          while ( ($occCount < $occ) & ( $spot > -1 ) ) { # still more searching to do
        $spot = index($baseString,$srchString,$spot+1); # find the next entry
        $occCount++;
      }
      return $spot; # return the last location found
    }
      }
      else { # not numeric and not OCC: so ignore it
        displayError("INSTR function format is:\n)FUNC INSTR xxx = <search string> <string> [startpos|OCC:occurence]\nNote: Third parm must be either numeric or start with OCC: - 3rd parm will be assumed 0",$currentSubroutine);
        $thirdParm = 0;
      }
    }
    else {
      displayDebug("srchString=$srchString, baseString=$baseString, index is " . index($baseString,$srchString,$thirdParm),2,$currentSubroutine);
    }

    if ( $srchString =~ /^SPC\d*.*/ ) {                           # convert to a space filled string of length xxx where xxx is a literal of the form SPCxxx
      my ($numSpaces) = ( $srchString =~ /^SPC(\d*)[^\d]*/ ) ;
      displayDebug("$numSpaces space has been requested",2,$currentSubroutine);
      $srchString = space($numSpaces);                            # establish thye search string as a space filled string of a certain length
    }
    
    displayDebug("srchString=$srchString, baseString=$baseString, index is " . index($baseString,$srchString),2,$currentSubroutine);

    return index($baseString,$srchString,$thirdParm);
  }  # end of INSTR function
  elsif ( uc($function) eq "SPLIT" ) { # instr function
    my $baseString = getToken($card);                       # string to be searched
    my $strDelim = getToken($card);                         # string delimiter
    my $thirdParm = getToken($card);                        # entry to return 
    my $fourthParm = getToken($card);                       # max number of array elements (not supplied = unlimited)

    if ( ($strDelim =~ /^'/) || ($strDelim =~ /^"/) ) {     # it is a quoted string ....
      $strDelim = substr($strDelim,1,length($strDelim)-2); # strip off the quotes
    }

    if ( ($baseString =~ /^'/) || ($baseString =~ /^"/) ) {     # it is a quoted string ....
      $baseString = substr($baseString,1,length($baseString)-2); # strip off the quotes
    }

    # SPLIT MUST have at least 2 parms

    if ( $strDelim eq "" ) { # 2 parameters haven't been supplied
      displayError("SPLIT function format is:\n)FUNC SPLIT xxx = <base string> <delimiter> [occurence] [max elements]\nNote: It MUST have 2 parameters - Function will return ''",$currentSubroutine);
      return '';
    }

    if ( $thirdParm eq '' ) { $thirdParm = 0 } # set a default value of zero for the occurence

    if ( ! isNumeric($thirdParm) ) {
      displayError("SPLIT function format is:\n)FUNC SPLIT xxx = <base string> <delimiter> [occurence] [max elements]\nNote: If supplied, the third parameter must be numeric - it will be assumed to be 0",$currentSubroutine);
      $thirdParm = 0;
    }

    if ( ( $fourthParm ne '' ) && ( ! isNumeric($fourthParm)) ) {
      displayError("SPLIT function format is:\n)FUNC SPLIT xxx = <base string> <delimiter> [occurence] [max elements]\nNote: If supplied, the fourth parameter must be numeric - it will be assumed to be missing",$currentSubroutine);
      $fourthParm = '';
    }
    elsif ( (isNumeric($fourthParm)) && ( $thirdParm >= $fourthParm) ) { # make sure that the entry is less than the number of entries
      $fourthParm = $thirdParm + 1;
      displayError("SPLIT function format is:\n)FUNC SPLIT xxx = <base string> <delimiter> [occurence] [max elements]\nNote: If supplied, the 4th Parm must be bigger than the 3rd Parm - it will be assumed to be $fourthParm",$currentSubroutine);
    }

    displayDebug("strDelim=$strDelim, baseString=$baseString, thirdParm=$thirdParm, fourthParm=$fourthParm",2,$currentSubroutine);

    my @elemArr;
    if ( $fourthParm eq '' ) {
      @elemArr = split($strDelim, $baseString);
    }
    else {
      @elemArr = split($strDelim, $baseString, $fourthParm);
    }

    return $elemArr[$thirdParm];   # return the wanted element

  }  # end of SPLIT function
  elsif ( uc($function) eq "LEFT" ) {                       # LEFT function
    my $baseString = getToken($card);                       # string to be searched
    my $strLength = getToken($card);                        # number of chars to return
      
    if ( $strLength eq '') {                                # second parameter not supplied
      displayError("LEFT function format is:\n)FUNC LEFT xxx = <string> <number Of Characters>\nNote: Function will return parameter if only one parameter supplied",$currentSubroutine);
      return $baseString;
    }

    displayDebug("baseString=$baseString, strLength=$strLength, left is " . substr($baseString,0,$strLength), 2, $currentSubroutine);

    if ( length($baseString) < $strLength) {      # if the base string is shorter than the number of chars required
      return $baseString;                         # just return the whole string - no padding is done
    }
    else { # do the calculation
      return substr($baseString,0,$strLength);    # return the specified number of characters
    }
    
  } # end of LEFT function
  elsif ( uc($function) eq "RIGHT" ) {                      # RIGHT function
    my $baseString = getToken($card);                       # string to be searched
    my $strLength = getToken($card);                        # number of chars to return
      
    if ( $strLength eq '') {                                # second parameter not supplied
      displayError("RIGHT function format is:\n)FUNC RIGHT xxx = <string> <number Of Characters>\nNote: Function will return parameter if only one parameter supplied",$currentSubroutine);
      return $baseString;
    }

    displayDebug("baseString=$baseString, strLength=$strLength, left is " . substr($baseString,0,$strLength),2, $currentSubroutine );
    
    if ( length($baseString) < $strLength) { # if the base string is shorter than the number of chars required
      return $baseString;                    # just return the whole string - no padding is done
    }
    else { # do the calculation
      return substr($baseString,length($baseString) - $strLength - 1,$strLength);0
    }
    
  } # end of RIGHT function
  elsif ( uc($function) eq "MID" ) {                         # MID function
    my $baseString = getToken($card);                        # string to be searched
    my $startPos = getToken($card);                          # start pos in string
    my $strLength = getToken($card);                         # length of string to return

    if ( $startPos eq '' ) {                                 # only 1 parameter was supplied - minimum 2 required
      displayError("RIGHT function format is:\n)FUNC MID xxx = <string> <start position> <length>]\nNote: A minumum of 2 parameters must be supplied",$currentSubroutine);
      return -1;
    }

    if ( $strLength eq "" ) {                                # no length specified ...
      if ( abs($startPos) > length($baseString)) {           # start pos is outside of the string (if -ve then it is counted from the right)
        displayError("Start position of $startPos is outside of the supplied string of length " . length($baseString) . "\n An empty string will be returned",$currentSubroutine);
        return '';
      }
      else {                                                 # no length problems
        displayDebug("baseString=$baseString, startpos=$startPos, strLength=$strLength, mid is " . substr($baseString,$startPos),2 );
        return substr($baseString,$startPos);
      }
    }
    else { # length parameter has been supplied .....
      if ( abs($startPos) > length($baseString)) {           # start pos is outside of the string (if -ve then it is counted from the right)
        displayError("Start position of $startPos is outside of the supplied string of length " . length($baseString) . "\n An empty string will be returned",$currentSubroutine);
        return '';
      }
      else {                                                 # no start pos problems
        displayDebug("baseString=$baseString, startpos=$startPos, strLength=$strLength, mid is " . substr($baseString,$startPos,$strLength),2, $currentSubroutine );
        return substr($baseString,$startPos,$strLength);
      }
    }
  }
  elsif ( uc($function) eq "REMOVECRLF") { # remove CRLFs from the supplied string
    $funcParm = trim($funcParm);
    return removeCRLF($funcParm);
  }
  elsif ( uc($function) eq "REMOVEWHITESPACE") { # remove unnecessary whitespace from the supplied string
    $funcParm = trim($funcParm);
    return removeUnnecessaryWhiteSpace($funcParm);
  }
  elsif ( uc($function) eq "FORMATSQL") { # format the supplied string as SQL
    $funcParm = trim($funcParm);
    if ( uc($funcParm) =~ "^FILE\:|^SQL\:|^FILE\=|^SQL\=" ) {                    # does the sql start with either SQL: or FILE: or SQL= or FILE=
      $funcParm = loadSQL(trim(substr($funcParm,$+[0])) , $currentSubroutine);             # load the SQL
    }
    elsif ( (uc($funcParm) =~ "^INLINE\:|^INLINE\=") || ( uc($funcParm) eq 'INLINE') ) {   # does the sql start with either INLINE: or INLINE: or is INLINE
      $funcParm = loadInlineCards($currentSubroutine);             # load the SQL
    }
    return formatSQL($funcParm);
  }
  elsif ( uc($function) eq "GDATE" ) {                      # GDATE function
    my $date = getToken($card);                             # should be a string of the format YYYYMMDD
    my $baseYear = getToken($card);                         # if this exists then should be a parm in the format BASE=YYYY (optional)
      
    if ( $baseYear ne '') {                                 # second parameter supplied
      if ( uc(substr($baseYear,0,4)) ne 'BASE' ) {          # first 4 chars must be BASE
        displayError("Malformed 2nd parameter: Must start with BASE\nGDATE function format is:\n)FUNC GDATE xxx = YYYYMMDD [BASE:YYYY]",$currentSubroutine);
        return '';  
      }
      elsif ( length($baseYear) != 9 ) {                       # length must be 9 chars
        displayError("Malformed 2nd parameter: must be 9 chars long\nGDATE function format is:\n)FUNC GDATE xxx = YYYYMMDD [BASE:YYYY]",$currentSubroutine);
        return '';  
      }
      elsif ( ! isNumeric(substr($baseYear,5,4)) ) {         # last 4 characters must be numeric
        displayError("Malformed 2nd parameter: last 4 characters must be numeric\nGDATE function format is:\n)FUNC GDATE xxx = YYYYMMDD [BASE:YYYY]",$currentSubroutine);
        return '';  
      }
    }

    if ( $date ne '') {                                 # second parameter supplied
      if ( length($date) != 8 ) {                          # length must be 8 chars
        displayError("Malformed 1st parameter: must be 8 chars long\nGDATE function format is:\n)FUNC GDATE xxx = YYYYMMDD [BASE:YYYY]",$currentSubroutine);
        return '';  
      }
      elsif ( ! isNumeric($date) ) {                    # must be numeric
        displayError("Malformed 1st parameter: must be numeric\nGDATE function format is:\n)FUNC GDATE xxx = YYYYMMDD [BASE:YYYY]",$currentSubroutine);
        return '';  
      }
    }
    else { # if no date value is supplied it will default to today
      $date = getDate2;    # returns the current date in YYYMMDD format
    }

    displayDebug("baseYear=$baseYear, date=$date)",2, $currentSubroutine);
    
    my @returned = myDate("Date:$date $baseYear");
    
    # create/update the internal variables
   
    setVariable('DT_DD',$returned[0]);
    setVariable('DT_MM',$returned[1]);
    setVariable('DT_YY',$returned[2]);
    setVariable('DT_Suff',$returned[3]);
    setVariable('DT_Month',$returned[4]);
    setVariable('DT_NumDays',$returned[5]);
    setVariable('DT_BaseDate',$returned[6]);
    setVariable('DT_EOM',$returned[7]);
    setVariable('DT_EOY',$returned[8]);
    setVariable('DT_EOFY',$returned[9]);
    setVariable('DT_BOM',$returned[10]);
    setVariable('DT_DOW',$returned[11]);
    setVariable('DT_DAY',$weekDays{$returned[11]});
    
    return $returned[5]; # return the number of days form the base date
    
  } # end of GDATE function
  elsif ( uc($function) eq "JDATE" ) {                      # JDATE function
    my $numDays = getToken($card);                          # should be a numeric string
    my $baseYear = getToken($card);                         # if this exists then should be a parm in the format BASE=YYYY (optional)
    
    if ($numDays < 0) { return ''; }                        # dont process negative days
    
    if ( $baseYear ne '') {                                 # second parameter supplied
      if ( uc(substr($baseYear,0,4)) ne 'BASE' ) {          # first 4 chars must be BASE
        displayError("Malformed 2nd parameter: Must start with BASE\nJDATE function format is:\n)FUNC JDATE xxx = nnnnnn [BASE:YYYY]",$currentSubroutine);
        return '';  
      }
      elsif ( length($baseYear) != 9 ) {                       # length must be 9 chars
        displayError("Malformed 2nd parameter: must be 9 chars long\nJDATE function format is:\n)FUNC JDATE xxx = nnnnnn [BASE:YYYY]",$currentSubroutine);
        return '';  
      }
      elsif ( ! isNumeric(substr($baseYear,5,4)) ) {         # last 4 characters must be numeric
        displayError("Malformed 2nd parameter: last 4 characters must be numeric\nJDATE function format is:\n)FUNC JDATE xxx = nnnnnn [BASE:YYYY]",$currentSubroutine);
        return '';  
      }
    }

    if ( $numDays ne '') {                                 # second parameter supplied
      if ( ! isNumeric($numDays) ) {                    # must be numeric
        displayError("Malformed 1st parameter: must be numeric - found $numDays\nJDATE function format is:\n)FUNC JDATE xxx = nnnnnnn [BASE:YYYY]",$currentSubroutine);
        return '';  
      }
    }
    else { # if no number of days is supplied it will default to 1
      $numDays = 1;       # 
    }

    displayDebug("baseYear=$baseYear, numDays=$numDays)",1, $currentSubroutine);
    
    my @returned = myDate("$numDays $baseYear");
    
    # create/update the internal variables
   
    setVariable('DT_DD',$returned[0]);
    setVariable('DT_MM',$returned[1]);
    setVariable('DT_YY',$returned[2]);
    setVariable('DT_Suff',$returned[3]);
    setVariable('DT_Month',$returned[4]);
    setVariable('DT_NumDays',$returned[5]);
    setVariable('DT_BaseDate',$returned[6]);
    setVariable('DT_EOM',$returned[7]);
    setVariable('DT_EOY',$returned[8]);
    setVariable('DT_EOFY',$returned[9]);
    setVariable('DT_BOM',$returned[10]);
    setVariable('DT_DOW',$returned[11]);
    setVariable('DT_DAY',$weekDays{$returned[11]});
    
    return "$returned[4] $returned[0]$returned[3], $returned[2]"; # return the date as calculated from BASEDATE and NUMDAYS in the format "March 12th, 2015"
    
  } # end of JDATE function
  elsif ( uc($function) eq "REPL" ) {                       # REPL function
    my $baseString = getToken($card);                       # string to be searched
    my $srchString = getToken($card);                       # String to be searched for
    my $replString = getToken($card);                       # Replacement String

    if ( $srchString eq '') {                               # second parameter not supplied
      displayError("REPL function format is:\n)FUNC REPL xxx = <string> <search string> <replacement string>\nNote: Function will remove string if replacement string not provided",$currentSubroutine);
      return $baseString;
    }

    displayDebug("baseString=$baseString, srchString=$srchString, replString=$replString", 2, $currentSubroutine);

    $baseString =~ s/$srchString/$replString/g; # do the replacement
    return $baseString;                         # 

  } # end of REPL function
  elsif ( uc($function) eq "WEBSAFE" ) {                    # REPL function
    my $baseString = getToken($card);                       # string to be converted

    displayDebug("baseString=$baseString", 2, $currentSubroutine);

    $baseString =~ s/\%/%25/g; # do the percent sign replacement - MUST be done first 
    $baseString =~ s/\ /%20/g; # do the space replacement
    $baseString =~ s/\!/%21/g; # do the exclamation replacement
    $baseString =~ s/\"/%22/g; # do the double quotes replacement
    $baseString =~ s/\#/%23/g; # do the number sign replacement
    $baseString =~ s/\$/%24/g; # do the dollar sign replacement
    $baseString =~ s/\&/%26/g; # do the ampersand replacement
    $baseString =~ s/\'/%27/g; # do the single quote replacement
    $baseString =~ s/\(/%28/g; # do the opening parenthesis replacement
    $baseString =~ s/\)/%29/g; # do the closing parenthesis replacement
    $baseString =~ s/\*/%2A/g; # do the asterisk replacement
    $baseString =~ s/\+/%2B/g; # do the plus sign replacement
    $baseString =~ s/\,/%2C/g; # do the comma replacement
    $baseString =~ s/\-/%2D/g; # do the minus sign replacement
    $baseString =~ s/\./%2E/g; # do the period replacement
    $baseString =~ s/\//%2F/g; # do the slash replacement
    return $baseString;                         # 

  } # end of WEBSAFE function

  displayError("Function $function unknown. Known functions are:\n     INT, TRIM, LTRIM, RTRIM, LEN, SPLIT, INSTR, LEFT, RIGHT, MID, REMOVECRLF, REMOVEWHITESPACE, FORMATSQL,\n     GDATE, JDATE, PAD\nFunction will return nothing",$currentSubroutine);
  return "";

} # end of processFunction

sub processLine {
  # -----------------------------------------------------------
  # Routine to process non-control card skeleton cards
  #
  # Usage: processLine(<skeleton line to process>)
  # Returns: nothing (just writes out the processed card)
  # -----------------------------------------------------------

  my $currentSubroutine = 'processLine'; 
  
  my $card = shift; # get the line to process - will be $skelLines[$skelArray{$currentActiveSkel}][$currentLinePosition]
  my $tempLine ;

  displayDebug("Start Processing Normal Card : $card",1,$currentSubroutine);
  if ( trim($card) eq "" ) { # it is a blank line
    displayDebug("Blank line",2,$currentSubroutine);
    outputLine($card);
  }
  else { # just do variable substitution
    $tempLine = putInTabs(substituteVariables($card)); 
    displayDebug("After tab and variable substitution >$tempLine<",1,$currentSubroutine);
    outputLine($tempLine);
  }
  
} # end of  processLine

sub adjustUnsetLengthFields {
  # -----------------------------------------------------------
  # Routine to set the length fields of unset FIXED entries
  #
  # Basically, a default length will be set where a length can be
  # reasonably calculated
  #
  # Usage: adjustUnsetLengthFields($fileRef);
  # Returns: Nothing but sets length valuefor undefined ctl cards
  # -----------------------------------------------------------

  my $fileRef = shift;
  my $currentSubroutine = 'adjustUnsetLengthFields';
  my $delimiter = ',';
  my $next_delimiter = ',';

  my $numCTLLines = $#{$ctlLines[$ctlArray{$fileRef}]} + 1;                    # set the number of lines in the array slice for this fileRef
  for ( my $i=0 ; $i<$numCTLLines; $i++ ) {                                    # for each control line

    displayDebug("CTL Field Array Entry being Processed: $ctlLines[$ctlArray{$fileRef}][$i]",1,$currentSubroutine);
    my $ctlCard = $ctlLines[$ctlArray{$fileRef}][$i];                          # place the card into a variable for easier typing
    $delimiter = substr($ctlCard,0,1);                                         # first char is the delimiter

    # break the preparsed ctl line into it's parts (maximum of 8 parts)
    displayDebug("CTL Card: $ctlCard",2,$currentSubroutine);
    my ($delNull,$delimType,$fldName, $fldStart, $fldLen, $condStart, $condLen, $condValue) = split (/[$delimiter]/,$ctlCard,8);

    # initialise parameters that weren't supplied
    if ( !defined($condValue) ) { $condValue = ''; }
    if ( !defined($condLen) ) { $condLen = ''; }
    if ( !defined($condStart) ) { $condStart = ''; }
    if ( !defined($fldLen) ) { $fldLen = ''; }

    if ( $delimType eq "FIXED" ) { # fixed length field
      if ( ($fldLen eq '') || ( $fldLen eq '0') ) { # length hasn't been set for this element
        if ( $i+1  == $numCTLLines ) { # we are on the last line so there is no calculation to do - default it to 15 chars
          $fldLen ='15';
        }
        else { # a next control rtecord is available .....
          if ( substr($ctlLines[$ctlArray{$fileRef}][$i+1],1,5) eq 'FIXED' ) { # the next control card is a FIXED record too
            # need to break the next line down ...
            my $next_ctlCard = $ctlLines[$ctlArray{$fileRef}][$i+1];           # place the card into a variable for easier typing
            $next_delimiter = substr($next_ctlCard,0,1);                       # first char is the delimiter
 
            # break the preparsed ctl line into it's parts (maximum of 8 parts)
            displayDebug("CTL Card: $next_ctlCard",2,$currentSubroutine);
            my ($next_delNull,$next_delimType,$next_fldName, $next_fldStart, $next_fldLen, $next_condStart, $next_condLen, $next_condValue) = split (/[$next_delimiter]/,$next_ctlCard,8);

            $fldLen = $next_fldStart - $fldStart;
          }
          else { # it's a delimited record so no idea where it starts - default length to 15
            $fldLen ='15';
          }
        }
        displayDebug("Adjusting fldLen to be $fldLen",1,$currentSubroutine);
        $ctlLines[$ctlArray{$fileRef}][$i] = "$delimiter$delimType$delimiter$fldName$delimiter$fldStart$delimiter$fldLen$delimiter$condStart$delimiter$condLen$delimiter$condValue";
      }
    }

  } # end of loop through ctl lines

}

sub setDefinedVariablesForFile {
  # -----------------------------------------------------------
  # This routine accepts a passed record of data and a control definition
  # using these it will break the record up and assign the values to skeleton variables
  #
  # CTL file information will be of the form:
  #
  # <CTL Delimiter>,FIXED,<fieldName>,<startPos>,<length>,<condition_pos>,<Condition_length>,<condition_Value>
  # or
  # <CTL Delimiter>,DELIMITED,<fieldName>,<delimiter>,<occurrance>,<condition_pos>,<Condition_length>,<condition_Value>
  # or
  # <CTL Delimiter>,DELIMITED,<fieldName>,<delimiter>,<occurrance>,DELIMITED,<occurrance>,<condition_Value>
  #
  # The condition field indicates when the field will hold a value 
  # a sample record would be;
  # fixed,recKey,0,10,72,8,= 28
  #
  # delimited,recKey,:,1
  # Note: the first character after the FIXED or DELIMITED is the delimiter
  #
  # Usage: setDefinedVariablesForFile($fileRef,$fileRecord);
  # Returns: Nothing but sets skeleton variables
  # -----------------------------------------------------------

  my $currentSubroutine = 'setDefinedVariablesForFile'; 
  
  my $fileRef = shift;       # What CTL file we should use to decode the record
  my $fileRecord = shift;    # the record being read in
  
  my $skelDOFIgnoreRecord = "No";    # initialise flag indicating if the control file indicates that this record should be skipped
  displayDebug("Looking for $fileRef in cache",1,$currentSubroutine);
  
  my $tmpB = (keys %ctlArray);
  displayDebug("# keys: $tmpB",1,$currentSubroutine); 
  foreach my $tmpA (keys %ctlArray) { displayDebug(">>>>> $tmpA, $ctlArray{$tmpA}",1,$currentSubroutine); }

  # control array is defined in $ctlLines[$ctlArray{$fileRef}]
  
  if ( ! defined($ctlLines[$ctlArray{$fileRef}]) ) { # no match found (not sure how that happens - perhaps an empty control file)
    displayError("CTL File $fileRef not found - this shouldn't happen but is probably caused by a file not found or empty file",$currentSubroutine);
    return; # unhappily
  }

  displayDebug("$fileRef control records found in array entry $ctlArray{$fileRef}",1,$currentSubroutine);

  my $delimiter;                                                               # control card delimiter (not the data record delimiter)
  my @delimArr;                                                                # array to hold the data record delimited data
  my $numCTLLines = $#{$ctlLines[$ctlArray{$fileRef}]} + 1;                    # set the number of lines in the array slice for this fileRef
  for ( my $i=0 ; $i<$numCTLLines; $i++ ) {                                    # for each control line
  
    displayDebug("CTL Field Array Entry being Processed: $ctlLines[$ctlArray{$fileRef}][$i]",1,$currentSubroutine);
    my $ctlCard = $ctlLines[$ctlArray{$fileRef}][$i];                          # place the card into a variable for easier typing
    $delimiter = substr($ctlCard,0,1);                                         # first char is the delimiter
    
    # break the preparsed ctl line into it's parts (maximum of 8 parts)
    displayDebug("CTL Card: $ctlCard",2,$currentSubroutine);
    my ($delNull,$delimType,$fldName, $fldStart, $fldLen, $condStart, $condLen, $condValue) = split (/[$delimiter]/,$ctlCard,8); 
    
    # initialise parameters that weren't supplied
    if ( !defined($condValue) ) { $condValue = ''; }
    if ( !defined($condLen) ) { $condLen = ''; }
    if ( !defined($condStart) ) { $condStart = ''; }
    if ( !defined($fldLen) ) { $fldLen = ''; }
    
    displayDebug("delimType is $delimType, fldName is $fldName, fldStart is $fldStart, fldLen is $fldLen, condStart is >$condStart<",1,$currentSubroutine);
    
    if ( uc($delimType) eq "DELIMITED" ) {                                     # it is a delimited control record .... split up the data record to save time
      $fldStart = '\\' . $fldStart;
      @delimArr = ();                                                          # initialise an array to hold the delimiter conditions
      @delimArr = split($fldStart, $fileRecord);                               # for a delimited record the 4th parm is the delimiter so split the data record based on that
    }

    my $setVar = "No";                                                         # defaults to NOT processing the record
    my $testValue = '';                                                        # value obtained to be tested against a condition
    
    if ( $condStart ne "" ) {                                                  # condition was supplied so check if we want to process this data card
      if ( uc($condStart) eq "DELIMITED" ) {                                   # delimited condition
    if ( defined($delimArr[$condLen]) ) {                                  # If the condition field exists ....
      $testValue = $delimArr[$condLen];                                    # assign the value to the test field
        }
    else { # test field doesn't exist
      $testValue = "KCKCTESTFAILEDKCKC";                                   # make up a value for the test value
      displayError("Conditional test on card $i in CTL File $fileRef failed to identify a field - this field ($fldName) was not assigned a value",$currentSubroutine);
    }
      }
      else { # not a delimited value ....
        if ( $condStart > length($fileRecord)) {                               # field start outside record
      $testValue = "KCKCTESTFAILEDKCKC";                                   # make up a value for the test value
      displayError("Positional test on card $i in CTL File $fileRef is outside the record - this field ($fldName) was not assigned a value",$currentSubroutine);
        }
        elsif ( $condStart + $condLen > length($fileRecord) ) {                # field end outside record
          $testValue = substr($fileRecord, $fldStart);
      displayError("Positional test on card $i in CTL File $fileRef stretches outside the record - this field ($fldName) was assigned a truncated value of $testValue",$currentSubroutine);
        }
        else { # all looks good
          $testValue = substr($fileRecord, $fldStart, $fldLen) ;               # assign the value to the test field
        }
      }

      if ( $testValue eq "KCKCTESTFAILEDKCKC" ) {                              # check if the test value was set
        if ( $condNULLisMatch ) {                                              # indicates that a 'not found' is a match
          $setVar = "Yes";                                                     # process this record
        }
      }
      else {
        if ( evaluateCondition($testValue . $condValue) eq "True" ) {          # Check if the condition holds
          $setVar = "Yes";
    }
      }
    }
    else { # no condition so just set the variable
      $setVar = "Yes";
    }

    displayDebug("length(\$fileRecord) is " . length($fileRecord),1,$currentSubroutine);
    
    my $fldValue;                                             # variable holds the value of the defined field
    if ( $setVar eq "Yes" ) {                                 # the variable has passed all conditional processing
      if ( uc($delimType) eq "FIXED" ) {                      # field is defined in fixed positions
        if ( $fldStart > length($fileRecord)) {               # field starts outside record
          $fldValue = "";                                     # assign it a null string
        }
        elsif ( $fldStart + $fldLen > length($fileRecord) ) { # field end outside record
          $fldValue = substr($fileRecord, $fldStart);         # assign it a truncated value
        }
        else {
          $fldValue = substr($fileRecord, $fldStart, $fldLen) ;  # assign it the right value
        }
      }
      else { # it is a delimited field
    if ( defined($delimArr[$fldLen]) ) {                     # Note: the data record has previously been split
      $fldValue = $delimArr[$fldLen];                        # assign it the right value
        }
    else { # not enough values in the record
      $fldValue = "";
      displayDebug("Delimited field on card $i in CTL File $fileRef failed to identify a field - this field ($fldName) was assigned the value blank",1,$currentSubroutine);
    }
      }
      # and now just set the value for the variable ....
      displayDebug("Setting variable $fldName to a value of $fldValue",1,$currentSubroutine);
      setVariable($fldName,$fldValue);
    } 
  }

  
} # end of setDefinedVariablesForFile

sub loadFileCTL {
  # -----------------------------------------------------------
  # Routine to load up the DOF control file into arrays
  # CTL file information will be of the form:
  #
  # FIXED,<fieldName>,<startPos>,<length>,<condition_pos>,<Condition_length>,<condition_Value>
  # or
  # DELIMITED,<fieldName>,<delimiter>,<occurrance>,<condition_pos>,<Condition_length>,<condition_Value>
  # or
  # DELIMITED,<fieldName>,<delimiter>,<occurrance>,DELIMITED,<occurrance>,<condition_Value>
  #
  # The condition field indicates when the field will hold a value 
  # a sample record would be;
  # fixed,recKey,0,10,72,8,= 28
  #
  # delimited,recKey,:,1
  # Note: the first character after the FIXED or DELIMITED is the delimiter for the ctl record values (NOT the file being processed)
  #
  # Usage: loadFileCTL(<file Ref>, <CTL file name> )
  # Returns: loaded arrays
  # -----------------------------------------------------------

  my $currentSubroutine = 'loadFileCTL'; 
  
  my $ctlRef = shift;                            # literal used to refer to this control file
  my $ctlFile = shift;                           # file to be loaded
  my $currentFieldLoc = -1;                      # current field being defined
  $condNULLisMatch = 0;
  
  displayDebug("loading control file $ctlFile", 1,$currentSubroutine);

  # Check to see if the controlfile is already loaded
  if ( $ctlCache ) {                            # use already loaded version if it exists .....
    if ( defined($ctlArray{$ctlRef}) ) {        # if it is defined then use it
      displayDebug("Using already loaded CTL file ref $ctlRef", 1, $currentSubroutine);
      return;
    }
  }
  else { # dont cache so always reload the information
    if ( defined($ctlArray{$ctlRef}) ) {        # if it is defined then remove it
      displayDebug("Removing old cached version of ctlfile $ctlRef", 1, $currentSubroutine);
      $ctlLines[$ctlArray{$ctlRef}] = '';        # get rid of the existing control lines
      delete $ctlArray{$ctlRef};                 # remove the skel name referrer
    }
  }
  
  if ( ! defined($ctlArray{$ctlRef}) ) {         # Establish the new array entry number if one doesn't exist
    displayDebug("# Array Elements $#ctlLines", 1, $currentSubroutine);
    if ( $skelDebugLevel > 0 ) { # is it debug time? 
      foreach my $tmpA ( keys %ctlArray) { displayDebug("ctlArray $tmpA: $ctlArray{$tmpA}",1,$currentSubroutine); }
    }
    $ctlArray{$ctlRef} = $#ctlLines + 1;          # allocate the next array entry
    displayDebug("Allocating $ctlArray{$ctlRef} as the new CTL Array entry for $ctlRef", 1, $currentSubroutine);
  }
  
  #  load the CTL Cards

  my $inCtl;
  if ( ! open ($inCtl, "<", "$ctlFile") ) { # open has failed ...
      displayError("Open of $ctlFile has failed\nError: $?",$currentSubroutine);
      $ctlLines[$ctlArray{$ctlRef}] = '';        # get rid of the existing control lines
      delete $ctlArray{$ctlRef};                 # remove the skel name referrer      
      return;
  }
  else { # load it up
    my $delimiter;
    my $j = 0;
    while ( <$inCtl> ) {
      chomp $_;                                # get rid of the CRLF

      displayDebug("Input CTL File Line: $_", 1, $currentSubroutine);
        
      # skip comments
      
      if ( uc(trim($_)) =~ /^#/ ) { # comments are basically any line that starts with a #
        next;
      }

      # validate the input control data
      
      if ( uc(trim($_)) =~ /^COND_NULL_IS_MATCH$/ ) { # set the flag if this control parameter is passed
        $condNULLisMatch = 1;                         # indicates that if a condition variable isn't found then it is considered a match (by default it is not)
        next;
      }
        
      # establish the field delimiter
      if ( uc($_) =~ /^FIXED/)        { $delimiter = substr($_,5,1); }
      elsif ( uc($_) =~ /^DELIMITED/) { $delimiter = substr($_,9,1); } 
      else                            { $delimiter = ','; }              # delimiter defaults to comma

      my @ctlVals = split (/[$delimiter]/,$_,7);                             # based on the delimiter split it into a max of 7 fields
      $ctlLines[$ctlArray{$ctlRef}][$j] = $delimiter . $ctlVals[0];      # keep the def type (first char is now the delimiter)
       
      if ( " FIXED DELIMITED " !~ uc($ctlVals[0]) ) {                    # first parm is not correct so just skip the whole card
        displayError("CTL Card parameter should be FIXED or DELIMITED - will be ignored",$currentSubroutine);
        next;
      }
        
      if ( defined($ctlVals[1]) ) {                                      # field name has been supplied
        # add the identified parameter to the verified parameter string (field name)
        $ctlLines[$ctlArray{$ctlRef}][$j] .= $delimiter . $ctlVals[1];
      }
      else {                                                             # field name has not been supplied
        displayError("CTL Card parameter must hasve a field name defined - card $_ will be ignored",$currentSubroutine);
        next;
      }        

      # Validate Start pos
      my $tmpk = 0;
      if (defined($ctlVals[2])) {                                         # parameter 3 exists .....
        if ( uc($ctlVals[0]) eq "FIXED" ) {                               # for a FIXED parameter ensure that it is numeric
          $tmpk = $ctlVals[2] * 1; 
          if ( $tmpk ne $ctlVals[2] ) {                                   # if $parm * 1 <> $parm then there must be some non-numeric stuff in the parm
            displayError("Start Pos Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
          }
        }
        else {                                                             # for a DELIMITED parameter parm 3 is just a string
          $tmpk = $ctlVals[2];
        }
      }
      else { # not defined
        displayError("Start Pos Field/Delimiter in card " . $j . " is missing - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
      }
      # add the identified parameter to the verified parameter string
      $ctlLines[$ctlArray{$ctlRef}][$j] .= $delimiter . $tmpk;

      # Validate Length/Occurrance
      $tmpk = 0;
      if (defined($ctlVals[3])) {                                           # parameter 4 exists ..... (for fixed it is length, for delimited it is occurrance)
        $tmpk = $ctlVals[3] * 1; 
        if ( $tmpk ne $ctlVals[3] ) {                                       # if $parm * 1 <> $parm then there must be some non-numeric stuff in the parm
          displayError("Length/Occurrance Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
        }
        else { # it is a number .....
          if ( uc($ctlVals[0]) eq "DELIMITED" ) { # if it is delimited then adjust the current position
            $currentFieldLoc = $tmpk;
          }
        }
      }
      else { # length/occurence not defined
        if ( uc($ctlVals[0]) eq "DELIMITED" ) { # if not provided then there is a default value for DELIMITED entries ...
          if ( $currentFieldLoc == -1 ) { # there is no current value set
            $tmpk = 0;    # start at position 0
          }
          else { # just add one to the last position
            $tmpk = $currentFieldLoc + 1;
          }
          $currentFieldLoc = $tmpk;
        }
        else { # it is a FIXED with no length
          displayError("Length/Occurrence Field in card " . $j . " is missing - it will be adjusted to either 15 or to value where the current field stretches to the beginning of the next field",$currentSubroutine);
        }
      }
      # add the identified parameter to the verified parameter string
      $ctlLines[$ctlArray{$ctlRef}][$j] .= $delimiter . $tmpk;

      # Validate Condition Start
      $tmpk = 0;
      if (defined($ctlVals[4])) {                                           # parameter 5 exists ..... (it is either Condition Start or DELIMITED)
        if ( uc($ctlVals[4]) eq "DELIMITED" ) {                             # delimited condition
          $tmpk = $ctlVals[4]; 
        }
        else {                                                              # Fixed location
          $tmpk = $ctlVals[4] * 1;                               
          if ( $tmpk ne $ctlVals[4] ) {                                     # if $parm * 1 <> $parm then there must be some non-numeric stuff in the parm
            displayError("Condition Start Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
          }
        }
      }
      else { # not defined
        $tmpk = "";                                                         # indicates that a condition was not supplied
        displayDebug("Condition Start Field in card " . $j . " is missing - it will be adjusted to a value of " . $tmpk,2,$currentSubroutine);
      }
      # add the identified parameter to the verified parameter string
      $ctlLines[$ctlArray{$ctlRef}][$j] .= $delimiter . $tmpk;

      # If condition start has been supplied then do some more checking ......
      if ( $tmpk ne "" ) {                                                  # i.e. Condition Start has been defined ....

        # Validate Condition Length or Occurrance
        my $tmpk = 0;
        if (defined($ctlVals[5])) {                                         # parameter 6 exists ..... (it is either Condition Length or Occurrance)
          $tmpk = $ctlVals[5] * 1;
          if ( $tmpk ne $ctlVals[5] ) {                                     # if $parm * 1 <> $parm then there must be some non-numeric stuff in the parm
            displayError("Condition Length Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
          }
        }
        else { # not defined
          displayError("Condition Length Field in card " . $j . " is missing - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
        }
        # add the identified parameter to the verified parameter string
        $ctlLines[$ctlArray{$ctlRef}][$j] = $ctlLines[$ctlArray{$ctlRef}][$j] . $delimiter . $tmpk;

        if ( defined($ctlVals[6])) {                                        # parameter 7 exists ..... (it is Condition value)
          # add the identified parameter to the verified parameter string
          $ctlLines[$ctlArray{$ctlRef}][$j] = $ctlLines[$ctlArray{$ctlRef}][$j] . $delimiter . $ctlVals[6];
        }
        else { # not defined so just add a delimter
          $ctlLines[$ctlArray{$ctlRef}][$j] = $ctlLines[$ctlArray{$ctlRef}][$j] . $delimiter;
        }
      }
      else { # no condition has been supplied so just blank out the last bits
        $ctlLines[$ctlArray{$ctlRef}][$j] = $ctlLines[$ctlArray{$ctlRef}][$j] . $delimiter . $delimiter;
      }
      $j++;
    } # end of while
  } # end of else load it up
  close $inCtl;

  # set any unset legth field on FIXED record definitions
  adjustUnsetLengthFields($ctlRef); # set any unset length fields

  if ( $skelDebugLevel  > 0 ) { # if we are debugging
    my $numCTLLines = $#{$ctlLines[$ctlArray{$ctlRef}]} + 1;                         # number of control lines in the array slice applicable to $ctlRef
    displayDebug("Number of CTL Lines accepted = $numCTLLines for $ctlFile", 1,$currentSubroutine);
    for ( my $k=0 ; $k < $numCTLLines ; $k++) {
      displayDebug("CTL FILE Saved - Line $k - $ctlLines[$ctlArray{$ctlRef}][$k]",1,$currentSubroutine);
    }
  }
} # end of loadFileCTL

sub loadInlineFileCTL {
  # -----------------------------------------------------------
  # Routine to load up the DOF control file into arrays from
  # inline control cards
  #
  # CTL file information will be of the form:
  #
  # FIXED,<fieldName>,<startPos>,<length>,<condition_pos>,<Condition_length>,<condition_Value>
  # or
  # DELIMITED,<fieldName>,<delimiter>,<occurrance>,<condition_pos>,<Condition_length>,<condition_Value>
  # or
  # DELIMITED,<fieldName>,<delimiter>,<occurrance>,DELIMITED,<occurrance>,<condition_Value>
  #
  # The condition field indicates when the field will hold a value
  # a sample record would be;
  # fixed,recKey,0,10,72,8,= 28
  #
  # delimited,recKey,:,1
  # Note: the first character after the FIXED or DELIMITED is the delimiter for the ctl record values (NOT the file being processed)
  #
  # Usage: loadInlineFileCTL(<file Ref>)
  # Returns: loaded arrays
  # -----------------------------------------------------------

  my $currentSubroutine = 'loadInlineFileCTL';

  my $ctlRef = shift;                            # literal used to refer to this control file

  my $currentFieldLoc = -1;                      # current field being defined
  $condNULLisMatch = 0;

  displayDebug("loading CTL records from inline statements", 1,$currentSubroutine);

  # Check to see if the controlfile is already loaded
  if ( $ctlCache ) {                            # use already loaded version if it exists .....
    if ( defined($ctlArray{$ctlRef}) ) {        # if it is defined then use it
      displayDebug("Using already loaded CTL file ref $ctlRef", 1, $currentSubroutine);
      return;
    }
  }
  else { # dont cache so always reload the information
    if ( defined($ctlArray{$ctlRef}) ) {        # if it is defined then remove it
      displayDebug("Removing old cached version of ctlfile $ctlRef", 1, $currentSubroutine);
      $ctlLines[$ctlArray{$ctlRef}] = '';        # get rid of the existing control lines
      delete $ctlArray{$ctlRef};                 # remove the skel name referrer
    }
  }

  if ( ! defined($ctlArray{$ctlRef}) ) {         # Establish the new array entry number if one doesn't exist
    displayDebug("# Array Elements $#ctlLines", 1, $currentSubroutine);
    if ( $skelDebugLevel > 0 ) { # is it debug time?
      foreach my $tmpA ( keys %ctlArray) { displayDebug("ctlArray $tmpA: $ctlArray{$tmpA}",1,$currentSubroutine); }
    }
    $ctlArray{$ctlRef} = $#ctlLines + 1;          # allocate the next array entry
    displayDebug("Allocating $ctlArray{$ctlRef} as the new CTL Array entry for $ctlRef", 1, $currentSubroutine);
  }

  #  load the CTL Cards

  $currentSkelLine++;
  my $inCtl = '';
  my $ctlLine = '';
  my $delimiter;
  my $j = 0;

  while ( defined($skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]) ) { # if the next line exists then keep on processing
    displayDebug("Card# $currentSkelLine is $skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]",2,$currentSubroutine);

    if ( uc(substr(trim($skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]),0,14)) eq ")END_OF_INLINE" ) { # reached the inline cards terminator
      # this should be the normal return point

      adjustUnsetLengthFields($ctlRef); # set any unset length fields

      if ( $skelDebugLevel  > 0 ) { # if we are debugging
        my $numCTLLines = $#{$ctlLines[$ctlArray{$ctlRef}]} + 1;                         # number of control lines in the array slice applicable to $ctlRef
        displayDebug("Number of Inline CTL Lines accepted = $numCTLLines", 1,$currentSubroutine);
        for ( my $k=0 ; $k < $numCTLLines ; $k++) {
          displayDebug("CTL FILE Saved - Line $k - $ctlLines[$ctlArray{$ctlRef}][$k]",1,$currentSubroutine);
        }
      }

      return;
    }

    # process the next line
    $ctlLine = $skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine];
    displayDebug("Input CTL File Line: $ctlLine", 1, $currentSubroutine);

    # skip comments
    if ( uc(trim($ctlLine)) =~ /^#/ ) { # comments are basically any line that starts with a #
      $currentSkelLine++;
      next;
    }

    # validate the input control data
    if ( uc(trim($ctlLine)) =~ /^COND_NULL_IS_MATCH$/ ) { # set the flag if this control parameter is passed
      $condNULLisMatch = 1;                         # indicates that if a condition variable isn't found then it is considered a match (by default it is not)
      $currentSkelLine++;
      next;
    }

    # establish the field delimiter
    if ( uc($ctlLine) =~ /^FIXED/)        { $delimiter = substr($ctlLine,5,1); }
    elsif ( uc($ctlLine) =~ /^DELIMITED/) { $delimiter = substr($ctlLine,9,1); }
    else                                  { $delimiter = ','; }              # delimiter defaults to comma

    my @ctlVals = split (/[$delimiter]/,$ctlLine,7);                       # based on the delimiter split it into a max of 7 fields
    $ctlLines[$ctlArray{$ctlRef}][$j] = $delimiter . $ctlVals[0];      # keep the def type (first char is now the delimiter)

    if ( " FIXED DELIMITED " !~ uc($ctlVals[0]) ) {                    # first parm is not correct so just skip the whole card
      displayError("CTL Card parameter should be FIXED or DELIMITED - will be ignored",$currentSubroutine);
      $currentSkelLine++;
      next;
    }

    if ( defined($ctlVals[1]) ) {                                      # field name has been supplied
      # add the identified parameter to the verified parameter string (field name)
      $ctlLines[$ctlArray{$ctlRef}][$j] .= $delimiter . $ctlVals[1];
    }
    else {                                                             # field name has not been supplied
      displayError("CTL Card parameter must hasve a field name defined - card $ctlLine will be ignored",$currentSubroutine);
      $currentSkelLine++;
      next;
    }

    # Validate Start pos
    my $tmpk = 0;
    if (defined($ctlVals[2])) {                                         # parameter 3 exists .....
      if ( uc($ctlVals[0]) eq "FIXED" ) {                               # for a FIXED parameter ensure that it is numeric
        $tmpk = $ctlVals[2] * 1;
        if ( $tmpk ne $ctlVals[2] ) {                                   # if $parm * 1 <> $parm then there must be some non-numeric stuff in the parm
          displayError("Start Pos Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
        }
      }
      else {                                                             # for a DELIMITED parameter parm 3 is just a string
        $tmpk = $ctlVals[2];
      }
    }
    else { # not defined
      displayError("Start Pos Field/Delimiter in card " . $j . " is missing - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
    }

    # add the identified parameter to the verified parameter string
    $ctlLines[$ctlArray{$ctlRef}][$j] .= $delimiter . $tmpk;

    # Validate Length/Occurrance
    $tmpk = 0;
    if (defined($ctlVals[3])) {                                           # parameter 4 exists ..... (for fixed it is length, for delimited it is occurrance)
      $tmpk = $ctlVals[3] * 1;
      if ( $tmpk ne $ctlVals[3] ) {                                       # if $parm * 1 <> $parm then there must be some non-numeric stuff in the parm
        displayError("Length/Occurrance Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
      }
      else { # it is a number .....
        if ( uc($ctlVals[0]) eq "DELIMITED" ) { # if it is delimited then adjust the current position
          $currentFieldLoc = $tmpk;
        }
      }
    }
    else { # length/occurence not defined
      if ( uc($ctlVals[0]) eq "DELIMITED" ) { # if not provided then there is a default value for DELIMITED entries ...
        if ( $currentFieldLoc == -1 ) { # there is no current value set
          $tmpk = 0;    # start at position 0
        }
        else { # just add one to the last position
          $tmpk = $currentFieldLoc + 1;
        }
        $currentFieldLoc = $tmpk;
      }
      else {
        displayError("Length/Occurrence Field in card " . $j . " is missing - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
      }
    }

    # add the identified parameter to the verified parameter string
    $ctlLines[$ctlArray{$ctlRef}][$j] .= $delimiter . $tmpk;

    # Validate Condition Start
    $tmpk = 0;
    if (defined($ctlVals[4])) {                                           # parameter 5 exists ..... (it is either Condition Start or DELIMITED)
      if ( uc($ctlVals[4]) eq "DELIMITED" ) {                             # delimited condition
        $tmpk = $ctlVals[4];
      }
      else {                                                              # Fixed location
        $tmpk = $ctlVals[4] * 1;
        if ( $tmpk ne $ctlVals[4] ) {                                     # if $parm * 1 <> $parm then there must be some non-numeric stuff in the parm
          displayError("Condition Start Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
        }
      }
    }
    else { # not defined
      $tmpk = "";                                                         # indicates that a condition was not supplied
      displayDebug("Condition Start Field in card " . $j . " is missing - it will be set to a null value",2,$currentSubroutine);
    }
    # add the identified parameter to the verified parameter string
    $ctlLines[$ctlArray{$ctlRef}][$j] .= $delimiter . $tmpk;

    # If condition start has been supplied then do some more checking ......
    if ( $tmpk ne "" ) {                                                  # i.e. Condition Start has been defined ....

      # Validate Condition Length or Occurrance
      my $tmpk = 0;
      if (defined($ctlVals[5])) {                                         # parameter 6 exists ..... (it is either Condition Length or Occurrance)
        $tmpk = $ctlVals[5] * 1;
        if ( $tmpk ne $ctlVals[5] ) {                                     # if $parm * 1 <> $parm then there must be some non-numeric stuff in the parm
          displayError("Condition Length Field in card " . $j . " should be numeric - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
        }
      }
      else { # not defined
        displayError("Condition Length Field in card " . $j . " is missing - it will be adjusted to a numeric value of " . $tmpk,$currentSubroutine);
      }
      # add the identified parameter to the verified parameter string
      $ctlLines[$ctlArray{$ctlRef}][$j] = $ctlLines[$ctlArray{$ctlRef}][$j] . $delimiter . $tmpk;

      if ( defined($ctlVals[6])) {                                        # parameter 7 exists ..... (it is Condition value)
        # add the identified parameter to the verified parameter string
        $ctlLines[$ctlArray{$ctlRef}][$j] = $ctlLines[$ctlArray{$ctlRef}][$j] . $delimiter . $ctlVals[6];
      }
      else { # not defined so just add a delimter
        $ctlLines[$ctlArray{$ctlRef}][$j] = $ctlLines[$ctlArray{$ctlRef}][$j] . $delimiter;
      }
    }
    else { # no condition has been supplied so just blank out the last bits
      $ctlLines[$ctlArray{$ctlRef}][$j] = $ctlLines[$ctlArray{$ctlRef}][$j] . $delimiter . $delimiter;
    }
    $currentSkelLine++;
    $j++;
  } # end of while looking for )END_OF_INLINE

  # really should never get here - to be here you have hit the end of the skeleton and
  # not found an )END_OF_INLINE

  adjustUnsetLengthFields($ctlRef); # set any unset length fields

  displayError("[loadInlineCards] Did not find a )END_OF_INLINE card", $currentSubroutine);

} # end of loadInlineFileCTL

sub setVariable {
  # -----------------------------------------------------------
  # This routine will modify the internal skeleton variable values
  #
  # Usage: setVariable('Name','Value');
  # Returns: nothing
  # Updates: skelVarArray
  # -----------------------------------------------------------

  my $currentSubroutine = 'setVariable'; 

  my $vName = shift;
  my $vValue = shift;

  $skelVarArray{$currentScope}{$vName} = $vValue;
  displayDebug("Variable $vName has been set to " . $skelVarArray{$currentScope}{$vName},1,$currentSubroutine);

  # Set the special skeleton variable 
  if ( uc($vName) eq "SKL_SHOWSQL" ) {
    if ( uc($vValue) eq "YES" ) { $skelShowSQL = 'Yes'; }
    else { $skelShowSQL = 'No'; }
  }

  # Set the special skeleton variable 
  if ( uc($vName) eq "SKL_VERBOSE_ERRORS" ) {
    if ( uc($vValue) eq "YES" ) { $skelVerboseSQLErrors = 'Yes'; }
    else { $skelVerboseSQLErrors = 'No'; }
  }

} # end of setVariable

sub getVariable {
  # -----------------------------------------------------------
  # This routine will return a variable value
  #
  # Usage: getVariable('Name');
  # Returns: value of variable
  # -----------------------------------------------------------

  my $currentSubroutine = 'getVariable'; 

  my $vName = shift;
  
  for ( my $i = $#scopeStack; $i >= 0 ; $i-- ) { # look back through the scope stack to see if the variable can be found
    if ( defined($skelVarArray{$scopeStack[$i]}{$vName})) { # variable exists
      displayDebug("Variable $vName has returned a value of " . $skelVarArray{$scopeStack[$i]}{$vName} . " from scope $scopeStack[$i]", 1, $currentSubroutine);
      return $skelVarArray{$scopeStack[$i]}{$vName};
    }
  }

  displayDebug("Variable $vName does not exist in any of the scopes available", 1, $currentSubroutine);

  return undef;

} # end of getVariable

sub setBaseVariables {
  # -----------------------------------------------------------
  # Establish the variable that are always available to the 
  # skeleton processor
  # 
  # Usage: setBaseVariables();
  # Returns: nothing
  # -----------------------------------------------------------

  my $currentSubroutine = 'setBaseVariables'; 

  if ( $^O eq "MSWin32") { # Establish the CRLF variable based on platform
    setVariable("crlf", "\cM\cJ") ;
  }
  else {
    setVariable("crlf", "\cJ") ;
  }
  if ( defined($machine) ) { setVariable("machine", $machine); }               # define machine
  if ( defined($skelViewQual) ) { setVariable("viewQual", $skelViewQual); }
  if ( defined($skelSID) ) { setVariable("SID", $skelSID); }
  if ( defined($skelTNS) ) { setVariable("TNS", $skelTNS); }
  if ( defined($skelUserID) ) { setVariable("userID", $skelUserID); }
  $a = calcVersion();
  setVariable('calcVers', $a);
  $a = commonVersion();
  setVariable('commVers', $a);
  $a = skelVersion();
  setVariable('prSkelVers', $a);
  setVariable('lastError','');


} # end of setBaseVariables 

sub setPassedParameters { 
  # -----------------------------------------------------------
  # set the value of the passed parameters 
  #
  # Usage: setPassedParameters();
  # Returns: nothing
  # -----------------------------------------------------------

  my $currentSubroutine = 'setPassedParameters';

  my $parameters = shift;

  my @PSplit = split(",",$parameters);                           # split the passed parameters into tuples based on a ',' character
  my $tuple;                                                    # will hold the A=x tuple

  foreach $tuple (@PSplit) {
    if ( $tuple =~ /=/ ) {                                      # if it includes an equals sign
      my ($var,$val) = split("=",$tuple);                       # split around the equals sign to give parm and value
      displayDebug("Parameter $var has a value of $val",2,$currentSubroutine);
      if ( trim($val) ne "" ) {
        setVariable($var, $val);                                # set the variable value if thevariable isn't blank
      }
    }
    else { # parameter is just a flag
      if ( uc($tuple) =~ "SHOWSQL" ) {                          # if parameter contains SHOWSQL 
        $skelShowSQL = "Yes";                                   # then set the internal variable (i.e not the 'skeleton' variable
      }
      elsif ( uc($tuple) eq "VERSIONS" ) {                      # if the parameter is versions 
        $a = calcVersion();                                     # then just print out the versions of all of the components
        print "$a\n";
        $a = commonVersion();
        print "$a\n";
        $a = skelVersion();
        print "$a\n";
      }
    }
  }

} # end of setPassedParameters

sub processSkeleton {
  # --------------------------------------------------------------------------------------
  #
  # The main process of the script - this is the called function.
  #
  # It is called as processSkeleton('table.skl')
  #
  # If the file does not exist in the current working directory then the working directory
  # needs to be set as an environment variable called SKELDIR
  #
  # prior to being called the 'procLit' variable and the 'outputMode' should be set
  # 'outputMode' defines how the result wll be returned :
  #       STDOUT - output will be generated to STDOUT
  #       HTTP and HTTPFILE - output will be returned as the string returned from this sub
  #
  # --------------------------------------------------------------------------------------

  # establish the DBI routines required .....

  if ( $DBIModule ne '' ) { # a DBI module has been set ....
    require DBI;
    import DBI;
    if ( uc($DBIModule) =~ 'DB2' ) { # DBI::DB2 module requested
      require DBD::DB2;
      import DBD::DB2;
    }
    elsif ( uc($DBIModule) =~ 'SQLITE' ) { # DBI::SQLite module requested
      require DBD::SQLite;
      import DBD::SQLite;
    }
    elsif ( uc($DBIModule) =~ 'ODBC' ) { # DBI::ODBC module requested
      require DBD::ODBC;
      import DBD::ODBC;
    }
  }
  
  # re-initialise some data structures just in case process Skeleton is called twice
  
  %skelArray = ();                       # associative array holding the array number where lines are held
  @skelLines = ();                       # 2 dimensional array holding the skeleton lines (referenced as $skelLines[$skelName{<Name>}][<line number>]
  @imbedStack = ();                      # stack variable used to hold position in skeletons while processing IMBED statements
  %skelVarArray = ();                    # Array holding skeleton variables
  $currentSkelLine = -1;                 # variable containing record number being processed in current Array
  $currentActiveSkel = "";               # skeleton currently being processed
  $skelDOTCount = 0;                     # initialise the )DOT/)ENDDOT balancing count
  $skelSELCount = 0;                     # initialise the )SEL/)ENDSEL balancing count
  @controlStack = ();                    # initialise the stack controlling )SEL and )DOT interactions
  
  my $currentSubroutine = 'processSkeleton'; 

  my $skeleton = shift;     # skeleton to process
  my $parameters = shift;   # seed parameters of the form A=1,B=2,C=3,....

  if ( defined($parameters) ) {
    $parameters =~ s/\\/&#92/g; # replace all backslashes with their ascii code
    setPassedParameters($parameters);          # set the passed parameters
  }

  # Initialise some variables ....
  
  setVariable('traceLevel',$skelDebugLevel);        # set the traceLevel variable
  setVariable('initialSkeleton',$skeleton);         # set the initialSkeleton variable
  setVariable('currentSkeleton',$skeleton);         # set the currentSkeleton variable

  # load the initial skeleton

  displayDebug ("Loading Skeleton $skeleton",1,$currentSubroutine);
  loadSkel($currentScope,$skeleton);     # load the initial skeleton
  setBaseVariables();
  
  # Main processing loop .....

  my $linesToProcess = 1;

  while ( $linesToProcess ) { # while there is still a line to process ....
    # current line is defined as : $skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]
    my $card = $skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine];
    displayDebug ("Processing Loop: $currentActiveSkel card number $currentSkelLine", 2,$currentSubroutine); 
    displayDebug ("Card $currentSkelLine = $card", 1,$currentSubroutine); 
    
    if ( substr( $card,0,1) eq ')' )  { # it is a control card (always processed in case they reset $skelSelSkipCards or $skelDOTSkipCards
      # clear out the last error message variable
      $statementError = '';
    
      processControlCard($card);
      setVariable('lastStatementError', $statementError);
    }
    else { # it's not a control card ....
      if ( ( $skelSelSkipCards eq "No" ) && ( $skelDOTSkipCards eq "No" ) ) { # not skipping cards
        processLine($card);
      } 
      else { # card was skipped
        displayDebug("Skipped: $card. Sel Skip = $skelSelSkipCards, SEL Count = $skelSELCount, SEL Resume Level = $skelSEL_resumeLevel, Dot Skip = $skelDOTSkipCards, DOT Count = $skelDOTCount, DOT Resume Level = $skelDOT_resumeLevel",2,$currentSubroutine);
      }
    }
    
    # line processed so go to next line ...
    
    $currentSkelLine++;
    
    if ( defined($skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]) ) { # if the next line exists then keep on processing
      displayDebug("Card# $currentSkelLine is $skelLines[$skelArray{$currentActiveSkel}][$currentSkelLine]",2,$currentSubroutine);
    }
    else { # see if we were processing an imbed and if so reinstate the previous skeleton
      if ( $#imbedStack > -1 ) { # stuff on the stack to process
        # clear out the old variable scope as necessary
        my $tempScope = pop(@scopeStack);                    # remove the current scope from the stack
        clearVariableScope($currentScope);
        $currentScope = pop(@imbedStack);                    # reset the variable scope
        $currentSkelLine = pop(@imbedStack);
        $currentSkelLine++;                                  # move to the line after the )IMBED
        $currentActiveSkel = pop(@imbedStack);
        setVariable('currentSkeleton',$currentActiveSkel);         # set the currentSkeleton variable
        displayDebug("Values pulled from imbedStack: \$currentSkelLine = $currentSkelLine, \$currentActiveSkel = $currentActiveSkel",2,$currentSubroutine);
        displayDebug("Continuing to process skeleton $currentActiveSkel",2,$currentSubroutine);
      }
      else { # it's all over
        displayDebug("no more skeletons to process",1,$currentSubroutine);
        $linesToProcess = 0;
      }
    }
  } 

  if ( $skelSELCount > 0 ) { # this should be zero at exit
    displayError(")ENDSEL missing - )SEL / )ENDSELs not balanced. $skelSELCount )ENDSEL statement(s) missing", $currentSubroutine);
  }

  if ( $skelDOTCount > 0 ) { # this should be zero at exit
    displayError(")ENDDOT missing - )DOT / )ENDDOTs not balanced. $skelDOTCount )ENDDOT statement(s) missing", $currentSubroutine);
  }

  return $skelReturnString;                                        # return the generated string

} # end of processSkeleton

1;

