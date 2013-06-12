package CloneIdFinder;


use strict;
use TabFileIndex;


my $Data_File_Directory = "data/afgc/";


#my @Data_Files = qw(abiotic anatomical_comparison biotic development hormone metabolism test);

# new datasets from Suparna 8.7.2003
my @Data_Files = ( "abiotictreatment",
                   "biotictreatment",
                   "chemicaltreatment",
                   "ecotypecomparison",
                   "hormonetreatment",
                   "nonwildtypecomparison",
                   "nutrienttreatment",
                   "tissuecomparison"
                 );

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
    return [qw(clone_id home)];
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



sub find_datasets
  {
    my $self = shift;
    my $clone_id = $self->{'_clone_id'};
    my @File_List = ();
    my $inx;

    foreach my $file (@Data_Files){
   
      # enclose searching in eval() block since fetch action
      # will throw exception if no records found for clone id
      eval { 

        # make sure index files have been created for data file
        my $fileName = "$self->{_home}$Data_File_Directory$file/$file.data";
        my $Index_File_Name = "$fileName.dir";
        if ( !(-e $Index_File_Name ) ) {
          my $inx2 = TabFileIndex->new($Index_File_Name, 'WRITE');
          $inx2->make_index($fileName);
        }
        
        # create index object assuming data file is indexed and find sets for clone id
        $inx = TabFileIndex->new("$self->{'_home'}$Data_File_Directory$file/$file.data.dir");
        
        if (my $record = $inx->fetch($clone_id)){
          push (@File_List, $file);
        }

      }; 
          }
    return @File_List;
}


1;
