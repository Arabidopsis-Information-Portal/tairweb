package hyperGeom;
use Math::BigInt;
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(binomialCumulative binomial choose chooseBig factorial hypergeometric hypergeometricBig);

sub hypergeometric{

    my ($x, $k, $m, $n) = @_;
    return unless $m>0 && $m==int($m) && $n>0 && $n==int($n) && $k>0 && $k<=$m+$n;
    return 0 unless $x<=$k && $x==int($x);
    
    
    #return ($n);
    return choose($m,$x) * choose($n,$k-$x)/choose($m+$n,$k);
    
}


sub hypergeometricBig{

    my ($x, $k, $m, $n) = @_;
    return unless $m>0 && $m==int($m) && $n>0 && $n==int($n) && $k>0 && $k<=$m+$n;
    return 0 unless $x<=$k && $x==int($x);
    
    
    my $nom = chooseBig($m,$x)->bmul(chooseBig($n,$k-$x)); 
    
    return ($nom)->bdiv(chooseBig($m+$n,$k));
    
}

sub binomial{

    my ($n,$k,$p) = @_;
    return $k==0 if $p==0;
    return $k!=$n if $p==1;

    return choose($n,$k) * $p**$k * (1-$p)**($n-$k);
}

sub binomialCumulative{

   my ($n,$k,$p) = @_;
   my $sum;
   return $k==0 if $p==0;
   return $k!=$n if $p==1;

   while($k < $n){
       
       $sum += choose($n,$k) * $p**$k * (1-$p)**($n-$k);
       $k ++;
   }
   return $sum;
}


sub chooseBig{

    my ($n, $k) = @_;
    return 0 if $k > $n || $k < 0;
    $k = ($n - $k) if ($n - $k) < $k;
    
    my $denom = factorial($k)->bmul(factorial($n-$k));
    my $result = factorial($n)->bdiv($denom);
    return $result;
    
}

# choose($n, $k) is the number of ways to choose $k elements from a set
# of $n elements, when the order of selection is irrelevant.
#
sub choose {
    my ($n, $k) = @_;
    my ($result, $j) = (1, 1);

    
    return 0 if $k > $n || $k < 0;
   
    $k = ($n - $k) if ($n - $k) < $k;

    while ( $j <= $k ) {
        $result *= $n--;
        $result /= $j++;
    }
    return $result;
}


sub choose_simple {
    my ($n, $k) = @_;
    return permutation($n,$k) / permutation($n-$k);
}



# permutation(n) is the number of permutations of n elements.
# permutation(n,k) is the number of permutations of k elements
#    drawn from a set of n elements.  k and n must both
#    be positive integers.
sub permutation {
    my ($n, $k) = @_;
    my $result  = 1;

    defined $k or $k = $n;
    while ( $k-- ) { $result *= $n-- }
    return $result;
}


sub factorial{

    my ($n, $i) = shift;
    my $result = Math::BigInt->new("1");
    return 1 if ($n < 1);
    for ($i=2; $i <=$n; $i ++){
    
	$result *= $i;
	
    }
    return $result;
}


1;
