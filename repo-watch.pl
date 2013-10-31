#!/usr/bin/perl
#  automatically watch for updates to the current branch, and push them 
#  using the update-working.pl script to your working directory 
#  copy the script to the directory containing your repo: cp $0 ../ 
#  and run it from there.
#  this could go horribly wrong :)
#  but if you're brave run like so: # nohup $0 -p <reponame>

use Getopt::Std;
use Cwd;
use IO::Socket;
use File::Basename;
# first, parse options
getopts('dG:l:p:');
our $prefix=cwd();

if ( defined $opt_p ) { chomp (our $project=$opt_p); } 
  else { our $project="learninggit"; }

if ( defined $opt_G ) { chomp ( our $gituser=$opt_G); } 
  else { our $gituser="thastjustprime"; }

if ( defined $opt_l ) { chomp ( our $logfile=$opt_l); } 
  else { our $logfile="/var/log/repowatch.log"; }

if ( defined $opt_d ) { our $debug = "yes"; }

# basic git variables
our $origin="origin/master";
our $master="master";
our $git="/usr/bin/git";
our $logfile="/var/log/repowatch.log";
our $gitrev="rev-parse";
our $gitwho="--format=%cn";
our $gitwhen="--format=%ct";
our $gitwhat="diff --name-status";
our $gitsub="--format=%s";

# strip non-alphanumeric characters from project name
our $project =~ s/[^A-Za-z0-9\-]//gi; 
our $url="git@\github.com\:$gituser/$project";
our $gitremote="ls-remote $url -h HEAD";
$debug && print "[$project] $url\n"; 

chdir "$prefix/$project" || die "cannot cd to $prefix/$project: $!\n";
our $pwd=cwd();

&timestamp;
our $mrev=&getrevs("$master");
our $orev=&getrem("$origin");
open (LOGFILE,">>$logfile") || die "Cannot append to $logfile: $!\n";
$debug && print LOGFILE "$time : [$project] monitoring repo $project from $pwd, updating $wdir on change\n";

# check the repo every 10 seconds!
while (1) { &checkrepo; sleep 10; }

exit 0;

sub getrem {
  my $what=shift;
  chomp ( my $tmp = `$git $gitremote |cut -f1` ) || warn "problem fetching $origin: $!\n";;
  $debug && print LOGFILE "$time : [$project] $what: $tmp\n";
  return "$tmp";
}

sub getrevs {
  my $what=shift;
  chomp ( my $tmp=`$git $gitrev $what` );
  $debug && print LOGFILE "$time : [$project] $what: $tmp\n";
  return "$tmp";
}

sub checkrepo {
  &timestamp;
  $orev=&getrem("$origin");
  $debug && print LOGFILE "$time : [$project] Comparing local repo $mrev with origin repo $orev\n";
  if ("$mrev" ne "$orev" ) {
    print LOGFILE "$time : [$project] $master ($mrev)  and $origin ($orev) do not match\n";
    my $log = `$git pull`; 
    my @logfiles=split ("\n",$log); foreach my $logline (@logfiles) { 
      print LOGFILE "$time : [$project] $git pull : $logline\n";
      }
    chomp ( my $owho=`$git log $orev -1 $gitwho` );
    chomp ( my $owhen=`$git log $orev -1 $gitwhen` );
    chomp ( my $owhat=`$git $gitwhat $mrev..$orev ` );
    chomp ( my $osub=`$git log $orev -1 $gitsub` );
    print LOGFILE "$time : [$project] $owho checked in files to $project $owhen. Message: $osub\n" ;
    # All set, now try re-set the local master rev
    $mrev=&getrevs("$master");
    }
}

sub timestamp{ chomp ( $time=`date`) ; } 

