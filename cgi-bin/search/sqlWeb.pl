#!/usr/bin/perl  -w

#############################################################################
##
## Copyright 2000. NCGR. All rights reserved.
## 
## clone_search.pl - Process the clone_search page for Arabidopsis.
##
#############################################################################

use CGI;
$ENV{'ORACLE_HOME'}='/opt/oracle/11.2.0/client';
use DBI;
use DBD::Oracle;
use CGI::Carp qw(fatalsToBrowser);
#use Sybase::DBlib;


use strict 'vars';
use vars qw( $debug $dbh $timeout_sec $database );

$| = 1;				# Flush output

my $debug = 1;
my $dbh;			# Database pointer
my $database = 'tairprod';
my $timeout_sec = 50;  ## timeout in seconds

#############################################################################
##
## fixQuotes
##
#############################################################################

sub fixQuotes()
  {
    my ( $string ) = @_;
    $string =~ s/\'/\'\'/g;
    return $string;
  } # fixQuotes()

#############################################################################
##
## fixBlanks
##
#############################################################################

sub fixBlanks()
  {
    my ( $str ) = @_;
    return ( $str eq '' ) ? '&nbsp;' : $str;
  } # fixBlanks()

#############################################################################
##
## queryDb - Submit a query and view results
##
#############################################################################

sub queryDb($$$$)
  {
    my ( $str, $dbh, $low, $high ) = @_;
    
    $str =~ s/^select//i;
    $str =~ m/^(.*)\b(from|FROM)\b(.*)\b(where|WHERE)/;
    
    my $what  = $1;
    my $table = $3;
    
    if ( $what eq '' ) 
      {				# catch case of no where clause
	$str =~ m/^(.*)\b(from|FROM)\b(.*)/;
	$what = $1;
	$table = $3;
      }
    
    my $newStr = "select " . $str;
    $newStr =~ s/\;$//;
    
    print( "<P><B>DATABASE</B>=$database\n" );
    print( "<BR><B>RANGE</B>=[$low:$high]\n" );
    print( "<BR><B>QUERY</B>=$newStr</P>\n" );
    
    my $sth = $dbh->prepare( $newStr );
    $sth->execute() || errorCheck( $dbh );
    
    my @column_names = @{$sth->{NAME}};
    
    print( "<table border=1>\n" );
    
    #print the table header
    print( "<tr>" );
    print( "<td valign=\"top\"><font size=\"-1\"><b>#</b></font></td>" );
    foreach my $name (@column_names) 
      {
	$name =~ s/_/ /g;
	print( "<td valign=\"top\"><font size=\"-1\"><b>$name</b></font></td>" );
      }
    print( "</tr>\n" );
    
    my $count;
    for ( $count=1; my @row = $sth->fetchrow_array; $count++ ) 
      {
	if ( $count < $low  ) { next; }
	if ( $count > $high ) { last; }
	print( "<tr>" );
	print( "<td valign=\"top\">$count</td>" );
	foreach my $val ( @row ) 
	  { print( "<td valign=\"top\">$val</td>" ); }
	print( "</tr>\n" );
      }
    print( "</table>\n" );
    
  } # queryDb()

#############################################################################
##
## queryDbTxt - Submit a query and view results as plain text.
##
#############################################################################

sub queryDbTxt($$$$)
  {
    my ( $str, $dbh, $low, $high ) = @_;
    
    $str =~ s/^select//i;
    $str =~ m/^(.*)\b(from|FROM)\b(.*)\b(where|WHERE)/;
    
    my $what  = $1;
    my $table = $3;
    
    if ( $what eq '' ) 
      {				# catch case of no where clause
	$str =~ m/^(.*)\b(from|FROM)\b(.*)/;
	$what = $1;
	$table = $3;
      }
    
    my $newStr = "select " . $str;
    $newStr =~ s/\;$//;
    
    my $sth = $dbh->prepare( $newStr );
    $sth->execute() || errorCheck( $dbh );
    
    my @column_names = @{$sth->{NAME}};
    
    print( join( "\t", @column_names ));
    print( "\n" );
    
    my $count;
    for ( $count=1; my @row = $sth->fetchrow_array; $count++ ) 
      {
	if ( $count < $low  ) { next; }
	if ( $count > $high ) { last; }
	print( join( "\t", @row ));
	print( "\n" );
      }
  } # queryDbTxt()

#############################################################################
##
## errorCheck
##
#############################################################################

sub errorCheck()
  {
    my ( $dbh ) = @_;
    my $err = $dbh->errstr;
    print( "<h1>ERROR!</h1><P>$err</P>" );

  } # errorCheck()

#############################################################################
##
## abortProcess
##
#############################################################################

sub abortProcess()
  {
    print( "<h1>ERROR!</h1><P>Query exceeded timeout of $timeout_sec seconds of CPU</P>" );
    exit( 0 );

  } # abortProcess()

#############################################################################
##
## Start of main body
##
#############################################################################

main();
sub main 
  {
    # Open CGI
    
    my $q;
    $q = new CGI;
    my @cgiNames = $q->param;
    
    # Production DB defaults
    #
    my $server = 'ARGENTINA';
    my $port = 1521;
    my $user = "tairwebsql";
    my $password = "watchme";

    
    if ( $q->param('db') eq 'tairtest' ) 
      {
	
	$server = 'wales';
	$database = 'tairtest';
      }
    
    my $low  = $q->param('low');
    my $high = $q->param('high');
    

    # Open database
    $dbh = DBI->connect("dbi:Oracle:host=$server;port=$port;sid=$database",$user,$password,{AutoCommit=>1,RaiseError=>1});
    if ( $dbh->err ) 
      {
	die "<h1>Could not open $database on $server</h1>\n";
      }
    
    if ($q->param('as_text') eq 'y') 
      {
	print( "Content-type: text/plain\n\n" );
	local $SIG{ALRM} = \&abortProcess;
	alarm($timeout_sec);
	queryDbTxt( $q->param('query'), $dbh, $low, $high );	
      }
    else 
      {
	# Make it go
	
	print( $q->header );
	# print $q->start_html( "TAIR: Results of clone search" );

	print( "<HTML>\n<HEAD>\n<TITLE>SQL Results</TITLE>\n" );
	print( "</HEAD>\n<BODY>\n" );

	local $SIG{ALRM} = \&abortProcess;
	alarm($timeout_sec);
	queryDb( $q->param('query'), $dbh, $low, $high );

	print( "</body>\n</html>\n" );
    }

    exit 1;

} # main()


