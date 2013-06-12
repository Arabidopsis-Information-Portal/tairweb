#!/bin/env perl


#
# Use the cluster blast to meet the seqviewer's need
#
# TO FIX:  Script executed by java and is executed by
# interpreter specified in #! line above - this is 
# environment dependent and must be hacked for each
# different setup
#
# Also, the use lib directive below needs to be set
# independently per environment
use strict;


use lib "/home/arabidopsis/cgi-bin/cluster";
use RemoteCluster;

my $ERRORLOG = "/home/arabidopsis/logs/cluster-error.log";

my ($inputFile,$outputFile);


if (@ARGV) {
  $inputFile = $ARGV[0];
  $outputFile = $ARGV[1];
}


blast($inputFile,$outputFile);

exit 0;

sub blast
  {

    my $sequenceFile = shift;
    my $blastOutFile = shift;



    my $startTime = time;       # see how long it takes in seconds 
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($startTime);
    my $thetime = sprintf ("%2d/%2d/%2d:%2d:%2d:%2d", $mday,$mon+1,$year+1900,$hour,$min,$sec);
    $thetime =~ s/ /0/g;

    my $program = "blastn";
    my $database = "arabidopsis.seq";

    # Set all BLAST options here for simplicity. Use all defaults
    # except for -F to disable low complexity filtering
    my $options = "-F F";

    my $sequence = "";

    open(SEQ, $sequenceFile) or die "Error! $0 could not open $sequenceFile.";
    while (<SEQ>) {
      $sequence .= $_;
    }
    close(SEQ);

    eval {
      # Create RemoteCluster instance to handle communication
      # with Analysis Farm
      my $server = RemoteCluster->new();

      # Create command string to execute on remote server
      my $command = "\$NCBIN/blastall -p $program -d \$NCREF/$database $options";

      my $priority = 1;

      # Create args hash to pass to server for execution
      # Query sequence must be submitted to remote job as STDIN.
      my %args = ( 'command' => $command,
		   'priority' => $priority,
		   'stdin' => $sequence );

      # Execute the Blast program on the Analysis Farm.
      my ( $response ) = $server->Submit( %args );

      $response = "Running";
      while ($response =~ "PleaseRun" || $response =~ "Running") {
	$response = $server->Status();
	sleep 1;
      }
      my ($my_result) = $server->Retrieve();
      $server->CleanUp();
      open (RESULT, ">$blastOutFile") or die "Can't create output file $blastOutFile: $!";
      print RESULT $my_result;
      close (RESULT);

    };

    if ($@) {
      print "$@\n";
      error2log("$thetime: $@");

    }
  }

sub error2log
  {
    my $text = shift;

    my $ERRORLOG = "error.log";

    open (LOG, ">>$ERRORLOG") or die "could not open $ERRORLOG\n";
    print LOG "$$: $text\n";
    close LOG;
  }

