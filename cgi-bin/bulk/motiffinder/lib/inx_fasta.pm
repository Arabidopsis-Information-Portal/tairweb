package inx_fasta;

use lib "/usr/local/lib/perl";
use Bio::Index::Fasta;
use strict;
use Exporter;
@inx_fasta::ISA = qw(Exporter);
@inx_fasta::EXPORT = qw(make_index get_seq_obj);

sub make_index{
    ##pass file to be indexed and index file name##
    my $file = shift;
    my $inx_file_name = shift;
    
    die "usage: make_index(\$file, \$inx_file_name)\n" if (! defined $file || !defined $inx_file_name );
    
    my $inx = Bio::Index::Fasta->new(
				     -filename => $inx_file_name,
				     -write_flag => 1
				     );
    $inx->id_parser( \&_my_id_parser );
    $inx->make_index($file);

}

sub _alternative_id_parser{

       my $header = shift;
       
       $header =~ s/>|\||\n//g;
       print $header, "\n";
       return $header;

}

sub _my_id_parser{

    ##will do default pattern match if first one not found;
    my $header = shift;
    my $a_ref_id;

    if($header=~ /^>(\w+)\s+/){

	push @{ $a_ref_id } , $1;
	print $1, "\n";
       
    }elsif ($header =~ /^>.+?\|(\w+)/){

	my @tmp = split /\|/, $header;
	for my $element(@tmp){

	    next if ($element =~ /\s+/);
	    $element =~ s/>//;
	    push @{ $a_ref_id } , $element; 
	}
	
    }elsif($header =~ /^>\s*(\S+)/){
       
	

	push @{ $a_ref_id } , $1;
    }
    
    #print join " ", @{ $a_ref_id }, "\n";
    return @{ $a_ref_id };
}

sub get_seq_obj{

    ##pass the index file name, and sequence id;
    ##returns Bio::Seq obj;
    
    my ( $inx_file_name, $ident ) = @_;
    

    return 0 if (! defined $inx_file_name || ! defined $ident);
    
    my $inx = Bio::Index::Fasta->new($inx_file_name);
    
    return 0 if (! $inx->get_Seq_by_id( $ident ) );
    return $inx->get_Seq_by_id( "$ident" ); # Returns Bio::Seq obj
}

1;
