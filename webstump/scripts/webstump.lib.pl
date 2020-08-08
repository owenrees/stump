# this is a collection of library functions for stump.

use IO::Handle;

# error message
sub error {
  my $msg = pop( @_ );

  if( defined $html_mode ) {
    print 
"Content-Type: text/html\n\n
<TITLE>WebSTUMP Error</TITLE>
<BODY BGCOLOR=\"#C5C5FF\" BACKGROUND=$base_address_for_files/images/bg1.jpg>
<H1>You have encountered an error in WebSTUMP.</H1>";

  &print_image( "construction.gif", "bug in WebSTUMP" );

  print " <B>$msg </B><HR>
Please cut and paste this
whole page and send it to <A HREF=mailto:$supporter>$supporter</A>.<P>
Query Parameters:<P>\n
<UL>";

    foreach (keys %request) {
      print "<LI> $_: $request{$_}\n";
    }
    exit 0;
  }

  die $msg;
}

# user error message
sub user_error {
  my $msg = pop( @_ );
  if( defined $html_mode ) {
    print 
"Content-Type: text/html\n\n
<TITLE>You have made a mistake.</TITLE>
<BODY BGCOLOR=\"#C5C5FF\" BACKGROUND=$base_address_for_files/images/bg1.jpg>
<H1>You have made a mistake.</H1>
  ";

  &print_image( "warning_big.gif", "Warning" );

  print " <B>$msg </B><HR>
Please go back to the previous page and correct it. If you get really
stuck, cut and paste this whole page and send it to <A
HREF=mailto:$supporter>$supporter</A>.

";

    exit 0;
  }

  die $msg;
}

# returns full config file name
sub full_config_file_name {
  my $short_name = pop( @_ );
  my $newsgroup = &required_parameter( "newsgroup" );
  $newsgroup =~ m/^\w[.0-9a-z+]+$/ or die;
  $newsgroup= $&;
  return  "$webstump_home/config/newsgroups/$newsgroup/$short_name";
}

# checks if the admin password supplied is correct
sub verify_admin_password {

  my $password = $request{'password'};

  my $password_file = "$webstump_home/config/admin_password.txt";

  open( PASSWORD, $password_file )
        || &error( "Password file $password_file does not exist" );
  my $correct_password = <PASSWORD>;
  chomp $correct_password;
  close( PASSWORD );

  &user_error( "invalid admin password" )
        if( $password ne $correct_password );

}

#
# appends a string to file.
#
sub append_to_file {
  my $msg = pop( @_ );
  my $file = pop( @_ );

  open_file_for_appending( FILE, "$file" ) 
  	|| die "Could not open $file for writing";
  print FILE $msg;
  close( FILE );
}

#
# add to config file
sub add_to_config_file {
  my $line = pop( @_ );
  my $file = pop( @_ );

print STDERR "File = $file, line= $line\n";

  if( !&name_is_in_list( $line, $file ) ) {
    &report_list_diff($file, sub {
	print DIFF "Added: $line\n" or die $!;
    });
    &append_to_file( &full_config_file_name( $file ), "$line\n" );
  }
}


sub report_list_diff ($$) {
  my ($list_file, $innards) = @_;

  my $head = &full_config_file_name( "change-notify-header" );
  if (!open DHEAD, '<', $head) {
      $!==&ENOENT or die "$head $!";
      return;
  }
  my $diff = "$list_file.diff.$$.tmp";
  my $ok= eval {
      open DIFF, '>>', $diff or die "$diff $!";
      while (<DHEAD>) { print DIFF or die $!; }
      print DIFF <<END or die $!;

Moderator: $request{'moderator'}
Control file: $list_file

END
      DHEAD->error and die $!;
      DIFF->flush or die $!;

      my $goahead= &$innards($diff);

      if ($goahead) {
	  print DIFF "\n-- \n" or die $!;
	  close DIFF or die $!;
	  my $child= fork; die unless defined $child;
	  if (!$child) {
	      open STDIN, '<', $diff or die "$diff $!";
	      exec find_sendmail(), qw(-odb -oem -oee -oi -t);
	      die $!;
	  }
	  waitpid($child,0) == $child or die "$list_file $!";
      }
      $?==0 or die "$list_file $?";
      unlink $diff or die $!;
      1;
  };
  if (!$ok) {
      unlink $diff;
      &error("Could not report change to $list_file: $@");
  }
}

# from CGI.pm
# unescape URL-encoded data
sub unescape {
    my $todecode = shift;
    $todecode =~ tr/+/ /;       # pluses become spaces
    $todecode =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    return $todecode;
}
 
# sets various useful variables, etc
sub setup_variables {
  $newsgroups_list_file = "$webstump_home/config/newsgroups.lst";
}

# initializes webstump, reads newsgroups list
sub init_webstump {
  &setup_variables;

  # read the NG list
  opendir( NEWSGROUPS, "$webstump_home/config/newsgroups" )
	|| &error( "can't open $webstump_home/config/newsgroups" );

    while( $_ = readdir( NEWSGROUPS ) ) {
      my $file = "$webstump_home/config/newsgroups/$_/address.txt";
      my $ng = $_;

      next if ! -r $file;

      open( FILE, $file ) or die $!;
      $addr = <FILE>;
      defined $addr or die $!;
      chop $addr;
      close( FILE );

	&error( "Invalid entry $_ in the newsgroups database." )
		if( !$ng || !$addr );
        push @newsgroups_array,$ng;
        $newsgroups_index{$ng} = "$addr";
    }
  close( NEWSGROUPS );

  open( LOG, ">>$webstump_home/log/webstump.log" ) or die $!;
  LOG->autoflush(1);
  print LOG "Call from $ENV{'REMOTE_ADDR'}, QUERY_STRING=$ENV{'QUERY_STRING'}\n" or die $!;
}

# gets the directory name for the newsgroup
sub getQueueDir {
  my $newsgroup = pop( @_ );
  if( $newsgroups_index{$newsgroup} ) {
    return "$queues_dir/$newsgroup";
  } 
  return ""; # undefined ng
}

# reads request, if any
sub readWebRequest {
  my @query;
  my %result;
  if( defined $ENV{"QUERY_STRING"} ) {

    @query = split( /&/, $ENV{"QUERY_STRING"} );
    foreach( @query ) {
      my ($name, $value) = split( /=/ );
      $result{&unescape($name)} = &unescape( $value );
    }
  }

  while(<STDIN>) {
    @query = split( /&/, $_ );
    foreach( @query ) {
      my ($name, $value) = split( /=/ );
      $result{&unescape($name)} = &unescape( $value );
    }
  }

  foreach( keys %result ) {
    print LOG "Request: $_ = $result{$_}\n" if( $_ ne "password" );
  }
  return %result;
}

# Checks if the program is running in a demo mode
sub is_demo_mode {
  return &optional_parameter( 'newsgroup' ) eq "demo.newsgroup" 
  	 && !$ignore_demo_mode;
}

# opens file for writing
sub open_file_for_writing { # filehandle, filename
  my $filename = pop( @_ );
  my $filehandle = pop( @_ );

  if( &is_demo_mode ) {
	return( open( $filehandle, ">/dev/null" ) );  
  } else {
	return( open( $filehandle, ">$filename" ) );
  }
}

# opens pipe for writing
sub open_pipe_for_writing { # filehandle, filename
  my $filename = pop( @_ );
  my $filehandle = pop( @_ );

  if( &is_demo_mode ) {
	return( open( $filehandle, ">/dev/null" ) );  
  } else {
	return( open( $filehandle, "|$filename" ) );
  }
}

# opens file for appending
sub open_file_for_appending { # filehandle, filename
  my $filename = pop( @_ );
  my $filehandle = pop( @_ );

  if( &is_demo_mode ) {
	return( open( $filehandle, ">>/dev/null" ) );  
  } else {
	return( open( $filehandle, ">>$filename" ) );
  }
}

# gets a parameter
sub get_parameter {
  my $arg = pop( @_ );
  return "" if( ! defined $request{$arg} );
  return $request{$arg};
}

# barfs if the required parameter is not supplied
sub required_parameter {
  my $arg = pop( @_ );
  user_error( "Parameter \"$arg\" is not defined or is empty" )
	if( ! defined $request{$arg} || !$request{$arg} );
  return $request{$arg};
}

# optional request parameter
sub optional_parameter {
  my $arg = pop( @_ );
  return $request{$arg};
}

# issues a security alert
sub security_alert {
  my $msg = pop( @_ );
  print LOG "SECURITY_ALERT: $msg\n";
}

# reads the moderators info
sub read_moderators {
  my $newsgroup = &required_parameter( "newsgroup" );

  my $file = &full_config_file_name( "moderators" );

  open( MODERATORS, "$file" )
        || error( "Could not open file with moderator passwords: $file" );
 
  while( <MODERATORS> ) {
    my ($name, $pwd) = split;
    $moderators{"\U$name"} = "\U$pwd";
  }
 
  close( MODERATORS );
}

# saves the moderators info
sub save_moderators {
  my $newsgroup = &required_parameter( "newsgroup" );

  my $file = &full_config_file_name( "moderators" );

  open_file_for_writing( MODERATORS, $file );
#        || &error( "Could not open file with moderator passwords: $file" );

  foreach (keys %moderators) {
      print MODERATORS "$_ $moderators{$_}\n";
  }
 
  close( MODERATORS );
}

# authenticates user
sub authenticate {
  my $password = &required_parameter( "password" );
  my $moderator = &required_parameter( "moderator" );
  my $newsgroup = &required_parameter( "newsgroup" );
  
  &read_moderators;

  if( !defined $moderators{"\U$moderator"} || 
      $moderators{"\U$moderator"} ne "\U$password" ) {
    &security_alert( "Authentication denied." )
    &user_error( "Authentication denied." );
  }
}

# cleans request of dangerous characters
sub disinfect_request {
  if( defined $request{'newsgroup'} ) {
    $newsgroup = $request{'newsgroup'};
    $newsgroup =~ m/^(\w[.0-9a-z+]+)$/ or die;
    $newsgroup= $1;
    $request{'newsgroup'} = $newsgroup;
  }

  if( defined $request{'file'} ) {
    my $file = $request{'file'};
    $file =~ m/^\w[.0-9a-z]+\.list$|^dir_\d+_\d+$/ or die "$file ?";
    $file = "$&";
    $request{'file'} = $file;
  }
}

# adds a user
sub add_user {
  my $user = &required_parameter( "user" );
  my $new_password = &required_parameter( "new_password" );

  &user_error( "Username may only contain letters and digits" )
    if( ! ($user =~ /^[a-zA-Z0-9]+$/ ) );
  &user_error( "Password may only contain letters and digits" )
    if( ! ($new_password =~ /^[a-zA-Z0-9]+$/ ) );
  &user_error( "Cannot change password for user admin" )
    if( "\U$user" eq "ADMIN" );

  $moderators{"\U$user"} = "\U$new_password";

  &save_moderators;
}

# checks that a config list is in enumerated set of values. Returns 
# untainted value
sub check_config_list {
  my $list_to_edit = pop( @_ );

 &user_error( "invalid list name $list_to_edit" )
    if( $list_to_edit ne "good.posters.list"
        && $list_to_edit ne "watch.posters.list"
        && $list_to_edit ne "bad.posters.list"
        && $list_to_edit ne "good.subjects.list"
        && $list_to_edit ne "watch.subjects.list"
        && $list_to_edit ne "bad.subjects.list"
        && $list_to_edit ne "bad.words.list"
        && $list_to_edit ne "watch.words.list"
        && $list_to_edit ne "watch.unquoted.words.list" );

  return &untaint( $list_to_edit );
}

# sets a configuration list (good posters etc)
sub set_config_list {
  my $list_content = $request{"list"};
  my $list_to_edit = &required_parameter( "list_to_edit" );

  $list_content .= "\n";
  $list_content =~ s/\r//g;
  $list_content =~ s/\n+/\n/g;
  $list_content =~ s/\n +/\n/g;
  $list_content =~ s/^\n+//g;

  $list_to_edit = &check_config_list( $list_to_edit );

  my $list_file = &full_config_file_name( $list_to_edit );

  open_file_for_writing( LIST, "$list_file.new" ) 
    || &error( "Could not open $list_file for writing" );
  print LIST $list_content;
  close( LIST );

  report_list_diff("$list_to_edit", sub {
      my ($diff)= @_;
      my $child= fork; die unless defined $child;
      if (!$child) {
	  open STDOUT, '>&DIFF' or die $!;
	  exec 'diff','-u','-L', "$list_to_edit.old",'-L', "$list_to_edit.new",'--', "$list_file","$list_file.new";
	  die $!;
      }
      waitpid($child,0) == $child or die "$list_file $!";
      $?==0 or $?==256 or die "$list_file $?";
      return !!$?;
  });
  rename ("$list_file.new", "$list_file");
}

# deletes a user
sub delete_user {
  my $user = &required_parameter( "user" );

  &user_error( "User \U$user" . " does not exist!" ) 
    if( ! defined $moderators{"\U$user"} );
  &user_error( "Cannot delete user admin" )
    if( "\U$user" eq "ADMIN" );

  delete $moderators{"\U$user"};

  &save_moderators;
}

# validate password change
sub validate_change_password {
  my $user = &required_parameter( "moderator" );
  my $new_password = &required_parameter( "new_password" );

  &user_error( "Password may only contain letters and digits" )
    if( ! ($new_password =~ /^[a-zA-Z0-9]+$/ ) );
  &user_error( "Cannot change password for user admin" )
    if( "\U$user" eq "ADMIN" );

  $moderators{"\U$user"} = "\U$new_password";

  &save_moderators;
  &html_welcome_page;
}

# reads rejection reasons
sub read_rejection_reasons {
  my $newsgroup = &required_parameter( 'newsgroup' );
  my $reasons = &full_config_file_name( "rejection-reasons" );
  open( REASONS, $reasons ) || &error( "Could not open file $reasons" );
 
  while( <REASONS> ) {
	chop;
	my ($name, $title) = split( /::/ );
	$rejection_reasons{$name} = $title;
        push @short_rejection_reasons, $name;
  }

  close REASONS;
}

sub find_sendmail {

  my $sendmail = "";

  foreach (@sendmail) {
    if( -x $_ ) {
      $sendmail = $_;
      last;
    }
  }
 
  &error( "Sendmail not found" ) if( !$sendmail );

  return $sendmail;
}

# email_message message recipient
sub email_message {
  my $recipient = pop( @_ );
  my $message = pop( @_ );
  my $sendmail= find_sendmail;
  my $sendmail_command = "$sendmail $recipient";
  $sendmail_command =~ /(^.*$)/; 
  $sendmail_command = $1; # untaint
  open_pipe_for_writing( SENDMAIL, "$sendmail_command > /dev/null " )
			 or die $!;
  print SENDMAIL $message or die $!;
  close( SENDMAIL ) or die "$? $!";
                
}

sub article_file_name {
  my $file = pop( @_ );
  return "$queues_dir/$newsgroup/$file";
}

sub untaint {
  $arg = pop( @_ );
  $arg =~ /(^.*$)/;
  return $1;
}

sub rmdir_rf {
  my $dir = pop( @_ );

  return if &is_demo_mode;

  opendir( DIR, $dir ) || return;
  while( $_ = readdir(DIR) ) {
    unlink &untaint( "$dir/$_" );
  }
  closedir( DIR );
  rmdir( $dir );
}

sub approval_decision {
  $newsgroup = &required_parameter( 'newsgroup' );
  my $comment = &get_parameter( 'comment' );
  my $decision = "";

  my $poster_decision = &optional_parameter( "poster_decision" );
  my $thread_decision = &optional_parameter( "thread_decision" );
  
  foreach( keys %request ) {
    if( /^decision_(dir_[0-9a-z_]+)$/ ) {
      $decision = $request{$&};
      my $file= $1; # untainted

      next if $request{'skip_submit'};
      next if $decision eq 'skip';

      my $waf= &article_file_name($1).'/stump-warning.txt';
      if ($decision eq 'leave') {
	  my $now= time;  defined $now or die $!;
	  utime $now,$now, $waf or $!==&ENOENT or die "$waf $!";
	  next;
      }

      if ($decision eq 'consider') {
	  if (!open ADDWARN, '>>', $waf) {
	      $!==&ENOENT or die "$waf $!";
	  } else {
	      print ADDWARN "A moderator has marked this message for further consideration - please consult your comoderators before approving.\n" or die $!;
	      close ADDWARN or die $!;
	  }
	  next;
      }

      die "$decision ?" unless $decision =~ m/^(approve|reject \w+)$/;
      $decision= $1;

      my $fullpath = &article_file_name( $file ) . "/stump-prolog.txt";

      $decision = "reject thread" if $thread_decision eq "ban";
      $decision = "approve" if $thread_decision eq "preapprove";

      #$decision = "reject blocklist" if $poster_decision eq "ban";
      die if $decision ne "approve" and $poster_decision eq "preapprove";

      if( -r $fullpath && open( MESSAGE, "$fullpath" ) ) {
        my $RealSubject = "", $From = "", $Subject = "";
        while( <MESSAGE> ) {
          if( /^Subject: /i ) {
	    chop;
            $Subject = $_;
	    $Subject =~ s/Subject: +//i;
          } elsif( /^Real-Subject: /i ) {
	    chop;
            $RealSubject = $_;
	    $RealSubject =~ s/Real-Subject: +//i;
	    $RealSubject =~ s/Re: +//i;
          } elsif( /^From: / ) {
	    chop;
            $From = $_;
	    $From =~ s/From: //i;
          }
          last if /^$/;
        }
        close MESSAGE;

        &add_to_config_file( "good.posters.list", $From ) 
		if $poster_decision eq "preapprove";

        &add_to_config_file( "good.subjects.list", $RealSubject ) 
		if $thread_decision eq "preapprove";

        &add_to_config_file( "watch.posters.list", $From ) 
		if $poster_decision eq "suspicious";

        &add_to_config_file( "bad.posters.list", $From ) 
		if $poster_decision eq "ban";

        &add_to_config_file( "bad.subjects.list", $RealSubject ) 
		if $thread_decision eq "ban";

        &add_to_config_file( "watch.subjects.list", $RealSubject ) 
		if $thread_decision eq "watch";

# Subject, newsgroup, ShortDirectoryName, decision, comment
        &process_approval_decision( $Subject, $newsgroup, $file, $decision, $comment, "moderator \U$request{'moderator'}" );

      }
    }
  }

  &html_moderation_screen;
}

# gets the count of unapproved articles sitting in the queue
sub get_article_count {
  my $newsgroup = pop( @_ );
   my $count = 0;
   my $dir = &getQueueDir( $newsgroup );
   opendir( DIR, $dir );
   my $file;
   while( $file = readdir( DIR ) ) {
     $count++ if( -d "$dir/$file" && $file ne "." && $file ne ".." && -r "$dir/$file/full_message.txt" );
   }

   return $count;
}

# processes web request
sub processWebRequest {

  my $action = $request{'action'};
  my $newsgroup = $request{'newsgroup'};
  my $moderator = $request{'moderator'};
  my $password = $request{'password'};

  $moderator = "\L$moderator";

  if( $action eq "login_screen" ) {
    &html_login_screen;
  } elsif( $action eq "moderation_screen" ) {
    &authenticate( $newsgroup, $moderator, $password );
    if( $moderator eq "admin" ) {
      &html_newsgroup_management;
    } else {
      &html_moderation_screen;
    }
  } elsif( $action eq "moderator_admin" ) {
    &authenticate( $newsgroup, $moderator, $password );
    &html_newsgroup_management;
  } elsif( $action eq "edit_list" ) {
    &authenticate( $newsgroup, $moderator, $password );
    &edit_configuration_list;
  } elsif( $action eq "add_user" ) {
    &authenticate( $newsgroup, $moderator, $password );
    if( $moderator ne "admin" ) {
      &security_alert( "Moderator $moderator tried to add user in $newsgroup" );
      &user_error( "Only administrator (login ADMIN) can add or delete users" );
    }

    &add_user;
    &html_newsgroup_management;
  } elsif( $action eq "set_config_list" ) {
    &authenticate( $newsgroup, $moderator, $password );
    &set_config_list;
    &html_newsgroup_management;
  } elsif( $action eq "delete_user" ) {
    &authenticate( $newsgroup, $moderator, $password );
    if( $moderator ne "admin" ) {
      &security_alert( "Moderator $moderator tried to add user in $newsgroup" );
      &user_error( "Only administrator (login ADMIN) can add or delete users" );
    }
    &delete_user;
    &html_newsgroup_management;
  } elsif( $action eq "approval_decision" ) {
    &authenticate( $newsgroup, $moderator, $password );
    if( $moderator eq "admin" ) {
      &user_error( "Login ADMIN exists for user management only" );
    }
    &approval_decision;
  } elsif( $action eq "moderate_article" ) {
    &authenticate( $newsgroup, $moderator, $password );
    if( $moderator eq "admin" ) {
      &user_error( "Login ADMIN exists for user management only" );
    }
    &html_moderate_article();
  } elsif( $action eq "change_password" ) {
    &authenticate( $newsgroup, $moderator, $password );
    &html_change_password;
  } elsif( $action eq "search_logs" ) {
    &authenticate( $newsgroup, $moderator, $password );
    &html_search_logs;
  } elsif( $action eq "validate_change_password" ) {
    &authenticate( $newsgroup, $moderator, $password );
    &validate_change_password;
#  } elsif( $action eq "init_request_newsgroup_creation" ) {
#    &init_request_newsgroup_creation;
#  } elsif( $action eq "complete_newsgroup_creation_request" ) {
#    &complete_newsgroup_creation_request;
  } elsif( $action eq "webstump_admin_screen" ) {
    &webstump_admin_screen;
  } elsif( $action eq "admin_login" ) {
    &admin_login_screen;
  } elsif( $action eq "admin_add_newsgroup" ) {
    &admin_add_newsgroup;
  } elsif( $action eq "help" ) {
    &display_help;
  } else {
    &error( "Unknown user action: '$action'" );
  }
}


1;
