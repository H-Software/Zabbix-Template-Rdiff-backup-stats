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
my $w_thresh;
my $c_thresh;
my $s_thresh;
my $t_thresh;
my $l_thresh;
my $cron_cycle;
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
my $script;
my $err = 0;
#r=repository
#p=cron cylce;
#w=warning threshold
#c=critical threshold
#l=changed size too large
#t=hour of day becomes critical
#h=bool help
#s=low sourcesize critical

if($<)
{
	print "ERROR: Must run as root\n";
	exit(3);
}

usage if(!@ARGV);

if (!getopts( "r:w:c:l:p:s:e:", \%opts ))
{
  print "ERROR: getopts failed!";
  exit 1;
}

#getopts( "r:w:c:l:p:s:e:", \%opts ) or usage();
#
#for(qw{r w c l p})
#{	
#	if(!exists $opts{$_})
#	{
#		print "Arguement -$_ is not optional\n";
#		$err = 1;
#	}
#}

#if($err)
#{
#	print "\n";
#	usage ();
#}

$repository = "$opts{r}/rdiff-backup-data";
$w_thresh = $opts{w};
$c_thresh = $opts{c};
#$l_thresh = $opts{l} * 1048576;
$t_thresh = $opts{t};
#$cron_cycle = $opts{p} * 3600;
#$script = $opts{e};

if(!-d$repository)
{
	print "Invalid repository directory\n";
	exit(3);
}

#if(defined $script)
#{
#	if(system($script) != 0)
#	{
#		print "CRITICAL: $script exited abnormally\n";
#		exit(2);
#	}
#}

$s_thresh = $opts{s} * 1048576 if(defined($opts{s}));
$s_thresh = 1048576 if(!defined($opts{s}));

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
	
#	if($elapsed > 20)
#	{
#		if ($elapsed < 3600)
#		{
#			printf("CRITICAL: Backup failed to run (%.1f minutes overdue) Last backup: %s\n",
#		  	$elapsed / 60,
#			scalar(localtime(stat($stats_fn)->mtime)));
#		}
#		else
#		{
#			printf("CRITICAL: Backup failed to run (%.1f hours overdue) Last backup: %s\n",
#		  	$elapsed / 3600,
#			scalar(localtime(stat($stats_fn)->mtime)));
#		}		
#		exit(2);
#	}
	
	if(!open(FILE, "< $stats_fn"))
	{
		print "ERROR: Could not open stat file\n";
		exit(3);
	}
	
	<FILE>;<FILE>;<FILE>;<FILE>;
	$size_now = <FILE>;
	($size_now) = $size_now =~ /SourceFileSize (.*) \(.*\)$/;
	
	$size_now = int($size_now /= 1048576);
	print "Total size...(in MB)\n";
	print $size_now;
	print "\n";
	
	#if($size_now <= $s_thresh)
	#{
	#	$s_thresh /= 1048576;
	#	print "CRITICAL: Source repository size dropped under $s_thresh megabyte(s)\n";
	#	exit(2);			
	#}
	
	<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;<FILE>;
	($size_change) = <FILE> =~ /TotalDestinationSizeChange (.*) \(.*\)$/;
	
	$size_change = int($size_change /= 1048576);
	print "Change size...(in MB)\n";
	print $size_change;
	print "\n";
	
	#if($size_change >= $l_thresh)
	#{
	#	$size_change /= 1048576;
	#	printf("WARNING: Transferred more than threshold(%dMB)\n", $size_change);
	#	exit(1);
	#}
	$elapsed = localtime(stat($stats_fn)->mtime);
	printf("OK: Last backup finished %s. Size change %d MB\n", $elapsed, $size_change);
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

print "ERROR: Neither one current mirror, nor two";
exit(3);

sub running()
{
	$cur_mir = <$repository/current_mirror*>;
	($time_stamp) = ($mir_list[0] =~ /current_mirror\.(.*)\.data$/);
	$stats_fn = "$repository/session_statistics.$time_stamp.data";
	$elapsed = ((time() - $cron_cycle) - stat($stats_fn)->mtime);
	if($elapsed > 0)
	{
		@hour = localtime(time());
		if($hour[2] >= $c_thresh)
		{
			print "CRITICAL: Backup still running after $c_thresh:00\n";
			exit(2);
		}
		if($hour[2] >= $w_thresh)
		{
			print "WARNING: Backup running after $w_thresh:00\n";
			exit(1);
		}
	}
	
	print "OK: Backup in progress\n";
	exit(0);
}

sub usage()
{
	print "Usage: rdiff_backup_stats.pl [OPTIONS]\n
	-r <rdiff repository>
	-w <time warning threshold>
	-c <time critical threshold>
	-l <transferred warning threshold>
	-p <cron period>\n
	-s <optional small size threshold>
	-e <optional script to execute>\n";
	exit(3);
}


