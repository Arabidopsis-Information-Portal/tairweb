#!/bin/env perl 

$ENV{'ORACLE_HOME'}='/opt/oracle/11.2.0/client';
#$ENV{'LD_LIBRARY_PATH'} = $ENV{'ORACLE_HOME'} . '/lib:' . $ENV{'LD_LIBRARY_PATH'};

use CGI qw(:standard);
#$ENV{'ORACLE_HOME'}='/Data/oracle/client';
use DBI;
use DBD::Oracle;

require '../format_tairNew.pl';

# module defines env. specific values for https/http URLs, data location
# and cereon/monsanto email address to send registration notifications to
use CereonServerConstants qw( $secureServer $webServer $dataPath $cereonMail $server $database $port $dbuser $dbpassword);

my $dbh = DBI->connect("dbi:Oracle:host=$server;port=$port;sid=$database",$dbuser,$dbpassword,{AutoCommit=>1,RaiseError=>1});
die( "Couldn't connect to $server:$database" ) if $dbh->err;
$dbh->do("alter session set nls_date_format=\'MM/DD/YYYY HH24:MI:SS\'");

$registerCgiPath = "/cgi-bin/cereon/cereon_seq_register.pl";
$cgiPath = "/cgi-bin/cereon/cereon_seq_login.pl";

$mailprog = '/usr/lib/sendmail';

$emailFrom = 'tairweb@arabidopsis.org';


$formCrypt = crypt "formName", "ncgr";
$showCrypt = crypt "showMe", "ncgr";
$chromCrypt = crypt "chromosome", "ncgr";

$verifyCrypt = crypt "verify", "ncgr";
$userCrypt = crypt "username", "ncgr";
$pwdCrypt = crypt "password", "ncgr";
$fillibuster = crypt "absolutelyuseless", "ncgr";
$fvalue = crypt "uselessvalue","ncgr";
$timestamp = crypt "timestamp", "cgnr";




##########################################################################################
##########################################################################################

sub showData 
  {

    my ($username, $cryptPassword) = @_;


    $temp = time;

    $now = $temp . "X" . int(rand 1000000);

    print header;

    $title = "Monsanto Arabidopsis Landsberg Sequence";

    print "<HTML><head><TITLE>$title</TITLE>";


    &tair_header();

    print &page_title("$title");

    print << "print_header";

<style type="text/css">
<!--
td	{font-family:helvetica,arial,sans-serif; font-size: 10pt;}
.title {font-size:16pt;font-weight:bold;}
.small {font-size:9pt;}
//-->
</style>


<table width=600 border=0 cellpadding=0 cellspacing=0 align=center>

<tr>
<td colspan=2>
<hr>
<br>

<P>The polymorphisms are detected by comparing the Columbia BAC
sequences produced by the AGI with the sequence from Monsanto's whole
genome shotgun of the Landsberg erecta ecotype.  Quality values are
used to distinguish true SNPs from sequencing errors.  Differences
caused by insertions and deletions are detected as gaps in aligned
sequences.  Due to their nature, the insertion-deletion predictions
have a higher rate of false positives unrelated to the quality of
sequence.  Validation rates measured by resequencing were close to
100% for SNPs and approximatey 70% for predicted insertion-deletion
polymorphisms. <!-- ending ' so that editors do not freak out -->
</p>

<P>For Questions about the data, please email: <a href="mailto:jeff.woessner\@monsanto.com">jeff.woessner\@monsanto.com</a>

<P>
The data can be downloaded as a fasta formated text file or in compressed zip file:
</p>
<P><b>Release 1 </b>
<P><b>Sequence file with fasta format </b>
<a href="$cgiPath?$fillibuster=$fvalue&$timestamp=$now&$formCrypt=$showCrypt&$verifyCrypt=$verifyCrypt&$userCrypt=$username&$chromCrypt=$allCrypt&$pwdCrypt=$cryptPassword&type=fasta"><b>Full file (95 Mb)</b></a>
<P>
<b>Compressed Files (.zip)</b> 
<a href="$cgiPath?$fillibuster=$fvalue&$timestamp=$now&$formCrypt=$showCrypt&$verifyCrypt=$verifyCrypt&$userCrypt=$username&$chromCrypt=$allCrypt&$pwdCrypt=$cryptPassword&type=zip"><b>Full file (29 Mb compressed)</b></a>
<P>
<b>BLAST service </b> 
<a href="$webServer/Blast/cereon.jsp"><b>BLAST against the Landsberg Sequence</b></a>
<br><br>


</td>
</tr>
<tr>
<td colspan=2 align=center>
<P>
<hr>

<a href="$webServer/Cereon/index.jsp"> <b>Return to Monsanto SNP and Sequence Entry Page</b></a>
</td></tr>
</table>

print_header

  &tair_footer;
	
    exit 0;
  }

##########################################################################################
##########################################################################################

sub showLogin 
  {
    print header;


    $title = "Monsanto Arabidopsis Landsberg Sequence - Login";

    print "<HTML><head><TITLE>$title</TITLE>";

    &tair_header();

    print &page_title("$title");

    print << "print_header";

<style type="text/css">
<!--
td	{font-family:helvetica,arial,sans-serif; font-size: 10pt;}
.title {font-size:16pt;font-weight:bold;}
.small {font-size:9pt;}
//-->
</style>

<table width=600 border=0 cellpadding=0 cellspacing=0 align=center>


<tr>
<td colspan=2>
<hr>
<br>
<form action="$cgiPath" method="post">
Please fill out the following login information:<br><br>
<table width=400 border=0 cellpadding=2 cellspacing=0 align=center>
<tr>
<td width=100><b>User name:</b></td>
<td><input type="text" name="username" size="15"></td>
</tr>
<tr>
<td width=100><b>Password:</b></td>
<td><input type="password" name="password" size="15"></td>
</tr>
<tr>
<td width=100></td>
<td><input type="hidden" name="formName" value="login">
<input type="submit" value=" SUBMIT ">
</td>
</tr>
</table>
</form>
</td>
</tr>
<tr><td>If you have problems with logging in, please contact us at: <A href="mailto:informatics\@arabidopsis.org">informatics\@arabidopsis.org</A></td></tr>

<tr>
<td colspan=2 align=center>
<P>
<hr> 
<a href="$webServer/Cereon/index.jsp"> <b>Return to Monsanto SNP and Sequence Entry Page</b></a>

</td></tr>
</table>
print_header

  &tair_footer;

    exit 0;
  }

##########################################################################################
##########################################################################################

sub verify 
  {
    if (param($verifyCrypt) eq $verifyCrypt) 
      {
	$username = param($userCrypt);	
	$password = param($pwdCrypt);
    
	#$dbh = DBI->connect( "dbi:Sybase:server=$server;database=$database", 
	#		     $dbuser, $dbpassword,
	#		     {AutoCommit => 1, PrintError => 1} );
	#die "Couldn't connect to $server:$database" if $dbh->err;
    
	$statement = "select password from CereonUser where " .
	  "username='$username'";
	$sth = $dbh->prepare($statement);
	$sth->execute() || die print "$statement";
	while (@row = $sth->fetchrow_array) 
	  { $truePassword = crypt $row[0], "ncgr"; }
	if ($username && $password && $truePassword eq $password) 
	  { &getData; }
	else 
	  { &htmlError("Invalid Username or Password!"); }
      }
    else 
      { &htmlError("Invalid Access to Monsanto Data, please login again"); }
  }

##########################################################################################
##########################################################################################

sub getData 
  {
    $field = "Cereon_Ath_Ler.";

    $field .= param('type');
  

    ### do the logging ##################
    $urltime = int(param($timestamp));
    $now = time;
    if (($now - $urltime) <= 600) 
      {
	&getDate;
	#$dbh = DBI->connect( "dbi:Sybase:server=$server;database=$database", 
	#		     $dbuser, $dbpassword,
	#		     {AutoCommit => 1, PrintError => 1} );
	#die "Couldn't connect to $server:$database" if $dbh->err;
	$name = "CereonLog_id,CereonUser,IP_address,IP_host,filename,last_login";
	$value = "'$username','" . $ENV{'REMOTE_HOST'} . "','" . 
	  $ENV{'REMOTE_ADDR'} . "','$field','$today'";
	$cmd = "insert into CereonLog ($name) values (CEREONLOG_CEREONLOG_ID_SEQ.nextval,$value)";
	$insert = $dbh->do("$cmd") or die print "$cmd\n";
      
	#if (param('type') eq "txt" or param('type') eq "README")     
	#if (param('type') eq "fasta" or param('type') eq "README") 
	 # { print "content-type: text/plain\n"; }
	#else 
	 # { print "content-type: application/zip\n"; }
	print "content-type: application/zip\n";
	print "content-disposition: attachment; filename=\"$field\"\n\n";
	open (READONLY,"<$dataPath$field") || die "Could not open $field\n";
	while (<READONLY>) 
	  { print $_; }
	close READONLY;
      }
    else 
      { 
	print header;
	
	$myTitle = "Monsanto Arabidopsis Landsberg Sequence";
	
	print "<HTML><head><TITLE>$myTitle</TITLE>";
	
	&tair_header();
	
	print &page_title("$myTitle");

	print << "print_header";

This URL has expired.  Please click <a href="$cgiPath">here</a> to login again.
print_header
  &tair_footer;
      }

    exit 0;
  }



#################################################################################################
#################################################################################################

sub registerForm {

	my (@isEmpty) = @data;
	my $emailErr;
	my $missing = 0;

	$ltype = $ftype = $etype = $otype = $ptype = $qtype = $atype = "normal";
	if (@isEmpty) {
	    $last_name=$isEmpty[0]; 
	    if ( !$last_name || $last_name eq "" ) { 
		$ltype = "missing"; 
		$missing++;
	    }
	    
	    $first_name=$isEmpty[1]; 
	    if ( !$first_name || $first_name eq "" ) { 
		$ftype = "missing"; 
		$missing++;
	    }
	    
	    $email=$isEmpty[2]; 
	    if ( !$email || $email eq "" ) { 
		$etype = "missing"; 
		$missing++;

	    } elsif ( !(validEmail( $email ) ) ) {
		$etype = "missing"; 
		$emailErr = "Invalid email address: $email<br>";
	    }
	    
	    $piName=$isEmpty[3]; 
	    if ( !$piName || $piName eq "" ) { 
		$ptype = "missing"; 
		$missing++;
	    }
	    
	    $piEmail=$isEmpty[4]; 
	    if ( !$piEmail || $piEmail eq "" ) { 
		$qtype = "missing"; 
		$missing++;
	    } elsif ( !(validEmail( $piEmail ) ) ) {
		$qtype = "missing"; 
		$emailErr .= "Invalid email address: $piEmail";
	    }
	    
	    $org=$isEmpty[5]; 
	    if ( !$org || $org eq "" ) { 
		$otype = "missing"; 
		$missing++;
	    }
	    
	    $address=$isEmpty[6]; 
	    if ( !$address || $address eq "" ) {
		$atype = "missing"; 
		$missing++;
	    }
	}
	
	print header;

	
	$myTitle = "Monsanto Arabidopsis User Registration Form";
	
	print "<HTML><head><TITLE>$myTitle</TITLE>";
	
	&tair_header();
	
	print &page_title("$myTitle");

print << "ENDOFBLOCK";

<style type="text/css">
<!--
td	{font-family:helvetica,arial,sans-serif; font-size: 10pt;}
.title {font-size:16pt;font-weight:bold;}
.small {font-size:10pt;}
.normal {font-weight:bold;}
.missing {font-weight:bold; color:#cc0000;}
//-->
</style>

<table width=600 border=0 cellpadding=0 cellspacing=0 align=center>
<tr>
<td valign=top>
<span class="title">MONSANTO ARABIDOPSIS LANDSBERG SEQUENCE REGISTRATION
</span>
</td>
</tr>
<tr>
<td colspan=2>
<hr>
<br>
<form action="$registerCgiPath" method="post">
This page allows you to register to the Monsanto Arabidopsis Landsberg Sequence.
<P>
ENDOFBLOCK



if (@isEmpty) {
    if ( $emailErr && $emailErr ne "" ) {
	print "<span class=\"missing\">$emailErr</span><br>"; 
    }

    if ( $missing > 0 ) {
	print "<span class=\"missing\">You are missing required information for one or more fields:</span><br>\n";
    }

    print "<br>";
}
else 
{
	print "Please fill out the following information:<br><br>\n";
}

print << "ENDOFBLOCK";
<table width=500 border=0 cellpadding=2 cellspacing=0 align=center>
<tr>
<td colspan=2>* - optional information<br><br></td>
</tr>
<tr>
<td width=175><span class="$ftype">First Name:</span></td>
<td width=325><input type="text" name="first_name" value="$first_name" size="20"></td>
</tr>
<tr>
<td width=175><span class="$ltype">Last Name:</span></td>
<td width=325><input type="text" name="last_name" value="$last_name" size="20"></td>
</tr>
<tr>
<td><span class="$etype">Email:</span></td>
<td><input type="text" name="email" value="$email" size="20"></td>
</tr>
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
</tr>
<tr>
<td>* Job title:</td>
<td><input type="text" name="title" value="$title" size="20"></td>
</tr>
<tr>
<td>* Phone Number:</td>
<td><input type="text" name="phone" value="$phone" size="20"></td>
</tr>
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
</tr>
<tr>
<td valign=top><span class="$ptype">Principal Investigator (PI):</span></td>
<td><input type="text" name="piName" value="$piName" size="35"></td>
</tr>
<tr>
<td><span class="$qtype">Email of PI:</span></td>
<td><input type="text" name="piEmail" value="$piEmail" size="35"></td>
</tr>
<tr>
<td valign=top><span class="$otype">Name of Institution:</span></td>
<td><input type="text" name="org" value="$org" size="35"></td>
</tr>
<tr>
<td valign=top><span class="$atype">Address:</span></td>
<td><textarea name="address" rows=3 cols=30>$address</textarea></td>
</tr>
<tr>
<td><b>Country:</b></td>
<td><select name="country">
<option>Afghanistan
<option>Albania
<option>Algeria
<option>American Samoa
<option>Andorra
<option>Angola
<option>Anguilla
<option>Antarctica
<option>Antigua And Barbuda
<option>Argentina
<option>Armenia
<option>Aruba
<option>Australia
<option>Austria
<option>Azerbaijan
<option>Bahamas, The
<option>Bahrain
<option>Bangladesh
<option>Barbados
<option>Belarus
<option>Belgium
<option>Belize
<option>Benin
<option>Bermuda
<option>Bhutan
<option>Bolivia
<option>Bosnia and Herzegovina
<option>Botswana
<option>Bouvet Island
<option>Brazil
<option>British Indian Ocean Territory
<option>Brunei
<option>Bulgaria
<option>Burkina Faso
<option>Burundi
<option>Cambodia
<option>Cameroon
<option>Canada
<option>Cape Verde
<option>Cayman Islands
<option>Central African Republic
<option>Chad
<option>Chile
<option>China
<option>China (Hong Kong S.A.R.)
<option>Christmas Island
<option>Cocos (Keeling) Islands
<option>Colombia
<option>Comoros
<option>Congo
<option>Cook Islands
<option>Costa Rica
<option>Cote D'Ivoire (Ivory Coast)
<option>Croatia (Hrvatska)
<option>Cuba
<option>Cyprus
<option>Czech Republic
<option>Denmark
<option>Djibouti
<option>Dominica
<option>Dominican Republic
<option>East Timor
<option>Ecuador
<option>Egypt
<option>El Salvador
<option>Equatorial Guinea
<option>Eritrea
<option>Estonia
<option>Ethiopia
<option>Falkland Islands
<option>Faroe Islands
<option>Fiji Islands
<option>Finland
<option>France
<option>French Guiana
<option>French Polynesia
<option>Gabon
<option>Gambia, The
<option>Georgia
<option>Germany
<option>Ghana
<option>Gibraltar
<option>Greece
<option>Greenland
<option>Grenada
<option>Guadeloupe
<option>Guam
<option>Guatemala
<option>Guinea
<option>Guinea-Bissau
<option>Guyana
<option>Haiti
<option>Heard and McDonald Islands
<option>Honduras
<option>Hungary
<option>Iceland
<option>India
<option>Indonesia
<option>Iran
<option>Iraq
<option>Ireland
<option>Israel
<option>Italy
<option>Jamaica
<option>Japan
<option>Jordan
<option>Kazakhstan
<option>Kenya
<option>Kiribati
<option>Korea
<option>Kuwait
<option>Kyrgyzstan
<optionLaos
<option>Latvia
<option>Lebanon
<option>Lesotho
<option>Liberia
<option>Libya
<option>Liechtenstein
<option>Lithuania
<option>Luxembourg
<option>Macao
<option>Macedonia
<option>Madagascar
<option>Malawi
<option>Malaysia
<option>Maldives
<option>Mali
<option>Malta
<option>Marshall Islands
<option>Martinique
<option>Mauritania
<option>Mauritius
<option>Mayotte
<option>Mexico
<option>Micronesia
<option>Moldova
<option>Monaco
<option>Mongolia
<option>Montserrat
<option>Morocco
<option>Mozambique
<option>Myanmar
<option>Namibia
<option>Nauru
<option>Nepal
<option>Netherlands Antilles
<option>Netherlands, The
<option>New Caledonia
<option>New Zealand
<option>Nicaragua
<option>Niger
<option>Nigeria
<option>Niue
<option>Norfolk Island
<option>North Korea
<option>Northern Mariana Islands
<option>Norway
<option>Oman
<option>Pakistan
<option>Palau
<option>Panama
<option>Papua new Guinea
<option>Paraguay
<option>Peru
<option>Philippines
<option>Pitcairn Island
<option>Poland
<option>Portugal
<option>Puerto Rico
<option>Qatar
<option>Reunion
<option>Romania
<option>Russia
<option>Rwanda
<option>Samoa
<option>San Marino
<option>Sao Tome and Principe
<option>Saudi Arabia
<option>Senegal
<option>Seychelles
<option>Sierra Leone
<option>Singapore
<option>Slovakia
<option>Slovenia
<option>Solomon Islands
<option>Somalia
<option>South Africa
<option>Spain
<option>Sri Lanka
<option>Sudan
<option>Suriname
<option>Svalbard And Jan Mayen Islands
<option>Swaziland
<option>Sweden
<option>Switzerland
<option>Syria
<option>Taiwan
<option>Tajikistan
<option>Tanzania
<option>Thailand
<option>Togo
<option>Tokelau
<option>Tonga
<option>Trinidad And Tobago
<option>Tunisia
<option>Turkey
<option>Turkmenistan
<option>Turks And Caicos Islands
<option>Tuvalu
<option>Uganda
<option>Ukraine
<option>United Arab Emirates
<option>United Kingdom
<option selected>United States
<option>United States Minor Outlying Islands
<option >Uruguay
<option>Uzbekistan
<option>Vanuatu
<option>Vatican City State (Holy See)
<option>Venezuela
<option>Vietnam
<option>Virgin Islands (British)
<option>Virgin Islands (US)
<option>Wallis And Futuna Islands
<option>Western Sahara
<option>Yemen
<option>Yugoslavia
<option>Zambia
<option>Zimbabwe
</select>
</td>
</tr>
<tr>
<td colspan=2 align=center><br>
<input type="hidden" name="formName" value="approve">
<input type="submit" value=" SUBMIT ">
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td colspan=2 align=center>
<br>
<hr>
<br>

<a href="$webServer/Cereon/index.jsp"><b>Return to Monsanto SNP and Sequence Entry Page</b></a>

</td></tr>
</table>

ENDOFBLOCK
&tair_footer;

exit 0;
}



sub agreement {

my ($username, $cryptPassword) = @_;

#my $cryptPassword = crypt  $password, "ncgr";

print header;

$title = "Monsanto Arabidopsis Landsber Sequence Registration";

print "<HTML><head><TITLE>$title</TITLE>";
	
&tair_header();

print &page_title("$title");

print << "ENDOFBLOCK";

<style type="text/css">
<!--
td	{font-family:helvetica,arial,sans-serif; font-size: 10pt;}
.title {font-size:16pt;font-weight:bold;}
.small {font-size:10pt;}
//-->
</style>


<form action="$registerCgiPath" method="post">
<table width=600 border=0 cellpadding=0 cellspacing=0 align=center>
<tr>
<td valign=top>
<span class="title">MONSANTO ARABIDOPSIS LANDSBERG SEQUENCE<br>
REGISTRATION AGREEMENT</span>
<br>
</td>
</tr>
<tr>
<td colspan=2>
<hr>
<br>
When you click on the<b> 'I Agree'</b> button, you will be required to fill out your and your PI's contact information. We will notify you, your PI, and Monsanto of the agreement by e-mail at which time you may download a paper copy for your file.  You are responsible for obtaining your institution's approval prior to accepting this agreement.
<br><br>
<b>TERMS OF ACCESS AGREEMENT TO MONSANTO ARABIDOPSIS LANDSBERG SEQUENCE</b>
<P>
       
<P>
<span class="small">
<dl>
<dt><b>1.	&nbsp;&nbsp;&nbsp;ACKNOWLEDGMENT AND ACCEPTANCE OF TERMS</b></dt>
<br>
<dd>Access to the Monsanto Arabidopsis Landsberg Sequence contained in the files accessible from this Website (the "Monsanto Information") is provided to you under the terms and conditions of this Terms of Access Agreement ("Agreement") and any operating rules or policies that may be published by Monsanto Company (together with its respective affiliates and subsidiaries, "Monsanto").  This Agreement comprises the entire agreement between you and Monsanto regarding access to the Monsanto Information and supersedes all prior agreements between the parties regarding the subject matter contained herein.  BY COMPLETING THE REGISTRATION PROCESS AND CLICKING THE "I AGREE" BUTTON, YOU ARE INDICATING YOUR AGREEMENT TO BE BOUND BY ALL OF THE TERMS AND CONDITIONS OF THIS AGREEMENT.</dd>
</dl>
<dl>
<dt><b>2.	&nbsp;&nbsp;&nbsp;	ACCESS LIMITED TO NON-PROFIT OR EDUCATIONAL INSTITUTIONS</b></dt>
<dd>
Access to the Monsanto Information is limited to
    <dl>
      <dt><dd>(i) non-profit institutions, and</dt></dd>
	 <dt><dd>(ii) universities and colleges (collectively "Institution"). </dt></dd></dl>
	 By accepting this Agreement, you represent that you are (i) an Institution or (ii) an employee, officer or agent of an Institution acting in your capacity as such employee, officer or agent.</dd>
</dl>
<dl>
<dt>

<b>3.	&nbsp;&nbsp;&nbsp;	LICENSE GRANT AND LIMITATIONS</b></dt>
<dd>
Subject to the limitations set forth below, Monsanto grants to you a personal, royalty free, non-transferable (except to the extent necessary to comply with 37 CFR 401.14), non-exclusive license to:
    <P>
   * Download one copy of the Monsanto Information to a personal computer owned and/or operated by you or to a personal, non-shared location on a shared server; and
 <P> 
  * Access and use the Monsanto Information from any terminal, wireless device, workstation and computer which is a part of your network.

 <P>YOU ARE LICENSED TO USE THE MONSANTO INFORMATION FOR NONCOMMERCIAL RESEARCH PURPOSES (WHICH SHALL INCLUDE FEDERALLY FUNDED RESEARCH THAT IS GOVERNED BY 37 CFR 401.14) ONLY. YOU AGREE NOT TO MAKE ANY COMMERCIAL USE OF THE MONSANTO INFORMATION WITHOUT THE EXPRESS WRITTEN CONSENT OF MONSANTO <a href="$registerCgiPath#foot">(See Footnote)</a>. EXCEPT AS PROVIDED FOR HEREIN, YOU AGREE THAT THE MONSANTO INFORMATION WILL NOT BE USED IN RESEARCH THAT IS SUBJECT TO CONSULTING, LICENSING OR OTHER CONTRACTUAL RIGHTS OF OR OBLIGATIONS TO ANY THIRD PARTY, OTHER THAN AN INSTITUTION WHICH IS BOUND BY A TERMS OF ACCESS AGREEMENT WITH MONSANTO. Except as expressly set forth in this Agreement, you agree not to otherwise use, copy, disseminate or permit access to the Monsanto Information, or any portion thereof, in any form or medium.</dd>
</dl>
<dl>
<dt>

<b>4.	&nbsp;&nbsp;&nbsp;	NO TRANSFER OR SUBLICENSE</b></dt>
<dd>
This license is personal and you agree not to sell, transfer, assign, sublicense or otherwise transfer this Agreement or the Monsanto Information, or any copy or portion thereof, to any other person, except as may be required by law or court order.</dd>
</dl>
<dl><dt>

<b>5.	&nbsp;&nbsp;&nbsp;	OWNERSHIP</b></dt>
<dd>
The Monsanto Information contains proprietary information belonging to Monsanto and certain other third parties. As licensee, you own the media on which the Monsanto Information is recorded, but not the Monsanto Information itself.  Monsanto retains all title and ownership to the Monsanto Information recorded on the media and all copyright and other intellectual property rights therein.  This license is not a sale of the Monsanto Information or any copy. </dd>
</dl>
<dl><dt>

<b>6.	&nbsp;&nbsp;&nbsp;	PUBLICATION; CONFIDENTIAL INFORMATION</b></dt>
<dd>
You are free to publish, in any form, any research results from use of the Monsanto Information provided that such a publication will not result in publication of all or a substantial portion of the Monsanto Information.    Published sequence information should be limited to disclosure of no more than 250 kilobases per publication.  If you desire to publish more than 250 kilobases of the Monsanto Information in a single publication, please e-mail your request to Athal\@monsanto.com.  Any such publication shall make reference to Monsanto Company.  You agree to maintain the Monsanto Information in confidence under the terms of this limited license and not to disclose the Monsanto Information to any other person except for that portion that is part of any such publication.</dd>
</dl>
<dl><dt>

<b>7.	&nbsp;&nbsp;&nbsp;	INFORMATION</b></dt>
<dd>
That while you are under no obligation to do so, you understand that Monsanto is very interested in developments regarding the Monsanto Information and in hearing about any new information or discoveries resulting from the use of the Monsanto Information.  Please send an e-mail to Athal\@monsanto.com regarding non-confidential information any such information or discoveries.   Please note that we assume no responsibility for reviewing unsolicited ideas for our business.  Also, please remember that you are responsible for whatever material you submit, and that you, and not Monsanto, have full responsibility for the message, including its reliability, originality and copyright.  Please do not reveal trade secrets or other confidential information in your messages.</dd>
</dl>
<dl><dt>

<b>8.	&nbsp;&nbsp;&nbsp;PROPRIETARY NOTICES</b></dt>
<dd>
You agree not to alter, remove, or obscure any copyright notices or other proprietary notices on and in the Monsanto Information. You agree to include on and in any copies of the Monsanto Information the same proprietary notices and other legends contained on and in the Monsanto Information as furnished to you by Monsanto.</dd>
</dl>
<dl><dt>

<b>9.	&nbsp;&nbsp;&nbsp;GOVERNING LAW</b></dt>
<dd>
This Agreement shall be construed in accordance with and governed by the
laws of the State of Missouri, U.S.A., excluding its choice of law rules.</dd>
</dl>
<dl><dt>

<b>10.	&nbsp;&nbsp;&nbsp;	LIMITATION OF LIABILITY</b></dt>
<dd>
You understand that Monsanto Company provides no guarantees whatsoever with respect to the accuracy of the Monsanto Information and that you and your Institution will not assert any claims against Monsanto Company which arise as a result of your use of the Monsanto Information.  For other important terms, including further limitations on liability, <a href="$webServer/Cereon/liability.jsp"><b>click here</b></a>.</dd>
</dl>
<b><a name="foot">Footnote</b></a> This restriction should be interpreted that the Monsanto information should not be used in a commercial setting (i.e., selling parts of the database for profit, for instance.) It is not a restriction on any results gained from the use of the Monsanto Information (for instance, if research using the Monsanto information results in discovering a gene, the restriction does not apply to the gene).
<P>
</span>
</td>
</tr>
<tr>
<td colspan=2 align=center>
<input type="submit" value=" I AGREE ">       
<P>
<hr>

<a href="$webServer/Cereon/index.jsp"><b>Return to Monsanto SNP and Sequence Entry Page</b></a>

<input type="hidden" name="formName" value="agreement">
<input type="hidden" name="userName" value="$username">
<input type="hidden" name="password" value="$cryptPassword">

</td></tr>
</table>
</form>


ENDOFBLOCK

&tair_footer;

exit 0;
}


sub validate {
    my @required = ("last_name","first_name","email","piName","piEmail","org","address");
    my $errors = 0;

    for ( $i = 0; $i < scalar( @required ); $i++ ) 
    {
	if ( param( $required[ $i ] ) && param( $required[ $i ] ) ne ""  ) 
	{
	    $data[$i] = param( $required[ $i ] );
	}
	else { 
	    $errors++; 
	}
	
    }
    
    if ( $data[ 2 ] && !( validEmail( $data[ 2 ] ) ) ) {
	$errors++;
    }

    if ( $data[ 4 ] && !( validEmail( $data[ 4 ] ) ) ) {
	$errors++;
    }

    return $errors;
    
}

#################################################################################################
### after user click the agreement SUBMIT button
#################################################################################################

sub isMissing 
{
  if ( (validate()) > 0 ) 
    { 
	registerForm(); 
    }
  else 
    {
	    #$dbh = DBI->connect( "dbi:Sybase:server=$server;database=$database", 
	    #	   "$dbuser", "$dbpassword", 
	    #		   {AutoCommit => 1, PrintError => 1} );
	    #die( "Couldn't connect to $server:$database" ) 
	    #if $dbh->err;
		
      $username = lc ((substr param('last_name'), 0, 6).(substr param('first_name'),0,2));
      $tempname = $username;
      $salt=1;
      while (!$flag) 
	{
	  $statement = "select last_name, first_name, email from CereonUser where username='$tempname'";
	  $sth = $dbh->prepare($statement);	
	  $sth->execute() or print "Could not execute $statement\n";
	  while (@row = $sth->fetchrow_array) 
	    { 
	      $lastname = $row[0]; 
	      $firstname = $row[1]; 
	      $email = $row[2];
	    }
	  if ($firstname) 
	    { 
	      $tempname = (substr $username, 0, 7).$salt++; 
	      if ($salt > 999) 
		{ $flag=1; }
	    }
	  else 
	    { $flag = 1; }
	  $firstname = "";
	}
		
      &getDate;
      $username = $tempname;
      $pString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
      $password = "";
      for ($i=0;$i<8;$i++) 
	{ $password .= substr $pString, int(rand 63), 1; }
		
      print header;

      ## need to update the ler_agreement too at here

      $name = "CEREONUSER_ID,last_name,first_name,username,password,email,phone,title,pi_name,pi_email,org_name,address,country,last_modified, ler_agreement"; ## change

      $newLastName = param('last_name');
      $newFirstName = param('first_name');
      $newEmail = param('email');
      $newPhone = param('phone');
      $newTitle = param('title');
      $newPiName = param('piName');
      $newPiEmail = param('piEmail');
      $newOrg = param('org');
      $newAddress = param('address');
      $newCountry = param('country');

      $value = "\'$newLastName\',\'$newFirstName\',\'$username\',\'$password\',";
      $value .= "\'$newEmail\',".(length($newPhone) > 0?"\'$newPhone\',":"NULL,").(length($newTitle) > 0?"\'$newTitle\',":"NULL,")."\'$newPiName\',";
      $value .= "\'$newPiEmail\',\'$newOrg\',\'$newAddress\',\'$newCountry\',\'$today\',\'T\'";

      $cmd = "insert into CereonUser ($name) values (CEREONUSER_CEREONUSER_ID_SEQ.nextval,$value)";
      $insert = $dbh->do("$cmd") or die print "$cmd\n";



      open (MAIL, "|$mailprog $cereonMail") || die "Can't open $mailprog!\n";

      print MAIL "From: $emailFrom\n";
      print MAIL "To: $cereonMail\n";

      print MAIL "Subject: User Registration Information";
      print MAIL "\n";
      print MAIL "\nThe following person has registered for the Monsanto data:\n\n";

      print MAIL "Name: $newFirstName $newLastName\n";
      print MAIL "Email: $newEmail\n";
      print MAIL "Phone #: $newPhone\n";
      print MAIL "Title: $newTitle\n";
      print MAIL "PI name: $newPiName\n";
      print MAIL "PI email: $newPiEmail\n";
      print MAIL "Org Name: $newOrg\n";
      print MAIL "Address: $newAddress\n";
      print MAIL "Country: $newCountry\n";
      print MAIL "\n";

      close MAIL;

      $count = 0;
      foreach $email ($newEmail, $newPiEmail) 
	{
	  open (MAIL, "|$mailprog $email") || die "Can't open $mailprog!\n";

	  print MAIL "From: $emailFrom\n";
	  print MAIL "To: $email\n";

	  print MAIL "Subject: Welcome to the Monsanto Arabidopsis Landsberg Sequence";
	  print MAIL "\n";

	  if ($count == 0) 
	  {
	      print MAIL "Thank you for registering with us.\n\n";
	      print MAIL "Notice: Access to Monsanto Information is limited to non-profit or\n";
	      print MAIL "educational institutions for use in noncommercial research only.\n";
	      print MAIL "Please be aware that any disclosure, copying or use of the contents of\n";
	      print MAIL "Monsanto Information by a commercial entity is prohibited. Monsanto will\n";
	      print MAIL "pursue all legal and equitable remedies for any improper use of this\n";
	      print MAIL "database, including recovery of any damages or obtaining other remedies\n";
	      print MAIL "available to Monsanto. If you are coming from the for-profit sector and\n";
	      print MAIL "want access to the data, you must contact Monsanto Company directly at:\n";
	      print MAIL "jeff.woessner\@monsanto.com \n\n";
	      print MAIL "Your username and password are:\n\n";
	      print MAIL "\tusername:\t$username\n";
	      print MAIL "\tpassword:\t$password\n";
	      $count++;
	  }
	  else 
	  {
	      print MAIL "$newFirstName $newLastName in your lab has registered with us to get access to Monsanto Arabidopsis Landsberg Sequence and agreed to the following terms.\n\n";
	  }

	  print MAIL "\n\n";
	  print MAIL << "print_header";

If you have any questions or problems, please contact Monsanto Company at: jeff.woessner\@monsanto.com
	      
By registering with us, you have agreed to the jeff.woessnerfollowing terms with Monsanto Company:

TERMS OF ACCESS AGREEMENT TO MONSANTO ARABIDOPSIS LANDSBERG SEQUENCE 

1.    ACKNOWLEDGMENT AND ACCEPTANCE OF TERMS 
Access to the Monsanto Arabidopsis Landsberg Sequence contained in the files accessible from this Website (the "Monsanto Information") is provided to you under the terms and conditions of this Terms of Access Agreement ("Agreement") and any operating rules or policies that may be published by Monsanto Company (together with its respective affiliates and subsidiaries, "Monsanto"). This Agreement comprises the entire agreement between you and Monsanto regarding access to the Monsanto Information and supersedes all prior agreements between the parties regarding the subject matter contained herein. BY COMPLETING THE REGISTRATION PROCESS AND CLICKING THE "I AAGREE" BUTTON, YOU ARE INDICATING YOUR AGREEMENT TO BE BOUND BY ALL OF THE TERMS AND CONDITIONS OF THIS AGREEMENT. 

2.     ACCESS LIMITED TO NON-PROFIT OR EDUCATIONAL INSTITUTIONS 
Access to the Monsanto Information is limited to 
(i) non-profit institutions, and 
(ii) universities and colleges (collectively "Institution"). 
By accepting this Agreement, you represent that you are (i) an Institution or (ii) an employee, officer or agent of an Institution acting in your capacity as such employee, officer or agent.
 
3.     LICENSE GRANT AND LIMITATIONS 
Subject to the limitations set forth below, Monsanto grants to you a personal, royalty free, non-transferable (except to the extent necessary to comply with 37 CFR 401.14), non-exclusive license to:
* Download one copy of the Monsanto Information to a personal computer owned and/or operated by you or to a personal, non-shared location on a shared server; and 

* Access and use the Monsanto Information from any terminal, wireless device, workstation and computer which is a part of your network. 

YOU ARE LICENSED TO USE THE MONSANTO INFORMATION FOR NONCOMMERCIAL RESEARCH PURPOSES (WHICH SHALL INCLUDE FEDERALLY FUNDED RESEARCH THAT IS GOVERNED BY 37 CFR 401.14) ONLY. YOU AGREE NOT TO MAKE ANY COMMERCIAL USE OF THE MONSANTO INFORMATION WITHOUT THE EXPRESS WRITTEN CONSENT OF MONSANTO. See Footnote  EXCEPT AS PROVIDED FOR HEREIN, YOU AGREE THAT THE MONSANTO INFORMATION WILL NOT BE USED IN RESEARCH THAT IS SUBJECT TO CONSULTING, LICENSING OR OTHER CONTRACTUAL RIGHTS OF OR OBLIGATIONS TO ANY THIRD PARTY, OTHER THAN AN INSTITUTION WHICH IS BOUND BY A TERMS OF ACCESS AGREEMENT WITH MONSANTO. Except as expressly set forth in this Agreement, you agree not to otherwise use, copy, disseminate or permit access to the Monsanto Information, or any portion thereof, in any form or medium.

4.     NO TRANSFER OR SUBLICENSE 
This license is personal and you agree not to sell, transfer, assign, sublicense or otherwise transfer this Agreement or the Monsanto Information, or any copy or portion thereof, to any other person, except as may be required by law or court order. 

5.     OWNERSHIP 
The Monsanto Information contains proprietary information belonging to Monsanto and certain other third parties. As licensee, you own the media on which the Monsanto Information is recorded, but not the Monsanto Information itself. Monsanto retains all title and ownership to the Monsanto Information recorded on the media and all copyright and other intellectual property rights therein. This license is not a sale of the Monsanto Information or any copy. 

6.     PUBLICATION; CONFIDENTIAL INFORMATION 
You are free to publish, in any form, any research results from use of the Monsanto Information provided that such a publication will not result in publication of all or a substantial portion of the Monsanto Information. Published sequence information should be limited to disclosure of no more than 250 kilobases per publication.  If you desire to publish more than 250 kilobases of the Monsanto Information in a single publication, please e-mail your request to Athal\@monsanto.com. Any such publication shall make reference to Monsanto Company. You agree to maintain the Monsanto Information in confidence under the terms of this limited license and not to disclose the Monsanto Information to any other person except for that portion that is part of any such publication. 

7.     INFORMATION 
That while you are under no obligation to do so, you understand that Monsanto is very interested in developments regarding the Monsanto Information and in hearing about any new information or discoveries resulting from the use of the Monsanto Information. Please send an e-mail to Athal\@monsanto.com regarding any such information or discoveries. Please note that we assume no responsibility for reviewing unsolicited ideas for our business. Also, please remember that you are responsible for whatever material you submit, and that you, and not Monsanto, have full responsibility for the message, including its reliability, originality and copyright. Please do not reveal trade secrets or other confidential information in your messages. 

8.    PROPRIETARY NOTICES 
You agree not to alter, remove, or obscure any copyright notices or other proprietary notices on and in the Monsanto Information. You agree to include on and in any copies of the Monsanto Information the same proprietary notices and other legends contained on and in the Monsanto Information as furnished to you by Monsanto. 

9.    GOVERNING LAW 
This Agreement shall be construed in accordance with and governed by the laws of the State of Missouri, U.S.A., excluding its choice of law rules. 

10.     LIMITATION OF LIABILITY 
You understand that Monsanto Company provide no guarantees whatsoever with respect to the accuracy of the Monsanto Information and that you and your Institution will not assert any claims against Monsanto Company which arise as a result of your use of the Monsanto Information. For other important terms, including further limitations on liability, click {here}. 
Footnote This restriction should be interpreted that the Monsanto information should not be used in a commercial setting (i.e., selling parts of the database for profit, for instance.) It is not a restriction on any results gained from the use of the Monsanto Information (for instance, if research using the Monsanto information results in discovering a gene, the restriction does not apply to the gene). 
print_header

  close MAIL;
}

#print header;

$title = "Monsanto Arabidopsis Landsberg Sequence - Welcome";

print "<HTML><head><TITLE>$title</TITLE>";

&tair_header();

print &page_title("$title");

print << "print_tag";


<style type="text/css">
<!--
td     {font-family:helvetica,arial,sans-serif; font-size: 10pt;}
.title {font-size:16pt;font-weight:bold;}
.small {font-size:10pt;}
//-->
</style>
  
<table width=600 border=0 cellpadding=0 cellspacing=0 align=center>
<tr>
<td valign=top>
<span class="title">MONSANTO ARABIDOPSIS LANDSBERG SEQUENCE LOGIN</span>
</td>
</tr>
<tr>
<td colspan=2>
<hr>
<br>
<form action="$cgiPath" method="post">
Your registration was successful and your username and password have been sent to:<br>
<table width=400 border=0 cellpadding=2 cellspacing=0 align=center>
<tr><td width=100><b>$newEmail</b></td></tr>
</table>
<br><br>
Please use your username and password to access the Monsanto Arabidopsis data:<br><br>
<table width=400 border=0 cellpadding=2 cellspacing=0 align=center>
<tr>
<td width=100><b>User name:</b></td>
<td><input type="text" name="username" size="15"></td>
</tr>
<tr>
<td width=100><b>Password:</b></td>
<td><input type="password" name="password" size="15"></td>
</tr>
<tr>
<td width=100></td>
<td><input type="submit" value=" SUBMIT ">
<input type="hidden" name="formName" value="login">
</td>
</tr>
</table>
</form>
</td>
</tr>
<tr>
<td colspan=2 align=center>
<P>
<hr>

<a href="$webServer/Cereon/index.jsp"> <b>Return to Monsanto SNP and Sequence Entry Page</b></a>

</td></tr>
</table>

print_tag

  &tair_footer;
		
       exit 0;

}
    

  }
# end sub
#}


#################################################################################################
# Update Registered (SNP) User's ler_agreement field and send the email to the user
#

sub updateRegistedUserAgreement 
{

  my ($username, $cryptPassword) = @_;

  # $dbh = DBI->connect( "dbi:Sybase:server=$server;database=$database", 
#		       "$dbuser", "$dbpassword", 
#		       {AutoCommit => 1, PrintError => 1} );
#  die( "Couldn't connect to $server:$database" ) 
#    if $dbh->err;
  

  ## need to update the ler_agreement too at here
  $statement = "UPDATE CereonUser SET ler_agreement = 'T' WHERE username='$username'";
  $sth = $dbh->prepare($statement);	
  $sth->execute() or print "Could not execute $statement\n";

  $statement = "SELECT last_name, first_name, email, pi_email FROM CereonUser WHERE username='$username'";
  $sth = $dbh->prepare($statement);	
  $sth->execute() or print "Could not execute $statement\n";
  while (@row = $sth->fetchrow_array) 
    {
      $lastname = $row[0]; 
      $firstname = $row[1]; 
      $email = $row[2];
      $pi_email = $row[3];
    }

		
  &getDate;

  print header;

  open (MAIL, "|$mailprog $cereonMail") || die "Can't open $mailprog!\n";

  print MAIL "From: $emailFrom\n";
  print MAIL "To: $cereonMail\n";

  print MAIL "Subject: User Registration Information";
  print MAIL "\n";
  print MAIL "\nThe following person has registered for the Monsanto data:\n\n";
  print MAIL "Name: $firstname $lastname\n";

  print MAIL "Who has registered before, signed the ler agreement:\n";
  print MAIL "\n";

  close MAIL;

  $count = 0;
  foreach $email ($email, $pi_email)

    {
      open (MAIL, "|$mailprog $email") || die "Can't open $mailprog!\n";

      print MAIL "From: $emailFrom\n";
      print MAIL "To: $email\n";

      print MAIL "Subject: Welcome to the Monsanto Arabidopsis Landsberg Sequence";
      print MAIL "\n";

      if ($count == 0) 
	{
	  print MAIL "Thank you for registering with us.\n\n";
	  print MAIL "Notice: Access to Monsanto Information is limited to non-profit or\n";
	  print MAIL "educational institutions for use in noncommercial research only.\n";
	  print MAIL "Please be aware that any disclosure, copying or use of the contents of\n";
	  print MAIL "Monsanto Information by a commercial entity is prohibited. Monsanto will\n";
	  print MAIL "pursue all legal and equitable remedies for any improper use of this\n";
	  print MAIL "database, including recovery of any damages or obtaining other remedies\n";
	  print MAIL "available to Monsanto. If you are coming from the for-profit sector and\n";
	  print MAIL "want access to the data, you must contact Monsanto Company directly at:\n";
	  print MAIL "jeff.woessner\@monsanto.com \n\n";
	  $count++;
	}
      else
	{
	  print MAIL "$firstname $lastname in your lab has registered with us to get access to Monsanto Arabidopsis Landsberg Sequence and agreed to the following terms.\n\n";
	}

      print MAIL "\n\n";
      print MAIL << "print_header";
      
If you have any questions or problems, please contact Monsanto Company at: jeff.woessner\@monsanto.com
  
By registering with us, you have agreed to the following terms with Monsanto Company:

TERMS OF ACCESS AGREEMENT TO MONSANTO ARABIDOPSIS LANDSBERG SEQUENCE 

1.    ACKNOWLEDGMENT AND ACCEPTANCE OF TERMS 
Access to the Monsanto Arabidopsis Landsberg Sequence contained in the files accessible from this Website (the "Monsanto Information") is provided to you under the terms and conditions of this Terms of Access Agreement ("Agreement") and any operating rules or policies that may be published by Monsanto Company (together with its respective affiliates and subsidiaries, "Monsanto"). This Agreement comprises the entire agreement between you and Monsanto regarding access to the Monsanto Information and supersedes all prior agreements between the parties regarding the subject matter contained herein. BY COMPLETING THE REGISTRATION PROCESS AND CLICKING THE "I AAGREE" BUTTON, YOU ARE INDICATING YOUR AGREEMENT TO BE BOUND BY ALL OF THE TERMS AND CONDITIONS OF THIS AGREEMENT. 

2.     ACCESS LIMITED TO NON-PROFIT OR EDUCATIONAL INSTITUTIONS 
Access to the Monsanto Information is limited to 
(i) non-profit institutions, and 
(ii) universities and colleges (collectively "Institution"). 
By accepting this Agreement, you represent that you are (i) an Institution or (ii) an employee, officer or agent of an Institution acting in your capacity as such employee, officer or agent. 

3.     LICENSE GRANT AND LIMITATIONS 
Subject to the limitations set forth below, Monsanto grants to you a personal, royalty free, non-transferable (except to the extent necessary to comply with 37 CFR 401.14), non-exclusive license to:
* Download one copy of the Monsanto Information to a personal computer owned and/or operated by you or to a personal, non-shared location on a shared server; and 

* Access and use the Monsanto Information from any terminal, wireless device, workstation and computer which is a part of your network. 

YOU ARE LICENSED TO USE THE MONSANTO INFORMATION FOR NONCOMMERCIAL RESEARCH PURPOSES (WHICH SHALL INCLUDE FEDERALLY FUNDED RESEARCH THAT IS GOVERNED BY 37 CFR 401.14) ONLY. YOU AGREE NOT TO MAKE ANY COMMERCIAL USE OF THE MONSANTO INFORMATION WITHOUT THE EXPRESS WRITTEN CONSENT OF MONSANTO. See Footnote  EXCEPT AS PROVIDED FOR HEREIN, YOU AGREE THAT THE MONSANTO INFORMATION WILL NOT BE USED IN RESEARCH THAT IS SUBJECT TO CONSULTING, LICENSING OR OTHER CONTRACTUAL RIGHTS OF OR OBLIGATIONS TO ANY THIRD PARTY, OTHER THAN AN INSTITUTION WHICH IS BOUND BY A TERMS OF ACCESS AGREEMENT WITH MONSANTO. Except as expressly set forth in this Agreement, you agree not to otherwise use, copy, disseminate or permit access to the Monsanto Information, or any portion thereof, in any form or medium.

4.     NO TRANSFER OR SUBLICENSE 
This license is personal and you agree not to sell, transfer, assign, sublicense or otherwise transfer this Agreement or the Monsanto Information, or any copy or portion thereof, to any other person, except as may be required by law or court order. 

5.     OWNERSHIP 
The Monsanto Information contains proprietary information belonging to Monsanto and certain other third parties. As licensee, you own the media on which the Monsanto Information is recorded, but not the Monsanto Information itself. Monsanto retains all title and ownership to the Monsanto Information recorded on the media and all copyright and other intellectual property rights therein. This license is not a sale of the Monsanto Information or any copy. 

6.     PUBLICATION; CONFIDENTIAL INFORMATION 
You are free to publish, in any form, any research results from use of the Monsanto Information provided that such a publication will not result in publication of all or a substantial portion of the Monsanto Information. Published sequence information should be limited to disclosure of no more than 250 kilobases per publication.  If you desire to publish more than 250 kilobases of the Monsanto Information in a single publication, please e-mail your request to Athal\@monsanto.com. Any such publication shall make reference to Monsanto Company. You agree to maintain the Monsanto Information in confidence under the terms of this limited license and not to disclose the Monsanto Information to any other person except for that portion that is part of any such publication. 

7.     INFORMATION 
That while you are under no obligation to do so, you understand that Monsanto is very interested in developments regarding the Monsanto Information and in hearing about any new information or discoveries resulting from the use of the Monsanto Information. Please send an e-mail to Athal\@monsanto.com regarding any such information or discoveries. Please note that we assume no responsibility for reviewing unsolicited ideas for our business. Also, please remember that you are responsible for whatever material you submit, and that you, and not Monsanto, have full responsibility for the message, including its reliability, originality and copyright. Please do not reveal trade secrets or other confidential information in your messages. 

8.    PROPRIETARY NOTICES 
You agree not to alter, remove, or obscure any copyright notices or other proprietary notices on and in the Monsanto Information. You agree to include on and in any copies of the Monsanto Information the same proprietary notices and other legends contained on and in the Monsanto Information as furnished to you by Monsanto. 

9.    GOVERNING LAW 
This Agreement shall be construed in accordance with and governed by the laws of the State of Missouri, U.S.A., excluding its choice of law rules. 

10.     LIMITATION OF LIABILITY 
You understand that Monsanto Company provides no guarantees whatsoever with respect to the accuracy of the Monsanto Information and that you and your Institution will not assert any claims against Monsanto Company which arise as a result of your use of the Monsanto Information. For other important terms, including further limitations on liability, click {here}. 
Footnote This restriction should be interpreted that the Monsanto information should not be used in a commercial setting (i.e., selling parts of the database for profit, for instance.) It is not a restriction on any results gained from the use of the Monsanto Information (for instance, if research using the Monsanto information results in discovering a gene, the restriction does not apply to the gene).  
print_header

  close MAIL;
}

$title = "Monsanto Arabidopsis Landsberg Sequence - Welcome";

print "<HTML><head><TITLE>$title</TITLE>";
	
&tair_header();

print &page_title("$title");

print << "print_tag";


<style type="text/css">
<!--
td	{font-family:helvetica,arial,sans-serif; font-size: 10pt;}
.title {font-size:16pt;font-weight:bold;}
.small {font-size:10pt;}
//-->
</style>

<table width=600 border=0 cellpadding=0 cellspacing=0 align=center>
<tr>

<td valign=top>
<span class="title">MONSANTO ARABIDOPSIS LANDSBERG SEQUENCE LOGIN</span>
</td>
</tr>
<tr>
<td colspan=2>
<hr>
<br>
<form action="$cgiPath" method="post">
<!--
Your registration was successful and your username and password have been sent to:<br>

<table width=400 border=0 cellpadding=2 cellspacing=0 align=center>
<tr><td width=100><b>$email</b></td></tr>

</table>
<br><br>
-->

You can now access the Monsanto Arabidopsis data:<br><br>
<table width=400 border=0 cellpadding=2 cellspacing=0 align=center>
<tr>
<td width=100><b>
<input type="submit" value=" CONTINUE ">
<input type="hidden" name="formName" value="showData">
<input type="hidden" name="username" value="$username">
<input type="hidden" name="passwd" value="$cryptPassword">

</td>
</tr>
</table>

</form>
</td>
</tr>
<tr>
<td colspan=2 align=center>
<P>
<hr>

<a href="$webServer/Cereon/index.jsp"> <b>Return to Monsanto SNP and Sequence Entry Page</b></a>

</td></tr>
</table>
</body> 
</html>
print_tag
  &tair_footer;
		
    exit 0;
}
# end sub
#}

#################################################################################################

sub htmlError {
print header;
print << "print_tag";
<HTML>
<HEAD>
<TITLE>Error</TITLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF">
<H2> Error: @_ </H2>
<p>
<hr>
<p>
<I><A HREF = javascript:history.back(-1)>Back</a></I>
</BODY>
</HTML>
print_tag
exit 0;
}


#################################################################################################

sub getDate {

	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdist) = localtime(time);
	$year+=1900;
	$mon++;
	$today = "$mon/$mday/$year";
	$now = "$hour:$min:$sec";

}


#################################################################################################

sub validEmail {
    my $email = @_[ 0 ];
    my $returnCode = 1;

    # invalidate if address has any junk characters
    my @invalidChars = ( " ", "/", "\\", ";", ":", "," );
    foreach my $char ( @invalidChars ) {
      if ( index( $email, $char ) >= 0 ) {
	  $returnCode = 0;
      }
    }

    # if no @ sign in address
    my $atPos = index( $email, "@" );
    if ( $atPos == -1 ) {
      $returnCode = 0;
    }

    # if more than 1 @ sign in address
    if ( index( $email, "@", $atPos + 1 ) != -1 ) {
	$returnCode = 0;
    }

    # if no dot in address
    my $periodPos = index( $email, ".", $atPos );
    if ( $periodPos == -1 ) {
	$returnCode = 0;
    }
    
    # if there aren't at least 2 characters after dot
    if ( $periodPos + 3 > length( $email ) ) {
	$returnCode = 0;
    }
	
    return $returnCode;
}
