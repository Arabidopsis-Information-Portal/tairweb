#!/bin/env perl 

use CGI qw(:standard);

require 'cereon_seq.pl';


my @data;

&getDate;

$formName = param('formName');	


# User clicked "I agree" button
if ($formName eq "agreement") {
  $username = param('userName');
  $cryptPassword = param('password');

  # user not login
  if ($username eq ""){
    &registerForm;
  }
  # user already login
  else {
    &updateRegistedUserAgreement($username, $cryptPassword);
  }
}

# After user submit the registration form
elsif ($formName eq "approve") { &isMissing;}

# When user enter the agreement page
else { &agreement("", ""); }

exit 0;


