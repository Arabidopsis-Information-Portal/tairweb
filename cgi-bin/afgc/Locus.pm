#------------------------------------------------------------------------
# $Id:
#
# Copyright 2002. NCGR. All rights reserved.
#
# Represent a row in the AFGC_arrayelements_082002.txt file,
# which is tab delimited.
#
#------------------------------------------------------------------------
#
# Cared for by Guanghong Chen <gc@ncgr.org>
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Locu - Interface for indexing clone_id locus_name description files

=head1 SYNOPSIS

    # Complete code for making an index for several
    # locus flat files
    use Locus;

    my %args = ('genbank_accession' => 'N96120',
	    'array_element_type' => 'EST',
	    'locus_name_chromosome' => 'At2g14260',
	    'locus_name_bac' => 'T1O16.15',
	    'annotation' => 'proline iminopeptidase');

    my $locus = Locus->new(%args);

    # Print out locus name
    print $locus->locus_name_chromosome();


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
  http://bio.perl.org/MailList.html              - About the mailing lists

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

package Locus;

use vars qw($VERSION @ISA @EXPORT_OK);
use strict;

@EXPORT_OK = qw();

sub _version {
    return 0.1;
}

$VERSION = _version();


=head2 _initialize

  Title   : new
  Usage   : $index->new
  Function: parse the arguments into different attributes.
  Example : 
  Returns : 
  Args    : 

=cut

sub new
  {

    my ($class, %args) = @_;
    my $self = {};
    bless $self, ref($class) || $class;

    $self->parse_args(construct(), %args);

    return $self;
}


sub construct
  {
    return [qw(genbank_accession array_element_type locus_name_chromosome locus_name_bac annotation)];
  }


# A generic method to parse arguments that loosely match the keys in input hash %args.
sub parse_args
  {
    my ($self, $list, %args) = @_;
    foreach my $arg (@$list)
      {
	#-- this would not work when two args match to the same element in list.
	my $k = join '', grep {$_ =~ /^(-|_)?$arg$/i} (keys %args);

	$self->{'_'.$arg} = $k ? $args{$k} : undef;
      }
  }

# getter/setter combo

sub genbank_accession
  {
    my $self = shift;
    @_ ? $self->{'_genbank_accession'} = shift      #modify attribute
      : $self->{'_genbank_accession'};               #retrieve attribute
  }

sub array_element_type
  {
    my $self = shift;
    @_ ? $self->{'_array_element_type'} = shift      #modify attribute
      : $self->{'_array_element_type'};               #retrieve attribute
}

sub locus_name_chromosome
  {
    my $self = shift;
    @_ ? $self->{'_locus_name_chromosome'} = shift      #modify attribute
      : $self->{'_locus_name_chromosome'};               #retrieve attribute
}
sub locus_name_bac
  {
    my $self = shift;
    @_ ? $self->{'_locus_name_bac'} = shift      #modify attribute
      : $self->{'_locus_name_bac'};               #retrieve attribute
}
sub annotation
  {
    my $self = shift;
    @_ ? $self->{'_annotation'} = shift      #modify attribute
      : $self->{'_annotation'};               #retrieve attribute
}




1; # To signify successful initialization
