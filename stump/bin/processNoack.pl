#
# Processes the "No Ack" request
#

# get the directory where robomod is residing
$MNG_ROOT = $ENV{'MNG_ROOT'} || die "Root dir for moderation not specified";

# common library
require "$MNG_ROOT/bin/robomod.pl";

$NoAckFile = "$MNG_ROOT/data/noack.list";

$Argv = join( ' ', @ARGV );

while( <STDIN> ) {
  $From = $_ if( /^From: / );

  chop;
  last if( /^$/ );
}

$From =~ s/^From: //;
chomp $From;
if( $From !~ m/([\w-\.]*)\@([\w-\.]+)/ || $From =~ m/\n/) {
  print STDERR "From line `$From' is incorrect\n";
  exit 0;
}

if( !&nameIsInListExactly( $From, "noack.list" ) ) { # need to preapprove
  print STDERR "Adding $From to the noack list...\n";
  open( NOACK, ">>$NoAckFile" ) or die $!;
    print NOACK "$From\n" or die $!;
  close( NOACK ) or die $!;
} else {
  print STDERR "$From already is in noack list\n";
}

1;
