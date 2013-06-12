#!/bin/env perl

#############################################################################
#       Script name :           RestCutList                                 #
#       Programmer :            Shuai Weng                                  #
#       Date :                  Feb. 1998                                   #
#       Comment :    This cgi script is used to present cut list for        # 
#                    the specified restriction enzyme                       #
#                    usage: RestCutList?id=17876&enzyme=BfiI (for atdb)     #
#                           RestCutList?id=17876&enzyme=BfiI&db=sgd         #
# 2001/12/14  -Changed the hard coded pathes by  $ENV{'DOCUMENT_ROOT'}      #
#              by Guanghong Chen                                            #
#############################################################################

use strict;

use CGI;



require '../format_tairNew.pl';
require '../untaint.pl';

$|=1;

my $TAIR_RE_LINK='http://www.arabidopsis.org/servlets/TairObject?type=restrictionenzyme&name';
my $PROJECT_ROOT =  $ENV{'DOCUMENT_ROOT'} . "/..";

my $dir = "/tmp"; #$PROJECT_ROOT . "/tmp/patmatch";

my $query = new CGI;

my $id = untaint($query->param('id'));
my $enzyme = untaint($query->param('enzyme'));
my $db;

if ($query->param('db')){
  $db = untaint($query->param('db')); 
}

if (!$db) {
    $db = "atdb";
}

my $infile = "$dir/restriction.tmp.$id";
open(IN, "$infile") || die "RestCutList: Can't open '$infile' for reading:$!\n";

my $i = 0;
my $cutnum = 0;

my ($seqlen, $seqname, $rest_enzyme, $pat, $offset, $overhang, $num1, $num2, $OFFSET, $OVERHANG, $PATTERN, @NUM1, @NUM2, @cut_num);
while (<IN>) {
    chop;    
    ($rest_enzyme, $pat, $offset, $overhang, $num1, $num2) = split(/ /);
    if ($rest_enzyme eq "AAAAlength") {
	$seqlen = $offset;
	next;
    }
    if ($rest_enzyme eq "AAAAseqname") {
	$seqname = $pat;
	next;
    }
    if ($rest_enzyme eq $enzyme) {
	$OFFSET = $offset;
	$OVERHANG = $overhang;
	$PATTERN = $pat;
	if ($num1 < $num2) {  
	     $NUM1[$i] = $num1;
	     $NUM2[$i] = $num2;
	     $cut_num[$cutnum++] = $num1 + $offset;
	     $i++;
	}
	else { 
	    my $found = 0;
	    for (my $j = 0; $j <= $#NUM1; $j++) {
		if ($num1 == $NUM2[$j] || $num2 == $NUM1[$j]) {
		    $found = 1;
		    last;
		}
	    }
	    if ($found == 0) {
		$cut_num[$cutnum++] = $num2 + $offset + $overhang;
	    }   	     
	}
    }       
}

my @sorted_cut_num = sort{ $a <=> $b }(@cut_num);
unshift(@sorted_cut_num, "0");
push(@sorted_cut_num, $seqlen);

### print HTML header stuff

print $query->header;

if ($db eq "atdb") {

    if ($seqname eq "unknown") {
	print $query->start_html(-title=>"Fragment Sizes Cut with $enzyme",
 	   	         -BGCOLOR=>"#ccffcc");
    }
    else {
	print $query->start_html(-title=>"Fragment Sizes for $seqname Cut with $enzyme", -BGCOLOR=>"#ccffcc");
    }
    print "<CENTER><TABLE CELLSPACING=10><TR>";
    print "<TD VALIGN=TOP><IMG ALIGN=ABSMIDDLE BORDER=0 ALT=\"TAIR Home\" SRC=\"/images/tairsmall.gif\"></TD>";
    if ($seqname eq "unknown") {
#	print "<TD VALIGN=BOTTOM><H1>Fragment Sizes Cut with <a href=\"http://genome-www3.stanford.edu/cgi-bin/Webdriver?MIval=atdb_motifs_max&name=$enzyme\">$enzyme</a></H1></TD>";
	    #print "<TD VALIGN=BOTTOM><H1>Fragment Sizes Cut with <a href=\"$TAIR_RE_LINK=".uc($enzyme)."\">$enzyme</a></H1></TD>";
	    print "<TD VALIGN=BOTTOM><H1>Fragment Sizes Cut with $enzyme</H1></TD>";
    }
    else {
	    #print "<TD VALIGN=BOTTOM><H1>Fragment Sizes for $seqname Cut with <a href=\"$TAIR_RE_LINK=".uc($enzyme)."\">$enzyme</a></H1></TD>";
	    print "<TD VALIGN=BOTTOM><H1>Fragment Sizes for $seqname Cut with $enzyme</H1></TD>";
    }
    print "</TR></TABLE></CENTER>";
}
else {
    if ($seqname eq "unknown") {
	print $query->start_html(-title=>"Fragment Sizes Cut with $enzyme", -BGCOLOR=>"#FFFFF0");
    }
    else {
	print $query->start_html(-title=>"Fragment Sizes for $seqname Cut with $enzyme", -BGCOLOR=>"#FFFFF0");
    }
    print &header_gif_sm; 
    if ($seqname eq "unknown") {
	print &page_title("Fragment Sizes Cut with <a href=\"http://genome-www.stanford.edu/cgi-bin/dbrun/SacchDB?find+Motif+$enzyme\">$enzyme</a>");
    }
    else {
	print &page_title("Fragment Sizes for $seqname Cut with <a href=\"http://genome-www.stanford.edu/cgi-bin/dbrun/SacchDB?find+Motif+$enzyme\">$enzyme</a>");
    }
    print &divider75;
    print &buttons_bar;
    print &divider75;
}

print "<center><table>";
print "<tr><th align=right><font color=red>offset \(bp\)</font> : </th><td align=left>$OFFSET</td></tr>";
print "<tr><th align=right><font color=red>overhang \(bp\)</font> : </th><td align=left>$OVERHANG</td></tr>";
print "<tr><th align=right><font color=red>recognition sequence</font> : </th><td align=left>$PATTERN</td></tr>";
print "</table></center>";

print "<p><center><table border=3>";
print "<tr align=center>";
print "<th>Cut Site</th>";
print "<th>Fragment Size (bp)</th>";
print "</tr>";

$i = 0;
my ($pre_cut,$cut_size, @SIZE);

foreach my $cut (@sorted_cut_num) {
    if ($i == 0) {
	print "<tr align=center>";
	print "<td>$cut</td>";
	print "<td><br></td></tr>";
    }
    else {
	$cut_size = $cut - ${pre_cut};
        push(@SIZE, $cut_size);
	print "<tr align=center>";
	print "<td><br></td>";
	print "<td>$cut_size</td></tr>";
	print "<tr align=center>";
	print "<td>$cut</td>";
	print "<td><br></td></tr>";
    }
    $i++;
    $pre_cut = $cut;
}
print "</table></center>";

my @reversed_sorted_SIZE = reverse( sort{ $a <=> $b }(@SIZE) );

print "<p><center><table>";
print "<tr align=center>";
print "<th>Sorted Fragment Size (bp)</th>";
print "</tr>";


foreach my $size ( @reversed_sorted_SIZE ) {
    print "<tr align=center>";
    print "<td>$size</td></tr>";
}
print "</table></center>";

if ($db eq "atdb") {
    if ($seqname eq "unknown") {
	print "<p><center><a href=\"/cgi-bin/patmatch/RESTmap?id=$id\">Restriction Map</a></center>";
    }
    else {
	print "<p><center><a href=\"/cgi-bin/patmatch/RESTmap?id=$id\">Restriction Map of $seqname</a></center>";
    }
}
else {
    if ($seqname eq "unknown") {
	print "<p><center><a href=\"/cgi-bin/patmatch/RESTmap?id=$id\">Restriction Map</a></center>";
    }
    else {
	print "<p><center><a href=\"/cgi-bin/patmatch/RESTmap?id=$id\">Restriction Map of $seqname</a></center>";
    }
}

print "</BODY></HTML>";

    








