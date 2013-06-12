#!/bin/env perl
package search;

use strict;
use fileiter;
use format;


## Searching module

## Attempt to perform the query, and return a list of the results.
sub GetQueryResults($$$$) {
    my ($stype, $qstring, $db_source, $maximum_results_requested) = @_;
    my $linesearcher = ConstructLineSearcher($stype, $qstring);
    if (! $linesearcher) { 
	return (); 
    }
    my $filesearcher = MakeFileSearcher($linesearcher, $maximum_results_requested);
    my @results = $filesearcher->($db_source);
    return @results;
}



sub GetStreamingQueryResults($$$) {
    my ($stype, $qstring, $db_source) = @_;
    my $linesearcher = ConstructLineSearcher($stype, $qstring);
    if (! $linesearcher) { 
	return undef; 
    }
    my $filesearcher = MakeFileSearcherAsIterator($linesearcher);
    my $resultiterator = $filesearcher->($db_source);
    return $resultiterator;
}



## Returns a predicate function that, given a line, says if that line
## should be a search hit.  If invalid parameters are passed, returns undef.
sub ConstructLineSearcher($$) {
    my ($stype, $qstring) = @_;
    if (! CleanQueryString($qstring)) { 
	return undef; 
    }
    my %searches = 
	(any => MakeAnySearch($qstring),
	 accession => MakeColumnSearcher($ACCESSION_COL, $qstring),
	 locus => MakeColumnSearcher($LOCUS_COL, $qstring),
	 other_gene_names => MakeColumnSearcher($OTHER_GENE_NAMES_COL, $qstring),
	 lead_pi => MakeColumnSearcher($PI_COL, $qstring),
	 proposal => MakeColumnSearcher($PROPOSAL_NAME_COL, $qstring),
	 );
    if (exists $searches{$stype}) {
 	my $linesearcher = $searches{$stype};
	return $linesearcher;
    }
}




######################################################################
## Given some line predicate, returns a function that returns all
## lines that satisfy that predicate.
sub MakeFileSearcher {
    my ($predicate, $maximum_results_requested) = @_;
    return sub {
	my ($filename) = @_;
	my @results;
	open(IN, $filename);
	while (defined(my $line = <IN>) && 
	       (@results <= $maximum_results_requested)) {
	    if ($predicate->($line)) {
		push @results, $line;
	    }
	}
	close(IN);
	return @results;
    }
}


## Given some line predicate, returns a function that, when called,
## returns another function that can be called successively to return
sub MakeFileSearcherAsIterator {
    my ($predicate) = @_;
    return sub {
	my ($filename) = @_;
	return fileiter->new($filename, $predicate);
    }
}


## Search throughout the line for the query string.
sub MakeAnySearch {
    my ($qstring) = @_;
    my @regexes = MakeSearchingRegexes($qstring);
    return sub {
	for my $re (@regexes) {
	    if ($_[0] =~ m/$re/) { return 1; }
	}
    }
};


## Given a column to search for, creates a function that knows how to
## search on that column.
sub MakeColumnSearcher {
    my ($col, $qstring) = @_;
    my @regexes = MakeSearchingRegexes($qstring);
    return sub {
	my ($line) = @_;
	my $column_info = (split("\t", $line, -1))[$col];
	for my $re (@regexes) {
	    if ($column_info =~ m/$re/) { return 1; }
	}
    }
}




## Given a query string of elements delimited by semicolons, returns an
## array of regular expressions that matches on any element.
sub MakeSearchingRegexes {
    my ($qstring) = @_;
    my @loci = grep {$_} map { CleanQueryString($_) } split(/;/, $qstring);
    return map {qr/$_/i} @loci;
}





## Remove weird stuff from the query string, but leaving the
## interesting regular expression characters alone.
sub CleanQueryString {
    my $qstring = shift;
    $qstring =~ s/[^A-Za-z0-9\- \.\*\?\^\$\|\/]//g;
    $qstring =~ s/\//\//g;        ## We escape the foward slashes
    $qstring =~ s/^\s+(.*)/$1/;   ## stripping out leading whitespace
    $qstring =~ s/(.*?)\s+$/$1/;  ## stripping off trailing whitespace
    return $qstring;
}


1;
