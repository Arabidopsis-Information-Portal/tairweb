#!/usr/local/bin/perl -w
#-d:ptkdb
#script to generate a detail gbrowse image for a given gene, and then link to the actual tair gene detail 
#page while passing in the location of the generated image

use CGI qw(:standard);
use Carp;
$SIG{__WARN__} = \&Carp::cluck;
use lib "$ENV{DOCUMENT_ROOT}/../lib";
use lib "$ENV{DOCUMENT_ROOT}/../lib/x86_64";
use lib "$ENV{DOCUMENT_ROOT}/../lib/x86_64/auto";
use Bio::Graphics::Browser;
use Bio::Graphics::Browser::Markup;
use Bio::Graphics::Browser::Util;

use constant PICTURE_WIDTH => 500;
local our $CONF_DIR = $ENV{"DOCUMENT_ROOT"}."/../conf/gbrowse.conf/";

local our $TAIR_GENE_DETAIL="http://www.arabidopsis.org/servlets/TairObject?name=";

local our ($name,$ref,$start,$end,$type,$source) = (param('name'),param('ref'),param('start'),param('end'),param('type'),param('source'));


local our $BROWSER = Bio::Graphics::Browser->new();
$BROWSER->read_configuration($CONF_DIR);
$BROWSER->dir($CONF_DIR);
#$BROWSER->clear_cache();
$BROWSER->source($source);
$BROWSER->width($PICTURE_WIDTH);
#$BROWSER->height(250);

if(!$name || !$start || !$end || !$ref)
{
	#freak out before we blow the memory ceiling off this server
	print STDERR "GOT a null or undef for one of the parameters (not including type which defaults to ProteinCoding): $name,$start,$end,$ref\n";
	print "CGI Paramter Error\n";
}	
else
{	

#print STDERR "about to open database $name $start $end $ref\n";
local our $segment = open_database($BROWSER)->segment($ref,$start,$end);
#print STDERR "after open database $start $end $ref $type\n";
#ProteinCoding,Pseudogene,TEGenes, or ncRNAs
my $track = ($type !~ /protein/i?($type =~ /pseudo/i?'Pseudogene':($type =~ /transposable/i?'TEGenes':'ncRNAs')):'ProteinCoding');
local our ($img,$map) = $BROWSER->render_panels({
					segment=>$segment,
					#labels=>['ProteinCoding'],
					labels=>[$track],
					title=>"Genomic segment : $ref:$start..$end",
					drag_n_drop=>0,
					keystyle=>'between',
					#do_map=>0,
					#hilite_callback=> sub { return 'yellow'; },
					tmpdir=>$ENV{"DOCUMENT_ROOT"}."/../tmp"});
#print STDERR "IMG/MAP:$img,$map\n";
$img =~ s/border="0"/border="1"/;

$img =~ /src=\"([^\"]+)\"/;
local our $img_file = $1;
$img =~ /width=\"(\d+)\".*height=\"(\d+)\"/;
local our $width = $1;
local our $height = $2;

#open(OUT,">/Data/webapps/coventry/tmp/test.gb.generation");
#print OUT "$name\t$ref\t$start\t$end\n";
#print OUT "$img\n";
#print OUT "$img_file\n";
#print OUT "$ENV{DOCUMENT_ROOT}\n";
#close(OUT);

print "content-type: text/html\n\n";
print $img;
#print STDERR "GBROWSE_DETAILS_IMG:$img\n";
#print "({\"source\":$img,\"request\":[]})";
}
