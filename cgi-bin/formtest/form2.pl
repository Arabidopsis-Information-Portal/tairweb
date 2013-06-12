#!/bin/env perl
# ----------------------------------------------------
# -----
# -----  Forms To Go v2.6.7 by Bebosoft, Inc.
# -----
# -----  http://www.bebosoft.com/
# -----
# ----------------------------------------------------

use CGI;


$query = new CGI;

$Submit = $query->param("Submit");



# Redirect user to do not agree page

print "Location:/aracyc/doesnotagree.html\n\n";
exit;

# End of Perl script
