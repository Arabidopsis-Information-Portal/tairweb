package BaseObj;

use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use MyUtils;
use MyDebug qw( dmsg );

sub new
{
    my( $class, @args ) = @_;

    my( $self ) = {};
    bless( $self, $class );
    $self->init( @args );

    return( $self );
}

sub init
{
    my( $self ) = shift;
}

1;
