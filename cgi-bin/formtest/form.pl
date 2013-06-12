#!/bin/env perl -Tw
# ----------------------------------------------------
# -----
# -----  Forms To Go v2.6.7 by Bebosoft, Inc.
# -----
# -----  http://www.bebosoft.com/
# -----
# ----------------------------------------------------

use CGI;
use strict;
#use warnings;

## We modify PATH to be as minimal as possible. See perldoc perlsec
## for details.
$ENV{PATH} = "/bin:/usr/bin"; # Minimal PATH.

#----------
# Validate: String

sub check_string
{
 my($value, $low, $high, $mode, $optional) = @_;

 if ( (length($value) == 0) && ($optional == 1) ) {
  return 1;
 }
 elsif ((length($value) >= $low) && ($mode == 1)) {
  return 1;
 }
 elsif ((length($value) <= $high) && ($mode == 2)) {
  return 1;
 }
 elsif ((length($value) >= $low) && (length($value) <= $high) && ($mode == 3)) {
  return 1;
 }
 else {
  return 0;
 }
}
#----------
# Validate: Email

sub check_email
{
 my($email, $optional) = @_;

 if ( (length($email) == 0) && ($optional == 1) ) {
  return 1;
 }
 elsif ( $email !~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ &&
	 $email =~ /^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/i ) {
  return 1;
 }
 else {
  return 0;
 }
}

#----------
# Validate: Equal to field

sub check_equalto
{
 my($original, $repeated) = @_;

 if ($original eq $repeated) {
  return 1;
 }
 else {
  return 0;
 }
}
my $mailProg = '/usr/lib/sendmail -t';

my $query = new CGI;

my $title = $query->param("title") || "";
my $name = $query->param("name") || "";
my $email = $query->param("email") || "";
my $repeatemail = $query->param("repeatemail") || "";
my $institution = $query->param("institution") || "";
my $department = $query->param("department") || "";
my $address = $query->param("address") || "";
my $phone = $query->param("phone") || "";
my $Institution_type = $query->param("Institution_type") || "";
my $Submit = $query->param("Submit") || "";


# Field Validations

my $validationFailed = 0;
my $errorList = '';
my $FTGname_errmsg = '';
if ( (! check_string($name, 1, 0, 1, 0))) {
 $validationFailed = 1;
 $FTGname_errmsg = "Name";
 $errorList .= $FTGname_errmsg . '<BR>';
}

my $FTGemail_errmsg = '';
if ( (! check_email($email, 0))) {
 $validationFailed = 1;
 $FTGemail_errmsg = "Email address";
 $errorList .= $FTGemail_errmsg . '<BR>';
}

my $FTGrepeatemail_errmsg = '';
if ( (! check_equalto($repeatemail, $email))) {
 $validationFailed = 1;
 $FTGrepeatemail_errmsg = "Repeat email address";
 $errorList .= $FTGrepeatemail_errmsg . '<BR>';
}

my $FTGinstitution_errmsg = '';
if ( (! check_string($institution, 1, 0, 1, 0))) {
 $validationFailed = 1;
 $FTGinstitution_errmsg = "Institution ";
 $errorList .= $FTGinstitution_errmsg . '<BR>';
}

my $FTGaddress_errmsg = '';
if ( (! check_string($address, 1, 0, 1, 0))) {
 $validationFailed = 1;
 $FTGaddress_errmsg = "Address";
 $errorList .= $FTGaddress_errmsg . '<BR>';
}

my $FTGInstitution_type_errmsg = '';
if ( (! check_string($Institution_type, 1, 0, 1, 0))) {
 $validationFailed = 1;
 $FTGInstitution_type_errmsg = "Institution Type";
 $errorList .= $FTGInstitution_type_errmsg . '<BR>';
}

# Embed error page and dump it to the browser

if ($validationFailed == 1) {

my $HOME = "$ENV{DOCUMENT_ROOT}/..";
my $fileErrorPage = "$HOME/htdocs/aracyc/error.html";

 if (!(-e $fileErrorPage)) {
  print "Content-type: text/html\n\n";
  print 'The error page: <b>' . $fileErrorPage. '</b> cannot be found on the server.';
  exit;
 }

 open(HANDLE, $fileErrorPage);
 my @errorPage = <HANDLE>;
 close(HANDLE);
 my $errorPage = '';
 foreach my $pageLine (@errorPage) {
  $errorPage .= $pageLine;
 }

 $errorPage =~ s/<!--VALIDATIONERROR-->/$errorList/;

 $errorPage =~ s/<!--FIELDVALUE:title-->/$title/;
 $errorPage =~ s/<!--FIELDVALUE:name-->/$name/;
 $errorPage =~ s/<!--FIELDVALUE:email-->/$email/;
 $errorPage =~ s/<!--FIELDVALUE:repeatemail-->/$repeatemail/;
 $errorPage =~ s/<!--FIELDVALUE:institution-->/$institution/;
 $errorPage =~ s/<!--FIELDVALUE:department-->/$department/;
 $errorPage =~ s/<!--FIELDVALUE:address-->/$address/;
 $errorPage =~ s/<!--FIELDVALUE:phone-->/$phone/;
 $errorPage =~ s/<!--FIELDVALUE:Institution_type-->/$Institution_type/;
 $errorPage =~ s/<!--FIELDVALUE:Submit-->/$Submit/;

 $errorPage =~ s/<!--ERRORMSG:name-->/$FTGname_errmsg/;
 $errorPage =~ s/<!--ERRORMSG:email-->/$FTGemail_errmsg/;
 $errorPage =~ s/<!--ERRORMSG:repeatemail-->/$FTGrepeatemail_errmsg/;
 $errorPage =~ s/<!--ERRORMSG:institution-->/$FTGinstitution_errmsg/;
 $errorPage =~ s/<!--ERRORMSG:address-->/$FTGaddress_errmsg/;
 $errorPage =~ s/<!--ERRORMSG:Institution_type-->/$FTGInstitution_type_errmsg/;

 print "Content-type: text/html\n\n";
 print $errorPage;
 exit;

}


# Email to Form Owner

my $emailTo = '"curator" <curator@arabidopsis.org>';

my $emailFrom = $email;

my $emailSubject = "AraCyc Download License Request";

open(MAIL,"|$mailProg");
print MAIL "To: $emailTo\n";
print MAIL "From: $emailFrom\n";
print MAIL "Subject: $emailSubject\n";
print MAIL "Reply-To: $emailFrom\n";
print MAIL "Return-Path: $emailFrom\n";
print MAIL "MIME-Version: 1.0\n";
print MAIL "X-Sender: $emailFrom\n";
print MAIL "Content-Type: text/plain; charset=\"ISO-8859-1\"\n";
print MAIL "Content-Transfer-Encoding: quoted-printable\n";
print MAIL "\n";
print MAIL "The following person has agreed to the AraCyc Download License:\n"
 . "title: $title\n"
 . "name: $name\n"
 . "email: $email\n"
 . "repeatemail: $repeatemail\n"
 . "institution: $institution\n"
 . "department: $department\n"
 . "address: $address\n"
 . "phone: $phone\n"
 . "Institution_type: $Institution_type\n"
 . "Submit: $Submit\n"
 . "\n"
 . "";
print MAIL "\n";
close(MAIL);

# Confirmation Email to User

my $confEmailTo = $email;

my $confEmailFrom = 'no-reply@arabidopsis.org';

my $confEmailSubject = "AraCyc Database Download Request";

open(MAIL,"|$mailProg");
print MAIL "To: $confEmailTo\n";
print MAIL "From: $confEmailFrom\n";
print MAIL "Subject: $confEmailSubject\n";
print MAIL "MIME-Version: 1.0\n";
print MAIL "Content-Type: text/plain; charset=\"ISO-8859-1\"\n";
print MAIL "Content-Transfer-Encoding: quoted-printable\n";
print MAIL "\n";
print MAIL "$name,\n"
 . "\n"
 . "You have agreed to the AraCyc Database Download License. We will review your information and get back to you within one working day with instructions on how to get the download.\n"
 . "\n"
 . "AraCyc Team";
close(MAIL);

# Redirect user to success page

print "Location:/aracyc/success.html\n\n";
exit;

# End of Perl script
