package GDLayer;

require GD;
use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use MyUtils;
use MyDebug qw( dmsg );

@ISA = qw( BaseObj );

my( $kImage ) = MyUtils::makeVariableName( "image" );
my( $kWidth ) = MyUtils::makeVariableName( "width" );
my( $kHeight ) = MyUtils::makeVariableName( "height" );
my( $kUsedWidth ) = MyUtils::makeVariableName( "used", "width" );
my( $kUsedHeight ) = MyUtils::makeVariableName( "used", "height" );

sub init
{
    my( $self, $w, $h ) = @_;
    my( $img );

    $self->{ $kWidth } = $w;
    $self->{ $kHeight } = $h;
    $img = $self->{ $kImage } = new GD::Image( $w, $h );

    # [[ sucks that we probably have to maintain a color
    # table for each image. ]]

    $self->{ $kBlack } = $img->colorAllocate( 0, 0, 0 );
    $self->{ $kWhite } = $img->colorAllocate( 255, 255, 255 );
    $self->{ $kGrayLight } = $img->colorAllocate( 204, 204, 204 );
    $self->{ $kGray } = $img->colorAllocate( 153, 153, 153 );
    $self->{ $kGrayDark } = $img->colorAllocate( 102, 102, 102 );
    $self->{ $kBgColor2 } = $white;
    $self->{ $kBgColor3 } = $grayLight;
    $self->{ $kDebugColor } = $img->colorAllocate( 0, 204, 0 );

    # brighter blues because they are so dark to begin with.
    $self->{ $kBlue } = $img->colorAllocate( 51, 51, 204 );
    $self->{ $kBlueDark } = $img->colorAllocate( 51, 51, 153 );
    $self->{ $kCyan } = $img->colorAllocate( 0, 204, 204 );
    $self->{ $kCyanDark } = $img->colorAllocate( 0, 153, 153 );
    $self->{ $kGreen } = $img->colorAllocate( 0, 204, 0 );
    $self->{ $kGreenDark } = $img->colorAllocate( 0, 153, 0 );
    $self->{ $kMagenta } = $img->colorAllocate( 204, 0, 204 );
    $self->{ $kMagentaDark } = $img->colorAllocate( 153, 0, 153 );
    $self->{ $kRed } = $img->colorAllocate( 204, 0, 0 );
    $self->{ $kRedDark } = $img->colorAllocate( 153, 0, 0 );
}

sub updateUsedWidth
{
    my( $self, $x ) = @_;

  MyUtils::updateBoundRef( \$self->{ $kUsedWidth }, $x, \&MyUtils::largerP );
}

sub updateUsedHeight
{
    my( $self, $y ) = @_;

  MyUtils::updateBoundRef( \$self->{ $kUsedHeight }, $y, \&MyUtils::largerP );
}

sub getImage
{
    my( $self ) = shift;
    return( $self->{ $kImage } );
}

sub getWidth
{
    my( $self ) = shift;
    return( $self->{ $kWidth } );
}

sub getHeight
{
    my( $self ) = shift;
    return( $self->{ $kHeight } );
}

sub getUsedWidth
{
    my( $self ) = shift;
    return( $self->{ $kUsedWidth } );
}

sub getUsedHeight
{
    my( $self ) = shift;
    return( $self->{ $kUsedHeight } );
}

1;
