
#
# BioPerl module for Bio::Index::Abstract
#
# Cared for by Guanghong Chen <gc@ncgr.org>
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

TabFileIndex - Interface for indexing tab delimited files

=head1 SYNOPSIS

    # Complete code for making an index for several
    # tab delimited flat files
    use TabFileIndex;

    my $Index_File_Name = shift;
    my $inx = TabFileIndex->new($Index_File_Name, 'WRITE');
    $inx->make_index(@ARGV);

    # Print out several lines present in the index

    use TabFileIndex;

    my $Index_File_Name = shift;
    my $inx = TabFileIndex->new($Index_File_Name);

    foreach my $id (@ARGV) {
        my $line = $inx->fetch($id); # Returns a line
        print "$line\n";;
    }


=head1 DESCRIPTION

Inherits functions for managing dbm files from Bio::Index::Abstract.pm,
and provides the basic funtionallity for indexing tab delimited files, and
retrieving the line from them. 


=head1 AUTHOR - Guanghong Chen

Email - gc@ncgr.org

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package TabFileIndex;

use vars qw($VERSION @ISA @EXPORT_OK);
use strict;

use Bio::Index::Abstract;
use Locus;

@ISA = qw(Bio::Index::Abstract Exporter);
@EXPORT_OK = qw();

sub _type_stamp {
    return '__TAB__'; # What kind of index are we?
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
  Function: Specialist function to index TAB format files.
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

    open TAB, $file or $self->throw("Can't open file for read : $file");

    # Main indexing loop
    while (<TAB>) {

      if ($. != 1){ # if is not first line, which usually column headers

            $begin = tell(TAB) - length( $_ );
            foreach my $id (&$id_parser($_)) {
                $self->add_record($id, $i, $begin, $.);
            }
        }
    }

    close TAB;
    return 1;
}



=head2 id_parser

  Title   : id_parser
  Usage   : $index->id_parser( CODE )
  Function: Stores or returns the code used by record_id
            to parse the ID for record from a string.  Useful
            for (for instance) specifying a different parser
            for different flavours of TAB file.
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
  Function: The default TabFileIndex ID parser for TabFileIndex.pm
            Returns first column from tab delimited line
  Example : 
  Returns : ID string
  Args    : a tab delimited line string

=cut

sub default_id_parser {

    my $line = shift;

    my ($id, $rest) = split /\t/, $line, 2;

    return $id;
}


=head2 fetch

  Title   : fetch
  Usage   : $index->fetch( $id )
  Function: Returns a Bio::Seq object from the index
  Example : $seq = $index->fetch( 'dJ67B12' )
  Returns : a line string
  Args    : ID

=cut

sub fetch {
    my( $self, $id ) = @_;
    
    my $db = $self->db();
    if (my $rec = $db->{ $id }) {

        my ($file, $begin) = $self->unpack_record( $rec );

        # Get the (possibly cached) filehandle
        my $fh = $self->_file_handle( $file );

        # find the exactly line
        seek($fh, $begin, 0);

        my $line = <$fh>;

        return $line;


    } else {
	$self->throw("Unable to find a line for $id in TabFileIndex index");
	return;
    }
}

sub fetch_line_number {
    my( $self, $id ) = @_;
    
    my $db = $self->db();
    if (my $rec = $db->{ $id }) {

        my ($file, $begin, $line_number) = $self->unpack_record( $rec );

        return $line_number;

    } else {
	$self->throw("Unable to find a line number for $id in TabFileIndex index");
	return;
    }
}

1;



