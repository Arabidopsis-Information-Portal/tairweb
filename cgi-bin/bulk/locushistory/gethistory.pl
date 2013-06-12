#!/bin/env perl

# cgi script that returns locus history for locus accessions.
#
#
# Lukas Mueller, April 10, 2002
# Iris Xu, 20050801, append chloro and mito loci to locushistory.txt file.
#

use strict;
use CGI;
require "../../format_tairNew.pl";

# filename for reading locushistory
my $datafile = "$ENV{DOCUMENT_ROOT}/../data/locushistory/locushistory.txt";

# link to tair
my $tairlink = "http://$ENV{SERVER_NAME}/servlets/TairObject?type=locus&amp;name=";

# version info
my $version = "1.0-20020426";
my $NUM_COLUMNS=7;

# hashes to store infos
my %hash;

# get cgi parameters
#
my $cgi = CGI -> new ();
my $lociStr = $cgi -> param("loci");

my $output_type = $cgi -> param("outputtype");
my $list = $cgi -> param("list"); # command that lists all obsoleted if equal to 'obsoleted' or all in use if equal to 'inuse'


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


$lociStr = uc($lociStr);     # convert to uppercase

my @loci = grep {$_} split /\W+/, $lociStr;


if ($list) { load_data(); output_list(); exit(); }


# check for errors -- was anything entered at all?
#
if (!@loci) { output_error("You did not enter any loci information", "Please enter loci accessions (e.g. At1g01030) in the textfield or upload a file with locus information"); exit(); }

# check if there are more than 1000 loci -- we revert to text output in any case.
#
if (scalar(@loci)>1000) { $output_type = "text"; } 

# build hash from file
#
load_data();


if ($output_type eq "text") { output_text(); }
else {
    output_html();
}



sub load_data {

# Build hash
#
    open (F, "<$datafile") || die "Can't find file $datafile.";
    
    while (<F>) {
	
	chomp;
	my ($pub_locus, @rest);
	($pub_locus, @rest) = split /\t/;

	if (! $pub_locus) { $pub_locus=$rest[0]; }
	push @{$hash{$pub_locus}}, join "\t", @rest;

    }
    
    close(F);
}

sub mysort {
    my @A=split /\t/, $a;
    my @B=split /\t/, $b;
    
   ### print "A: $A[1], B: $B[1]\n";
   # we want TIGR data always first
   #if($A[1] eq "TIGR" && $B[1] eq "TIGR" ){
   #    return $B[3] <=> $A[3];
  # }elsif ($A[1] eq "TIGR" && $B[1] ne "TIGR") {
  #     return  $A[1]>$B[1] ;
  # }else {
  #     return $B[1]>$A[1];
  # }
    # was sorted by date 
    return $B[3] <=> $A[3];
}
    
sub output_html {
    print "Content-type: text/html\n\n";
    
    tair_header("Locus History");
    
    
    print "<TABLE border=0 width=602>\n";
    print "<TR><TD><span class=header>Locus History Information</span><br><br>\n";
    print "</TABLE>\n";
    
    print "<TABLE border=0 width=598 cellpadding=4>\n";
    print "<TR bgcolor=#b0b0b0><TD rowspan=2>Locus</TD><TD rowspan=2>Current Status</TD><TD colspan=4>Modification</TD></TR>\n";
    print "<TR bgcolor=#b0b0b0><TD>Who</TD><TD >Date</TD><TD>Modification<BR>Comments</TD><TD>Loci Involved in Modification</TD></TR>\n";
    
    my $locus;
    my $counter=0;
    my $bgcolor="#F4F9FF";
    foreach $locus (@loci) {
	$counter++;
	if ($counter % 2) { $bgcolor="#f0f0f0";} else { $bgcolor="#e0e0e0"; }
	if (exists($hash{$locus})) {
	    my (@unsortedlist) = @{$hash{$locus}};
	    # sort list according to modification date
	    my (@list) = sort mysort @unsortedlist;
	    print "<TR bgcolor=$bgcolor><TD rowspan=\"".scalar(@list)."\" valign=top>";
	    print "<a href=$tairlink$locus>$locus</TD><TD rowspan=\"".scalar(@list)."\" valign=top>";
	    #if ($list[0] !~ /obsolete/ && $list[0] !~ /delet/ && $list[0]!~/replaced/i && $list[0]!~/removed/i) { print "in use"; }
	    my @fields = split(/\t/,$list[0]);
		my $sz = scalar @fields;
	    if((length($fields[0]) < 1 && $fields[2] !~ m/(merge)?obsolete/g) || (length($fields[0]) >=1 && $fields[0] !~ /obsolete/))
	    { print "in use";}
	    else { print "obsolete"; }
	    print "</TD>";
	    foreach my $element (@list) {
		my ($tigrinternal, $who, $modification, $date, @with) = split /\t/, $element;
		print "<TD bgcolor=$bgcolor>$who</TD><TD bgcolor=$bgcolor>$date</TD><TD bgcolor=$bgcolor>$modification</TD><TD bgcolor=$bgcolor>@with</TD></TR>\n";
	    }
	    
	}
	else {
	    print "<TR bgcolor=$bgcolor><TD>$locus</TD><TD>not in use</TD><TD>&nbsp;</TD><TD>&nbsp;</TD><TD>&nbsp;</TD></TR>";
	}
    }
    print "</TABLE>\n";
    #print "<TABLE width=602><TR><TD><FONT size=1>v. $version</font></TABLE>\n";    
    tair_footer();

}

sub output_text {
  print "Content-type: text/plain\n\n";
  foreach my $locus (@loci) { 
    if (exists($hash{$locus})) {
      print "$locus\t";
      my (@unsortedlist) = @{$hash{$locus}}; 
      # sort list according to modification date 
      my (@list) = sort mysort @unsortedlist; ; 
      if ($list[0] !~ /obsolete/ && $list[0] !~ /delet/ && $list[0]!~/replaced/i && $list[0]!~/removed/i) { 
	print "IN USE\t"; 
      } 
      else { 
	print "OBSOLETED\t"; 
      } 
      print "\n";
      foreach my $element (@list) { 
	my ($tigrinternal, $who, $modification, $date, @with) = split /\t/, $element; 
	print "\t$locus\t$who\t$date\t$modification\t@with\n"; 
      } 
    
    }
    else { 
      print "$locus\tNOT IN USE\n";
    }
  }
}

sub output_list {
  print "Content-type: text/plain\n\n";
  foreach my $locus (keys %hash) {
    if ($locus && !($locus eq "ALL") ){ 
       my $outputstr = "";
       $outputstr = "$locus\t";
       my (@unsortedlist) = @{$hash{$locus}}; 
       # sort list according to modification date 
       my (@list) = sort mysort @unsortedlist; 
       if ($list[0] !~ /obsoleted/ && $list[0] !~ /delet/ && $list[0]!~/replaced/i && $list[0]!~/removed/i) { 
         $outputstr .= "IN USE\t"; 
       } 
       else { 
         $outputstr .= "OBSOLETED\t"; 
       } 
       if ($list eq "inuse" && $outputstr =~ /IN USE/) { print "$locus\tIN USE\n"; }
       if ($list eq "obsoleted" && $outputstr =~ /OBSOLETED/) { print "$locus\tOBSOLETED\n"; }
   }
}
}


  
sub output_error {
  my $title = shift;
    my $message = shift;
    print "Content-type: text/html\n\n";

    tair_header("Locus History");


    print "<TABLE border=0 width=602>\n";
    print "<TR><TD><span class=header>Error: $title</span><br><br>\n";
    print "$message<BR><BR><BR><BR>\n";
    print "<a href=\"/tools/bulk/locushistory/\">Go back to search page</a><BR><BR><BR>";
    print "</TABLE>\n";

    tair_footer();

}




