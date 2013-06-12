package ScientificNotation;

use Carp;
use lib "/share/fasolt/www-data/cgi-bin/lib/jces";
use MyDebug qw( dmsg debugP );

my( $kZero ) = '0.0e0';
my( $kOne ) = '1.0e0';

# some day i should make a really strong set
# of regexps to make sure i'm handling valid numbers.
my( $kAllowedGlyphsRegexp ) = '[\de\.-]';
my( $kNotAllowedGlyphsRegexp ) = '[^\de\.-]';

debugP( 0 );

# i want a zero p value to be the first thing in the list - we're really
# trying to sort from most to least significant. gross.
sub cmp
{
    my( $a, $b ) = @_;

    my( $asn, $am, $ae );
    my( $bsn, $bm, $be );
    my( $cmp );

    $asn = toScientificNotation( $a );
    $am = getMantissa( $asn );
    $ae = getExponent( $asn );

    $bsn = toScientificNotation( $b );
    $bm = getMantissa( $bsn );
    $be = getExponent( $bsn );

    if( isZero( $asn ) && ! isZero( $bsn ) )
    {
	$cmp = -1;
    }
    elsif( isZero( $bsn ) && ! isZero( $asn ) )
    {
	$cmp = 1;
    }
    elsif( $ae == $be )
    {
	$cmp = $am <=> $bm;
    }
    else
    {
	$cmp = $ae <=> $be;
    }    

    return( $cmp );
}

sub isZero
{
    my( $num ) = shift;
    my( $zP );

    $num = toScientificNotation( $num );

    if( $num eq $kZero )
    {
	$zP = 1;
    }
    else
    {
	$zP = 0;
    }

    return( $zP );
}

sub isOne
{
    my( $num ) = shift;
    my( $zP );

    #dmsg( "isOne(): before = $num" );
    $num = toScientificNotation( $num );
    #dmsg( "isOne(): after = $num" );

    if( $num eq $kOne )
    {
	$zP = 1;
    }
    else
    {
	$zP = 0;
    }

    return( $zP );
}

sub getMantissa
{
    my( $num ) = shift;
    my( $man );

    $num = toScientificNotation( $num );
    $man = $num;
    $man =~ s/(^[^e]*)e.*/$1/;

    return( $man );
}

sub getExponent
{
    my( $num ) = shift;
    my( $exp );

    $num = toScientificNotation( $num );
    $exp = $num;
    $exp =~ s/^[^e]*e(.*)/$1/;

    return( $exp );
}

sub toScientificNotation
{
    my( $num ) = shift;
    my( $sn );

    #dmsg( "toScientificNotation( $num )" );

    if( ! numberP( $num ) ) { confess( 'NAN' ); }

    # this could turn a number into string by add .0 at the end of the number
    # example: 1e-60 ==> Argument "1e-60.0" isn't numeric in eq a

    if( $num == 0 )
      
      {
	$sn = $kZero;
	return $sn;
      }

    $num = cleanNumber( $num );
    
    if( $num =~ m/([^e]*)e([^e]*)/ )
    {
	$sn = $num;
    }
    elsif( $num =~ m/(\d*)\.(\d*)/ )
    {
	my( $oldPre, $newPre );
	my( $oldPost, $newPost );
	my( $lenPre );

	$oldPre = $1;
	$oldPost = $2;
	$lenPre = length( $oldPre );

	# first case: \d{2,}\.\d*
	if( $lenPre > 1 )
	{
	    my( $exp );

	    $newPre = substr( $oldPre, 0, 1 );
	    $newPost = substr( $oldPre, 1 );
	    $newPost .= $oldPost;
	    $exp = $lenPre-1;
	    $sn = "$newPre.$newPost" . 'e' . $exp;
	    $sn = addSignPrefix( $sn, $num );
	}
	# second case: [1-9]\.\d*
	elsif( $lenPre == 1 && $oldPre != 0 )
	{
	    $sn = "$oldPre.$oldPost" . 'e0';
	}
	# last case: 0\.\d*
	else
	{
	    my( $zcount );
	    my( $exp );

	    if( $oldPost =~ m/^(0+)/ )
	    {
		$zcount = length( $1 );
	    }
	    else
	    {
		$zcount = 0;
	    }
	    $exp = $zcount + 1;

	    # we resuse ourself to set the decmial
	    # and then reset the bogus exponent value
	    # to the correct one we just computed.
	    #dmsg( "toScientificNotation(): before $oldPost" );
	    $sn = toScientificNotation( $oldPost );
	    #dmsg( "toScientificNotation(): after $sn" );

	    $sn =~ s/e.*//;
	    $sn .= "e-$exp";
	}
    }

    #dmsg( "toScientificNotation(): $sn" );

    return( $sn );
}

sub cleanNumber
{
    my( $str ) = shift;

    #dmsg( "cleanNumber( $str )" );

    if( ! numberP( $str ) )
    {
	die( "cleanNumber(): can't parse $str" );
    }

    # remove any leading zeros since
    # they only confuse things.
    $str =~ s/^0+(.*)/$1/;

    #dmsg( "cleanNumber(): 1 $str" );

    # but we'd like to have a single
    # leading zero before the decimal
    # point if all we have is a fraction.
    if( $str =~ m/^\./ )
    {
	$str = "0$str";
    }

    #dmsg( "cleanNumber(): 2 $str" );

    # remove any trailing zeros.
    if( $str =~ m/(.*e\d)0+$/ )
    {
	$str = $1;
    }

    #dmsg( "cleanNumber(): 3 $str" );

    # we want to make sure there
    # is a decmial in there somewhere,
    # because that's what our converter
    # is looking for.
    if( $str !~ m/\./ )
    {
	$str = "$str.0";
    }

    #dmsg( "cleanNumber(): 4 $str" );

    # make sure there's something
    # after the decimal, too.
    if( $str =~ m/\.$/ )
    {
	$str .= "0";
    }

    #dmsg( "cleanNumber(): final output = $str" );

    return( $str );
}

sub addSignPrefix
{
    my( $str ) = shift;
    my( $num ) = shift;
    my( $negP );

    $negP = negativeP( $num );
    if( $negP )
    {
	$str = "-$str";
    }

    return( $str );
}

sub negativeP
{
    my( $num ) = shift;
    my( $negP );

    if( $num >= 0 )
    {
	$negP = 0;
    }
    else
    {
	$negP = 1;
    }

    return( $negP );
}

sub numberP
{
    my( $str ) = shift;
    my( $numP );

    # if anything other than acceptable
    # items are found, then it's not
    # a number.

    $numP = 1;

    if( !defined( $str ) )
    {
	confess( "undef value not allowed" );
    }
    elsif( $str !~ m/\S/ )
    {
	$numP = 0;
    }
    elsif( $str =~ m/$kNotAllowedGlyphsRegexp/ )
    {
	$numP = 0;
    }
    elsif( countRegexp( $str, '\.' ) > 1 )
    {
	$numP = 0;
    }
    elsif( countRegexp( $str, '\-' ) > 2 )
    {
	$numP = 0;
    }

    return( $numP );
}

sub countRegexp
{
    my( $str, $regexp ) = @_;
    my( $count ) = 0;

    while( $str =~ m/$regexp/ )
    {
	$str =~ s/$regexp//;
	$count++;
    }

    return( $count );
}

1;
