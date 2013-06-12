#!/bin/env perl

# cgi script that handles sequence bulk downloads using the BLAST datasets.
#
#
# Lukas Mueller, February 15, 2002
#
use strict;

use LociSeqFetch;

use CGI;
use Bio::Seq;
use Bio::SeqIO;
use Bio::Index::Fasta;

require "../../format_tairNew.pl";

# directory where indexed fasta files are located
my $datadir = "$ENV{DOCUMENT_ROOT}/../data/sequences/";
my $indexfiledir = "$ENV{DOCUMENT_ROOT}/../data/sequences/";
my $locusfile = "$ENV{DOCUMENT_ROOT}/../data/genes/Locus_GeneModelDescriptions.txt";
my $genefile = "$ENV{DOCUMENT_ROOT}/../data/genes/Gene_GeneModelDescriptions.txt";

# datasets that contain multiple alternate spliced forms distinguished by .1, .2 etc.
my @alternate_spliced_datasets = (
				                  "At_transcripts",
                                  "ATH1_cds",
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
my $outputformat = $cgi -> param("outputformat");
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
my @old_loci = split /\t/, $lociStr;

if ($dataset =~ m/At_upstream/ || $dataset =~ m/At_downstream/ || $dataset =~ m/At_intergenic/ ){
    @loci = get_loci_list( "locus", $genefile, \@loci );
} elsif ($search_against eq "rep_gene" && $dataset ne "At_intron") {
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

output_text();

sub output_html {
}

sub output_text {

  print "Content-type: text/plain\n\n";
  my $print_desc = -1;
  if ($dataset !~ m/At_upstream/ && $dataset !~ m/At_downstream/ && $dataset !~ m/At_intergenic/) {
    foreach my $seqid ( @old_loci) { 
        my $this_print_desc = -1;
        if ( $seqid =~ /[aA][tT]\d[gG]\d{5}\.\d/ && $print_desc != 1){
            foreach my $newid ( @loci) {
                if ($newid eq $seqid){
                    $this_print_desc = 0;
                }
            }
        }
        if ($this_print_desc == -1){
            $print_desc = 1;
        }
    }
  }
  
  if ($search_against eq "rep_gene" && $print_desc == 1) {
    print "Note that the below sequence corresponds to the representative gene model and not the queried gene model.\n";
    print "To obtain the queried gene model sequence, please select 'Get sequences for only the gene model/splice form matching my query' on query page\n\n";
  }
  my %args = ('index_file' => $indexfile);

  eval {

    my $fetcher = LociSeqFetch->new(%args);
    my ($sequence, $no_seq_found);
    if ($dataset eq 'At_intron'){
        ($sequence, $no_seq_found) = $fetcher->fetch_loci_sequences_by_array(\@loci, $is_alternate_spliced_dataset, $outputformat, $dataset );
    }else{
        ($sequence, $no_seq_found) = $fetcher->fetch_loci_sequences_by_array(\@loci, $is_alternate_spliced_dataset, $outputformat, "direct_search" );
    }
      
    print "$sequence\n";

    if (@$no_seq_found) {
      print "\n------------------\nThe following sequences were not found:\n";
      foreach my $noseq (@$no_seq_found) {
        print "$noseq\n";
      }
    }

  };

  if ($@){
    output_error("Error",$@);
    
  }



    
}

sub output_error {
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
    ##
    # loop through gene file and return a list of all rep gene models that
    # match either the locus or gene model searched
    ##
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
    ##
    # lopp through gene file and return a lost of loci that
    # match either that loci or gene model searched
    ##
    } if ($type eq "locus") {
        my %locus_hash;
        my %gene_hash;
        while (my $line = <F>) {
            chomp $line;
            my @lines = split(/\t/, $line);
            $locus_hash{$lines[0]} = $lines[0];
            $gene_hash{$lines[2]} = $lines[0];
        }
        foreach my $locus(@loci) {
            if (exists $locus_hash{$locus} ) { 
                $return_loci_hash{$locus_hash{$locus}} = 1;
            }
            if (exists $gene_hash{$locus} ) { 
                $return_loci_hash{$gene_hash{$locus}} = 1;
            }
        }
    }elsif ( $type eq "both") {
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
                                                                                
