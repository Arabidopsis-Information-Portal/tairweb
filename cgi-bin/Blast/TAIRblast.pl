#!/bin/env perl 
#########################################################################
# Copyright: (c) 2001 National Center for Genome Resources (NCGR)
#            All Rights Reserved.
# $Revision: 1.59 $
# $Date: 2006/10/10 20:40:42 $
#########################################################################


#########################################################################
# revision of script by Wen Huang, which was revision of Mike Cherry script
# changes made by AWD starting 17 Feb, 2000
#   change length limits, make into function of query length and dataset size
#   read metadata about target sets from data/FASTA/fastaMetaData
#     (num seqs, size, date, etc)
#   change behavior to send job to Thing 2 IF it is NOT completely busy
#     (less than 2 running jobs)
#   change number processors from 4 to 3 to better use the 6-processor
#     DeCyphers
#   write to log file
#   clean up blastres.tmp.$$.mapdata from tmp directory
#   changed specification of which strands to search - both for dna, direct
#     for protein
#
#   now this script handles email by itself, does not call mailBlast.pl
#   changes by AWD put into production 16 March, 2000
#########################################################################

use CGI qw/:standard :html -nph/;

use lib '../bulk/sequences/';

use LociSeqFetch;

require '../format_tairNew.pl';

use lib "../cluster/";
use RemoteCluster;

use strict 'vars';

my $rootDir = $ENV{'DOCUMENT_ROOT'} . "/..";
my $serverName = $ENV{'SERVER_NAME'};
my $serverPort = $ENV{'SERVER_PORT'};

my $URLPATH = $ENV{'DOCUMENT_ROOT'}  . "/Blast/tmp/";
my $httpRoot = "http://". $serverName . ":" . $serverPort . "/Blast/tmp/";

my $TMPPATH = $rootDir . "/tmp/blast/";

my $errorlog = "error_log";



my $RESFILE = "blastres.tmp.$$";
my $blastlog = $rootDir . "/logs/blast/blast.log";
my $seqMetaDataFile = $rootDir . "/data/FASTA/fastaMetaData";

my $mailprog = '/usr/lib/sendmail'; # for email return

my $maxMaxScores = 500;
my $maxMaxAlign = 250;
my $largeDatasetThresh = 50000000; # what size dataset is considered "large"

# keep track of whether Content-type header has been printed
# yet or not to avoid collisions
my $headerPrinted = 0;

# URLs to use when inserting hyperlinks into HTML results
my $PIR = 'http://www-nbrf.georgetown.edu/cgi-bin/nbrfget?uid=';

my $GB_NT_old =
   "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&db=Nucleotide&doptcmdl=GenBank&term=";

my $GB_NT_EST = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nucest&id=';
my $GB_NT_CORE = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nuccore&id=';

my $GenPept_old =
   'http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi?'
  .'cmd=Retrieve&db=Protein&dopt=GenPept&list_uids=';

my $GenPept = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=protein&id=';

my $TIGR = "http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=Retrieve&dopt=full_report&list_uids=";

#   "http://www.tigr.org/tigr-scripts/euk_manatee/shared/"
#  ."ORF_infopage.cgi?db=ath1&orf=";
my $TIGR_BAC =
   "http://www.tigr.org/tigr-scripts/euk_manatee/"
  ."BacAnnotationPage.cgi?db=ath1&asmbl_id=";

my $MIPS = 'http://signal.salk.edu/cgi-bin/tdnaexpress?gene=';
#'http://mips.gsf.de/cgi-bin/proj/thal/search_gene?code=';
my $SEED_DETAIL = "/servlets/SeedSearcher?action=detail&stock_number=";
my $LOCUS_DETAIL = "/servlets/TairObject?type=locus&name=";
my $ASSEMBLY_UNIT_DETAIL = "/servlets/TairObject?type=assembly_unit&name=";

my $UNIPROT = "http://www.uniprot.org/entry/";

select(stdout);
$| = 1;

my $submitSeq = 1;		## if submit locus name, $submitSeq = 0

my $cgi = CGI->new();

# Do standard HTTP stuff #
my $targetSet = $cgi->param('BlastTargetSet');
my $algorithm = $cgi->param('Algorithm');

my $GB_NT = $GB_NT_EST;
    if ($targetSet =~ /exp|genomic|refseq/i) {  #eq "ATH1_pep" or $database eq "ArabidopsisP" ) {
	$GB_NT = $GB_NT_CORE; #$GenPept;
    }

my ( $sequence, $locusName, @loci );

my $textbox = $cgi->param('textbox');

if ( $textbox eq 'seq' ) {
    $sequence = $cgi->param('QueryText');
}
else {
    $submitSeq = 0;
    $locusName = $cgi->param('QueryText');
}

my $filename = $cgi->upload('upl-file');

my $comment = $cgi->param('Comment');
my $email = $cgi->param('ReplyTo');
my $queryFilter = $cgi->param('QueryFilter');

if ( $queryFilter ne 'T' ) {
    $queryFilter = "F";
}

my $replyVia = $cgi->param('ReplyVia');
my $replyFormat = $cgi->param('ReplyFormat');

my $expectation = $cgi->param('Expectation'); # E "default"
my $maxScores = $cgi->param('MaxScores'); # S "default"
my $maxAlign = $cgi->param('MaxAlignments'); # B & V "100"
my $matrix = $cgi->param('Matrix'); # -matrix "BLOSUM62"
my $gapAlign = $cgi->param('GappedAlignment'); # -gap
my $psiExpect = $cgi->param('PsiExpectation');
my $passes = $cgi->param('Passes'); # PsiBlast Iterations
my $openPenalty = $cgi->param('OpenPenalty'); # Gap Open Penalty
my $extThresh = $cgi->param('ExtensionThreshold'); # Extension Threshold
my $extendPenalty = $cgi->param('ExtendPenalty'); # Gap Extension Penalty
my $wordSize = $cgi->param('WordSize');
my $gapTrigger = $cgi->param('GapTrigger'); # PsiBlast Gap Trigger
my $nucleicMatch = $cgi->param('NucleicMatch');
my $threshold = $cgi->param('Threshold'); # Reporting Threshold
my $nucleicMis = $cgi->param('NucleicMismatch');
my $showGI = $cgi->param('ShowGI'); # Show GI Numbers
my $queryGC = $cgi->param('QueryGeneticCode'); # Query and Database Genetic Code

my $fieldRecord = $cgi->param('FieldRecord');
my $field = $cgi->param('Field');



# use the descriptions from the meta data file as database names
my %dbLabels = ( );


open( DATABASES, $seqMetaDataFile ) 
    or die( "Error! $0 could not open $seqMetaDataFile." );

<DATABASES>; #dump first line, should be: Name    Type    NumSeqs Residues        Date    Description
while ( <DATABASES> ) {

    chomp();
    my $line = $_;
    my ($name, $type, $num_seqs, $residues, $date, $desc) = split /\t/, $line;

    if ($name) {
	if ($type eq 'AA') { 
	    $type = "protein";
	}

	my $display = "$desc ($type)";
	$dbLabels{$name} = $display;
	#note2log("adding \$dbLabels{$name} = $dbLabels{$name}");
    }
}
close( DATABASES );


# see if we are in debug mode

my $debug = $comment eq 'debugxxx' ? 1 : 0;

if ( $replyVia ne 'BROWSER' && !$email ) {
    HTMLerror( "Please specify an email address for returning results "
          ."via email<br><br\n" );
}

# If a sequence was submitted, make sure the sequence is readable by Unix.

if ($submitSeq) {

    # Error check

    if ( !$filename && !$sequence ) {
        HTMLerror( 'No Sequence Provided. Please return to the form and '
              .'enter a sequence.' );
    }

    # If a file was submitted, convert carriage returns to newline characters
    if ($filename) {
        $sequence = "";
        while (<$filename>) {
            tr/\r/\n/;
            $sequence .= $_;
        }
    }
}

# Otherwise a locus was submitted.

else {

    # Error check

    if ( !$filename && !$locusName ) {
        HTMLerror( 'No locus name provided. Please return to the form '
              .'and enter a locus name.' );
    }

    # If a file was submitted, convert carriage returns to newline characters
    if ($filename) {
        $locusName = "";
        while (<$filename>) {
            tr/\r/\n/;
            $locusName .= $_;
        }
    }
}

my @sequence = ();
my @seqDescr = ();
my $seqLength = 0;
my @no_seq_found = ();

# If a locus name was submitted, get the sequence according to locus name

if ( !$submitSeq ) {
    my $dataset = "ATH1_cds";

    if ( $algorithm eq "blastp" || $algorithm eq "tblastn" ){
        $dataset = "ATH1_pep";
    }

    # Directory where indexed fasta files are located

    my $datadir = $rootDir ."/data/sequences/";
    my $indexfiledir = $rootDir ."/data/sequences/";
    my $datasetpath = $datadir.$dataset;
    my $indexfile   = $indexfiledir.$dataset;

    my %args = ( 'index_file' => $indexfile );

    my $fetcher = LociSeqFetch->new(%args);

    # 1, means need to add .1 to the end of locus name if there is no .1
    # extension
    ( $sequence, my $no_seq_found_ptr ) =
      $fetcher->fetch_loci_sequences( $locusName, 1 );

    @no_seq_found = @$no_seq_found_ptr;

    if ( !$sequence ) {
        my $errorMessage = "The following loci have no sequences found:<UL>\n";

        foreach my $noseq (@no_seq_found) {
            $errorMessage .= "<LI>$noseq\n";
        }

        $errorMessage .= "</UL>\n";

        HTMLerror($errorMessage);
    }
}

$sequence =~ s/^\s+//;          #Trim leading white space
$sequence =~  s/\s+$//;         #Trim trailing whitespace

# If the sequence has no leading greater-than sign, then it is assumed that
# the sequence was supplied by the user and a line with ">user-submitted
# sequence\n" needs to be prepend to the sequence variable as a pseudo fasta
# header.

if ( $sequence !~ /^>/ ) {
    $sequence = ">user-submitted sequence\n" . $sequence;
}

# Loop through the sequence if it starts with a fasta header and parse out
# the headers from the sequences into their own arrays.

while ( $sequence =~ /^(>.*)\n/m ) {
    $sequence = $';		# part after first line is sequence
    push( @seqDescr, $1 );	# push fasta header into @seqDescr list
    $sequence =~ /([^>]*)/m;
    my $tmpseq = $1;
    $tmpseq =~ s/\W//gm;
    $seqLength += length($tmpseq);
    push( @sequence, $tmpseq );
}

# Count the number of sequences from the number of fasta headers.

my $numQuerySeqs = scalar(@seqDescr);

$sequence = "";			# make sure sequence variable is undefined.

# Translate sequence text array into a scalar w/out description for
# validating below

my $validateSeq = "";
foreach my $seq (@sequence) {
    $validateSeq .= $seq;
}

# Now reconstitute the sequences with the headers in a scalar variable

while (@seqDescr) {
    $sequence .= shift(@seqDescr);
    $sequence .= "\n";
    $sequence .= shift(@sequence);
    $sequence .= "\n";
}

# Error check: Number of headers should equal number of sequences.

if ( !$numQuerySeqs or !$seqLength ) {
    HTMLerror("No sequence could be found in your submission.");
}

# Open tab-delimited file that describes the data sets
# (num seqs, num residues, etc.)

my %dataset = ();		# description of data set (target set)

open( MetaData, $seqMetaDataFile )
  or die("Could not open $seqMetaDataFile");

my @fields = split( "\t", <MetaData> );
#print "fields ".$fields[1]."\n";
while (my $line = <MetaData>) {
	chomp($line);
    my @vals = split( "\t", $line );
    my $name = $vals[0];
    if ( $name eq $targetSet ) {
	    #print "name  $name\n"; 
	    foreach $field (@fields) {
            $dataset{$field} = shift(@vals);
        }
    }
}
if($targetSet eq 'Cereon_Ath_Ler')
{
	$dataset{Name}='Cereon_Ath_Ler';
	$dataset{Type}='DNA';
	$dataset{NumSeqs}=0;
	$dataset{Residues}=0;
	$dataset{Date}='NA';
	$dataset{Description}='Landsberg Sequence from Cereon, Total Genome (DNA)';
}

#print "name=".$dataset{Name}."|name=$targetSet|type=".$dataset{Type}."\n";

close(MetaData);

# Validate sequence type in 2 stages -- first make a best guess as
# to which type of sequence (AA|NT) was submitted based on sequence
# text and chosen algorithm
my $queryType = isSequenceDNA( $validateSeq, $algorithm ) ? "DNA" : "AA";
# Next validate sequence text based on algorithm to try to determine if
# an invalid sequence was submitted - if so, print HTML error & bail out now

if ( my $errMsg = validateSequence( $validateSeq, $algorithm ) ) {
    HTMLerror(
        "$errMsg<br>Query= $queryType, " ."dataset = $dataset{ Type }<br>" );
}

# Now if/else through various sequence type/algorithm combinations and print
# error msg if mismatches received

# Algorithm is either tblastn or tblastx:

if ( $algorithm =~ /tblast[nx]/ ) {

    # Error if algorithm is tblastx and either query type or dataset type
    # is not dna

    if (
        $algorithm eq "tblastx"
        &&(   $queryType ne "DNA"
            ||$dataset{Type} ne "DNA" )
      )
    {
        HTMLerror( "$algorithm requires both query and dataset to be DNA."
              ."<br>Query = $queryType, dataset = $dataset{Type}<br>" );
    }

    # Error if algorithm is tblastn and either query type is not amino acide
    # or data type is not dna.

    if (
        $algorithm eq "tblastn"
        &&(   $queryType ne "AA"
            ||$dataset{Type} ne "DNA" )
      )
    {
        HTMLerror( "$algorithm requires query to be protein and dataset "
              ."to be DNA.<br>$sequence<br>" );
    }
}

# Algorithm is blastp (i.e. psiblast)

elsif ( $algorithm eq "blastp" ) {

    # Error if query type is not amino acid.

    if ( $queryType ne "AA" ) {
        HTMLerror( "$algorithm requires a protein query.<br>  You have "
              ."submitted a nucleotide query or locus name.  Please "
              ."go back and select again<br><br>" );
    }

    # Error if type of dataset is not amino acid

    if ( $dataset{Type} ne "AA" ) {
        HTMLerror( "$algorithm requires a protein database.<br>  You have "
              ."selected a nucleotide database $targetSet.  Please go "
              ."back and select again<br><br>" );
    }
}

# Algorithm is blastx

elsif ( $algorithm eq "blastx" ) {

    # Error if query type is not dna

    if ( $queryType ne "DNA" ) {
        HTMLerror( "$algorithm requires a nucleotide query.<br>  You have "
              ."submitted a protein query or locus name.  Please go "
              ."back and select again<br><br>" );
    }

    # Error if dataset tpe is not amino acid

    if ( $dataset{Type} ne "AA" ) {
        HTMLerror( "$algorithm requires a protein database.<br>  You have "
              ."selected a DNA database $targetSet.  Please go back "
              ."and select again<br><br>" );
    }
}

# Algorithm is blastn

elsif ( $algorithm eq "blastn" ) {

    # Error if query tpe is not dna

    if ( $queryType ne "DNA" ) {
        HTMLerror( "$algorithm requires a nucleotide query.<br>  You have "
              ."submitted a protein query or locus name.  Please go "
              ."back and select again<br><br>" );
    }

    # Error if dataset type is not dna

    if ( $dataset{Type} ne "DNA" ) {
        HTMLerror( "$algorithm requires a nucleotide database.<br>  You "
              ."have selected a protein database $targetSet.  Please "
              ."go back and select again<br><br>" );
    }
}

# Check if length of query is permitted for algorithm and dataset size

if ( $seqLength > queryLimit( $algorithm, $dataset{Residues} ) ) {
    HTMLerror( "The length of your sequence ($seqLength) is too long.  For "
          ."the size of the dataset $dataset{Name} "
          ."($dataset{Residues}) the limit on queries using "
          ."$algorithm is "
          .queryLimit( $algorithm, $dataset{Residues})
          .".<br>" );
}

# BLOSUM50, BLOSUM90 and PAM250 weight matrix options are only
# valid with BLASTN
if (
    $algorithm ne "blastn"
    and ( $matrix eq "Blosum50"
        or$matrix eq "Blosum90"
        or$matrix eq "Pam250" )
  )
{
    HTMLerror(
        "Weight matrix option $matrix cannot be used with $algorithm<br>");
}

# IE browsers try to render XML output and complain that no stylesheet is
# found.  Only allow XML output if results sent by email
if ( $replyFormat eq "XML" and $replyVia ne "EMAIL-MESSAGE" ) {
    HTMLerror( "Results can be received in XML format only by email. Please "
          ."click the 'Back' button below and select 'Return Results' to "
          ."be 'By E-mail message' and include your email address.<br>" );

}

# HTTP header -- if replying to browser and requested
# format is NOT HTML, set content type to plain text
if ( $replyVia eq "BROWSER" && $replyFormat ne "HTML" ) {
    printContentType("text/plain");
    print("TAIR Blast Job Pending")

}
else {

    printContentType("text/html");


}

# Get the maximum length of a query for the selected dataset.
my $lengthLimit = queryLimit( $algorithm, $dataset{Residues} );

# Determine the maximum number of scores
if ( $maxScores =~ /^([0-9]+)\.[0-9]*$/ ) {
    $maxScores = $1;
}

if ( $maxScores > $maxMaxScores ) {
    $maxScores = $maxMaxScores;
}
elsif ( $maxScores < 1 ) {
    $maxScores = 100;
}

# Determine the maximum alignment allowed

if ( $maxAlign > $maxMaxAlign ) {
    $maxAlign = $maxMaxAlign;
}
elsif ( $maxAlign < 1 ) {
    $maxAlign = 50;
}

# If the query type or the dataset type is "DNA", then we need to change the
# text to "NT", which is what the NCBI Blast application expects.

$queryType =~ s/DNA/NT/;
$dataset{Type} =~ s/DNA/NT/;

# Gather the options selected by the user to apply to the analysis
my $options;

## Number of processors
$options .= " -a 2";

## Boolean whether to filter the query sequence.  Default = "T" (true).
## DUST is used with blastn, SEG with others.
if ( $queryFilter && $queryFilter ne "T" ) {
    $options .= " -F F";
}

## Number of one line descriptions.  Default = 500
if ( $maxScores && $maxScores ne "500" ) {
    $options .= " -v $maxScores";
}

## Number of alignments to show.  Default = 250
if ( $maxAlign && $maxAlign ne "250" ) {
    $options .= " -b $maxAlign";
}

## Boolean whether to perform gapped alignment.  Default = "T" (true)
## Not available with tblastx.
if ( $algorithm ne "tblastx" ) {
    if ( $gapAlign && $gapAlign ne "T" ) {
        $options .= " -g F";
    }
}
else {
    $options .= " -g F";
}

## Output format.  Current options are 'HTML', 'TEXT', 'TABULAR',
## 'TABULAR_COMMENTED', 'XML' or 'ASN'. Default = 'TEXT'
if ( $replyFormat eq 'HTML' ) {
    $options .= " -T T";
}
elsif ( $replyFormat eq 'XML' ) {
    $options .= " -m 7";
}
elsif ( $replyFormat eq 'TABULAR' ) {
    $options .= " -m 8";
}
elsif ( $replyFormat eq 'TABULAR_COMMENTED' ) {
    $options .= " -m 9";
}
elsif ( $replyFormat eq 'ASN' ) {
    $options .= " -m 10";

    # ASN format needs this option set true ("believe the query defline")
    $options .= " -J T";
}

## Expectation value.  Default = 10.0
if ( $expectation && $expectation ne "10" ) {
    $options .= " -e $expectation";
}

## Matrix.  Default = "BLOSUM62"
if ( $matrix && $matrix ne "Blosum62" ) {
    $options .= " -M $matrix";
}

## Cost to open a gap.  Default = 0
if ( $openPenalty && $openPenalty ne "0 (use default)" ) {
    $options .= " -G $openPenalty";
}

## Cost to extend a gap.  Default = 0
if ( $extendPenalty && $extendPenalty ne "0 (use default)" ) {
    $options .= " -E $extendPenalty";
}

## Word size.  Default = 0 ( default translates to 11 for nucs and 3 for
## proteins )
if ( $wordSize && $wordSize ne "0 (use default)" ) {
    $options .= " -W $wordSize";
}

## Reward for a nucleotide match.  Default = 1.  Used by blastn only.

if ( ($nucleicMatch && $nucleicMatch ne "1") and $algorithm = "blastn" ) {
    $options .= " -r $nucleicMatch";
}

## Threshold for extending hits.  Default = 0
if ( $extThresh && $extThresh ne "0 (use default)" ) {
    $options .= " -f $extThresh";
}

## Penalty for a nucleotide mismatch.  Default = -3
if ( $nucleicMis && $nucleicMis ne "-3" ) {
    $options .= " -q $nucleicMis";
}

## Query Genetic code to use.  Default = 1.  For use by blastx and tblast(NX)
## only.
## 1 = standard or universal
## 2 = vertebrate mitochondrial
## 3 = yest mitochondrial
## 4 = mold, protozoan, coelenterate mitochondrial and mycoplasma/spiroplasma
## 5 = invertebrate mitochondrial
## 6 = ciliate macronuclear
## 9 = echinodermate mitochondrial
## 10 = alternative ciliate macronuclear
## 11 = eubacterial
## 12 = alternative yeast
## 13 = ascidian mitochondrial
## 14 = flatworm mitochondrial
if (   ( $algorithm eq "blastx" or $algorithm =~ /tblast[nx]/ )
    and( $queryGC && $queryGC ne "1" ) )
{
    $options .= " -Q $queryGC";
}

if ( $replyVia eq  'EMAIL-URL' ) {
    print( "<br>When done, the results of this analysis will be available "
          ."<a href=$httpRoot$$.html>here</a>.<br>  This URL will be "
          ."mailed to you at $email, so you don't have to wait on this "
          ."page.<p>" );
}

# Set up some logging data

my $startTime = time();		# see how long it takes in seconds
my $remoteHost = $ENV{'REMOTE_HOST'};
my $remoteIP = $ENV{'REMOTE_ADDR'};
my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
  localtime($startTime);
my $thetime = sprintf(
    "%2d/%2d/%2d:%2d:%2d:%2d",
    $mday, $mon + 1,$year + 1900,
    $hour, $min, $sec
);
$thetime =~ s/ /0/g;
note2log( "$remoteIP\t$remoteHost\t$thetime\t$algorithm\t$targetSet"
      ."\t$seqLength\t$replyVia" );

# save any warnings generated by running program for printing later
my @warnings;

eval{

    # Create RemoteCluster instance to handle communication with
    # Analysis Farm
    my $server = RemoteCluster->new();

    # Define which queue to load the program into depending on the algorithm.
    my $queue = 1;		# short queue

    if (  $algorithm eq "tblastx"
        ||$algorithm eq "tblastn" )
    {
        $queue = 0;		# long queue
    }

    # Create command string to execute on remote server
    my $command =
      "\$NCBIN/blastall -p $algorithm -d \$NCREF/$targetSet $options";

#note2log("command: " . $command . "\n" .
#         "priority: " . $queue . "\n" .
#         "sequence: " . $sequence . "\n");

    # Create args hash to pass to server for execution
    # Query sequence must be submitted to remote job as STDIN.
    my %args = (
        'command' => $command,
        'priority' => $queue,
        'stdin' => $sequence
    );

    # Execute the Blast program on the Analysis Farm.
    my ($response) = $server->Submit(%args);

    # Wait for completion of the task, sending information to the user's screen
    my $queued = 0;
    my $running = 0;
    my $secs = 1;
    if ( $queue == 0 ) {
        $secs = 5;
    }				# Wait longer if on long queue

    # use <BR> or \n for line break depending on whether we're printing
    # HTML or plain text
    my $lineBreak =
      ( $replyVia eq "BROWSER" &&$replyFormat ne "HTML") ?"\n" : "<br>";
    do{
        $response = $server->Status();

        if ( $response =~ "PleaseRun" ) {
            if ( not $queued ) {
                $queued = 1;

            }
            else {

            }

            sleep($secs);
        }
        elsif ( $response =~ "Running" ) {
            if ( not $running ) {
                $running = 1;

            }
            else {

            }

            sleep($secs);
        }
        else {

        }
    }while ( $response =~ "PleaseRun" || $response =~ "Running" );

    # Check for errors. Error log will be the output to STDERR
    # generated by BLAST as it ran. Need to check and make sure
    # that messages are not just warnings before really bailing out.
    my $errorLog = $server->ErrorLog();
    if ( length($errorLog) > 5 ) {

        my @lines = split( /\n/, $errorLog );
        my $errorFlag = 0;
        my $numLines = scalar(@lines);

        foreach my $line (@lines) {

            # if line begins w/WARNING label save for printing later
            if ( $line =~ /^\[blastall\] WARNING/ ) {
                push( @warnings, $line );

                # else, treat as a fatal error and bail out now -- check to
                # make sure that line contains more than just the SOH (start
                # of heading) char (ASCII 1)
            }
            elsif ( $line ne chr(1) ) {
                $errorFlag = 1;
                last;
            }
        }

        if ($errorFlag) {
            print( STDERR "$errorLog\n" );
            $server->CleanUp();
            HTMLerror("<b>$errorLog</b><br>");
        }
    }

    # Retrieve the results
    my $results = $server->Retrieve();

    # Set the name of the database used
    $results = filterDBName($results);

    # Clean up the results on the machine that executed the Blast
    $server->CleanUp();

    # Write the results to $TMPPATH$RESFILE
    open( RESULT, ">$TMPPATH$RESFILE" )
      or die("Can't create output file $TMPPATH$RESFILE: $!\n");
    print( RESULT $results );
    close(RESULT);
};

# Trap any errors in the above eval block

if ($@) {
    HTMLerror( "$@ <BR>Please send email to "
          ."informatics\@arabidopsis.org to report this error." );
}

if ( $replyVia eq 'EMAIL-MESSAGE' ) {
    open( MAIL, "|$mailprog $email" ) || die("Can't open $mailprog!\n");

    tair_header( "TAIR BLAST Result" );
    print("<TABLE width=600    align =\"CENTER\"><TR><TD>\n");
    print("Output sent to $email\n");
    print("</TD></TR></TABLE>");
    tair_footer();
    print( MAIL "From: TAIR_BLAST\@arabidopsis.org\n" );
    print( MAIL "To: $email\n" );

    if (  $comment
        &&$comment !~ 'optional, will be added to output for your use' )
    {
        print( MAIL "Subject: TAIR BLAST Search Results: $comment\n\n" );
    }
    else {
        print( MAIL "Subject: TAIR BLAST Search Results\n\n" );
    }

    select(MAIL);		# all output will go to this mail job
}
elsif ( $replyVia eq  'EMAIL-URL' ) {
    open( MAIL, "|$mailprog $email" ) || die("Can't open $mailprog!\n");
    print( MAIL "From: TAIR_BLAST\@arabidopsis.org\n" );
    print( MAIL "To: $email\n" );

    if (  $comment
        &&$comment !~ 'optional, will be added to output for your use' )
    {
        print( MAIL "Subject: TAIR BLAST Search Results: $comment\n\n" );
    }
    else {
        print( MAIL "Subject: TAIR BLAST Search Results\n\n" );
    }

    print( MAIL "Your results are here: $httpRoot$$.html\n" );

    open( URL_Retrieval, ">$URLPATH$$.html" )
      or note2log("Could not open $URLPATH$$.html for writing");

    note2log("writing to $URLPATH$$.html");
    select(URL_Retrieval);	# all output will go to this mail job
}

# Output format is HTML.
if ( $replyFormat eq 'HTML' ) {
    if ( index( $replyVia, "EMAIL" ) < 0 ) {
        printContentType("text/html");
        print( "<HTML><HEAD><TITLE>TAIR BLAST Results</TITLE></HEAD>"
              ."<BODY BGCOLOR=#FFFFFF>" );
    }

    open( BLAST, "<$TMPPATH$RESFILE" ) || die("\n");

    # pass error message string if any occurred
    my $errorMessage;

    # if locus name not found...
    if ( scalar(@no_seq_found) > 0 ) {
        $errorMessage =
           "<FONT color=red>The following loci have no "
          ."sequences found:</FONT><UL>\n";

        foreach my $noseq (@no_seq_found) {
            $errorMessage .= "<LI>$noseq\n";
        }

        $errorMessage .= "</UL>\n";
    }

    # print any warnings received from remote server
    if (@warnings) {

        $errorMessage .=
           "<br><font color=red>BLAST job completed with "
          ."the following warnings</font>:<br>";

        foreach my $warning (@warnings) {
            $errorMessage .= "$warning<br>";
        }
        $errorMessage .= "<br>";
    }

    formatOutputToHTML( \*BLAST, $errorMessage, "" );

    print("</body></html>\n");
}

# Output format is text.
else {

    if (  $comment
        &&$comment !~ 'optional, will be added to output for your use' )
    {
        print("For: $comment\n\n");
    }

    # print any warnings received from remote server
    if (@warnings) {
        print "\nBLAST job completed with the following warnings:\n";
        foreach my $warning (@warnings) {
            print "$warning\n";
        }
        print "\n";
    }

    open( BLAST, "<$TMPPATH$RESFILE" ) || die("\n");

    while (<BLAST>) {
        print("$_");
    }
}

close(BLAST);
close(MAIL) if (MAIL);
close(URL_Retrieval) if (URL_Retrieval);

Cleanup();

my $seconds = time - $startTime;
note2log("Done, elapsed time = $seconds");

exit 0;

##############################################################################

###################################################################################
# limits on lengths of queries for different algorithms
# input algorithm, datasetsize in number of residues
###################################################################################

sub queryLimit(){
    my $alg = shift;
    my $datasetsize = shift;
    if ( $alg eq 'blastn' ) {
        return 25000;
    }
    elsif ( $alg eq 'blastx' ) {
        return 25000;
    }
    elsif ( $alg eq 'blastp' ) {
        return 5000;
    }
    elsif ( $alg eq 'tblastn' ) {
        return $datasetsize < $largeDatasetThresh ? 3000 : 2500;
    }
    elsif ( $alg eq 'tblastx' ) {
        return $datasetsize < $largeDatasetThresh ? 3000 : 2500;
    }
    else {
        HTMLerror("Algorithm not recognized: $algorithm.<br><br>");
    }
}

###########################################
# Make note in blast log, use for debugging
###########################################

sub note2log($){
    open( blastlog, ">>$blastlog" ) or warn("could not open $blastlog:$!\n");
    my $text = shift;
    print( blastlog "$$ \t$text\n" );
    close(blastlog);

}				# note2log()

#########################################################################
# Perform a simple test of whether sequence is DNA or Protein
# This test could be mislead, but it should work most of the time
#
# Validation rules from Eva:
#
# Use user's choice of algorithm to infer what type [AA|NT] of sequence is
# allowed to be submitted, then make sure there are no chars in sequence
# that suggest that opposite type has been submitted
#
# User says it's protein (meaning blastp or tblastn are chosen)
#    If sequence has U and does not have EFILPQXZ
#       it is nucleotide
#    If sequence has only ACGTN
#       it is nucleotide
#      (this could in theory be a valid protein, but probably does not
#       exist in real life - this should catch most of the user errors
#       in choosing the wrong blast program)
#    Else
#       accept it as protein
#
# User says it's nucleotide (meaning blastn, blastx or tblastx)
#    If sequence has EFILPQXZ and does not have U
#       it is protein
#    Else
#       accept it as nucleotide
#
###########################################################################
sub isSequenceDNA($$){
    my $seq = shift;
    my $algorithm = shift;
    my $isDNA = 0;

    if (  $algorithm eq "blastp"
        ||$algorithm eq "tblastn" )
    {

        if ( $seq =~/Uu/ && !( $seq =~ /[EFILPQXZefilpqxz]/ ) ) {
            $isDNA = 1;
        }
        elsif ( !( $seq =~ /[^ACGTNacgtn]/ ) ) {
            $isDNA = 1;
        }
    }
    elsif ( $algorithm eq "blastn"
        ||$algorithm eq "blastx"
        ||$algorithm eq "tblastx" )
    {
        if ( !( $seq =~ /[Uu]/ ) && $seq =~ /[EFILPQXZefilpqxz]/ ) {
            $isDNA = 0;
        }
        else {
            $isDNA = 1;
        }
    }

    return $isDNA;

}				# isSequenceDNA()

##############################################################################
# Validates sequence along with choice of algorithm - if sequence
# contains chars that should not be in type of sequence (NT|AA) implied
# by algorithm, return err msg.  An empty err msg means sequence is valid
#
# Validation  rules from Eva
#
# User says it's protein (meaning blastp or tblastn are chosen)
#    If sequence (has J or O), or (has any of EFILPQXZ and also has U) ->
#       not valid, give error
#
# User says it's nucleotide (meaning blastn, blastx or tblastx)
#    If sequence (has J or O), or (has any of EFILPQXZ and also has U) ->
#       not valid
#    If sequence has EFILPQXZ and does not have U
#       it is protein (not valid )
#
##############################################################################
sub validateSequence($$){
    my $seq = shift;
    my $algorithm = shift;
    my $errMsg;

    if ( $algorithm eq "blastp" || $algorithm eq "tblastn" ) {
        if (
            $seq =~ /[JjOo]/
            ||(   $seq =~ /[EFILPQXZefilpqxz]/
                &&$seq =~ /[Uu]/ )
          )
        {
            $errMsg = "Invalid sequence for $algorithm<br>sequence: $seq";
        }

    }
    elsif ( $algorithm eq "blastn"
        ||$algorithm eq "blastx"
        ||$algorithm eq "tblastx" )
    {
        if (
            $seq =~ /[JjOo]/
            ||(   $seq =~ /[EFILPQXZefilpqxa]/
                &&$seq =~ /[Uu]/ )
          )
        {
            $errMsg = "Invalid sequence for $algorithm<br>sequence: $seq";
        }
    }

    return($errMsg);

}				# validateSequence()

########################################################################
#
# Remove output files.
#
########################################################################
sub Cleanup(){
    if ( -e $TMPPATH . $RESFILE ) {
	    unlink( $TMPPATH . $RESFILE );
    }

    # I suspect the following file may get different process ids for their
    # names
    if ( -e $TMPPATH . $RESFILE . "mapdata" ) {
	    unlink( $TMPPATH . $RESFILE . "mapdata" );
    }

    return();

}				# Cleanup()

########################################################################
#
# HTMLerror:    When everything else doesn't work, this should.
#
########################################################################

sub HTMLerror(){
    printContentType("text/html");
    tair_header( "TAIR BLAST Error" );
    print("<table width=600    align =\"CENTER\"><TR><TD>\n");
    print("<FONT color=red> Error: </FONT> @_");
    print("<p>");
    print("<I><A HREF = javascript:history.back(-1)>Back</a></I>");
    print("</TD></TR></TABLE>");
    tair_footer();

    exit;

}				# HTMLerror()

########################################################################
#
# printContentType : Print content-type header using submitted type.
# Checks status of $headerPrinted to avoid printing twice
#
########################################################################
sub printContentType($){
    my $contentType = shift;

    if ( !$headerPrinted ) {
        print("Content-type: $contentType\n\n");
        $headerPrinted = 1;
    }
}

########################################################################
#
# formatOutputToHTML: Go through results line by line and parse results
# to insert helpful HTML links to TAIR, GenBank, TIGR, etc.  Parsing
# format is different for different types of datasets.  HTML format
# results are automatically written with hyperlinks on Scores in  summary
# pointing to anchors down below in detail.
#
########################################################################

sub formatOutputToHTML() {
    my $BLAST = shift;
    my $errorMessage = shift;
	
	my $dbname = $dbLabels{$targetSet};

    print("<h1>BLAST query on ".(defined($dbname)?$dbname:$targetSet)." sequences</H1><br>\n");

    if (  $comment
        &&$comment !~ 'optional, will be added to output for your use' )
    {
        print("<font size=4><b>Results for</b> $comment</font><br><br>\n");
    }

    print( "<I>Query performed by the <A HREF=\"/\">"
          ."The Arabidopsis Information Resource (TAIR)</A> for full "
          ."BLAST options and parameters, refer to the NCBI" );
    print( "<A HREF=\"http://www.ncbi.nlm.nih.gov/BLAST/\">"
          ."BLAST Documentation</A></I>" );
    print( "<p>Your comments and suggestions are requested: Send a Message "
          ."to <a href=\"mailto:curator\@arabidopsis.org\">TAIR</a>" );
    print("<p>");
    print("$errorMessage");
    print("<pre>");

    my $counter = 0;
    my $counter2 = 0;
    my @anames;

    while (<$BLAST>) {
        chomp();
	
	if(/Searching\.\.\..*done$/i)
	{
		$_ = $_."\n</b>\n";
	}
        ### Matches TDNA insertion flank sequences  - targetSet = TDNA
        if (/Stock/) {
            my ( $seedID, $seedURL, $genBank, $genBankURL, $locus, $locusURL );

            # add link to seed stock detail page

            if ( $_ =~ /Stock\|(\S+)\s?/ ) {
                $seedID = $1;
                $seedURL =
                  "<a href=\"$SEED_DETAIL$seedID\" " ."target=_new>$seedID</a>";
                $_ =~ s/$seedID/$seedURL/;
            }

            # add link to GenBank

            if ( $_ =~ /GB\|(\S+)\s?/ ) {
                $genBank = $1;
                $genBankURL =
                  "<a href=\"$GB_NT$genBank\" " ."target=_new>$genBank</a>";
                $_ =~  s/$genBank/$genBankURL/;
            }

            # add link to TairObject locus detail page

            if ( $_ =~ /Locus\|(\S+)\s?/ ) {
                my $locus = $1;
                $locusURL =
                  "<a href=\"$LOCUS_DETAIL$locus\" " ."target=_new>$locus</a>";
                $_ =~ s/$locus/$locusURL/;
            }
        }

        ### Matches TIGR BACS dataset=ATH1_bacs_con ###
        elsif ( $targetSet =~ /ATH1_bacs_con/ ) {

            # if in summary, first char is not >, if in detail down below
            # first char is > and HTML anchor is in string before clone
	    #if (/^>?(<a.+<\/a>)?(\w+)\s*(\d{5})/) {
	    if (/^>?(<a.+<\/a>)?(\w+)(<\/a>)?\s*(\d{5})/) {
                my $clone_name = $2;
                my $tigr_id = $4;
		
		$_ =~ s/><a.*<\/a>/>/;

                ## link to TIGR's database for this BAC
                if ( $tigr_id ne "" ) {
                    my $url =
                       "<a href=\"$TIGR_BAC$tigr_id\" "
                      ."target=_new>$tigr_id</a>";
                    $_ =~ s/$tigr_id/$url/;
                }

                ## link to TAIR assembly unit detail page
                if ( $clone_name ne "" ) {
		    my $url2="<a name = $clone_name></a>";
                    my $url =
                       "<a href=\"$ASSEMBLY_UNIT_DETAIL$clone_name\" "
                      ."target=_new>$clone_name</a>";
                    $_ =~ s/^$clone_name/$url/;
                    $_ =~ s/^>/>$url2$url/;
                }
            }
        }
        
        
        ### Matches Uniprot dataset = uniprot ###
        elsif ( $targetSet =~ /At_Uniprot_prot/ ) {

            # if in summary, first char is not >, if in detail down below
            # first char is > and HTML anchor is in string
            if (/^>?(<a.+<\/a>)?((\w+)\s*\|\s*(\w+))(\s*.*)/) {
                my $uniprot_id = $4;
		my $all = $2;

                ## link to uniprot
                if ( $uniprot_id ne "" ) {
                    my $url =
                       "<a href=\"$UNIPROT$uniprot_id\" "
                      ."target=_new>$uniprot_id</a>";
		    $_ =~ s/$uniprot_id/$url/; 
                }

            }
        }
        

        ## matches Landsberg Cereon sequences --- do nothing explicitly...
        elsif (/ATL/) {
            ;
        }

        # the following pattern matches the ncbi descriptions including
        # protein and AGI_BAC, recent_at, AtBACEND, AtEST, ArabidopsisN
        # and AtANNOT, brassica & PlantDNA subsets
        elsif (/^>?(<a.+<\/a>)?gi\|/) {

            # if in summary, first char is not >, if in detail down below
            # first char is > and HTML anchor is in string before locus
            if (/^>?(<a.+<\/a>)?gi\|(\d+)/) {
                my $giNumber = $2;

                # link to NT or AA URL at GenBank depending on dataset
                my $giURL;
                if (  $targetSet eq "At_flanks_DNA"
                    ||$targetSet eq "At_GB_genomic"
                    ||$targetSet eq "At_GB_exp_tx_DNA"
                    ||$targetSet eq "At_GB_refseq_tx_DNA"
                    ||$targetSet eq "gp_GB_genomic_DNA"
                    ||$targetSet eq "gp_GB_exp_tx_DNA"
                    ||$targetSet eq "gp_GB_refseq_tx_DNA" )
                {

                    $giURL =
                      "<a href=\"$GB_NT$giNumber\" target=_new>$giNumber</a>";

                }
                else {
                    $giURL =
                      "<a href=\"$GenPept$giNumber\" target=_new>$giNumber</a>";
                }

                $_ =~ s/$giNumber/$giURL/;
            }
        }

        # Matches At_* sets derived from TIGR data:
        # upstream/downstream, intron, intergenic and transcripts
        elsif ( $targetSet =~ /At_/ || $targetSet =~ /^ATH1_/) {

            # if in summary, first char is not >, if in detail down below
            # first char is > and HTML anchor is in string before locus
	    #if (/^>?(<a.+<\/a>)?(A[Tt][1-5mMcC][Gg]\d{5})(\.\d)?/) {
            if ($_ !~ /TAIR:(A[Tt][1-5mMcC][Gg]\d{5})(\.\d)?|(A[Tt][1-5mMcC][Gg]\d{5})(\.\d)?\//i && $_ =~ />?(<a.+<\/a>)?(AT[1-5mMcC]G\d{5})(\.\d)?/) {
                my $locus = $2;
                my $suffix = $3;

		#fixed, last time we were not allowing the same page links
		#the introns are also fixed, however, if two introns from the same model show up, there
		#will be problems
                my $locusURL1 =
                   "<a name=\"$locus$suffix\"></a>";
                my $locusURL2 ="<a href=\"$LOCUS_DETAIL$locus\" target=_new>$locus</a>$suffix";
		   #$_ =~ s/$locus$suffix/$locusURL/;
		$_ =~  s/^$locus$suffix/$locusURL2/g;
		$_ =~  s/^><.*>/>$locusURL1$locusURL2/g;
		$_ =~ s/(#AT\wG\d{5}\.\d+)\-\d+/$1/g;
		#$_ =~ s/^><a name = />/;
		#   $_ =~ s/>>/>/;
		   #."target=_new>$locus$suffix</a>";
		   #$_ =~ s/$locus$suffix/$locusURL/;
            }
        }

        # for PIR proteins in NCBI's nr  -- matches ArabidopsisP
        # ArabidopsisP contains PIR proteins as well as GenBank -- this
        # branch will be processed only if GenBank gi number is not first string
        # in header -- if so, it will be caught by GenBank branch above
        elsif ( $targetSet eq "ArabidopsisP" ) {

            # if in summary, first char is not >, if in detail down below
            # first char is > and HTML anchor is in string before seq name
            if (/^>?(<a.+<\/a>)?([A-Z]+\d{4,6})/) {
                my $seqName = $2;

                my $seqURL =
                  "<a href=\"$PIR$seqName\" target=_new>$seqName</a>";

                $_ =~ s/$seqName/$seqURL/;
            }
        }

        ##### Matches TIGR sets - ATH1_seq, ATH1_pep, ATH1_cds and generated
        ##### sets of TIGR UTRs ATH1_3_UTR and ATH1_5_UTR
        elsif ( $targetSet =~ /^ATH1_/ ) {

            if ($_ =~ />?(<a.+<\/a>)?(AT[1-5mMcC]G\d{5})(\.\d)?/ && $_ !~ /TAIR:(A[Tt][1-5mMcC][Gg]\d{5})(\.\d)?|(A[Tt][1-5mMcC][Gg]\d{5})(\.\d)?\//i) {

                my $locus = $2;

                # remove leading > sign
                $_ =~ s/^>//;

                # create links to TIGR, MIPS & TairObject locus detail page
		my $tigrURL = ""; #"<a href=\"$TIGR$locus\" target=_new>TIGR</a>";
                my $mipsURL = "<a href=\"$MIPS$locus\" target=_new>SIGnAL</a>";
                my $tairURL =
                  "<a href=\"$LOCUS_DETAIL$locus\" target=_new>TAIR</a>";

                # add links to beginning of header
		#$_ = "$tairURL|$tigrURL|$mipsURL " . $_;
		#no longer doing this
		#$_ = "$tairURL|$mipsURL " . $_;
            }
        }

        # find out size of database and update fastaMetaData if necessary
        elsif (/^\s+Database: /) {
            my $dbsize = 0;
            my $dbdate = 0;
            my $dbseqs = 0;
            print("$_\n");
            $_ = <$BLAST>;
            print();

            if (/^\s+Posted date:\s+(\w+ \d+, \d+)/) {
                $dbdate = $1;
                $_ = <$BLAST>;
                print();

                if (/^\s+Number of letters in database:\s+([0-9,]+)/) {
                    $dbsize = $1;
                    $dbsize =~ s/,//g;
                    $_ = <$BLAST>;
                    print();

                    if (/^\s+Number of sequences in database:\s+([0-9,]+)/) {
                        $dbseqs = $1;
                        $dbseqs =~ s/,//g;
                    }
                }
            }

            if (   $dbsize
                && $dataset{Residues}
                &&$dbsize != $dataset{Residues} )
            {
                print( "Updating fastaMetaData size for $dataset{Name} "
                      ."from $dataset{Residues} to $dbsize\n" );
                note2log( "Updating fastaMetaData size for $dataset{Name} "
                      ."from $dataset{Residues} to $dbsize" );

                open( MetaData, $seqMetaDataFile )
                  or die("Could not open $seqMetaDataFile");

                my $metadata = "";

                while (<MetaData>) {
                    if (/^$dataset{Name}/) {
                        my @row = split "\t";

                        # Name  Type  NumSeqs  Residues  Date  Description
                        $_ = join "\t",
                          (
                            $row[0], $row[1], $dbseqs,
                            $dbsize, $dbdate, $row[5]
                          );
                    }

                    $metadata .= $_;
                }

                close(MetaData);

                open( MetaData, ">$seqMetaDataFile" )
                  or die("Could not open $seqMetaDataFile");
                print( MetaData $metadata );
                close(MetaData);
            }

            next;			# i.e., don't do the following print statement
        }

        print("$_\n");

    }				#End of While

    print("</PRE>");

}

# formatOutputToHTML()

sub filterDBName () {
  
    my $line = shift;

    if ( exists $dbLabels{$targetSet} ) {
	my $name = $dbLabels{$targetSet};
	$line =~ s/(Database:\s*)(.*$targetSet)(\s*)/$1 $name$3/g;
    }

    return "$line";
}

