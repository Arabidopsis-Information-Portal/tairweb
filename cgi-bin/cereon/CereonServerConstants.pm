#!/usr/local/bin/perl -w

########################################################################
#
# Module to encapsulate web server URL constants needed by cereon scripts
# for correctly switching between https:// and http:// sections of the
# site.  Values should be edited appropriately for each environment
# scripts are deployed to.
#
#########################################################################

package CereonServerConstants;
use strict;
use base 'Exporter';
#our @ISA = qw( Exporter );
our @EXPORT_OK =
    qw( $secureServer $webServer $dataPath $cereonMail $server $database $port $dbuser $dbpassword );


our $server = "argentina";
our $port=1521;
our $database = 'tairprod';
#my $dbuser = 'tairdbo';
#my $dbpassword = 'm14kwood';
our $dbuser = 'cereonadmin';
our $dbpassword = 'sari0wN';

our $secureServer = "https://www.arabidopsis.org:443";
our $webServer = "http://www.arabidopsis.org";
our $dataPath = $ENV{DOCUMENT_ROOT}."/../data/cereon/";
our $cereonMail = "jeff.woessner\@monsanto.com";
