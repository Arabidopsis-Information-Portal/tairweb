#!/bin/env perl

###########################################################
############################################################
use lib "../sequences/";
use lib "lib/";
use LociSeqFetch;
use oligoAnalysisTools; 
use Bio::Seq;
use Bio::SeqIO; 
use Bio::Index::Fasta;
use PDL; 
use PDL::IO::FastRaw;  
use PDL::Char;  
use IO::File;
use Sort::Fields;

use CGI qw/:standard :html3/;
use CGI::Carp qw(fatalsToBrowser);
use strict;

my $dataDir = "data/";
my $seq_datadir = "../sequences/data/" ;
my $seq_indexfiledir = "../sequences/data/" ;
my $UPSTREAM_500=$seq_datadir."At_upstream_500";
my $UPSTREAM_1000=$seq_datadir."At_upstream_1000";

my $cgi = new CGI;
my $input = $cgi -> param("input");
my $upstream  = $cgi -> param("upstream");
my $output_type = $cgi -> param("output_type");
my $sequence;
my $no_seq_found ;
my @loci;

#my $NUM_BACKGROUND_SEQS=31407;
my $NUM_BACKGROUND_SEQS=get_num_background_seqs();
if(!$NUM_BACKGROUND_SEQS)
{
	die "couldn't retrieve the correct number of background sequences, exiting!\n";
}
chomp($NUM_BACKGROUND_SEQS);
$NUM_BACKGROUND_SEQS=trim($NUM_BACKGROUND_SEQS);

my $MIN_NUM_TIMES_DISTINCT_GENE_CONTAINS_OLIGO=3;
my $CHECK_BOTH_STRANDS=1;

# are we uploading a file?
#
my $uploadStr="";
my $fh = $cgi->upload("file");

if ($fh) {
    while (<$fh>) {
	$uploadStr .= $_;    
    }
    $input = $uploadStr;
}

$input = trim($input);

if ( ! $input) {   
   &start_page();
   &complain_input($input); 
   &end_page();  
} else {
   if ( isLociNames( $input) ) {
	@loci = grep {$_} split /\W+/, uc($input) ;
	my $seq_datasetpath = $seq_datadir."At_upstream_".$upstream ;
	my $seq_indexfile   = $seq_indexfiledir."At_upstream_".$upstream ;

	my %args = ('index_file' => $seq_indexfile ); 
 
	my $fetcher = LociSeqFetch->new(%args);
	($sequence, $no_seq_found) = $fetcher->fetch_loci_sequences_by_array(\@loci, 0, $output_type ); 
    } elsif ( isNotValid($input) ) {
	&start_page();
	&complain_input($input); 
	&end_page();
    } else {
	$sequence = $input ;
    }

    my $oligoLength = 6;
    my $oligoPDL = PDL::Char->new( readfraw( $dataDir."oligoPDL_6mer" ) );   
    my $bkgrndCountsFileName = "Upstream_all_".$upstream."bp6_mer_both_strands_counts";

    my $bkgrndCountsNormFileName = "Upstream_all_".$upstream."bp6_mer_both_strands_counts_norm"; 
    my $bkgrndCounts = readfraw($dataDir.$bkgrndCountsFileName );
    my $bkgrndCountsNorm = readfraw($dataDir.$bkgrndCountsNormFileName);
    my $tmpFile = "/var/tmp/oligoAnalysis_"; 
    my ( $fh ) = IO::File->new("> $tmpFile" );

    print $fh $sequence;
    undef $fh;

    my ($node, $nodeSize, $nodeCounts, $nodeCountsNorm, $pdlHypNorm);
    $nodeSize = countSeqs('file'=>$tmpFile);
    ($nodeCounts , $nodeCountsNorm) = countOligos('file'=>$tmpFile, 
                                       'oligoLength'=>$oligoLength, 
                                       'bothStrands'=>$CHECK_BOTH_STRANDS);
    $pdlHypNorm = calcBinomial( 'bkgrndCounts'=>$bkgrndCountsNorm, 
                                'nodeCounts'=>$nodeCountsNorm, 
                                 'bkgrndSize'=>$NUM_BACKGROUND_SEQS,  #'28088', 
                                 'nodeSize'=>$nodeSize);   

    my ( @oligo_results , @sorted_results); 
    my  @positions ;   
    for (my $i=0; $i <= 4095; $i++) { 
	next if ( $nodeCountsNorm->at($i) <= $MIN_NUM_TIMES_DISTINCT_GENE_CONTAINS_OLIGO-1 );
	push @positions, $i;
  	push @oligo_results , ( sprintf "%s\t%s\t%s\t%s\t%s\t%.2e\t%s", 
				$oligoPDL->atstr($i),
                                $nodeCounts->at($i), 
                                $bkgrndCounts->at($i), 
				$nodeCountsNorm->at($i)."/".$nodeSize,
				$bkgrndCountsNorm->at($i)."/$NUM_BACKGROUND_SEQS",
				$pdlHypNorm->at($i), 
				$i );

    }
    # hashref of position-> sequences
    my $sequence_namerefe = oligoAnalysisTools::getSequencesAtPosition('file'=>$tmpFile, 
								    'oligoLength'=>$oligoLength, 
								    'bothStrands'=>$CHECK_BOTH_STRANDS, 
								    'position'=>\@positions);
 
    @sorted_results = fieldsort ["6n" ] , @oligo_results;

    my $result_message = "Only oligos occurring in $MIN_NUM_TIMES_DISTINCT_GENE_CONTAINS_OLIGO or more of sequences in the query set are reported, and are sorted by p-value. Columns are as follows (left to right):\noligoMer\nAbsolute number of this oligoMer in query set\nAbsolute number in genomic set\nNumber of sequences in query set containing oligoMer\nNumber of sequences (out of $NUM_BACKGROUND_SEQS in genomic set) containing oligoMer\np-value from binomial distribution ";    
  
    if ($output_type eq "text") { 
  	&output_text( $nodeSize, $sequence_namerefe,  @sorted_results); 
    } else { 
 	&output_html($nodeSize, $sequence_namerefe, @sorted_results);
    }
}

sub output_html {
    my ($nodeSize,  $sequence_namerefe, @sorted_results) = @_;
    &start_page();
    &results_blurb() ;

    print "<center><table width=602 align=center border=0 cellspacing=3 cellpadding=2>";
    print "<p style='font-family: monospace'>";
    map { print "<TR>"; printEntryInOneLine( $_, $sequence_namerefe ); "</TR>" ; }  @sorted_results;
    print "</p>";
    print "</table></center>";
    print hr ;
    if ( isLociNames($input) ){
       print p ;
       print ( $nodeSize." sequences analyzed: " ); 
       my @found_loci; 

       if ( ! @$no_seq_found ){
          @found_loci = @loci ;
       }
       foreach my $locus (@loci) {
          my $found = 1;
          foreach my $noseq (@$no_seq_found) {
             if ($locus eq $noseq){
                $found = 0; 
             }
          }
          if ( $found == 1 ){
              print "$locus &nbsp;";
          }  
       }
       print p ;
       if ( @$no_seq_found ){
         print "The following sequences were not found:\n";
         foreach my $noseq (@$no_seq_found) {
            print "$noseq &nbsp;";
	 }
     }
    }else {
        print p( $nodeSize." sequences analyzed." ),p;
    }
    &end_page();
}

# print the entry in html table  as one line
sub printEntryInOneLine {
   my ($pdlString, $sequenceref ) = @_;
   my %sequence_names = %$sequenceref;  
   my @columns =  split (/\t/, $pdlString );
   my $index = pop @columns ;
   map {print "<TD valign=top align=left nowrap>".$_."</TD>" ; }  @columns;
   if ( $sequence_names{$index} ){
        my  @sequence_name = @{$sequence_names{$index}};
        print  "<TD valign=top align=left nowrap>";
        my $size = scalar @sequence_name ; 
        my $seq_per_line = 4; 
        for (my $index = 0; $index < $size ; $index += $seq_per_line  ){
             my $stop = ( $index + $seq_per_line  < $size ? $index + $seq_per_line  : $size);
             print join("&nbsp;&nbsp;", @sequence_name[$index..$stop-1] );
             print "<BR>";
        }
        print "</TD>";
   }
 
}

sub trim {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub output_text{
    my ($nodeSize,$sequence_namerefe,  @sorted_results)=@_; 
    my $result_message = "Only oligos occurring in $MIN_NUM_TIMES_DISTINCT_GENE_CONTAINS_OLIGO or more of sequences in the query set are reported, and are sorted by p-value. Columns are as follows (left to right):\noligoMer\nAbsolute number of this oligoMer in query set\nAbsolute number in genomic set\nNumber of sequences in query set containing oligoMer\nNumber of sequences (out of $NUM_BACKGROUND_SEQS in genomic set) containing oligoMer\np-value from binomial distribution \nQuery sequences containing this oligoMer";
    print "Content-type: text/plain\n\n"; 
  
    print "$result_message\n" ;
   
    map { printOneEntry( $_, $sequence_namerefe ); }  @sorted_results;

    print "\n";
    if ( isLociNames($input) ){
       print ( $nodeSize." sequences analyzed: " ); 
       foreach my $locus (@loci) {
          my $found = 1;
          foreach my $noseq (@$no_seq_found) {
             if ($locus eq $noseq){
                $found = 0; 
             }
          }
          if ( $found == 1 ){
              print "$locus  ";
          }  
      }
       
       print "\n" ;
       
       if ( @$no_seq_found ){
         print "The following sequences were not found: ";
         foreach my $noseq (@$no_seq_found) {
            print "$noseq \t";
	 } 
         print "\n" ;
      }
    }else {
        print ( $nodeSize." sequences analyzed.\n" ) ;
    }

}

# print the entry in plain  text
sub printOneEntry {
   my ( $pdlString, $sequenceref ) = @_;
   my %sequence_names = %$sequenceref;  
   my @columns =  split (/\t/, $pdlString );
   my $index = pop @columns ;
   
   map {print $_."\t" ; }  @columns;
   
   if ( $sequence_names{$index} ){
        my  @sequence_name = @{$sequence_names{$index}}; 
        map {print $_."  " ;} @sequence_name;
        print "\n"; 
       # print  join("\t", @sequence_name )
   }
}

# check the input is loci names or not
# simply check if any line of the input starts with >
sub isLociNames {
    my ($input) = @_;
    if (!input){ return 0; }
    my @lines = split (/\r\n/, $input);

    for my $line (@lines){
	if ($line =~ /^>/ ){
          return 0;
        }
    }  
    return 1;    
}


sub isNotValid{
    my ($input) = @_;
    if (!input){ return 1; }
    my @lines = split (/\r\n/, $input);

    for my $line (@lines){
	if ($line =~ /^[^>]/ && $line =~ /[^ATGC]/i ){
          return 1;
        }
    }  
    return 0;    
}

sub start_page{
    print $cgi->header;
    print $cgi->start_html( -title => 'Motif Analysis in promoter/upstream sequences');
    
    print "<script language='JavaScript' src='/js/navbar.js'></script>";
    print "<link rel='stylesheet' type='text/css' href='/css/main.css' >";
    print "<script language='JavaScript'>var highlight = 2; var helpfile='/help/index.jsp';</script></head>";
   
    print  "<body leftmargin=0 topmargin=0 marginwidth=0 marginheight=0 bgcolor=#F5F9FF>";

    print "<script language='JavaScript' SRC='/js/header'></script><p>";

    print "<center><table width=602 align=center border=0 cellspacing=0 cellpadding=2>";
    print "<tr><td>";           
    print " <span class='header'>Motif Analysis in Promoter/Upstream Sequences</span>";
}


sub complain_input{
    my ($input) = @_; 
    print ("<BR><BR><BR><font color=red>");
    if (!$input){
       print ("No input");
       print ("</font><BR>");
      
   }else{
       print ("Invalid input catched, please check( invalid bases have been highlighted): </font><BR><BR>"); 
       my @lines = split (/\r\n/, $input);
       my $line_count = 0;
       for my $line (@lines){
          $line_count++;
	  if ($line =~ /^[^>]/ && $line =~ /[^ATGC]/i ){
             print "<font color= red>line $line_count: </font>";
             my $index ;
             for ($index = 0; $index< length($line); $index++) {
		my $char = substr($line,$index, 1 );
                if ($char =~ /[^ATGC]/i ){
		   print "<font color= red>$char</font>";
	        }else {
                   print "<font color = black>$char</font>";
                }
            }
            print "<BR>";
        }
      } 
   }
   print ("<BR><BR>");
   print ("Please go back and enter sequence in the textfield or upload a file with those information");
   
}

sub results_blurb{
    print $cgi->p("Only oligos occurring in $MIN_NUM_TIMES_DISTINCT_GENE_CONTAINS_OLIGO or more of sequences in the query set are reported, and are sorted by p-value. Columns are as follows (left to right):"), p, pre("oligoMer\nAbsolute number of this oligoMer in query set\nAbsolute number in genomic set\nNumber of sequences in query set containing oligoMer\nNumber of sequences (out of $NUM_BACKGROUND_SEQS in genomic set) containing oligoMer\np-value from binomial distribution\nQuery sequences containing this oligoMer"), hr;
}

sub end_page{
    
    print"</TD></TR></TABLE></center>";

    print "<script language='javascript' src='/js/footer.js'></script>";

    print $cgi->end_html();
}


sub new_query_link{
  "</TABLE>",

  "<script language='javascript' src='/js/footer.js'></script>",
    print $cgi->p, a({-href => $cgi->url() }, "Go Back");
}


sub _dumpParam{

#for debug only;

    my @array = $cgi->param;
    for my $p ( @array  ){

	print $p, " ", $cgi->param($p), p ;
    }
}

sub get_num_background_seqs
{
	if( -e $UPSTREAM_500 )
	{
		return `grep ">" $UPSTREAM_500 | wc -l`;
	}
	elsif( -e $UPSTREAM_1000 )
	{
		return `grep ">" $UPSTREAM_1000 | wc -l`;
	}
	return;
}
