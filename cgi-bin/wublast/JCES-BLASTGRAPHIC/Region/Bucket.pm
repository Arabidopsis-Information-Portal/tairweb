package Region::Bucket;

# our more useful version of an IntSpan.

use Carp;
use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use Set::IntSpan;
use MyUtils;
use MyDebug qw( dmsg assert );
use List;

@ISA = qw( BaseObj );

my( $kSpan ) = MyUtils::makeVariableName( "span" );

sub init
{
    my( $self, $arg ) = @_;

    $self->{ $kSpan } = new Set::IntSpan $arg;
}

sub toString
{
    my( $self ) = shift;

    return( $self->getSpan()->run_list );
}

sub getSpan
{
    my( $self ) = shift;

    return( $self->{ $kSpan } );
}

sub addRegion
{
    my( $self, $region ) = @_;

    assert( $self->disjointP($region) == 1, "illegal overlap",
	    $self->getSpan()->run_list(), $region->run_list() );

    $self->{ $kSpan } = $self->getSpan()->union( $region );
}

sub getRegions
{
    my( $self ) = shift;
    my( $runStr );
    my( @runs );
    my( $run );
    my( $region );
    my( $regionList );

    $regionList = new List();

    $runStr = $self->getSpan()->run_list();
    @runs = split( /,/, $runStr );
    foreach $run ( @runs )
    {
	$region = new Set::IntSpan $run;
	$regionList->addElement( $region );
    }

    return( $regionList );
}

sub getIntersection
{
    my( $self ) = shift;
    my( $otherSpan ) = shift;
    my( $bucketSpan );
    my( $iset );

    $bucketSpan = $self->getSpan();
    $iset = intersect $bucketSpan $otherSpan;

    return( $iset );
}

sub disjointP
{
    my( $self ) = shift;
    my( $otherSpan ) = shift;
    my( $bucketSpan );
    my( $iset );
    my( $empty );
    my( $emptyP );

    $bucketSpan = $self->getSpan();
    $iset = $self->getIntersection( $otherSpan );

    if( empty $iset )
    {
	$emptyP = 1;
    }
    else
    {
	$emptyP = 0;
    }
    #dmsg( "disjointP():", $emptyP, $iset->run_list );

    return( $emptyP );
}

1;
