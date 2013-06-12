#!/bin/env perl

#############################################################################
##
##  FILE NAME
##    ucase_header.pl
##
##  SYNOPSIS 
##    ucase_header.pl fasta_file_name
##
##
##  DESCRIPTION
##    Converts header text to upper case for each sequence found in submitted
##    FASTA file.  This is done to normalize headers to allow case-insensitive
##    searching.  This script is used to create the following datasets:
## 
##         ATH1.seq.formatted (from ATH1_seq)
##         ATH1.cds.formatted (from ATH1_cds)
##         ATH1.pep.formatted (from ATH1_pep)
##         At.transcripts.formatted (from At_transcripts/ATH1_cdna)
##
##    These formatted datasets are used by the sequence bulk download tool to
##    retrieve sequences given a locus name.  Since these sets are indexed and
##    searched using the BioPerl module, there's no easy way to force the 
##    indexing or searching to be case insensitive; this script can be used to 
##    manually convert the headers before indexing.
##
##    Script writes all data to a new file that is named submitted file name 
##    plus ".formatted", where any underscore chars are turned into dots. Example
##
##    ATH1_seq -> ATH1.seq.formatted
##
##    Headers are identified by  leading ">" char
##
##  ARGUMENTS
##    fasta_file_name
##        FASTA data set file to parse
##
##  AUTHOR
##    nam@ncgr.org 7.7.03
##
#############################################################################

use strict;

# Get file name from command line -- exit if no file name submitted
my $file_name = $ARGV[ 0 ];

if ( $file_name eq "" ) {
  print "\nUsage: ucase_header.pl fasta_filename\n\n";
  exit( 0 );
}

# create new file name using source file + suffix
my $new_file_name = "$file_name" . ".formatted";
$new_file_name =~ s/_/\./g;

# transform "_" to "." to keep dataset names the same as in production
$new_file_name =~ s/_/\./g;


# read source file and uppercase any headers
open ( FILE, $file_name ) || die "Couldn't open $file_name: $!\n";
open ( NEWFILE, ">$new_file_name" ) || die "Couldn't open $new_file_name: $!\n";
while ( <FILE> ) { 
  my $line = $_;

  if ( $line =~ />/ ) {
    $line = uc( $line );
  }

  # write all lines to new file
  print NEWFILE $line;
}

close( FILE ) || die "Couldn't close $file_name: $!\n";
close( NEWFILE ) || die "Couldn't close $new_file_name: $!\n";
