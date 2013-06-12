#!/bin/env perl
use strict;

process_files("/Data/apache_logs/2008/02/18"); 

my $megalist;


#open and get a list of the files
sub process_files {
    
    my $path = shift;

    opendir (DIR, $path) or die "$!";
   
    #take out . and .. files
    my @files = grep { !/^\.{1,2}$/ } readdir (DIR);
    closedir(DIR);
    
    @files = map { $path . '/' . $_ } @files;
    
    for (@files){
        if (-d $_){
            process_files($_);
        }else{
            if (($_ =~ m/access_log/) && ($_ !~ m/ssl_access_log/)) {
                
                print "now parsing" . $_ . "\n";
                #copy the configuration file to a temporary file
                #`cp tempconf.conf awstats.awstats_prod.conf`;
                
                #change the new configuration file to show Logfile = whatever we have
                #system "perl -pi -le 'print \"LogFile=\\\"$_\\\"\" if \$. == 1' awstats.awstats_prod.conf";
                
                #run the configuration on that particular log file
                #system "perl awstats.pl -config=awstats -update -month=ALL -year=2007 -logfile=\"".$_."\"";
                #system "perl awstats.pl -config=awstats -update -logfile=\"".$_."\"";
                system "perl awstats.pl -config=awstats_byday -update -databasebreak=day -logfile=\"".$_."\"";
            }
        }
    }
}


#system "perl -pi -le 'print \"LogFile=\\\"$megalist\\\"\" if \$. == 1' awstats.test2.conf";
