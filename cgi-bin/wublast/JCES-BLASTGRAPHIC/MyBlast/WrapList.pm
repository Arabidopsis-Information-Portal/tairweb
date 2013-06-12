package MyBlast::WrapList;

use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use List;
use ListEnumerator;
use ScientificNotation;
use MyBlast::HitWrapper;
use MyUtils;
use MyDebug qw( dmsg dmsgs );

@ISA = qw( List );

sub pValueSorterIncreasing
{
    my( $cmp );
    my( $aP, $bP );

    $aP = $a->getP();
    $bP = $b->getP();
    $cmp = ScientificNotation::cmp( $aP, $bP );

    return( $cmp );
}

sub mapHelper
{
    $_->getP();
}

sub sortByPValue
{
    my( $self ) = shift;
    my( @ray );

    @ray = @{$self->getElementsRef()};
    #dmsgs( "sortByPValue(): before = ", map( mapHelper, @ray ) );

    @ray = sort pValueSorterIncreasing @ray;
    #dmsgs( "sortByPValue(): after = ", map( mapHelper, @ray ) );

    $self->putElementsRef( \@ray );
}

# really, we're looking at the p value.
sub getLeastNonZeroElement
{
    my( $self ) = shift;
    my( $elem );
    my( $ref, $te );
    
    $ref = $self->getElementsRef();
    foreach $te ( @{$ref} )
    {
	if( ! ScientificNotation::isZero( $te->getP() ) )
	{
	    $elem = $te;
	    last;
	}
    }

    return( $elem );
}

1;
