#!/bin/env perl  
use CGI qw(:all);
use DBI;
use lib '.';
use DBD::Oracle;

require 'cereon.pl';
use CereonServerConstants qw( $secureServer $webServer $dataPath $cereonMail $server $database $port $dbuser $dbpassword );



&getDate;


# after user fill the user name and password from cereon_register.pl or from cereon_login.pl
if (param('formName') eq "login") 
  {
    $username = param('username');	
    $password = param('password');
    
    my $dbh = DBI->connect("dbi:Oracle:host=$server;port=$port;sid=$database",$dbuser,$dbpassword,{AutoCommit=>1,RaiseError=>1});
    #$dbh = DBI->connect( "dbi:Sybase:server=$server;database=$database",
    #		  "$dbuser", "$dbpassword", 
    #                    {AutoCommit => 1, PrintError => 1} );
    die( "Couldn't connect to $server:$database" ) 
      if $dbh->err;

    $statement = "select password, snp_agreement from CereonUser where username='$username'";
    $sth = $dbh->prepare($statement);
    $sth->execute() || die print "$statement";

    while (@row = $sth->fetchrow_array) 
      { $truePassword = $row[0];
	$hasSignedAgreement =  $row[1];
      }


    # if user has right password and the field snp_agreement is true, show the data

    # if first character of password in db is '*', consider it to be inactive

    if ($username && $password && $truePassword eq $password &&
	(substr($truePassword, 0, 1) ne '*')){
      if ($hasSignedAgreement eq 'T')
	{ &showData($username, crypt $password, "ncgr" ); }

      # if user has right password and the field snp_agreement is not true, show the registration form
      else
	{&agreement($username, crypt $password, "ncgr" );}
    }
    # else show the error message
    else
      { &htmlError("Invalid Username or Password."); }

  }
else
  {
    if (param('formName') eq "showData"){
      $username = param('username');	
      $cryptPassword = param('passwd');
      &showData($username,  $cryptPassword );

    }
    elsif (param($formCrypt) eq $showCrypt)
      { &verify; }

    # entry page of this script
    else
      { &showLogin; }
  }

exit 0;
