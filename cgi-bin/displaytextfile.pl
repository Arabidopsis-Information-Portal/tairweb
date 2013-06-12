#!/bin/env perl 

use CGI qw(:standard);


$mycgi = new CGI;

print header;

print "\<HTML\>\<HEAD\>\<TITLE\>Result\</TITLE\>";
print "\<SCRIPT SRC=\"/js/navbar.js\"\>\</SCRIPT\>";
print "<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/main.css\" >   ";
print "</HEAD><BODY BGCOLOR = \"f5f9ff\"> ";

print "\<!-- HEADER using external JavaScript file --\>";

print "\<script language=\'JavaScript\'\>";
print "var highlight = 0; var helpfile=\"\" ";
print "\</script\>";
print "\<script language=\'JavaScript\' SRC=\'/js/header\'\>";
print "\</script\>\<p\>";

print "\<!-- End of header --\>";

$base = "";

@fields = $mycgi -> param;

$whichfile = $mycgi -> param(@fields[0]);

for ($i=1; $i <= (scalar(@fields)-1); $i++)
{  $searchterms[$i] = $mycgi -> param($fields[$i]);
}

open (IN, "<$whichfile") || die "Can't open $whichfile";
@file = <IN>;
close(IN);
chomp(@file);

print "<CENTER><TABLE WIDTH=\"602\"><TR><TD>";
print STDOUT "<P>Return to <a href=\"javaScript:{history.back()}\">results page</a></P>";

print "Search Terms: ";
foreach $searchterm (@searchterms) { print $searchterm." ";  } 
print "<P>";
print "<FONT SIZE=2> ";

$text = join "\t", @file;

$doctext = $text;

# The following lines would be used for displaying html files.
# Here they are commented out.
#
#$doctext =~ s/(\<BODY\>)(.*)(\<\/BODY\>)/\2/;     # Take body only
#$doctext =~ s/(.*)(X\-UID\: [0-9]{1,6})(.*)/\3/;  # Copy only stuff after X-UID:
#$doctext =~ s/\<.+?\>//g;   # remove all HTML tags

for ($i = 1; $i <= scalar(@searchterms)-1; $i++)
{
   $coucou = $searchterms[$i];
   $doctext =~ s/($coucou)/\<B\>\1\<\/B\>/ig;
}

@newfile = split /\t/, $doctext;

foreach $line (@newfile)
{   
    #if ($line ne "") { 
        print "$line<BR>"; 
    #}
}
print "</TD></TR></TABLE></CENTER>";
print end_html;




