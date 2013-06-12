package oligoAnalysisTools;

@EXPORT = qw( getOligomerPDL calcBinomial countSeqs calcHyperGeom countOligos);
use Bio::SeqIO;
use PDL;
use PDL::IO::FastRaw;
use Data::Dumper;
# use IO::String;
use wordCount;
use hyperGeom;
use strict;


sub countSeqs{

    my %args = @_;
    die "Usage: 'file'=>file || 'fh'=>fh, || 'bioSeqObjects'=>a_ref \n" if (! $args{'file'} && ! $args{'fh'} && ! $args{'bioSeqObjects'});
    my $a_ref = 0;
    eval{
        $a_ref = &_bioSeqObjects( %args );
    };
    return scalar @{$a_ref} if($a_ref);
    return 0;
}


sub getOligomerPDL{

    ##since we make use of the wordCount class here, this method is
    ##just a wrapper method to get the oligoPDL for a certain oligomer size
    ##from the wordCount object;

    my %args = ( 'length'=>5 , @_ );
    
    my $wordObj = wordCount->new();

    return $wordObj->getOligoPDL('length'=>$args{'length'});
    
    
}

sub countOligos{

##pass file or fh or list of bioSeqObjects and oligomer length to be counted. Returns
##pdls of count (absolute) and normalised count (number of seqs with
##at least one instance of the oligo) Counts leading strand only by default
##both strands on request;

    my %args =  ('oligoLength'=>6, 'bothStrands'=>0, @_ );
    my ($oligoLength, $bothStrands) = ( $args{'oligoLength'} , $args{'bothStrands'}); 

    die "Usage: 'file'=>file || 'fh'=>fh, || 'bioSeqObjects'=>a_ref \n" if (! $args{'file'} && ! $args{'fh'} && ! $args{'bioSeqObjects'});
    
    my $a_ref = &_bioSeqObjects( %args ) || die "Check seqs\n";
    
    my $pdl = zeroes( 4** $oligoLength );
    my $pdlNorm = zeroes( 4** $oligoLength);
    

    my ($thisPDL, $thisPDLNorm);
    my $wordObj = wordCount->new();

    for my $bioSeqObj ( @{$a_ref} ){

	if ($bothStrands){
	    $thisPDL = $wordObj->countWords('length'=>$oligoLength, 'bioSeqObj'=>$bioSeqObj, 'bothStrands'=>1 );
	}else{
	    $thisPDL = $wordObj->countWords('length'=>$oligoLength, 'bioSeqObj'=>$bioSeqObj );
	}

	$thisPDLNorm = $thisPDL ->hclip(1);
	$pdl = $pdl + $thisPDL;
	$pdlNorm = $pdlNorm + $thisPDLNorm;

    }
    return ($pdl, $pdlNorm);
}


## Returns a list of the sequences that have a nonzero component in their
## oligo count, at positions .
sub getSequencesAtPosition {
    my %args =  ('oligoLength'=>6, 'bothStrands'=>0, @_ );
    my ($oligoLength, $bothStrands, $position_refe) = ( $args{'oligoLength'} , $args{'bothStrands'},$args{'position'});

    die "Usage: 'file'=>file || 'fh'=>fh, || 'bioSeqObjects'=>a_ref \n" if (! $args{'file'} && ! $args{'fh'} && ! $args{'bioSeqObjects'});

    my $a_ref = &_bioSeqObjects( %args ) || die "Check seqs\n";
    my $thisPDL;
    my $wordObj = wordCount->new();
    my %sequences;
    my @positions = @$position_refe;

    for my $bioSeqObj ( @{$a_ref} ){
	if ($bothStrands){
	    $thisPDL = $wordObj->countWords('length'=>$oligoLength, 'bioSeqObj'=>$bioSeqObj, 'bothStrands'=>1 );
	}else{
	    $thisPDL = $wordObj->countWords('length'=>$oligoLength, 'bioSeqObj'=>$bioSeqObj );
	}
	for  my $this_position ( @positions )  {
	    if ($thisPDL->at($this_position)) {
               push @{$sequences{$this_position}}, $bioSeqObj->display_id;    
	    }
	}
    }
    return \%sequences;
}



sub _bioSeqObjects{

    ##internal - pass a fh OR filename OR list of bioSeqObjects - will return list of bioSeqObjs;
    my %args = @_;
    my $stream;
    my @list;
    
    if ( $args{'file'} ){
	
	$stream = Bio::SeqIO->new(-file=>$args{'file'}) || return 0;
    
    }elsif($args{'fh'}){
	
	$stream = Bio::SeqIO->new(-fh=>$args{'fh'}) || return 0;
	
    }elsif($args{'bioSeqObjects'}){
	
	return $args{'bioSeqObjects'} ;

    }else{
	return 0;
    }

    while(my $seq = $stream->next_seq){

      push @list, $seq;
   
      # the output handle is reset for every file
    #  my $string; 
    #  my $stringio = IO::String->new($string);
    #  my $out = Bio::SeqIO->new('-fh' => $stringio,
                         #       '-format' => 'fasta');
      # output goes into $string
    #  $out->write_seq($seq);
      # modify $string
       
    #  $string =~ s|(>)(\w+)|$1<font color="Red">$2</font>|g;
      # print into STDOUT
    #  print STDERR $string;

   }

    return \@list;
    
}



sub calcBinomial{


    ##pass pdl of backgroundCounts, number background seqs, pdl of
    ##cluster counts, number of cluster (node) sequences;
    my %args = ('bkgrndCounts'=>'', 'nodeCounts'=>'', 'bkgrndSize'=>'', 'nodeSize'=>'', @_);
    
    my ($bkgrndCounts, $nodeCounts, $bkgrndSize, $nodeSize) = ($args{'bkgrndCounts'}, $args{'nodeCounts'}, $args{'bkgrndSize'}, $args{'nodeSize'});
    
    
    my $pdlBinomial = ones( nelem($bkgrndCounts));
    my $pdlProbs = $bkgrndCounts/$bkgrndSize;


    for  ( my $i = 0; $i <= nelem($bkgrndCounts) - 1; $i++  ){
	
	
	my $thisBinomialPval = hyperGeom::binomial($nodeSize, $nodeCounts->at($i), $pdlProbs->at($i) );
    
	set $pdlBinomial, $i, $thisBinomialPval;
    }

    return $pdlBinomial ;
}


sub calcHyperGeom{


    ##pass pdl of backgroundCounts, number background seqs, pdl of
    ##cluster counts, number of cluster (node) sequences;
    my %args = ('bkgrndCounts'=>'', 'nodeCounts'=>'', 'bkgrndSize'=>'', 'nodeSize'=>'', @_);
    
    my ($bkgrndCounts, $nodeCounts, $bkgrndSize, $nodeSize) = ($args{'bkgrndCounts'}, $args{'nodeCounts'}, $args{'bkgrndSize'}, $args{'nodeSize'});
    
    
    my $pdlHyperGeom = ones( nelem($bkgrndCounts));
   


    for  ( my $i = 0; $i <= nelem($bkgrndCounts) - 1; $i++  ){
	
	
	my $hyp = hyperGeom::hypergeometric($nodeCounts->at($i), $nodeSize, $bkgrndCounts->at($i), $bkgrndSize - $bkgrndCounts->at($i) );
    
	set $pdlHyperGeom, $i, $hyp;
    }

    return $pdlHyperGeom;
}




1;








