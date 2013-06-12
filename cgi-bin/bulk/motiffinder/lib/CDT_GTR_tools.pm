package CDT_GTR_tools;




=head1 NAME

    CDT_GTR_tools - simple parsing and selection of data from the cdt/gtr files used by SMD
    

=head1 SYNOPSIS


    use CDT_GTR_tools
    my $object = CDT_GTR_tools->new('cdt'=> "full path to name of my cdt file", 'gtr'=>"full path .. gtr file")
    $object->getValues()
    $object->setCorrCutOff('correlation coeff threshold')
    $object->setNodeSizeCutOff('node size threshold')
    $object->setNodeNames($referenceToArrayOfNodeNames)
    $object->getCorr()
    $object->getNodes()



=head1 DESCRIPTION

    Conceived of as simple means for parsing cdt/gtr files. Example
    functionality: returning correlation values for a subset of the
    clusters in a hierarchical tree, returning all those clusters
    (nodes) with more than a number of objects (clones..), returning
    all those nodes with correlation value greater than a given
    value..

=head1 METHODS

    new('cdt'=> "full path to name of my cdt file", 'gtr'=>"full path
    .. gtr file") initialises the object, the names (full paths if
    necessary) of the cdt and gtr file should be passed as arguments
    as shown. Note performs rudimentary checking of the cdt/gtr files,
    will complain/stop if finds a problem with these files.

    getValues() Currently unfinished method. At present simply returns
    ref to hash where keys are array elements ('GENE1X' etc) and value
    is string containing the expression value.


    getNodes(). Returns a ref to hash in which keys are clusters
    'NODE1X' etc and keys are arrays of genes 'GENE1X' etc. See the
    three methods below  for how to specify which clusters you want.


    setCorrCutOff('correlation coeff threshold'). Set the cutoff value
    for the correlation coeff associated with each node. This method
    should be used with the getNodes method above which will return
    all those clusters with a coeff greater than the value passed to
    setCorrCutOff

    setNodeSizeCutOff('node size threshold'). Similar to the
    setCorrCutOff method. Pass a number as the argument - this is the
    minimum size of clusters to be returned by getNodes.

    setNodeNames($referenceToArrayOfNodeNames). Pass and array of
    nodenames to be returned by getNodes().

    
    getCorr(). Returns ref to hash where keys are nodes and vals are
    correlation coeffs for nodes passed to setNodeNames.



=head1 AUTHOR

    Rob Ewing.
    Last Update Fri Sep  7 15:41:47 PDT 2001
    

=cut









use IO::File;
use strict;
use Data::Dumper;
##simple parsing of cdt/gtr files (both must be given).




sub new{

    my $class = shift;
    my $self;
    my ( %args ) = ('cdt'=>"", 'gtr'=>"", @_);

    $self->{'_gtrFH'} = IO::File->new("< $args{'gtr'}");
    $self->{'_cdtFH'} = IO::File->new("< $args{'cdt'}");
    
    die "Usage new('cdt'=>cdtFile, 'gtr'=>gtrFile)\n" if (! defined $args{'cdt'} || ! defined $args{'gtr'}  || ! $self->{'_gtrFH'} || ! $self->{'_cdtFH'});

    
    bless $self, $class;
    $self->_parseCDT();
    $self->_parseGTR();

    
    ##number of nodes should be number of leaves - 1:
    die "Correct CDT/GTR pair?\n" if ( scalar keys %{$self->{'_gids'}} !=  ( scalar keys %{$self->{'_nodes'} } ) + 1);
    
    return $self;
    

}

sub _parseCDT{

    ##parse standard cdt - retrieve gid and uniqid for each element

    my $self = shift;
    my $fh = $self->{'_cdtFH'};
    my $hash_ref;

    while(<$fh>){

	my @line = split /\t/;
	
	if ($.==1){
	    
	    for ( my $i = 0; $i <= $#line; $i ++){
		
		$hash_ref->{ $line[$i] } = $i; 
	    }
	}
	next if (! /^GENE\d+X/);
	
	##set $name to be what you want - CLID, NAME etc;
	my ($gid, $name) = ( $line[ $hash_ref->{'GID'}  ],  $line[ $hash_ref->{'CLID'} ] );
	$self->{'_values'}->{$gid} = join (" ", splice (@line, 3) );
	$self->{'_gids'}->{$gid} = $name;
    }
}



sub _parseGTR{


    my $self = shift;
    my $fh = $self->{'_gtrFH'};

    while(<$fh>){

        my ( $node, $subnode1, $subnode2, $corr ) = split /\s+/, $_;
    
	$self->{'_corr'}->{$node} = $corr;

	if (defined $self->{'_gids'}->{$subnode1} ) {
	
	    push @{ $self->{'_nodes'}->{$node} }, $self->{'_gids'}->{$subnode1};
    
	}elsif( defined $self->{'_nodes'}->{$subnode1} ){
	
	    push @{ $self->{'_nodes'}->{$node} }, @{ $self->{'_nodes'}->{$subnode1} };
    }

 
	if (defined $self->{'_gids'}->{$subnode2} ) {
	
	    push @{ $self->{'_nodes'}->{$node} }, $self->{'_gids'}->{$subnode2};
    
	}elsif( defined $self->{'_nodes'}->{$subnode2} ){
	
	    push @{ $self->{'_nodes'}->{$node} }, @{ $self->{'_nodes'}->{$subnode2} };
	}

	

    }


}

sub getValues{

    ##unfinished - simply dumps hash at present;
    my $self = shift;
    return $self->{'_values'};
}

sub setCorrCutOff{
    my $self = shift;
    $self ->{'_corrCutOff'} = shift;
}

sub setNodeSizeCutOff{
    my $self = shift;
    $self->{'_nodeSizeCutOff'} = shift;
}

sub setNodeNames{
    ##pass ref to array of selected nodes;
    my $self = shift;
    $self->{'_nodeNames'} = shift;
}

sub getCorr{
    
    ##returns correlation values for nodes set using setNodeNames;
    
    my $self = shift;
    return 0 if (! $self->{'_nodeNames'} );
    
    my $h_ref;
    for my $node( @{$self->{'_nodeNames'}} ){

	$h_ref->{$node} = $self->{'_corr'}->{$node};
    }
    return $h_ref;
    
    
}

sub getNodes{


    ##return h_ref of nodes according to cutoffs;
    ## size cutoff applied before correlation cutoff;
    
    my $self = shift;
    my $h_ref;
    
    if ( defined $self->{'_nodeNames'} ){
	
	for my $node( @{ $self->{'_nodeNames'} } ){

	    $h_ref->{$node} = \@{$self->{'_nodes'}->{$node} };
	}
	return $h_ref;
	
	
    }elsif (! defined $self->{'_nodeSizeCutOff'} && ! defined $self->{'_corrCutOff'}){
	
	$h_ref = $self->{'_nodes'}  ;
	
    }elsif (defined $self->{'_nodeSizeCutOff'} && defined $self->{'_corrCutOff'}){

	for my $node(sort { scalar @{ $self->{'_nodes'}->{ $b } } <=> scalar @{ $self->{'_nodes'}->{ $a } } } keys %{ $self->{'_nodes'} } ){

	    last if (scalar @{ $self->{'_nodes'}->{$node} } <  $self->{'_nodeSizeCutOff'} );
	    
	    $h_ref->{$node}  = \@{ $self->{'_nodes'}->{$node} } if ($self->{'_corr'}->{$node} >= $self->{'_corrCutOff'});
	

	}

	
    }elsif (defined $self->{'_corrCutOff'}){

	for my $node(sort { $self->{'_corr'}->{ $b }  <=> $self->{'_corr'}->{ $a }  } keys %{ $self->{'_corr'} } ){

	    last if ( $self->{'_corr'}->{$node}  <  $self->{'_corrCutOff'} );
	    
	    $h_ref->{$node}  = \@{ $self->{'_nodes'}->{$node} } ;
	    
	}
   
	
    }elsif(defined $self->{'_nodeSizeCutOff'} ){


	for my $node(sort { scalar @{ $self->{'_nodes'}->{ $b } } <=> scalar @{ $self->{'_nodes'}->{ $a } } } keys %{ $self->{'_nodes'} } ){

	    last if (scalar @{ $self->{'_nodes'}->{$node} } <  $self->{'_nodeSizeCutOff'} );
	    
	    $h_ref->{$node}  = \@{ $self->{'_nodes'}->{$node} } ;
	
	}
    
    }

    return $h_ref;
}
1;
