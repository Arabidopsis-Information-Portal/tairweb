package MyBlast::MapUtils;

use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use MyUtils;
use MyDebug qw( assert dmsg );
use MyBlast::MapDefs
    qw( $imgWidth $imgHeight $fontWidth $fontHeight $imgTopBorder
       $imgBottomBorder $imgLeftBorder $imgRightBorder $namesHorizBorder
       $imgHorizBorder $imgVertBorder $arrowHeight $halfArrowHeight
       $arrowWidth $halfArrowWidth $hspPosInit $hspArrowPad $hspHeight
       $formFieldWidth $tickHeight $bottomDataOffset $topDataOffset
       $kNumberOfPartitions $bucketZeroMax $bucketOneMax $bucketTwoMax
       $bucketThreeMax $bucketFourMax );

@ISA = qw( BaseObj );

my( $kNamesP ) = MyUtils::makeVariableName( "names", "predicate" );
my( $kNamesHorizBorder ) = MyUtils::makeVariableName( "names", "horiz", "border" );
my( $kImgWidth ) = MyUtils::makeVariableName( "img", "width" );
my( $kQueryLeft ) = MyUtils::makeVariableName( "query", "left" );
my( $kQuerySpace ) = MyUtils::makeVariableName( "query", "space" );

sub init
{
    my( $self, $pP ) = @_;

    $self->putNamesP( $pP );
    $self->putNamesHorizBorder( $namesHorizBorder );
    $self->recalc();
}

sub recalc
{
    my( $self ) = shift;
    my( $pP ) = $self->getNamesP();
    my( $namesHorizBorder ) = $self->getNamesHorizBorder();
    my( $tmp );

    $tmp = $imgWidth;
    if( $pP ) { $tmp += $namesHorizBorder; }
    $self->{ $kImgWidth } = $tmp;

    $tmp = $self->getImgWidth() - $imgHorizBorder;
    if( $pP ) { $tmp -= $namesHorizBorder; }
    $self->{ $kQuerySpace } = $tmp;

    $tmp = $imgLeftBorder;
    if( $pP ) { $tmp += $namesHorizBorder; }
    $self->{ $kQueryLeft } = $tmp;
}   

sub putNamesP
{
    my( $self, $pP ) = @_;
    $self->{ $kNamesP } = $pP;
}

sub getNamesP
{
    my( $self ) = shift;
    return( $self->{ $kNamesP } );
}

sub putNamesHorizBorder
{
    my( $self ) = shift;
    my( $phb ) = shift;
    $self->{ $kNamesHorizBorder } = $phb;
    $self->recalc();
}

sub getNamesHorizBorder
{
    my( $self ) = shift;
    return( $self->{ $kNamesHorizBorder } );
}

sub getImgWidth
{
    my( $self ) = shift;
    return( $self->{ $kImgWidth } );
}

sub getNoteLeft
{
    my( $self ) = shift;
    return( $imgLeftBorder );
}

sub getQueryLeft
{
    my( $self ) = shift;
    return( $self->{ $kQueryLeft } );
}

sub getQueryWidth
{
    my( $self ) = shift;
    return( $self->{ $kQuerySpace } );
}

sub getStringDimensions
{
    my( $self, $str ) = @_;
    my( $w, $h );

    $w = length( $str ) * $fontWidth;
    $h = $fontHeight;

    return( $w, $h );
}

1;
