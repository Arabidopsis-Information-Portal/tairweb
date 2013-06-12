#!/bin/env perl

$incoming = $ENV{'QUERY_STRING'};
if ($incoming eq "") {
print "Content-type: text/html\n\n<html><head>Error</head><h1>Error Empty Query</h1></html>\n";
exit;
}

# Create a user agent object
use LWP::UserAgent;
$ua = new LWP::UserAgent;
$ua->agent("TAIRWWW/0.1");

if ($incoming =~ /Symbols/) {
	$OKURL = "http://mutant.lse.okstate.edu/frontmutant/one_symbol_result.asp";
	$incoming =~ /(.*)&Symbols/;
	$incoming = $1;
} else {
	$OKURL = "http://mutant.lse.okstate.edu/frontmutant/special_locus_result.asp";
}

# Create a request
my $req = new HTTP::Request POST => $OKURL;
$req->content_type('application/x-www-form-urlencoded');
$req->content("$incoming");

# Pass request to the user agent and get a response back
my $res = $ua->request($req);

# Check the outcome of the response

print "Content-type: text/html\n\n";
if ($res->is_success) {
    $output = $res->content;
    $output =~ s#SRC=\"#SRC=\"http://mutant.lse.okstate.edu/#g;
    $output =~ s#HREF=\"#HREF=\"http://mutant.lse.okstate.edu/#g;
    $output =~ s#/../#/#;
    print $output;
} else {
    print "okstate-mutant: query to OK State was not successful.\n";
}

exit;
