#!/bin/env perl

## Describes the file format for the data.tab file.

package format;
use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($ACCESSION_COL 
	     $LOCUS_COL 
	     $OTHER_GENE_NAMES_COL 
	     $PROPOSAL_NAME_COL
	     $PROPOSAL_NUM_COL
	     $PI_COL
	     $COMMENT_COL
	     $GRANTING_AGENCY_COL
	     $WEB_SITE_COL
	     $OPTIONAL_PROPOSAL_NUMBER_URL_COL
	     );

## The respective column positions in our data file.  If we need to add new
## columns, please make sure to modify GetRow appropriately.
$ACCESSION_COL = 0;
$LOCUS_COL = 1;
$OTHER_GENE_NAMES_COL = 2;
$PROPOSAL_NAME_COL = 3;
$PROPOSAL_NUM_COL = 4;
$PI_COL = 5;
$COMMENT_COL = 6;
$GRANTING_AGENCY_COL = 7;
$WEB_SITE_COL = 8;


## The last column here is not required.  If the source of the data is
## non-NSF, then we can't automatically provide a URL link on the
## proposal number, since we have no idea what to link to.  If
## OPTIONAL_PROPOSAL_NUMBERL_URL_COL is provided, we use that.
$OPTIONAL_PROPOSAL_NUMBER_URL_COL = 9;





1;
