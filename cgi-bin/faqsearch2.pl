#!/bin/env perl
#
#
# faqsearch2.pl
# Version 2.1.
#
# History: based on Version 1.0 by Debika Battarachayya, July 2000
#              basic search capability
#          Version 2.0 by Lukas Mueller, Sept 2000
#              TAIR user interface, uses displayfile.pl to display results
#          Version 2.1, Nov 2000 
#              uses environment variables, uses displaytextfile.pl          
#          Version 2.2, Oct 2001 (modifications by Danny Yoo dyoo@acoma)
#              displays Subject header line if one exists.


# Define Variables							     #

$basedir = $ENV{DOCUMENT_ROOT};

$baseurl = $ENV{SERVER_NAME};

@files = ('help/faqs_txt/');
$title = "TAIR SEARCH FAQs PAGE";
#$title_url = 'http://acoma.stanford.edu/faqsearch.html';
#$search_url = 'http://acoma.stanford.edu/faqsearch.html';

# Done									     #
##############################################################################

# Parse Form Search Information
&parse_form;

# Get Files To Search Through
&get_files;

# Search the files
&search;

# Print Results of Search
&return_html;


sub parse_form {

   # Get the input
   read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

   # Split the name-value pairs
   @pairs = split(/&/, $buffer);

   foreach $pair (@pairs) {
      ($name, $value) = split(/=/, $pair);

      $value =~ tr/+/ /;
      $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

      $FORM{$name} = $value;

   # modifications to get rid of case and boolean operators Lukas 2000-08-28. 
   $str = $FORM{'terms'};
   $FORM {'boolean'} = 'AND';
   if ($str =~ /\band\b/i) { $FORM{'boolean'} = 'AND';
                         $str =~ s/\band\b//gi; }
   if ($str =~ /\bor\b/) { $FORM{'boolean'} = 'OR';
                           $str =~s/\bor\b//gi;
                         }
   $FORM{'case'} = 'Insensitive';
   $FORM{'terms'} = $str;
   }
}


sub get_files {
   chdir($basedir);
   foreach $file (@files) {
      $ls = `ls $file`;
      @ls = split(/\s+/,$ls);
      foreach $temp_file (@ls) {
         if (-d $file) {
            $filename = "$file$temp_file";
            if (-T $filename) {
               push(@FILES,$filename);
            }
         }
         elsif (-T $temp_file) {
            push(@FILES,$temp_file);
         }
      }
   }
}


sub search {

   @terms = split(/\s+/, $FORM{'terms'});

   foreach $FILE (@FILES) {

      open(FILE,"$FILE");
      @LINES = <FILE>;
      close(FILE);

      $string = join(' ',@LINES);
      $string =~ s/\n//g;
      if ($FORM{'boolean'} eq 'AND') {
         foreach $term (@terms) {
            if ($FORM{'case'} eq 'Insensitive') {
               if (!($string =~ /$term/i)) {
                  $include{$FILE} = 'no';
  		  last;
               }
               else {
                  $include{$FILE} = 'yes';
               }
            }
            elsif ($FORM{'case'} eq 'Sensitive') {
               if (!($string =~ /$term/)) {
                  $include{$FILE} = 'no';
                  last;
               }
               else {
                  $include{$FILE} = 'yes';
               }
            }
         }
      }
      elsif ($FORM{'boolean'} eq 'OR') {
         foreach $term (@terms) {
            if ($FORM{'case'} eq 'Insensitive') {
               if ($string =~ /$term/i) {
                  $include{$FILE} = 'yes';
                  last;
                  }
               else {
                  $include{$FILE} = 'no';
               }
            }
            elsif ($FORM{'case'} eq 'Sensitive') {
               if ($string =~ /$term/) {
		  $include{$FILE} = 'yes';
                  last;
               }
               else {
                  $include{$FILE} = 'no';
               }
            }
         }
      }
      if ($string =~ /<title>(.*)<\/title>/i) {
         $titles{$FILE} = "$1";
      }
      else {
         $titles{$FILE} = "$FILE";
      }
   }
}



sub get_subject_line {
    my ($filename) = @_;
    open(SUBJECTFILE, $filename);
    my @lines = <SUBJECTFILE>;
    my $text = join("\n", @lines);
    my ($subject) = ($text =~ 
		     m/subject:
		     \s*
	             (.+)
		     /xi);
    return $subject;
}


      
sub return_html {

     print "Content-type: text/html\n\n";

print "<HTML><HEAD><TITLE>Search results</TITLE>";
   
print "\<SCRIPT SRC=\"/js/navbar.js\"\>\</SCRIPT\>";
print "<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/main.css\" > ";

print "</HEAD><BODY BGCOLOR = \"f5f9ff\"> ";

print "\<!-- HEADER using external JavaScript file --\>";

print "\<script language=\'JavaScript\'\>";
print "var highlight = 0; var helpfile=\"\" ";
print "\</script\>";
print "\<script language=\'JavaScript\' SRC=\'/js/header\'\>";
print "\</script\>\<p\>";


   print "<table width=600 align =\"CENTER\"><TR><TD>";
   print "<B>Results of Search in $title\n </B>";
   print "Search Information:\n";
   print "<ul>\n";
   print "<li><b>Terms:</b> ";
   $i = 0;
   # List the search terms and produce a string that contains them 
   # in MIME encoding (will be used to display the detail page
   # in displayfile.pl)
   
   $termstring = "";
   foreach $term (@terms) {
      print "$term";
      $termstring = $termstring."\&T".$i."=".$term;
      $i++;
      if (!($i == @terms)) {
         print ", ";
      }
   }
   $hits = 0;
   foreach $key (keys %include) 
   {
      if ($include{$key} eq 'yes') { $hits++ }
   }
   
       
   print "<LI><B>Hits:</B> $hits";

   print "</UL>";

   print "<ul>\n";
   $hits = 0;
   foreach $key (keys %include) {
      if ($include{$key} eq 'yes') {
         print "<li><a href=\"/cgi-bin/displaytextfile.pl?filename=$basedir/"."$key"."$termstring\">$titles{$key}</a>\n";
	 my $subject_line = get_subject_line($key);
	 if ($subject_line) { print "$subject_line\n"; }
      }
   }
   print "</ul>\n";
   print "\n";
   print "<li><b>Boolean Used:</b> $FORM{'boolean'}\n";
   print "<li><b>Case $FORM{'case'}</b>\n";
   print "</ul>\n";

   # print "Basedir: $basedir Baseurl: $baseurl\n";
   
   print "</TD></TR></table></body>\n</html>\n";
}
   
