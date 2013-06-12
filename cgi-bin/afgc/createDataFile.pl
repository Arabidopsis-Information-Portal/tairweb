#!/bin/env perl 

# Author : Gavin Sherlock
# Date   : 3rd August 2000

# Purpose : to take a .cdt file, and generate a .data file, which is used
#           by the expression data interfaces.
#           The output .data file will be put in the same directory as the
#           input file
#
# Usage   : createDataFile.pl <inputfile>

use strict;

my $inputFile = $ARGV[0] || &Usage;

if ($inputFile!~/\.cdt$/) { &Usage };

&MakeDataFile($inputFile);




###########################################################################
sub Usage{
###########################################################################
# 

    print STDERR "You must supply an input .cdt file as the sole argument to createDataFile.pl\n";

    exit(1);

}

############################################################################
sub MakeDataFile{
############################################################################
# This subroutine creates the data file from the .pcl file
# It simply does this by printing out the first column, skips the second and
# third columns, then prints all other columns.  It also skips the second row

    my ($inputFile) = @_;

    $inputFile =~ /^(.+)\.cdt$/;

    my $stem = $1;

    my $outputFile = $stem.".data";

    open (IN, $inputFile) || die "Cannot open $inputFile : $!\n";

    open (OUT, ">$outputFile") || die "Cannot make $outputFile : $!\n";

    my (@line);

    while (<IN>){

	next if ($.==2);

	chomp;

	@line = split ("\t", $_, -1);

	print OUT $line[1], "\t"; # this is the YORF

	shift @line; # get rid of GENE0X etc
	shift @line; # get rid of YORF
	shift @line; # get rid of NAME
	shift @line; # get rid of GWEIGHT

	print OUT join ("\t", @line), "\n";

    }

    close IN;
    close OUT;

}














