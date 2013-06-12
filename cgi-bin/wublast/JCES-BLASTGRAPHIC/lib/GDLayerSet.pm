package GDLayerSet;

require GD;
use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use MyUtils;
use MyDebug qw( dmsg );

@ISA = qw( BaseObj );

my( $kLayerHash ) = MyUtils::makeVariableName( "layer", "hash" );

sub init
{
    my( $self ) = shift;

    $self->{ $kLayerHash } = {};
}

sub getLayer
{
    my( $self, $name ) = @_;
    my( $img );

    $img = $self->{ $kLayerHash }->{ $name };

    return( $img );
}

sub newLayer
{
    my( $self, $name, $w, $h ) = @_;
    my( $img );
    
    $img = new GDLayer( $w, $h );
    $self->{ $kLayerHash }->{ $name } = $img;

    return( $img );
}

1;
