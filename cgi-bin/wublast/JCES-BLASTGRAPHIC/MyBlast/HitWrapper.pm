package MyBlast::HitWrapper;

use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use MyUtils;
use MyDebug qw( assert dmsg );
use Region::BucketSet;
use Set::IntSpan;
use ScientificNotation;

@ISA = qw( BaseObj );

my( $kHit ) = MyUtils::makeVariableName( "hit" );
my( $kForwardHSPs ) = MyUtils::makeVariableName( "forward", "hsps" );
my( $kReverseHSPs ) = MyUtils::makeVariableName( "reverse", "hsps" );
my( $kSortedP ) = MyUtils::makeVariableName( "sorted", "predicate" );
my( $kLineCount ) = MyUtils::makeVariableName( "line", "count" );
my( $kForwardBucketSet ) = MyUtils::makeVariableName( "forward", "bucket", "set" );
my( $kReverseBucketSet ) = MyUtils::makeVariableName( "reverse", "bucket", "set" );

#
# instance stuff.
#

sub init
{
    my( $self, $hit ) = @_;

    $self->{ $kHit } = $hit;
    $self->{ $kForwardHSPs } = new List();
    $self->{ $kReverseHSPs } = new List();

    $self->{ $kSortedP } = 0;
    $self->sortHSPs();

    $self->{ $kForwardBucketSet } = new Region::BucketSet();
    $self->{ $kReverseBucketSet } = new Region::BucketSet();
    $self->calculateHSPLineCount();
}

sub toString
{
    my( $self ) = shift;
    my( $str );

    $str = MyUtils::makeDumpString( $self, $self->getName(), $self->getP(), $self->getScore() );

    return( $str );
}

sub getForwardBucketSet
{
    my( $self ) = shift;
    return( $self->{ $kForwardBucketSet } );
}

sub getReverseBucketSet
{
    my( $self ) = shift;
    return( $self->{ $kReverseBucketSet } );
}

sub getHit
{
    my( $self ) = shift;

    return( $self->{ $kHit } );
}

sub getForwardHSPs
{
    my( $self ) = shift;
    return( $self->{ $kForwardHSPs } );
}

sub getReverseHSPs
{
    my( $self ) = shift;
    return( $self->{ $kReverseHSPs } );
}

sub getStrandTypeCount
{
    my( $self ) = shift;

    my( $list );
    my( $count ) = 0;

    $list = $self->getForwardHSPs();
    if( $list->getCount() > 0 )
    {
	$count++;
    }

    $list = $self->getReverseRef();
    if( $list->getCount() > 0 )
    {
	$count++;
    }

    return( $count )
}

# should only ever be called by init.
sub sortHSPs
{
    my( $self ) = shift;

    my( $hit ) = $self->getHit();
    my( @hsps ) = $hit->hsps();
    my( $hsp, $queryDir, $hspDir );
    my( $fwd, $rev );

    $fwd = $self->getForwardHSPs();
    $rev = $self->getReverseHSPs();

    foreach $hsp ( @hsps )
    {
	($queryDir, $hspDir) = $hsp->strand();

	# [[ this makes everything relative to the
	# query sequence, which seems maybe bad. :} ]]
	if( $queryDir eq $hspDir )
	{
	    $fwd->addElement( $hsp );
	}
	else
	{
	    $rev->addElement( $hsp );
	}
    }

    # [[ we used to sort the HSPs left-to-right,
    # but right now i don't care. ]]
}

sub getP
{
    my( $self ) = shift;
    return( $self->getHit()->p() );
}

sub getPExponent
{
    my( $self ) = shift;
    my( $p );
    my( $exp );

    $p = $self->getP();
    $exp = ScientificNotation::getExponent( $p );
    #dmsg( "getPExponent: $p $exp" );

    return( $exp );
}

sub getScore
{
    my( $self ) = shift;
    return( $self->getHit()->score() );
}

sub getName
{
    my( $self ) = shift;
    return( $self->getHit()->name() );
}

sub getDescription
{
    my( $self ) = shift;
    return( $self->getHit()->desc() );
}

sub getGraphAnnotation
{
    my( $self ) = shift;
    return( $self->getName() . ' ' . $self->getP() );
}

sub calculateHSPLineCount
{
    my( $self ) = shift;

    #dmsg( "calculateHSPLineCount(): hit = " . $self->getHit()->name() );

    $self->addHSPsRef( $self->getForwardHSPs(), $self->getForwardBucketSet() );
    $self->addHSPsRef( $self->getReverseHSPs(), $self->getReverseBucketSet() );

    $self->{ $kLineCount } =
	$self->getForwardBucketSet()->getCount() +
	    $self->getReverseBucketSet()->getCount();
}

sub getHSPLineCount
{
    my( $self ) = shift;
    return( $self->{ $kLineCount } );
}

sub addHSPsRef
{
    my( $self, $list, $bset ) = @_;
    my( $hsp );
    my( $start, $end );
    my( $region );

    # the list could be empty (we don't
    # always have both forward and reverse hsps).   

    #dmsg( "addHSPsRef(): bset = $bset, count = " . $list->getCount() );

    foreach $hsp ( @{ $list->getElementsRef() } )
    {
	$start = $hsp->start( 'query' );
	$end = $hsp->end( 'query' );
	$region = new Set::IntSpan "$start-$end";
	#dmsg( "addHSPsRef(): hsp = ", $hsp->name(), $hsp, $region->run_list() );
	$bset->addRegion( $region );
    }
}

1;
