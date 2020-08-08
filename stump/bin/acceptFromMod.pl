#
# This script accepts an email from moderators and processes
# an approval or a rejection.
#
 
$MNG_ROOT = $ENV{'MNG_ROOT'} || die "\$MNG_ROOT is not defined";
 
$Prefix = $ENV{'BOT_SUBJECT_PREFIX'} 
  || die "\$BOT_SUBJECT_PREFIX is not defined";
 
$MessageNumber = "";
$Error = "";
 
#######################################################################
# notifies the bot supporter
#
sub processError {
  $msg = pop( @_ );

print STDERR "Approval error: " . $msg . "\n"; 

  if( $MessageFile && -r $MessageFile ) {
    system( "suspicious no NOTICE: This message is being RE-SENT to you because of the following error in your approval: $msg < $MessageFile" );
  } else {
    print STDERR "ERROR: Completely bogus approval from $From, $msg\n";
  }

  exit 1;
}
 
####################################################################### main
# handling headers
#
while( <STDIN> ) {
 
  chop;

  if( /^$/ ) {
    goto after_header;
  }
 
  if( /^Subject: /i  && !$Subject ) {
 
    $Subject = $_;
    $Subject =~ s/^Subject: //i;
 
    if( /::$Prefix\// ) {
 
      $MessageNumber = $Subject;
      $MessageNumber =~ s/^.*::$Prefix\///;
      $MessageNumber =~ /(\d+)/;
      $MessageNumber = $1;
      $ENV{'WEBSTUMP_MESSAGENUM'}= $MessageNumber;

      $MessageFile = "$MNG_ROOT/tmp/messages/$MessageNumber";
 
      if( !($MessageNumber =~ /[0-9]+/) || !(-r $MessageFile) )
        {
          $Error = "Message number in subject incorrect";
        }
 
    } else {
      $Error = "no message number";
    }
 
  } elsif ( /^From: /i ) {
    $From = $_;
    $From =~ s/^From: //i;
  }
}


after_header:
 
&processError($Error) if( $Error );
 
#
# Now we are looking at the body
#
 
$done = "";
$command = "";
$comment = "";
 
while( <STDIN> ) {
 
  chop;
 
  if( /preapprove/i ) {
    $command = "processPreapproved xxx";
    $done = "yes";
    goto after_body;
  }
 
  if( /approve/i ) {
      $command = "processApproved xxx ";
    $done = "yes";
    goto after_body;
  }
 
  if( /reject/i ) {
 
    $reason = $_;
    $reason =~ s/^.*reject //i;
    $reason =~ s/( |`|'|"|;|\.|\/|\\)//g;
    &processError( "wrong rejection reason" ) if( !$reason );

    &processError( "Wrong rejection reason" )
       if( !( -r "$MNG_ROOT/etc/messages/$reason" ) 
	   && ($reason ne "custom")
         );
 
    $command = "processRejected xxx $reason";
 
    $done = "yes";
    goto after_body;
  }
}

after_body:
print STDERR "After body\n";

&processError( "No Command Specified" ) if( !$command );

while( <> ) {
  if( /^comment/ ) {
    s/^comment//;
    $comment = $_;  
    $comment .= $_ while( <> );
  }
}

print STDERR "Comment is: $comment\n" if( $comment );
print STDERR "Signal handling for SIGPIPE: $SIG{PIPE}.\n";

$ENV{'EXPLANATION'} = $comment;

open( COMMAND, "| $command" ) ||  &processError( "$command failed" );

  open( MESSAGE, "$MessageFile" ) || &processError( "Can't open $MessageFile" );
  while( <MESSAGE> ) { print COMMAND or die $!; }
  close( MESSAGE ) or die "$? $!";

#  if( $comment && !($command =~ '^processRejected') ) {
#    print COMMAND 
#       "\n======================================= MODERATOR'S COMMENT: \n" .
#       $comment;
#  }
close( COMMAND ) or die "$command $? $!";

&processError( "No action specified" ) 
  if( $done ne "yes" );

unlink( $MessageFile );


1;
