package atUgSeqObject;

use DBI;
use lib '/share/daisy/www-data/lib/common'; 
use Login qw (ConnectToDatabase);
use strict;
no strict "refs";

=head1 NAME

    atUgSeqObject -- class for accessing AT sequence info in MAD

=head1 SYNOPSIS

    use atUgSeqObject;

    $obj = atUgSeqObject->new()
    $obj->getCloneid('key'=>'value')
    $obj->getSuid('key'=>'value')
    $obj->getClusterid('key'=>'value')
    $obj->getSeqid('key'=>'value')
    $obj->getGbacc('key'=>'value')
    $obj->getProtsim('key'=>'value')
    $obj->getAllClusterids()
    $obj->getAllCloneids()


=head1 DESCRIPTION

    atUgSeqObject methods are simply front-ends for common queries
    related to arabidopsis sequence information. Methods query the
    at_ugseq, at_ugcluster , at_ugprotsim, stanfordseq, dbest and
    clone tables in MAD.

=head1 METHODS

    new() return a new atUgSeqObject
    
    getCloneid('key'=>'value') keys may be 'suid', 'clusterid', 'gbacc'
    ,'seqid'.
    (Note - will return undef if more than one key=>value pair supplied)
    examples: 
    getCloneid('suid'=>$suid) will return the cloneid corresponding
    to suid $suid. 
    getCloneid('clusterid'=>$clusterid) returns ref to list containing 
    cloneids in cluster $clusterid.
    This method, as others will return undef if underlying query 
    returns null value.
    

    getSuid('key'=>'value') keys may be 'clusterid', 'cloneid', 'gbacc'
    Functions as per getCloneid.
    Note that getting Suid by cloneid returns ref to list.

    getClusterid('key'=>'value') keys may be 'cloneid', 'suid', 'gbacc'
    Functions as per getCloneid, getSuid.
    Note that gettting clusterid by cloneid returns ref to list.

    getSeqid('key'=>'value') currently key may only be 'clusterid'.
    Functions as above.

    getGbacc('key'=>'value') currently key may be 'cloneid'. Functions
    as above.
    Returns ref to list of gbaccs since cloneid is not necessarily unique

    getProtsim('key'=>'value') currently only 'clusterid'=>$clusterid
    or 'description'=>$description accepted as argument. Returns a ref
    to a list with order: PID, EVALUE, ALIGN_PCT, DESCRIPTION
    corresponding to best protein similarity match for this clusterid
    OR returns ref to list of list of matches to this description
    (Note that matches are case-sensistive, wildcarded )

    getAllClusterids() no arguments required. Simply returns ref to list
    of all current AT clusterids.

    getAllCloneids() no arguments required. Simply returns ref to list
    of all current AT cloneids.

=head1 AUTHOR

    Rob Ewing. Wed May 17 09:21:27 PDT 2000
    Updated Thu May 18 12:34:45 2000
    Updated Fri May 26 11:50:37 PDT 2000
    Thu Jun 29 15:20:35 2000 : Added getProtsim('description'=>$description)
    capability
    Fri Aug  4 12:09:04 2000: Added getGbacc() method
    Fri Aug 11 11:10:08 2000: All methods called with 'cloneid'=>$cloneid
    argument return ref to list since cloneid not necessarily unique.
    

=cut




sub getCloneid{

    my $self = shift;
    $self->_clearData;
    my $args_ref = { @_ };
    return unless (scalar keys %{$args_ref} == 1);

    

    if( $args_ref->{'clusterid'} ){
	
	$self->_cloneid_by_clusterid($args_ref->{'clusterid'});
	
	return $self->{'_data'}->{'_cloneid_by_clusterid'}->{$args_ref->{'clusterid'}};

    }elsif($args_ref->{'suid'}){

	$self->_cloneid_by_suid($args_ref->{'suid'});


    }elsif($args_ref->{'gbacc'}){

	$self->_cloneid_by_gbacc($args_ref->{'gbacc'});
	return $self->{'_data'}->{'_cloneid_by_gbacc'}->{$args_ref->{'gbacc'}};

    }elsif($args_ref->{'seqid'}){

	$self->_cloneid_by_seqid($args_ref->{'seqid'});

	return $self->{'_data'}->{'_cloneid_by_seqid'}->{$args_ref->{'seqid'}};


    }
    
    
}

sub getSuid{

    

    my $self = shift;

    $self->_clearData;
    
    my $args_ref = { @_ };
    
    return unless (scalar keys %{$args_ref} == 1);

    if( $args_ref->{'clusterid'} ){
	
	$self->_gbacc_by_clusterid($args_ref->{'clusterid'});
	
	
	my $a_ref_gbaccs = $self->{'_data'}->
	{'_gbacc_by_clusterid'}->{$args_ref->{'clusterid'}};

	return if (! $a_ref_gbaccs);
	
	for my $gbacc(@{$a_ref_gbaccs}){
	    
	    next if (! defined $gbacc); 
	    $self->_suid_by_gbacc($gbacc);
	    
	    next if(! defined $self->{'_data'}->{'_suid_by_gbacc'}->{$gbacc});

	    push @{$self->{'_data'}->{'_suid_by_clusterid'}->{$args_ref->{'clusterid'} } }, $self->{'_data'}->{'_suid_by_gbacc'}->{$gbacc};


	}

	return $self->{'_data'}->{'_suid_by_clusterid'} ->{$args_ref->{'clusterid'}};
	

    }elsif($args_ref->{'cloneid'}){

	$self->_suid_by_cloneid($args_ref->{'cloneid'});
	
	return $self->{'_data'}->{'_suid_by_cloneid'}->{$args_ref->{'cloneid'}};

    }elsif($args_ref->{'gbacc'}){
	
	$self->_suid_by_gbacc( $args_ref->{'gbacc'} );
	return $self->{'_data'}->{'_suid_by_gbacc'}->{$args_ref->{'gbacc'}};
    }


}

sub getGbacc{

    

    my $self = shift;

    $self->_clearData;
    
    my $args_ref = { @_ };
    
    return unless (scalar keys %{$args_ref} == 1);

    if( $args_ref->{'cloneid'} ){
	
	$self->_gbacc_by_cloneid($args_ref->{'cloneid'});
	
	return $self->{'_data'}->{'_gbacc_by_cloneid'}->{$args_ref->{'cloneid'}};


    }elsif( $args_ref->{'suid'} ){


	$self->_gbacc_by_suid($args_ref->{'suid'});
	
	return $self->{'_data'}->{'_gbacc_by_suid'}->{$args_ref->{'suid'}};
		

    }elsif( $args_ref->{'clusterid'} ){

	
	$self->_gbacc_by_clusterid($args_ref->{'clusterid'});
	
	return $self->{'_data'}->{'_gbacc_by_clusterid'}->{$args_ref->{'clusterid'}};



    }

    


}


sub getAllCloneids{

    my $self = shift;
    $self->_clearData;
    ##return list of all at cloneids;
    $self->_all_cloneids();
    return $self->{'_data'}->{'_all_cloneids'}



}

sub getAllClusterids{

    
    my $self = shift;
    $self->_clearData;
    ##return list of all at clusterids;
    $self->_all_clusterids();
    return $self->{'_data'}->{'_all_clusterids'}

}

sub getClusterid{

    ##returns clusterid given suid, gbacc or cloneid;
    ##requires precisely one argument in form 'suid'=>'' etc;
    
    my $self = shift;
    $self->_clearData;
    my $args_ref = { @_ };
    
    return unless (scalar keys %{$args_ref} == 1);
    return unless($args_ref->{'suid'} || $args_ref->{'cloneid'} || $args_ref->{'gbacc'});
    
    if( $args_ref->{'cloneid'} ){
	
	$self->_clusterid_by_cloneid($args_ref->{'cloneid'});
	return $self->{'_data'}->{'_clusterid_by_cloneid'}->{$args_ref->{'cloneid'}};

    }elsif( $args_ref->{'suid'}){

	$self->_cloneid_by_suid( $args_ref->{'suid'});
	my $this_cloneid = ( $self->{'_data'}->{'_cloneid_by_suid'}->{$args_ref->{'suid'}});
    
	return if (! $this_cloneid);
    
	$self->_clusterid_by_cloneid($this_cloneid);
	return $self->{'_data'}->{'_clusterid_by_cloneid'}->{$this_cloneid};


    }elsif($args_ref->{'gbacc'}){

	$self->_clusterid_by_gbacc($args_ref->{'gbacc'});
	return $self->{'_data'}->{'_clusterid_by_gbacc'}->{$args_ref->{'gbacc'}};
    }

    
}

sub getProtsim{

    
    ##queries at_ugprotsim table by clusterid or by description; 
    ##if clusterid arg passed -> returns ref to list containing : 
    ##PID, EVALUE, ALIGN_PCT, DESCRIPTION from best prot similarity;
    ##if description passed  -> returns ref to list of lists 
    ##containing clusterid, PID, EVALUE, ALIGN_PCT, DESCRIPTION for
    ##each match (note matching is wildcarded and case -sensistive;

    my $self = shift;
    $self->_clearData();
    my $args_ref = { @_ };
    if ( $args_ref->{'clusterid'} ){

	
	$self->_protsim_by_clusterid($args_ref->{'clusterid'});
	return $self->{'_data'}->{'_protsim_by_clusterid'};
    
    }elsif( $args_ref->{'description'} ){
	
	$self->_protsim_by_description($args_ref->{'description'});
	
	return $self->{'_data'}->{'_protsim_by_description'};

    }else{

	return;

    }
}


sub getSeqid{

  
    ##currently only 'clusterid'=>$clusterid argument implemented;
    my $self = shift;
    $self->_clearData;
    my $args_ref = { @_ };
    return unless (scalar keys %{$args_ref} == 1 && $args_ref->{'clusterid'});
    $self->_seqid_by_clusterid( $args_ref->{'clusterid'} );
    return $self->{'_data'}->{'_seqid_by_clusterid'}->{$args_ref->{'clusterid'}};
}


##################################################################
#external method - constructor
##################################################################
sub new{

    ##returns ref to blessed hash;
    ##sets up connection to db ;
    ##populates object with all available sql statements;
    
    my $class = shift;
    my $h_ref = bless {}, $class;

    $h_ref->_connectToDatabase();
    $h_ref->_getSQL();
    
    return $h_ref;
}
#####################################################################
#internal general methods
#####################################################################
sub _clearData{
    my $self = shift;
    delete $self->{'_data'};
}


#######################################################################
#internal methods for handling specific queries and 
#calling _executeSQL method
#######################################################################


sub _gbacc_by_clusterid{

    my $self = shift;
    my $clusterid = shift;
    my $a_ref = $self->_executeSQL('_gbacc_by_clusterid', $clusterid);
    return if( ! $a_ref);
    for my $element( @{$a_ref} ){
	push @{ $self->{'_data'}->{'_gbacc_by_clusterid'}->{$clusterid} } , @{ $element } ;
    }
}

sub _suid_by_gbacc{

    my $self = shift;
    my $gbacc = shift;
    

    my $a_ref = $self->_executeSQL('_suid_by_gbacc', $gbacc);
    return if( ! $a_ref);
    $self->{'_data'}->{'_suid_by_gbacc'}->{$gbacc} = $a_ref->[0]->[0];
}



sub _gbacc_by_suid{

    my $self = shift;
    my $suid = shift;
    

    my $a_ref = $self->_executeSQL('_gbacc_by_suid', $suid);
    return if( ! $a_ref);
    $self->{'_data'}->{'_gbacc_by_suid'}->{$suid} = $a_ref->[0]->[0];
}




sub _gbacc_by_cloneid{

    my $self = shift;
    my $cloneid = shift;
    my $a_ref = $self->_executeSQL('_gbacc_by_cloneid', $cloneid);
    return if( ! $a_ref);
    for my $element( @{$a_ref} ){
	push @{ $self->{'_data'}->{'_gbacc_by_cloneid'}->{$cloneid} } , @{ $element } ;
    }
}




sub _suid_by_cloneid{

    my $self = shift;
    my $cloneid = shift;
    my $a_ref = $self->_executeSQL('_suid_by_cloneid', $cloneid);
    return if( ! $a_ref);
    for my $element(@{$a_ref}){
	
	push @{ $self->{'_data'}->{'_suid_by_cloneid'}->{$cloneid} } , @{ $element } ;
    }

}

sub _clusterid_by_cloneid{
    ##internal
    my $self = shift;
    my $cloneid = shift;

    my $a_ref = $self->_executeSQL('_clusterid_by_cloneid', $cloneid);
    return if (! $a_ref);
    for my $element(@{$a_ref}){
	
	push @{ $self->{'_data'}->{'_clusterid_by_cloneid'}->{$cloneid} } , @{ $element } ;
    }
}



sub _protsim_by_description{

    my $self = shift;
    my $description = shift;
    $description = "%$description%";
    my $a_ref = $self->_executeSQL('_protsim_by_description', $description);
    return if( ! $a_ref);
    for my $element( @{$a_ref} ){
	push @{ $self->{'_data'}->{'_protsim_by_description'} } , \@{ $element } ;
    }
}

sub _seqid_by_clusterid{

    my $self = shift;
    my $clusterid = shift;
    
    my $a_ref = $self->_executeSQL('_seqid_by_clusterid', $clusterid);
    return if( ! $a_ref);
    for my $element(@{$a_ref}){
	
	push @{ $self->{'_data'}->{'_seqid_by_clusterid'}->{$clusterid} } , @{ $element } ;
    }
}



sub _protsim_by_clusterid{

    my $self = shift;
    my $clusterid = shift;
    my $a_ref = $self->_executeSQL('_protsim_by_clusterid', $clusterid);
    return if (! $a_ref);

    $self->{'_data'}->{'_protsim_by_clusterid'} = $a_ref->[0];
}




sub _all_clusterids{
    
    ##internal - get all clusterids
    my $self= shift;
    my $a_ref = $self->_executeSQL('_all_clusterids');
    return if (! $a_ref);
    for my $element(@{$a_ref}){

	next if ( ! $element || ! $element ->[0] );

	push @{ $self->{'_data'}->{'_all_clusterids'} } , @{ $element } ;
    }
}

sub _all_cloneids{
    
    ##internal - get all cloneids
    my $self= shift;
    my $a_ref = $self->_executeSQL('_all_cloneids');
    return if (! $a_ref);
    for my $element(@{$a_ref}){

	next if ( ! $element || ! $element ->[0] );
	
	push @{ $self->{'_data'}->{'_all_cloneids'} } , @{ $element } ;
    }
}



sub _clusterid_by_gbacc{
    #internal
    my $self = shift;
    my $gbacc = shift;

    my $a_ref = $self->_executeSQL('_clusterid_by_gbacc', $gbacc);
    return if (! $a_ref);
    
    $self->{'_data'}->{'_clusterid_by_gbacc'}->{$gbacc} = $a_ref->[0]->[0];

}

sub _cloneid_by_suid{

    my $self = shift;
    my $suid = shift;
    

    my $a_ref = $self->_executeSQL('_cloneid_by_suid', $suid);
    return if( ! $a_ref);
    $self->{'_data'}->{'_cloneid_by_suid'}->{$suid} = $a_ref->[0]->[0];
}

sub _cloneid_by_gbacc{

    my $self = shift;
    my $gbacc = shift;
    

    my $a_ref = $self->_executeSQL('_cloneid_by_gbacc', $gbacc);
    return if( ! $a_ref);
    $self->{'_data'}->{'_cloneid_by_gbacc'}->{$gbacc} = $a_ref->[0]->[0];
}

sub _cloneid_by_seqid{

    my $self = shift;
    my $seqid = shift;
    
    
    my $a_ref = $self->_executeSQL('_cloneid_by_seqid', $seqid);
    return if( ! $a_ref);
    $self->{'_data'}->{'_cloneid_by_seqid'}->{$seqid} = $a_ref->[0]->[0];
}


sub _cloneid_by_clusterid{

    my $self = shift;
    my $clusterid = shift;
    
    my $a_ref = $self->_executeSQL('_cloneid_by_clusterid', $clusterid);
    return if( ! $a_ref);
    for my $element(@{$a_ref}){
	push @{ $self->{'_data'}->{'_cloneid_by_clusterid'}->{$clusterid} } , @{ $element } ;
    }
}


###################################################################
#internal dbi methods
###################################################################

sub _getSQL{

    ##internal: sets up sql statements (new statements can be added
    ##here);

    my $self = shift;

    ##########################################################




    ###########################################################
    $self->{'_sql'}->{'_suid_by_cloneid'} = 'select suid from
    prod.stanfordseq, prod.clone where stanfordseq.seqname =
    to_char(clone.clone_no) and clone.cloneid = ?';
    
    $self->{'_sql'}->{'_suid_by_gbacc'} = 'select suid from
    prod.stanfordseq, prod.clone_gbacc where stanfordseq.seqname =
    to_char(clone_gbacc.clone_no) and gb_acc = ?';
    
    
    ############################################################
    $self->{'_sql'}->{'_clusterid_by_gbacc'} = 'select clusterid from
    prod.at_ugseq where gb_acc = ?';

    $self->{'_sql'}->{'_clusterid_by_cloneid'} = 'select clusterid from
    prod.at_ugseq where cloneid = ?';

    ############################################################
    $self->{'_sql'}->{'_all_clusterids'} = 'select clusterid from
    prod.at_ugcluster';

    $self->{'_sql'}->{'_all_cloneids'} = 'select cloneid from
    prod.at_ugseq';

    
    ##############################################################
    $self->{'_sql'}->{'_cloneid_by_gbacc'} = 'select cloneid from
    prod.dbest where gbacc = ?';

    $self->{'_sql'}->{'_cloneid_by_seqid'} = 'select cloneid from
    prod.at_ugseq where seqid = ?';

    $self->{'_sql'}->{'_cloneid_by_suid'} = 'select cloneid from
    prod.stanfordseq, prod.clone where stanfordseq.seqname =
    to_char(clone.clone_no) and stanfordseq.suid = ?';

    $self->{'_sql'}->{'_cloneid_by_clusterid'} = 'select cloneid from
    prod.at_ugseq where clusterid = ?';

    ############################################################
    
    $self->{'_sql'}->{'_seqid_by_clusterid'} = 'select seqid from
    prod.at_ugseq where clusterid = ?';
    
    ############################################################

    ##Note ! Cloneid may not be unique!
    $self->{'_sql'}->{'_gbacc_by_cloneid'} = 'select gbacc from
    prod.dbest where cloneid = ?';

    $self->{'_sql'}->{'_gbacc_by_clusterid'} = 'select gb_acc from
    prod.at_ugseq where clusterid = ?';
    

    
    $self->{'_sql'}->{'_gbacc_by_suid'} = 'select gb_acc from
prod.clone_gbacc, prod.stanfordseq where to_char(clone_gbacc.clone_no)
= stanfordseq.seqname and suid = ?';

    #############################################################
    $self->{'_sql'}->{'_protsim_by_clusterid'} = 'select pid, evalue,
    align_pct, description from prod.at_ugprotsim where clusterid = ?';
    
    $self->{'_sql'}->{'_protsim_by_description'} = 'select clusterid, pid, evalue,
    align_pct, description from prod.at_ugprotsim where description like ?';

}


sub _executeSQL{

    ##internal: execution of generic statement handle;
    my $self = shift;
    my ($query_name, $query) = @_;
    
    if (! $self->{'_sth'}->{$query_name}){

	$self->_prepareStatement($query_name);

    } 

    if ($query){

	eval { ( $self->{'_sth'}->{$query_name} )->execute($query) };
    
    }else{

	eval { ( $self->{'_sth'}->{$query_name} )->execute() };
	
    }
    return if ($@);
    
    
    my $a_ref = ($self->{'_sth'}->{$query_name}) ->fetchall_arrayref;
    return if (ref($a_ref) ne 'ARRAY');
    return if (! $a_ref->[0]);
    return $a_ref;
}


sub _connectToDatabase{
    ##internal: make connection to database (mad);
    my $self = shift;
    $self->{'_dbh'} = &ConnectToDatabase( 'mad' );
}

sub _prepareStatement{
    ##internal: prepare statement handle;
    my $self = shift;
    my ($query_name) = @_;
    
    $self->{'_sth'}->{$query_name} = ($self->{'_dbh'})
    ->prepare($self->{'_sql'}->{$query_name});

}

sub DESTROY{

    ##internal: handles DBI::finish calls for statement handles
    ##and disconnection for db handle;
    my $self = shift;
    my $query_name;
    foreach $query_name(keys %{ $self->{'_sth'} }){

	( $self->{'_sth'}->{$query_name} )->finish;
    }
    
    $self->{'_dbh'} -> disconnect;
}
1;



