#!/bin/env perl

# cgi script that returns GO annotations for locus accessions.
# Lukas Mueller, February 14, 2002
# Modifiled by Iris Xu, since this script treat at1g18710.1 as two seperate loci, 
#                       while we want to treat it as at1g18710 Jan. 20, 2004
# Modified by Thomas Yan, go slim terms are now displayed Jan 26, 2004
# Iris 07-01-2004, go_slim and annotations are in ont file now, the script will read 
# this one file instead on two
use strict;
use CGI;
require "../../format_tairNew.pl";

my $slim_ann_file = "$ENV{DOCUMENT_ROOT}/../data/TAIR_GO";

# version info
my $version = "20040702";

# hashes to store infos
# key is locus is, value is an array of hases (key is gene, go_id...)

my %loci_hash;

# get cgi parameters
#
my $cgi = CGI -> new ();
my $lociStr = $cgi -> param("loci");

my $output_type = $cgi -> param("output_type");

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

my $sessID = $cgi->cookie('getgoid') || "$ENV{UNIQUE_ID}";
#my $cookie = $cgi->header(-cookie=>$cgi->cookie(-name=>'getgoid',-value=>"$sessID"));
my $tmp_params = "$ENV{DOCUMENT_ROOT}/../tmp/getgo/$sessID";
if($lociStr){
	print "Set-Cookie: getgoid=$sessID; path=/\n";
	open TMP_PARAMS, ">$tmp_params";
	print TMP_PARAMS "$output_type\n$lociStr";
	close TMP_PARAMS
}
elsif($sessID){
	open (TMP_PARAMS, "<$tmp_params");
	$output_type = <TMP_PARAMS>;
	$lociStr = join '', <TMP_PARAMS>;
	chomp $output_type;
}

print STDERR "sess:$sessID:\n";
print STDERR "type:$output_type:\n";
print STDERR "loci:$lociStr:\n";

$lociStr = uc($lociStr);     # convert to uppercase

my @loci = grep {$_} split /\W+/, $lociStr; # this will treat at1g18710.1 as two loci

# we  want to weep out .1 .2 appends to loci names
@loci = grep (!/^\d/, @loci );

# check for errors -- was anything entered at all?
#
if (!@loci) { output_error("You did not enter any loci information", "Please enter loci accessions (e.g. At1g01030) in the textfield or upload a file with locus information"); exit(); }

# check if there are more than 1000 loci -- we revert to text output in any case.
#
if (scalar(@loci)>1000) { $output_type = "text"; } 

build_slim_annotation_hash ();

if ($output_type eq "text") { output_text(); }
else {  output_html(); }

sub build_slim_annotation_hash {

    open (F, "<$slim_ann_file") || die "Can't find file $slim_ann_file.";
    while (<F>) {
	chomp;
	my ($pub_locus, $other_infor) = split (/\t/, $_, 2);
        push @{$loci_hash{$pub_locus}}, $other_infor ;
    }
    close(F);
}

sub output_html {
    print "Content-type: text/html\n\n";
    
    tair_header("GO Annotation");
    
#   print "<center>\n";
    

    print "<span class=mainheader>GO Annotations</span>\n";

    
    print "<TABLE border='1' width='100%' bgcolor='#ffffff'>\n";
    print "<TR><TD>Locus</TD><TD>Gene Model(s)</TD><TD>GO term <br /><font size=1>(links to Tair Keyword Browser)</font><br />(GO ID)</TD><TD>cat</TD><TD>code</TD><TD>GO Slim</TD><TD>Reference</TD><TD>Made by:<br />date last modified</TD></TR>\n";
    my $locus;
    foreach $locus (@loci) {
        my $locuslink;
        if ( !exists ($loci_hash{$locus}) ){
             print "<TR><TD>$locus</TD><TD colspan=8>&nbsp;</TD></TR>";
        } else { 
	    my @infor = @{$loci_hash{$locus}};
	    my @processed_infor =  mergeGoSlim( @infor );
	    if ($locus =~ /AT\dG[\d]{5}/i) {
		$locuslink = "<a href=\"/servlets/TairObject?type=locus&name=$locus\" target=\"_blank\">$locus</a>";
	    }
        
	    for (my $i=0; $i < scalar(@processed_infor); $i++) {
                my( $tair_id, $genemodel,$goterm, $goid, $term_id, $cat,$slim, $evicode, $ref,$by, $date) = split (/\t/, $processed_infor[$i]);
                
		print "<TR><TD ";

            	if ( !$locuslink && $genemodel) {
		    $locuslink = "<a href=\"/servlets/TairObject?accession=$genemodel\" target=\"_blank\">$locus</a>";
                }
	        my $cleanedAccessionParam = cleanAccession( $ref );
                my $analysisreflink = "<a href=\"/servlets/TairObject?accession=$cleanedAccessionParam\" target=\"_blank\">$ref</A>";
		        my $evidencelink = "<a href=/portals/genAnnotation/functional_annotation/go.jsp#$evicode target=\"_blank\">$evicode</A>";
		#	my $gobrowserlink = "<a href=http://godatabase.org/cgi-bin/go.cgi?query=$goid&view=details&search_constraint=terms&depth=0 target=\"_other\">$goterm</a>";
               	my $browserlink = "/servlets/Search?action=new_tree&type=tree&tree_type=keyword&node_id=".$term_id;
                my $institutionlink;
		if ($by eq "TAIR") {
		    $institutionlink = "<a href=\"/index.jsp\" target=_blank>TAIR</a>";
		} elsif ($by eq "TIGR") {
		    $institutionlink = "<a href=http://www.tigr.org target=_blank>TIGR</a>";
		} else {
		    $institutionlink ="NA";
		}
		if ( $i == 0) {
		    print "rowspan=".scalar(@processed_infor)." valign=top>$locuslink</TD><TD>";
		} else {
		    print ">";
		}
                print "$genemodel</TD><TD><A href=$browserlink target=_blank>$goterm</A><br />( $goid ) </TD><TD>$cat</TD><TD>$evidencelink</TD><TD>$slim</TD><TD>$analysisreflink</TD><TD>$institutionlink<br />$date";
		print "</TD></TR>\n";
	    }
	}
    }

    print "</TABLE>\n";
    print "v. $version\n";    
    tair_footer();

}

sub output_text {
    print "Content-type: text/plain\n\n";
    print "Locus\tGene Model(s)\tGO term (GO ID)\tcat\tcode\tGO Slim\tReference\tMade by: date last modified\n";

    my $locus;
    foreach $locus (@loci) {
	if (! exists  $loci_hash{$locus} ) {
	    print "$locus\t\t\t\t\t\t\t\t\n" ;
	} else {
	    my @infor =  @{$loci_hash{$locus}};
	    my @processed_infor =  mergeGoSlim( @infor );
	    if (  @processed_infor  ) {
		for (my $i=0; $i < scalar(@processed_infor ); $i++) {
		    print $locus."\t".$processed_infor[$i]."\n";
		}
	    }
	}
    } # for 
    
}

sub format_goslim_text {
    my $html_terms = shift;
    my @terms = split(/<br>/, $html_terms);
    my $text_terms = "";
    foreach (@terms) {
	$text_terms .= "$_";
    }
    return $text_terms;
}

sub make_short_aspect {
    my $aspect = shift;
    if ($aspect eq "unknown") {
	return "unknown";
    } else {
	my $short_aspect = substr($aspect, 0, 4);
	return $short_aspect;
    }
}


sub output_error {
    my $title = shift;
    my $message = shift;
    print "Content-type: text/html\n\n";

    tair_header("TAIR: GO Search Error");

    print "<center>\n";

    print "<TABLE border=0 width=602>\n";
    print "<TR><TD><span class=header>Error: $title</span><br><br>\n";
    print "$message<BR><BR><BR><BR>\n";
    print "<a href=\"/tools/bulk/go/\">GO Search Page</a><BR><BR><BR>";
    print "</TABLE>\n";

    tair_footer();

}

#
# references are listed in data file as:
#
# TAIR:[accession number]|PMID:1234
#
# trim off leading TAIR and trailing PMID to
# leave just the valid TAIR accession # for
# passing as param in hyperlinks to reference
# pages
sub cleanAccession() {
  my $accessionStr = shift;

  $accessionStr =~ s/TAIR://;
  $accessionStr =~ s/\|PMID:\d+//;

  return $accessionStr;
}

# merge the goslim into a pipe format if all the other informations are same

sub  mergeGoSlim{
   my (@infor) =  @_; 
   my %temp_hash ;
   for (my $i=0; $i < scalar(@infor); $i++) {
      my( $tair_id, $genemodel,$goterm, $goid, $term_id, $cat,$slim, $evicode, $ref,$by,$date) = split (/\t/, $infor[$i]);
      my $key = join ( "\t", $tair_id, $genemodel,$goterm, $goid, $term_id,$cat, $evicode, $ref, $by,$date);
      my $value ;
      if (exists ($temp_hash{$key})) {
	    $value = $temp_hash{$key};  
	    $value .= " | $slim" ;
      }else{
	    $value = $slim ;
      }
      $temp_hash{$key} = $value;
   }
   my @return_array ;
   while ( my ($key, $value) = each(%temp_hash) ) {
       my( $tair_id, $genemodel,$goterm, $goid, $term_id,$cat,$evicode, $ref,$by,$date) = split (/\t/, $key);
       push   @return_array , join ( "\t", $tair_id, $genemodel,$goterm, $goid, $term_id, $cat, $value, $evicode, $ref, $by,$date);
   } 
   return @return_array ;
 }


