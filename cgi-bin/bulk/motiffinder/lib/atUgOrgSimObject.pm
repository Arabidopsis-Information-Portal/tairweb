package atUgOrgSimObject;

use strict;
use DBI;

use Data::Dumper;
use lib "/share/daisy/www-data/lib/common";
use Login  qw (ConnectToDatabase);

=head1 NAME

    atUgOrgSimObject -- class for querying at_ugorgsim view in mdev

=head1 SYNOPSIS

    use atUgSeqObject;

    $obj = atUgOrgSimObject->new();
    $obj->getByProfile('hs < 1e-10', 'mm > .001', ...)
    $obj->getByClusterid('clusterids'=>['clusterid', 'clusterid', ... ])
    $obj->numberRows()


=head1 DESCRIPTION

    at_ugOrgSim view holds best matches (e-values) of at consensus
    seqs to whole genomes/ partial genomes of other organisms. This
    class allows simple querying of the at_ugOrgSim table


=head1 METHODS


    new() return a new atUgOrgSimObject object 

    getByProfile($arg1, $arg2, ...) where arguments take form of
    'organism < e-value' . These args are passed fairly directly into
    the sql - so organism should correspond directly to one of columns
    in at_ugorgsim view - i.e hs, mm, rn etc. Evalue may or may not be
    in scientific notation. Operator may be '<' or '>'.Must be spaces
    between 'organism', operator and evalue. Returns whole rows from
    at_ugorgsim view - as array of hashes, in addition to the number
    of sequences corresponding to each clusterid. If no arguments
    supplied to getByProfile - will return all rows from the table. If
    arguments are incorrectly formed will return 0.

    getByClusterid('clusterids' => ['clusterid', 'clusterid', ... ] )
    Returns whole rows from at_ugorgsim view - as array of hashes in
    addition to the number of seqs corresponding to clusterid. Returns
    0 if no arguments supplied.

    numberRows() may be called after call to getByProfile or
    getByClusterid to return number of resulting rows from the query



=head1 AUTHOR


    Rob Ewing. 
    
    Update
    Thu Jun 15 12:37:46 2000
    getByClusterid method added
    Objects made resuable
    Now sorts the results according to the _sortResults method.
    (Currently sorted by number of sequences in clusterid / clusterid number)
    getByProfile first creates data structure holding all data - and querying
    is done entirely on perl side

=cut



sub new{

    
    my $class = shift;
    my $h_ref = {};
    bless $h_ref, $class;

    $h_ref->_connect(); ## make connection to mdev
    return $h_ref;

}

sub numberRows{

    ##return number of rows from query;
    my $self = shift;

    return 0 if (! $self->{'_data'});

    return scalar @{$self->{'_data'}};

}

sub getByClusterid{

    my $self = shift;
    ##so that objects can be reused:
    $self->_sql();
    delete $self->{'_data'};
    delete $self->{'_sth'};
    ###############################
    
    
    my %args = ( 'clusterids' => [], @_ );
    return if (scalar @{ $args{'clusterids'} } < 1);
    
    
    $self->{'_sth'} = ( $self->{'_dbh'} )->prepare( $self->{'_sql1'} );
    
    
    for my $clusterid( @{ $args{'clusterids'} } ){

	eval{ ( $self->{'_sth'} ) ->execute ( $clusterid ) };
	next if ($@);

	my $h_ref = ( $self->{'_sth'} )->fetchrow_hashref;
	
	push @{ $self->{'_data'} } , $h_ref;

    }
    
    $self->_sortResults();
    return $self->{'_data'};
    
}


sub getByProfile{

    ##NOTE oracle cannot handle comparisons of numbers < 1e-130
    ##therefore all comparisons in getByProfile method are done on
    ##perl side - 
    ##all rows from at_ugorgsim are retrieved,
    ##stored. Queries are performed against this data structure 
    ##rather than table itself. The data structure is reusable between 
    ##invocations of getByProfile;


    my $self = shift;
    ##so that objects can be reused:
    $self->_sql();
  
    delete $self->{'_data'} if ($self->{'_data'});
    delete $self->{'_sth'}  if ($self->{'_sth'});
    ###############################

    ##create data structure holding all data if it does not yet exist

    if (! $self->{'_allResults'}){
	
	$self->{'_sth'} = ( $self->{'_dbh'} )->prepare( $self->{'_sql2'} );
    
	eval{ ( $self->{'_sth'} ) ->execute () };
    
	return if ($@);

	while ( my $h_ref = ( $self->{'_sth'} )->fetchrow_hashref ){
	    
	    push @{$self->{'_allResults'}}, \%{$h_ref};
	}
    }
    ###################################################################
	

    $self->_parseArgs(@_);
    
    my $statement; 
    

    if (! $self->{'_args'}){

	$statement = "1";
	
    }else{

	$statement = join " && ", @{ $self->{'_args'} };
    }
    
    for my $h_ref( @{ $self->{'_allResults'} } ){

	my ($HS, $SACC, $CAEN, $DROS, $EUBACT, $ARCH, $SYNECHO) = ($h_ref->{'HS'},$h_ref->{'SACC'},$h_ref->{'CAEN'},$h_ref->{'DROS'},$h_ref->{'EUBACT'}, $h_ref->{'ARCH'}, $h_ref->{'SYNECHO'} ); 
	
	    
	push @{ $self->{'_data'} } , $h_ref  if (eval $statement);
	
    }
    
    
    $self->_sortResults();
    return $self->{'_data'};
    
}

sub _sortResults{

    #this method can be heavy if large number of results -> uncomment the call to this method
    #in getByProfile or getByClusterid if its is desired.
    #internal obj oriented - sorts the data - called from getByProfile, getByClusterid
    ##makes uses of __sortResults
    my $self = shift;
    return if (! $self->{'_data'} );
    
    my @sorted = sort __sortResults @{$self->{'_data'}};
    
    $self->{'_data'} = \@sorted;
}


sub __sortResults{

    ##internal non obj oriented - called from _sortResults
    ##add or change order to sort accordingly 

    
	$b->{'NUMSEQS'} <=> $a->{'NUMSEQS'} || ( $a->{'CLUSTERID'} =~ /^AT\.(.+?)$/ ) <=> ( $b->{'CLUSTERID'} =~ /^AT\.(.+?)$/ );


    }


sub _connect{

    ##internal makes connection;
    my $self = shift;
    my $database = "mdev";
    $self->{'_dbh'} = ConnectToDatabase($database);
}

sub _sql{
    ##internal - maintains base sql statements
    my $self = shift;
    $self->{'_sql1'} = "select at_ugorgsim.clusterid, numseqs, hs, sacc, caen, dros, eubact , arch, synecho from ewing.at_ugorgsim , prod.at_ugcluster where at_ugorgsim.clusterid = at_ugcluster.clusterid and at_ugorgsim.clusterid = ?";
     $self->{'_sql2'} = "select at_ugorgsim.clusterid, numseqs, hs, sacc, caen, dros, eubact, arch, synecho from ewing.at_ugorgsim , prod.at_ugcluster where at_ugorgsim.clusterid = at_ugcluster.clusterid";
        
}

sub _parseArgs{

    ##internal - parses arguments - rudimentary checking
    ##only used from getByProfile method;
    my $self = shift;
    ##so that objects are resuable:
    delete $self->{'_args'} if ($self->{'_args'});
   
    my @args = (@_);
    my $arg;
    

    for $arg(@args){

	
	
	my ($sp, $operator, $value ) = split (/\s+/, $arg ) ;
	
	$sp =~ tr/a-z/A-Z/;
	return if ($sp !~ /^(HS|ARCH|SYNECHO|CAEN|DROS|EUBACT|SACC)$/);
	return if ($operator !~ /^(>|<)$/);

	$value = sprintf "%g", $value;

	##note that we are adding a $ in front of sp names - so that 
	## we can eval these args directly;
	push @{ $self->{'_args'} }, "\$".$sp." ".$operator." ".$value;

		     
    }
    
}


sub DESTROY{

    ##internal: handles DBI::finish calls for statement handles
    ##and disconnection for db handle;
    my $self = shift;
   
    ( $self->{'_sth'} )->finish;
    ( $self->{'_dbh'} ) -> disconnect;
}

1;







