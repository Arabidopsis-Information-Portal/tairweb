#!/bin/env perl

#########################################################################
# Copyright: (c) 2003 National Center for Genome Resources (NCGR)
#            All Rights Reserved.
# $Log: patTable.pl,v $
# Revision 1.8  2006/10/11 21:24:50  tacklind
# new footer/header
#
# Revision 1.7  2006/01/25 18:06:51  nam
# add new uniprot dataset
#
# Revision 1.6  2004/08/04 18:30:33  nam
# Patmatch update from Thomas - remove obsolete scan for matches binary
#
# Revision 1.5  2004/01/21 19:48:49  dcw
# Change subroutine call 'escape' to 'uri_escape' and loaded URI::Escape
#
# Revision 1.4  2003/11/24 22:09:50  dcw
# Rewritten to get all required data from $HOME/tmp/patmatch/patmatch.param.$$
# and $HOME/tmp/patmatch/patmatch.pattern.$$ and no longer gets data from the
# raw fasta files because the fasta files are now on a remote analysis server.
#
#
#########################################################################

use CGI qw/:standard :html/;
use CGI::Carp qw( fatalsToBrowser );
use URI::Escape;

require "../format_tairNew.pl";

# Global Variables

use strict 'vars';
use vars qw( $debug 
             $processId
             $pattern 
             $tmpDir
             $db
             $recordStart
             $numHitsFound
             $dbdescription
             $DIR
             $PAGESIZE
             $SCRIPT_NAME
             $BGCOLOR_TAIR
             $BGCOLOR_GREY
             %databases 
           );

# Constants

$PAGESIZE = 25;
$SCRIPT_NAME = "/cgi-bin/patmatch/patTable.pl";
$DIR = "/cgi-bin/patmatch";
$BGCOLOR_TAIR = "f5f9ff";
$BGCOLOR_GREY = "cccccc";

#old:
#"<A HREF=http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&db=Nucleotide&doptcmdl=GenBank&term=$id>$display_id</A>";
my $GB_NT_EST = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nucest&id=';
my $GB_NT_CORE = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nuccore&id=';

#old:
#"<A HREF=http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi?cmd=Retrieve&db=Protein&dopt="
my $GenPept = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=protein&id=';

# $debug = 1;  # uncomment this line to display debug messages

# Get parameters

# The first call to the program supplies the process id as a command line parameter.

$processId = shift;

# Subsequent calls will provide process id and the starting record as cgi parameters.

my $cgiProcessId;
if ( not $processId )
{
    $cgiProcessId = param( "id" );
    $recordStart = param( "beg" ); # $recordStart = first record of the page to display.
}

# Correct the value of $recordStart if it was not initialized

if ( $recordStart == 0 ) { $recordStart = 1; }

# Read configuration file

my $config_file = "newpatmatch.conf";
open( CONF, "<$config_file" ) || 
    die "Can't read newpatmatch configuration file $config_file";

while ( <CONF> ) 
{
    chomp;
    my $line = $_;
    my $tag;
    if ( $line =~ /^\#/ ) { next; }
    if ( $line =~ /^tempdir/i )  { ( $tag, $tmpDir ) = split( /\t/, $line ); }
    if ( $line =~ /^dataset_file/i ) 
    {
	    my ($tag,$file) = split(/\t/,$line);
		open(IN,"<$file") || debug("couldnt open datasets mapping file $file\n");
		foreach my $lines (<IN>)
		{
			chomp($lines);
			if($lines !~ /^[Nn]ame/)
			{
				my ($name,$type,$num,$residues,$date,$desc) = split(/\t/,$lines);
				if ($type eq 'AA') {
				    $type = 'protein'
				}
				$desc = "$desc ($type)";

				$databases{$name} = $desc;
			}
		}
	    #   my ( $tag, $type, $file, $desc ) = split( /\t/, $line ); 
	    #$databases{"$desc ($type)"} = $file;
    }
    debug( %databases );
}

close( CONF );

#$tmpDir = "$ENV{DOCUMENT_ROOT}/../tmp/patmatch";

# If we didn't receive command line parameters we accept the cgi parameters.
# We need to know if we run as a cgi to output a header.

my $cgi; # flag to see if we are running as cgi or not.

if ( $processId eq "" ) 
{ 
    $processId = $cgiProcessId; 
    $cgi = "TRUE"; # we are running as cgi. We have to print a header.
}

if ( $cgi ) 
{
    print( header() );
    print( start_html( -title => "TAIR Patmatch Results",
                       -BGCOLOR => '#f5f9ff', ) );
    tair_header( "" );
}
    
# Read paramfile

my $paramFile = "$tmpDir/patmatch.param.$processId";
open( PARAM, "<$paramFile" ) || 
    die "Can't open $paramFile";

my $line = <PARAM>;

my ( $strand, $showPattern, $extendedPattern, $mismatch, $deletion, $insertion, $substitution, $numSeqsHit, $maxhits, $numSeqsSearched, $numBytesSearched );

( $db, $strand, $showPattern, $extendedPattern, $mismatch, $deletion, 
  $insertion, $substitution, $numSeqsHit, $numHitsFound, $maxhits, 
  $numSeqsSearched, $numBytesSearched ) = split( / /, $line );
if ( $showPattern =~ /^\<(.+)$/ ) 
{
    $showPattern =~ s/\</&lt/;
}
elsif ( $showPattern =~ /^(.+)\>$/ )
{
    $showPattern =~ s/\>/&gt/;
}

debug( "Param file produced: db=$db, strand=$strand, showPattern=$showPattern, " .
       "extendedPattern=$extendedPattern, mismatch=$mismatch, deletion=$deletion, " .
       "insertion=$insertion, substitution=$substitution numSeqsHit=$numSeqsHit, " . 
       "numHitsFound=$numHitsFound, " .
       "maxhits=$maxhits, numSeqsSearched=$numSeqsSearched, " .
       "numBytesSearched=$numBytesSearched" );

close( PARAM );

# Retrieve the database description from the databases hash
$dbdescription = $databases{$db};
#foreach my $k ( keys %databases ) 
#{
#    if ( $databases{$k} eq $db ) 
#    { 
#        $dbdescription = $k; 
#        last;
#    }
#}

# Display infos

if ( $numHitsFound > 0 )
{
    print( center(
                  table( { -border => 1 }, 
                         Tr( td( "Hits found:" ),
                             td( "$numHitsFound" ),
                           ), 
                         Tr( td( "Sequences with hits:" ),
                             td( "$numSeqsHit" ),
                           ), 
                         Tr( td( "Sequences searched:" ),
                             td( "$numSeqsSearched" ),
                           ), 
                         Tr( td( "Bytes searched:" ),
                             td( "$numBytesSearched" ),
                           ), 
                         Tr( td( "Pattern:" ),
                             td( "$showPattern" ),
                           ),
                         Tr( td( "Dataset searched:" ),
                             td( "$dbdescription" ),
                           ), 
                         Tr( td( "Download all matches as a textfile" ),
                             td( a( { -href => path_translated() . 
                                      "dumpresults.pl?results=patmatch.pattern." .
                                      "$processId" },
                                    "download" ), ), 
                           ), 
                       ), 
                 ),
           br(),
           br()
         );
}
else
{
    print( center(
                  table( { -border => 1 }, 
                         Tr( td( "Hits found:" ),
                             td( "$numHitsFound" ),
                           ), 
                         Tr( td( "Sequences with hits:" ),
                             td( "$numSeqsHit" ),
                           ), 
                         Tr( td( "Sequences searched:" ),
                             td( "$numSeqsSearched" ),
                           ), 
                         Tr( td( "Bytes searched:" ),
                             td( "$numBytesSearched" ),
                           ), 
                         Tr( td( "Pattern:" ),
                             td( "$showPattern" ),
                           ),
                         Tr( td( "Dataset searched:" ),
                             td( "$dbdescription" ),
                           ), 
                       ), 
                 ),
           br(),
           br()
         );
}

displayResults();
tair_footer();

exit( 0 );

#############################################################################
##
##  SUBROUTINE NAME
##    displayResults()
##
##  SYNOPSIS 
##    displayResults()
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

sub displayResults() 
{
    return if ( $numHitsFound == 0 );

    # Variables
    
    my $realhitno; 
    my $bgcolor;
    my $display_id;
    my $databaselink;
    my $lineno = 0;

    # $realhitno counts the number of hits displayed -- namely, $PAGESIZE hits. 
    # Every realhit is composed of several hits to one sequence.
    
    my $patternFile = "$tmpDir/patmatch.pattern.$processId";
    open( PAT, "<$patternFile" ) || 
        die "patTable.pl: Can't open $patternFile!";
    
    print( "<CENTER>\n" );
    
    displayNavigationButtons();

    print( "<TABLE border=1 cellpadding=5>\n" );
    
    print( Tr( { -bgcolor => "$BGCOLOR_GREY" },
               th( { -rowspan => 2 }, "Hit#" ),
               th( { -rowspan => 2 }, "Sequence name" ),
               th( { -rowspan => 2 }, "# of hits" ),
               th( { -rowspan => 2 }, "Hit" . br() . "pattern" ),
               th( { -colspan => 2 }, "Matching Positions" ),
               th( { -rowspan => 2 }, "Hit" . br() . "sequence" )
             ), "\n",
           Tr( { -bgcolor => "$BGCOLOR_GREY" },
               th( "start" ),
               th( "end" )
             ), "\n" 
         );

    my $line;
    my $previous_id="";

    $realhitno = 0;
    my ( $id, $freq, $start, $end, $patseq );

    while ( ( $line = <PAT> ) && 
            ( $realhitno < ( $recordStart + $PAGESIZE ) ) ) 
    {
	$lineno++;
	chomp( $line );
		
	$previous_id = $id;

	( $id, $freq, $start, $end, $patseq ) = 
            split( / /, $line );
	
	if ( ( $previous_id ne $id ) && ( $realhitno < $recordStart ) ) 
        {
            # If the realhitno counter is smaller than the recordStart, we just 
            # scan through the file without printing out
            # anything. We have to decide whether we have to increment the 
            # realhitno counter. If the hit had the same id as the previous one,
            # we don't increase, otherwise we increase.

	    $realhitno++; 
	}
	    
	#
 
	if ( $realhitno >= $recordStart ) 
        {

	    # Here we decide how to color the background for the current hit.

	    $display_id = $id;

	    if ( $display_id ne $previous_id ) 
            { 
		if ( $bgcolor eq $BGCOLOR_TAIR ) { $bgcolor = $BGCOLOR_GREY; }
		else { $bgcolor = $BGCOLOR_TAIR; }
	    }
	    
	    # $link_id is used to link out to newGetSequence. We have to 
	    # replace the # in the id with the appropriate % code (%23).

	    my $link_id = $display_id; 
	    



	    # Is it from the intron dataset?

	    if ( $id =~ /([Aa][Tt]\d[gG]\d+)\-I\d+/ ) 
            {
	      $link_id = uc( $id );
	      $id = $1;
	      $display_id = $id;
	      $databaselink = "<A HREF=\"/servlets/TairObject" .
                  "?type=locus&name=$id\">$display_id</a>";
	    }

	    ### Matches Uniprot dataset = uniprot ###
        elsif ( $db eq "At_Uniprot_prot"  ) {
            $link_id = uri_escape( $display_id ); #encode for URL
            my @linkparts = split(/\|/, $display_id);
            if (@linkparts > 0) { 
                $databaselink = "<a href=\"http://www.uniprot.org/entry/$linkparts[1]\">" . "$display_id</a>";
            } else { 
                $databaselink = "<a href=\"http://www.uniprot.org/entry/$link_id\">" . "$display_id</a>";
            }
        }
	    
	    # If it is a TIGR identifier of the form "TIGR|MIPS|TAIR|chrbasedname" 
	    # isolate the chrbasedname and use for linking to tair.

	    elsif ( $id =~ /TIGR\|MIPS\|TAIR\|(\S+)\|/ ) 
            {
		$id = $1;

                #encode | for correct URL
 
		$link_id = uri_escape( $display_id ); 

		$display_id =~ s/TIGR\|MIPS\|TAIR\|\S+\|\S+/$id/;

		$databaselink = "<A HREF=\"/servlets/TairObject" .
                    "?type=locus&name=$id\">$display_id</A>";
	    }
	    
	    # Is it the bacs dataset?

	    elsif ( $id =~ /^\d+$/ ) 
            {
		$databaselink = "<A HREF=\"http://www.tigr.org/" .
                    "tigr-scripts/euk_manatee/BacAnnotationPage.cgi" .
                        "?db=ath1&asmbl_id=$display_id\">$display_id</A>";		
	    }


            # Is it TIGR BACS?  Handle separately to avoid getting
            # caught by PIR rules below

            elsif ( $db =~ /ATH1_bacs_con/ ) 
            {
              $link_id = uri_escape( $display_id ); #encode for URL
              $databaselink = "<A HREF=\"/servlets/TairObject" .
                  "?type=assembly_unit&name=$link_id\">$display_id</a>";
            }  
	    
	    # Is it a PIR identifier??

	    elsif ( $id =~ /^[A-Z]\d+/ ) 
            {
		$databaselink = "<A HREF=\"http://www-nbrf.georgetown.edu/" .
                    "cgi-bin/nbrfget?uid=$id\">$id</A>";
	    }

	    # Is it a GenBank identifier?
	    # Determine whether a peptide or NT dataset &
	    # use correct database link

	    elsif ( $id =~ /^gi\|(\d+)/ ) 
            {
		$id = $1;

		if ( $db =~ /prot/i ) 
                {
	 		$databaselink = "<A HREF=$GenPept$id>$display_id</A>";
		} 
                else 
                {
			my $GB_NT = $GB_NT_EST;
    			if ($db =~ /exp|genomic|refseq/i) 
			{
				$GB_NT=$GB_NT_CORE;
			}
	 		$databaselink = "<A HREF=$GB_NT$id>$display_id</A>";
		}
	    }

	    # add link to seed stock detail page

	    elsif ( $id =~ /Stock\|(\S+)\s?/ ) 
	    {
		$databaselink = "<A HREF=\"/servlets/SeedSearcher" .
                    "?action=detail&stockID=$1\">$display_id</a>"
	    }
	    
	    # is it a tigr identifier on its own?

	    elsif ( $id =~ /([Aa][Tt]\d[Gg]\d{5})/ ) 
        {
		
            $display_id=$1;
            
            #check to see if in locus form or gene form 
            if ($id =~ /[aA][tT]\d[gG]\d{5}\.\d/){
                $databaselink = "<A HREF=\"/servlets/TairObject" .
                    "?type=gene&name=$id\">$id</A>";
            } else { 
                $databaselink = "<A HREF=\"/servlets/TairObject" .
                    "?type=locus&name=$display_id\">$display_id</A>";
	        }
        }

	    # Otherwise, we just display the id.

	    else 
            {
		$databaselink = $display_id;
		$link_id =~ s/\#/\%23/g;
	    }
	    
	    
	    # Here, we want to display a range of lines if the sequence contains 
            #several hits.

	    my $displayline = "";
	    my $totallines = 0;

	    if ( $freq > 1 ) 
            { 
                $totallines = $lineno + $freq -1;  
                $displayline = "$lineno - $totallines"; 
            }
	    else 
            {
		$displayline = $lineno;
	    }
	    
            # If the pattern length is greater than 25, then split it to serveral 
            # lines 

            if ( length( $patseq ) > 25 ) 
            {
                my $tmpseq = $patseq;
                $patseq = "";

                while ( $tmpseq && length( $tmpseq ) > 25 ) 
                {
                    my $tmp = substr( $tmpseq, 0, 25 );
                    
                    if ( $patseq ) { $patseq = "$patseq<br>$tmp"; }
                    else { $patseq = "$tmp"; }

                    $tmpseq = substr( $tmpseq, 25 );
                }

                $patseq = "$patseq<br>$tmpseq";
            }

	    # We increment the realhitno counter here

	    $realhitno++;

	    print( Tr( { -bgcolor => "$bgcolor" },
                       td( { -rowspan => $freq }, "$displayline" ),
                       td( { -rowspan => $freq }, "$databaselink" ),
                       td( { -rowspan => $freq }, "$freq" ),
                       td( "$patseq" ),
                       td( "$start" ),
                       td( "$end" ),
                       td( a( { -href => "$DIR/newGetSequence.pl" .
                                "?seq=$link_id&id=$processId" .
                                "&beg=$start&end=$end" }, 
                              "sequence" ) ),
                     ) 
                 );

	    my $i;

	    for ( $i = $freq - 1; $i > 0; $i-- ) 
            {
		# We have read another line so we increase the $lineno counter - 
                # but not the realhitno counter
		# since the hit is on the same sequence

		my $line2 = ( <PAT> );
		$lineno++;
                chomp( $line2 );
		( $id, $freq, $start, $end, $patseq ) = split( / /, $line2 ); 

		print( Tr( { -bgcolor => "$bgcolor" },
                           td( "$patseq" ),
                           td( "$start" ),
                           td( "$end" ),
                           td( a( { -href => "$DIR/newGetSequence.pl" .
                                    "?seq=$link_id&id=$processId" .
                                    "&beg=$start&end=$end" },
                                  "sequence" ) )
                         ), "\n" 
                     );
	    }
	    #$previous_id = $display_id;
	}
	
    }
    
    print( "</TABLE>\n" );
    
    displayNavigationButtons();

    print( "<BR><BR><BR>" );
    print("</CENTER>" );
    close( PAT );

} # displayResults() 

#############################################################################
##
##  SUBROUTINE NAME
##    displayNavigationButtons()
##
##  SYNOPSIS 
##    displayNavigationButtons()
##
##  DESCRIPTION
##    Displays two buttons, "Previous Results" and "Next Results" but only if 
##    there is data to point at.  In other words, the "Previous Results" button 
##    is displayed only if there is data previous to the current display of data 
##    and the "Next Results" button is displayed only if there is more data 
##    beyond the currently displayed data.  The buttons are in a table so that 
##    they are always centered irrespective if one or two buttons are displayed.  
##    If no other data is available, the subroutine simply returns.
##
##  GLOBAL VARIABLES
##    $numHitsFound - (in) Total number of data rows that can be displayed
##    $recordStart - (in) Current starting position within the data rows
##    $PAGESIZE - (in) Constant defining the maximum number of rows to display
##
##  RETURN VALUE
##    none
##
#############################################################################

sub displayNavigationButtons
{
    # If the total number of data rows is less than or equal to the maximum
    # number of rows to display on a page, return since there are no other pages
    # that can be displayed.

    return if ( $numHitsFound <= $PAGESIZE );

    # Display the buttons within a table.

    print( "<TABLE border=0>\n" );
    print( "<TR>\n" );

    # Add a "Previous Results" link if we are not on the first page

    my $prevIsDisplayed;

    if ( $recordStart >= $PAGESIZE ) 
    {
        # Print the "Previous" button.

	print( td( a( { -href => "$SCRIPT_NAME?id=$processId&beg=" . 
                        ( $recordStart - $PAGESIZE ) },
                      "< Previous Results" ) ) );

        # Flag to indicate that the previous button is displayed.

        $prevIsDisplayed = 1;
    }

    # Add a "Next Results" link if we are not on the last page...

    if ( ( $recordStart + $PAGESIZE - 1 ) < $numHitsFound ) 
    {
        # If the previous button is displayed, add space between the two buttons.

        if ( $prevIsDisplayed ) { print( td( " | " ) ); }

        # Print the "Next" button.

	print( td( a( { -href => "$SCRIPT_NAME?id=$processId&beg=" . 
                        ( $recordStart + $PAGESIZE ) }, 
                      "Next Results >" ) ) );
    }

    print( "</TR></TABLE>\n" );

} # displayNavigationButtons()

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
    if ( $debug ) { print( "$message\n" ); }

} # debug()

