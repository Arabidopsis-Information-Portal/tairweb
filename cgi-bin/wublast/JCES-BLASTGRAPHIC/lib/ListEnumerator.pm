package ListEnumerator;

use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use MyUtils;
use MyDebug qw( dmsg );
use List;

@ISA = qw( BaseObj );

# sorry my enumerators suck so much.

my( $kList ) = MyUtils::makeVariableName( "list" );
my( $kIndex ) = MyUtils::makeVariableName( "index" );
my( $kMaxDex ) = MyUtils::makeVariableName( "max", "dex" );

sub init
{
    my( $self, $list ) = @_;

    #dmsg( "init(): ", $list->toString() );

    $self->{ $kList } = $list;
    $self->{ $kMaxDex } = $list->getCount() - 1;
    $self->reset();
}

sub reset
{
    my( $self ) = shift;
    $self->{ $kIndex } = -1;
}

sub getList
{
    my( $self ) = shift;
    return( $self->{ $kList } );
}

sub previousIndex
{
    my( $self ) = shift;
    my( $dex );

    $dex = $self->getIndex();

    # we can go back to -1, even though that
    # is sort of a cheesy hack, to show that
    # we don't want anything in the list.
    if( $dex > -1 )
    {
	$dex--;
    }

    $self->putIndex( $dex );
}

# have to call this first to start things off.
sub nextIndex
{
    my( $self ) = shift;
    my( $dex );
    my( $maxDex );

    $dex = $self->getIndex();
    $maxDex = $self->getMaxIndex();

    #dmsg( "nextIndex(): before =", $dex );

    # should be able to move to maxDex+1
    # which signifies there are no more elements.
    if( $dex <= $maxDex )
    {
	$self->putIndex( ++$dex );
    }

    #dmsg( "nextIndex(): after =", $self->getIndex() );
}

sub getCurrentElement
{
    my( $self ) = shift;
    my( $elem );
    my( $dex );
    my( $maxDex );

    $elem = undef;
    $dex = $self->getIndex();
    $maxDex = $self->getMaxIndex();

    #dmsg( "nextIndex(): dex=$dex maxDex=$maxDex" );

    if( $dex <= $maxDex )
    {
	$elem = $self->getList()->getElementAt( $dex );
    }

    return( $elem );
}

sub getNextElement
{
    my( $self ) = shift;
    $self->nextIndex();
    return( $self->getCurrentElement() );
}

sub getMaxIndex
{
    my( $self ) = shift;
    return( $self->{ $kMaxDex } );
}

sub getIndex
{
    my( $self ) = shift;
    return( $self->{ $kIndex } );
}

sub putIndex
{
    my( $self, $dex ) = @_;
    $self->{ $kIndex } = $dex;
}

sub getCount
{
    my( $self ) = shift;
    return( $self->getMaxIndex() );
}

1;
