package MyDebug;

use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use Carp;
require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( debugP dmsg dmsgs assert );

my( $pkgOn ) = {};

sub debugP
{
    my( $flag ) = shift;

    my( $pkg, $file, $line ) = caller();

    $pkgOn{ $pkg } = $flag;
}

# concatenates with " ".
sub dmsg
{
    my( @msg ) = @_;
    my( $flag );

    ( $pkg, $file, $line ) = caller();

    $flag = $pkgOn{ $pkg };
    
    if( !defined($flag) || $flag != 0 )
    {
	print STDERR "[$pkg $line]", join( " ", @msg ), "\n";
    }
}

# concatenates with ", ".
sub dmsgs
{
    my( @msg ) = @_;
    my( $flag );

    ( $pkg, $file, $line ) = caller();

    $flag = $pkgOn{ $pkg };
    
    if( !defined($flag) || $flag != 0 )
    {
	print STDERR "[$pkg $line]", join( ", ", @msg ), "\n";
    }
}

sub assert
{
    my( $val, @msg ) = @_;

    if( ! $val )
    {
	confess( "[" . join( " ", @msg ) . "]" );
    }
}

1;
