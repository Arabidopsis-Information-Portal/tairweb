package alignAceParse;


=head1 NAME

    alignAceParse - parsing for AlignACE output 

=head1 SYNOPSIS

    use alignAceParse
    my $object = alignAceParse->new("file")
    $object->getNumSeqs()
    $object->getMotifNums()
    
    $object->setMotifNum("number")
    $object->setSeq("seq identifier")

    $object->getMotifNumSeqs()
    $object->getMotifNumDiffSeqs()
    $object->getMotifScore()
    
    $object->getSubSeq()
    $object->getSeqs()
    $object->getNucComp()



=head1 DESCRIPTION

    Parsing of alignAce out put files - creates internal object
    representing single alignAce output file and allows multiple
    methods for querying and retrieval of data.

=head1 METHODS

    new("file") Simply initialises the object (internal parsing of
    alignAce output file).  Filename ( + complete path to file if file
    is not in ./) should be passed as arg .  $object->getNumSeqs()
    
    

    Methods can be divided into those that act on whole set of motifs
    or seqs or on single motifs. These 2 methods get the number of
    sequences input to the program (getNumSeqs) or get the identifying
    numbers of the motifs (getMotifNums) (motifs are numbered from 1
    .. whatever the last motif is)


    $object->getNumSeqs()
    $object->getMotifNums()
    
    

    To work on individual motifs or seqs - first set the motif number
    or the sequence as below

    $object->setMotifNum("number")
    $object->setSeq("seq identifier")

    
    Having set the Motif Number using setMotifNum, the following
    methods will retrieve information 'about' a given motif:

    $object->getMotifNumSeqs() #returns the number of seqs (total) contributing to a motif


    $object->getMotifNumDiffSeqs() #returns the number of DIFFERENT
    seqs contributing to a motif (since a given sequence may
    contribute more than one sub sequence to a motif)
    
    $object->getMotifScore #returns the score for the motif set with setMotifNum

    $object->getSeqs #returns the list of seqs contributing to a given motif 
    
    $object->getNucComp() #returns frequencies of nucleotides within set motif
    (as reference to hash)



    Method requiring that both sequence is set (setSeq) and motif (setMotifNum)
    $object->getSubSeq() #returns strand/subseq infor for a given seq in a given motif
    

=head1 AUTHOR

    Rob Ewing.
    Last Update Mon Sep 10 10:44:11 PDT 2001     

=cut







use strict;
use Data::Dumper;
use IO::File;
use Bio::Seq;


sub new{

    my $class = shift;
    return 0 if ($class ne 'alignAceParse');

    my $file = shift;
    my $fh = IO::File->new("< $file") || return 0;
    my $self;
    
    $self = bless {}, $class;
    
    $self->{'_fh'} = $fh;
    $self->_parseFile();
    
    return $self;
    
}



sub setMotifNum{

    my $self = shift;
    $self->{'_useMotifNum'} = shift;
}

sub getNumSeqs{


    my $self = shift; 
    return scalar keys %{ $self->{'_inputSeqIndex'}}; 

}

sub getMotifNumSeqs{

    ##returns number of seqs in motif (a given input sequence may be
    ##represented more than once in a motif)


    my $self = shift;
    die "Call setMotifNum\n" if (! $self->{'_useMotifNum'});
    return scalar @{ $self->{'_motifs'}->{       $self->{'_useMotifNum'}            } };

}

sub setSeq{
    ##set seq name for retrieval of subseqs;
    my $self = shift;
    $self->{'_useSeq'} = shift;
}

sub getSubSeq{

    ##return subseqs/strand/start for given Seq in given Motif;
    my $self = shift;
    die "Call setMotifNum and setSeq\n" if (! $self->{'_useMotifNum'} || ! $self->{'_useSeq'});

    my @list;
    for my $h_ref( @{$self->{'_motifs'}->{  $self->{'_useMotifNum'}  } } ){	
	
	next if ($h_ref->{'seqName'} ne $self->{'_useSeq'});
	
	push @list, {'subSeq'=> $h_ref->{'subseq'}, 'start'=>$h_ref->{'start'}, 'strand'=>$h_ref->{'strand'} };
    }

    return \@list;
}




sub getSeqs{ 


    ##returns list of seqs for given Motif Number (each seq
    ##may contribute > 1 subseq to motif)
    my $self = shift;
    die "Call setMotifNum\n" if (! $self->{'_useMotifNum'});
    my $tmp_href = {};
    
    for my $h_ref( @{$self->{'_motifs'}->{  $self->{'_useMotifNum'}  } } ){	
	
	$tmp_href->{ $h_ref->{'seqName'} } ++;
    }

    return keys %{$tmp_href};
}

sub getMotifNumDiffSeqs{

    ##returns number of different seqs in motif (each input sequence
    ##counted only once - although multiple subseqs from a given input
    ##sequence may occur in a given motif)

    
    my $self = shift;
    my $tmp_href = {};
    die "Call setMotifNum\n" if (! $self->{'_useMotifNum'});
    
    for my $h_ref(@{ $self->{'_motifs'}->{$self->{'_useMotifNum'}}}){
	
	##count number of times subseqs from seqName occur;
	$tmp_href->{ $h_ref->{'seqName'} } ++;
	
    }
    
    #return number of diff seqs represented in this motif;
    return scalar keys %{$tmp_href};

}


sub getMotifScore{

    my $self = shift;
    die "Call setMotifNum\n" if (! $self->{'_useMotifNum'});
    return $self->{'_motifScores'}->{       $self->{'_useMotifNum'}            };
}

sub getMotifNums{

    my $self = shift;

    return keys %{$self->{'_motifs'}};

}

sub getNucComp{


    #returns ref to hash in which keys are nucs and vals numbers of
    #occurrences within motif


    my $self = shift;


    die "Call setMotifNum\n" if (! $self->{'_useMotifNum'});
    my $hash_ref;
    for my $h_ref(@{ $self->{'_motifs'}->{    $self->{'_useMotifNum'}     } }){
	
	my ( @chars ) = $h_ref->{'subseq'} =~ /(\w{1})/g;
	
	for my $char(@chars){

	    $hash_ref->{$char}++;
	}
    }
    
    return $hash_ref;

}

sub getMotif{

    my $self = shift;
    die "Call setMotifNum\n" if (! $self->{'_useMotifNum'});
    return $self->{'_completeMotifs'}->{ $self->{'_useMotifNum'} };

}


sub _parseFile{

    my $self = shift;
    my $fh = $self->{'_fh'};
    my ($header, $inputSeqs, $motifs);
    {
	local $/ = undef;
	($header, $inputSeqs, $motifs) = <$fh> =~ /^(AlignACE.+?)\n\n(Input sequences\:.+?)\n+(Motif.+?)$/sg ;
    
    }
    
    my ( @inputSeqs ) = $inputSeqs =~ /(\#\d+\s+\w+)/sg ;

    for my $line(@inputSeqs){

	my ($indice, $seqName) = $line =~/^\#(\d+)\s+(\w+)$/;
	$self->{'_inputSeqIndex'}->{$indice} = $seqName;
    }
  
    my ( @motifs ) = $motifs =~ /(Motif.+?MAP Score\:.+?)\n/sg;
    
    for my $motif( @motifs ){

	
	my ( $motifNum, $seqs, $mapScore ) = $motif =~ /Motif\s+(\d+)\n(.+?)MAP Score\:\s+(\d+\.\d+)/sg;
	
	$self->{'_completeMotifs'}->{$motifNum} = $motif;
	$self->{'_motifScores'}->{$motifNum} = $mapScore;
	
	for my $line( split /\n/, $seqs){

	    next if ($line =~ /\*/);
	    my ($subseq, $indice, $start, $strand ) = split /\s+/, $line;
	    
	    push @{ $self->{'_motifs'}->{$motifNum} }, { 'seqName' => $self->{'_inputSeqIndex'}->{$indice}, 'subseq'=>$subseq, 'start'=>$start, 'strand'=>$strand };
	    
	}

    }
   
}


sub revComp{

    my $string = shift;
    $string =~ s/\n|\s//g;
    $string =~ tr/a-z/A-Z/;
    my @chars = $string =~ /(\w{1})/g;
    
    my $hash = { 'A'=>'T', 'T'=>'A', 'C'=>'G', 'G'=>'C' };
    
    my $revCom;
    for my $char(reverse(@chars)){
	
	if( $hash->{$char} ){
	    $revCom .= $hash->{$char};
	}else{

	    $revCom.= $char;
	}
    }
    return $revCom;
    
}


1;
