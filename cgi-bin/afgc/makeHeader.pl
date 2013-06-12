#!/bin/env perl 

# Author : Gavin Sherlock
# Date   : August 8th 2000

# This samll program makes an image to go at the head of
# expression results to indicate which columns are from which experiments

# It takes a cdt file as a single command line argument

use GD;         # loads Lincoln Stein's GD interface module

my $cdtFile = $ARGV[0];

$cdtFile =~ /^(.+)\.cdt$/;

my $stem = $1;

open (IN, $cdtFile) || die "Couldn't open $cdtFile : $!\n";

my $line = <IN>; # just need first line

close IN;

chomp $line;

my @words = split ("\t", $line);

shift @words;shift @words;shift @words;shift @words; # just leave expt names

my $blocksize = 16;
my $border = 5;

&definegif;

&writeText;

&printgif;


################################################################################################
#
#      Subroutines from here on down
#
###############################################################################################

sub definegif(){

    my $max=0;

    foreach (@words){

	$max = length($_) if length($_) > $max;

    }

    $height = $max * gdSmallFont->width + $border;

    $im = new GD::Image($blocksize * @words, $height); # define an image

    $white = $im->colorAllocate(255,255,255); # define some colors

    $black = $im->colorAllocate(0,0,0);

    $grey = $im->colorAllocate(127,127,127);

}

###############################################################################################

sub writeText(){

    my $i=0;

    foreach (@words){

	$im->stringUp(gdSmallFont, $i*$blocksize, $height-1-$border, $_, $black);
	$i++;

    }
    
}

################################################################################################

sub printgif(){

    open (IMAGE, ">$stem.header.gif") || die "couldn't create $stem.gif : $!\n";

    print (IMAGE $im->gif);
 
    close (IMAGE);

    print "done\n";

}




