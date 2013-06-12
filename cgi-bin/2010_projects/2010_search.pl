#!/bin/env perl -Tw


## 2010_search.pl --- a search interface for the 2010 Projects list.
##
## Danny Yoo (dyoo@acoma.stanford.edu)
##
## This CGI accepts the following request parameters:
##
##     qstring: a query string, the string that we're searching.
##     stype: the type of a search.
##     start: the beginning row of our output.
##     limit: bounds on how many rows we display at once.
##
## This script also has a bulk text output mode that's on if a 'text'
## attribute is set.  In this mode, only 'qstring' and 'stype' are
## considered, and all results are returned using Content-type: text/plain.
##
##
## See getQueryResults() to add new types of searches to the script.
##
## We expose the following template parameters when displaying our results:
##
##     NUM_OF_ROWS
##     ROWS
##     START
##     LIMIT
##     QUERY_STRING
##     QUERY_TYPE
##     NEXT
##     PREVIOUS

use CGI;
use strict;
use HTML::Template;
use lib ".";
use search;
use format;


## The default number of entries per page.
my $LIMIT_DEFAULT = 50;

## Enforce a limit on how many results we'll get altogether.
my $LIMIT_SEARCH_MAX_RESULTS = 5000;


main();
## The main entry point of our program.
sub main {
    my $db_source = "data/data.tab";
    my $index_file = 'templates/index.html.template';

    my $template = HTML::Template->new(filename => $index_file,
				       die_on_bad_params => 0); 
    my $cgi = CGI->new();
    if ($cgi->param("text")) {
	searchAndStreamFlatText($cgi, $db_source);
    } else {
	searchAndPrintHtmlResults($template, $cgi, $db_source);
    }
}



## Given an entry, returns a reference to a hash that maps column
## names to values.  Also processes the fields to add hyperlinks.
sub GetRow($) {
    my ($entry) = @_;
    my @columns = split("\t", $entry, -1);
    @columns = map {strip($_)} @columns;
    my %row = (ACCESSION_NUMBER => extractAccessionNumber($columns[$ACCESSION_COL]),
	       ACCESSION_TYPE => extractAccessionType($columns[$ACCESSION_COL]),
	       LOCUS => $columns[$LOCUS_COL] || "",
	       OTHER_GENE_NAMES => $columns[$OTHER_GENE_NAMES_COL] || "",
	       # Add email anchors to a PI's email address.
	       PI_NAME => GetEmailLinkedString($columns[$PI_COL]) || "",
	       PROPOSAL_NAME => $columns[$PROPOSAL_NAME_COL] || "",
	       PROPOSAL_NUMBER => $columns[$PROPOSAL_NUM_COL] || "",
	       # Add http anchors to comments.
	       COMMENT => urlify($columns[$COMMENT_COL]) || "",
	       GRANTING_AGENCY => $columns[$GRANTING_AGENCY_COL] || "",
	       WEB_SITE => $columns[$WEB_SITE_COL] || "",
	       OPTIONAL_PROPOSAL_NUMBER_URL => 
	       $columns[$OPTIONAL_PROPOSAL_NUMBER_URL_COL] || "",
	       );
    $row{PROTEIN_ACCESSION} = ($row{ACCESSION_TYPE} eq 'protein');
    return \%row;
}


sub extractAccessionNumber {
    my $accession = shift || "";
    if ($accession =~ m/^protein:(.+)$/i) {
	return $1;
    }
    return $accession;
}



sub extractAccessionType {
    my $accession = shift || "";
    if ($accession =~ m/^protein:/) {
	return "protein";
    }
    return "nucleotide";
}





## This is actually doing two things: it does the search, and also
## displays the output.  Perhaps I should break this down into two pieces.
sub searchAndPrintHtmlResults($$$) {
    my ($template, $cgi, $db_source) = @_;
    my $IS_QUERY_NONEMPTY = 1;
    if (! $cgi->param('qstring')) { $IS_QUERY_NONEMPTY = 0; }
    my $stype = $cgi->param('stype') || "any";
    my $start = $cgi->param('start') || 1;
    my $limit = $cgi->param('limit') || $LIMIT_DEFAULT;
    my $qstring = $cgi->param('qstring') || "";

    my $starttime = time();
    my ($too_many_results, 
	@results) = getResultsFromSearch($qstring, $stype, $db_source, 
					 $start, $limit);
    my $stoptime = time();

    my $max_result_count = scalar(@results);
    @results = BoundByLimits($start, $limit, @results);

    $template->param({ "NUM_OF_ROWS" => scalar(@results),
		       "NUM_OF_MAX_RESULTS" => $max_result_count,
		       "ROWS" => \@results,
		       "START" => $start,
		       "END" => $start + scalar(@results) - 1,
		       "LIMIT" => $limit,
		       "QUERY_STRING" => urlEscape($qstring),
		       "QUERY_TYPE" => urlEscape($stype),
		       "NEXT" => clamp($start + $limit, 1, $max_result_count),
		       "PREVIOUS" => clamp($start - $limit, 1, $max_result_count),
		       "SEARCH_TIME" => $stoptime - $starttime,
		       "TOO_MANY_RESULTS" => $too_many_results,
		       });
    print $cgi->header;
    print $template->output;
}


## Outputs a flat text file of all the lines in our $db_source that satisfy
## the query.
sub searchAndStreamFlatText($$) {
    my ($cgi, $db_source) = @_;
    my $stype = $cgi->param('stype') || "any";
    my $qstring = $cgi->param('qstring') || "";
    my $resultiter = search::GetStreamingQueryResults($stype, $qstring, $db_source);
    print "Content-type: text/plain\n\n";
    printFlatTextHeader();
    while ($resultiter->hasNext()) {
	print $resultiter->next();
    }
    $resultiter->close();
}


sub printFlatTextHeader {
    my @columns = ("genbank_accession",
		   "locus",
		   "other_gene_names",
		   "proposal_name",
		   "proposal_number",
		   "principal_investigator",
		   "comment",
		   "granting_agency",
		   "web_site",
		   );
# The optional proposal number url isn't used by the current set of
# data, so we won't display it.
    print join "\t", @columns;
    print "\n";
}




sub getResultsFromSearch {
    my ($qstring, $stype, $db_source, $start, $limit) = @_;
    my $too_many_results = 0;
    my @results = search::GetQueryResults($stype, $qstring, $db_source, 
					  $LIMIT_SEARCH_MAX_RESULTS);
    ## If we hit the result ceiling, better say so.
    if (@results >= $LIMIT_SEARCH_MAX_RESULTS) {
	$too_many_results = 1;
    }
    my $i = 0;
    while ($i < @results) {
	$results[$i] = GetRow($results[$i]);
	$i++;
    }
    @results = CompressResults(@results);
    @results = AddOtherFlags(@results);
    return ($too_many_results, @results);
}







## To reduce the number of rows we're displaying on the HTML, we'll
## compress entries with the same content (except for accession
## number) down into the same entry.  We return back another list of
## results, where all the ACCESSION_NUMBERs are compressed into a
## single ACCESSION_NUMBERS field.
sub CompressResults {
    my @results = @_;
    my %uniques;
    for my $r (@results) {
	my $signature = packEntryIntoSignature($r);
	if (exists $uniques{$signature}) {
	    push(@{$uniques{$signature}},
		 {ACCESSION_NUMBER => $r->{ACCESSION_NUMBER}});
	}
	else { 
	    $uniques{$signature} =
		[ {ACCESSION_NUMBER => $r->{ACCESSION_NUMBER}} ];
	}
    }
    my @compressed;
    for my $key (keys %uniques) {
	my @elements = unpackSignatureIntoEntry($key);
	push(@compressed, { @elements, 
			    "ACCESSION_NUMBERS" => $uniques{$key} })
	}
    return @compressed;
}

## Given an entry, returns a "signature" suitable as a hash key.
sub packEntryIntoSignature {
    my $r = shift;
    my %hash = %$r;
    ## The signature is everything except the accession number.
    my @columns_without_accession_number =
      grep {$_ ne 'ACCESSION_NUMBER'} sort keys %{$r};
    my @values = @hash{@columns_without_accession_number};
    my $signature = join("\t", zip(\@columns_without_accession_number,
				   \@values));
    return $signature;
}
## Undoes the damage of packing.
sub unpackSignatureIntoEntry {
    my $sig = shift;
    ## We need the -1 in the split!  Otherwise, we can't feed it into
    ## @compressed as a hash, since split() truncates empty columns.
    return split(/\t/, $sig, -1);
}




## Add other distinguishing flags to each entry's hashref.  For
## example, to distinguish NSF from non NSF entries, we plug a flag
## into the hashref after comparing against the granting agency.
sub AddOtherFlags {
    my @results = @_;
    for my $r (@results) {
	if (uc($r->{GRANTING_AGENCY}) eq "NSF") {
	    $r->{IS_NSF} = "1";
	}
	else {
	    $r->{IS_NSF} = "0";
	}
    }
    return @results;
}


sub BoundByLimits {
    my ($start, $limit, @results) = @_;
    return @results[$start-1 .. min($start - 1 + $limit - 1, $#results)];
}






######################################################################

######################################################################
## Small utility functions

## Given a string containing email addresses, surround each with a
## mailto href tag.
sub GetEmailLinkedString {
    my $str = shift;
    if (! $str) { return $str; }
    $str =~ s/(
              [\w\d\-\_\.]+        ## the user's email name
              @                    ## followed by the "at" symbol
              [\w\d\-\_\.]+        ## and host name,
              )

              (?=[.!:,\(\)\[\]]    ## with a lookahead assertion on
	                           ## ending characters
                  |                   
                  $
              ) 
             /<a href=mailto:$1>$1<\/a>/xg;
    return $str;
}


## Change all undefined elements of a list to empty strings.
sub pacifyUndefs {
    return map {$_ || ''} @_;
}



## Given two references to arrays, returns a new array where the
## elements have been ruffle-shuffled together.
sub zip {
    my ($l1, $l2) = @_;
    my @new_array;
    for(my $i = 0; $i < @$l1; $i++) {
	push @new_array, $l1->[$i];
	push @new_array, $l2->[$i];
    }
    return @new_array;
}


## Removes whitespaces from both sides of a string.
sub strip {
    my ($str) = @_;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}


## Takes the minimum of two numbers.
sub min {
    my ($x, $y) = @_;
    return $x < $y ? $x : $y;
}


## "clamps" $x between a $low and $high bound, to make sure $x is
## within those bounds.
sub clamp {
    my ($x, $low, $high) = @_;
    if ($x < $low) {
	return $low;
    }
    if ($x > $high) {
	return $high;
    }
    return $x;
}



## Escape the characters in an URL to make them safe to transport
sub urlEscape {
    my ($string) = @_;
    $string=~s/(\W)/sprintf("%%%02x",ord($1))/eg;
    return $string;
}


## Tom Christiansen's urlify program, converted to a function.  This
## takes a string and introduces HTTP anchors when it sees any URLs.
## See http://cpan.valueclick.com/doc/FMTEYEWTK/regexps.html for
## details about this neat function.
##
## Nov 3 2006. Changed showing the URL in the Comment Colomn from $1 to 
## Link to site; otherwise the table is too wide. 
sub urlify {
    my $string = shift;
    if (! $string) { return $string; }
    my $urls = '(' . join ('|', qw{ http telnet gopher file wais ftp } ) . ')';
    my $ltrs = '\w';
    my $gunk = '/#~:.?+=&%@!\-';
    my $punc = '.:?\-'; 
    my $any = "${ltrs}${gunk}${punc}";

    $string =~ s{
        \b                          # start at word boundary
        (                           # begin $1  {
          $urls     :               # need resource and a colon
          [$any] +?                 # followed by on or more
                                    #  of any valid character, but
                                    #  be conservative and take only
                                    #  what you need to....
        )                           # end   $1  }
        (?=                         # look-ahead non-consumptive assertion
                [$punc]*            # either 0 or more puntuation
                [^$any]             #   followed by a non-url char
            |                       # or else
                $                   #   then end of the string
        )
	}{<a HREF="$1">Link to site</a>}igox;
    return $string;
}
