#!/bin/env perl

#########################################################################
# Copyright: (c) 2003 National Center for Genome Resources (NCGR)
#            All Rights Reserved.
# $Revision: 1.1 $
# $Date: 2004/05/12 22:08:13 $
#
# $Log: RemoteCluster.pm,v $
# Revision 1.1  2004/05/12 22:08:13  nam
# Remove configuration module; add new RemoteCluster module to handle all communications with remote analysis cluster generically; migrate all properties formerly in Configuration module to RemoteCluster
#
#
# Functions for submitting jobs to analysis cluster using perl and
# the Blastpid linux cluster supplied socket utilities.
#
#########################################################################

package RemoteCluster;

use IO::Socket::INET;

use strict;

# Constants
my $NL = "\n";		# Always send newline after command.
my $EOF = chr( 1 );	# End of transmission marker.
my $EOFNL = $EOF . $NL;	# End of reception marker.


#
# Server wide configuration settings - these values will be different
# from environment to environment.
#

# Name of machine acting as main dispatcher for 
# all jobs run on cluster.
#my $dispatcherHost = "prodc1";
#we use a 3rd party load balancing app now (probably pen)
my $BALANCER_ADDRESS = "usa.tairgroup.org";
$BALANCER_ADDRESS = "netbatchpenloadbalancer.tairgroup.org";
$BALANCER_ADDRESS = "tairvm07.tacc.utexas.edu";

# Port to use when connecting to dispatcher machine
my $BALANCER_PORT = 26201;
# Protocol (i.e. tcp) use when connecting to cluster machines
my $BALANCER_PROTOCOL = "tcp";


#############################################################################
##
##  SUBROUTINE NAME
##    new()
##
##  SYNOPSIS 
##    new()
##
##  DESCRIPTION
##    Constructor
##
##  ARGUMENTS
##    none
##
##  RETURN VALUE
##    none
##
#############################################################################

sub new
{
    my $class = shift;
    my $self = {};
    bless( $self, ref( $class ) || $class );


    # Connect to selected server using peer port value specified above
    my $sock = IO::Socket::INET->new( PeerAddr => $BALANCER_ADDRESS,
                                   PeerPort => $BALANCER_PORT,
                                   Proto => $BALANCER_PROTOCOL ) 
    || die( "Cannot connect to queue $BALANCER_ADDRESS" );

    $self->{'socket'} = $sock;

    return $self;

} # new()


#############################################################################
##
##  SUBROUTINE NAME
##    DESTROY()
##
##  SYNOPSIS 
##    DESTROY( $self )
##
##  DESCRIPTION
##    Destructor
##
##  ARGUMENTS
##
##
##  RETURN VALUE
##    none
##
#############################################################################

sub DESTROY
{
    my $self = shift;
	if(defined($self->{'socket'}))
	{
    		$self->{'socket'}->DESTROY();
	}
}

#############################################################################
##
##  SUBROUTINE NAME
##    Submit()
##
##  SYNOPSIS 
##    $response = Submit( %args )
##
##  DESCRIPTION
##    Send a job to a remote server in the analysis cluster
##
##  ARGUMENTS
##    %args may contain values for the following keys:
##       priority - Priority to run job at. 0 = long queue; 1 = short queue.
##       command  - Command string to execute on remote server.  Should
##                  contain program name and any command line options
##
##       stdin    - Text to submit as STDIN to program (optional - some
##                  programs may not need to submit using STDIN
##
##  RETURN VALUE
##    $response
##
#############################################################################
sub Submit
{
    my ($self, %args ) = @_;

    my $priority = $args{ 'priority' };
    my $command = $args{ 'command' };
    my $stdin = $args{ 'stdin' };

    # Check for a valid priority
    if ( $priority < 0 || $priority > 1 )
    {
        die( "Invalid priority: $priority. Should be either 0 or 1." );
    }

    # Must submit a command to execute 
    if ( !$command ) {
        die( "Invalid command string submitted: $command" );
    }


    # Set up the job; the actual command run is of the form
    # 'command args <stdin >stdout 2>stderr' so you should
    # NOT put any redirection or anything unless you know
    # just what you are doing.
    my $sock = $self->{'socket'};


    $sock->print( "newjob $command" . $NL );

    # Server sends a confirmation line starting with "OK" if there is no
    # error -- it contains a job handle ($jobid) that we must use to
    # refer to the job later.
    my $response = $sock->getline;

    # Extract the jobid. "ERROR" will be returned if you garble the
    # server command.
    my ( $code, $junk, $junk2, $jobid ) = split( ' ', $response );

    $self->{'jobid'} = $jobid;

    # if $priority == 0, put it in the Long queue, meaning running
    # very long program executions
    if ( !$priority ) 
    {
        $sock->print( "jobqueue $jobid Long" . $NL );
        $response = $sock->getline;
    }

    # set stdin for command if any submitted
    if ( $stdin ) {
      $sock->print( "jobstdin $jobid".$NL );
      $sock->print( $stdin . $NL );
      $sock->print( $EOF );
    }

    # Tell the server to queue the job; check the confirmation sent
    # for an initial "OK"; bail if not.
    $sock->print( "runjob $jobid" . $NL );
    $response = $sock->getline;

    die( "Something wrong when submitting job: $response" ) 
        unless $response =~ "OK";

    return ( $response );

} # Submit()

#############################################################################
##
##  SUBROUTINE NAME
##    Status()
##
##  SYNOPSIS 
##    $response = Status()
##
##  DESCRIPTION
##    Now poll every second or so until the jobstate command returns something 
##    other than "PleaseRun" or "Running". For faster response, check response 
##    right before sleeping.
##
##  ARGUMENTS
##
##
##  RETURN VALUE
##    $response
##
#############################################################################

sub Status
{
    my $self = shift;
    my $sock = $self->{'socket'};
    my $jobid = $self->{'jobid'};

    $sock->print( "jobstate $jobid" . $NL );
    my $response = $sock->getline;

    return $response;
}

#############################################################################
##
##  SUBROUTINE NAME
##    Retrieve()
##
##  SYNOPSIS 
##    $output = Retrieve()
##
##  DESCRIPTION
##    Now read all the lines of the output from running the query and print 
##    them. Remember that we check for $EOFNL as an end of file marker.
##
##  ARGUMENTS
##
##
##  RETURN VALUE
##    $output
##
#############################################################################

sub Retrieve
{
    my $self = shift;
    my $sock = $self->{'socket'};
    my $jobid = $self->{'jobid'};


    $sock->print( "jobstdout $jobid" . $NL );

    my $output  = "";

    my $response = "junk";

    while ( $response ne $EOFNL ) {
      $response = $sock->getline;
      $output .= $response;
    }

    return $output;
}

#############################################################################
##
##  SUBROUTINE NAME
##    Statistics()
##
##  SYNOPSIS 
##    $statistics = Statistics()
##
##  DESCRIPTION
##
##
##  ARGUMENTS
##
##
##  RETURN VALUE
##    $statistics
##
#############################################################################

sub Statistics
{
    my $self = shift;
    my $sock = $self->{'socket'};
    my $jobid = $self->{'jobid'};

    # Before cleaning up, let's get the job statistics and print
    # them out.  Could be useful.  It is important to differentiate
    # the 'jobstatus' command used below from the 'jobstate' command
    # used in polling, above.

    # Please note that you may see surprising and/or missing values
    # in the 'jobstatus' output.  Don't take them too seriously yet.

    $sock->print( "jobstatus $jobid" . $NL );
    my $response = "junk";
    my $statistics = "";

    while ( $response ne $EOFNL ) 
    {
        $response = $sock->getline;
        $statistics .= $response;
    }

    return $statistics;
}

#############################################################################
##
##  SUBROUTINE NAME
##    ErrorLog()
##
##  SYNOPSIS 
##    $output = ErrorLog()
##
##  DESCRIPTION
##    Now read all the lines of the output from running the query and print 
##    them. Remember that we check for $EOFNL as an end of file marker.
##
##  RETURN VALUE
##    $output
##
#############################################################################

sub ErrorLog
{
    my $self = shift;
    my $sock = $self->{'socket'};
    my $jobid = $self->{'jobid'};

    $sock->print( "jobstderr $jobid" . $NL );

    my $output  = "";

    my $response = "junk";

    while ( $response ne $EOFNL ) 
    {
        $response = $sock->getline;
        $output .= $response;
    }

    return( $output );
}

#############################################################################
##
##  SUBROUTINE NAME
##    CleanUp()
##
##  SYNOPSIS 
##    CleanUp()
##
##  DESCRIPTION
##    Always clean up a job, whether successful, or errored out, or whatever.
##    The server does not clean up for you.  The primary reason for this is
##    leave debris around for debugging if something goes wrong and the job
##    is orphaned.
##
##  ARGUMENTS
##
##
##  RETURN VALUE
##    none
##
#############################################################################

sub CleanUp
{
    my $self = shift;
    my $sock = $self->{'socket'};
    my $jobid = $self->{'jobid'};


    $sock->print( "endjob $jobid" . $NL );
    my $response = $sock->getline;

    # Finally, close the network connection gracefully.

    $sock->print( "goodbye" . $NL );

    close( $sock );
}

1; # To signify successful initialization
