#!/bin/env perl

use strict;

my $adb = shift;
my $history = shift;

main();

sub main
{
	my %hash;
	open(IN,"<$adb");
	while(my $line = <IN>)
	{
		chomp($line);
		$hash{$line}=1;
	}
	close(IN);
       	
	my %past;
	open(IN,"<$history");
        while(my $line = <IN>)
        {
                chomp($line);
		my ($name,$junk,$who,$type,$date) = split(/\t/,$line);
		if($who ne "MIPS")
		{
			push(@{$past{$name}},$line);
		}
	}
	close(IN);

	foreach my $key (keys %past)
	{
		my @a = @{$past{$key}};
		my @sorted=sort { my @a1=split (/\t/,$a); my @b1=split(/\t/,$b); if($a1[4] < $b1[4]) {return 1;} return 0;} @a;
		my ($name,$junk,$who,$type,$date) = split(/\t/,$sorted[0]);
		#if($type =~ /(obsoleted)|(not\s+in\s+use)/ && $hash{$name} == 1)
		#{
		#	print "MISMATCH: $name ".$sorted[0]."\n";
	#	}
		if($type !~ /(obsoleted)|(not\s+in\s+use)/ && !defined($hash{$name}))
		{
			print "SHOULD_BE_OBSOLETED: ".$sorted[0]."\n";
		}	
	}
	foreach my $key (keys %hash)
	{
		my @a = @{$past{$key}};
		my @sorted=sort { my @a1=split (/\t/,$a); my @b1=split(/\t/,$b); if($a1[4] < $b1[4]) {return 1;} return 0;} @a;
		my ($name,$junk,$who,$type,$date) = split(/\t/,$sorted[0]);
		if($type =~ /(obsoleted)|(not\s+in\s+use)/)
		{
			print "INCORRECT_OBSOLETION: $name ".$sorted[0]."\n";
		}
	}
			
}
		
	
