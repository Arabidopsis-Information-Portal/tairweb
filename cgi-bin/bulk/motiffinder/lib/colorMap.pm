package colorMap;
#class for generating an image 'cell' on passing a value according to 
# a supplied or default scale;
#

use GD;
use strict;



sub new{

    ##returns new colorMap object;
    ## pass x and y arguments for size of rectangle to generate;
    
    my $class = shift;
    my %args = ('x'=> 10, 'y'=>10 , @_ );
    
    my $self = bless {} , $class;
    
    ( $self->{'_image_size_x'}, $self->{'_image_size_y'} ) = ($args{'x'}, $args{'y'});

    
    
    ##set up standard gd object
    $self->_standardGDObj($self->{'_image_size_x'}, $self->{'_image_size_y'});

    return $self;

}

sub setBins{


    ##call this method with list of arguments which will be the 'bins'
    ##defaults to default bins if no arguments supplied;
    my $self = shift;
    

    my @default_bins = ( 1e-2, 1e-5, 1e-10, 1e-20,1e-30,1e-50, 1e-100,1e-150,1e-200,1e-320);

    my @args = ( @_ );
    @args = @default_bins if (scalar @args < 2);

    $self->{'_peak'}  = pop @args;
    $self->{'_cutoff'}  = shift @args;
    $self->{'_bins'}->{ $self->{'_peak'} } = 255;
    $self->{'_bins'}->{ $self->{'_cutoff'} } = 0;

    my $number_elements = scalar @args;
    my $increment = int( 255/($number_elements + 1) );
    my $i;
    
    for ($i = $increment; $i <= 255; $i += $increment){

	last if (@args < 1);
	my $element = shift @args;
	$self->{'_bins'}->{ $element } = $i;
	

    }

    
    
    
    

}


sub _standardGDObj{

    ##internal - set up standard GD obj;
    my $self = shift;
    my $x = shift;
    my $y = shift;
    
    if (! $x || ! $y){

	$self->{'_image'} = GD::Image->new();
	
    }else{

	$self->{'_image'} = GD::Image->new($x, $y);
    }

}

sub plotCell{

    ##call this method to return an image representing the supplied valye
    ##
    
    
    my $self = shift;
    $self->setBins() if ( ! $self->{'_bins'});
    
    my %args = ('value' => 1, @_);

    my $increment = $self->_bin($args{'value'}) ;
    my $im = $self->{'_image'};
    
    $im ->filledRectangle(0, 0, $self->{'_image_size_x'}, $self->{'_image_size_y'},$im->colorAllocate(0, $increment, 0 )  );
	
    $self->_standardGDObj($self->{'_image_size_x'}, $self->{'_image_size_y'});

    

    return $im->gif;
}

sub legend{

    ##returns hash - keys are 'values' , values are images;
    my $self = shift;
    my $key;
    my $h_ref;

    for $key(keys %{$self->{'_bins'}}){

	$h_ref->{sprintf "%.1e", $key} = $self->plotCell('value' => $key);

    }
    
    return $h_ref;
}


sub _bin{
    
    #internal method to assign value to appropriate bin


    my $self = shift;
    my $value = shift;

    
    for my $key(sort {$b <=> $a} keys %{ $self->{'_bins'}}){

	
	return $self->{'_bins'}->{$key} if ($value >= $key);
	
    }

    return $self->{'_bins'}->{ $self->{'_peak'} };

    
}



1;








