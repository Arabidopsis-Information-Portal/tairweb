#!/bin/env perl

# cgi script that sends sequences to EBI's ClustalW website
# this script is a modified version of getseq.pl
#
# December 19, 2003
#
use strict;

use LociSeqFetch;

use CGI;

use Bio::Seq;
use Bio::SeqIO;
use Bio::Index::Fasta;

use HTTP::Request::Common;
use LWP::UserAgent;

require "../../format_tairNew.pl";


my $EBI_URL = "http://" . $ENV{'SERVER_NAME'} . ":" .  $ENV{'SERVER_PORT'} . "/servlets/processor?type=clustalw";

# directory where indexed fasta files are located
my $datadir = "$ENV{DOCUMENT_ROOT}/../data/sequences/";
my $indexfiledir = "$ENV{DOCUMENT_ROOT}/../data/sequences/";
my $genefile = "$ENV{DOCUMENT_ROOT}/../data/genes/Gene_GeneModelDescriptions.txt";

# datasets that contain multiple alternate spliced forms distinguished by .1, .2 etc.
my @alternate_spliced_datasets = (
    #"At.transcripts.formatted",
    "At_transcripts",
    #"ATH1.cds.formatted",
    "ATH1_cds",
    #"ATH1.pep.formatted",
    #"ATH1.seq.formatted",
    "ATH1_pep",
    "ATH1_seq",
    "ATH1_3_UTR",
    "ATH1_5_UTR"
);

# version info
my $version = "1.1-20020815";

# get cgi parameters
#
my $cgi;
if (@ARGV) {
    $cgi = CGI -> new ($ARGV[0]);
}
else {
    $cgi = CGI -> new();
}
my $lociStr = $cgi -> param("loci");
my $dataset = $cgi -> param("dataset");
# my $outputformat = $cgi -> param("outputformat");
my $outputformat = "fasta"; # only format supported is FASTA
my $search_against = $cgi-> param("search_against");

# are we uploading a file?
#
my $uploadStr="";
my $fh = $cgi->upload("file");
if ($fh) {
    while (<$fh>) {
	$uploadStr .= $_;
    }
    $lociStr = $uploadStr;
}    

$lociStr = uc($lociStr);     # convert to uppercase
$lociStr =~ s/\n/\t/g;       # convert newlines to tabs
$lociStr =~ s/\r/\t/g;       # convert carriage returns to tabs
$lociStr =~ s/[, ;:]/\t/g;   # convert separators to tabs - be careful not to convert dots
                             # (can be part of id for multiple alternetaly spliced variants)
$lociStr =~ tr/\t/\t/s;      # squash multiple tabs into one

my @loci = split /\t/, $lociStr;
if ($search_against eq "rep_gene" && $dataset ne "At_intron") {
    @loci = get_loci_list( "rep_gene", $genefile, \@loci);
} elsif ($search_against eq "both" && $dataset ne "At_intron") {
    @loci = get_loci_list( "both", $genefile, \@loci);
}

if (!@loci) { 
  output_error("You did not enter any loci information", "Please enter loci accessions (e.g. At1g01030) in the textfield or upload a file with locus information. Thanks!"); 
}

if (scalar(@loci) > 2000) {
  output_error("The search is limited to 2000 entries.", "Please enter fewer than 2000 identifiers in the text box or file to upload. Thanks!"); 
}

my $is_alternate_spliced_dataset = 0;

#if (grep {/$dataset/} @alternate_spliced_datasets){
#   $is_alternate_spliced_dataset = 1;
#}

my $datasetpath = $datadir.$dataset;
my $indexfile   = $indexfiledir.$dataset;

send_seqs_to_clustalw();

sub send_seqs_to_clustalw()
{
  my %args = ('index_file' => $indexfile);

  eval {

    my $fetcher = LociSeqFetch->new(%args);
    my ($sequence, $no_seq_found);
    if ($dataset eq 'At_intron'){
        ($sequence, $no_seq_found) = $fetcher->fetch_loci_sequences_by_array(\@loci, $is_alternate_spliced_dataset, $outputformat, $dataset );
    }else{
        ($sequence, $no_seq_found) = $fetcher->fetch_loci_sequences_by_array(\@loci, $is_alternate_spliced_dataset, $outputformat, "direct_search" );
    }

    if (@$no_seq_found) {
      print "Content-type: text/html\n\n";
      print "<html>\n<head><title>Sequences Not Found</title></head>\n";
      print "<body>\n";
      print "<br>------------------<br>\n";
      print "File not sent to EBI ClustalW because the following ";
      print "sequences were not found:<br>\n";
      foreach my $noseq (@$no_seq_found) {
        print "$noseq<br>\n";
      }
      print "</body></html>";
    }
    else
    {
	print "Content-type: text/html\n\n";
	# print "<html>\n<head>\n";	
	# my $url = "/tools/bulk/sequences/EBI_clustalw.jsp";
	# print "<META HTTP-EQUIV=Refresh CONTENT=\"0; URL=$url?";
	#print cgiEscape("sequences", $sequence);
	#print "\"\n";
	# print "</head>\n<body>\n</body>\n</html>\n";
	
	# my $temp = "abcdefg";
	# use Data::Dumper;
	# print Dumper {%ENV};
	my $ua = LWP::UserAgent->new();
	my $req = POST "$EBI_URL", [ sequences => $sequence ];
	my $content = $ua->request($req)->content;
	print $content;
    }

  };

  if ($@){
    output_error("Error",$@);
    
  }
}


sub cgiEscape {
    my ($key, $value) = @_;
    my $cgi = CGI->new('');
    $cgi->param($key, $value);
    return $cgi->query_string();
}


sub output_error 
{
    my $title = shift;
    my $message = shift;
    print "Content-type: text/html\n\n";

    tair_header("TAIR: Search Error");

    print "<TABLE border=0 width=602>\n";
    print "<TR><TD><span class=header>Error: $title</span><br><br>\n";
    print "$message<BR><BR><BR><BR>\n";
    print "DEBUG INFO: $lociStr<BR><BR> $dataset<BR><BR>\n";
    print "</TABLE>\n";

    tair_footer();

    exit;
}

sub get_loci_list {
    my ($type, $file, $loci_list) = @_;
    my @loci = @{ $loci_list };
    my %return_loci_hash;
    my @return_loci;
    
    open (F, "<$file") || die "Cant find file $file";
    if ($type eq "rep_gene") {
        my %locus_hash;
        my %gene_hash;
        while (my $line = <F>) {
            chomp $line;
            my @lines = split(/\t/, $line);
            $locus_hash{$lines[0]} = $lines[1];
            $gene_hash{$lines[2]} = $lines[1];
        }
        foreach my $locus (@loci) {
            if (exists $locus_hash{$locus} ) {
                $return_loci_hash{$locus_hash{$locus}} = 1;
            }
            if (exists $gene_hash{$locus} ) {
                $return_loci_hash{$gene_hash{$locus}} = 1;
            }
        }
    } elsif ( $type eq "both") {
        my %locus_hash;
        my %gene_hash;
        while (my $line = <F>) {
            #
            # genes_hash maps genes to corresponding locus
            # locus_hash maps loci to a list of all genes separated by ":"
            #
            chomp $line;
            my @lines = split(/\t/, $line);
            $gene_hash{$lines[2]} = $lines[0];
            if ( exists $locus_hash{$lines[0]} ) {
                $locus_hash{$lines[0]} = $locus_hash{$lines[0]} . ":" . $lines[2];
            } else { 
                $locus_hash{$lines[0]} = $lines[2];
            }
        }
        my $unparsed_string = "";
        foreach my $locus(@loci) {
            if ( exists $gene_hash{$locus} ) {
                my $locus_found = $gene_hash{$locus};
                $unparsed_string = $unparsed_string . ":" . $locus_hash{$locus_found};
            }elsif (exists $locus_hash{$locus} ) {
                $unparsed_string = $unparsed_string . ":" . $locus_hash{$locus};
            }
        }
        my @unparsed_loci = split(/:/, $unparsed_string);
        foreach my $locus(@unparsed_loci) {
            $return_loci_hash{$locus} = 1;
        }
    }
    close(FILE);
    
    # get unique only results of @return_loci
    foreach my $key( sort keys %return_loci_hash ) {
        if ($key ne ""){
            push (@return_loci, $key);
        }
    }
    return @return_loci;
}

