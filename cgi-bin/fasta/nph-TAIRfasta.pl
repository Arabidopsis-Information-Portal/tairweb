#!/bin/env perl

#########################################################################
# Copyright: (c) 2003 National Center for Genome Resources (NCGR)
#            All Rights Reserved.
# $Revision: 1.20 $
# $Date: 2006/10/10 20:50:43 $
#
# $Log: nph-TAIRfasta.pl,v $
# Revision 1.20  2006/10/10 20:50:43  tacklind
# new header/footer
#
# Revision 1.19  2006/02/28 00:41:12  dyoo
# nph-TAIRfasta.pl: changed the order of arguments to put the stdin hyphen at the end of the options as per standard option parsing order.
#
# Revision 1.18  2006/01/25 18:06:35  nam
# add new uniprot dataset
#
# Revision 1.17  2004/05/12 22:09:09  nam
# Remove RemoteFasta module; alter nph-TAIRfasta.pl to use generic RemoteCluster module for communicating with analysis farm
#
# Revision 1.16  2004/05/11 23:27:25  nam
# Alter to use cluster configuration module for connection settings
#
# Revision 1.15  2004/05/06 22:49:56  nam
# change master host to blaster03
#
# Revision 1.14  2003/12/11 18:51:09  dcw
# Fixed bug where selecting "Force strand to be all Dna or Protein" failed.
#
# Revision 1.13  2003/11/18 22:02:26  dcw
# Modified to run the fasta program from the remote Analysis Cluster.
#
#
# Modified by Allan Dickerman from nph-fastaatdb.pl from CherryandCo@Stanford
# this version parses output of FASTA3 or FASTX3 directly
#
# 12/13/2001, modified by Guanghong Chen from TAIRfasta.pl to allow
# 1. Completed (Non-Parsed) Headers so that user knows he is waiting for load drop
# 2. Used uptime system call to determine system load average instead of how many
#    fasta processes are running
#
# 04/18/2002, modified by Guanghong Chen
# 1. Turned on the -w flag and fix lots of warnings
# 2. Changed the way to print out CGI form
# 3. Hotlink to matches to public database
#
#########################################################################

use CGI qw(:standard :html -nph/);

use lib "../cluster";
use RemoteCluster;

use strict 'vars';

require "../format_tairNew.pl";

use strict 'vars';
use vars qw( $debug );

my $action = "$ENV{'SCRIPT_NAME'}";
# the same script to process form data

$debug = ( param( 'debug' ) ); #toggle debug mode
#$debug = 1;

my $PROJECT_HOME = $ENV{'DOCUMENT_ROOT'} . "/..";

my $TMPDIR = $PROJECT_HOME . "/tmp/fasta/";
my $templog = $PROJECT_HOME . "/logs/fasta/templog";
my $SEQTMP = $TMPDIR . "fasta.tmp.$$";
my $OUTFILE = $TMPDIR . "fasta.out.$$";

my $MAXLOAD = 4;

my $FASTLIBS = "$PROJECT_HOME/data/FASTA/fastaMetaData"; 
my $MATRICES = "matrices.txt"; # name of file containing paths to matrices for fasta

my $PATH_TO_EXECUTABLE = "/usr/local/fasta3/";
my $MIN_QUERY_LENGTH = 8;

# Determine if the client browser in Microsoft Internet Explorer.

my $isMSIE = 0;
my $http_user_agent = $ENV{'HTTP_USER_AGENT'};
if ( $http_user_agent =~ /MSIE/ )
{ $isMSIE = 1; }

$ENV{FASTLIBS} = $FASTLIBS;
my %dataset; #specifically formatted file that tells paths to searchable files
my @dataset; #keep array to preserver order
my %datasetType; # store whether nucleotide or protein

open( FASTALIBS, $FASTLIBS ) 
    or die( "Error! $0 could not open $FASTLIBS." );

debugOut( "\n" );

<FASTALIBS>; #dump first line, should be: Name    Type    NumSeqs Residues        Date    Description

my $last_group = "";

while ( <FASTALIBS> )
{

    chomp();
    my $line = $_;
    my ($name, $type, $num_seqs, $residues, $date, $desc) = split /\t/, $line;

    if ($name) {
	if ($type eq 'AA') { 
	    $type = "protein";
	}
	my $display = "$desc ($type)";

	$display =~ /^(\S+)/;
	my $this_group = $1;

	if ($last_group ne "" &&  $last_group ne $this_group ) {
	    my $blank = '-------------';
	    $dataset{$blank} = $blank;
	    $datasetType{$blank} = $blank; 
	    push (@dataset, $blank);
	}

	$dataset{$display} = $name;
	$datasetType{$display} = $type; 
	push (@dataset, $display);

	$last_group = $this_group;
 	debugOut( "dataset{$display} = $dataset{$display}\n" );
    } else {
	debugOut( "$line NOT TRANSLATED\n" );
    }

}

close( FASTALIBS );

my %matrices;
my @matrices;

# read a file that tells paths to protein-comparison matrices

open( MATRICES, $MATRICES )
    or warn( "Error! $0 could not open $MATRICES." );

while ( <MATRICES> )
{ 
    my ( $nm, $pth ) = split;
    next if !( length( $pth ) );
    push( @matrices, $nm );
    $matrices{$nm} = $pth;
}

close MATRICES;

# WWW link stems for databases copied from TAIR NCBI blast CGI code

#my $GB_NT_old = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?".
#    "cmd=Search&db=Nucleotide&doptcmdl=GenBank&term=";
#my $GB_AA_old = "http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi" .

my $GB_NT_EST = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nucest&id=';
my $GB_NT_CORE = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nuccore&id=';
my $GB_NT;
my $GB_AA = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=protein&id=';
my $TIGR = "http://www.tigr.org/tigr-scripts/euk_manatee/shared/" .
    "ORF_infopage.cgi?db=ath1&orf=";
my $TIGR_BAC = "http://www.tigr.org/tigr-scripts/euk_manatee/" .
    "BacAnnotationPage.cgi?db=ath1&asmbl_id=";
my $MIPS = 'http://mips.gsf.de/cgi-bin/proj/thal/search_gene?code=';   
my $SEED_DETAIL = "/servlets/SeedSearcher?action=detail&stock_number=";
my $LOCUS_DETAIL = "/servlets/TairObject?type=locus&name=";
my $CLONE_DETAIL = "/servlets/TairObject?type=clone&name=";
my $UNIPROT = "http://www.uniprot.org/entry/";


# If no parameters, then print form.
if ( !param() ) 
{
    printCgiHeader();
    print( "Content-type: text/html", "\n\n" );
    printForm();
    exit 0;
}

# If parameters do exist, then process them and run fasta.

else 
{
    $| = 1;  # set autoflush on

    print( "HTTP/1.0 200\n" );
    printCgiHeader();
    print( "Content-type: text/html", "\n\n" );

    print( start_html( -title=>'TAIR FASTA Search',
                       -BGCOLOR=>"\#FFFFFF" ) );

    #### Print message to user to have patience & not resubmit job ###

    print( br(),
           br(),
           p( "Your FASTA request has been queued and will be processed. ",
              font( { -color=>"red" }, "Please ",
                    b( "do not" ),
                    "hit \"Stop\" and resubmit your job" ),
              ".  Such action will add to the queue of jobs already in ",
              "progress and have the effect of placing your request to ",
              "the end of the line." ),
           p( center( img( { -src=>"/images/coffeecup.gif",
                             -width=>45,
                             -height=>52 } ) ) ) );

    print( "<a href=\"/index.html\"><img src=\"/images/logosmall.gif\" " .
           "border=0 align=left></a>\n" );
    print( "<h1 align=center>TAIR Fasta Search Results</h1>\n" );
    print( "<CENTER><IMG src=\"/images/line.red2.gif\" alt=\"[line]\">" .
           "</CENTER>\n" );

    # this is only for testing

    if ( param( 'test' ) )
    {
	#$PATH_TO_EXECUTABLE = ""; # use local version of executable
	param( 'maxaligns', "5" );
	param( 'maxscores', '10' );

	if ( param( 'protein' ) )
        { param( 'sequence', "MSYLREVATAVALLLPFILLNKFP" ); }
	else  {
	    param( 'sequence', "ggtctcggagtggatcgatttgggattctgttcgaagattt" ); }

	param( 'dataset', $dataset[0] );
	param( 'expect', 10 );
	debugOut( "Debugging: dataset = ", param( 'dataset' ), "\n" );
    }

    # the following section about optout is for debugging
    #    open( OPTOUT, ">".$TMPDIR."options.tmp" ); 
    #    @keys = param;
    #    print( OPTOUT join( "\n", @keys ) );
    #    foreach $opt ( @keys )
    #    {
    #	print( OPTOUT "$opt = ", param( $opt ), "\n" );
    #    }
    #    close OPTOUT;

    my $options = " -Q";

    if ( param( 'histogram' ) )
    { $options .= " -H"; }

    if ( param( 'force' ) )
    { $options .= " -n"; }

    if ( param( 'expectation' ) ne "10" )
    { $options .= ( " -E" . param( 'expectation' ) ); }

    if ( param( 'maxscores' ) ne "unlimited" )
    { $options .= " -b" . param( 'maxscores' ); }

    if ( param( 'maxaligns' ) ne "unlimited" )
    { $options .= " -d" . param( 'maxaligns' ); }

    if ( param( 'invert' ) )
    { $options .= " -i"; }

    if ( param( 'matrix' ) ne "BLOSUM50" ) 
    { $options .= " -s $matrices{param('matrix')}"; }
    
    # Get dataset to search

    my $mydataset = $dataset{param( 'dataset' )};
    if ($mydataset =~ /exp|genomic|refseq/i) {  #eq "ATH1_pep" or $database eq "ArabidopsisP" ) {
	$GB_NT = $GB_NT_CORE; #$GenPept;
    } else {
	$GB_NT = $GB_NT_EST;
    }
    
    my $seqname = param( "seqname" );

    # Get sequence and remove non-alphabetic characters

    my $sequence;
    
    # This means the text area was used to paste in sequence

    if ( param( "sequence" ) )
    { $sequence = param( "sequence" ); }

    # This means user uploaded a file, get sequence from it

    elsif ( param( "fileupload" ) )
    {
        my $fileupload = param( 'fileupload' );

        # CGI.pm magic makes name into file handle

        while ( <$fileupload> )
        { $sequence .= $_; }
    }

    # See if sequence has a fasta-header line

    # This means they have a fasta description on what they pasted in
    $sequence =~ s/\r//g;
    if ( $sequence =~ /^\s*>/ )
    {
	my $firstGT = index( $sequence, ">" );
	my $firstNewLine = index( $sequence, "\n" ); #end of first line

        # if user didn't specify a name (description), save description

	if ( !$seqname )
        { $seqname = substr( $sequence, $firstGT+1, $firstNewLine-1 ); }

	$sequence = substr( $sequence, $firstNewLine+1 ); 	      
    }

    # Remove non-alphabet characters

    $sequence =~ s/\W//go;  

    # Setup sequence name (with length appended)

    $seqname .= "  (Length: ";
    $seqname .= length( $sequence );
    $seqname .= ")";

    if ( length( $sequence ) < $MIN_QUERY_LENGTH )
    {
	print( "<H1>Error!</H1><p>Sequence length was ", 
               length( $sequence ), 
               ". The minumum is $MIN_QUERY_LENGTH.", p, end_html );
	exit 0;
    }

    # Print reference for fasta

    print( p(),
           b( "Reference: " ),
           "Pearson, W.R. and D.J. Lipman (1988) \n",
           "Improved tools for biological sequence comparison. \n",
           "Proc. Natl. Acad. Sci. U.S.A. 85:2444-2448 [\n",
           a( { -href=>"http://www3.ncbi.nlm.nih.gov/htbin-post/" .
           "Entrez/query?uid=88190088&form=6&db=m&Dopt=r" }, "Medline" ),
           "]",
           p(), "\n" );
    
    # Write sequence to temporary file, use processID to make unique.
    # Also write sequence to web page for verification

    my $querySequence;

    open( SEQTMP, ">$SEQTMP" ) or 
        die( "$0 couldn't create temporary sequence file $SEQTMP." );

    print( SEQTMP ">$seqname\n" );
    $querySequence = ">$seqname\n";

    print( "<b>Query sequence:</b><pre>\n$seqname\n" ); #printing to web browser

    my $COLUMN_WIDTH = 70;

    while ( length( $sequence ) > $COLUMN_WIDTH )
    {
	print( SEQTMP substr( $sequence, 0, $COLUMN_WIDTH ), "\n" );
        $querySequence .= substr( $sequence, 0, $COLUMN_WIDTH ) . "\n";
	print( substr( $sequence, 0, $COLUMN_WIDTH ), "\n" ); # to browser
	$sequence = substr( $sequence, $COLUMN_WIDTH, length( $sequence ) );
    }

    print( SEQTMP "$sequence\n" );
    $querySequence .= "$sequence\n";
    print( "$sequence</pre><p>\n" ); # to browser
    close( SEQTMP );
    
    print( "<b>Dataset to search: ", param( 'dataset' ), "</b><p>\n" );

    if ( param( 'dataset' ) =~ /CSHL/ ) 
    {
	print( "\n<b>NOTE: The CSHLPrel dataset is updated every day from " .
               "the CSHL preliminary sequence data available from the CSHL " .
               "Anonmymous (<a href=ftp://ftp.cshl.org/pub/sequences/" .
               "arabidopsis/>FTP server</a>). This dataset contains " .
               "<i>Arabidopsis thaliana</i> genomic DNA sequence data " .
               "generated by the GSC in St. Louis, the HGC at Cold Spring " .
               "Harbor Laboratory and the ACGT at Perkin-Elmer, Corp. It " .
               "is very important that you understand these sequences are " .
               "preliminary. They have not been released to GenBank, may " .
               "not have been verified, contain incomplete information, " .
               "are not annotated, and will likely change after they are " .
               "verified and submitted to GenBank.</b><p>\n" );
    }
    
    my $sequenceType = "AA"; 
    $sequenceType = "DNA" if ( isSequenceDNA( \$sequence ) );
    my $algorithm = "fasta34_t";

    #print( "Sequence type is $sequenceType<br>\n" );

    if ( $sequenceType ne $datasetType{ param( 'dataset' ) } and
         not param( 'force' ) )
    {
	if ( $sequenceType eq "DNA" )
        { $algorithm = "fastx34_t"; }
	else
        { $algorithm = "tfastx34_t"; }
    }
    
    print( "<hr>\n" );

    # The following are flags for signalling stepping through sections of fasta output

    my $histogram = 0;
    my $scores = 0;
    my $alignments = 0;
    my $topPart = 1; # We start in state 'topPart'
    eval 
    {
        # Create RemoteCluster instance to handle communication 
        # with Analysis Farm.
        my $server = RemoteCluster->new();

	# set priority for job - use 0 (long queue) for tfastx
        my $priority = 1;
        if ( $algorithm eq "tfastx3_t" ) {
	  $priority = 0;
	}

	# Create command string to be executed on remote string
	my $command = 
	  "\$FASTA/$algorithm " .
	    " $options - " .
	      "\$RAWDATA/$dataset{param('dataset')} ";
		
	# Create hash of options to pass to RemoteCluster.  Query
	# sequence must be submitted to remote job as STDIN.
	my %options = ( 'command' => $command,
			'priority' => $priority,
			'stdin' => $querySequence );
	

	# submit job and get initial response
	my ( $response ) = $server->Submit( %options );

        my $queued = 0;
        my $running = 0;
        my $secs = 1;
        if ( $priority == 0 )
        { $secs = 5; }

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

                sleep( $secs );
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

                sleep( $secs );
            }
            else
            { print( "<br>" ); }
        } 
        while ( $response =~ "PleaseRun" || $response =~ "Running" );

        # Check for errors.

        my $errorLog = $server->ErrorLog();
        if ( length( $errorLog ) > 5 )
        { 
            $server->CleanUp();
	    unlink( $SEQTMP );
            htmlError( "<b>ERROR: $errorLog<br>" ); 
        }

        # Retrieve the results.

        my ( $myResult ) = $server->Retrieve();

        # Clean up the remote server.

        $server->CleanUp();

        # Write the results to a temporary file.

        open( RESULT, ">$OUTFILE" )
            or die( "Can't create output file $OUTFILE: $!" );
        print( RESULT $myResult );
        close( RESULT );

        # Output the results to the browser page.

        open( RESULT, "<$OUTFILE" )
            or die( "Can't open output file $OUTFILE: $!" );

        print( p(),
               p(),
               b( "Results:" ), "\n",
               "<pre>" );

        while ( <RESULT> )
        {
            if ( $topPart )
            {
                if ( m/^ version/ ) 
                {
                    print( "$algorithm $_" );
                }
                elsif ( /^\s+opt\s+E\(\)/ )
                {
                    $topPart = 0;
                    $histogram = 1;
                    print( "Histogram of scores\n$_<p>\n" );
                }
                elsif ( /^The best\s+scores are:/ )
                {
                    $topPart = 0;
                    $scores = 1;
                    print( "$_<p>" );
                }
            }
            elsif( $histogram )
            {
                if ( /^The best\s+scores are:/ )
                {
                    print( "<hr>\n" );
                    $histogram = 0;
                    $scores = 1;
                }
                print( "$_<p>" );
            }
            elsif ( $scores )
            {
                if ( /\S/ )
                {
                    hotLinkURLandEvalue(); 
                    print( );
                    print( "<p>" );
                }
                else
                {
                    debugOut( "Turning Scores off, Alignments on\n" );
                    $scores = 0;
                    $alignments = 1;
                    print( "<hr>\n" );
                }
            }
            elsif ( $alignments )
            {
                if ( /^>>/ )
                {
                    $_ = $'; # removing leading '>>'
                    print( "<hr>>>" );
                    addSeqIDAnchor( \$_ );
                }
                print( "$_<br>" );
            }
        }

        close( RESULT );

        print( end_html );
    };

    if ( $@ ) 
    {
        htmlError( "$@<p>Please send email to " .
                   "informatics\@arabidopsis.org to inform this error." );
    }

    unlink( $SEQTMP );
    unlink( $OUTFILE );

    exit 0;
} # endif when parameters are included in program call

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
##    none
##
##  RETURN VALUE
##    none
##
#############################################################################

sub printCgiHeader
{
    my $server_protocol = $ENV{'SERVER_PROTOCOL'};
    my $server_software = $ENV{'SERVER_SOFTWARE'};
    #### will serve page as  browser page , not to download  - cpm  
    #### uncommented following 1 line
    print( "$server_protocol 200 OK","\n" );
    print( "Server: $server_software","\n" );
    ####  header tags are jumbled may need to edit format_tair.pl 
#    print( "Content-type: text/html", "\n\n" );
}        

#############################################################################
##
##  SUBROUTINE NAME
##    checkLoad()
##
##  SYNOPSIS 
##    checkLoad()
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

sub checkLoad
{
    open( UPTIME, "uptime |" );
    my $line = <UPTIME>;
    close( UPTIME );

    if ( $line =~ /load average: (\d+.\d+)/ ) 
    { $line = $1; }

    if ( $line > $MAXLOAD ) 
    { return 0; } 
    else 
    { return 1; }
} # checkLoad()

#############################################################################
##
##  SUBROUTINE NAME
##    printForm()
##
##  SYNOPSIS 
##    printForm()
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

sub printForm
{
    tair_header( "FASTA" );

    print( "<table width=600 align =\"CENTER\"><TR><TD>" );
    print( "<span class=\"header\">FASTA</span><BR> " );


    print( "</td></tr></table>" );

    print(       
          table( {-width=>600,            
                  -border=>0,
                  -align=>'CENTER'},	    
                 Tr(
                    td(
                       start_multipart_form( -action=>$action ),
                       b( 'Name of query:' ), 
                       '(optional)&nbsp',
                       textfield( 'seqname' ),
                       br,
                       b( "Enter a query sequence:" ),
                       " (format: raw or fasta)", 
                       br
                       textarea( -name=>"sequence", -columns=>60, -rows=>5 ),
                       br,
                       b( 'OR' ), 
                       br,
                       b( "Upload a file containing query sequence:" ),
                       " (format: raw or fasta)<BR>",
                       filefield( -name=>"fileupload", -size=>50, 
                                  -maxlength=>80 ),
                       p,
                       b( 'Datasets: [<a href=' .
                          '"/help/helppages/BLAST_help.html#datasets">' .
                          'Description</a>]' ),
                       popup_menu( -name=>'dataset', -values=>\@dataset ), 
                       br,
                       submit(),
                       "&nbsp&nbsp", 
                       reset(),
                       p(),
                       "<small>The type of query sequence and target " .
                       "dataset determine the program used:</small>\n",
                       br,
                       table( { -width=>512,            
                                -border=>1,
                                -font=>'small',
                                -cellpadding=>2,
                                -cellspacing=>0},
                              Tr( td( "<small>Query</small>" ),
                                  td( "<small>Dataset</small>" ),
                                  td( "<small>Program</small>" ) ),
                              Tr( td( "<small>DNA</small>" ),
                                  td( "<small>DNA</small>" ),
                                  td( "<small>fasta3, searches both " .
                                      "strands</small>" ) ),
                              Tr( td( "<small>Protein</small>" ),
                                  td( "<small>Protein</small>" ),
                                  td( "<small>fasta3</small>" ) ),
                              Tr( td( "<small>Protein</small>" ),
                                  td( "<small>DNA</small>" ),
                                  td( "<small>tfastx3, searches all " .
                                      "six frames</small>" ) ),
                              Tr( td( "<small>DNA</small>" ),
                                  td( "<small>Protein</small>" ),
                                  td( "<small>fastx3, forward 3 frames, " .
                                      "see options for reverse</small>" ) ) ),
                       #  hr,
                       h1( 'Options' ),
                       p(), 
                       "Maximum number of scores to show: ",
                       popup_menu( -name=>"maxscores",
                                   -values=>['10','50','100','500',
                                             'unlimited'],
                                   -default=>'50' ), #change back to 100 when set
                       br(),
                       "Maximum number of alignments to show: ",
                       popup_menu( -name=>"maxaligns",
                                   -values=>['0', '10','50','100','500',
                                             'unlimited'],
                                   -default=>'50' ), #change back to 100 when set
                       br(),
                       "Expectation threshold: (lower is more stringent) ",
                       popup_menu( -name=>"expectation",
                                   -values=>['1e-4', '0.001', '0.1','1','10',
                                             '20','50'],
                                   -default=>'10'
                                 ),
                       br(),
                       "Protein comparison matrix: ",
                       popup_menu( -name=>"matrix", 
                                   -values=>\@matrices, 
                                   -default=>'BLOSUM50' ),
                       br(),
                       checkbox( -name=>'invert',
                                 -label=>' Reverse Complement (DNA only)' ),
                       br(),
                       checkbox( -name=>'histogram',
                                 #-checked=>'checked',
                                 -label=>' Suppress Histogram' ),
                       br(),
                       checkbox( -name=>'force',
                                 -label=>' Force interpreting sequence ' .
                                 'as DNA' ),
                       br(),
                       submit(), 
                       "&nbsp&nbsp", 
                       reset(),
                       end_form(),
                      ),
                   ),
               )
         );
    
    tair_footer();
    
    exit 0;
    
} # printForm()

#############################################################################
##
##  SUBROUTINE NAME
##    hotLinkSeqURL()
##
##  SYNOPSIS 
##    hotLinkSeqURL()
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

sub hotLinkSeqURL
{
    my $id = 0;
    my $url = "";

    my $sequenceType = $datasetType{ param('dataset') };
    
    my $set =  $dataset{ param('dataset') };

    # PlantDNA 

    if ( /^GSDB:S:([0-9]+)/o ) 
    {
	$url = "<B><A HREF=\"$GB_NT$1\">GSDB:S:$1</A></B>";
	$id = $1;
	$_ = $url.$'; # keep remainder
    }

       
     ### Matches Uniprot dataset = uniprot ###
    elsif ( $set eq "At_Uniprot_prot" && /^>?(\w+)\|(\w+)/ ) {
        my $uniprot_id = $2;

        if ( $uniprot_id ne "" ) {
            $url = "<a href=\"$UNIPROT$uniprot_id\" " .
                    "target=_new>$uniprot_id</a>";
            $_ =~ s/$uniprot_id/$url/;
        }
    }
        
    # TIGR

    #
    # Matches dataset - ATH1_cds, ATH1_seq, ATH1_pep
    #TIGR|MIPS|TAIR|At3g45780|F16L2.3 T6D9.110 nonphototropic ...   845  0.        1
    #TIGR|MIPS|TAIR|At3g45780|F16L2.3 T6D9.110 nonphototropic ...   845  7.1e-33   1
    #TIGR|MIPS|TAIR|At5g18660|T1A4.40  putative protein 2'-hyd...   177  0.015     1
    #TIGR|MIPS|TAIR|At5g53040|MNB8.10  putative protein simila...   138  0.56      1
    
    elsif ( m%(TIGR)\|(MIPS)\|(TAIR)\|(.*?)\|%o )
    {
        $url = "<B><A HREF= \"$TIGR$4\">$1</A>\|<a href=\"$MIPS$4\">$2</A>\|<a href=\"$LOCUS_DETAIL$4\">$3</A></B>\|$4|";
        $id = $4;
        $_ = $url.$'; # keep remainder
    }

    #
    # Matches TDNA insertion flank sequences  - targetSet = TDNA
    #
    #Stock|CS100256 SequenceName|SGT6752-3-3.txt                    125  0.42      1
    #Stock|SALK_007402 GB|BH212302 Locus|                           124  0.53      1
    #Stock|SALK_005579 GB|BH172346                                  127  0.44      1
    #Stock|SALK_010903 GB|BH251043 Locus|At5g18940 (an annotat...   122  0.59      1

    elsif ( m%^(SequenceName\|)(\S+) (Stock\|)(\S{5,})%o )
    {      
        $url = "$1$2 $3<b><a href= \"$SEED_DETAIL$4\">$4</A></b>";
        $id = $2;
        $_ = $url.$'; # keep remainder
        
        ## if locus name is truncated, do not hyperlink
	  
        if ( /(Locus\|)(\S+)(\s)/ ) 
        {
            if ( length( $2 ) >= 9 ) 
            {
                s%(Locus\|)(\S+)(\s)%$1<b><a href=\"$LOCUS_DETAIL$2\">$2</a></b>$3%o;
            }
        }
    }
    elsif ( m%^(GB\|)(\S+) (Stock\|)(\S+)%o )
    {
        $url = "$1<b><a href=\"$GB_NT$2\">$2</A></b> $3<b><a href= \"$SEED_DETAIL$4\">$4</A></b>";
        $id = $2;
        $_ = $url.$'; # keep remainder

        ## if locus name is truncated, do not hyperlink

        if ( /(Locus\|)(\S+)(\s)/ ) 
        {
            if ( length( $2 ) >= 9 )
            {
                s%(Locus\|)(\S+)(\s)%$1<b><a href=\"$LOCUS_DETAIL$2\">$2</a></b>$3%o;
            }
        }
    }

    #
    #
    # Matches TIGR BACS dataset=ATH1_bacs_con ###
    # ( /(\d+)\sbac:\s(\S+)/ ) {
    #67250   bac: T6D9       chromo: 3       seq_group: Genoscope-EU genbank...  3585  0.       12

    elsif ( /^(\d+)(\sbac:\s)(\S+)/o )
    {
        $url = "<b><a href=\"$TIGR_BAC$1\">TIGR</A></b>$2<b><a href=\"$CLONE_DETAIL$3\">$3</A></b>";
        $id = $1;
        $_ = $url.$'; # keep remainder	     
        ## link to GenBank 
        s%(genbank_accession:\s)(\S+)%$1<b><a href="$GB_NT$2">$2</a></b>%o;
    }
    
    #gi|6587720|gb|AC007323.5|AC007323 Gen (79760) [f] 1140 1140 1140  368.0   1.7e-15
    #gi|18423463 ref|NM_124683.1| Arabidopsis thaliana chromos...   138  0.995     1
    elsif ( m%^(gi\|)(\d+)%o )
    {
        if ( $sequenceType eq "DNA" ) 
        { $url = "$1<b><a href= \"$GB_NT$2\">$2</A></b>"; }
        else 
        { $url = "$1<b><a href= \"$GB_AA$2\">$2</A></b>"; }

        $id = $2;
        $_ = $url.$'; # keep remainder	  
    }

    #
    #
    # Matches AGI BACS dataset=AGI_BAC ###
    #emb|AL162459.2|ATF16L2 Arabidopsis thaliana DNA chromosom...   925  1.3e-35   1
    #dbj|AB010693.1|AB010693 Arabidopsis thaliana genomic DNA,...   137  0.993     1
    #gb|AF002109.2|AF002109 Arabidopsis thaliana chromosome II...   137  0.993     1

    #recent_at, 
    #gi|15237134 ref|NC_003076.1| Arabidopsis thaliana chromos...   177  0.044     1
    #gb|AY065129.1| Arabidopsis thaliana unknown protein (At3g...   145  0.68      1
    #dbj|AB073153.1|AB073153 Arabidopsis thaliana DNA, chromos...   142  0.82      1
    #ref|NC_003074.1| Arabidopsis thaliana chromosome 3, compl...   635  9.2e-23   1

    # AtBACEND, 
    #emb|AL082779.1|CNS00O59 Arabidopsis thaliana genome surve...   142  0.38      1

    #AtEST, 
    #gb|W43664.1|W43664 23057 CD4-16 Arabidopsis thaliana cDNA...  1145  8.5e-47   1

    #ArabidopsisN
    #emb|AL162459.2|ATF16L2 Arabidopsis thaliana DNA chromosom...   925  3.1e-35   1
    #gb|AV529038.1|AV529038 AV529038 Arabidopsis thaliana abov...   870  1.2e-33   1
    #gi|18408071 ref|NM_114447.1| Arabidopsis thaliana chromos...   845  6.6e-32   1
    #dbj|AB073153.1|AB073153 Arabidopsis thaliana DNA, chromos...   142  0.9993    1
      
    #AtANNOT
    #gb|AF360218.1|AF360218 Arabidopsis thaliana putative nonp...   920  1.8e-35   1
    #emb|AL157735.2|ATT6D9 Arabidopsis thaliana DNA chromosome...   925  2.2e-35   1
    #dbj|AB073153.1|AB073153 Arabidopsis thaliana DNA, chromos...   142  0.994     1
    #gi|18423463 ref|NM_124683.1| Arabidopsis thaliana chromos...   138  0.995     1
 
    #ArabidopsisP PlantProtein
    #gi|15238073|ref|NP_198957.1| homeodomain  ( 611)  532  532  532  597.5   4.4e-26
    #gi|27363268|gb|AAO11553.1| At5g41410/MYC  ( 611)  532  532  532  597.5   4.4e-26
    #dbj|BAB08513.1|| homeotic prot  ( 611)  532  532  532  597.5   4.4e-26

    elsif ( m%^(gb)\|(.*?)(\|.*)% || 
            m%(dbj)\|(.*?)(\|.*)% || 
            m%(emb)\|(.*?)(\|.*)% )
    {
        if ( $sequenceType eq "DNA" ) 
        {
            $url = "$1|<b><a href= \"$GB_NT$2\">$2</A></b>|$3";
        }
        else 
        {
            $url = "$1|<b><a href= \"$GB_AA$2\">$2</A></b>|$3";
        }
        
        $id = $2;
        $_ = $url.$';           # keep remainder	  
    }
    
    #ref|NC_003074.1| Arabidopsis thaliana chromosome 3, compl...   635  9.2e-23   1

    elsif ( m%^(ref)\|(.*?)(\|.*)%o )
    {
        $url = "$1|<b><a href= \"$GB_NT$2\">$2</A></b>|$3";
        $id = $2;
        $_ = $url.$'; # keep remainder	  
    }
  

    
    #
    # Matches At_upstream_1000 At_upstream_3000, At_downstream_1000, At_downstream_3000
    #
            
    #AT2G39920 5' sequence, length=1000 [CHR 2 START 16613083 ...   137  0.56      1
    #AT4G09350 5' sequence, length=1000 [CHR 4 START 4896633 E...   133  0.71      1

    elsif ( m%^([Aa][Tt]\d[Gg]\d+)% )
    {
        $url = "<b><a href=\"$LOCUS_DETAIL$1\">$1</A></b>";
        $id = $1;
        $_ = $url.$'; # keep remainder	    
    }
    
    elsif ( /^(GP-[A-Z0-9]+_\d+\s+gi\|)([0-9]+)/o ) 
    {
	$url = "<b><a href=\"http://www.ncbi.nlm.nih.gov/htbin-post/" .
            "Entrez/query?db=p&form=6&Dopt=g&uid=$2\">$1$2</a></b>";
	$id = $2;
	$_ = $url.$';  #rest of line
    }

    elsif ( /^PIR-([A-Z0-9]+)/o ) 
    {
	$url = "<b><a href=\"http://pir.georgetown.edu/cgi-bin/nbrfget?" .
            "&uid=$1\">PIR-$1</a></b>";
	$id = $1;
	$_ = $url.$';
    }

    return $id;	    

} # hotLinkSeqURL()

#############################################################################
##
##  SUBROUTINE NAME
##    hotLinkURLandEvalue()
##
##  SYNOPSIS 
##    hotLinkURLandEvalue()
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

sub hotLinkURLandEvalue
{
    chomp;
    my $id = hotLinkSeqURL();
    
    #put in link to internal anchor, e-value is clickable link

    if ( / \(( *)(\d+)(\) .*\S+)\s+(\d[0-9\.e\-]*)$/ )
    { $_ = "$` ($1$2$3   <a href=\"\#$id-$2\">$4</a>\n"; }

    return $_;

} # hotLinkEvalue()

#############################################################################
##
##  SUBROUTINE NAME
##    addSeqIDAnchor()
##
##  SYNOPSIS 
##    addSeqIDAnchor()
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

sub addSeqIDAnchor
{ 
    # use id and length for html internal anchor

    my $id = hotLinkSeqURL();
    my $length = 0;

    if ( / \( *(\d+) [ant]{2}\)/ )    
    { $length = $1; }

    $_ = "<a name=$id-$length>$_";

} # addSeqIDAnchor()

#############################################################################
##
##  SUBROUTINE NAME
##    isSequenceDNA()
##
##  SYNOPSIS 
##    isSequenceDNA(  )
##
##  DESCRIPTION
##    
##
##  ARGUMENTS
##    
##
##  RETURN VALUE
##    return 1 if proportion of ACGT > 80, else 0
##
#############################################################################

sub isSequenceDNA
{
    my $seqref = shift;
    my $limit = length( $$seqref );
    my $nucCount = 0;

    for ( my $i = 0; $i < $limit; $i++ )
    {
        my $c = substr( $$seqref, $i, 1 );
        $nucCount++ if ( $c eq 'a' || $c eq 'A' || $c eq 'c' || $c eq 'C' || 
                         $c eq 'g' || $c eq 'G' || $c eq 't' || $c eq 'T' );
    }

    return ( $nucCount >= ( $limit * 0.80 ) );
} # isSequenceDNA()

#############################################################################
##
##  SUBROUTINE NAME
##    debugOut()
##
##  SYNOPSIS 
##    debugOut( $note )
##
##  DESCRIPTION
##    Subroutine for displaying debug information when the debug option is set.
##
##  ARGUMENTS
##    
##
##  RETURN VALUE
##    none
##
#############################################################################

sub debugOut
{
    my ( $note ) = @_;

    print( STDERR $note )
        if ( $debug );
    
} # debugOut()

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
    print( end_html() );

    exit();

} # htmlError()

#############################################################################
##
##  SUBROUTINE NAME
##    printTairHeader()
##
##  SYNOPSIS 
##    printTairHeader()
##
##  DESCRIPTION
##    Prints the standard TAIR header at the top of the web page.
##
##  ARGUMENTS
##    none
##
##  RETURN VALUE
##    none
##
#############################################################################

sub printTairHeader
{
    tair_header( "FASTA results" );
    print( "<table width=600    align =\"CENTER\"><TR><TD>\n" );
}

#############################################################################
##
##  SUBROUTINE NAME
##    printTairFooter()
##
##  SYNOPSIS 
##    printTairFooter()
##
##  DESCRIPTION
##    Prints the standard TAIR footer at the bottom of the web page.
##
##  ARGUMENTS
##    none
##
##  RETURN VALUE
##    none
##
#############################################################################

sub printTairFooter
{

    print( "</TD></TR></TABLE>\n" );
    tair_footer();
}

