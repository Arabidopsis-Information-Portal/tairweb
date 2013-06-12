#!/bin/env perl

#########################################################################
# Copyright: (c) 2003 National Center for Genome Resources (NCGR)
#            All Rights Reserved.
# $Log: nph-patmatch.pl,v $
# Revision 1.24  2006/10/11 18:15:15  tacklind
# removed extra old footer at bottom of page
#
# Revision 1.23  2006/10/10 20:55:29  tacklind
# *** empty log message ***
#
# Revision 1.22  2005/07/27 15:51:32  nam
# corrected path to perl interpreter
#
# Revision 1.21  2005/07/26 21:01:20  tacklind
# per Thomas
#
# Revision 1.12  2005/07/19 00:37:27  tyan
#
# Revision 1.11  2005/07/15 21:01:00  tyan
# Applied fixes made to patmatchPatternChecker.pl here.  This is duplicated code
# and should be cleaned up.  Fixes were made in response to bug report
# PR#2876.
#
# Revision 1.10  2005/07/11 17:40:31  tyan
# Added explanations to clarify what patterns mean.
#
# Revision 1.9  2004/09/07 20:48:15  tyan
# Checks for warnings from the remote server, and displays them to the user.
#
# Revision 1.19  2004/08/24 16:37:28  nam
# Updates from Thomas
#
# Revision 1.8  2004/08/23 23:10:31  tyan
# Added update gifs to peptide syntax
#
# Revision 1.7  2004/08/23 22:48:23  tyan
# User interface updates and check for minimum length of input pattern.
#
# Revision 1.6  2004/08/13 16:34:10  tyan
# Fixed 6220 bug and HTML formatting of tables.
#
# Revision 1.13  2004/08/04 18:30:33  nam
# Patmatch update from Thomas - remove obsolete scan for matches binary
#
# Revision 1.4  2004/08/03 20:58:29  tyan
# Fixed syntax error.
#
# Revision 1.3  2004/08/02 23:13:35  tyan
# param line in checkPattern()
#
# Revision 1.2  2004/08/02 23:02:44  tyan
# Merging changes.
#
# Revision 1.12  2004/06/28 21:32:30  dcw
# Forced all jobs to run on the long queue on the farm.
#
# Revision 1.11  2004/05/12 22:10:22  nam
# Remove RemotePatmatch.pm; alter nph-patmatch to use generic RemoteCluster module for communicating with remote analysis farm
#
# Revision 1.10  2004/05/11 23:27:05  nam
# Alter to use cluster configuration module for connection settings
#
# Revision 1.9  2004/05/06 22:49:43  nam
# change master host to blaster03
#
# Revision 1.8  2004/04/19 21:29:22  nam
# remove perldocs referencing newSTOP.pl (not used)
#
# Revision 1.7  2004/02/10 21:50:02  dcw
# Added error handler to prevent the user from performing a wildcard search
# on a peptide that also includes a mismatch, insertion or deletion.
#
# Revision 1.6  2004/01/28 00:22:14  dcw
# Fixed bug where server->Submit function had two parameters (insertion and
# deletion) inverted in order.
#
# Revision 1.5  2004/01/22 00:02:06  dcw
# Remove lines that modify the pattern if mismatch, deletion or insertion is
# selected because that work is now done in runPatmatch.pl on the analysis
# cluster.
#
# Revision 1.4  2004/01/19 19:15:33  dcw
# Changed the manner that sequences are retrieved from the runPamatch.pl program
# that runs remotely and writes the sequences into a separate file without
# redundancy.
#
# Revision 1.3  2003/12/16 23:38:10  dcw
# Reset the server name to blaster01
#
# Revision 1.2  2003/11/24 22:07:07  dcw
# Added new temporary file for the seqeunce data read from runPatmatch.pl
#
#
# newpatmatch
# Based on nph-patmatch. Modified Nov 2001 by Lukas Mueller.
# Added newpatmatch.conf file that reads configuration from file
# Re-wrote patTable as patTable.pl in Perl
# Re-wrote getSequence as newGetSequence.pl using BioPerl. Supports automatic indexing
#   of fasta files - needs write access to the data directory to do so. 
#   (grp = nobody etc.)
# 
#########################################################################

use CGI qw/:standard :html -nph/;
use CGI::Carp qw( fatalsToBrowser );
use Parse::RecDescent;

use lib "../cluster";
use RemoteCluster;

require '../format_tairNew.pl';
require '../untaint.pl';

# Global Variables

use strict 'vars';
use vars qw( $debug 
             $pattern 
             $originalPattern 
             $strand 
             $class 
             $maxhits 
             $mismatch 
             $deletion 
             $insertion
	     $substitution
	     $minSeqHits
	     $maxSeqHits
             $extendedPattern 
             $dir
             $tmpDir
             $data_file
             $MAXHIT 
             $db
             %databases 
             %databaseDisplayHash 
             @databaseDisplay 
           );

$MAXHIT = 250000;  # absolute maximum number of hits allowed
my $MESSAGE = "Please click on your browser's BACK button, make the " .
    "necessary correction, and submit again."; # message used by error checker

# %databases - keeps hash for easy referencing by key when we want it - stored as 
# display value as key referencing dataset file name

# @databaseDisplay - holds dataset display values in array so we can create menu 
# that displays in the order they come out of config file

# %databaseDisplayHash - keeps another hash of databases, but with file name as key 
# referencing display value - need this for easy translating both ways

#$debug = "TRUE";   # Uncomment this field to cause debug output to appear in the log

# Read configuration file


my $config_file = "newpatmatch.conf";
open( CONF, "<$config_file" ) || 
    die "Can't read newpatmatch configuration file $config_file";

while ( <CONF> ) 
{
    chomp();
    my $line = $_;
    my $tag;
    if ( $line =~ /^\#/ ) { next; }
    if ( $line =~ /^dataset_file/i ) { ( $tag, $data_file ) = split /\t/, $line; }
    if ( $line =~ /^tempdir/i ) { ( $tag, $tmpDir ) = split /\t/, $line; }
    if ( $line =~ /^homedir/i ) { ( $tag, $dir ) = split /\t/, $line; }
}

close( CONF );

open( DATA, $data_file ) or die "Cant open data file $data_file";

<DATA>; # First line just has head info

my $last_group = "";
while (<DATA>) {
    chomp();
    my $line = $_;
    my ($name, $type, $num_seqs, $residues, $date, $desc) = split /\t/, $line;

    if ($type and $name ne 'gp_GB_genomic_DNA' and $name ne 'gp_GB_exp_tx_DNA') {
	if ($type eq 'AA') {
	    $type = 'protein'
	}

	my $display = "$desc ($type)";

	$display =~ /^(\S+)/;
	my $group = $1;

	if ($last_group ne "" && $group ne $last_group) {
	    my $blank = '-------------';
	    $databases{$blank} = $blank;
	    $databaseDisplayHash{$blank} = $blank;
	    push (@databaseDisplay, $blank);
	}

	$databases{$display} = $name;
	$databaseDisplayHash{$name} = $display;
	push (@databaseDisplay, $display);

	$last_group = $group;
    }
}

close( DATA );

#$tmpDir = "$ENV{DOCUMENT_ROOT}/../tmp/patmatch";
#$dir = "$ENV{DOCUMENT_ROOT}/cgi-bin/patmatch";

$| = 1;  # output autoflush

# If no parameters are provided with the URL, then present the user with the form page.
# That page will exit.

presentForm() unless param;

# Otherwise process the user inputs, run the application and display the results.

printCgiHeader(); 
processForm();
prepareResults();
runPatmatch();

exit();

#############################################################################
##
##  SUBROUTINE NAME
##    processForm()
##
##  SYNOPSIS 
##    processForm()
##
##  DESCRIPTION
##    Gets the CGI parameters sent from the form page and ascertains if the selections 
##    by the user are valid.  If an invalid condition is found, then an error page 
##    is displayed explaining the error.  This subroutine also processes the pattern.
##
##  GLOBAL VARIABLES
##    $pattern - (out) Pattern to be used in the search
##    $originalPattern - (out) Copy of pattern before any processing
##    $class - (out) Class type: "watson", "crick" or "both"
##    $db - (out) Name of the database to search
##    $maxhits - (out) Maximum number of hits allowed
##    $strand - (out) Strand type: "dna" or "pep"
##    $mismatch - (out) 
##    $deletion - (out) 
##    $insertion - (out)
##    $substitution - (out)
##    $minSeqHits - (out) Minimum number of hits per sequence
##    $maxSeqHits - (out) Maximum number of hits per sequence 
##    $extendedPattern - (out) 
##
##  RETURN VALUE
##    none
##
#############################################################################

sub processForm 
{
    $pattern = param( 'pat' );

    ## Note: $pattern should NOT be untainted using untaint.pl.
    ## Otherwise, we lose several of the special pattern characters that
    ## untaint strips out.

    $pattern =~ s/ //g;
    $pattern =~ s/\15//g;
    $pattern =~ s/\12//g;
    $pattern =~ s/\-//g;
    $pattern =~ s/\&//g;
    $originalPattern = $pattern;
  
    $class = untaint( param( 'seq_class' ) );

    if ( $class =~ /^nuc/ ) { $class = "dna"; }
    else { $class = "pep"; }
  
    # save dataset file name

    $db = untaint( param( 'current_db' ) );

    # translate file name into display name

    my $database = $databaseDisplayHash{ $db };
  
    if ( param( 'maxhits' ) ) { $maxhits = untaint( param( 'maxhits' ) ); }

    if ( $maxhits && $maxhits == $MAXHIT ) { $maxhits = $MAXHIT; }
    elsif ( !$maxhits || $maxhits !~ /^[0-9]+$/ ) { $maxhits = 100; }

    $strand = "both";

    if ( param( 'strand' ) ) { $strand = untaint( param( 'strand' ) ); }

    if ( $strand )
    {
        if ( $strand =~ /^Watson/ ) { $strand = "watson"; }
        elsif ( $strand =~ /^Crick/ ) { $strand = "crick"; }
        else { $strand = "both"; }
    }

    if ( param( 'mismatch' ) )
    { $mismatch = untaint( param( 'mismatch' ) ); }

    if ( param( 'deletion' ) )
    { $deletion = untaint( param( 'deletion' ) ); }

    if ( param( 'insertion' ) )
    { $insertion = untaint( param( 'insertion' ) ); }

    if (param( 'substitution' ) )
    { $substitution = untaint( param ( 'substitution' ) ); }

    if (param( 'min_seq_hits' ) )
    { $minSeqHits = untaint( param ( 'min_seq_hits' ) ); }

    if (param( 'max_seq_hits' ) )
    { $maxSeqHits = untaint( param ( 'max_seq_hits' ) ); }

    if ( !$mismatch || $mismatch !~ /^[0-9]+$/ ) 
    { $mismatch = 0; }

    if ( !$minSeqHits || $minSeqHits !~/^[0-9]+$/ )
    { $minSeqHits = 1; }
    
    if ( !$maxSeqHits || $maxSeqHits !~/^[0-9]+$/ )
    { $maxSeqHits = 100; }

    if ( $minSeqHits > $maxSeqHits)
    {
	my $temp = $minSeqHits;
	$minSeqHits = $maxSeqHits;
	$maxSeqHits = $minSeqHits;
    }
  
    $extendedPattern = "no";

    if ( $class eq "pep" && 
         $database !~ /\(Protein\)/i )
    {
        errorReport( "Your choice of Database (\"$db\") does not match the " .
                     "choice of the peptide pattern type. Peptide pattern " .
                     "requires a protein sequence database. Nucleotide " .
                     "pattern requires a nucleotide sequence database. " .
                     "<p> Please click on BACK button to return to the form " .
                     "and then adjust either the pattern type or database " .
                     "selection. " );
    }

    if ( $class eq "dna" && 
         $database !~ /\(DNA\)/i ) 
    {
        errorReport( "Your choice of Database (\"$db\") does not match the " .
                     "choice of the nucleotide pattern type. Nucleotide " .
                     "pattern requires a nucleotide sequence database. " .
                     "Peptide pattern requires a protein sequence database. " .
                     "<p> Please click on BACK button to return to the form " .
                     "and then adjust either the pattern type or database " .
                     "selection. " );
    }

    if ( length( $pattern ) > 40 && 
         $pattern =~ /^[A-Za-z]+$/ ) 
    {
        errorReport( "PatMatch is designed for short (<20 residues) " .
                     "sequences, or ambiguous - degenerate patterns. If you " .
                     "are searching for a sequence >20 bp or aa with no " .
                     "degenerate positions, please use " .
                     "<a href=\"/blast/\">BLAST</a> or " .
                     "<a href=\"/cgi-bin/fasta/nph-TAIRfasta.pl\">FASTA</a>." .
                     " BLAST will be about 100 times faster than PatMatch. " .
                     "PatMatch is not a replacement for BLAST and FASTA. " .
                     "Thanks!" );
    }

    # Error check the pattern.
  
    checkPattern( $pattern );

    debug( "Pattern = $pattern" );
  
}  # processForm()

#############################################################################
##
##  SUBROUTINE NAME
##    prepareResults()
##
##  SYNOPSIS 
##    prepareResults()
##
##  DESCRIPTION
##    Prepares the browser page for the run.  A message is displayed informing 
##    the user that the program is queued and please don't hit the stop button 
##    as the user will not get the program to run faster by doing so but will 
##    actually be put to the end of the queue.
##
##  RETURN VALUE
##    none
##
#############################################################################

sub prepareResults 
{
  

    tair_header( "TAIR PatMatch Results" );

    print( center( p(), img( { -src=>"/images/line.red2.gif" } ) ), "\n" );

    print( br(),
           br(),
           p( "Your PatMatch request has been queued and will be processed. ",
              font( { -color=>"red" }, "Please ",
                    b( "do not" ),
                    "hit \"Stop\" and resubmit your job" ),
              ".  Such action will add to the queue of jobs already in ",
              "progress and have the effect of placing your request to ",
              "the end of the line." ),
           p( center( img( { -src=>"/images/coffeecup.gif",
                             -width=>45,
                             -height=>52 } ) ) ) 
         );

}  # prepareResults()

#############################################################################
##
##  SUBROUTINE NAME
##    runPatmatch()
##
##  SYNOPSIS 
##    runPatmatch()
##
##  DESCRIPTION
##    Executes the program for performing the search and parses the results 
##    into two data files for use by patTable.pl which will handle displaying 
##    the results and parses the data into multiple pages if necessary.
##
##  ARGUMENTS
##    
##
##  RETURN VALUE
##    none
##
#############################################################################

sub runPatmatch 
{ 
    print( center( "PatMatch Search is now Starting..." ), "\n", 
           p(), "\n" );
  
    # Define the priority of the remote processing.  Most programs are run on the
    # short queue but exceeding long program executions should be put on the long 
    # queue.  One of the obvious indicators of a slow process that should be put on 
    # the long queue is one that has to process a very large database.  Currently 
    # two groups of databases that are very large are the brassica and Plant data 
    # sets.  THIS PRIORITY SHOULD BE UPDATED ACCORDINGLY AS THE CONFIG FILE IS UPDATED.

    my $priority = 0;  # long queue always
#    my $priority = 1;  # short queue
#    if ( $db =~ /brassica/ or
#         $db =~ /Plant/ )
#    {
#        $priority = 0;  # long queue
#    }

    # Create RemoteCluster instance to handle communication 
    # with  Analysis Farm
    my $server = RemoteCluster->new();

    # Create command string to run on remote server.  Enclose
    # all args (except program name and database, which use 
    # ENV vars defined on cluster side) in single quotes to prevent
    # command line mangling
    my $command = 
      "\$PATMATCH/runPatmatch.pl " .
      "'$pattern' '$strand' '$class' " .
	"\$PATREF/$databases{ $databaseDisplayHash{ $db } } " .
	  "'$mismatch' '$insertion' '$deletion' '$substitution' " .
	  "'$maxhits' '$minSeqHits' '$maxSeqHits'";

    # submit job and get initial response
    my %args = ( 'priority' => $priority,
		 'command' => $command );

	print STDERR "COMMAND\t$command\n";

    my $response = $server-> Submit( %args );

    # Query the remote server for the status of the job.  A requirement is to 
    # continually write to the browser so that the application doesn't timeout on 
    # long jobs.  Initially the job will be queued and then it will start running.
    # We can indicate to the user which state the job is in and how long with a 
    # continuous update.

    my $queued = 0;
    my $running = 0;

    do
    {
        $response = $server->Status();
        if ( $response =~ "PleaseRun" )
        {
            if ( not $queued )
            {
                $queued = 1;
                print( ">>>Queued" );
            }
            else
            { print( "*" ); }

            sleep( 1 );
        }
        elsif ( $response =~ "Running" )
        {
            if ( not $running )
            {
                $running = 1;
                print( "<br>>>>Running" );
            }
            else
            { print( "*" ); }

            sleep( 3 );
        }
        else
        { print( "<br>" ); }
    } 
    while ( $response =~ "PleaseRun" || $response =~ "Running" );

    # Check for errors.  Error log will be the output to STDERR generated by
    # nrgrep_coords as it ran.  If the errors are warnings, save the warnings
    # to be printed along with the output, otherwise treat the errors as fatal
    # errors.
    my @warnings;
    my $errorLog = $server->ErrorLog();
    if ( length( $errorLog ) > 5 )
    { 
	my @lines = split( /\n/, $errorLog );
	my $errorFlag = 0;
 
	my %warning_hash; # store warnings as keys
	foreach my $line (@lines) {
	    if ( $line =~ /Warning/ ) {
		$warning_hash{$line} = 1;
	    } else {
		$errorFlag = 1;
		last;
	    }
	}

	if ( $errorFlag ) {
	    $server->CleanUp();
	    htmlError( "<b>ERROR: $errorLog<br>" ); 
	}
        
	# Build the warning array if there are any warnings
	if ( keys( %warning_hash ) ) {
	    foreach my $key (keys %warning_hash) {
		push( @warnings, $key );
	    }
	}
    }

    # Retrieve the results.

    my $myResult = $server->Retrieve();

    $server->CleanUp();

    # Print any warnings received from remote server
    if (@warnings) {
	print "\nJob completed with the following warnings:<br>\n";
	foreach my $warning (@warnings) {
	    print "$warning<br>\n";
	}
	print "<br>\n";
    }

    # Write the results to a temporary file.

    my $tmpFile = "$tmpDir/patmatch.tmp.$$";
    open( TMP, ">$tmpFile" )
        or die( "Can't create output file $tmpFile $!" );
    print( TMP $myResult );
    close( TMP );

    # Now open the temporary file and write two new files from this one.

    open( TMP, "<$tmpFile" )
        or die( "Can't create output file $tmpFile $!" );

    # Write the param file.  Two of the parameters in this file are in the first
    # line of the temporary file.

    my $line = readline( *TMP );
    my ( $numSeqsHit, $numHitsFound, $numSeqsSearched, $numBytesSearched ) = 
        split( /\t/, $line );

    my $paramFile = "$tmpDir/patmatch.param.$$";
    open( PARAM, ">$paramFile" ) || 
        die( "nph-patmatch: Can't open '$paramFile' for writing:$!\n" );
    print( PARAM "$db $strand $originalPattern $extendedPattern $mismatch " .
           "$deletion $insertion $substitution $numSeqsHit $numHitsFound " . 
	   "$maxhits $numSeqsSearched $numBytesSearched\n" ); 
    debug( "WRITING TO $paramFile: $db $strand $originalPattern " .
           "$extendedPattern $mismatch $deletion $insertion $substitution " .
	   "$numSeqsHit $numHitsFound $maxhits $numSeqsSearched " . 
	   "$numBytesSearched\n" );   
    close( PARAM );

    # Write the rest of the results to the pattern and sequence files.

    my $readingSequences = 0;
    my $patternFile = "$tmpDir/patmatch.pattern.$$";
    my $seqFile = "$tmpDir/patmatch.seq.$$";
    open( PAT, ">$patternFile" );
    open( SEQ, ">$seqFile" );
    while ( <TMP> )
    { 
        chomp();

        # If the sequence data haven't been found, compare the current line with the
        # flag used to signal the end of the pattern data and the beginning of the
        # sequence data.  If found, set the $readingSequences to true and skip to the
        # next record in the tmp file.

        if ( not $readingSequences )
        { 
            if ( $_ eq "SEQUENCES" )
            { 
                $readingSequences = 1;
                next;
            }
        }

        # If not reading sequences, read the data into the pattern file.

        if ( not $readingSequences )
        {
            my ( $id, $freq, $beg, $end, $patseq ) = split( / /, $_ );

            if ( $beg > 0 )
            { print( PAT "$id $freq $beg $end $patseq\n" ); }
        }

        # Otherwise we're reading the sequence data and writing the data to the 
        # sequence file.

        else
        {
            my ( $id, $fullseq, @desc ) = split( / /, $_ );
            print( SEQ "$id $fullseq @desc\n" );
        }
    }

    # Close all of the open files.

    close( PAT );
    close( SEQ );
    close( TMP );

    # Delete the temporary file as it is no longer required.

    unlink( $tmpFile );

    # Sort the pattern file in reversed order: using option -r among others

    system( "sort +1rn -2 +0 -1 +2n -4 $patternFile " .
            "-o $patternFile 2>/dev/null" ) && 
                debug( "sorting didn't work" );

    # Execute the patTable.pl script to send the output to the user.

    system( "$dir/patTable.pl $$" ) == 0 || 
        errorReport( "Can't execute $dir/patTable.pl $$!\n" );

    exit();

} # runPatmatch()

#############################################################################
##
##  SUBROUTINE NAME
##    printCgiHeader()
##
##  SYNOPSIS 
##    printCgiHeader()
##
##  DESCRIPTION
##    
##
##  ARGUMENTS
##    
##
##  RETURN VALUE
##    none
##
#############################################################################

sub printCgiHeader
{
    my $server_protocol=$ENV{'SERVER_PROTOCOL'};
    my $server_software=$ENV{'SERVER_SOFTWARE'};

    #### will serve page as  browser page , not to download  - cpm  
    #### uncommented following 1 line

    print( "$server_protocol 200 OK", "\n" );

    #print( "Server: $server_software","\n" );

    ####  header tags are jumbled may need to edit format_tair.pl 

    print( "Content-type: text/html\n\n" );
    #print( &PrintHeader );

} #  printCgiHeader()

#############################################################################
##
##  SUBROUTINE NAME
##    presentForm()
##
##  SYNOPSIS 
##    presentForm()
##
##  DESCRIPTION
##    Entry page to the program that displays a form that the user fills in 
##    and submits.
##
##  RETURN VALUE
##    none
##
#############################################################################

sub presentForm
{
    printCgiHeader();
    
 
    my $script = <<EOF

    <script type="text/javascript">
    function updateDatabase() {
    var x = document.getElementById("default_db");
    var db = document.getElementById("current_db");
    var seq_class = document.getElementById("seq_class").value;
    var not_match = "";
    if (seq_class == "peptide") {
        not_match = "(DNA)";
    } else {
        not_match = "(protein)";
    }
    db.options.length = 0;
    for (var i=0; i<x.length; i++){
        var cur_value = x[i].text;
        if (!cur_value.match(not_match)){
            var y = document.createElement("option");
            y.value = x[i].value;
            y.text = x[i].text;
            y.disabled = x[i].disabled; 
            //need to do try/catch command because of IE7
            try { db.add(y, null); } catch (ex) { db.add(y); }
        }
    }
}   

function setSequence( sequence_type ) {
    if (sequence_type == "protein" ) {
        document.getElementById("seq_class").value = "peptide";
    } else {
        document.getElementById("seq_class").value = "nucleotide";
    }
    updateDatabase();
}

function updateMismatchDropdown()
{
	var mismatch = document.getElementById("mismatch");
	var insertion = document.getElementById("insertion");
	var deletion = document.getElementById("deletion");
	var substitution = document.getElementById("substitution");
	if(mismatch.selectedIndex == 0 && (insertion.checked == true || deletion.checked == true || substitution.checked == true))
	{
		mismatch.selectedIndex=1;
	}
	if(mismatch.selectedIndex != 0 && insertion.checked==false && deletion.checked==false && substitution.checked==false)
	{
		mismatch.selectedIndex=0;
	}
}

function updateMismatchCheckBoxes()
{
	var mismatch = document.getElementById("mismatch");
	var insertion = document.getElementById("insertion");
	var deletion = document.getElementById("deletion");
	var substitution = document.getElementById("substitution");
	if(mismatch.selectedIndex != 0 && insertion.checked==false && deletion.checked==false && substitution.checked==false)
	{
		insertion.checked=true;
		deletion.checked=true;
		substitution.checked=true;
	}
	if(mismatch.selectedIndex == 0)
	{
		insertion.checked=false;
		deletion.checked=false;
		substitution.checked=false;
	}
}

</script>

EOF
;

    tair_header( "TAIR Pattern Match", "/css/page/search_short.css");
    print "$script\n";
    print( "<table width=600 align =\"CENTER\"><TR><TD>\n" );
  
    print( "<span class=\"header\">Patmatch</span><BR>\n" );
  
    # End TAIR header
  
    print( p(),
           "Pattern Matching allows you to search for short ",
           "(<20 residues) nucleotide or peptide sequences, or ",
           "ambiguous/degenerate patterns. It uses the same Arabidopsis ",
           "dataset as TAIR's ",
           a( { -href=>"/Blast" }, "BLAST" ),
           " and ",
           a( { -href=>"/cgi-bin/fasta/nph-TAIRfasta.pl" }, "FASTA" ),
           " programs. If you are searching for a sequence >20 bp or aa ",
           "with no degenerate positions, please use BLAST or FASTA, ",
           "which are much faster. Pattern Matching allows for ambiguous ",
           "characters, mismatches, insertions and deletions, but does ",
           "not do alignments and so is not a replacement for ",
           a( { -href=>"/Blast" }, "BLAST" ), 
           " and ",
           a( { -href=>"/cgi-bin/fasta/nph-TAIRfasta.pl" }, "FASTA" ),
           " Currently the maximum ",
           "number of hits retrieved is 250,000 and the minimum number of ",
           "input string is 3 residues.","\n" );
  
    #print( p(),
    #       "This program allows you to search for any nucleotide or ",
    #       "peptide pattern of interest in TAIR's Arabidopsis sequence ",
    #       "datasets. These are the same datasets used by TAIR's ",
    #       a( { -href=>"/Blast" }, "BLAST" ),
    #       " and ",
    #       a( { -href=>"/cgi-bin/fasta/nph-TAIRfasta.pl" }, "FASTA" ), 
    #       " programs. ",
    #       "Pattern Matching, however, does not do alignments, but ",
    #       "instead allows the use of the ambiguous characters, mismatch, ",
    #       "insertions or deletions in your search. Currently the maximum ",
    #       "number of hits retrieved is 75000 and the minimum number of ",
    #       "input string is 4.",
    #       "\n" );
  
    print( p(),
	   a( { -href=>"/patmatch/release_notes.jsp" }, 
	      "Version 1.1 Release Notes" ),
	   "\n" );

    print( p(),
           "Your comments and suggestions are appreciated :",
           a( { -href=>"/contact" }, "Send a Message to TAIR" ),
           "\n" ); 

    print( start_multipart_form(), 
           img( { -src=>"/images/ball.red.gif", -alt=>"[x]" } ),
           "\n",
           b( "<big>Enter a</big>" ),
           "\n",
           Select( { -name=>"seq_class", -id=>"seq_class", -onChange=>"updateDatabase()"},
                   option( {-value=>"nucleotide", -selected=>undef}, "nucleotide" ),
                   option( {-value=>"peptide"}, "peptide" ) ),
           "\n",
           b( "<big>sequence or pattern (",
              a( { -href=>"#syntax" }, "examples" ),
              "):</big>" ),
           "\n",
           input( { -name=>"pat", -size=>50 } ),
           "\n",
           br(), 
           "\n",
           p(),
           "\n",
           b( "<big>Choose a Sequence Database (click and hold to see ",
              "the list):</big>" ),
           "\n",
           br(),
           "\n",
           "All public Arabidopsis sequences can be found within ",
           "these datasets.(",
           "\n",
           a( { -href=>"/help/helppages/BLAST_help.jsp#datasets" }, 
              "Datasets Description" ),
           "\n",
           ")",
           "\n",
           br(),
           "\n" );

    print( "<div id=\"searchbox\">\n<select name=\"default_db\" class=\"hidden\" id=\"default_db\">\n" );
    foreach my $k ( @databaseDisplay ) 
    { print( "<option value='$databases{$k}'>$k</option>\n" ); }
    print( "</select>\n" );
    print( "<select name=\"current_db\" id=\"current_db\"</select>\n" );
    print( "<script type=\"text/javascript\">updateDatabase();</script>\n</div>\n" );


    print( p(),
           "\n",
           b( "<big><input type=submit value='START PATTERN SEARCH'>  ",
              "or  <input type=reset value='reset form'></big>" ),
           "\n" );

    print( 
	   p(),
           "\n",
           b( "PLEASE WAIT FOR EACH REQUEST TO COMPLETE BEFORE ",
              "SUBMITTING ANOTHER." ),
           "\n",
           "<!-- These searches are done on a single computer at Stanford ",
           "shared by many other people. -->",
           "\n",
           hr(),
           "\n",
           b( "<big>More Options :</big>" ),
           "\n",
           br(),
           "\n",
           "Maximum hits: ",
           "\n",
           Select( { -name=>"maxhits" }, 
                   option( "25" ),
                   option( "50" ),
                   option( "100" ),
                   option( "200" ),
                   option( "500" ),
                   option( "1000" ),
                   option( { -selected=>undef }, "75000" ),
		   option( "100000" ),
		   option( "150000" ),
		   option( "200000" ),
		   option( "250000" ) ),
           "\n",
	   img( { -src=>"/images/update.gif" } ),
           br(),
           "\n",
           "If DNA, Strand:",
           "\n",
           Select( { -name=>"strand" },
                   option( { -selected=>undef }, "both strands" ),
                   option( "Watson(given)" ),
                   option( "Crick (rev. complement)" ) ),
           "\n",
           br(),
           "\n",
           "Mismatch: ",
           "\n",
           Select( { -name=>"mismatch", -id=>"mismatch", -onChange=>"updateMismatchCheckBoxes()" },
                   option( { -selected=>undef }, "0" ),
                   option( "1" ),
                   option( "2" ),
                   option( "3" ) ),
           "\n",
           br(),
           "\n",
	   "Mismatch Type: ",
	   "\n",
	   checkbox(-name=>'insertion',
		    -id=>"insertion",
		    -checked=>undef,
		    -value=>'on',
		    -label=>'Insertions ',
	    	    -onClick=>"updateMismatchDropdown()"),
	   checkbox(-name=>'deletion',
		    -id=>"deletion",
		    -checked=>undef,
		    -value=>'on',
		    -label=>'Deletions',
	    	    -onClick=>"updateMismatchDropdown()"),
	   checkbox(-name=>'substitution',
		    -id=>"substitution",
		    -checked=>undef,
		    -value=>'on',
		    -label=>'Substitutions',
	    	    -onClick=>"updateMismatchDropdown()"),
	   "\n",
	   img( { -src=>"/images/update.gif" } ),
	   br(),
	   "\n",
	   "Minimum Hits per Sequence: ",
	   "\n",
	   textfield(-name=>'min_seq_hits',
		     -default=>'1',
		     -size=>'5',
		     -maxlength=>'5'),
	   "\n",
	   img( { -src=>"/images/new.gif" } ),
	   br(),
	   "\n",
	   "Maximum Hits per Sequence: ",
	   "\n",
	   textfield(-name=>'max_seq_hits',
		     -default=>'100',
		     -size=>'5',
		     -maxlength=>'5'),
	   "\n",
	   img( { -src=>"/images/new.gif" } ),
	   br(),
	   "\n",
           br(),
           "\n",
           end_form(),
           "\n" );

    print( p(),
           "\n",
           a( { -name=>"syntax" },
              b( "<big>Supported Pattern Syntax and Examples:</big>" ) ),
           "\n",
           center( "\n",
                  table( { -border=>{ -width=>"100%" } },
                         "\n",
                         Tr( th( "Search Type" ),
                             th( "Character" ),
                             th( "Meaning" ),
                             th( "Examples" ) ),
                         "\n",
                         Tr( th( { -align=>"center", 
                                   -rowspan=>6 }, 
                                 "Peptide Searches" ),
                             td( { -align=>"center" }, 
                                 "IFVLWMAGCYP TSHEDQNKR" ),
                             td( "Exact match" ), 
                             td( "DQGT" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "J",
				 img { -src=>"/images/update.gif" } ), 
                             td( "Any hydrophobic residue (IFVLWMAGCY)" ),
                             td( "AAAAAAJJ" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "O",
				 img { -src=>"/images/update.gif" } ),
                             td( "Any hydrophilic residue (TSHEDQNKR)" ),
                             td( "TTTTTTOO" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "B",
				 img { -src=>"/images/update.gif" } ),
                             td( "D or N" ),
                             td( "FLGB" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "Z", 
				 img { -src=>"/images/update.gif" } ),
                             td( "E or Q" ),
                             td( "GLFGZ" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "X or ." ),
                             td( "Any amino acid" ),
                             td( " DXXXNW..VSK" ) ),
                         "\n",
                         Tr( th( { -rowspan=>12, -align=>"center" }, 
                                 "Nucleotide searches" ),
                             td( { -align=>"center" }, "ACTGU" ),
                             td( "Exact match" ),
                             td( "ACCGGCGTAA" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "R" ),
                             td( "Any purine base (AG)" ),
                             td( "AAGGCCGGRRRR" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "Y" ),
                             td( "Any pyrimidine base (CT)" ),
                             td( "CCCATAYYGGYY" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "S" ),
                             td( "G or C" ),
                             td( { -rowspan=>4, -valign=>"center" }, 
                                 "YGGTWCAMWTGTY" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "W" ),
                             td( "A or T" ) ),
                         "\n",
                         Tr( td( { -align=>"center"} , "M" ),
                             td( "A or C" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "K" ),
                             td( "G or T" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "V" ),
                             td( "A or C or G" ),
                             td( { -rowspan=>4, -valign=>"center" },
                                 "CCGG...WHW.{3,5}HWH...CCGG" ) ),
                         "\n",
                         Tr( td( { -align=>"center"} , "H" ),
                             td( "A or C or T" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "D" ),
                             td( "A or G or T" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "B" ),
                             td( "C or G or T" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, 
                                 "N or X or ." ),
                             td( "Any base" ),
                             td( " ATGCTNNNNATCG" ) ),
                         "\n",
                         Tr( th( { -rowspan=>6, -align=>"center" }, 
                                 "All searches:" ),
                             td( { -align=>"center" }, "[ ]" ),
                             td( "A subset of elements", br(),
				 "[TC] = T or C" ),
                             td( " [WFY]XXXDN[RK][ST]" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "[^ ]" ),
                             td( "An excluded subset of elements", br(),
				 "[^TA] = not T or A,", br(),
				 "(matches nucleotides C or G)" ),
                             td( "NDBB...[VILM]Z[DE]...[^PG]" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "( )" ),
                             td( "Specifies a sub-pattern", br(),
				 "(YPT) = YPT" ),
                             td( " (YDXXX){2,} " ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "{m,n}" ),
                             td( "{m} = exactly m times", br(), 
                                 "{m,} = at least m times", br(),
                                 "{,m} = 0 to m times", br(),
                                 "{m,n} = between m and n times", br() ),
                             td( " L{3,5}X{5}DGZ " ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, "<" ),
                             td( "Constrains pattern to N-terminus ",
                                 "or 5' end" ),
                             td( " &lt;MNTD (pep)", br(),
                                 "&lt;ATGX{6,10}RTTRTT (nuc)" ) ),
                         "\n",
                         Tr( td( { -align=>"center" }, ">" ),
                             td( "Constrains pattern to C-terminus ",
                                 "or 3' end" ),
                             td( " sbgz&gt; (pep) ", br(),
                                 " yattrtga&gt; (nuc)" 
                               ) ), 
                         "\n" ),
                   "\n" ),
           "\n" );

    
    print( "</table>" );
    tair_footer();
 
    exit( 0 );

} # presentForm()

#############################################################################
##
##  SUBROUTINE NAME
##    checkPattern()
##
##  SYNOPSIS 
##    checkPattern()
##
##  DESCRIPTION
##    Performs a test of the validity of the pattern provided by the user.
##
##  ARGUMENTS
##    $pattern - (in) The pattern to check.
##
##  RETURN VALUE
##    none
##
#############################################################################

sub checkPattern
{
    my $pattern = shift;

    # Context free grammar for the Patmatch pattern syntax
    my $grammar = q{
       startrule: pattern /^\Z/
       pattern: left_anchor query right_anchor
       left_anchor: '<' | ''
       right_anchor: '>' | ''
       query: single query | single
       single: literal_list repeat | notany repeat | any repeat | any repeat 
       | group repeat | literal | notany | any | group
       literal: /[A-Za-z\.]/
       literal_list: literal literal_list | literal
       notany: '[^' literal_list ']'
       any: '[' literal_list ']'
       group: '(' query ')'
       repeat: '{' /\d+/ ',' /\d+/ '}'
       | '{' /\d+/ ',' '}'
       | '{' ',' /\d+/ '}'
       | '{' /\d+/ '}'
    };

    my $parser = new Parse::RecDescent($grammar);
    if (defined $parser->startrule($pattern))
    {
	checkCharacters($pattern);
	checkMinimumLength($pattern);
    }
    else
    {
	errorReport("Invalid pattern syntax.  $MESSAGE");
    }
} # checkPattern()

#############################################################################
##
##  SUBROUTINE NAME
##    checkCharacters()
##
##  SYNOPSIS 
##    checkCharacters()
##
##  DESCRIPTION
##    Check for invalid characters in the pattern
##
##  ARGUMENTS
##    $pattern - (in) The pattern to check.
##
##  RETURN VALUE
##    none
##
#############################################################################

sub checkCharacters
{
    my $pattern = shift;
    
    if ($class eq "dna")
    {
	checkNucleotides($pattern);
    }
    else
    {
	checkPeptides($pattern);
    }
} # checkCharacters()

#############################################################################
##
##  SUBROUTINE NAME
##    checkNucleotides()
##
##  SYNOPSIS 
##    checkNucleotides()
##
##  DESCRIPTION
##    Check for invalid characters in the pattern
##
##  ARGUMENTS
##    $pattern - (in) The pattern to check.
##
##  RETURN VALUE
##    none
##
#############################################################################

sub checkNucleotides
{
    my $pattern = shift;

    if ($pattern =~ m/[EFIJLOPQZefijlopqz]/)
    {
	errorReport("Invalid nucleotide character found in pattern.  " .
		    "$MESSAGE");
    }
} # checkNucleotides()

#############################################################################
##
##  SUBROUTINE NAME
##    checkPeptides()
##
##  SYNOPSIS 
##    checkPeptides()
##
##  DESCRIPTION
##    Check for invalid peptide characters in the pattern
##
##  ARGUMENTS
##    $pattern - (in) The pattern to check.
##
##  RETURN VALUE
##    none
##
#############################################################################

sub checkPeptides
{
    my $pattern = shift;
    
    if ($pattern =~ m/[uU]/)
    {
	errorReport("Invalid peptide character found in pattern.  " .
		    "$MESSAGE");
    }
} # checkPeptides()

#############################################################################
##
##  SUBROUTINE NAME
##    checkMinimumLength()
##
##  SYNOPSIS 
##    checkMinimumLength()
##
##  DESCRIPTION
##    Check to make sure that the pattern is not shorter than 3 tokens.
##    Anything between { }, ( ), or [ ] counts as one token.
##    Assumes that the pattern syntax is correct.
##
##  ARGUMENTS
##    $pattern - (in) The pattern to check.
##
##  RETURN VALUE
##    none
##
#############################################################################

sub checkMinimumLength
{
    my $pattern = shift;
    
    my @patArray = split(//, $pattern);
    my $tokens = 0;
    my $countingMode = 1; # indicates if characters are being counted or not
    my $prevCharOpenBracket = 0; # previous character was '{'

    my $patLength = @patArray;
    for (my $i = 0; $i < $patLength; $i++)
    {
	my $char = $patArray[$i];
	if ($prevCharOpenBracket)
	{
	    $prevCharOpenBracket = 0; # no longer true
	    $tokens += getIntValueAfterBracket($pattern, $i);
	}
	elsif ($char eq '{')
	{
	    $prevCharOpenBracket = 1;
	    $countingMode = 0;
	}
	elsif ($char eq '[')
	{
	    $tokens = incrementToken($countingMode, $tokens);
	    $countingMode = 0;
	}
	elsif (($char eq '(') || ($char eq ')') || ($char eq ']') 
	       || ($char eq '}'))
	{
	    $countingMode = 1;
	}
	else
	{
	    $tokens = incrementToken($countingMode, $tokens);
	}
    }
    
    if ($tokens < 3)
    {
	errorReport("Your pattern is shorter than the minimum number of 3 "
		    . "residues.  $MESSAGE");
    }
} # checkMinimumLength()

#############################################################################
##
##  SUBROUTINE NAME
##    incrementToken()
##
##  SYNOPSIS 
##    incrementToken()
##
##  DESCRIPTION
##    Check for invalid peptide characters in the pattern
##
##  ARGUMENTS
##    $countingMode - 1 if should increment, 0 if should not increment
##    $tokenValue - the current value of the token
##
##  RETURN VALUE
##    incremented value of the token
##
#############################################################################

sub incrementToken
{
    my $countingMode = shift;
    my $tokenValue = shift;

    if ($countingMode)
    {
	$tokenValue++;
    }
    return $tokenValue;
} # incrementToken()

#############################################################################
##
##  SUBROUTINE NAME
##    getIntValueAfterBracket()
##
##  SYNOPSIS 
##    getIntValueAfterBracket()
##
##  DESCRIPTION
##    Get the value of the integer after the '{' in the pattern whose
##    location is specified by the given index.
##
##  ARGUMENTS
##    $pattern - the PatMatch pattern
##    $index - index of the '{' character being analyzed
##
##  RETURN VALUE
##    value of the integer after the '{' in the pattern
##
#############################################################################

sub getIntValueAfterBracket
{
    my $pattern = shift;
    my $index = shift;

    my @patArray = split(//, $pattern);
    my $patLength = @patArray;
    my $charStr = ""; # Characters after the '{' being analyzed
    for (my $i = $index; $i < $patLength; $i++)
    {
	my $char = $patArray[$i];
	if ($char =~ m/\d/)
	{
	    $charStr .= $char;
	}
	else
	{
	    last;
	}
    }
    if ($charStr =~ /\d+/) # $charStr is an integer
    {
	return $charStr;
    }
    else
    {
	return 0;
    }
} # getIntValueAfterBracket


#############################################################################
##
##  SUBROUTINE NAME
##    oldCheckPattern()
##
##  SYNOPSIS 
##    oldCheckPattern()
##
##  DESCRIPTION
##    Performs a test of the validity of the pattern provided by the user.
##
##  ARGUMENTS
##    $pattern - (in) The pattern to check.
##
##  RETURN VALUE
##    none
##
#############################################################################

sub oldCheckPattern()
{
    my( $pattern ) = @_;

    my $leftC  = 0;  ###   ---> {
    my $rightC = 0;  ###   ---> }
    my $leftS  = 0;  ###   ---> [
    my $rightS = 0;  ###   ---> ]
    my $leftB  = 0;  ###   ---> (
    my $rightB = 0;  ###   ---> )

    while ( $pattern ) 
    {
	my $char = chop( $pattern );
	if ( $char eq '{' ) 
        {
	    if ( $rightC ) { $rightC--; }
	    else { $leftC++; }
	}
	elsif ( $char eq '}' ) 
        {
	    if ( $leftC ) { $leftC--; }
	    else { $rightC++; }
	}
	elsif ( $char eq '[' ) 
        {
	    if ( $rightS ) { $rightS--; }
	    else { $leftS++; }
	}
	elsif ( $char eq ']' ) 
        {
	    if ( $leftS ) { $leftS--; }
	    else { $rightS++; }
	}
	elsif ( $char eq '(' ) 
        {
	    if ( $rightB ) { $rightB--; }
	    else { $leftB++; }
	}
	elsif ( $char eq ')' ) 
        {
	    if ( $leftB ) { $leftB--; }
	    else { $rightB++; }
	}
    }

    if ( $leftC || $rightC || $leftS || $rightS || $leftB || $rightB ) 
    {
	my $message = "The input pattern \( $originalPattern \) may have " .
            "syntax errors. Please click on your browser's BACK button, check";
	my $note;

	if ( $leftC || $rightC ) 
        {
	    $message = "$message \{ \}";
	    $note = 1;
	}

	if ( $leftS || $rightS ) 
        {
	    if ( $note == 1 ) 
            {
		if ( $leftB || $rightB ) { $message = "$message, \[ \]"; }
		else { $message = "$message and \[ \]"; }

		$note = 2;
	    }
	    else 
            {
		$message = "$message \[ \]";
		$note = 1;
	    }		
	}

	if ( $leftB || $rightB ) 
        {
	    if ( $note ) { $message = "$message and \( \)"; }
	    else { $message = "$message \( \)"; }
	}

	$message = "$message, make necessary correction and submit again. " .
            "Thanks!";
	errorReport( $message );
    }
    else { return; }	  

} # oldCheckPattern()

#############################################################################
##
##  SUBROUTINE NAME
##    processPattern()
##
##  SYNOPSIS 
##    processPattern()
##
##  DESCRIPTION
##    Processes the pattern so that scan_for_matches runs correctly.
##
##  ARGUMENTS
##    $pattern - (in) Pattern to be processed.
##
##  RETURN VALUE
##    $pattern - Processed pattern
##
#############################################################################

sub processPattern()
{
    my( $pattern ) = @_;

    $pattern =~ s/\./X/g;   # convert . to X
    $pattern =~ s/x/X/g;
    $pattern =~ s/\{1\}//g; # remove {1}

    if ( $class =~ /^dna/ ) { $pattern =~ s/[Nn]/X/g; }
    
    $pattern =~ s/\[([a-zA-Z])\]/$1/g;  # convert GT[X]{1,5}RUG to GTX{1,5}RUG 
    $pattern =~ s/\(([a-zA-Z]+)\)([^\{])/$1$2/g; # convert (NXT)[X]{5,15}(NXT)
                                                 # to NXTX{5,15}NXT
    $pattern =~ s/X\*/\{0,100\}/g;
    $pattern =~ s/X\+/\{1,100\}/g;
    $pattern =~ s/\*/\{0,10\}/g;
    $pattern =~ s/\+/\{0,10\}/g;

    $pattern =~ s/X\{([0-9]+)\,([0-9]+)\}/ $1...$2 /g;
    $pattern =~ s/X\{([0-9]+)\}/ $1...$1 /g;
    $pattern =~ s/X\{([0-9]+)\,\}/ $1...50 /g;
    $pattern =~ s/X\{\}/ 0...50 /g;
    $pattern =~ s/X\{\,([0-9]+)\}/ 0...$1 /g;

    my ( $head, $base, $num1, $num2, $tail );

    if ( $pattern =~ /\{/ ) 
    {
	if ( $pattern =~ /^(.*)\(([A-Za-z]+)\)\{([0-9]+)\,([0-9]+)\}(.*)$/ || 
             $pattern =~ /^(.*)([A-Za-z])\{([0-9]+)\,([0-9]+)\}(.*)$/ ) 
        {
	    $head = $1;
	    $base = $2;
	    $num1 = $3;
	    $num2 = $4;
	    $tail = $5;
	}
	elsif ( $pattern =~ /^(.*)\(([A-Za-z]+)\)\{([0-9]+)\}(.*)$/ || 
                $pattern =~ /^(.*)([A-Za-z])\{([0-9]+)\}(.*)$/ ) 
        {
        
	       $head = $1;
	    $base = $2;
	    $num1 = $3;
	    $num2 = $3;
	    $tail = $4;
	}
	elsif ( $pattern =~ /^(.*)\(([A-Za-z]+)\)\{([0-9]+)\,\}(.*)$/ || 
                $pattern =~ /^(.*)([A-Za-z])\{([0-9]+)\,\}(.*)$/ ) 
        {
	    $head = $1;
	    $base = $2;
	    $num1 = $3;

	    if ( $num1 < 10 ) { $num2 = 10; }
	    else 
            {
		$num1 =~ /^([0-9]+)[0-9]$/;
		my $tmp = $1 + 1;
		$num2 = "$tmp" . 0;	       
	    }

	    $tail = $4;
	}
	elsif ( $pattern =~ /^(.*)\(([A-Za-z]+)\)\{\,([0-9]+)\}(.*)$/ || 
                $pattern =~ /^(.*)([A-Za-z])\{\,([0-9]+)\}(.*)$/ ) 
        {
	    $head = $1;
	    $base = $2;
	    $num1 = 0;
	    $num2 = $3;
	    $tail = $4;
	}
	elsif ( $pattern =~ /^(.*)\(([A-Za-z]+)\)\{\}(.*)$/ || 
                $pattern =~ /^(.*)([A-Za-z])\{\}(.*)$/ ) 
        {
	    $head = $1;
	    $base = $2;
	    $num1 = 0;
	    $num2 = 10;
	    $tail = $3;
	}

	my $pattern_group = "";

	for ( my $i = $num1; $i <= $num2; $i++ ) 
        {
	    if ( $pattern_group ) 
            { $pattern_group = "$pattern_group\n$head".$base x $i."$tail"; }
	    else 
            { $pattern_group = "$head".$base x $i."$tail"; }
	}

	$pattern = $pattern_group;
    }

    if ( $class =~ /^pep/ ) 
    {
    	if ( $pattern =~ /[BZXbzx]/ )   # handle B, Z, X
        {
	    $pattern =~ s/[Bb]/ any(IFVLWMAGCY) /g;
	    $pattern =~ s/[Zz]/ any(TSHEDQNKR) /g;
	    $pattern =~ s/[Xx]/ any(IFVLWMAGCYTSHEDQNKRJOUP) /g;
	}

	if ( $pattern =~ /\[[A-Za-z]+\]/)  # handle [..]
        { $pattern =~ s/\[([A-Za-z]+)\]/ any($1) /g; }

	if ( $pattern =~ /\[\^[A-Za-z]+\]/) # handle [^..]
        { $pattern =~ s/\[\^([A-Za-z]+)\]/ notany($1) /g; }
    }
    else 
    {
	while ( $pattern =~ /\[/ ) 
        {
	    $pattern =~ /^(.*)\[(.+)\](.*)$/;
	    $head = $1;
	    my $body_tmp = $2;
	    $tail = $3;
	    my $body = "";

	    for ( my $i = length( $body_tmp ); $i >= 1; $i-- ) 
            {
		if ( !$body ) { $body = chop( $body_tmp ); }
		else 
                {
		    $body = chop( $body_tmp )." | $body";
		    if ( $i > 1 ) { $body = "\($body\)"; }
		}
	    }

	    $body = " \($body\)";
	    $pattern = "$head$body$tail";
	}	
   }

   return( $pattern );

} # processPattern()

#############################################################################
##
##  SUBROUTINE NAME
##    errorReport()
##
##  SYNOPSIS 
##    errorReport()
##
##  DESCRIPTION
##    Writes an error message to the browser.
##
##  ARGUMENTS
##    $err - (in) Message to be displayed
##
##  RETURN VALUE
##    none
##
#############################################################################

sub errorReport()
{
    my( $err ) = @_;
 
    my $title = "TAIR Pattern Matching Error Report";
    print( start_html( -title=>$title, 
                       -BGCOLOR=>"#f5f9ff" ), "\n",
           a( { -href=>"/" },
              img( { -src=>"/images/tairsmall.gif",
                     -border=>0,
                     -align=>"left" } ) ), "\n",
           page_title( "$title" ), "\n",
           p(), "\n",
           font( { -color=>"red" }, $err ), "\n",
           p(), "\n",
           hr(), "\n",
           end_html(), "\n" );
    exit();

} # errorReport()

############################################################################
##
##  SUBROUTINE NAME
##    htmlError()
##
##  SYNOPSIS 
##    htmlError( $errorMsg )
##
##  DESCRIPTION
##    Writes an error message to the browser window.
##
##  ARGUMENTS
##    $errorMsg - (in) Error message to be displayed.
##
##  RETURN VALUE
##    none
##
#############################################################################

sub htmlError
{
    my ( $errorMsg ) = @_;

    print( table( { -width=>600,
                    -align=>"center" },
                  Tr( td( font( { -color=>"red" }, "Error: " ),
                          "$errorMsg",
                          p(),
                        ) 
                    ) 
                ), "\n" );
    print( "</table>" );
    tair_footer();
    exit();

} # htmlError()

#############################################################################
##
##  SUBROUTINE NAME
##    debug()
##
##  SYNOPSIS 
##    debug()
##
##  DESCRIPTION
##    Prints to STDOUT the message provided.  Used for debugging.  You must set 
##    gloval variable $debug to a non-zero value for this subroutine to print.
##
##  ARGUMENTS
##    $message
##
##  RETURN VALUE
##    none
##
#############################################################################

sub debug()
{
    my $message = $_[0];
    if ( $debug ) 
    { 
        #print( font( { -color=>"red" }, "$message\n" ) ); 
        print( STDERR "$message\n" );
    }

} # debug()

#############################################################################

# POD Documentation

=head1 SYNOPSIS

newpatmatch is a updated version of patmatch that runs using the normal blast datasets.

=head1 VERSION

1.0, of November 15, 2001

=head1 DESCRIPTION

=head2 Installation

newpatmatch is a cgi application that should reside in a subdirectory of $HOST/cgi-bin. It requires Bioperl 0.71 to be installed on the system and comprises the following programs:

=over 4

=item newpatmatch

This is the main program that should be called by the web-browser. If no parameters are supplied, an input form is shown, otherwise the patmatch search is launched with the parameters supplied.

=item patTable.pl

This is a new perl program that replaces the old patTable C-program. It is called by newpatmatch to display the results. 

=item newGetSequence.pl

This is also a new perl program that replaces the old getSequence.pl perl program. The new program relies on bioperl for indexing fasta files.

=item scan_for_matches_50M

This is the actual C-program that is called to do the searching. It has been modified for
newpatmatch, to handle fasta entries that are larger than 10MB. The new limit is 50MB. 
This is necessary for searching complete pseudochromosomes in future applications.

=back

=head1 Configuring newpatmatch

To make configuration simpler, a newpatmatch.conf file has been added, which is used to
setup the datasets, temp-directories etc.

=head2 The .conf file

The structure of the .conf file is self-explanatory. An example is given here:
Note that # denotes a comment line.

 #
 # newpatmatch.conf
 # ================
 #
 # This is the newpatmatch configuration file. There are 5 different types of entries:
 #
 # tempdir       gives the location of the tmp dir to be used.
 # datadir       gives the loacation of the data files (fasta format)
 # dataset       gives the type (DNA or Protein), filename (without path), a file description and a date for a dataset.
 # indexfiledir  points to the directory where the indexfiles are kept. If automatic indexing is used,
 #               nobody needs to have write access there.
 # debug         if a value other than the null string is entered, additional information will be output.
 #
 # This file is read by both newpatmatch and by patTable.pl
 # All lines are tab delimited text.
 #
 #
 # Values
 # ======
 #
 # The tmp directory
 #
 tempdir tmp
 #
 # The datadir
 #
 datadir /home/arabidopsis/data/FASTA
 #
 # The indexfiledir
 #
 indexfiledir    /home/arabidopsis/cgi-bin/patmatch/indexfiles
 #
 # The datasets
 #
 dataset Protein ATH1_pep        All Proteins from AGI, Total Genome
 dataset DNA     ATH1_seq        Genes from AGI, Total Genome
 dataset DNA     ATH1_cds        CDS from AGI, Total Genome
 dataset DNA     ATH1_bacs_con   TIGR BAC Sequences
 dataset DNA     AGI_BAC GenBank AGI BAC Sequences
 dataset Protein ArabidopsisP    GenPept, PIR and SwissProt
 dataset DNA     AtBACEND        Genbank and Kazusa BAC ends
 dataset DNA     AtEST   Genbank ESTs (DNA)
 dataset DNA     AtANNOT GenBank, minus ESTs and BAC ends
 dataset DNA     ArabidopsisN    GenBank, including ESTs and BAC ends
 #
 # Print debug info (add TRUE if you want debug info, leave blank or comment out otherwise)
 #
 debug   


=head1 AUTHOR

patmatch was written by Shuai Wei of SGD.

newpatmatch was worked upon by Lukas Mueller (I<mueller@acoma.stanford.edu>) and Neil Miller (I<nam@ncgr.org>) of TAIR.

newpatmatch was reworked by Dan Weems (I<dcw@ncgr.org>) of TAIR to distribute the analysis part of the software to a remote server rather than requiring the web server to use precious resources.

=cut
