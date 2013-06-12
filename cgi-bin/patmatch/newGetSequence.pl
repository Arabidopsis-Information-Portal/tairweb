#!/bin/env perl

#########################################################################
# Copyright: (c) 2003 National Center for Genome Resources (NCGR)
#            All Rights Reserved.
# $Log: newGetSequence.pl,v $
# Revision 1.6  2006/10/12 21:47:36  tacklind
# new footer/header
#
# Revision 1.5  2004/08/04 18:30:32  nam
# Patmatch update from Thomas - remove obsolete scan for matches binary
#
# Revision 1.4  2004/01/19 19:16:24  dcw
# Updated to read a new format of the sequence file that removed redundancy.
#
# Revision 1.3  2003/12/02 23:08:21  dcw
# Rewritten so that it no longers uses a regular expression to insert the
# tag to change the font but does so interatively and thereby removed the
# restriction that only the first 32766 characters would be evaluated for
# the presence of the pattern that is written in red and bold.
#
# Revision 1.2  2003/11/24 22:11:21  dcw
# Rewritten to get all required data from ../../tmp/patmatch/patmatch.seq.$$
# rather than from BioPerl index files of the raw fasta data because that data
# is not available anymore as it is moved to a remove analysis server.
#
#
# This CGI Perl script is used to get DNA or protein  sequence and highlight 
# the matching region.
#
# Originally written by Lukas Mueller of Carnegie Institute of Washington
# at Stanford, CA, Nov 2001
# 
#########################################################################

use CGI qw/:standard :html/;
use CGI::Carp qw( fatalsToBrowser );
#use Bio::Seq;
#use Bio::SeqIO;
#use Bio::Index::Fasta;

require '../format_tairNew.pl';

use strict 'vars';
use vars qw( $debug 
             $tmpDir );

#$debug = 1;  # uncomment if you want to turn on debugging

# Read configuration file

my $config_file = "newpatmatch.conf";

open( CONF, "<$config_file" ) || 
    die "Can't read newpatmatch configuration file $config_file";

while ( <CONF> ) 
{
    chomp;
    my $line = $_;
    my $tag;
    if ( $line =~ /^tempdir/i )  
    { 
        ( $tag, $tmpDir ) = split /\t/, $line;
        last;
    }
}

close( CONF );

#$tmpDir = "$ENV{DOCUMENT_ROOT}/../tmp/patmatch";

# Read in the CGI variables

my $seqId = param( 'seq' );
my $processId = param( 'id' );
my $beg = param( 'beg' );
my $end = param( 'end' );
my $title = "Sequence for $seqId";

debug( "SeqId=$seqId\n" );

# Open the seq file identified by the processId.

my $seqFile = "$tmpDir/patmatch.seq.$processId";
open( SEQ, "<$seqFile" ) || 
    die "newGetSequence.pl: Can't open $seqFile!";

# Loop through the seq file until the line identified by the id matches that 
# sent as seqId.

my $desc;
my ( $id, $fullseq, @desc );

while ( <SEQ> )
{
    chomp();

    ( $id, $fullseq, @desc ) = split( / /, $_ );
    $desc = join( " ", @desc );
    debug( "id=$id\nbeg=$beg\nend=$end\nfullseq=$fullseq\ndesc=$desc\n" )
        if ( $id eq $seqId );
    last if ( $id eq $seqId );
}

close( SEQ );

# Reverse the beg in end parameters if beg > end.

if ( $beg > $end ) 
{
    my $tmp = $beg;
    $beg = $end;
    $end = $tmp;
}

# Added by tyan on 4/9/04 so that this page prints out the pattern searched and
# restrictions on the pattern.
my $paramFile = "$tmpDir/patmatch.param.$processId";
open (PARAM, "<$paramFile")
    || die "Can't open $paramFile";
my $paramLine = <PARAM>;
my ($db, $strand, $showPattern, $extendedPattern, $mismatch, $deletion, $insertion, $substitution, $numSeqsHit, $numHitsFound, $maxHits, $numSeqsSearched, $numBytesSearched ) = split(/ /, $paramLine);
my $mismatchTypes = "";
if ($mismatch > 0)
{
    if ($deletion eq 'on')
    {
	$mismatchTypes .= "deletions ";
    }
    if ($insertion eq 'on')
    {
	$mismatchTypes .= "insertions ";
    }
    if ($substitution eq 'on')
    {
	$mismatchTypes .= "substitutions";
    }
}

print "Content-type: text/html\n\n";
tair_header( "$title" );
print( page_title( "$title" ) );
print( divider75() );

displaySequence( $fullseq, $desc, $beg, $end );

tair_footer();
print( end_html() );

#############################################################################
##
##  SUBROUTINE NAME
##    displaySequence()
##
##  SYNOPSIS 
##    displaySequence( $seq, $desc, $beg, $end )
##
##  DESCRIPTION
##    Displays the full sequence with the portion of sequence that matches the 
##    pattern displayed in red.
##
##  ARGUMENTS
##    $seq  - (in) Full sequence
##    $desc - (in) Description
##    $beg  - (in) Begin coordinate of the pattern within the sequence.
##    $end  - (in) Ending coordinate of the pattern within the sequence.
##
##  RETURN VALUE
##    none
##
#############################################################################

sub displaySequence() 
{ 
    my ( $seq, $desc, $beg, $end ) = @_;

    # Here we display the sequence with a linelength of $linelength
    # and highlight the matching region (from $beg to $end - converted
    # to zero based indices.

    print( "<CENTER>" );

    # Display the pattern searched as well as restrictions on the pattern
    print ( table( {-border => 1},
		   Tr( td( "Pattern:" ),
		       td( "$showPattern"),
		     ),
		   Tr( td( "Mismatches Allowed:" ),
		       td( "$mismatch" ),
		     ),
		   Tr( td( "Mismatch types:" ),
		       td( "$mismatchTypes" ),
		     )
		   ),
	     br(),
	     br()
	    );

    # Display the sequence description for that entry

    print( table( { -border => 0 },
                  Tr(),
                  td( "$desc" )
                ), "\n",
         );

    # Display the sequence but divide the sequence into multiple lines that are
    # no longer than $MAX_LINE_LENGTH.

    print( "<TABLE border =1><TR><TD><pre>" );
    my @seq = split //, $seq;  # Split sequence into an array of characters
    my $MAX_LINE_LENGTH = 50;
    my $charCount = 0;  # Sequence length excluding HTML commands

    for ( my $i = 0; $i < scalar( @seq ); $i++ )
    {
        if ( $i == $beg - 1 )
        {
            print( "<FONT COLOR=RED><b>$seq[$i]" ); 
        }
        elsif ( $i == $end - 1 )
        {
            print( "$seq[$i]<\/b><\/FONT\>" ); 
        }
        else
        {
            print( "$seq[$i]" ); 
        }

        $charCount++;
        if ( $charCount % $MAX_LINE_LENGTH == 0 ) 
        { 
           print( "\n" ); 
        }
    }

    print( "</pre></TD></TR></TABLE>" );
    print( "</CENTER>" );

}  # displaySequence() 

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
    if ( $debug ) { print( STDERR "$message\n" ); }

} # debug()

