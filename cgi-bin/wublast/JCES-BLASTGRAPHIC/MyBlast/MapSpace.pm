package MyBlast::MapSpace;

use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use MyUtils;
use MyBlast::MapDefs;
use MyBlast::HitWrapper;
use MyDebug qw( assert dmsg );

@ISA = qw( BaseObj );

my( $kInitialSpace ) = MyUtils::makeVariableName( "initial", "space" );
my( $kSpaceRemaining ) = MyUtils::makeVariableName( "space", "remaining" );
my( $kFullP ) = MyUtils::makeVariableName( "full", "predicate" );

sub init
{
    my( $self ) = shift;

    $self->{ $kInitialSpace } =
	$self->{ $kSpaceRemaining } =
	    ($MyBlast::MapDefs::imgHeight -
	     $MyBlast::MapDefs::hspPosInit -
	     $MyBlast::MapDefs::imgBottomBorder );

    #dmsg( "init(): space = ", $self->getSpaceRemaining() );
}

sub getSpaceRemaining
{
    my( $self ) = shift;
    return( $self->{ $kSpaceRemaining } );
}

sub getSpaceUsed
{
    my( $self ) = shift;
    return( $self->{ $kInitialSpace } - $self->{ $kSpaceRemaining } );
}

sub putSpaceRemaining
{
    my( $self, $space ) = @_;
    assert( $space >= 0, "space must be non-negative" );
    $self->{ $kSpaceRemaining } = $space;
}

# return true iff the last call to wrapperFitsP returned false.
sub getFullP
{
    my( $self ) = shift;
    return( $self->{ $kFullP } );
}

sub putFullP
{
    my( $self, $fp ) = @_;
    $self->{ $kFullP } = $fp;
}

sub wrapperFitsP
{
    my( $self, $wrap ) = @_;
    my( $space );
    my( $wheight );
    my( $fitsP );

    $space = $self->getSpaceRemaining();

    $wheight = $wrap->getHSPLineCount() * $MyBlast::MapDefs::hspHeight;
    if( $wheight <= $space )
    {
	$fitsP = 1;
	#dmsg( "wrapperFitsP(): $wheight <= $space" );
    }
    else
    {
	$fitsP = 0;
	#dmsg( "wrapperFitsP(): $wheight > $space" );
    }

    $self->{ $kFullP } = (! $fitsP);

    return( $fitsP );
}

sub updateFromWrapper
{
    my( $self, $wrap ) = @_;
    my( $space );
    my( $count );
    my( $wheight );

    $space = $self->getSpaceRemaining();
    $count = $wrap->getHSPLineCount();
    $wheight = $count * $MyBlast::MapDefs::hspHeight;
    #dmsg( "updateFromWrapper(): ", $wrap->getName(), "$count $wheight" );

    assert( $wheight <= $space, "not enough space left" );

    $self->putSpaceRemaining( $space - $wheight );
}

1;
