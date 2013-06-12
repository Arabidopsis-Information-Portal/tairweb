

package LociSeqFetch;


use strict;
use Bio::Index::Fasta;

my $LOCUS_PATTERN = '[aA][tT]\w[gG]\d{5}';
my $INTRON_PATTERN = '[aA][tT]\w[gG]\d{5}\.\w-\w';

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
    return [qw(index_file)];
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


sub convert_locus_names_to_array {
  my($self, $locusName) = @_;
  $locusName =~ s/^\s+//;#Trim leading white space
  $locusName =~  s/\s+$//; #Trim trailing whitespace
  
  
  $locusName = uc($locusName);     # convert to uppercase
  $locusName =~ s/\n/\t/g;         # convert newlines to tabs
  $locusName =~ s/\r/\t/g;         # convert carriage returns to tabs
  $locusName =~ s/[, ;:]/\t/g;     # convert separators to tabs - be careful not to convert dots
  # (can be part of id for multiple alternetaly spliced variants)
  
  
  $locusName =~ tr/\t/\t/s;      # squash multiple tabs into one
       
    my @loci = split /\t/, $locusName;

  return \@loci;
}

sub fetch_loci_sequences
  {
    my($self, $locusName, $is_alternate_spliced_dataset) = @_;


    $locusName =~ s/^\s+//;#Trim leading white space
    $locusName =~  s/\s+$//; #Trim trailing whitespace
    
    
    $locusName = uc($locusName);     # convert to uppercase
    $locusName =~ s/\n/\t/g;         # convert newlines to tabs
    $locusName =~ s/\r/\t/g;         # convert carriage returns to tabs
    $locusName =~ s/[, ;:]/\t/g;     # convert separators to tabs - be careful not to convert dots
    # (can be part of id for multiple alternetaly spliced variants)
    
    
    $locusName =~ tr/\t/\t/s;      # squash multiple tabs into one

    my @loci = split /\t/, $locusName;


    my @no_seq_found = ();
    my $sequence;

    #if (!(-e ($self->{_index_file}))) {
    #  die "Data file, $self->{_index_file}, does not exist. Please send email to informatics\@arabidopsis.org for help. ";
    #}
    if (!(-e ($self->{_index_file}.".dir"))) {
      die "Data file, $self->{_index_file}, is not indexed. Please send email to informatics\@arabidopsis.org for help. ";
    }

    my $inx = Bio::Index::Fasta->new($self->{_index_file}.".dir");
    #my $inx = Bio::Index::Fasta->new($self->{_index_file});

    foreach my $seqid (@loci) {


      # if the identifier has the format At1g01010 but no extension, add .1
      if ($is_alternate_spliced_dataset){
        if (($seqid =~/[aA][tT][\dmMcC][gG]\d{5}/) && ($seqid !~/[aA][tT][\dmMcC][gG]\d{5}\.\d/))
          { $seqid .=".1";}
      }

      my $seq =  $inx->fetch($seqid); # Returns Bio::Seq object


      if (ref($seq))  {
        my $sequen = $seq -> seq();
        my $description = $seq -> desc();
        chomp($description);
	
	
        $sequen =~ s/(.{100})/$1\n/g;
        $sequen =~ s/\n$//;   
        # if the last line is exactly 100 long there will be
        # a CR at the end -- remove one.

        $sequence .= ">$seqid $description\n$sequen\n";
	
      }
      else {
        push @no_seq_found, $seqid;
      }
    }

    return ($sequence, \@no_seq_found);
}


sub fetch_loci_sequences_by_array
  {
    my($self, $loci, $is_alternate_spliced_dataset, $outputformat, $dataset ) = @_;
    
    my @no_seq_found = ();
    my $sequence;
	#track sequences we've already seen when downloading for multiple
    my %seen;

    if (!(-e ($self->{_index_file}.".dir"))) {
      die "Data file, $self->{_index_file}, is not indexed. Please send email to informatics\@arabidopsis.org for help. ";
    }

#    my $inx = Bio::Index::Fasta->new($self->{_index_file});
    my $inx = Bio::Index::Fasta->new($self->{_index_file}.".dir");
    
    # if dataset is 'At_intron', make sure that the loci array is correct
    if ($dataset eq "At_intron"){
        
        #make sure it has locus or gene otherwise, dont need to do this
        my $non_intron = "false";
        foreach my $seqid( @$loci ){
            if ($seqid !~/$INTRON_PATTERN/){
                $non_intron = "true";
            }
        }
        
        #if has non-intron format (gene or locus) find all introns
        if ($non_intron eq "true") {
            my @all_ids = $inx->get_all_primary_ids();
            my @loci_temp;
            foreach my $seqid( @$loci) {
                foreach my $id(@all_ids){
                    if ($id =~ /$seqid/){
                        push @loci_temp, $id;
                    }
                }
            }
            if (@loci_temp > 0 ){
                @$loci = @loci_temp;
            }
        }
        @$loci = sort(@$loci);
    }
    
    foreach my $seqid (@$loci) {

      # if the identifier has the format At1g01010 but no extension, add .1
      if ($is_alternate_spliced_dataset){
	      #if (($seqid =~/AT\wG\d{5}/) && ($seqid !~/AT\wG\d{5}\.\d/))
	      if (($seqid =~/$LOCUS_PATTERN/) && ($seqid !~/$LOCUS_PATTERN\.\d/)) { $seqid .=".1";}
	  }

	if(!$is_alternate_spliced_dataset && $seqid =~ /($LOCUS_PATTERN)\.\d+/ && $seqid !~ /($LOCUS_PATTERN)\.\d+\-\d+/ && $dataset ne "direct_search")
	{
		$seqid = $1;
	}
	my @ids;
	#if(($seqid =~ /^$LOCUS_PATTERN$/ && $is_alternate_spliced_dataset) || ($self->{_index_file} =~ m/[iI]ntergenic|[iI]ntron/ && $seqid !~ /($LOCUS_PATTERN)\.\d+\-\d+/))
	
	my %seqids;
	#>+AT1G01010 | chr1:1-3630 FORWARD
	#>AT1G01010-AT1G01020 | chr1:5900-6789 FORWARD
	#>AT1G01010- | chr1:1-3630 FORWARD
	if($self->{_index_file} =~ m/[iI]ntergenic/)
	{
		my $grep = "grep $seqid $self->{_index_file}";
		my @headers = `$grep`;
		foreach my $header (@headers)
		{
			$header =~ /^>((\w+)(\s+|((\-)(\w+)\s+)))\|.*$/;
			my $id = $1;
			my $first = $2;
			my $delimiter = $5;
			my $second = $6;
			$first =~ s/\s//g;
			$second =~ s/\s//g;
			$id =~ s/\s//g;
			if(($first eq $seqid) || ($delimiter eq '-' && length($second) > 0 && $second eq $seqid))
			{
				#print "id |$id|\n";
				$seqids{$id}=1;
			}
		}	
		#@ids = $inx->get_all_primary_ids();
	}

	#id intergenic we need to do an exact match between the fasta id in the header and the id
	#we've been given (AGI)
	#my %seqids2;
	#if(defined(@ids))
	#{
#		foreach my $id (@ids)
#		{
#			if($id =~ /$seqid/)
#			{
#				print "read id |$id|\n";
#				$seqids2{$id}=1;
#			}
#		}
#	}
	if(!defined(%seqids) || scalar keys %seqids < 1)
	{
		$seqids{$seqid}=1;
	}
	#print (scalar keys %seqids)." ".defined(@ids)."\n";
foreach my $seqid_ (sort keys %seqids)
{
#	if(defined($seen{$seqid_}))
#	{
#		next;
#	}
#	$seen{$seqid_}=1;
      my $seq =  $inx->fetch($seqid_); # Returns Bio::Seq object
      #print "seqid_ $seqid_ |$seq|\n";
	#print "fetching $seqid $seq ".$self->{_index_file}."\n";

      if (ref($seq))  {
        my $sequen = $seq -> seq();
        my $description = $seq -> desc();
        chomp($description);
	
	
        $sequen =~ s/(.{100})/$1\n/g;
        $sequen =~ s/\n$//;   
        # if the last line is exactly 100 long there will be
        # a CR at the end -- remove one.
	

	# output sequence in tab-delimited format or fasta according
	# to what user selected on webform
	if ( $outputformat eq "tabtext" ) 
	  {
	    ## remove all new lines from sequence text form plain text version
	    $sequen =~ s/\n//g;

	    $sequence .= "$seqid_\t$description\t$sequen\n";
	  } 
	else
	  {
	    $sequence .= ">$seqid_ $description\n$sequen\n";
	  } 
      }
      else {
        push @no_seq_found, $seqid;
      }
}
    }

    return ($sequence, \@no_seq_found);
}

1;
