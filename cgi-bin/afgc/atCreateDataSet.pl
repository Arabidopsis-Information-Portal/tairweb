#!/bin/env perl


# This program is intended to create all the components required
# for an expression dataset, from a .pcl file.

# it does the following :

# 1. Ask what the dataset should be called
# 2. Create a directory /share/daisy/www-data/data/SGD/$dataset
# 3. Asks the name of the input .pcl file
# 4. makes a copy of the .pcl file in the new directory, named by the dataset name
# 5. clusters the dataset
# 6. makes a file of sorted correlation
# 7. makes a cdt gif, and gtr gif, and also places copies of them in images directory
# 8. makes a heading gif, which it places in the images directory
# 9. makes a .data file
# 10.makes a .lut file

# really needs some error handling, to undo parts of dataset creation, if it fails
# at some point

use strict;
use Carp;

# globals #

my $rootDir = "/share/daisy/tmp/afgc/data";
my $imageDir = "/share/daisy/tmp/afgc/html";
my $cluster = "/share/common/bin/sparc-sol/cluster";
my $correlations = "/share/common/bin/sparc-sol/correlations";
my $clusterImageMaker = "/share/common/bin/sparc-sol/CLUSTER/clusterImageMaker";
my $makeHeader = "/share/sgd/bin/expression/makeHeader.pl";
my $makeData = "/share/sgd/bin/expression/createDataFile.pl";


my $requiredPercent = 50; # required percentage of good data

my ($pclFile, $dataset) = &GetInput;

&MakeDirectory;

&FilterPclFile;

$pclFile = "$rootDir/$dataset/$dataset.pcl";
my $cdtFile = "$rootDir/$dataset/$dataset.cdt";

&ClusterData;

&MakeCorrelations;

&MakeImages;

&MakeHeaderImage;

&MakeDataFile;



######################################################################################
sub GetInput{
######################################################################################
# This subroutine gets the user input that is required to create the dataset

    my ($pclFile, $dataset);

    while (!defined($pclFile)){

	print "Enter the name (including the full path) of the .pcl file:\n";
	
	$pclFile = <STDIN>;
    
	chomp $pclFile;

	if (!-e $pclFile){

	    print "$pclFile does not exist.  Please try again\n";
	    undef $pclFile;
	    
	}

    }

    while (!defined($dataset)){
	
	print "Enter the name for your dataset (a single word, no metacharacters)):\n";
	
	$dataset = <STDIN>;
    
	chomp $dataset;

	if ($dataset=~/\s/){

	    print "Only a single word can be used to name the dataset\n";
	    undef $dataset;

	}elsif ($dataset =~ /[\/\\\*\@\$\%\(\)\?\[\]\{\}\!]/){

	    print "You may not use metacharacters in the dataset name\n";
	    undef $dataset;

	}elsif (-e "$rootDir/$dataset"){

	    if ($ARGV[0] eq "-f"){

		print "Forcing recreation of dataset...\n";

	    }else{

		print "A dataset with that name already exists.  Please try another one, or use -f to force it's recreation.\n";
		exit;

	    }

	}
	
    }

    return ($pclFile, $dataset);

}

#########################################################################################
sub MakeDirectory{
#########################################################################################
# This subroutine creates the directory which will house all the files for the dataset

    return if (-e "$rootDir/$dataset");

    print "Creating dataset directory\n";

    mkdir ("$rootDir/$dataset", 0777) || die "Cannot make $rootDir/$dataset :$!\n";

}

#########################################################################################
sub FilterPclFile{
#########################################################################################
# This subroutine filters the pcl file to remove any unnamed genes, and any with less than 
# $requiredPercent data datapoints, and puts the filtered version in the dataset directory

    open (IN, $pclFile) || die "Can't open $pclFile file : $!\n";

    open (OUT, ">$rootDir/$dataset/$dataset.pcl") || die "Cannot make $rootDir/$dataset/$dataset.pcl : $!\n";

    my (@line, $numExpts, $requiredExpts, $datum);

    while (<IN>){

	chomp;

	@line = split ("\t", $_, -1);

	if ($.==1){

	    $numExpts = @line-3;
	    $requiredExpts = $requiredPercent/100 * $numExpts;

	    print OUT "$_\n";

	    next;

	}

	if ($.==2){

	    print OUT "$_\n";
	    next;

	}

	next if ($line[0] eq ""); # skip unnamed ones 

	my $numPoints = 0;

	shift @line;  shift @line;  shift @line;

	foreach $datum (@line){

	    $numPoints++ if ($datum ne "");

	}

	next if ($numPoints < $requiredExpts);

	print OUT "$_\n";

    }

    close IN;
    close OUT;

}

#########################################################################################
sub ClusterData{
#########################################################################################
# This subroutine clusters the pcl file
    
    print "Clustering pcl file\n";
    
    my $output = system("$cluster -f $pclFile");

    $output && &Abort("An error occured during clustering : $output\n");
    
}

#########################################################################################
sub MakeCorrelations{
#########################################################################################
# This subroutine creates the sorted correlations file

    print "Making sorted correlations\n";

    my $output = system("$correlations -f $pclFile -showCorr 0");
    
    $output && &Abort("An error occured during creation of correlations : $output\n");
    
}

##########################################################################################
sub MakeImages{
##########################################################################################
# This subroutine creates the gtr gif, and the cdt gif

    print "Creating images\n";

    system("$clusterImageMaker -f $dataset -fp $rootDir/$dataset/ -gp $rootDir/$dataset/");
    
    #$output && &Abort("An error occured during image creation : $output\n");
    
    my $output = `/bin/cp  $rootDir/$dataset/$dataset.cdt.gif  $imageDir 2>&1 1>/dev/null`;

    $output && &Abort("An error occured during copying if the cdt image to the image directory : $output\n");

    $output = `/bin/cp  $rootDir/$dataset/$dataset.gtr.gif  $imageDir 2>&1 1>/dev/null`;

    $output && &Abort("An error occured during copying if the gtr image to the image directory : $output\n");

}

###########################################################################################
sub MakeHeaderImage{
###########################################################################################
# This subroutine creates the header image

    print "Creating header image\n";

    my $output = `$makeHeader $cdtFile 2>&1 1>/dev/null`;

    $output && &Abort("An error occured during header image creation : $output\n");

   $output = `/bin/cp  $rootDir/$dataset/$dataset.header.gif $imageDir 2>&1 1>/dev/null`;
	
    $output && &Abort("An error occured during header image copying : $output\n");

}

###########################################################################################
sub MakeDataFile{
###########################################################################################
# This subroutine extracts info from the cdt file to create a datafile

    print "Creating data file\n";

    my $output = `$makeData $cdtFile 2>&1 1>/dev/null`;

    $output && &Abort("An error occured during data file creation : $output\n");

}


###########################################################################################
sub Abort{
###########################################################################################
# this subroutine aborts dataset creation, and cleans up the created files

    my ($message) = @_;

    print $message;

    exit(0);

}









