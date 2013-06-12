package MyBlast::WrapPartitionsFixed;

use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use BaseObj;
use MyUtils;
use MyDebug qw( dmsg dmsgs assert );
use List;
use ListSet;
use MyBlast::HitWrapper;
use MyBlast::MapSpace;
use MyBlast::MapDefs
    qw( $bucketZeroMax $bucketOneMax $bucketTwoMax $bucketThreeMax
       $bucketFourMax $kNumberOfPartitions );

@ISA = qw( BaseObj );

# partition 0 is for the 'best' hits, 5 for the 'worst'.
# P=1e-4 -- P=1e-10
# P=1e-10 -- P=1e-50
# P=1e-50 -- P=1e-100
# P=1e-100 -- P=1e-200
# P<1e-200

my( $kPartitionSet ) = MyUtils::makeVariableName( "partition", "set" ); # ListSet.
my( $kPartitionCounts ) = MyUtils::makeVariableName( "partition", "counts" );
my( $kRemovalPartitionIndex ) = MyUtils::makeVariableName( "removal", "partition", "index" );
my( $kSpace ) = MyUtils::makeVariableName( "space" );

sub init
{
    my( $self, $wrapListRef, $debugP ) = @_;
    my( $dex );

    # optional; is off if $debugP is undef.
  MyDebug::debugP( $debugP );

    $self->{ $kPartitionSet } = new ListSet();
    $self->{ $kPartitionCounts } = {}; # { dex => [ count before, after ] }.
    $self->{ $kSpace } = new MyBlast::MapSpace();

    $self->partitionWrappers( $wrapListRef );
}

# assumes that the wrappers are still
# in sorted order. that way, each of
# the partitions will itself be sorted.
sub partitionWrappers
{
    my( $self ) = shift;
    my( $list ) = shift;

    my( $wrap );
    my( $dex );
    my( $part );

    my( $enum ) = $list->getEnumerator();
    while( defined( $wrap = $enum->getNextElement() ) )
    {
	#dmsg( "partitionWrappers(): wrap = ", $wrap->toString() );

	# the problem here is that we only look at the exponent.
	# 1.0 and 0.0 are at opposite ends, yet they have the
	# same exponent, namely zero, so 1.0 gets put into
	# the wrong bucket. so rather than pass in only the exponent,
	# i pass in the whole thing. this is a different meaning
	# of the term 'value' than elsewhere.
	$part = $self->getPartitionFromExtendedValue( $wrap->getP() );

	$part->addElement( $wrap );
    }

    # now set the "before" counts.
    for( $dex = 0; $dex < $kNumberOfPartitions; $dex++ )
    {
	$part = $self->getPartitionAt( $dex );
	$self->addPartitionCountAt( $dex, $part->getCount() );
    }
}

# returns 0...(kNumberOfPartitions-1)
# [[ where 0 is for the 'highest' values, oddly enough.
# this whole higher/lower more/less significant thing sucks. ]]
sub getPartitionIndexFromExtendedValue
{
    my( $self, $value ) = @_;
    my( $dex );
    my( $step );
    my( $exp );

    if( $value <= $bucketZeroMax ) { $dex = 0; }
    elsif( $value <= $bucketOneMax ) { $dex = 1; }
    elsif( $value <= $bucketTwoMax ) { $dex = 2; }
    elsif( $value <= $bucketThreeMax ) { $dex = 3; }
    elsif( $value <= $bucketFourMax ) { $dex = 4; }
    else { confess( 'invalid value $value' ); }
   
    #dmsg( "getPartitionIndexFromExtendedValue( $value ): $dex" );

    return( $dex );
}

sub getPartitionFromExtendedValue
{
    my( $self, $value ) = @_;
    my( $dex );
    my( $part );

    $dex = $self->getPartitionIndexFromExtendedValue( $value );
    $part = $self->getPartitionAt( $dex );
    
    return( $part );
}

sub emptyP
{
    my( $self ) = shift;
    my( $emptyP );

    $emptyP = $self->{ $kPartitionSet }->emptyP();

    return( $emptyP );
}

sub nextRemovalPartitionIndex
{
    my( $self ) = shift;
    my( $thisDex );
    my( $nextDex );

    # assume we start with 0
    # and want to use it before
    # moving along, capiche?

    $thisDex = $self->getRemovalPartitionIndex();

    $nextDex = ($thisDex + 1) % $kNumberOfPartitions;
    $self->putRemovalPartitionIndex( $nextDex );

    return( $thisDex );
}

# this is so gross. sorry.
sub reduce
{
    #dmsg( "reduce()..." );

    my( $self ) = shift;
    my( $partSet );
    my( $setEnum );
    my( $list );
    my( $key );
    my( $listEnum );
    my( %listEnums );

    $partSet = $self->getPartitions();
    #dmsg( "reduce(): part count =", $partSet->getCount() );
    $setEnum = $partSet->getEnumerator();
    #dmsg( "reduce(): enum =", $setEnum );

    while( defined($list = $setEnum->getNextElement()) )
    {
	$listEnum = $list->getEnumerator();
	$key = $setEnum->getCurrentKey();
	$listEnums{ $key } = $listEnum;
	#dmsg( "reduce(): added $key $listEnum count=", $listEnum->getCount() );
    }

    my( $space ) = $self->{ $kSpace };
    my( @keys );
    my( @kill );
    my( $dex );
    my( $wrap );
    my( $debugCount ) = 0;

    # my apologies for how gross this code is!
    
    # while we have room left,
    # and there are still lists with data,
    # do one loop over the lists.
    # make sure to keep the list enumerations
    # sorted because we'll be deleting them
    # as they run out.

    for( @keys = sort keys( %listEnums );
	 (scalar(@keys) > 0) && (!$space->getFullP());
	 @keys = sort keys( %listEnums ) )
    {	
	# during one loop, stop if we run out of space.

	#dmsg( "reduce(): #keys = ", scalar(@keys) );

	for( $dex = 0;
	     ($dex < scalar(@keys)) && (!$space->getFullP());
	     $dex++ )
	{
	    #dmsg( " reduce(): dex = $dex, space =", $space->getSpaceRemaining() );

	    # get the current list to read.
	    $key = $keys[ $dex ];
	    $listEnum = $listEnums{ $key };
	    #dmsg( " reduce(): key=$key enum=$listEnum count=", $listEnum->getCount() );

	    # process it's current element.
	    if( defined( $wrap = $listEnum->getNextElement() ) )
	    {
		#dmsg( " reduce(): wrap =", $wrap->toString() );

		if( ! $space->wrapperFitsP( $wrap ) )
		{
		    #dmsg( " reduce(): doesn't fit" );
		    $listEnum->previousIndex();
		    $space->putFullP( 1 );
		}
		else
		{
		    $space->updateFromWrapper( $wrap );
		    #dmsg( " reduce(): does fit, added #", ++$debugCount, " from $key @ ", $listEnum->getIndex() );
		}
	    }
	    else
	    {
		#dmsg( " reduce(): no more elements for key $key, removing" );
		delete $listEnums{ $key }
	    }
	}
    }

    # if the lists have any elements left in them, shorten them.
    @keys = sort keys( %listEnums );
    #dmsgs( "reduce(): final keys = ", @keys );
    foreach $key ( @keys )
    {
	$listEnum = $listEnums{ $key };
	$dex = $listEnum->getIndex();

	# the index is of the last element successfully added to the space.
	#dmsg( "reduce(): $key $dex (max=", $listEnum->getCount(), ")" );

	$list = $listEnum->getList();
	$list->truncateAt( $dex+1 );
	#dmsg( "reduce(): $key $dex list=", $list->toString() );
    }

    # now set the "after" counts.
    for( $dex = 0; $dex < $kNumberOfPartitions; $dex++ )
    {
	$part = $self->getPartitionAt( $dex );
	$self->addPartitionCountAt( $dex, $part->getCount() );
    }

    #dmsg( "...reduce()" );
}

sub getHeight
{
    my( $self ) = shift;

    return( $self->{ $kSpace }->getSpaceUsed() );
}

#
# boring stuff.
#

sub getRemovalPartitionIndex
{
    my( $self ) = shift;
    return( $self->{ $kRemovalPartitionIndex } );
}

sub putRemovalPartitionIndex
{
    my( $self, $pdex ) = @_;
    $self->{ $kRemovalPartitionIndex } = $pdex;
}

sub getPartitions
{
    my( $self ) = shift;
    return( $self->{ $kPartitionSet } );
}

# as long as N < $kNumberOfPartitions,
# this will return a List, however,
# the list might have zero elements
# in it (but you will always get
# list, not undef).
sub getPartitionAt
{
    my( $self, $n ) = @_;

    $part = $self->{ $kPartitionSet }->getListAt( $n );

    return( $part );
}

sub putValueRange
{
    my( $self, $sr ) = @_;
    #dmsg( "putValueRange( $sr )" );
    $self->{ $kValueRange } = $sr;
}

sub getValueRange
{
    my( $self ) = shift;
    my( $range ) = $self->{ $kValueRange };
    assert( defined($range), "call calculateValueRange() first" );
    return( $range );
}

sub getMaxAnnotationWidthForFont
{
    my( $self ) = shift;
    my( $fontWidth ) = shift;
    my( $pdex );
    my( $part );
    my( $enum );
    my( $wrap );
    my( $max );
    my( $str );
    my( $width );

    $max = 0;

    for( $pdex = 0; $pdex < $kNumberOfPartitions; $pdex++ )
    {
	$part = $self->getPartitionAt( $pdex );
	$enum = $part->getEnumerator();

	for( $wrap = $enum->getNextElement();
	    defined( $wrap );
	    $wrap = $enum->getNextElement() )
	{

	    $str = $wrap->getGraphAnnotation();
	    $width = length( $str ) * $fontWidth;
	    if( $width > $max )
	    {
		$max = $width;
	    }
	    #dmsg( "font width=$width, max=$max" );
	}
    }

    return( $max );
}

sub toString
{
    my( $self ) = shift;
    my( $str );
    my( @strs );
    my( $dex );
    my( $step );
    
    $step = $self->getPartitionValueStep();

    for( $dex = 0; $dex < $kNumberOfPartitions; $dex++ )
    {
	$str = $dex * $step + $self->getLowValue();
	$str .= '-';
	$str .= ($dex+1) * $step - 1 + $self->getLowValue();
	push( @strs,  MyUtils::makeDumpString( $dex, $str ) );
    }

    $str = MyUtils::makeDumpString( $self, $kNumberOfPartitions, @strs );

    return( $str );
}

sub addPartitionCountAt
{
    my( $self, $dex, $count ) = @_;
    my( $ref );

    $ref = $self->{ $kPartitionCounts }->{ $dex };
    if( !defined( $ref ) )
    {
	$self->{ $kPartitionCounts }->{ $dex } = [ $count ];
    }
    else
    {
	push( @{$ref}, $count );
    }
}

sub getPartitionElementsCountAfter
{
    my( $self ) = shift;
    my( $count );
    my( $dex );
    my( $pairRef );
    
    for( $dex = 0; $dex < $kNumberOfPartitions; $dex++ )
    {
	$pairRef = $self->getPartitionElementsCountsRefAt( $dex );
	$count += $$pairRef[ 1 ];
    }

    return( $count );
}

sub getPartitionElementsCountBefore
{
    my( $self ) = shift;
    my( $count );
    my( $dex );
    my( $pairRef );
    
    for( $dex = 0; $dex < $kNumberOfPartitions; $dex++ )
    {
	$pairRef = $self->getPartitionElementsCountsRefAt( $dex );
	$count += $$pairRef[ 0 ];
    }

    return( $count );
}

sub getPartitionElementsCountsRefAt
{
    my( $self, $dex ) = @_;
    my( $ref );

    $ref = $self->{ $kPartitionCounts }->{ $dex };

    return( $ref );
}

1;
