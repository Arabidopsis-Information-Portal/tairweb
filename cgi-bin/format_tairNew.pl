#!/bin/env perl 
#
# format_sc.pl  -  custom HTML routines for SGD
######################################################################

1;  ### Return a value to make perl happy

use CGI q(:cgi);
use LWP::UserAgent;
use Digest::MD5  'md5_hex';

sub PrintHeader {
  return "Content-type: text/html\n\n";
}

sub tair_header
{
    print get_html_header(@_);
}

sub get_html_header
{
  my ($page,@css) = @_;
  my $host = server_name();
  my $digest = md5_hex(join '', @_);
  my $cssparams = join( '', map {"&cssfile=$_"} @css );
  return get_cached_content("/tmp/static_html_header$digest.html", "http://$host/jsp/includes/dyn_header.jsp?&pageName=$page$cssparams");
}

sub get_cached_content
{
  local($cached_file,$url) = @_;
  my $age = 0.125; # 3 hours
  if(!-e "$cached_file" || -M $cached_file > $age){
    my $ua = new LWP::UserAgent;
    my $req = new HTTP::Request GET => $url;
    my $res = $ua->request($req);
    if ($res->is_success) {
      my $header = $res->content;
      open(FOUT, ">$cached_file");
      print FOUT $header;
      close(FOUT);
      return $header;
    }
  }

  if(-e "$cached_file"){
    local( $/, *FH ) ;
    open( FH, $cached_file ) or die "sudden flaming death\n";
    $text = <FH>;
    return $text;
  }

  return "";
}

sub tair_footer {
    print "</div>\n";
    print "<script type=\"text/javascript\">writeFooter();</script>\n"; 
    print "</div>\n";
    print "</body>\n";

    print "</html>\n";

}


### Small gif for header aligned left
sub header_gif_sm {
    my $output = "<a href=\"http://genome-www.stanford.edu/Saccharomyces/\"><img src=\"http://genome-www.stanford.edu/images/SGD-t.gif\" alt=\"SGD\" align=left hspace=25 border=0></a>";
    return $output;
}


### Help button aligned right (takes $helpfile argument)
sub help { 
    local($helpfile) = @_;
    my $output = "<a href=\"http://genome-www.stanford.edu/Saccharomyces/help/$helpfile\"><img src=\"http://genome-www.stanford.edu/images/help-button.gif\" alt=\"Help\" align=right border=0></a>\n";
    return $output;
}


### HTML page title <H1> centered (takes $title argument)
sub page_title {
    local($title) = @_;
    my $output = "<h1 align=center>$title</h1>\n";
    return $output;
}

### Resource buttons separated by vertical bars
sub buttons_bar {
    my $output ="<center>\n";
    $output .= "<a href=\"http://genome-www.stanford.edu/cgi-bin/SGD/search\">Search SGD</a> |\n";
    $output .= "<a href=\"http://genome-www2.stanford.edu/cgi-bin/SGD/seqTools\">Gene/Seq Resources</a> |\n";
    $output .= "<a href=\"http://genome-www.stanford.edu/Saccharomyces/help.html\">Help</a> |\n";
    $output .= "<a href=\"http://genome-www.stanford.edu/Saccharomyces/registry.html\">Gene Registry</a> | \n";
    $output .= "<a href=\"http://genome-www.stanford.edu/Saccharomyces/maps.html\">Maps</a><br>\n";
    $output .= "<a href=\"http://genome-www2.stanford.edu/cgi-bin/nph-blast2sgd\">BLAST</a> |\n";
    $output .= "<a href=\"http://genome-www2.stanford.edu/cgi-bin/nph-fastasgd\">FASTA</a> |\n";
    $output .= "<a href=\"http://genome-www2.stanford.edu/cgi-bin/SGD/PATMATCH/nph-patmatch\">PatMatch</a> |\n";
    $output .= "<a href=\"http://genome-www.stanford.edu/Sacch3D\">Sacch3D</a> |\n";
    $output .= "<a href=\"http://genome-www2.stanford.edu/cgi-bin/SGD/web-primer\">Primers</a> |\n";
    $output .= "<a href=\"http://genome-www.stanford.edu/Saccharomyces/\">SGD Home</a>\n";
    $output .= "</center>\n";
    return $output; 
}


### Resource buttons as table headings
sub buttons {
    my $output = "<center><table border=2 cellpadding=3><tr>\n";
    $output .= "<th><a href=\"http://genome-www.stanford.edu/cgi-bin/SGD/search\"><b>Search SGD</b></a></th>\n";
    $output .= "<th><a href=\"http://genome-www.stanford.edu/VL-yeast.html\"><b>Virtual Library</b></a></th>\n";
    $output .= "<th><a href=\"http://genome-www.stanford.edu/Saccharomyces/help/glossary.html\"><b>Glossary</b></a></th>\n";
    $output .= "<th><a href=\"http://genome-www.stanford.edu/Saccharomyces/aboutGR.html\"><b>Gene Registry</b></a></th>\n";
    $output .= "<th><a href=\"http://genome-www.stanford.edu/Saccharomyces/MAP/GENOMICVIEW/GenomicView.html\"><b>Genomic View</b></a></th></tr></table></center>\n";
    $output .= "<center><table border=2 cellpadding=3><tr>\n";
    $output .= "<th><a href=\"http://genome-www2.stanford.edu/cgi-bin/nph-blast2sgd\"><b>BLAST</b></a></th>\n";
    $output .= "<th><a href=\"http://genome-www2.stanford.edu/cgi-bin/nph-fastasgd\"><b>FASTA</b></a></th>\n";
    $output .= "<th><a href=\"http://genome-www.stanford.edu/Sacch3D\"><b>Sacch3D</b></a></th>\n";
    $output .= "<th><a href=\"http://genome-www2.stanford.edu/cgi-bin/web-primer\"><b>Primers</b></a></th>\n";
    $output .= "</tr></table></center>\n";
    return $output; 
}
 

### solid black line 95% width of page with beginning and trailing <p>
sub black_line {
    my $output = "<p><hr size=3 noshade width=95%><p>\n";
    return $output;    
}


### suggestion centered with trailing <p>
sub suggestion {
    my $output = "<center>Your comments and suggestions are appreciated: <a href=\"http://genome-www.stanford.edu/Saccharomyces/forms/suggestion.html\">Send a Message to SGD</a></center><p>\n";
    return $output;
}


### small line 75% width of page
sub divider75 {
    my $output = "<hr size=2 width=75%>\n";
    return $output;
}

### small line 50% width of page
sub divider50 {
    my $output = "<hr size=2 width=50%>\n";
    return $output;
}

### small line 35% width of page with beginning and trailing <p>
sub divider35 {
    my $output = "<p><hr width=35%><p>\n";
    return $output;
}

### small line 35% width of page
sub divider35np {
    my $output = "<hr width=35%>\n";
    return $output;
}


### small line 35% width of page with beginning and trailing <p>
sub divider {
    my $output = "<p><hr width=35%><p>\n";
    return $output;
}


### Small arrow gif for return to SGD footer 
sub footer_gif {
    my $output = "<a href=\"http://genome-www.stanford.edu/Saccharomyces/\"><img src=\"http://genome-www.stanford.edu/images/arrow.small.up.gif\" border=0>Return to Saccharomyces Genome Database</a>\n";
    return $output;
}

### Small arrow gif and email yeast curators gif in SGD footer
sub footer_email_gif {
my $output = "<hr><table border=0 width=100\%>\n" .
    "<tr><td align=left>\n" .
    "<a href=\"http://genome-www.stanford.edu/Saccharomyces/\">\n" .
    "<img src=\"http://genome-www.stanford.edu/images/arrow.small.up.gif\" border=0>Return to Saccharomyces Genome Database</a></td>\n" .
    "<td align=right><a href=\"http://genome-www.stanford.edu/Saccharomyces/forms/suggestion.html\">Send a Message to the SGD Curators <img src=\"http://genome-www.stanford.edu/images/mail.gif\" border=0></a></td></tr></table>\n";
    return $output;
}

### Excite "find" search field 
sub footer_find {
    my $output = "<p><FORM ACTION=\"http://genome-www.stanford.edu/cgi-bin/SGD/AT-yeastsearch.cgi\" METHOD=\"POST\"><center><TABLE><TR><TD><b>Search SGD WWW pages with <a href=\"http://www.excite.com/\">eXcite</a> :</b> <INPUT NAME=\"search\" size=20></TD><TD><INPUT TYPE=\"image\" SRC=\"http://genome-www.stanford.edu/Excite/pictures/AT-search_button.gif\" NAME=\"searchButton\" HEIGHT=20 WIDTH=75 ALT=\"Search\" BORDER=0></TD></TR></TABLE></center>\n";
    $output .= "<INPUT TYPE=\"hidden\" NAME=\"souce\" VALUE=\"local\">\n";
    $output .= "<INPUT TYPE=\"hidden\" NAME=\"backlink\" VALUE=\"http://genome-www.stanford.edu/Saccharomyces/\">\n";
    $output .= "<INPUT TYPE=\"hidden\" NAME=\"bltext\" VALUE=\"SGD WWW Home\">\n";
    $output .= "<INPUT TYPE=\"hidden\" NAME=\"sp\" VALUE=\"sp\">\n";
    $output .= "</FORM>\n";
    return $output;
}

### End table 
sub table_end {
    my $output = "</td></TR></TABLE>\n";
    return $output;
}

sub atdb_footer_links {
	print "<CENTER>";
    print "<TABLE ALIGN=\"CENTER\" BORDER=\"2\" CELLPADDING=\"6\"><TR><TD><font size=-1><a href=\"http://genome-www3.stanford.edu/atdb_welcome.html\"><center>Database Table of Contents</font></center>\n";
    print "<font size=-1><a href=\"/search.html\">Search</a> | <a href=\"/blast/\">BLAST</a> | <a href=\"/cgi-bin/fasta/TAIRfasta.pl\">FASTA</a> | <a href=\"/cgi-bin/patmatch/nph-patmatch.pl\">PatMatch</a> | <a href=\"/cgi-bin/patmatch/RestrictionMapper.pl\">Restriction Analysis</a></font></TD></TR></TABLE>\n";
    print "</CENTER>";
    print "<br><center><hr size=3 noshade width=95%></center><p>\n";
    print "<a href=\"/\"><img src=\"/images/arrow.small.up.gif\" border=0>Return to TAIR Home Page</a>\n";

}
    

########################################################################
# Use these functions if NOT using CGI.PM
########################################################################
### HTML header and title (takes $title argument)
### use only if NOT using CGI.pm
sub html_header {
    local($title) = @_;
    my $output = "Content-type: text/html\n\n";
    $output .= "<HTML><HEAD>\n";
    $output .= "<TITLE>$title</TITLE></HEAD>\n";
    return $output; 
}

### Background 
### use only if NOT using CGI.pm
sub background {
    my $output = "<BODY BGCOLOR=\"#FFFFF0\">\n";
    return $output;
} 

### HTML footer 
### use only if NOT using CGI.pm
sub html_footer {
    my $output = "</BODY></HTML>\n";
    return $output; 
}    



