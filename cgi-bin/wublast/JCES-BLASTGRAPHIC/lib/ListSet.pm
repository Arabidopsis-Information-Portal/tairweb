package ListSet;

use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use MyUtils;
use MyDebug qw( dmsg dmsgs assert );
use List;
use ListSetEnumerator;

@ISA = qw( BaseObj );

my( $kLists ) = MyUtils::makeVariableName( "lists" );

sub init
{
    my( $self ) = shift;

    $self->{ $kLists } = {};
}

sub getKeys
{
    my( $self ) = shift;
    my( @keys );

    @keys = keys( %{$self->{ $kLists }} );
    #dmsgs( "getKeys(): ", @keys );

    return( @keys );
}

# overwrites any existing list at key with given list.
sub putListAt
{
    my( $self, $n, $list ) = @_;

    $self->{ $kLists }->{ $n } = $list;
}

sub getListAt
{
    my( $self, $n ) = @_;

    my( $list );

    $list = $self->{ $kLists }->{ $n };
    if( !defined($list) )
    {
	$self->{ $kLists }->{ $n } = $list = new List();
	#dmsg( "getListAt( $n ): new ", $list->toString() );
    }

    return( $list );
}

sub removeListAt
{
    my( $self, $n ) = @_;
    my( $ref );

    $ref = $self->{ $kLists };
    delete( $ref->{ $n } );
}

sub emptyP
{
    my( $self ) = shift;
    my( @keys );
    my( $key );
    my( $list );
    my( $emptyP );

    @keys = keys( %{$self->{ $kLists }} );
    $emptyP = 1;

    while( $emptyP && scalar(@keys) > 0 )
    {
	$key = shift( @keys );
	$list = $self->{ $kLists }->{ $key };
	$emptyP = $list->emptyP();
    }

    return( $emptyP );
}

sub getCount
{
    my( $self ) = shift;
    my( $count );

    $count = scalar( $self->getKeys() );

    return( $count );
}

sub getEnumerator
{
    my( $self ) = shift;

    return( new ListSetEnumerator( $self ) );
}

sub toString
{
    my( $self ) = shift;
    my( $str );
    my( @strs );
    my( $enum );
    my( $list );

    $enum = $self->getEnumerator();
    while( defined( $list = $enum->getNextElement() ) )
    {
	push( @strs, " " . $list->toString() . "\n" );
    }
    $str = MyUtils::makeDumpString( $self, $self->getCount() . "\n", @strs );

    return( $str );
}

1;
