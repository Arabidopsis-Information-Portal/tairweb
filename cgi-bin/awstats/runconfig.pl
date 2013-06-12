#!/bin/env perl
use strict;
use DBI qw(:sql_types);

my $option = shift;
my $thisdir = shift;
my $logdir = shift;
my $tempdir = shift;
my $tempdir2 = shift;
my $dbh = DBI->connect("dbi:mysql:webstattest:germany","writer","w\$*t1#",{AutoCommit=>0});


#
# process yesterdays time
#
my $rightnow=time();
my ($today_sec, $today_min, $today_hour, $today_mday, $today_mon, $today_year, $today_wday, $today_yday, $today_isdst) = localtime($rightnow);
$rightnow -= (24 * 60 * 60);
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($rightnow);
$year = $year+1900;
$mon = $mon+1;
if ($mon<10){
    $mon = '0'.$mon;
}
$mday = $mday;
if ($mday<10){ 
    $mday = '0'.$mday;
}
chdir($thisdir);
#my $logfile = "$logdir/$year/$mon/$mday/access_log";
my $logfile = "$logdir/access_log-$year$mon$mday";

if ($option eq "PROCESS_FILES") { 
    process_files(); 
}else{
    process_db();
}
$dbh->disconnect();

#open and get a list of the files
sub process_files {
	
	#
    # run the configuration on that particular log file
	#
    #system "perl awstats.pl -config=awstats -update -month=ALL -year=$year -logfile=\"".$_."\"";
    print "perl awstats.pl -config=awstats -update -logfile=\"".$logfile."\" > monthout\n";
    system "perl awstats.pl -config=awstats -update -logfile=\"".$logfile."\" > monthout";
	print "perl awstats.pl -config=awstats_byday -update -databasebreak=day -logfile=\"".$logfile."\" > dayout";
	system "perl awstats.pl -config=awstats_byday -update -databasebreak=day -logfile=\"".$logfile."\" > dayout";
}

sub process_db
{
    #
    # delete awstats data 
    #
    
    #
    # if today is the 1st of the month, add in awstats data into the database, and then regenrate files
    #
    my $file = "$thisdir/../../../data/awstats/awstats$mon$year.awstats.txt";
    open (FILE, "<$file") or die "cant open $file";
    my @splitline;
    my $QUERY = "DELETE FROM Session where date_temp = '$year-$mon-01' AND date_type = 'month'";
    my $pre_sth = $dbh->prepare($QUERY);
    $pre_sth->execute() || die "couldnt execute $QUERY\n";

    while (my $line = <FILE>){
        print $line;
        if ($line =~ m/^From1/){
        @splitline = split(/\s/, $line);
        $QUERY = "INSERT INTO Session(analyzer_id, date_temp, statistics_type_id, aggregate_type_id, count, date_type)
        VALUES (2, '" . $year . "-" . $mon . "-01" . "', 4, 28, " . $splitline[2] . ",'month')";
        my $sth = $dbh->prepare($QUERY);
        $sth->execute() || die "couldn't execute $QUERY\n";

        $QUERY =  "INSERT INTO Session(analyzer_id, date_temp, statistics_type_id, aggregate_type_id, count, date_type)
        VALUES (2, '" . $year . "-" . $mon . "-01" . "', 4, 29, " . $splitline[1] . ",'month')";
        my $sth2 = $dbh->prepare($QUERY);
        $sth2->execute() || die "couldn't execute $QUERY\n";
           

        }elsif ($line =~ m/^TotalUnique/){
            @splitline = split(/\s/, $line);
            $QUERY = "INSERT INTO Session(analyzer_id, date_temp, statistics_type_id, aggregate_type_id, count, date_type)
            VALUES (2, '" . $year . "-" . $mon . "-01" . "', 4, 30, " . $splitline[1] . ",'month')";
            my $sth3 = $dbh->prepare($QUERY);
            $sth3->execute() || die "couldn't execute $QUERY\n";
            
        }
    }
        
    close(FILE);
        
    generate_year_stats();
    generate_month_stats(); 
}

sub generate_year_stats
{
    my $file = "executive";
    open (OUT, ">$tempdir/$file");
    open (OUT2, ">$tempdir2/$file");
    print OUT "---YEAR STATISTICS---\n";
    print OUT2 "---YEAR STATISTICS---\n";
    my $QUERY = "SELECT YEAR(s.date_temp) AS year, avg(s.count), at.aggregate_value, a.analyzer_name
    FROM Session s, Aggregate_Type at, Statistics_Type st, Analyzer a
    WHERE at.aggregate_type_id = s.aggregate_type_id AND at.aggregate_type_name = 'total'
    AND s.statistics_type_id = st.statistics_type_id AND st.statistics_type_name = 'Hits'
    AND s.analyzer_id = a.analyzer_id
    AND s.date_type = 'month'
    GROUP BY at.aggregate_value, year, a.analyzer_name";

    my $sth = $dbh->prepare($QUERY);
    $sth->execute() || die "couldnt execute $QUERY\n";
    my $rows = $sth->fetchall_arrayref();
    foreach my $row (@$rows){
    my ($year, $count, $ag_value, $an_name) = @$row;
        print OUT $ag_value . ":" . $year . ":" . $count . ":" . $an_name . "\n";
        print OUT2 $ag_value . ":" . $year . ":" . $count . ":" . $an_name . "\n";
    }
    close(OUT);
    close(OUT2);
}

sub generate_month_stats
{
    my $file = "yearly";
    open(OUT, ">$tempdir/$file");
    open(OUT2, ">$tempdir2/$file");
    print OUT "---MONTH STATISTICS---\n";
    print OUT2 "---MONTH STATISTICS---\n";
    my $QUERY = "SELECT MONTH(s.date_temp) AS month, YEAR(s.date_temp) AS year, avg(s.count), at.aggregate_value, a.analyzer_name 
    FROM Session s, Aggregate_Type at, Statistics_Type st, Analyzer a
    WHERE at.aggregate_type_id = s.aggregate_type_id AND at.aggregate_type_name = 'total' 
    AND s.statistics_type_id = st.statistics_type_id AND st.statistics_type_name = 'Hits'
    AND s.analyzer_id = a.analyzer_id
    AND s.date_type = 'month'
    GROUP BY at.aggregate_value, year, month, a.analyzer_name";
    my $sth = $dbh->prepare($QUERY);
    $sth->execute() || die "couldnt execute $QUERY\n";

    my $rows = $sth->fetchall_arrayref();
    foreach my $row (@$rows){
        my ($month, $year, $count, $ag_value, $an_name) = @$row;
        print OUT $ag_value . ":" . $year . ":" . $count . ":" . $month . ":" . $an_name . "\n";
        print OUT2 $ag_value . ":" . $year . ":" . $count . ":" . $month . ":" . $an_name . "\n";
    }

    close(OUT);
    close(OUT2);
}
