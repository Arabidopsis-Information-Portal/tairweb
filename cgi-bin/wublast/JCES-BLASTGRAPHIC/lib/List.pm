package List;

use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use MyUtils;
use MyDebug qw( dmsg dmsgs );
use ListEnumerator;

@ISA = qw( BaseObj );

#
# basically, just a wrapper so we can
# use it in ListSet a little more clearly.
# tho you cannot have undefs as elements of the list.
#

my( $kElements ) = MyUtils::makeVariableName( "elements" );

sub init
{
    my( $self, @ref ) = @_;

    # this sure is gross, but it seems to work.
    if( defined( @ref ) )
    {
	if( ref( $ref[0] ) eq "ARRAY" )
	{
	    #dmsg( "got reference to array" );
	    $self->{ $kElements } = $ref[0];
	}
	elsif( !ref( $ref[0] ) )
	{
	    #dmsg( "got array itself" );
	    $self->{ $kElements } = \@ref;
	}
    }
    else
    {
	#dmsg( "no ref given at all" );
	$self->{ $kElements } = [];
    }
}

sub getElementsRef
{
    my( $self ) = shift;
    return( $self->{ $kElements } );
}

sub putElementsRef
{
    my( $self, $lref ) = @_;
    $self->{ $kElements } = $lref;
}

sub addElement
{
    my( $self, $elem ) = @_;
    push( @{$self->getElementsRef}, $elem );
}

# dex is zero based.
sub getElementAt
{
    my( $self, $dex ) = @_;
    my( $ref );
    my( $maxDex );
    my( $elem );

    $elem = undef;
    $maxDex = $self->getCount()-1;

    if( $dex <= $maxDex )
    {
	$ref = $self->getElementsRef();
	$elem = $ { $ref } [ $dex ];
    }
 
    return( $elem );
}

sub removeElement
{
    my( $self, $elem ) = @_;
    my( $ref );
    my( $dex );
    my( $test );

    $ref = $self->getElementsRef();
    for( $dex = 0; $dex < $self->getCount(); $dex++ )
    {
	$test = $self->getElementAt( $dex );
	last if( $test == $elem );
    }

    splice( @{$ref}, $dex, 1 );
}

sub shift
{
    my( $self ) = shift;
    my( $val );

    $val = shift( @{$self->getElementsRef()} );
    #dmsg( "shift(): $val" );
    return( $val );
}

sub shiftSafe
{
    my( $self ) = shift;
    my( $val );

    if( $self->emptyP() )
    {
	$val = undef;
    }
    else
    {
	$val = $self->shift();
    }

    return( $val );
}

# return 1 based count.
sub getCount
{
    my( $self ) = shift;
    my( $ref ) = $self->getElementsRef();
    #dmsgs( "getCount(): ref = ", @{$ref} );
    my( $count ) = scalar( @{$self->getElementsRef()} );
    #dmsg( "getCount(): count = ", $count );
    return( $count );
}

sub emptyP
{
    my( $self ) = shift;
    my( $emptyP );

    if( $self->getCount() == 0 )
    {
	$emptyP = 1;
    }
    else
    {
	$emptyP = 0;
    }

    return( $emptyP );
}

# [[ $sub is the fully qualified name of a sorter subroutine.
# that routine must refer to $List::a and $List::b to work;
# perl suck. ]]
# subclasses might override this to provide a fixed
# sorting method, which ignores any given subroutine.
sub sort
{
    my( $self, $sub ) = @_;
    my( $lref );
    my( @ray );

    $lref = $self->getElementsRef();

    @ray = sort $sub @{$lref};

    $self->putElementsRef( \@ray );
}

# n is zero based.
# element at location n is also removed.
sub truncateAt
{
    my( $self, $n ) = @_;
    my( $lref );

    if( $n < 0 )
    {
	$self->putElementsRef( [] );
    }
    else
    {
	$lref = $self->getElementsRef();
	splice( @{$lref}, $n );
    }
}

sub getEnumerator
{
    my( $self ) = shift;
    return( new ListEnumerator( $self ) );
}

sub toString
{
    my( $self ) = shift;
    my( $str );

    $str = MyUtils::makeDumpString( $self, $self->getCount, @{$self->getElementsRef()} );

    return( $str );
}

1;
