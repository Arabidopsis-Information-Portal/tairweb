#!/bin/env perl
# cgi script that returns hits for microarray probes.
#
# based on lukas muller 's getgo.pl
#
# Iris Xu Aug 1st, 2002
#
# modified by Nick Moseyko 04/05/2004.

use strict;
use CGI;

require "../../format_tairNew.pl";
use lib "../../afgc";
use Data::Dumper;
use CloneIdFinder;
#use Set::Scalar;

my $data_dir = "$ENV{'DOCUMENT_ROOT'}/../data/microarray/";
my $cgi = CGI -> new ();
my $search_for_string = $cgi -> param("search_for");
my $output_type = $cgi -> param("output_type");
my $search_from = $cgi -> param("search_against");

#change these every time we update the mapping (usually right after a release)
my $MAPPING_DATE='07/29/2009';
my $TAIR_RELEASE_NUM=9;

# are we uploading a file?
my $uploadStr="";
my $fh = $cgi->upload("file");
if ($fh) {
    while (<$fh>) {
        $uploadStr .= $_;
    }
    $search_for_string = $uploadStr;
}

$search_for_string = uc($search_for_string);     # convert to uppercase
$search_for_string =~ s/[\;\,\r\n\t]/\t/g;       # convert all seperators to tabs
$search_for_string =~ tr/\t/\t/s;      # squash multiple tabs into one

my @search_for = split /\t/, $search_for_string;

# check for errors -- was anything entered at all?
#
if (!@search_for) { output_error("You did not enter any loci or genbank_accession information", "Please enter loci or genbank_accession in the textfield or upload a file with those information"); exit(); }
# preprocess file, read file into hash or array

my @exp_file;

my @results;

my %has_hit_flag;
my $flag_ref =  \%has_hit_flag;

$search_from = lc($search_from);     # convert to lower case

my %searchFromToFile = ('afgc'=> "afgc",
			'affy8k' => "affy_AG",   #_array_elements-2006-04-05.txt",
			'affy25k' =>"affy_ATH1", #_array_elements-2006-04-05.txt",
			'catma' => "catma",  #_array_elements-2006-4-11.txt",
			'agilent' => "agilent"  #_array_elements-2006-4-11.txt",
			);

## afgc has some special logic, so we leave that here:

my $file_name = read_file_list($searchFromToFile{$search_from});


if ($search_from eq 'afgc'){
    my %afgc_file = read_afgc_file_into_hash($file_name);    #"afgc_array_elements-2006-4-18.txt");
    @exp_file = read_exp_file_into_array("${data_dir}not_found-2003-08-22.txt");
    @results = get_hits($search_for_string, $flag_ref, %afgc_file );
} elsif(-e $file_name) { # $searchFromToFile{$search_from}) {
    my %affy_file = read_affy_or_catma_file_into_hash($file_name);     #$searchFromToFile{$search_from});
    @results = get_hits($search_for_string, $flag_ref, %affy_file );
}

# check if there are more than 1000 entries in the hash -- we revert to text output in any case.
#
if ( scalar(@results) >1000 ) { $output_type = "text"; }

if ( $output_type eq "text" ) { 
   output_text( ); 
} else {
   output_html( );
}

# get a list of hash key sorted by SUID

sub sort_hash{
    my %hash = @_;
    my @sorted = sort{ $hash{$b}{SUID} <=> $hash{$a}{SUID} } keys %hash;
    return @sorted;
}

sub output_html {
    print "Content-type: text/html\n\n";
    tair_header("Microarray Elements");
    print "<TABLE border=0 width=725>\n";
    print "<TR><TD><center><span class=mainheader>Microarray Elements Search Results</span> ".
    "[<A href=\"/help/helppages/microarray_readme.jsp#mic3\" target=\"_blank\">Help</A>]</center><br /><br />\n";
    print "<TABLE border=1 width=725>\n";
    # print table header
    my $headerString = makeResultHeader( );
    print $headerString;

    # print search result
    foreach my $hitref (@results){
        printOneEntry( $hitref);
    }
    print "</TABLE>\n";
    print "<br /><TR><TD><center>Genome Mapping Date: $MAPPING_DATE, TAIR$TAIR_RELEASE_NUM release</center><br />";
    print "<BR />";
    # print a little summary

    if( scalar(@search_for) > scalar (keys %has_hit_flag)){
        print "<TR><TD align=\"center\"><B>Your query for the following terms resulted in no hits:&nbsp; ";
        my @non_found;
        foreach my $key(@search_for){
            if ($has_hit_flag{$key} eq "yes"){}
            else{
               push @non_found, $key ;
            }
        }
        print join ("; &nbsp;    " , @non_found);
        print "</B></TD></TR>";
    }
    print "</TABLE>\n";
    tair_footer();

}

sub  makeResultHeader{
    my $headerRow = "<TR><TD align=\"center\">Array Element</TD>"; 
	
    if ($search_from eq 'afgc') {
       $headerRow .= "<TD align=\"center\">GenBank Accession</TD>"; 
    }

    $headerRow .= "<TD align=\"center\">Locus Identifier</TD><TD align=\"center\">Annotation</TD>".
          	       "<TD align=\"center\">Organism</TD><TD align=\"center\">Probe Type</TD><TD align=\"center\">Is Control</TD>";
    if ($search_from eq 'afgc') {
	 $headerRow .= "<TD align=\"center\">Expression Viewer</TD><TD align=\"center\">Spot History</TD>".
          		       "<TD align=\"center\">Avg Log Ratio</TD><TD align=\"center\">Avg Log Std Err</TD>".
	  		       "<TD align=\"center\">Avg Intensity</TD><TD align=\"center\">Avg Intensity Std Err</TD>";
    }
    return  $headerRow; 
}

# print one search result entry as one table row
sub printOneEntry{
    my ($hitref) = @_;   
    print "<TR>";
    my %entry = %$hitref;
    if ($entry{probe_name}){
       print "<TD align=\"center\">$entry{probe_name}</TD>";
    }
    if ($entry{clone_id}){
       print "<TD align=\"center\">$entry{clone_id}</TD>";
    }

    if ($search_from eq 'afgc') {
       if( $entry{genbank_accession} ){
            my @gb = split(/;/, $entry{genbank_accession});
            my @gb_url = map "<A HREF=http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?save=0&cmd=search&val=".$_." target=\"_blank\">".$_."</A>",@gb ;
            my $genbankString = join ("<BR />", @gb_url);
            printCell(  $genbankString ); 
       }else {
            printCell (""); 
       }
    }

    if ( $entry{locus} ){
       	my @la = split(/;/, $entry{locus});
        my @loci_url = map "<A href=/servlets/TairObject?type=locus&amp;name=".$_." target=\"_blank\">".$_."</A>", @la;
        my $lociString =( join "<BR />", @loci_url);
        printCell(  $lociString );
    }else{
        printCell( "");
    }

    my %alignment = ("align"=>"left");
    printCell( $entry{annotation} , %alignment );  
    printCell( $entry{organism} );
    printCell( $entry{probe_type} ); 
    printCell( $entry{is_control} );
    if ($search_from eq 'afgc') {
        if ($entry{probe_name}){
            print "<TD align=\"center\">&nbsp;</TD>";
        }
        if ($entry{clone_id}){
           if ( isCloneIdInNotFoundList( $entry{clone_id} )){
               printCell( $entry{clone_id} ); 
           } else {
               my $clone_url = "<A HREF=/cgi-bin/afgc/atExpressioncgi.pl?clone_id=".$entry{clone_id}." target=\"_blank\">".$entry{clone_id}."</A>";
               printCell( $clone_url );    
          }
        }
        if ($entry{SUID}){
           print "<TD align=\"center\"><A HREF=http://genome-www5.stanford.edu/cgi-bin/data/spotHistory.pl?state=parameters;login=no;suid=$entry{SUID} target=\"_blank\">$entry{SUID}</A></TD>";
        }else {
            print "<TD align=\"center\">&nbsp;</TD>";
        }
        printCell( $entry{ave_log} );
        printCell( $entry{ave_se} );
        printCell( $entry{ave_int} );
        printCell( $entry{ave_int_se} );
     }
     print "</TR>";
}

sub printCell{
    my ($cell, %alignment ) = @_;
    my $align ="center" ;
    if ( exists $alignment{"align"} ) { $align =$alignment{"align"}; }
    if ($cell){ print "<TD align=\"$align\">$cell</TD>"; } 
    else{ print "<TD align=\"center\">&nbsp;</TD>"; }  
}

# is the clone_id in not-found file list, this is used to determine if we link out the expression viewer for a given clone_id
sub isCloneIdInNotFoundList{
    my ($clone_id) =@_;
    my $found = 0; 
    foreach my $item(@exp_file){
       if ($clone_id eq $item){
           $found = 1;
           last;
       }
    }
    return $found;
}

sub output_text {
    print "Content-type: text/plain\n\n";
   ### print "Content-type: application/octet-stream\n\n";
    # print header
    print "Array Element\t"; 
    if ($search_from eq 'afgc') {
        print "GeneBank Accession\t";
    }
    print "Locus Identifier\tAnnotation\tOrganism\tProbe Type\tIs Control\t";
    if ($search_from eq 'afgc') {
       print "SUID\tAvg Log Ratio\tAvg Log Std Err\tAvg Intensity\tAvg Intensity Std Err\tSource";
    }
    print "\n";

    # print search result
  #  while (defined(my $hitref = $found_set->each)){ 
     foreach my $hitref (@results){
        my %entry = %$hitref;
        if ($entry{probe_name}){
            print "$entry{probe_name}\t";
        }
        if ($entry{clone_id}){
            print "$entry{clone_id}\t";
        }
  
        if ($search_from eq 'afgc') {
           if ($entry{genbank_accession} ){
              print "$entry{genbank_accession}\t";
           }
        }

        print "$entry{locus}"."\t".
              "$entry{annotation}"."\t".
              "$entry{organism}"."\t".
              "$entry{probe_type}"."\t".
              "$entry{is_control}"."\t";

        if ($search_from eq 'afgc') {
            print  "$entry{SUID}"."\t".
                   "$entry{ave_log}"."\t".
                   "$entry{ave_se}"."\t".
	      	   "$entry{ave_int}"."\t".
                   "$entry{ave_int_se}";
        }
        print "\n";
    }
 
    # list of not found items
    if( scalar(@search_for) > scalar (keys %has_hit_flag)){
        print "The query for the following terms resulted in no hits: ";
    }
    foreach my $key(@search_for){
        if ($has_hit_flag{$key} eq "yes"){}
        else{
            print "$key  ";
        }
    }
    print "\n";
}

sub output_error {
    my $title = shift;
    my $message = shift;
    print "Content-type: text/html\n\n";
    tair_header("Microarray Element Search Error");
    print "<TABLE border=0 width=602>\n";
    print "<TR><TD><span class=header>Error: $title</span><br /><br />\n";
    print "$message<BR /><BR /><BR /><BR />\n";
    print "<a href=\"/tools/bulk/microarray/\">Microarray Probes Search Page</a><BR /><BR /><BR />";
    print "</TABLE>\n";
    tair_footer();
}

#search the file-hash for the input loci 
sub get_hits{
    my ( $search_for_string, $flags, %source)=@_; 
    my @search_for = split /\t/, $search_for_string; 
    my @hits;
    foreach my $search_for (@search_for){
       my $search_for_this  = trim( $search_for );
       if (exists($source{uc $search_for_this})){
            $flag_ref->{$search_for_this}= "yes";
            my @found_entry = @{$source{$search_for_this}};
            push @hits, @found_entry;
       }
    }
    my @uniq_hits = uniq(@hits);
    return @uniq_hits;
}


## A more robust version of dumper.  Possibly slower.
sub uniq {
    my @values = @_;
    my %h;
    for my $v (@values) {
	$h{Dumper($v)} = $v;
    }
    return values %h;
}

sub trim {
    my $string = shift;
    for ($string) {
        s/^\s+//;
        s/\s+$//;
    }
    return $string;
}


sub read_affy_or_catma_file_into_hash{
    my ($file)=@_;
    my %hash;
    open (F, "<$file") || die "Can't find file $file";
    my @columns = qw (
                 probe_name
		 probe_type
                 organism
                 is_control
                 locus
		 annotation
                 is_ambiguous
                     );
    while (my $line = <F>) {
        chomp $line;
        my %entry;
        @entry{@columns} = split(/\t/, $line);
        $entry{annotation} =~ s/[\n\r]//g;
        # might be multiple loci delimited by ;
        my @loci = split(/\;/, $entry{locus});
        push (@{$hash{uc $entry{probe_name}}}, \%entry);
        foreach my $this_locus(@loci){
    #       push (@{$hash{uc $entry{locus}}} , \%entry);
           push (@{$hash{uc $this_locus}} , \%entry);
        }
    }
    return %hash;
}

sub read_afgc_file_into_hash{
    my ($file)=@_;
    my %hash;
    open (F, "<$file") || die "Can't find file $file";
    my @columns = qw (SUID
                     clone_id
                     genbank_accession
                     probe_type
                     organism
                     is_control
                     locus
                     annotation
		     is_ambiguous
		     start
                     end 
		     ave_int
                     ave_int_se
                     ave_log
                     ave_se
                     );
    while (my $line =<F>) {
        chomp $line;
        my %entry;
        @entry{@columns} = split(/\t/, $line);
        $entry{annotation} =~ s/[\n\t\r]//g;
        push (@{$hash{uc $entry{clone_id}}}, \%entry);
        push (@{$hash{uc $entry{genbank_accession}}},\%entry);
        # might be multiple loci delimited by ;
        my @loci = split(/\;/, $entry{locus}); 
        foreach my $this_locus(@loci){
           push (@{$hash{uc $this_locus}} , \%entry);
        }
    }
    return %hash;
}

sub read_exp_file_into_array{
    my ($file)=@_;
    my @array = ();
    open (F, "<$file") || die "Can't find file $file";
    while (<F>) {
        chomp;
        push(@array, $_);
    }
    return @array;
}

sub read_file_list
{
	my $prefix = shift;

	my @files = glob("${data_dir}${prefix}_array_elements*");
	chomp(@files);
	return $files[0] if $files[0];
	print "could not find file with prefix $prefix\n";
}

