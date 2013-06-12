#!/usr/local/bin/perl 

# reformats blast output into html; adds
# an active Mapic overview map.
# usage: map.pl [blast output filename]
# [[ this would be much cleaner if everything
# were an object for real, so the arrows would
# know where they are and how to label themselves,
# and the HSPs would know how they overlap &c.
# this itself should just be an object
# so i wouldn't have to be passing
# around stupid values, or
# using globals. ]]

# yes, the code sucks. there are lots of
# hard-coded constants for lining up graphics.

#
# Modified by Bengt Anell December, 2000
# Paths were modified to fit TAIR Linux system.
#


use GD;
use Carp;
use strict;
use CGI::Carp qw( fatalsToBrowser );

use lib "/home/gc/tair/web/cgi-bin/wublast/JCES-BLASTGRAPHIC/lib";
#use lib "/home/gc/tair/web/cgi-bin/wublast/JCES-BLASTGRAPHIC/";

require Bio::Tools::Blast;
require Set::IntSpan;
use MyDebug qw( dmsg dmsgs assert );
use MyMath qw( round max );
use MyUtils;
use MyBlast::HitWrapper;
use MyBlast::WrapPartitionsFixed;
use MyBlast::WrapList;
use MyBlast::MapSpace;
use MyBlast::MapUtils;
use MyBlast::MapDefs
    qw( $imgWidth $imgHeight $fontWidth $fontHeight $imgTopBorder
       $imgBottomBorder $imgLeftBorder $imgRightBorder $namesHorizBorder
       $imgHorizBorder $imgVertBorder $arrowHeight $halfArrowHeight
       $arrowWidth $halfArrowWidth $hspPosInit $hspArrowPad $hspHeight
       $formFieldWidth $tickHeight $bottomDataOffset $topDataOffset
       $kNumberOfPartitions $bucketBest $bucketZeroMax $bucketOneMax
       $bucketTwoMax $bucketThreeMax $bucketFourMax );

#----------------------------------------
# [[ we really need to be an object some day!
# i'm starting to put 'globals' in here. ]]
my( $ref ) = {};
my( $kDebugCount ) = MyUtils::makeVariableName( "debug", "count" );
my( $kTickList ) = MyUtils::makeVariableName( "tick", "list" );
my( $kHitCount ) = MyUtils::makeVariableName( "hit", "count" );
my( $kMapUtils ) = MyUtils::makeVariableName( "map", "utils" );
my( $kAllShowingP ) = MyUtils::makeVariableName( "all", "showing", "predicate" );
$ref->{ $kDebugCount } = 0;
$ref->{ $kTickList } = [];

#------------------------------
# argc.
#------------------------------

my( $bfname, $cutoff, $showNamesP, $db );
eval
{
    $bfname = MyUtils::getArgOrDie( 0, "Missing blast filename to parse (1st arg)", @ARGV );

    # [[ cutoff is no longer used. ]]
    $cutoff = MyUtils::getArgOrDie( 1, "Missing cutoff (2nd arg)", @ARGV );

    $showNamesP = MyUtils::getArgOrParam( 2, 1, @ARGV );
};
if( $@ )
{
    confess $@;
}

$ref->{ $kMapUtils } = new MyBlast::MapUtils( $showNamesP );

# i think there is a reaper cron job which looks
# for files with this naming convention.
my( $imgName ) = "$$.50.gif";

#------------------------------
# the /hotdocs/images/orfmap is a soft link to /home/arabidopsis/tmp/wublast
# for the generated images, will be cleaned up by a cron job
#------------------------------
my( $dstDir ) = "/home/gc/tair/web/htdocs/images/orfmap/";
my( $dstURL ) = "http://xanadu.ncgr.org:8080/images/orfmap/";

my( $mapName ) = "imap";
my( $formFieldWidth ) = 60;         #edited by bengt, was 100

#------------------------------
# get blast results, quit if there aren't any/enough hits.
#------------------------------

my( $blast ) = Bio::Tools::Blast->new( -file => $bfname, -parse  => 1);

my( $hc ) = scalar( $blast->hits() );
#dmsg( "hit count = $hc" );
if( $hc <= 0 )
{
    print( "<p>Mapper found no hits.</p>" );
    exit;
}

#------------------------------
# figure out a horizontal scale.
#------------------------------

my( $horizRatio, $hit, $hit, $wrap, $wrapList, $parts );

# we want to scale everything to fit in the Mapic.
# convert from length to pixels. length * (pixels/length) = pixels.

my( $srcLength ) = $blast->length;
$horizRatio = $ref->{ $kMapUtils }->getQueryWidth() / $srcLength;
#dmsg( $srcLength, $horizRatio );

#------------------------------
# figure vertical layout.
#------------------------------

$wrapList = new MyBlast::WrapList();
foreach $hit ( $blast->hits() )
{
    $wrap = new MyBlast::HitWrapper( $hit );
    #dmsg( "adding", $wrap->toString(), $wrap->getPExponent() );
    $wrapList->addElement( $wrap );
}
$wrapList->sortByPValue();
undef( $blast ); # allow gc.

# remember how many hits we had
# so that we can report how many
# we don't show.
$ref->{ $kHitCount } = $wrapList->getCount();

$parts = new MyBlast::WrapPartitionsFixed( $wrapList );
$parts->reduce();

my( $hitCountBefore ) = $ref->{ $kHitCount };
my( $hitCountAfter ) = $parts->getPartitionElementsCountAfter();
countHTML( $hitCountAfter, $hitCountBefore );
if( $hitCountAfter == $hitCountBefore )
{
    $ref->{ $kAllShowingP } = 1;
}
else
{
    $ref->{ $kAllShowingP } = 0;
}

#------------------------------
# now that we can know the size
# of the graph, init a bunch of poop.
#------------------------------

my( $annotationWidth ) = $parts->getMaxAnnotationWidthForFont( $fontWidth );
$ref->{ $kMapUtils }->putNamesHorizBorder( $annotationWidth + 10 );

my( $realWidth ) = $ref->{ $kMapUtils }->getImgWidth();
my( $realHeight ) = $parts->getHeight() + $imgVertBorder;
my( $img ) = new GD::Image( $realWidth, $realHeight );
$img->interlaced( 'true' );

my( $black ) = $img->colorAllocate( 0, 0, 0 );
my( $white ) = $img->colorAllocate( 255, 255, 255 );
my( $grayLight ) = $img->colorAllocate( 204, 204, 204 );
my( $gray ) = $img->colorAllocate( 153, 153, 153 );
my( $grayDark ) = $img->colorAllocate( 102, 102, 102 );

my( $debugColor ) = $img->colorAllocate( 0, 204, 0 );
my( $bgColor2 ) = $white;
my( $bgColor3 ) = $grayLight;

# range colors. things are hard-coded throughout to use these.

# brighter blues because they are so dark to begin with.
my( $blue ) = $img->colorAllocate( 51, 51, 204 );
my( $blueDark ) = $img->colorAllocate( 51, 51, 153 );

my( $cyan ) = $img->colorAllocate( 0, 204, 204 );
my( $cyanDark ) = $img->colorAllocate( 0, 153, 153 );

my( $green ) = $img->colorAllocate( 0, 204, 0 );
my( $greenDark ) = $img->colorAllocate( 0, 153, 0 );

my( $magenta ) = $img->colorAllocate( 204, 0, 204 );
my( $magentaDark ) = $img->colorAllocate( 153, 0, 153 );

my( $red ) = $img->colorAllocate( 204, 0, 0 );
my( $redDark ) = $img->colorAllocate( 153, 0, 0 );

# will have an alternating background
# to help hilight hsps in the same hit.
my($curBgColor) = $bgColor2;

# but everything else should have a white background
# to distinguish where the hits start & end.
$img->filledRectangle( 0, 0, $realWidth, $imgHeight, $white );

# [[ debugging.
#$img->rectangle( 2,
#		$imgTopBorder,
#		$realWidth-2, 
#		$realHeight - $imgBottomBorder,
#		$red );
#$img->rectangle( 4,
#		$hspPosInit,
#		$realWidth-4,
#		$hspPosInit + new MyBlast::MapSpace()->getSpace(),
#		$cyan );
# ]]

#------------------------------
# draw!
#------------------------------

writeIMapStart();
drawQuery( $srcLength, $horizRatio );
drawGraph( $parts );
drawKey();
drawStamp();
writeGIF();
writeIMapEnd();
 #
 #
 #----------------------------------------
 #
 #           the subroutines
 #
 #----------------------------------------
 #
 #

#----------------------------------------
# spit gif out to a file.

sub writeGIF
{
    unless( open( GIFOUT, ">$dstDir$imgName" ) )
    {
	croak( "couldn't write to $dstDir$imgName" );
    }
    #print GIFOUT $img->gif;
    print GIFOUT $img->png;
    close GIFOUT;
}

#----------------------------------------
# draw partitions in order.
# must come after drawQuery if
# you want the ticks everywhere.
sub drawGraph
{
    my( $parts ) = shift;

    #dmsg( "drawGraph()..." );

    my( $hspPos, $hspBefore, $hspAfter, $hspMid );
    my( $pdex );
    my( $part );
    my( $countsRef );
    my( $countsStr );
    my( $wrap );
    my( $enum );
    my( $totalCount, $shownCount );

    $hspPos = $hspPosInit;

    for( $pdex = 0; $pdex < $kNumberOfPartitions; $pdex++ )
    {
	$part = $parts->getPartitionAt( $pdex );
	#dmsg( "drawGraph(): partition \#$pdex count =", $part->getCount() );

	# draw the hsps in the hits.
	# keep track of how much vertical space is used.

	$hspBefore = $hspPos;

	$enum = $part->getEnumerator();
	while( defined( $wrap = $enum->getNextElement() ) )
	{	    
	    $hspPos = drawWrap( $wrap, $hspPos );
	}
	$hspAfter = $hspPos;

	# annotate with count of
	# shown/total per bucket.

	$countsRef = $parts->getPartitionElementsCountsRefAt( $pdex );
	#dmsgs( "drawGraph(): partition counts = ", @{$countsRef} );
	$totalCount = $$countsRef[ 0 ];
	$shownCount = $$countsRef[ 1 ];

	if( $totalCount != 0 )
	{
	    if( $shownCount == $totalCount )
	    {
		$countsStr = 'All';
	    }
	    else
	    {
		$countsStr = $shownCount . '/' . $totalCount;
	    }

	    if( $ref->{ $kAllShowingP } == 0 )
	    {
		$hspMid = getHspMid( $hspBefore, $hspAfter );
		drawString( $countsStr, GD::gdSmallFont(),
			   $realWidth - $imgRightBorder + 3, $hspMid,
			   pickColorN( $pdex ) );
	    }
	}
    }

    #dmsg( "...drawGraph()" );
}

sub getHspMid
{
    my( $hspBefore, $hspAfter ) = @_;
    my( $hspMid );

    $hspMid = $hspBefore + ($hspAfter - $hspBefore)/2 - $fontHeight/2 - 2;

    return( $hspMid );
}

#----------------------------------------
sub drawWrap
{
    my( $wrap ) = shift;
    my( $hspPos ) = shift;
    
    my( $hspBefore, $hspAfter, $hspMid );
    my( $fwdRef, $revRef );
    my( $fwdCount, $revCount );
    my( $bgY1, $bgY2 );
    my( $textPos );
    my( $colorN );
    my( $tickX );

    $fwdRef = $wrap->getForwardBucketSet();
    $revRef = $wrap->getReverseBucketSet();
    $fwdCount = $fwdRef->getCount(); # number of lines.
    $revCount = $revRef->getCount();

    # alternating background color. serious fudge factors
    # because i'm way too confused by math. so if you change
    # values in MapDefs this will be all wrong. sorry.
    $bgY1 = $hspPos;
    $bgY2 = $hspPos + $hspHeight * $wrap->getHSPLineCount() - 1;
    $curBgColor = ( $curBgColor == $bgColor2 ) ? $bgColor3 : $bgColor2;
    $img->filledRectangle( $ref->{ $kMapUtils }->getNoteLeft(), $bgY1, $realWidth-$imgRightBorder, $bgY2, $curBgColor );
    annotateIMap( $wrap, $ref->{ $kMapUtils }->getNoteLeft(), $bgY1, $realWidth-$imgRightBorder, $bgY2 );
   
    foreach $tickX ( @{$ref->{ $kTickList }} )
    {
	$img->line( $ref->{ $kMapUtils }->getQueryLeft()+$tickX, $bgY1, $ref->{ $kMapUtils }->getQueryLeft()+$tickX, $bgY2, $white );
    }
    if( $showNamesP )
    {
	$img->line( $ref->{ $kMapUtils }->getQueryLeft(), $bgY1, $ref->{ $kMapUtils }->getQueryLeft(), $bgY2, $white );
    }

    $colorN = getColorNFromP( $wrap, 0 );

    $hspBefore = $hspPos;
    if( $fwdCount > 0 )
    {
	#dmsg( "drawWrap(): fwd..." );
	$hspPos = drawDirection( $fwdRef->getBucketList(), $hspPos, 'plus', $colorN );
	#dmsg( "drawWrap(): ...fwd", $hspPos );
    }
    if( $revCount > 0 )
    {
	#dmsg( "drawWrap(): rev..." );
	$hspPos = drawDirection( $revRef->getBucketList(), $hspPos, 'minus', $colorN );
	#dmsg( "drawWrap(): ...rev", $hspPos );
    }
    $hspAfter = $hspPos;

    if( $showNamesP )
    {
	my( $mdefs ) = $ref->{ $kMapUtils };
	my( $buf ) = $mdefs->getNamesHorizBorder();
	my( $note ) = $wrap->getGraphAnnotation();
	my( $w, $h ) = $mdefs->getStringDimensions( $note );

	# [[ assuming that the border is at least as wide as the string! ]]
	$buf -= $w;
	$buf /= 2;

	my( $x ) = $mdefs->getNoteLeft() + $buf;

	$hspMid = getHspMid( $hspBefore, $hspAfter );
	$img->string( GD::gdSmallFont(), $x, $hspMid, $note, $black );
    }

    #dmsg( "...drawWrap()" );

    return( $hspPos );
}

#----------------------------------------
sub drawDirection
{
    my( $bucketList, $hspPos, $dir, $colorN ) = @_;
    my( $bucket );
    my( $regionList );
    my( $region );

    my( $start, $end, $scaledLength );
    my( $x1, $y1, $x2, $y2 );

    while( $bucket = $bucketList->shift() )
    {
	$regionList = $bucket->getRegions();
	while( $region = $regionList->shift() )
	{
	    #dmsg( "drawDirection(): unscaled = " . $region->run_list );

	    $start = round( $region->min() * $horizRatio );
	    $end = round( $region->max() * $horizRatio );
	    $scaledLength = $end - $start;
	    $x1 = $ref->{ $kMapUtils }->getQueryLeft() + $start;
	    $y1 = $hspPos + $hspArrowPad;
	    $x2 = $x1 + $scaledLength;
	    $y2 = $y1 + $arrowHeight;

	    #dmsg( $x1, $y1, $x2, $y2 );

	    drawArrowedOutlinedFromN( $x1, $y1, $scaledLength, $dir, $colorN );
	}

	$hspPos += $hspHeight;
    }

    return( $hspPos );
}

#----------------------------------------
# must come before drawGraph if
# you want the ticks everywhere.
sub drawQuery
{
    my( $length ) = shift;
    my( $ratio ) = shift;

    my( $rawX, $rawStep );
    my( $pX );
    my( $str );

    # try to space the ticks out reasonably.
    if( $length < 100 ) { $rawStep = 10; }
    elsif( $length < 500 ) { $rawStep = 50; }
    elsif( $length < 1000 ) { $rawStep = 100; }
    elsif( $length < 5000 ) { $rawStep = 200; }
    else { $rawStep = 500; }

    $img->line( $ref->{ $kMapUtils }->getQueryLeft(), $topDataOffset,
	        $ref->{ $kMapUtils }->getQueryLeft()+$length*$ratio, $topDataOffset,
	        $black );
    $img->string( GD::gdSmallFont(),
		  $ref->{ $kMapUtils }->getQueryLeft(), $topDataOffset-15,
		  "Query", $black );

    for( $rawX = $rawStep; $rawX < $length; $rawX += $rawStep )
    {
	$str = "$rawX";
	drawTick( $str, $rawX, $ratio );
    }

    # put little nobbins at the ends to signify, well, the ends.
    $pX = $ref->{ $kMapUtils }->getQueryLeft();
    $img->line( $pX, $topDataOffset, $pX, $topDataOffset+2, $black );
    $pX = $ref->{ $kMapUtils }->getQueryLeft()+($length*$ratio);
    $img->line( $pX, $topDataOffset, $pX, $topDataOffset+2, $black );
}

#----------------------------------------
sub drawTick
{
    my( $str, $rawX, $ratio ) = @_;

    my($nudgeTextX) = round(length($str)*5/2.0);
    my($pX) = int($rawX * $ratio);

    push( @{$ref->{ $kTickList }}, $pX );

    $img->line( $ref->{ $kMapUtils }->getQueryLeft()+$pX, $topDataOffset,
	        $ref->{ $kMapUtils }->getQueryLeft()+$pX, $topDataOffset-$tickHeight, $black );

    $img->string( GD::gdSmallFont(),
		  $ref->{ $kMapUtils }->getQueryLeft()+$pX-$nudgeTextX, $topDataOffset-15,
		  $str, $black );
}

#----------------------------------------
sub drawString
{
    my( $str, $font, $xpos, $ypos, $color ) = @_;
    my( $end );

    if( !defined( $color ) ) { $color = $black; }
    $end = length($str) * $fontWidth;
    $img->string( $font, $xpos, $ypos, $str, $color );

    return( $end );
}

#----------------------------------------
sub annotateIMap
{
    my( $wrap, $x1, $y1, $x2, $y2 ) = @_;

    my( $cx1, $cy1, $cx2, $cy2 );
    my( $name, $href );
    my( $englishDesc, $scoreDesc, $pos );

    print "<area shape=rect";
    print " ";

    $cx1 = $x1 - $arrowWidth;
    $cy1 = $y1;
    $cx2 = $x2 + $arrowWidth;
    $cy2 = $y2;
    print "coords=$cx1,$cy1,$cx2,$cy2";
    print " ";

    # [[ need to match the rest of the pages names.
    # unfortunately, it looks like the information required
    # isn't available from Blast.pm or Sbjct.pm.
    # so this is hardcoded to match that format as
    # much as possible, and requires the use of sed
    # in blast_web3.csh to clean things up. sucks. ]]

    # [[ furthermore, the format of the anchors that
    # are put in my blast2html aren't consistent with
    # the data i get from the hit object (e.g.:
    # when it's protien searches). kill me. ]]

    $name = $href = $wrap->getName();

    $href =~ s/_\d$//;
    print "href=\"#" . $href . "_A\"";
    print " ";

    $scoreDesc = "p=" . $wrap->getP() . " s=" . $wrap->getScore();
    $pos = $formFieldWidth - length($scoreDesc);

    $englishDesc = $wrap->getDescription();
    # it's stupid. the description can contain a *different* name!
    $name =~ s/([^_]*).*/$1/;
    if( $englishDesc !~ m/$name/i ) { $englishDesc = "$name|$englishDesc"; }
    $englishDesc = substr( $englishDesc, 0, $pos );

    # the description might contain 5' which then
    # confuses the hell out of javascript, so i
    # have to escape those.
    $englishDesc =~ s/\'/\&\#39/g;

    print "ONMOUSEOVER='document.daform.notes.value=\"$scoreDesc $englishDesc\"'";
    print ">\n";
}

sub makeColorBarHelper
{
    my( $min, $sep, $max, $colorN ) = @_;
    my( $str );

    if( ScientificNotation::numberP( $min ) )
    {
	$min = abs( ScientificNotation::getExponent( $min ) );
    }
    if( ScientificNotation::numberP( $max ) )
    {
	$max = abs( ScientificNotation::getExponent( $max ) );
    }

    $str = $min . $sep . $max;

    return( $str );
}

#----------------------------------------
sub makeColorBar
{
    my( @barParts );

    # going from worst to best.
    push( @barParts, makeColorBarHelper( '', '< ', $bucketThreeMax ), 4 );
    push( @barParts, makeColorBarHelper( $bucketThreeMax, '-', $bucketTwoMax ), 3 );
    push( @barParts, makeColorBarHelper( $bucketTwoMax, '-', $bucketOneMax ), 2 );
    push( @barParts, makeColorBarHelper( $bucketOneMax, '-', $bucketZeroMax ), 1 );
    push( @barParts, makeColorBarHelper( $bucketZeroMax, ' <', '' ), 0 );

    #dmsgs( "makeColorBar():", @barParts );

    return( @barParts );
}

#----------------------------------------
# this is a huge hack and will probably break easily. sorry.
sub drawKey
{
    my( @barParts );
    my( $xpos );
    my( $ypos );
    my( $strWidthPart );
    my( $strWidthPartMax );
    my( $strWidthFull ) = 0;
    my( $partPad ) = 10;
    my( $dex );
    my( $str );
    my( $strOffset );
    my( $clr );
    my( $scoreStr ) = "Neg P Exponent: ";

    # draw the fixed parts, the arrows.

    $strOffset = 22;

    $ypos = $realHeight - $imgBottomBorder + $bottomDataOffset;

    $xpos = $ref->{ $kMapUtils }->getQueryLeft();
    $strOffset = drawString( "Fwd:", GD::gdMediumBoldFont(), $xpos, $ypos+1, $grayDark );
    $xpos += $strOffset + 4;
    drawArrowedOutlined( $xpos, int($ypos+$fontHeight/2), 9, 'plus', $grayDark, $grayDark );

    $xpos += 18;
    drawString( "Rev:", GD::gdMediumBoldFont(), $xpos, $ypos+1, $grayDark );
    $xpos += $strOffset + 4;
    drawArrowedOutlined( $xpos, int($ypos+$fontHeight/2), 9, 'minus', $grayDark, $grayDark );

    @barParts = makeColorBar();

    # figure out box spacing.

    $strWidthPart = length($scoreStr) * $fontWidth + $partPad;
    $strWidthFull += $strWidthPart;

    for( $dex = 0; $dex < 5; $dex++ )
    {
	$str = $barParts[ $dex*2 ];
	$strWidthPart = length($str) * $fontWidth + $partPad;
      MyUtils::updateBoundRef( \$strWidthPartMax, $strWidthPart, \&MyUtils::largerP );
	$strWidthFull += $strWidthPart;
    }

    # center key in image.
    $xpos = $ref->{ $kMapUtils }->getQueryLeft() + int($ref->{ $kMapUtils }->getQueryWidth()-$strWidthFull)/2;
    # nudge it to the left to be optically more balanced.
    $xpos -= 5;

    $img->string( GD::gdMediumBoldFont(), $xpos, $ypos+1, $scoreStr, $grayDark );
    $xpos += length($scoreStr) * $fontWidth + $partPad;

    for( $dex = 0; $dex < 5; $dex++ )
    {
	$str = $barParts[ $dex*2 ];
	$clr = pickColorN( $barParts[ $dex*2 + 1 ] );

	$img->filledRectangle( $xpos, $ypos, $xpos+$strWidthPartMax, $ypos+$fontHeight+5, $clr );

	$strWidthPart = length($str) * $fontWidth;
	$strOffset = ( $strWidthPartMax - $strWidthPart ) / 2;
	$img->string( GD::gdSmallFont(), $xpos+$strOffset, $ypos+1, $str, $white );

	$xpos += $strWidthPartMax;
    }
}

#----------------------------------------
sub getArrowedLinePoly
{
    my( $x1, $y1, $scaledLength, $dir) = @_;
    my( $ymid, $x2, $y2, $poly, $poly );
    my( $fudge );

    # fudge-a-licious math to prevent the arrows from exploding if the
    # hit is smaller than an arrow width (since we normally draw the
    # arrows inside the bounding box of the hit).
    if( $scaledLength < ($arrowWidth*2) )
    {
	$fudge = (($arrowWidth * 2) - $scaledLength) / 2;
	$x1 -= $fudge;
	$scaledLength += ($fudge*2);
    }

    $x2 = $x1 + $scaledLength;
    $y2 = $y1 + $arrowHeight;
    $ymid = $y1 + $halfArrowHeight;
    $poly = new GD::Polygon;

    # drawing them with the arrows inside the bounding box.
    if( rightP($dir) )
    {
	# top.
	$poly->addPt( $x1, $y1 );
	$poly->addPt( $x2-$arrowWidth, $y1 );

	# rhs.
	$poly->addPt( $x2, $ymid );
	$poly->addPt( $x2-$arrowWidth, $y2 );

	# bottom.
	$poly->addPt( $x1, $y2 );

	# lhs.
	$poly->addPt( $x1+$arrowWidth, $ymid );
    }
    elsif( leftP( $dir ) )
    {
	# top.
	$poly->addPt( $x1+$arrowWidth, $y1 );
	$poly->addPt( $x2, $y1 );

	# rhs.
	$poly->addPt( $x2-$arrowWidth, $ymid );
	$poly->addPt( $x2, $y2 );

	# bottom.
	$poly->addPt( $x1+$arrowWidth, $y2 );

	# lhs.
	$poly->addPt( $x1, $ymid );
    }
    else
    {
	croak( "invalid direction $dir\n" );
    }

    return( $poly );
}

#----------------------------------------
sub drawArrowedOutlinedFromN
{
    my( $x1, $y1, $scaledLength, $dir, $colorN ) = @_;
    my( $light, $dark );

    $light = pickColorN( $colorN, 0 );
    $dark = pickColorN( $colorN, 1 );

    drawArrowedOutlined( $x1, $y1, $scaledLength, $dir, $light, $dark );
}

#----------------------------------------
sub drawArrowedOutlined
{
    my( $x1, $y1, $scaledLength, $dir, $light, $dark ) = @_;
    my( $poly );

    $poly = getArrowedLinePoly( $x1, $y1, $scaledLength, $dir );
    $img->filledPolygon( $poly, $light );

    # put an arrow in the middle, to help distinguish direction.
    # (try to avoid rounding problems.)
    my( $xmidLeft ) = $x1 + int($scaledLength/2) - $halfArrowWidth;
    my( $xmidRight ) = $xmidLeft + $arrowWidth;
    my( $ymid ) = $y1 + $halfArrowHeight;
    my( $y2 ) = $y1 + $arrowHeight;

    # used to use curBgColor but i think all white is more clear.
    if( rightP( $dir ) )
    {
	$img->line( $xmidLeft, $y1, $xmidRight, $ymid, $white );
	$img->line( $xmidRight, $ymid, $xmidLeft, $y2, $white );
    }
    else
    {
	$img->line( $xmidRight, $y1, $xmidLeft, $ymid, $white );
	$img->line( $xmidLeft, $ymid, $xmidRight, $y2, $white );
    }

    # now apply the outline.
    $img->polygon( $poly, $dark );
}

#----------------------------------------
sub getColorNFromP
{
    my( $wrap ) = shift;
    my( $darkP ) = shift;
    my( $value );
    my( $n );

    # [[ this assumes that we have 5 partitions,
    # since the number of colors is fixed. ]]

    $value = $wrap->getP();
    $n = $parts->getPartitionIndexFromExtendedValue( $value );

    return( $n );
}

#----------------------------------------
sub pickColorN
{
    my( $n ) = shift;
    my( $darkP ) = shift;
    my( $color );

    if( !defined($darkP) ) { $darkP = 0; }

    if( $n == 4 )
    {
	$color = ( $darkP == 1 ) ? $blueDark : $blue;
    }
    elsif( $n == 3 )
    {
	$color = ( $darkP == 1 ) ? $cyanDark : $cyan;
    }
    elsif( $n == 2 )
    {
	$color = ( $darkP == 1 ) ? $greenDark : $green;
    }
    elsif( $n == 1 )
    {
	$color = ( $darkP == 1 ) ? $magentaDark : $magenta;
    }
    elsif( $n == 0 )
    {
	$color = ( $darkP == 1 ) ? $redDark : $red;
    }
    else
    {
	croak( "pickColorN(): invalid index $n" );
    }

    return( $color );
}

#----------------------------------------
# cheap hack. shows a color based
# on $dex % 5.
sub pickNextDebugColors
{
    my( $color );
    my( $bgColor );
    my( $dex );

    $dex = $ref->{ $kDebugCount };

    if( $dex == 0 )
    {
	$bgColor = $blueDark;
	$color = $blue;
    }
    elsif( $dex == 1 )
    {
	$bgColor = $greenDark;
	$color = $green;
    }
    elsif( $dex == 2 )
    {
	$bgColor = $cyanDark;
	$color = $cyan;
    }
    elsif( $dex == 3 )
    {
	$bgColor = $magentaDark;
	$color = $magenta;
    }
    elsif( $dex == 4 )
    {
	$bgColor = $redDark;
	$color = $red;
    }

    $ref->{ $kDebugCount } = ++$dex % 5;

    return( $color, $bgColor );
}

#----------------------------------------
sub drawStamp
{
    my( @date ) = localtime();
    my( $dstr ) = join( "/", $date[4], $date[3], $date[5]+1900 );
    my( $xpos ) = $realWidth - (length( $dstr ) * $fontWidth) - $imgRightBorder;
    my( $ypos ) = $realHeight - $imgBottomBorder + $bottomDataOffset;

    drawString( $dstr, GD::gdSmallFont(), $xpos, $ypos, $grayDark );
}

#----------------------------------------
sub countHTML
{
    my( $shown, $max ) = @_;
    my( $word );

    if( $max > 1 ) { $word = 'hits'; }
    else { $word = 'hit'; }

    print( '<center><h1>Summary of BLAST Results</h1></center>' );

    print( '<p align=center>' );
    if( $shown < $max )
    {
	print( 'The graph shows the highest hits per range.<br>' );
	print( '<b>Data has been omitted:</b> ' );
	print( "$shown/$max $word displayed." );
    }
    else
    {
	print( 'All hits shown.' );
    }

    print( "</p>\n" );
}

#----------------------------------------
sub writeIMapStart
{
    print( "<center>\n" );
    print( "<FORM NAME=\"daform\">\n" );
    print( "<INPUT TYPE=\"text\" SIZE=\"$formFieldWidth\" NAME=\"notes\" VALUE=\"Mouse-overs require JavaScript\"><br>\n" );
    print( "<MAP NAME=\"$mapName\">\n" );
}

#----------------------------------------
sub writeIMapEnd
{
    print( "</MAP>\n" );
    print( "<img src=\"$dstURL$imgName\" usemap=\"#$mapName\" border = 0>\n" );
    print( "</FORM>\n" );
    print( "</center>\n" );
}

#----------------------------------------
sub rightP
{
    my( $dir ) = shift;
    my( $p );
    if( $dir =~ m/plus/i ) # is plus == right?
    {
	$p = 1;
    }
    else
    {
	$p = 0;
    }

    return( $p );
}

#----------------------------------------
sub leftP
{
    my( $dir ) = shift;
    my( $p );
    if( $dir =~ m/minus/i ) # is minus == left?
    {
	$p = 1;
    }
    else
    {
	$p = 0;
    }

    return( $p );
}
