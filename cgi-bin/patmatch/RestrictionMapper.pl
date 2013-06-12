#!/bin/env perl

#####################################################################
#          Script Name:       RestrictionMapper                     #
#          Author:            Shuai Weng                            #
#          Date:              Jan. 1998                             #
#          Comment:  This script is used to present a search form   #
#                    for AtDB Restriction Analysis and process the  #
#                    result data                                    #
#####################################################################
# 
# Modifications:
#
# 2001/01/29 - Changed to new TAIR interface;
#              Added use of ENV{} variables where applicable; 
#              by Lukas Mueller  
# 2001/07/20 - Added new TAIR footer.js
# 2001/12/14 - Use  $ENV{'DOCUMENT_ROOT'} to avoid the hard code path
#              Fixed a bunch of bugs 
#              by Guanghong Chen
# 2002/04/23 - Turn on -w flag, use strict, use FileHandle;
#              Use the cross project format_tair.pl 
#####################################################################
use strict;
use CGI;
use FileHandle;

require '../format_tairNew.pl';
require '../untaint.pl';

$| = 1;


my $PROJECT_ROOT = $ENV{'DOCUMENT_ROOT'} . "/.."; #"/home/arabidopsis"; #$ENV{'DOCUMENT_ROOT'} . "/..";

my $dir = $ENV{'SCRIPT_NAME'};
$dir =~ s/\/[A-Za-z.]*?$//g; 

my $dataDir = $PROJECT_ROOT . "/data/PATMATCH"; 
my $tmpdataDir = "/tmp"; #$PROJECT_ROOT . "/tmp/patmatch";

my $seqfile = "$dataDir/GB.seqlist";

my ($seqname,  $sequence,  $enzyme, $beg, $datafile, $pattern, %LENGTH, $locus, $access, $other, $seqdatafile, $display);

my $query = new CGI;  

  $seqname = $query->param('seqname');
  if ($seqname){
    $seqname =~ s/^ *(.+) *$/$1/;
  }
  
  $sequence = $query->param('sequence');
  if ($sequence){
    if ($sequence =~ /^[\12\15]+$/) {
      $sequence = "";
    }
    
    $sequence =~ s/[^A-Za-z]//g;
  }
  
  $enzyme = $query->param('enzyme');
  if (!$enzyme) {
    $enzyme = "all";
  }
  $beg = $query->param('beg');
  if (!$beg) {
    $beg = 1;
  }


#&present_form unless $query->param();
if (!$sequence && !$seqname) {
  &present_form;
}
else {
  if ($sequence) {
    $seqname = "unknown";
    $seqdatafile = "$tmpdataDir/${seqname}\.dna.tmp.$$";
    $sequence =~ s/[^A-Za-z]//g;
    
    open(SEQ, ">$seqdatafile") || err_report("Cannot open $seqdatafile, $!\n");
    print SEQ ">$seqname\n";
    print SEQ "$sequence\n";
    close (SEQ);
    
    $LENGTH{$seqname} = length($sequence);
  }
  else {
    my $found = 0;
    if ($seqname =~ /^(.+)\*$/) {
      $pattern = "\U$1";
      $pattern = untaint($pattern);
      #undef @matchList;
      my  @matchList = ();
      
      open(SEQFILE, "$seqfile") || 
	err_report("Cannot open: $seqfile, $!");
      while(<SEQFILE>) {
	chop;
	if ("\U$_" =~ /^$pattern/) {
	  push(@matchList, $_);
	}    
      }
      close (SEQFILE);
      
      
      if ($#matchList < 0) {
	err_report("No sequences were found in TAIR with the name that begins with $pattern");
      }
      elsif ($#matchList == 0) {
	$seqname = $matchList[0];
      }
      else {
	push(@matchList, $pattern);
	&present_subform(@matchList);
	exit (0);
      }
    } 
    else {
      $seqname = untaint($seqname);
    }
    
    if ($seqname =~ /^CSHL/) {
      $datafile = "$dataDir/CSHLPrel.seq";
    }
    else {
      $datafile = "$dataDir/GenBank.seq";
    }
    
    $seqdatafile = "$tmpdataDir/${seqname}\.dna.tmp.$$";
    
    open(DATA, "$datafile") 
      || err_report("Cannot open: $datafile, $!");
    open(SEQ, ">$seqdatafile") 
      || err_report("Cannot open: $seqdatafile, $!");
    
    while(<DATA>) {
      chop;
      if (/^>[^:]+:(.+)$/) {
	($locus, $access, $other) = split(/ /, $1);
      }
      elsif ("\U$locus" eq "\U$seqname" || "\U$access" eq "\U$seqname"){
	if ("\U$locus" eq "\U$seqname") {
	  print SEQ ">$locus\n";
	}
	else {
	  print SEQ ">$access\n";
	}
	print SEQ "$_\n";
	$LENGTH{$seqname} = length($_);
		$found = 1;
	last;
      }
    }
    close(DATA);
    close (SEQ);
    
    if ($found == 0) {
      &err_report("No sequences were found in TAIR with the name $seqname. You may try to include the <b>wildcard character</b> \(\*\) at the end of the sequence name.");
    }
  }
  my $tmpoutfile = "$tmpdataDir/restriction.tmp.$$.tmp";
  my $tempoutfile = "$tmpdataDir/restriction.tmp.$$.temp";
  my $outfile1 = "$tmpdataDir/restriction.tmp.$$";
  my $outfile2 = "$tmpdataDir/restriction.tmp.NONrestriction.tmp.$$";
  
  my $fh = FileHandle->new();
  
  if ($enzyme =~ /^3/) {
    $display = "3";
    open($fh,"$dataDir/rest_enzymes.3") || err_report("Cannot open DNA patterns");
  }
  elsif ($enzyme =~ /^5/) {
    $display = "5";
    open($fh,"$dataDir/rest_enzymes.5") || err_report("Cannot open DNA patterns");
  }
  elsif ($enzyme =~ /^blunt/) {
    $display = "blunt";
    open($fh,"$dataDir/rest_enzymes.blunt") || err_report("Cannot open DNA patterns");
  }
  elsif ($enzyme =~ /^cut once/) {
    $display = "once";
    open($fh,"$dataDir/rest_enzymes") || err_report("Cannot open DNA patterns");
  }
  elsif ($enzyme =~ /^cut twice/) {
    $display = "twice";
    open($fh,"$dataDir/rest_enzymes") || err_report("Cannot open DNA patterns");
  }
  elsif ($enzyme =~ /^Six-base cutter/) {
    $display = "6base";
    open($fh,"$dataDir/rest_enzymes.6base") || err_report("Cannot open DNA patterns");
  }
  else {
    $display = "all";	
    open($fh,"$dataDir/rest_enzymes") || err_report("Cannot open DNA patterns");
  }
  my ($patfile, $rest_enzyme, $offset, $pat, $overhang, %OFFSET, %OVERHANG, %PAT);
  while(<$fh>) {
    chop;
    ($rest_enzyme, $offset, $pat, $overhang) = split(/ /);
    
    $OFFSET{$rest_enzyme} = $offset;
    $OVERHANG{$rest_enzyme} = $overhang;
    $PAT{$rest_enzyme} = $pat;
    $patfile = "$tmpdataDir/tmp.pat.$$";
    
    open(TMP,">$patfile");
    print TMP $pat;
    close(TMP);
    
    open(OUT, ">>$tmpoutfile") || 
      err_report("Cannot open: $tmpoutfile, $!");
    print OUT "\>\>$rest_enzyme:\n";
    close (OUT);
        
    system("/bin/nice -10 $ENV{'DOCUMENT_ROOT'}/cgi-bin/patmatch/scan_for_matches_50M -c $patfile < $seqdatafile >> $tmpoutfile");    
  }

  $fh->close();
  
  unlink $patfile;
#  system("rm $patfile 2>/dev/null");
  
  ######### process search result:
  
  system("tr '\12' '\15' < $tmpoutfile > $tempoutfile");
  open(IN, "$tempoutfile") || err_report("Cannot open: $tempoutfile, $!");
  open(OUT1, ">$outfile1") || err_report("Cannot open: $outfile1, $!");
  open(OUT2, ">$outfile2") || err_report("Cannot open: $outfile2, $!");
  
  print OUT1 "AAAAlength no $LENGTH{$seqname} 0 0 0\n";
  print OUT1 "AAAAseqname $seqname 0 0 0 0\n";
  while(<IN>) {
    my @list = split(/>>/);
    shift @list;
    foreach my $list (@list) {
      my @item = split(/\15/, $list);
      if ($#item == 0) {
	chop $item[0];
	print OUT2 "$item[0]\n";
      }
      else {
	$rest_enzyme = shift (@item);
	chop ($rest_enzyme); # remove the padding :
	#$ENZYME[$hitnum] = $rest_enzyme; only used once here
	my $watson_cut = 0;
	my $crick_cut = 0;
	foreach my $item (@item) {
	  if ($item =~ /^>.+:\[([0-9]+)\,([0-9]+)\]$/ ) {
	    if ($1 < $2) {
	      $watson_cut++;
	    }
	    elsif ($1 > $2) {
	      $crick_cut++;
	    }
	  }
	}
	if ($enzyme =~ /^cut once/) {
	  if ( ($watson_cut == 1 && $crick_cut <= 1) ||
	       ($crick_cut == 1 && $watson_cut <= 1)     ) {
	    foreach my $item (@item) {
	      if ($item =~ /^>.+:\[([0-9]+)\,([0-9]+)\]$/ ) {
		print OUT1 "$rest_enzyme $PAT{$rest_enzyme} $OFFSET{$rest_enzyme} $OVERHANG{$rest_enzyme} $1 $2\n";
	      }
	    }
	  }
	}
	elsif ($enzyme =~ /^cut twice/) {
	  if ( ($watson_cut == 2 && $crick_cut <= 2) ||
	       ($crick_cut == 2 && $watson_cut <= 2)     ) {
	    foreach my $item (@item) {
	      if ($item =~ /^>.+:\[([0-9]+)\,([0-9]+)\]$/ ) {
		print OUT1 "$rest_enzyme $PAT{$rest_enzyme} $OFFSET{$rest_enzyme} $OVERHANG{$rest_enzyme} $1 $2\n";
	      }
	    }
	  }	
	}
	else {
	  foreach my $item (@item) {
	    if ($item =~ /^>.+:\[([0-9]+)\,([0-9]+)\]$/ ) {
	      print OUT1 "$rest_enzyme $PAT{$rest_enzyme} $OFFSET{$rest_enzyme} $OVERHANG{$rest_enzyme} $1 $2\n";
	    }
	  }
	}    
      }       
    }
  }
  close (IN);
  close (OUT1);
  close (OUT2);
  
  #system("rm $tmpoutfile $tempoutfile $seqdatafile 2>/dev/null"); 
  unlink $tmpoutfile; 
  unlink $tempoutfile;
  unlink $seqdatafile;

  ########### display the graphic and table:
  
  print "location: /cgi-bin/patmatch/RESTmap?id=$$&beg=1&type=$display\n";
  print "Content-type: text/html\n\n";
  exit;
}


sub tairheader
  {


    tair_header("AtDB Pattern Matching");
    print "<table width=600 align =\"CENTER\"><TR><TD>";
  }


sub footer
  {
    print "</TD></TR></TABLE>\n";
    &tair_footer;
  }


sub present_form {
  
  my $title = "TAIR Restriction Analysis";
  
  print $query->header;
  
  tairheader();
  
  print "<span class=\"mainheader\">Restriction Analysis</span> ";

  print "<CENTER><P>This program was written by Dr. Shuai Weng at AtDB.<P></CENTER>\n";
  
  
  print $query->startform(-method => 'POST',
			  -Action => $ENV{SCRIPT_NAME});
  
  print <<HTML;

This page allows you to perform a restriction analysis based on the arbitrary DNA sequence you typed or pasted. <p>
<table width=95% border=0 cellpadding=10>
<tr>
<td valign="top" bgcolor=lightgrey width=50%>
<IMG SRC=/images/redball.gif alt="[x]"><b><big>Type or Paste a DNA Sequence:</big></b><br>
<textarea name="sequence" cols=80 rows=10>
</textarea><br>
The sequence can be provided in raw, fasta or GCG format without comments  
(numbers are okay).
</td></tr>
</table>
<P>
<IMG SRC=/images/redball.gif alt="[x]"><b>Choose Restriction Enzymes:</b><br>
<select name="enzyme"> <option selected>all
<option>3' overhang
<option>5' overhang
<option>blunt end
<option>cut once
<option>cut twice
<option>Six-base cutters
</select>

<br><font color=red><b>Note</b></font>: To find enzymes that do not cut, choose 'all' and see the resulting list at bottom.
<BR><BR>
<input type=submit value="Display Restriction Map">  or  <input type=reset value="Reset Form">

HTML
  

  footer();
exit (0);
}

sub present_subform {

    my (@list) = @_;
    my ($pattern) = pop(@list);
    
    my $title = "TAIR Restriction Analysis";

    print $query->header;
    print $query->start_html(-title=>"$title", -BGCOLOR=>"#ccffcc");
    print "<a href=/><img src=\"/images/tairsmall.gif\" border=0 align=left></a>\n";
    print &page_title("$title");
    print "<CENTER><P>This program was written by Dr. Shuai Weng at AtDB.<P></CENTER>\n";
    print &divider75;
	    
    print "Available sequence names that begin with <B>$pattern</B>:<br>";
    print "<ul>";
    foreach my $list(@list) {
	print "<li><a href=\"$ENV{SCRIPT_NAME}?seqname=$list\">$list</a>";
    }
    print &divider75;
    print $query->end_html;
}


sub err_report {
    my ($err) = @_;
     
    print "Content-type: text/html\n\n";
    print "<HTML><HEAD>\n";
    print "<TITLE>TAIR Restriction Analysis Error Report</TITLE>";
    print "</HEAD><BODY BGCOLOR=\"#ccffcc\">\n";
    print "<A href=/><IMG src=\"/images/tairsmall.gif\" border=0 align=left></A>\n";
    print "<P><B>TAIR Restriction Mapper Error</B>\n";
    print "<P><HR>";
    print "<P>$err<P>";
    print "<HR></BODY></HTML>";

    exit(-1);
}



















