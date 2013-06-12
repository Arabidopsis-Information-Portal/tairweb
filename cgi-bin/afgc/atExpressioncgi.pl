#!/bin/env perl 


use strict;
#use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:all :html3);


use atExpression;

use CloneIdFinder;


require '../format_tairNew.pl';

#Autoflash
$|=1;

my $docRoot = $ENV{'DOCUMENT_ROOT'};
my $home = "$docRoot/../";
my $script = "$ENV{'SCRIPT_NAME'}";

my $helppage = "/help/helppages/help_expression.html";

my $cgi;

$cgi = new CGI;

my $jScript;

    $jScript=<<EOF;
<script type="text/javascript">
<!--
function showLocusDetail(locus) {
  servlet = "/servlets/TairObject?type=locus&name=" + locus;
  wName = "_" ;
  fWindow = window.open(servlet,wName,'toolbar=yes,menubar=yes,scrollbars=yes,resizable=yes,location=yes,status=yes');
  fWindow.focus();
}
//-->
</SCRIPT>
EOF


    print "Content-type: text/html\n\n";
tair_header("Expression Analysis Across All the Experiments");
print "$jScript\n";




print "<table width=\"700\" border=\"0\"><tr><td>";

# get cloneid that was passed in
my $cloneid= ($cgi->param('clone_id'));

# if no clone id, look for SUID - links from TAIR detail pages will
# use this id since clone id/names don't match up to TAIR clone names. If
# we have an SUID, get corresponding clone id from AFGC data file and continue
my $su_id = $cgi->param( 'su_id' );
if (!$cloneid && $su_id ) {
  $cloneid = translateSUID( $su_id, $home );
}

## if clone id still empty, give error message and quit
if ( !$cloneid ) {
  print font({-color=>'red'},
             h4("No cloneid name was passed in. Please select your cloneid by selecting Clone List icon on AFGC web."));
  print "</td></tr></table>\n";
  tair_footer();

  exit;

}


$cloneid = uc( $cloneid );
print "<br>";



my $dataset=$cgi->param('dataset');

if (!$dataset){
# if no dataset provided, diaplay the dataset selection page
    &printForm($cloneid);
 }
else { 
# then go on to display the expression profile
  $dataset=lc($dataset);

}

my (%dataset, %dataset_choices);


# old datasets

#%dataset_choices = 
#(
#                    development => ['title'=>"Expression of $cloneid in response to Developmental changes",
#                                    'blocksize'=>16],
#                    
#                    metabolism => ['title'=>"Expression of $cloneid during Metabolism",
#                                   'blocksize'=>16],
#                    
#                    anatomical_comparison => ['title'=>"Expression of $cloneid in response to various Anatomical Comparisons",
#                                              'blocksize'=>16],
#                    
#                    test => ['title'=>"Expression of $cloneid in response to various Test/Control experiments",
#                             'blocksize'=>16],
#                    
#                    hormone => ['title'=>"Expression of $cloneid in response to Hormonal/Drug treatment",
#                                'blocksize'=>16],
#                    
#                    abiotic => ['title'=>"Expression of  $cloneid in response to Abiotic stress",
#                                'blocksize'=>16],
#                    
#                    biotic => ['title'=>"Expression of $cloneid in response to Biotic stess",
#                               'blocksize'=>16],
#                   );

### new datasets from Suparna 8.7.2003
%dataset_choices = 
  (
   abiotictreatment => ['title'=>"Expression of  $cloneid in response to Abiotic treatment",
                        'blocksize'=>16],
   
   biotictreatment => ['title'=>"Expression of $cloneid in response to Biotic treatment",
                       'blocksize'=>16],
   
   chemicaltreatment => ['title'=>"Expression of $cloneid in response to chemical treatment",
                         'blocksize'=>16],
   
   ecotypecomparison => ['title'=>"Expression of $cloneid in response to various Ecotype Comparisons",
                         'blocksize'=>16],
   
   hormonetreatment => ['title'=>"Expression of $cloneid in response to Hormonal/Drug treatment",
                        'blocksize'=>16],
   
   nonwildtypecomparison => ['title'=>"Expression of $cloneid in response to various Non-wild type Comparisons",
                             'blocksize'=>16],
   
   nutrienttreatment => ['title'=>"Expression of $cloneid in response to Nutrient treatment",
                         'blocksize'=>16],
   
   tissuecomparison => ['title'=>"Expression of $cloneid in response to various Tissue Comparisons",
                        'blocksize'=>16],
   
  );


if (exists $dataset_choices{$dataset}) {
    %dataset = @{$dataset_choices{$dataset}};
}
else{
    &Error("The passed in dataset was not recognized\n<br>");
}

my $expressionQuery;

if (&isRunningAsApplication()) {
    $expressionQuery = atExpression->new(home=>$home,
                                         script=>$script,
                                         dataset=>$dataset,
					 cloneid=>$cloneid,
					 %dataset);
}

else {
    $expressionQuery = atExpression->new(home=>$home,
                                         script=>$script,
                                         dataset=>$dataset,
					 cloneid=>$cloneid,
					 %dataset);

}

$expressionQuery->print;

print "</td></tr></table>\n";
&tair_footer;

#print $cgi->end_html;




###########################################################################
# Translated submitted su id to clone_id (name) that is used throughout 
# all other viewer functions. This is done for a quick and dirty solution
# to allow linking to expression viewer from TAIR detail pages.  Since
# array element/clone name is not a reliable link, we need to allow for 
# linking using SUID. This routine opens the array element data file and
# finds the corresponding clone id.
#
# Searching through data file is done using plain old perl IO -  seems
# to work fine, and much easier to get running than going through steps
# needed for indexing files using BioPerl. Can revisit if this turns out
# to be too slow for some reason.
#
# arguments:  
#   su_id     SU ID to be translated
#   homeDir   Web root script lives in (i.e. /home/arabidopsis - determined
#             using ENV{} vars above
#
# return:
#   clone_id (name) that can be used for rest of expression viewer functions
#
# NM 9.30.2003
##########################################################################
sub translateSUID() 

{
  my ( $su_id, $homeDir ) = @_;
  my $dataFile =  "$homeDir/data/afgc/AFGC_arrayelements_082002.txt";
  open( DATA, $dataFile ) || die "Couldn't open $dataFile: $!\n";

  my $clone_id;
  my $file_su_id;
  while ( <DATA> ) {
    if ( /$su_id/ ) {
      ($file_su_id, $clone_id) = split( /\t/ );
      last;
    }
  }
  close( DATA ) || die "Error closing $dataFile: $!\n";

  return $clone_id;
}
       


###########################################################################
sub printForm 
##########################################################################
{

  my $clone_id = shift;

  my %args = (home=>$home,
              clone_id => $clone_id);

  my $finder = CloneIdFinder->new(%args);

  my @datasets = $finder->find_datasets;

  # display labels to use for each dataset
  my %labels = (
                abiotictreatment => "abiotic treatment",
                biotictreatment => "biotic treatment",
                chemicaltreatment => "chemical treatment",
                ecotypecomparison => "ecotype comparison",
                hormonetreatment => "hormone treatment",
                nonwildtypecomparison => "non-wild type comparison",
                nutrienttreatment => "nutrient treatment",
                tissuecomparison => "tissue comparison"
               );

  print $cgi->p,h1({-align=>'left'},"Expression Analysis Across All the Experiments");
	
  print "<p>Please select a dataset from the list below to view the expression of <font color= red>$cloneid</font> across all the experiments in that dataset.\n";

  print "<p><b>DATASET(S) WITH CLUSTERED DATA: </b><br>\n";

  print $cgi->start_form;




  print $cgi->scrolling_list(-name=>'dataset',
                             -value=>\@datasets,
                             -default=> undef,
                             -size=> scalar(@datasets),
                             -multiple=>'false',
                             -labels => \%labels 
                            );

  print $cgi->hidden('clone_id', "$cloneid");

  print $cgi->submit(-name=>'submit',
                     -value=>'submit');

  print $cgi->reset(-name=>'Reset',
                    -value=>'clear');

  print $cgi->end_form;
  print "<br></TD></TR>\n";

  print "<TR><TD>To see the entire list of datasets, see <A HREF=\"$helppage#datasets\">Help</A>.</TD></TR></TABLE>\n";

  &tair_footer;
  exit;
}	


############################################################################################
# This subroutine simply prints out a page with an error message on it
############################################################################################
sub Error{

  my ($message) = @_;

  #print header;
 
  print start_html("Error");

  print table({-width=>'100%',
               -border=>0,
               -cellspacing=>0,
               -cellpadding=>0},
              
              Tr(td({-width=>500,
                     -valign=>'middle'},
                    # h1({-align=>'center'}, "Error")
                   )
                 
                ));
    
    
  h2($message),

  
    end_html;
  
  exit;

}

########################################################################
# A small subroutine that tells us if we're running as an application
# or as a CGI.
########################################################################
sub isRunningAsApplication {


        if (exists $ENV{"REQUEST_METHOD"} ) {     #checking if it is cgi
	return 0;
    }
    return 1;    # if it is an application
}













