#!/usr/bin/perl -w 

###############################################################################
#ORIGINAL INFO
###############################################################################

# rdiff_check.pl v0.03  #
#
# This is a plugin for nagios to check the status of an rdiff-backup repository.
# Written by Christian Marie from Solutions First
# email christian@solutionsfirst.com.au for support
#
# Licensed under the GNU GPLv2 which google will find a copy of
# for you. 
# 
#
# For nagios you would simply stick a similar command in checkcommands or services and go from there.
# You should check it works from the commandline first.

#############################################################################
#NEW INFO
#############################################################################

# rdiff_backup_stats.pl v0.1 #

# This is rewritten plugin for zabbix to check and collect statistics of
# an rdiff-backup repository.


use strict;
use File::stat;
use Getopt::Std;
use File::Basename;

sub usage();
sub running();
my @date;
my @mir_list;
my $repository;
my %opts=();
my $time_stamp;
my $no_mir;
my $stats_fn;
my $elapsed;
my $cur_mir;
my @hour;
my $pid_1;
my $pid_2;
my $size_now;
my $size_change;
my $debug;
#my $err = 0;
my $command = $ARGV[2];
my $result;

if($<)
{
	$debug .= "ERROR: Must run as root\n";
	print "0\n";
	exit(3);
}

usage if(!@ARGV);

if (!getopts( "r:w:c:l:p:s:e:", \%opts ))
{
  print "ERROR: getopts failed!";
  exit 1;
}

$repository = "$opts{r}/rdiff-backup-data";

if($command eq ""){
	print "ERROR: Invalid \"COMMAND\"\n";
	exit(6);
}

@mir_list = <$repository/current_mirror*>;
$no_mir = scalar @mir_list;


if($no_mir == 1)
{
	$cur_mir = <$repository/current_mirror*>;
	($time_stamp) = ($mir_list[0] =~ /current_mirror\.(.*)\.data$/);
	$stats_fn = "$repository/session_statistics.$time_stamp.data";

	if(!-f $stats_fn)
	{
		print "ERROR: No session statistics file, deleted?";
		exit(3);
	}
	
	#$elapsed = ((time() - $cron_cycle) - stat($cur_mir)->mtime);
	
	print "stats - starttime (cca) \n";
	print stat($cur_mir)->mtime;
	print "\n";
	
	if(!open(FILE, "< $stats_fn"))
	{
		$debug .= "ERROR: Could not open stat file\n";
		print "0\n";
		exit(3);
	}
	
	<FILE>;<FILE>;<FILE>;<FILE>;
	$size_now = <FILE>;
	($size_now) = $size_now =~ /SourceFileSize (.*) \(.*\)$/;
	
	$size_now = int($size_now /= 1048576);
	print "Total size...(in MB)\n";
	print $size_now;
	print "\n";

	<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;
	($size_change) = <FILE> =~ /TotalDestinationSizeChange (.*) \(.*\)$/;
	
	$size_change = int($size_change /= 1048576);
	print "Change size...(in MB)\n";
	print $size_change;
	print "\n";

	$elapsed = localtime(stat($stats_fn)->mtime);
	
	$debug .= "OK: Last backup finished ".$elapsed.". Size change ". $size_change." MB\n";
	$result = "1";
	
	if($command eq "status"){
	    print $result . "\n";
	}
	else{
	    print "ERROR: Unknown mode! \n";
	}
	
	if($opts{d}){
	    print $debug;
	}
	
	exit(0);
}

if($no_mir == 2)
{
	open(FILE,"< $mir_list[0]");
	$pid_1 = <FILE>;
	
	if(!defined $pid_1)
	{
		print "CRITICAL: Really broken repository\n";
		exit(3);
	}
	
	chomp($pid_1);
	($pid_1) = ($pid_1 =~ /PID (.*)$/);
   
	open(FILE,"< $mir_list[1]");
	$pid_2 = <FILE>;
	chomp($pid_2);
	($pid_2) = ($pid_2 =~ /PID (.*)$/);
	
	if(!defined $pid_2)
	{
		print "CRITICAL: Really broken repository\n";
		exit(2);
	}

	if(-f "/proc/$pid_1/cmdline")
	{
		if(!open(FILE, "< /proc/$pid_1/cmdline"))
		{
			print "ERROR: Couldn't open cmdline file, permissions?\n";
			exit(3);
		}
		$pid_1 = <FILE>;
		running() if ($pid_1 =~ /rdiff-backup/);
	}
	
	if(-f "/proc/$pid_2/cmdline")
	{
		if(!open(FILE, "< /proc/$pid_2/cmdline"))
		{
			print "ERROR: Couldn't open cmdline file, permissions?\n";
			exit(3);
		}
		$pid_2 = <FILE>;
		running() if ($pid_2 =~ /rdiff-backup/);
	}
	
	print "CRITICAL: Backup interrupted";
	exit(2);
}

$debug .= "ERROR: Neither one current mirror, nor two";
print "0\n";
exit(3);

sub running()
{
	$cur_mir = <$repository/current_mirror*>;
	($time_stamp) = ($mir_list[0] =~ /current_mirror\.(.*)\.data$/);
	$stats_fn = "$repository/session_statistics.$time_stamp.data";
#	$elapsed = ((time() - $cron_cycle) - stat($stats_fn)->mtime);
#	if($elapsed > 0)
#	{
#		@hour = localtime(time());
#		if($hour[2] >= $c_thresh)
#		{
#			print "CRITICAL: Backup still running after $c_thresh:00\n";
#			exit(2);
#		}
#		if($hour[2] >= $w_thresh)
#		{
#			print "WARNING: Backup running after $w_thresh:00\n";
#			exit(1);
#		}
#	}
	
	print "OK: Backup in progress\n";
	exit(0);
}

sub usage()
{
	print "Usage: rdiff_backup_stats.pl [OPTIONS] [COMMAND]\n
      OPTIONS:
	-r <rdiff repository>
	-d <debug>\n
      COMMAND:
	status <status of backup>
	ct <change size>
	ts <total size"
	.">\n";
	exit(3);
}
