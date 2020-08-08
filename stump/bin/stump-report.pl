#!/usr/bin/perl
#
# This script processes the logfile given as it first command argument, 
# and prints a nice report about approved, rejected, etc postings, to
# stdout.
#
# is called from report.sh
#

# get the directory where robomod is residing
$MNG_ROOT = $ENV{'MNG_ROOT'} || die "Root dir for moderation not specified";

# common library
require "$MNG_ROOT/bin/robomod.pl";

$logFile = $ARGV[0]   || die "A log file name must be specified";
open( LOG, $logFile ) || die "Can't open logfile $logFile for reading";

$approvedCount = 0;
$autoCount     = 0;
$rejectedCount = 0;
$preApprovedCount = 0;

while( <LOG> ) {
  $approvedCount++    if( /processApproved/i );
  $autoCount++        if( /PREAPPROVED/ );
  $rejectedCount++    if( /processRejected/i );
#  $approvedCount++    if( /processPreapproved/i );
  $preApprovedCount++ if( /processPreapproved/i );
}

print "

Approved:       $approvedCount 	messages (of them, $autoCount automatically)
Rejected:       $rejectedCount 	messages
Preapproved:    $preApprovedCount	new posters
" or die $!;
