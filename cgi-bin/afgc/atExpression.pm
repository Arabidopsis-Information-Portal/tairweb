package atExpression;

#modify the program to enable the display of expression viewer on tair site at 
#tair.stanford.edu, Aug 8, 2002
#by Suparna Mundodi

#Oct. 2002 by Guanghong Chen

# This object is a simple encapsulation of all the things required to show the expression
# data for a gene in a particular expression data set.

use strict;
use CGI qw( :standard);

use GD;

use Desc;
use Locus;


#Autoflash
$|=1;


my $dataDir = "data/afgc/";

my $microarray_home = "/tools/bulk/microarray/index.html";


sub new {
    my $self = {};
    bless $self, shift;
    $self->_init(@_);
    return $self;

}


#####################################################################
sub _init {
#####################################################################

    my ($self, %args) = @_;

    my $defaultBlocksize = 16;

    $self->{'_home'} = $args{'home'};

    my $defaultImagedir = $self->{'_home'}."WebRoot/i/d/";

    my $defaultImageUrl = "/i/d/";

    $self->{'_script'} = $args{'script'};

    $self->{'_dataset'} = $args{'dataset'};
    $self->{'_stem'} = $self->{'_home'}.$dataDir.$self->{'_dataset'}."/".$self->{'_dataset'};
    $self->{'_dataFile'} = $self->{'_stem'}.".data";
    $self->{'_correlationFile'} = $self->{'_stem'}.".stdCor";

    $self->{'_gifFile'} = $self->{'_stem'}.".cdt.png";

    $self->{'_title'} = $args{'title'};
    $self->{'_cloneid'} = $args{'cloneid'};
    $self->{'_blocksize'} = $args{'blocksize'} || $defaultBlocksize;


    $self->{'_image_dir'} = $args{'image_dir'} || $defaultImagedir;
    $self->{'_image_url'} = $args{'image_url'} || $defaultImageUrl;

    #where the experiment names are printed 
    $self->{'_image_header_url'} = "/i/afgc/$self->{'_dataset'}.header.gif";
    
    # each image header has a text file that contains HTML for image mapping
    # experiment names to detail pages
    my $mapFileName = "$self->{ '_dataset' }_map.txt";
    $self->{'_image_header_map_file' } = "$self->{'_home'}$dataDir$self->{ '_dataset' }/$mapFileName";
    $self->{'_image_header_html_map' } = "$self->{ '_dataset' }header";



    # So you need to copy the image manually from the Imageheader to home dir to make it available to the program.
   
##    $self->{'_image_header'} = $args{'image_header'} || $defaultImageHeader;
##    $self->copyImageHeader();
}

#########################################################################
# copy the image from the temporary directory to the home directory 
# --- this is a workaround for the strange permissions on the web server.
######################################################################
sub copyImageHeader {
	
  my $self = shift;
  `cp $self->{_image_header} $self->{'_image_dir'}`;
}


#####################################################################
# This method prints out everything associated with the expression query
#####################################################################
sub print {
    my ($self) = @_;

    #print start_html($self->{'_title'}, $jScript);
    #&tair_header(2, "/Blast/BLAST_help.html");

   print table({-width=>'100%',
		 -border=>0,
		 -cellspacing=>0,
		 -cellpadding=>0},
		
		Tr(td({-width=>500,
		       -valign=>'middle'},
		      h1({-align=>'left'}, $self->{'_title'}))
		   ));

    #print &Divider75,


    my (@similar, %similar, @data, %positions);

    my $seen = $self->getSimilar(\@similar, \%similar);
	

    if ($seen){

      my ($expts,$genes) = $self->getLinesAndLineNumbers(\@similar, \@data, \%positions);
        #my ($expts,$genes) = $self->getDataAndPositions(\%similar, \@data, \%positions);
      $self->createColorStrips($expts, $genes, \%positions);

      $self->printResults(\@similar, $expts);
    }else{

      print h2("There is no expression information for $self->{'_cloneid'} in the $self->{'_dataset'} dataset.");
    }


    #end_html;

}

##########################################################################
# This subroutine retrieves the similarly expressed Cloneids to the query clone
# by parsing the stdCor file.  The cloneid itself will be the first entry of the
# populated array.  In addition a hash will be made that can be used to
# check if an CLoneid is in the similar list
##########################################################################
sub getSimilar{

    my ($self, $similarArrayRef, $similarHashRef) = @_;

    my $seen;

    my $cloneid = $self->{'_cloneid'};

    open (IN, $self->{'_correlationFile'})|| die "Can't open $self->{'_correlationFile'} : $!\n";

    while (<IN>){

	next unless /^$cloneid/;

	chomp;

	@{$similarArrayRef} = split ("\t");

	$seen = 1;

	last;

    }

    close IN;

    foreach (@{$similarArrayRef}){

	$$similarHashRef{$_}=1;
	
    }

    return $seen;

}

############################################################################
# This subroutine look into the data file, .data to work out the line that the
# cloneid and similar cloneids are on
############################################################################
sub getDataAndPositions{


    my ($self, $similarRef, $dataRef, $positionsRef) = @_;

    my $cloneid = $self->{'_cloneid'};

    #print "datafile is: $self->{'_dataFile'} \n";

    open (IN, $self->{'_dataFile'}) || die "Can't open $self->{'_dataFile'} : $!\n";

    my (@line, $name);

    while (<IN>){

	chomp;

	@line = split("\t", $_, -1);

	$name = shift(@line);

	next unless $$similarRef{$name}; # skip if not similar

	$$positionsRef{$name}=$.-1; # record line (-2)

	next unless $name eq $cloneid ;

	@{$dataRef} = @line;

    }

    print "dataRef is @{$dataRef}<BR>\n";
    my $genes = $.-1;
    my $expts = @{$dataRef};

    close OUT;
	
    return ($expts,$genes);

}

############################################################################
# This subroutine look into the data index file, .data.* to work out the line that the
# cloneid and similar cloneids are on
############################################################################
sub getLinesAndLineNumbers{


    my ($self, $similarRef, $dataRef, $positionsRef) = @_;

    my $cloneid = $self->{'_cloneid'};


    my $index = TabFileIndex->new("$self->{'_dataFile'}.dir");

    my $line = $index->fetch($cloneid);
    my $max_line_number = $index->fetch_line_number($cloneid);


    my @line = split /\t/, $line;

    #number of arrays
    my $expts = scalar(@line) - 1;

    foreach my $name (@{$similarRef}){
      $line = $index->fetch($name);
      my $line_number = $index->fetch_line_number($name);
      $$positionsRef{$name}=$line_number-1;
      if ($line_number > $max_line_number){
        $max_line_number = $line_number;
      }

    }
    # The last line of these co-expressed genes
    my $genes = $max_line_number-1;	

    # width and height from the original image
    return ($expts,$genes);

}
	
###########################################################################
# This subroutine will create a small color strip for each gene, using the
# premade color gif that contains 1 x 1 pixel blocks for each gene across
# all experiments
###########################################################################

sub createColorStrips{

  my ($self, $expts, $genes,$positionsRef) = @_;
  
  open (GIF, $self->{'_gifFile'}) || die "Can't open $self->{'_gifFile'} : $!\n";
  #print "_gifFile is: $self->{'_gifFile'} \n";

  my $im = new GD::Image($expts,$genes);
  
  #$im = newFromGif GD::Image(\*GIF) || die "can't make new image : $!\n";
  $im = newFromPng GD::Image(\*GIF) || die "can't make new image : $!\n";
  
  close(GIF);
  
  my $newIm = new GD::Image($expts,1);
  
  foreach (keys %{$positionsRef}){
    #print "$_\t$$positionsRef{$_}\t$expts\t$genes<BR>\n";
    $newIm->copy($im,0,0,0,$$positionsRef{$_},$expts,1);
    open (OUT, ">$self->{'_image_dir'}$_.$self->{'_dataset'}.gif")||die "Can't make $self->{'_image_dir'}$_.$self->{'_dataset'}.gif: $!";
    #print "Content-type:image/GIF\n\n"; 
    binmode OUT;

    print OUT $newIm->png;
    close OUT;
    
  }
  
}

#############################################################################
# Find image map HTML file for header image and print
#############################################################################
sub printImageMapText() {
  my $self = shift;
  
  open( FILE, $self->{'_image_header_map_file' } ) || die "Couldn't open $self->{ '_image_header_map_file' }: $!\n";
  while ( <FILE> ) {
    print $_;
  }
  close( FILE ) || die "Couldn't close $self->{ '_image_header_map_file' }: $!\n";
}

    



#############################################################################
# This subroutine prints out all the pertinent results for the query
#############################################################################
sub printResults{

  my ($self, $similarRef, $expts) = @_;

  my (@rows, $cloneid, $i, $color);
  my $spacer;
  my $headSpacer = th({-width=>20}, "");
  my $blocksize = $self->{'_blocksize'};
   
  my $url = url; # url of this script
    	


	
  #I'm attaching the image.header on top of the images for now. 
  push (@rows, Tr( "<td colspan=\"4\">" .
                   h5("<font color=red>Click on a hybridization name to see " .
                      "the corresponding experiment details.</font>") .
                   "</td>" .
		   "<td rowspan=\"2\"><img src=\"$self->{_image_header_url}\" " .
		   "USEMAP=\"#$self->{'_image_header_html_map'}\" BORDER=0></td>" .
                   $headSpacer .
                   $headSpacer )
        );

  push (@rows, Tr( TableHead( "cloneid" ) . 
		   $headSpacer . 
		   TableHead( "locus" ) . 
		   $headSpacer . 
		   $headSpacer.TableHead( "description" )
                 ));

  my $indexfile = $self->{'_home'}."data/afgc/AFGC_arrayelements_082002.txt.dir";
  my $inx = Desc->new($indexfile);
  
  my $loci_names = "";

  $i = 0;
  foreach $cloneid (@{$similarRef}){

    if (!odd($i+1)){          #if it is a odd line
      $color = "white";
    }else{
      $color = "#EEEEEE";   #else give grey color
    }

    $spacer = td({-width=>20,
                  -nowrap=>1,
                 },
                 "&nbsp;");

    $i++;


    my $locus =  $inx->fetch($cloneid);

    my $locus_name = $locus->locus_name_chromosome();

    if ($locus_name){
      
      $loci_names .= " $locus_name";
    }

    my $description = $locus->annotation();

    push (@rows, Tr({-bgcolor=>$color,
                     #			 -nowrap=>1
                    },
                    $self->TableCell(a($cloneid)).$spacer.

                    $self->TableCell(a{-href=>"/servlets/TairObject?type=locus&name=$locus_name"},$locus_name).$spacer.
                    $self->TableCell(a({-href=>$url."?dataset=$self->{'_dataset'}&clone_id=$cloneid"},


                                       img({-src=>"$self->{'_image_url'}$cloneid.$self->{'_dataset'}.gif",
                                            -width=>$expts * $blocksize,
                                            -height=>$blocksize,
                                            -border=>0}))).$spacer.
                    $self->TableCell($description)
                   ));
  }

  a({-href=>"/help/helppages/help_expression.html"},
    -align=>'right',
    (img ({-src=>"/help/helppages/images/help-button.gif"}))),
    
      br,
        print b("Scale : (fold repression/induction)"), br,
    
          img({-src=>"/help/helppages/images/scale.1.5.gif"}),
            br,br,
    
    a({-href=>"/help/helppages/help_expression.html"},
      #-align=>'right',
     (img ({-src=>"/help/helppages/images/help-button.gif"}))),
    
    br,
    
      h4("Click on a color strip to see clustered data for that gene."),

        h4("Up to 20 similar genes are shown, with a Pearson correlation of > 0.8 to the query gene");



  print font({-face=>'verdana, arial, sans-serif', 
              -size=>-1},
             table({-border=>0,
                    -cellspacing=>0,
                    -cellpadding=>0},
                   @rows),
             br(),

             
            );


  ### get HTML text for image map & add to page ###
  $self->printImageMapText();

#  print "<FORM ACTION=/cgi-bin/bulk/motiffinder/oligoAnalysis.pl METHOD=\"POST\"  ENCTYPE=\"application/x-www-form-urlencoded\" >\n";
#  print "<INPUT TYPE=\"hidden\" NAME=\"input\" VALUE=\"".$loci_names."\"><INPUT TYPE=\"hidden\" NAME=\"output_type\" VALUE=\"html\"><INPUT TYPE=\"hidden\" NAME=\"textbox\" VALUE=\"seq\"><INPUT TYPE=\"submit\" NAME=\".submit\"></FORM>\n";



  print "\n";
  print a({-href=>$microarray_home},"Back to microarray front page."), br,
   a({-href=>$self->{'_script'}."?clone_id=".$self->{'_cloneid'}},"Back to datasets selection page."), br;
  
}

#################################################################################
# This subroutine simply returns a cell to go in the table
#################################################################################
sub TableCell{

    my ($self, $string) = @_;

    return td(  {-nowrap => 1 },
	      font({-size=>-1}, $string));

}

#################################################################################
# This subroutine simply returns a heading cell for the table
#################################################################################
sub TableHead{


    return th({-align=>'LEFT',
	       -valign=>'BOTTOM'}, $_[0]);

}

########################################################################
sub odd {
#####################################################################
    return $_[0] % 2 == 1;
}


1;


#################################################################
sub Divider75{
############################################################
#Small dividing line 75% width of page 
 
     return "<hr size=2 width=75%>\n";

}
















