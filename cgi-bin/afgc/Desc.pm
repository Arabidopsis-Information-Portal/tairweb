
#
# BioPerl module for Bio::Index::Abstract
#
# Cared for by Guanghong Chen <gc@ncgr.org>
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Desc - Interface for indexing clone_id locus_name description files

=head1 SYNOPSIS

    # Complete code for making an index for several
    # locus flat files
    use Desc;

    my $Index_File_Name = shift;
    my $inx = Desc->new($Index_File_Name, 'WRITE');
    $inx->make_index(@ARGV);

    # Print out several loci present in the index

    use Bio::Index::Desc;

    my $Index_File_Name = shift;
    my $inx = Desc->new($Index_File_Name);

    foreach my $id (@ARGV) {
        my $locus = $inx->fetch($id); # Returns Bio::Seq object
        print $seq->array_element_type();
    }


=head1 DESCRIPTION

Inherits functions for managing dbm files from Bio::Index::Abstract.pm,
and provides the basic funtionallity for indexing fasta files, and
retrieving the sequence from them. 

Bio::Index::Desc supports the Bio::DB::BioSeqI interface, meaning
it can be used a a Sequence database for other parts of bioperl

=head1 FEED_BACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  vsns-bcd-perl@lists.uni-bielefeld.de          - General discussion
  vsns-bcd-perl-guts@lists.uni-bielefeld.de     - Technically-oriented discussion
  http://bio.perl.org/MailList.html             - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via
email or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Guanghong Chen

Email - gc@ncgr.org

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Desc;

use vars qw($VERSION @ISA @EXPORT_OK);
use strict;

use Bio::Index::Abstract;
use Locus;

@ISA = qw(Bio::Index::Abstract Exporter);
@EXPORT_OK = qw();

sub _type_stamp {
    return '__LOCUS__'; # What kind of index are we?
}

sub _version {
    return 0.1;
}

$VERSION = _version();



=head2 _initialize

  Title   : _initialize
  Usage   : $index->_initialize
  Function: Calls $index->SUPER::_initialize(), and then adds
            the default id parser for fasta files.
  Example : 
  Returns : 
  Args    : 

=cut

sub _initialize {
    my($self, $index_file, $write_flag) = @_;
    
    $self->SUPER::_initialize($index_file, $write_flag);
    $self->id_parser( \&default_id_parser );
}


=head2 _index_file

  Title   : _index_file
  Usage   : $index->_index_file( $file_name, $i )
  Function: Specialist function to index LOCUS format files.
            Is provided with a filename and an integer
            by make_index in its SUPER class.
  Example : 
  Returns : 
  Args    : 

=cut

sub _index_file {
    my( $self,
        $file, # File name
        $i     # Index-number of file being indexed
        ) = @_;


    my $begin = 0; # Offset from start of file of the start of the last found record.


    my $id_parser = $self->id_parser;

    open LOCUS, $file or $self->throw("Can't open file for read : $file");

    # Main indexing loop
    while (<LOCUS>) {

      if ($. != 1){ # if is not first line, which usually column headers

            $begin = tell(LOCUS) - length( $_ );
            foreach my $id (&$id_parser($_)) {
                $self->add_record($id, $i, $begin);
            }
        }
    }

    close LOCUS;
    return 1;
}



=head2 id_parser

  Title   : id_parser
  Usage   : $index->id_parser( CODE )
  Function: Stores or returns the code used by record_id
            to parse the ID for record from a string.  Useful
            for (for instance) specifying a different parser
            for different flavours of LOCUS file.
  Example : $index->id_parser( \&my_id_parser )
  Returns : ref to CODE if called without arguments
  Args    : CODE

=cut


sub id_parser {
    my( $self, $code ) = @_;
    
    if ($code) {
        $self->{'_id_parser'} = $code;
    }
    return $self->{'_id_parser'} || \&default_id_parser;
}



=head2 default_id_parser

  Title   : default_id_parser
  Usage   : $id = default_id_parser( $header )
  Function: The default Desc ID parser for Desc.pm
            Returns $1 from applying the regexp /^>\s*(\S+)/
            to $header.
  Example : 
  Returns : ID string
  Args    : a fasta header line string

=cut

sub default_id_parser {
    #my ($self, $line) = @_;
    my $line = shift;

    my ($suid, $clone_id, $rest) = split /\t/, $line, 3;

    return $clone_id;
}


=head2 fetch

  Title   : fetch
  Usage   : $index->fetch( $id )
  Function: Returns a Bio::Seq object from the index
  Example : $seq = $index->fetch( 'dJ67B12' )
  Returns : Bio::Seq object
  Args    : ID

=cut

sub fetch {
    my( $self, $id ) = @_;
    
    my $db = $self->db();
    if (my $rec = $db->{ $id }) {
        my( @record );
        
        my ($file, $begin) = $self->unpack_record( $rec );
        
        # Get the (possibly cached) filehandle
        my $fh = $self->_file_handle( $file );

        # find the exactly line
        seek($fh, $begin, 0);

        my $firstLine = <$fh>;

        my ($SUID, $clone_id, $GenBank_accession, $array_element_type, $organism, $is_control, $locus_name_chromosome, $locus_name_BAC, $annotation) = split /\t/, $firstLine;

        #print "$SUID, $clone_id, $GenBank_accession, $array_element_type, $organism, $is_control, $locus_name_chromosome, $locus_name_BAC, $annotation\n";
        my %args = ('genbank_accession' => $GenBank_accession,
                    'array_element_type' => $array_element_type,
                    'locus_name_chromosome' => $locus_name_chromosome,
                    'locus_name_bac' => $locus_name_BAC,
                    'annotation' => $annotation);
        
        my $locus = Locus->new(%args);

        return $locus;


    } else {
	$self->throw("Unable to find a locus for $id in Desc index");
	return;
    }
}



1;



