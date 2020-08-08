#!/usr/bin/perl
#
# This is the main webstump cgi script.
#
# Figure out the home directory
#

if( !($0 =~ /\/scripts\/webstump\.pl$/) ) {
  die "This script can only be called with full path name!!!";
}

umask 007;

$webstump_home = $0;
$webstump_home =~ s/\/scripts\/webstump\.pl$//;

my $logfile= "$webstump_home/../errs";
open STDERR, ">> $logfile" or die "$logfile $!";

$webstump_home =~ /(^.*$)/;
$webstump_home = $1;

require "$webstump_home/config/webstump.cfg";
require "$webstump_home/scripts/webstump.lib.pl";
require "$webstump_home/scripts/filter.lib.pl";
require "$webstump_home/scripts/html_output.pl";
#require "$webstump_home/scripts/gatekeeper.lib";
require "$webstump_home/scripts/mime-parsing.lib";

$html_mode = "yes";

&init_webstump;

######################################################################

%request = &readWebRequest;

$command = "";

if( defined %request ) {
  &disinfect_request;
  $command = $request{'action'} if( defined $request{'action'} );
}

if( ! $command ) {
  &html_welcome_page;
} else {
  &processWebRequest( $command );
}
