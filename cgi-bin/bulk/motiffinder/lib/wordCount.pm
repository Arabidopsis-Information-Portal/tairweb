package wordCount;

use Data::Dumper;

use Bio::SeqIO;
use Bio::Tools::SeqWords;
use Data::Dumper;
use PDL;
use PDL::Char;
use strict;


sub new{
    
    #initialises oligoPDL/oligoHash - constructor   
    my ($h_ref,$i);
    my $class = shift;
    $h_ref = {};
    bless $h_ref, $class;

    ##by default initialise up to 7mers
    for ($i = 1; $i <=7; $i++){
	$h_ref->_createOligos($i);
    }
    return $h_ref;
}

sub _createOligos{

    #method for creating oligoHash and pdl;
    #for each oligo length create an oligo pdl and hash;

    my ($oligoLen, $a_strings, $a_chars, $i, $oligoHash);
    my $self = shift;
    $oligoLen = shift;
    
    $a_strings = [ qw(A C G T) ];
    $a_chars = [ qw(A C G T) ];
    
    for ($i = 1; $i < $oligoLen; $i ++){
	$a_strings = __incre( $a_strings, $a_chars );
    }

    for ($i = 0; $i <= scalar @{$a_strings}-1; $i ++){
	$oligoHash->{ $a_strings->[$i] } = $i;
    }
    $self->{'_oligoHash'}->{$oligoLen} = $oligoHash;
    $self->{'_oligoPDL'}->{$oligoLen} = PDL::Char->new( @{$a_strings} );
}


sub __incre{
    #internal - called only by _createOligos
    my $a_strings = shift;
    my $a_chars  = shift;
    my $a_newstrings;
    for my $string( @{$a_strings} ){
	for my $char(@{ $a_chars } ){
	    push @{$a_newstrings}, $string.$char;
	}
    }
    return $a_newstrings;
}

sub _clearData{
    #internal - clears out the temp portion of object;
    #i.e everything but the oligoPDL and oligoHash;
    my $self = shift;
    delete $self->{"tmp"} if ($self->{"tmp"});
}

sub countWords{

    my ($indice, $word, $tmpCountsHash_1, $tmpCountsHash_2, $oligoLen, $wordObj_1, $wordObj_2, $seq, $i, $seqObj, $thisSeqObj_1, $thisSeqObj_2, $seqLen, $tmpPDLs_1, $tmpPDLs_2);
    my $self = shift;
    $self->_clearData();
    
    my %args = ('length'=>6, 'bioSeqObj'=>undef, 'bothStrands'=>0, @_);
    $self->{"tmp"}->{'_oligoLen'} = $oligoLen = $args{'length'};
    $seqObj = $args{'bioSeqObj'};

    
    $seqLen = $seqObj->length();


    $self->{"tmp"}->{"_oligoCountsPDL"} = zeroes ( scalar keys %{$self->{'_oligoHash'}->{$oligoLen} } );

    ##count oligos for different frames - for both strands
    for ($i=1; $i <=$oligoLen ; $i++){
	
	$tmpPDLs_1->{$i} = zeroes(scalar keys %{$self->{'_oligoHash'}->{$oligoLen} } );
	$tmpPDLs_2->{$i} = zeroes(scalar keys %{$self->{'_oligoHash'}->{$oligoLen} } );

	$thisSeqObj_1 = Bio::PrimarySeq->new(-seq=>$seqObj->subseq($i,$seqLen)); 
	$thisSeqObj_2 = Bio::PrimarySeq->new(-seq=>$seqObj->revcom()->subseq($i, $seqLen) ); 

	$wordObj_1 = Bio::Tools::SeqWords->new($thisSeqObj_1);
	$wordObj_2 = Bio::Tools::SeqWords->new($thisSeqObj_2);

	$tmpCountsHash_1 = $wordObj_1->count_words($oligoLen);
	$tmpCountsHash_2 = $wordObj_2->count_words($oligoLen);
	
	##parse the hash into pdl for strand 1
	for $word(keys %{$tmpCountsHash_1}){
	    next if ( ! defined $self->{'_oligoHash'}->{$oligoLen}->{$word} );
	    $indice = $self->{'_oligoHash'}->{$oligoLen}->{$word};
	    set $tmpPDLs_1->{$i}, $indice, $tmpCountsHash_1->{$word};
	    
	}

	##parse the hash into pdl for strand 2
	for $word(keys %{$tmpCountsHash_2}){
	    next if ( ! defined $self->{'_oligoHash'}->{$oligoLen}->{$word} );
	    $indice = $self->{'_oligoHash'}->{$oligoLen}->{$word};
	    set $tmpPDLs_2->{$i}, $indice, $tmpCountsHash_2->{$word};
	    
	}

	
	##add data for both strands if requested:
	if ($args{'bothStrands'} == 1){
	    
	    $self->{"tmp"}->{'_oligoCountsPDL'} = $self->{"tmp"}->{'_oligoCountsPDL'} + $tmpPDLs_1->{$i} + $tmpPDLs_2->{$i};

	}else{

	    $self->{"tmp"}->{'_oligoCountsPDL'} = $self->{"tmp"}->{'_oligoCountsPDL'} + $tmpPDLs_1->{$i};
	}

    }

    return $self->{"tmp"}->{'_oligoCountsPDL'};
}


sub getOligoPDL{

    my $self = shift;
    my %args = ( 'length'=>5 , @_ );
    my $oligoLen = $args{'length'};
    return $self->{'_oligoPDL'}->{$oligoLen}; 

}


1;
