#!/bin/env perl
#
# genehunter - passed a gene name from geneform program
#              search SGD locus class
#              search PubMed database at NCBI
#              search GenBank at NCBI
#              search Swiss-Prot in Geneva 
#              display results
#
# written 12/96 by Gail Juvik
# updated 1/97 - added SwissProt, Sacch3D, MIPS, YPD searches
#              - default = all
#         9/97 - add PIR and ATCC queries
#         2/98 - change ATCC query to use clone database
#
# changed 12/98 by Yuhua Liu (hacks)
#              - change search_meinke to remove wrong message
#              - change search_swissport to point to right server
# 
# change 10/99 by Wen (porting changes to new TAIR server
# change 02/01 by Bryan Murtha (bug fixin)
# change 07/01 by Bryan Murtha 
#             - changed TAIR search from name_search.pl to gene_search.pl
#               commented out Mendel, can't search multiple classes easily
#               
# changed 2002-11-01 by Lukas Mueller. 
#               - Re-routed TAIR link to search servlet
#                 instead of outdated cgi link
#               - commented out Meinke site.      
######################################################################

# Create a user agent object
use LWP::UserAgent;

$ua = new LWP::UserAgent;
$ua->agent("TAIRWWW/0.1");

select(stdout); 
$| = 1; # to prevent buffering problems

$hunter = "/cgi-bin/geneform/genehunter.pl";
$tairhome = "/";
$arabgeneform = "/cgi-bin/geneform/geneform.pl";
$base_href = "http://tair.stanford.edu";

&cgi_receive;
&cgi_decode;

$gene = $FORM{'gene'};
$tair = $FORM{'atdb'};
$genbank = $FORM{'genbank'};
$swissprot = $FORM{'swissprot'};
#$meinke = $FORM{'meinke'};
$meinke="";
#$agr = $FORM{'agr'};
$pubmed = $FORM{'pubmed'};
$biosis = $FORM{'biosis'};
$plantcell = $FORM{'plantcell'};
$tigr = $FORM{'tigr'};
$mendel = $FORM{'mendel'};
$pir = $FORM{'pir'};


if ($all) {
	$tair = 'tair';
	$genbank = 'genbank';
	$swissprot = 'swissprot';
	#$meinke = 'meinke';
	#$agr = 'agr';
	$pubmed = 'pubmed';
	$biosis = 'biosis';
	$plantcell = 'plantcell';
	$tigr = 'tigr';
	$mendel = 'mendel';
	$pir = 'pir';
}


# Remove blanks and wildcards from gene name
$gene =~ /((\s)*)(.*)/;
$gene = $3;
$gene =~ s/ /+/g;
$gene =~ s/\++/+/g;
if ( substr( $gene, -1, 1) eq "+" ) {
	chop $gene;
}
@genelist=split( /\+/, $gene );
$trsgdgene = $genelist[0];
$trgene = $trsgdgene;

if ($gene =~ /\*/) {
    $sgdgene = $gene;
    $gene =~ s/\*//g;
    # $trsgene =~ s/\*//g;
} else {
    $sgdgene = $gene;
}


if ($gene eq "") {
    print "Content-type: text/html\n";
    print "Location: ${arabgeneform}\n\n";
    exit;
}

if (!$sgd && !$pubmed && !$genbank && !$swissprot && !ypd && !pdb && !pir && !mips && !atcc) {
    print "Content-type: text/html\n";
    print "Location: ${arabgeneform}\n\n";
    exit;
}

# Print html page header stuff
print "Content-type: text/html\n\n";
print "<html><head><title>Arabidopsis Gene Hunter</title>\n";
print "<script language=\"JavaScript\" src=\"\/js\/navbar.js\"><\/script>\n";
print "<link rel=\"stylesheet\" type=\"text\/css\" href=\"\/css\/main.css\">\n";
print "<script language=\'JavaScript\'>\n";
print "var highlight = 2\; var helpfile=\"\"\;";
print "<\/script>";
print "</head><body bgcolor=#ffffff>\n";
print "<script language=\'JavaScript\' SRC=\'/js/header\'></script><p>\n";
print "<blockquote>\n";
print "<h2>Name Searched</h2>\n";
print "<ul>\n";
print "<li>", $sgdgene, "\n";
print "</ul>\n";

## if genename is long check symbols ##

if ( !($FORM{'m'}) ) {

$gene =~ /([a-zA-Z]*)(\d*)(.*)/;
$abc = $1;
$num = $2;
$rest = $3;

if ( (length($abc)>3) || (length($num)>3) || (length($rest)>0) ) {
	open( SYMB, "mutant.symb" );
	$entries[0] = $sgdgene;
	$descriptions[0]= ' ';
	$j=1;
	foreach $ent (<SYMB>) {
		$entsv = $ent;
		$ent =~ tr/a-z/A-Z/;
		foreach $glst (@genelist ) {
			if ( $ent =~ /$glst/ ) {
				( $symb, $dscr ) = split( /\t/, $entsv);
				( $symb ) = split (/\t/, $ent );
				$j1 = 0;
				if ( $symb ne $glst ) {
					$j2 = 0;
					foreach $e (@entries) {
						if ($e eq $symb) {
							$j1=1;
							$dscr = $descriptions[$j2];
							$dscr =~ s/($glst)/<b>$1<\/b>/gi;
							$descriptions[$j2] = $dscr;
						}
						$j2 = $j2+1;
					}
					if ( $j1 == 0 ) {
						$entries[$j] = $symb; 
						$dscr =~ s/($glst)/<b>$1<\/b>/gi;
						$descriptions[$j] = $dscr;
						$j = $j+1;
					}
				}
			}
		}
	}
	close( SYMB );

	if (( $#genelist > 0)and($#entries==0)) {
		print "The search term was truncated to <b>$genelist[0]</b> for the TAIR, Mendel, PIR and MIPS databases.";
	}
        
	print "<p><hr size=2 width=602 noshade><p>";
	print "<center><b>";
	print "Please send comments about TAIR's Arabidopsis Gene Hunter to ";
	print "<a href=\"mailto:curator","@","arabidopsis.org\">curator","@", "arabidopsis.org</a></b></center>";
	print "<p><hr size=2 width=602 noshade><p>";
  

	@pn = split (/&/, $incoming);
	if ( $#entries > 0) {
		print "<h2>Query Term Options</h2>";
		print "The name you searched has the mutant gene symbol/s shown below. Please click on the term you want to be used in your query, since results may vary. 

<!-- 
To obtain results from Meinke's database you must use the gene symbol as the query term.
-->
The Meinke database is presently not available.  
<br><ul>";
		$j=0;
		foreach $ent ( @entries ) {
			$inc = "gene=" . $ent;
			foreach $p1 (@pn) {
				($sm, $val) = split( /=/, $p1 );
				if ( $sm ne "gene" ) {
					$inc = $inc . "&" . $p1;
				}
			}
			$inc = $inc . "&m=m";

			print "<li>";
			print "<A href=\"${hunter}?${inc}\">${ent}</A> - ${descriptions[$j]}<BR>";
			$j=$j+1;
		}
		print "</ul>";
		exit;
	}
}

}
#######################################
print "<a name=\"dbs\"></a>\n";
print "<h2>Databases Searched</h2>\n";
print "<ul>\n";

if ($tair) {
    print "<li><a href=\"#tair\"><i>The Arabidopsis Information Resource (TAIR)</i></a>.\n";
} 

if ($tigr) {
    print "<li><a href=\"#tigr\">TIGR Arabidopsis Annotation Database</a>\n";
}

#if ($agr) {
#    print "<li><a href=\"#agr\">Arabidopsis Genome Resource (AGR)</a> - NASC\n";
#}

if ($genbank) {
    print "<li><a href=\"#genbank\">GenBank (nucleotide database)</a> - NCBI\n";
} 

if ($pubmed) {
    print "<li><a href=\"#pubmed\">PubMed (literature from National Library of Medicine)</a> - NCBI\n";
} 

if ($meinke) {
    print "<li><a href=\"#meinke\">Mutant Genes of Arabidopsis</a> - Meinke Lab. Oklahoma State U.\n";
}

if ($swissprot) {
    print "<li><a href=\"#swissprot\">Swiss-Prot (annotated protein database)</a> - Swiss Institute of Bioinformatics\n";
}

if ($pir) {
    print "<li><a href=\"#pir\">Protein Information Resource (PIR)</a> - Georgetown U.\n";
}

#if ($mendel) {
#    print "<li><a href=\"#mendel\">Mendel Plant Gene Nomenclature Database</a> - ISPMB (Stanford Mirror)\n";
#}

print "</ul>\n";
print "<p><hr size=2 width=95% noshade><p>";
print "</blockquote>\n";
&search_tair;
&search_tigr;
#&search_agr;
&search_genbank;
&search_pubmed;
&search_meinke;
&search_swissport;
&search_pir;
#&search_mendel;


## (dyoo) Which function is this?  Isn't this supposed to be
## "&tair_footer"?
##&tair_footer_links;


exit;


##########################################################################
# Search TAIR
##########################################################################
sub search_tair {

if ($tair) {

    # Create the request
    $sgdurl = "http://www.arabidopsis.org/servlets/Search?type=gene&search_action=search&pageNum=1&name_type=name&method=2&name=$trgene";
	
    my $reqsgd = new HTTP::Request POST => $sgdurl;
    $reqsgd->content_type('application/x-www-form-urlencoded');
    
    # Pass request to the user agent and get a response back
    my $ressgd = $ua->request($reqsgd);
    
    # Check the outcome of the response
    if ($ressgd->is_success) {
	$output = $ressgd->content;
               $output =~ s/<script.*<\/script>//g;
               $output =~ s/<.*<\/Form>//g;
               $output =~ s/<script language=\'JavaScript\' SRC=\'js\/header\'>//g;
	    print "<a name=\"tair\"></a>\n";
	    print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000><i>The Arabidopsis Information Resource</i>(TAIR)</font>\n";
		$printstr = "<p>This <a href=\"${sgdurl}\">query<\/a> searched the Gene and Gene Alias tables of TAIR relational Database with the term <b>$trgene</b>.";
		if ( $#genelist > 0) {
			$printstr = $printstr ."<p> <FONT COLOR=#ff0000>The query ${gene} was truncated to <b>${trgene}</b>, as this site accepts only single-term queries.</FONT>";
		}
		$printstr = $printstr . "<p>";
		print $printstr;
	    print "<p><hr size=2 width=75%><p>\n";
	    print "<blockquote>$data</blockquote>\n";
	    print $output;
    } else {
	print "<p>The TAIR database is unavailable at this time.  Try again later.\n<p>";
    }
    
	&tair_footer;

}
}

##########################################################################
# Search NCBI nucleotide database 
##########################################################################
sub search_genbank {

if ($genbank) {
    # Create the request
    $gburl = "http://www3.ncbi.nlm.nih.gov/entrez/query.fcgi?dispmax=10&db=Nucleotide&cmd=Search&term=Arabidopsis[ORGN]";

    $i=0;
    foreach $gnn (@genelist ) {
	if ( $i == 0 ) {
	    $gburl = $gburl . "+AND+(";
	    $i=1;
	} else {
	    $gburl = $gburl . "+AND";
	}
	$gburl = $gburl . "+${gnn}[GENE]|${gnn}[WORD]";
    }
    $gburl = $gburl . "+)+&dispmax=10&dopt=d";

    
    my $reqgb = new HTTP::Request GET => $gburl;
    $reqgb->content_type('application/x-www-form-urlencoded');
    
    # Pass request to the user agent and get a response back
    my $resgb = $ua->request($reqgb);
    
    # Check the outcome of the response
    if ($resgb->is_success) {
	$output = $resgb->content;
	&get_ncbi_acc_ids;
	$output =~ s/ACTION=\/htbin/ACTION=http:\/\/www3.ncbi.nlm.nih.gov\/htbin/g;
	$output =~ s/ACTION=\"\/htbin/ACTION=\"http:\/\/www3.ncbi.nlm.nih.gov\/htbin/g;
	$output =~ s/SRC=\/Gifs/SRC=http:\/\/www3.ncbi.nlm.nih.gov\/Gifs/g;
	$output =~ s/src=\/Gifs/src=http:\/\/www3.ncbi.nlm.nih.gov\/Gifs/g;
	$output =~ s/a href=\"\/htbin/a href=\"http:\/\/www3.ncbi.nlm.nih.gov\/htbin/g;
	$output =~ s/A HREF=\"\/htbin/a href=\"http:\/\/www3.ncbi.nlm.nih.gov\/htbin/g;
	$output =~ s/a href=\/htbin/a href=http:\/\/www3.ncbi.nlm.nih.gov\/htbin/g;
	$output =~ s/A HREF=\/htbin/a href=http:\/\/www3.ncbi.nlm.nih.gov\/htbin/g;
	$output =~ s/SRC=\/PMGifs/SRC=http:\/\/www3.ncbi.nlm.nih.gov\/PMGifs/g;
	$output =~ s/src=\"\/PMGifs/src=\"http:\/\/www3.ncbi.nlm.nih.gov\/PMGifs/g;
	$output =~ s/<body .*>//;
        $output =~ s/<script language=\"JavaScript\">document.frmQueryBox.term.focus\(\)\;<\/script>/ /g;
	
	print "<a name=\"genbank\"></a>\n";
	print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000>GenBank (nucleotide database) from NCBI</font>\n";
	$printstr = "<p>This <a href=\"${gburl}\">query<\/a> searched the nucleotide section of GenBank for all records that include the word <b>Arabidopsis</b> in the organism field and the term <b>$gene</b> in the gene name, gene description, definition or comment fields.<p>\n";
	
	print $printstr;
	print "<blockquote>$output</blockquote>\n";
    } else {
	print "<a name=\"genbank\"></a>\n";
	print "<p>GenBank at NCBI is unavailable at this time.  Try again later.\n<p>";
    }
	&tair_footer;
}

}

##########################################################################
# Search PubMed 
##########################################################################
sub search_pubmed {

    if ($pubmed) {

	# Create the request
	#$medurl = "http://www4.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=m&form=4&term=\(";
        $medurl = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&db=PubMed&term=%28$trgene%5bTEXT%3anoexp%5d%20AND%20Arabidopsis%5bALL%5d%29";
	#$i=0;
	#foreach $gnn (@genelist ) {
	#    if ($i== 0 ) {
	#	$i=1;
	#   } else {
	#	$medurl = $medurl . "+AND+";
	#    }
	#    $medurl = $medurl . "${gnn}[TEXT:noexp]";
	#}
	#$medurl = $medurl . "\)&Arabidopsis[ALL]&dispmax=10&dopt=d";

	my $reqmed = new HTTP::Request GET => $medurl;
	$reqmed->content_type('application/x-www-form-urlencoded');


	# Pass request to the user agent and get a response back
	my $resmed = $ua->request($reqmed);
    
	# Check the outcome of the response
	if ($resmed->is_success) {
	    $output = $resmed->content;
	    $output =~ s/ACTION=\/htbin/ACTION=http:\/\/www4.ncbi.nlm.nih.gov\/htbin/g;
	    $output =~ s/ACTION=\"\/htbin/ACTION=\"http:\/\/www4.ncbi.nlm.nih.gov\/htbin/g;
	    $output =~ s/a href=\"\/htbin/a href=\"http:\/\/www4.ncbi.nlm.nih.gov\/htbin/g;
	    $output =~ s/a href=\/htbin/a href=http:\/\/www4.ncbi.nlm.nih.gov\/htbin/g;
	    $output =~ s/A HREF=\"\/htbin/a href=\"http:\/\/www4.ncbi.nlm.nih.gov\/htbin/g;
	    $output =~ s/A HREF=\/htbin/a href=http:\/\/www4.ncbi.nlm.nih.gov\/htbin/g;
            $output =~ s/background\=\"http:\/\/www.ncbi.nlm.nih.gov\/corehtml\/bkgd.gif\"/ /g;

	    $output =~ s/SRC=\/Gifs/SRC=http:\/\/www4.ncbi.nlm.nih.gov\/Gifs/g;
	    $output =~ s/src=\/Gifs/src=http:\/\/www4.ncbi.nlm.nih.gov\/Gifs/g;
	    $output =~ s/SRC=\/PMGifs/SRC=http:\/\/www4.ncbi.nlm.nih.gov\/PMGifs/g;
	    $output =~ s/src=\"\/PMGifs/src=\"http:\/\/www4.ncbi.nlm.nih.gov\/PMGifs/g;
	    print "<a name=\"pubmed\"></a>\n";
	    print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000>PubMed (literature from National Library of Medicine)</font>\n";

	    $cpmedurl = $medurl;
	    $cpmedurl =~ s/TEXT:noexp/ALL/g;

	    $printstr = "<p>This <a href=\"${medurl}\">query<\/a> searched PubMed for all citations that include the word <b>Arabidopsis</b> in any field and the term <b>$gene</b>";
	
	    $printstr = "${printstr} in any text field.  A different PubMed <a href=\"http://www4.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=m&form=4&term=\(";
	    $i=0;
	    foreach $gnn ( @genelist ) {
		$printstr = "${printstr}${gnn}[ALL]|${gnn}p[ALL]";
	    }
	
	    $printstr = "${printstr} \)&Arabidopsis[ALL]&dispmax=50&dopt=d\">query</a> expands the search terms using the Unified Medical Language System (e.g., a query for the gene alr2 also searches for aldehyde reductase).<p>\n";
	    print $printstr;
	
	    print "<blockquote>$output</blockquote>\n";
	
	} else {
	    print "<a name=\"pubmed\"></a>\n";
	    print "<p>PubMed at NCBI is unavailable at this time.  Try again later.\n<p>";
	}

	&tair_footer; 
    }
}


##########################################################################
# Search Swiss-Prot protein database 
##########################################################################
sub search_swissport {

if ($swissprot) {

    # Create the request
    $spurl = "http://www.expasy.ch/cgi-bin/sprot-search-de?$gene+ARABIDOPSIS";

    my $reqsp = new HTTP::Request GET => $spurl;
    $reqsp->content_type('application/x-www-form-urlencoded');

    # Pass request to the user agent and get a response back
    my $ressp = $ua->request($reqsp);

    # Check the outcome of the response
    if ($ressp->is_success) {
        # hack so point to the right server
        $_ = $ressp->content;
	$stanfordUrl = "\"/";
 	$swissUrl = "\"http://www.expasy.ch/";
	s/$stanfordUrl/$swissUrl/g;
	$output = $_;

	#$output = $ressp->content;
	&swiss_prot_cleanup;
	
	($top, $download, $footer) = split(/<HR>/,$output);
	($title, $rest) = split(/<UL><LI>/,$top);
	($ul, $data) = split(/<\/UL>/,$rest);
	($list1, $list2) = split(/<LI>/,$ul);
	($address, $home) = split (/<P>/,$footer);
	
	$data =~ s/HREF=\"\/cgi-bin\/get-sprot-entry/HREF=\"http:\/\/www.expasy.ch\/cgi-bin\/get-sprot-entry/g;
	$home =~ s/\/www/http:\/\/www.expasy.ch\/www/g;
	$home =~ s/SRC=\"\/sgifs/SRC=\"http:\/\/www.expasy.ch\/sgifs/g;
	
	print "<a name=\"swissprot\"></a>\n";
	print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000>Swiss-Prot (annotated protein database)</a> from the Swiss Institute of Bioinformatics</font>\n";
	print "<p>This <a href=\"${spurl}\">query<\/a> searched Swiss-Prot for all protein sequence entries that include the word <b>Arabidopsis</b> and the term <b>$gene</b> in the description or identification (the IDentification, DEscription, Gene Name, Organism Species or OrGanelle fields).<p>\n";
	if ($list1) {
		print "<blockquote>$title<ul><li>$list1</ul>$data<p>$home</blockquote>\n";
	} else {
		print "<blockquote>$title</blockquote>\n";
	}
    } else {
	print "<a name=\"Swiss-Prot\"></a>\n";
	print "<p>Swiss-Prot at Geneva is unavailable at this time.  Try again later.\n<p>";
    }
    
	&tair_footer;
}

}

    
##########################################################################
# Search Yeast Protein Database (YPD) 
##########################################################################

sub search_ypd {
if ($ypd) {

    # Create the request
    $ypdurl = "http://www.proteome.com/cgi-bin/searchYPD?reports=$gene";
#    if ($add) {
#    	foreach $oname (@onames) {
#    		$ypdurl = $ypdurl . "|" . $oname;
#	}
#    }

    my $reqypd = new HTTP::Request GET => $ypdurl;
    $reqypd->content_type('application/x-www-form-urlencoded');
    
    # Pass request to the user agent and get a response back
    my $resypd = $ua->request($reqypd);
    
    # Check the outcome of the response
    if ($resypd->is_success) {
	$output = $resypd->content;

	$output =~ s/href=\"\/YPD/href=\"http:\/\/quest7.proteome.com\/YPD/g;
	$output =~ s/src=\"\/gifs/src=\"http:\/\/quest7.proteome.com\/gifs/g;

	print "<a name=\"ypd\"></a>\n";
	print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000>Yeast Protein Database (YPD) from Proteome</font>\n";
	print "<p>This <a href=\"http://www.proteome.com/cgi-bin/searchYPD?reports=$gene\">query<\/a> searched YPD for the gene name or synonym <b>$gene</b>.<p>\n";
	print "<blockquote>$output</blockquote>\n";
    } else {
	print "<a name=\"ypd\"></a>\n";
	print "<p>YPD from Proteome is unavailable at this time.  Try again later.\n<p>";
    }
    
    print "<p><hr size=2 width=75%>";
    print "<center><a href=\"${arabgeneform}\"><b>Search another gene name</b></a> |\n";
    print "Go to list of <a href=\"#contents\"><b>Databases Searched</b></a> |\n";
    print "<a href=\"http://genome-www.stanford.edu/Saccharomyces/\">SGD Home</a>\n";
    print "<hr size=2 width=95% noshade></center><p>";

}
}
##########################################################################
# Search Protien Information Resource (PIR) 
##########################################################################
sub search_pir {

if ($pir) {

    # Create the request
    $pirurl = "http://pir.georgetown.edu/cgi-bin/nbrffind?SPECIES=Arabidopsis&GENE_NAME=$gene";

    my $reqpir = new HTTP::Request GET => $pirurl;
    $reqpir->content_type('application/x-www-form-urlencoded');
    
    # Pass request to the user agent and get a response back
    my $respir = $ua->request($reqpir);
    
    # Check the outcome of the response
    if ($respir->is_success) {
	$output = $respir->content;

	$output =~ s/HREF=\"\/cgi-bin/HREF=\"http:\/\/pir.georgetown.edu\/cgi-bin/g;

	print "<a name=\"pir\"></a>\n";
	print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000>Protein Information Resources (PIR) - Georgetown University</font>\n";
	print "<p>This <a href=\"${pirurl}\">query<\/a> searched PIR for the species <b>Arabidopsis</b> and gene name <b>$trgene</b>.";
	if ( $#genelist > 0) {
		print "<p><FONT COLOR=#ff0000>The query ${gene} was truncated to <b>${trgene}</b>, as this site accepts only single-term queries.</FONT>";
	}
	print "<p>";
	print "<blockquote>$output</blockquote>\n";
    } else {
	print "<a name=\"pir\"></a>\n";
	print "<p>PIR from Georgetown is unavailable at this time.  Try again later.\n<p>";
    }
    
	&tair_footer;
}
}

##########################################################################
# Mutant Genes of Arabidopsis:  Locus | Symbol - Meinke Lab. Oklahoma U.
##########################################################################
sub search_meinke {
	if ($meinke) {
	$gl_url = "http://www.arabidopsis.org/cgi-bin/geneform/okstate-mutant.pl?search=$gene";
	&do_request;

	print "<a name=\"meinke\"></a>\n";

	if ($ressp->is_success) {
		$output = $ressp->content;
		print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000><I>Arabidopsis Genetics</I> at Meinke Laboratory</font>\n";
		$printstr = "<p>This <a href=\"${gl_url}\">query<\/a> searched the Mutant Genes of Arabidopsis containing the term <b>$gene</b>.<p>";
		print $printstr;
		print "<blockquote>";
		print $output;
		print "</blockquote>\n";

		if ( $output =~ /not found/ ) {
			$gl_url = "/cgi-bin/geneform/okstate-mutant.pl?search=$gene&Symbols";
			&do_request;
			if ($ressp->is_success) {
			    # hack to remove the wrong message
			    $_ = $ressp->content;
			    $oldMes = "<H3>$gene <B>can be submitted</B> as a new gene symbol if the search term was acceptable.</H3><P>";
			    $newMes = "<P>";
			    s/$oldMes/$newMes/g;
			    $output = $_;
			    
			    #$output = $ressp->content;			    
			    $printstr = "</b><p>This <a href=\"${gl_url}\">query<\/a> searched the Meinke Database for Mutant Gene Symbols containing the term <b>$gene</b>.<p>";
			    print $printstr;
			    print "<blockquote>";
			    print $output;
			    print "</blockquote>\n";
			}
		}
	} else {
		print "<p>The Meinke Laboratory is unavailable at this time.  Try again later.\n<p>";
	}

	&tair_footer;
	}
}

##########################################################################
# Arabidopsis Genome Resource (AGR)
##########################################################################
 
#sub search_agr {
#    if ($agr) {
#      $gl_url = "http://ukcrop.net/perl/ace/tree/AGR?name=$trgene&class=Gene_name";
#      &do_request;
#	
#        print "<a name=\"agr\"></a>\n";
#
#        if ($ressp->is_success) {
###	    $output = $ressp->content;
#	    $output = fix_unqualified_urls
#		("http://ukcrop.net/perl/ace/search/",
#		 $ressp->content);
#	    print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000><I>Arabidposis</I> Genome Resource (AGR) at NASC</font>\n";
#	    $printstr = "<p>This <a href=\"${gl_url}\">query<\/a> searched AGR for all entries that include the term <b>$gene</b>.";
#	    if ( $#genelist > 0) {
#		$printstr = $printstr . "<p><FONT COLOR=#ff0000>The query ${gene} was truncated to <b>${trgene}</b>, as this site accepts only single-term queries.</FONT>";
#	    }
#	    
#	    $printstr = $printstr . "<p>";
#	    &translate_link( "http://synteny.nott.ac.uk" );
#	    print $printstr;
#	    $output =~ s/<LINK REL=\"stylesheet\" TYPE=\"text\/css\" HREF=\"\/elegans.css\">//g;
#	    print "<blockquote>";
#	    print $output;
#	    print "</blockquote>\n";
#	    
#        } else {
#	    print "<p>AGR at NASC is unavailable at this time.  Try again later.\n<p>";
#        }
#        &tair_footer;
#    }
#}
                  
sub search_biosis {
	if ($biosis) {
        $gl_url = "http://library.lanl.gov:8001/QUERY:%7fnextbrowse=html/wordlist.html%7fentitytempjds=TRUE%7f%3Asessionid=?%7Fbrowseflag=true%7f5&terma=$gene&dbname=SU_UEF";
	$gl_url = "http://library.lanl.gov:8001/CHOOSE:next=html/!DBNAME!_search.html|html/simple_search.html:entityClearLimits=1:%3Asessionid=?:1&dbname=SU_UEF";
        &do_request;

	if ($ressp->is_success) {
		$output = $ressp->content;
	} else {
		return;
	}

	$mmhit = 0;
	@lines = split (/\n/, $output );
		foreach $line (@lines) {
			if ($mmhit == 0) {
			if ( $line =~ /FORM/ ) {
				$line =~ /(.*?)ACTION="(.*?)"/;
				$gl_url = "http://library.lanl.gov:8001" . $2;
				$mmhit = 1;
			}
			}
		}
	$reqsp = new HTTP::Request POST => $gl_url;
	$reqsp->content_type('application/x-www-form-urlencoded');
	$text = "indexa=su:&terma=" . $gene . " AND Arabidopsis";
	$reqsp->content( $text );
	$ressp = $ua->request($reqsp);

        print "<a name=\"biosis\"></a>\n";

        if ($ressp->is_success) {
                $output = $ressp->content;
                print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000>Biosis at Los Alamos National Laboratory</font>\n";
                $printstr = "<p>This <a href=\"${gl_url}\">query<\/a> searched Biosis for all sequences that include the word <b>$gene</b>.";
		$printstr = "<p>Biosis was searched for all papers that include <b>Arabidopsis</b> and the term <b>$gene</b>.  Biosis is only available from computers at Stanford.<p>";
                print $printstr;
		$output =~ s/HREF=\"\//HREF=http:\/\/library\.lanl\.gov:8001\//g;
		$output =~ s/src=\"\//src=\"http:\/\/library\.lanl\.gov:8001\//g;
		$output =~ s/href=\"\//href=\"http:\/\/library\.lanl\.gov:8001\//g;
		$output =~ s/SRC=\"\//SRC=\"http:\/\/library\.lanl\.gov:8001\//g;
	#	$output =~ s/<LINK REL=\"stylesheet\" TYPE=\"text\/css\" HREF=\"\/elegans.css\">//g;
                $output =~ s/HREF=\"elegans.css\"/ /g;
		print "<blockquote>";
                print $output;
		print "</blockquote>\n";

        } else {
                print "<p>Biosis is unavailable at this time.  Try again later.\n<p>";
        }

        &tair_footer;
	}
}
##########################################################################
# Search Plant Cell ( No longer in use):
# 1096 - fixed, Modify the scripts and web interface to exclude "The Plant Cell" site 
##########################################################################

sub search_plantcell {
       if ($plantcell) {
        $gl_url = "http://www.plantcell.org/cgi/search?fulltext=Arabidopsis+AND+$sgdgene";
        &do_request;

        print "<a name=\"plantcell\"></a>\n";

        if ($ressp->is_success) {
                $output = $ressp->content;
                print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000>The Plant Cell at American Society of Plant Physiologists</font>\n";
                $printstr = "<p>This <a href=\"${gl_url}\">query<\/a> searched the Plant Cell for all papers that include the word <b>Arabidopsis</b> and the term <b>$sgdgene</b>.<p>";
                print $printstr;
		&remove_plantcell_add;
		&plantcell_zero_cleanup;
		$output =~ s/SRC=\"\//SRC=\"http:\/\/www\.plantcell\.org\//g;
		$output =~ s/HREF=\"\//HREF=\"http:\/\/www\.plantcell\.org\//g;
		print "<blockquote>";
                print $output;
		print "</blockquote>\n";

        } else {
                print "<p>The Plant Cell is unavailable at this time.  Try again later.\n<p>";
        }

        &tair_footer;
        }
}
##########################################################################
# The Institute for Genomic Research - (TIGR):
# 1098 - fixed, Add TIGR to the Gene Hunter list
##########################################################################

sub search_tigr {
if ($tigr) {
        $gl_url = "http://www.tigr.org/docs/tigr-scripts/edb2_scripts/neuk_name_search.spl?db=ath1&search_string=$gene";
        &do_request;

        print "<a name=\"tigr\"></a>\n";
	$output = "";
        if ($ressp->is_success) {
                $output = $ressp->content;
                print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000>TIGR Arabidopsis Annotation Database</font>\n";
                $printstr = "<p>This <a href=\"${gl_url}\">query<\/a> searched TIGR Arabidopsis Annotation Database for all sequences that include the word <b>Arabidopsis</b> and the term <b>$sgdgene</b>.<p>";
                print $printstr;
		&remove_plantcell_add;
		&plantcell_zero_cleanup;
                $output =~ s/SRC=\"\//SRC=\"http:\/\/www\.tigr\.org\//g;
              
                $output =~ s/HREF=\"\//HREF=\"http:\/\/www\.tigr\.org\//g;
		print "<blockquote>";
                print $output;
		print "</blockquote>\n";

        } else {
                print "<p>TIGR Arabidopsis Annotation Database is unavailable at this time.  Try again later.\n<p>";
        }
	&tair_footer;

        }
}

##########################################################################
# Mendel Plant Gene Nomenclature Database - ISPMB (Stanford Mirror)
# 1031 - fixed, fix Mendel, only returning 0 results
##########################################################################
#sub search_mendel {
#	if ($mendel) {
#		if ($genbank) {
#			&search_mendel_genbank;
#		} else {
#			&search_mendel_only;
#		}
#	}
# }
#
# sub search_mendel_only {
#    if ( ($mendel) ) {
#	print "<a name=\"mendel\"></a>\n";
#	print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000>Mendel Plant Gene Nomenclature Database</font><br>\n";	
#	print "The Mendel Database was searched using ";  
#	$i = $#ncbi_acc_ids +1;
#	print $i;
#	print " accession numbers found by the GenBank search above.";
#	$myhit = 0;
#	foreach $ncbi_acc (@ncbi_acc_ids) {
#	    $gl_url = "http://genome-www.stanford.edu/cgi-bin/dbrun/Mendel?find+DNAseqAC+%22${ncbi_acc}%22";
#	    &do_request;
#	    if ($ressp->is_success) {
#		$output = $ressp->content;
#		if ($output =~ /Sorry/ ) {
#		} else {
#		    $myhit = 1;
#		    $output =~ /(.*?)(DNAseqAC(.|\n)*)/;
#		    $output = $2;
#		    $output =~ /((.|\n)*?)<hr>.*/;
#		    $output = $1;
#		    $output =~ s/href=\"\//href=\"http:\/\/genome-www\.stanford\.edu\//g;
#		    print "<blockquote>";
#		    print $output;
#		    print "</blockquote>\n";
#		}
#	    }
#	}
#	if ($myhit == 0) {
#	    print "  None of these could be found in The Mendel Database.";
#	}	&tair_footer;
#    }
# }

sub search_mendel {
       if ($mendel) {
        $gl_url = "http://genome-www.stanford.edu/cgi-bin/dbrun/Mendel?LongGrep+$trsgdgene";
        &do_request;

        print "<a name=\"mendel\"></a>\n";

        if ($ressp->is_success) {
                $output = $ressp->content;
                print "<IMG border=0 SRC=\"/images/right.gif\" alt=\"[X]\"><font size=+3 FONT COLOR=#ff0000>Mendel Plant Gene Nomenclature Database</font>\n";
                $printstr = "<p>This <a href=\"${gl_url}\">query<\/a> searched Mendel Plant Gene Nomenclature Database for all sequences that include the word <b>$trsgdgene</b>.";
		if ($#genelist > 0) {
			$printstr = $printstr . "<p><FONT COLOR=#ff0000>The query ${sgdgene} was truncated to <b>${trsgdgene}</b>, as this site accepts only single-term queries.</FONT>";
		}
		$printstr = $printstr . "<p>";
                print $printstr;
		print "<blockquote>";
                print $output;
		print "</blockquote>\n";
        } else {
                print "<p>The Mendel Plant Gene Nomenclature Database is unavailable at this time.  Try again later.\n<p>";
        }

        &tair_footer;
        }

}


sub do_request {
	$reqsp = new HTTP::Request GET => $gl_url;
	$reqsp->content_type('application/x-www-form-urlencoded');
	$ressp = $ua->request($reqsp);
}

###########################################################################
# Subroutines
###########################################################################
sub cgi_receive {
    if ($ENV{'REQUEST_METHOD'} eq "POST") {
        read(STDIN, $incoming, $ENV{'CONTENT_LENGTH'});
    }
    else {
        $incoming = $ENV{'QUERY_STRING'};
    }
}

sub cgi_decode {
    @pairs = split(/&/, $incoming);

    foreach (@pairs) {
        ($name, $value) = split(/=/, $_);

        $name  =~ tr/+/ /;
        $value =~ tr/+/ /;
        $name  =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/gie;
        $value =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/gie;

        #### Strip out semicolons unless for special character
        $value =~ s/;/$$/g;
        $value =~ s/&(\S{1,6})$$/&$1;/g;
        $value =~ s/$$/ /g;

        $value =~ s/\|/ /g;
        $value =~ s/^!/ /g; ## Allow exclamation points in sentences

        #### Skip blank text entry fields
        next if ($value eq "");

	$FORM{$name} = $value;

    }
	$FORM{'gene'} =~ tr/a-z/A-Z/;
}

#############################################################################

sub tair_footer {
	print "<head><base href=\"http://$ENV{HTTP_HOST}\"></head>\n";
    print "<p><hr size=2 width=75%>";
    print "<center><a href=\"${arabgeneform}\"><b>Search another gene name</b></a> |\n";
    print "Go to list of <a href=\"${hunter}#dbs\"><b>Databases Searched</b></a> |\n";
    print "<a href=\"${tairhome}\">TAIR Home</a>\n";
    print "<hr size=2 width=95% noshade></center><p>";
}

sub get_ncbi_acc_ids {
	local( @ncbi_acc );

	@ncbi_acc = split( /<INPUT TYPE=\"checkbox\" NAME=\"uid\"/, $output );
	$i=0;
	foreach $ncbi_acc (@ncbi_acc) {
		if ($i != 0) {
#			if ($i <= $#ncbi_acc) {
			if ($i < 45 ) {
			$ncbi_acc[$i] =~ /(.*?)>(\W*?)(\w*)(\W*?)<(.|\n)*/;
			$ncbi_acc_ids[$i-1] = $3;
			}
		}
		$i=$i+1;
	}
}

sub remove_plantcell_add  {
	@lines = split (/\n/, $output );
	$output = "";
	foreach $line (@lines) {
		if ( $line =~ /\/ads\/gifs\// ) {
			# get rid of this line 
		} else {
			$output = $output . "\n";
			$output = $output . $line;
		}
	}

}

sub plantcell_zero_cleanup {
	if ( $output =~ /Your search retrieved zero articles/ ) {
		@lines = split (/\n/, $output );
		$output = "";
		$mmhit=0;
		foreach $line (@lines) {
			if ($mmhit == 0) {
				if ( $line =~ /Anywhere in Article:/ ) {
					$mmhit = 1;
				}
				$output = $output . $line;
				$output = $output . "\n";
			} elsif ($mmhit == 1) {
				if ( $line  =~ /<\/BODY>/ ){
					$output = $output . "\n<P>&nbsp;<P>\n";
					$output = $output . "<STRONG><FONT COLOR=A70716>Your search retrieved zero articles.</FONT></STRONG></DL>";
					$output = $output . $line;
					$output = $output . "\n";
					$mmhit = 0;
				}
			}
		}
	}

}

sub empty_output {
	local ( $text ) = @_;
	@lines = split (/\n/, $output );
	$mmhit = 0;
	$head = "";
	$body = "";
	foreach $line (@lines) {
		if ($mmhit == 0) {
			$head = $head . $line;
			if ( $line =~ /<BODY/ ) {
				$mmhit = 1;
			}
		} elsif ($mmhit == 1) {
			$body= $body . $line;
		}
	}	
	@empty = split ( /<.*?>/, $body );
	$mmhit = 0;
	foreach $line ( @empty ) {
		if ( $line =~ /\w/ ) {
			$mmhit = 1;
		}
	}
	if ($mmhit == 0 ) {
		$output = $head . $text . "</BODY></HTML>";
	}
}

sub swiss_prot_cleanup {
        if ( $output =~ /No entries have been found/ ) {
                @lines = split (/\n/, $output );
                $output = "";
                $mmhit=0;
                foreach $line (@lines) {
                        if ($mmhit == 0) {
                                if ( $line =~ /No entries have been found/ ) {
                                        $mmhit = 1;
                                }
                                $output = $output . $line;
                                $output = $output . "\n";
                        } elsif ($mmhit == 1) {
                                if ( $line  =~ /<\/BODY>/ ) {
                                        $output = $output . $line;
                                        $output = $output . "\n";
                                        $mmhit = 0;
                                }
                        }
                }
        }
}

sub translate_link {
	my ( $linktr ) = @_;

	$output =~ s/SRC=\"\//SRC=\"${linktr}\//g;
	$output =~ s/ACTION=\"\//ACTION=\"${linktr}\//g;
	$output =~ s/href=\"\//href=\"${linktr}\//g;
}




## Replace all unqualified urls in the source with qualified ones.
## This is a useful utility; perhaps it might be good to move this off
## into another module.
## We expect $base to end with a '/'.
sub fix_unqualified_urls {
    my ($base, $source) = @_;
    my ($host) = ($base =~ m{(http://.*?)/});
    my $LTRS = '\w';
    my $GUNK = '/#~:.?+=&%@!\-';
    my $PUNC = '.:?\-';
    my $ANY = $LTRS . $GUNK . $PUNC;
    my $REF = qr{
	  ((href|src) \s* = \s*)              ## Group 1 (method)
                       (["'])                 ## Group 3 (quote)
               (?! (http://|mailto:))         ## Group 4 (negative lookahead)
               ([$ANY]  +?)                   ## Group 5 (content)
               (?=                            ## (positive lookahead)
                     [$PUNC]*
                     [^$ANY]
                  |
                     $
               )
               (["'])                        ## Group 6 (quote)

             }xi;
    ## Not quite perfect yet; if the selected url begins with a '/', we
    ## need to do some more url adjustments.
    my $result = $source;
    while($source =~ m/$REF/g) {
        my ($method, $quote, $content, $quote2) = ($1, $3, $5, $6);
        my $replacing_string = "$1$3$5$6";
        if (substr($content, 0, 1) eq '/') {
            $result =~ s/\Q$replacing_string\E/$method$quote$host$content$quote2/g;
        }
        else {
            $result =~ s/\Q$replacing_string\E/$method$quote$base$content$quote2/g;
        }
    }
    return $result;
}

######################################################################
#"'}}# this line is just to make Emacs happy again.
######################################################################
