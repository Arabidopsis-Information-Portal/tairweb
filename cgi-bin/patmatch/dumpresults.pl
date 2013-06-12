#!/bin/env perl

use CGI;


# Constants
my $config_file = "newpatmatch.conf";
my $indexdir = "";
my $datadir ="";
my $tmpdir = "";
my %databases= ();
my $debug = "";

my $cgi = CGI -> new();

my $file = $cgi -> param("results");

# print html stuff
#
print $cgi -> header('text/html');
print $cgi -> start_html();

#print "File: $file\n";

# Read configuration file
#
open (CONF, "<$config_file") || die "Can't read newpatmatch configuration file $config_file";
while (<CONF>) {
    chomp;
    my $line = $_;
    my $tag;
    if ($line =~ /^\#/) { next; }

    if ($line =~ /^indexfiledir/i) { ($tag, $indexdir) = split /\t/, $line; }
    if ($line =~ /^datadir/i) { ($tag, $datadir) = split /\t/, $line;  }
    if ($line =~ /^tempdir/i)  { ($tag, $tmpdir) = split /\t/, $line; }
    if ($line =~ /^dataset/i) {
        my ($tag, $type, $file, $desc) = split /\t/, $line; $databases{"$desc ($type)"} = $file;
    }
    if ($line =~ /^debug/i) { ($tag, $debug) = split /\t/, $line; }
}
close (CONF);

#don't trust the settings in the conf file since the relative paths don't work, so beware using any of the other paramters from that 
#file, really, we shouldn't be using that file at all, but for now we'll let it go
#$tmpdir = "$ENV{DOCUMENT_ROOT}/../tmp/patmatch";


# clean $file so that no other directory can be accessed
$file =~ s/\.\.//g;
$file =~ s/\///g;

if (!$file eq "") {
    if (-e "$tmpdir/$file") {
	
	open (FILE, "<$tmpdir/$file") || die "Can't open $file... zut!";
	print "<PRE>";
	while (<FILE>) {
	    
	    # translate spaces to tabs for better excel compatility
	    s/ /\t/g;
	# print contents of file
	    print "$_";
	    
	}
	
	print "</PRE>";
    }
}
else {
  
    print "<H3>Sorry, the results were not found. Please try again.\n</H3>";

}

print $cgi -> end_html();




