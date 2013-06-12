#!/bin/env perl
#
# untaint.pl   11/12/97 SW
###########################################################################

sub untaint  {
    local($value) = @_;
    # accept only words, hyphens periods, underscores, parentheses, primes
    $value =~ /([\w\s\-.,_\(\)\']+)/;
    return $1;
}

1;

