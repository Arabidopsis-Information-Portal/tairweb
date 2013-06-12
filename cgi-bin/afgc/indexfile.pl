#!/bin/env perl 

# extremely quick and dirty file to make an index file of the
# array element data file. Index file is assumed to be there
# by atExpression.pm, but there is no facility provided to create
# it

use strict;
use Desc;

my $fileName = shift;

if ( !$fileName ) {
    die( "usage indexfile.pl fileName (full path)\n" );
}

my $Index_File_Name = "$fileName.dir";
my $inx = Desc->new( $Index_File_Name, 'WRITE' );
$inx->make_index($fileName);
