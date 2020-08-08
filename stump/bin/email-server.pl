#!/usr/bin/perl
######################################################################
# This perl script is a file server. It allows users
# to retrieve and alter certain files.
# Its purpose is to allow them to manage their installations
# without the need to log in remotely and without the need to know 
# anything about Unix(tm).
#
# It only allows retrieving and updating files that have been
# explicitly mentioned as available in its configuration file.
#
# USAGE: 
#
# First, you have to come up with a password (I strongly suggest using 
# a password that is DIFFERENT from your regular Unix password).
#
# Save it in file $HOME/.email-server.pwd
#
# Second, create a file $HOME/.email-server.cfg and list files (and their
# optional text descriptions) like this:
#
# stump-faq tmp/stump-users-faq.txt FAQ for STUMP users
# rw:mydir some/dir/mydir Directory with test files
#
# The syntax of this file is as follows:
#
# [mode:]filehandle fullpath comment
#
# where mode is either r or rw. r means read only (which is the 
# default mode that is used if no mode is mentioned], and rw means that 
# the file can be both read and changed. 
#
# filehandle is the "external" name by 
# which the file will be known to the email user. It may be different from 
# the actual file name.
#
# fullpath is the actual path to the file or directory that you want
# to make available, RELATIVE to your home directory.
#
# This script is supposed to be called from your .procmailrc. To recognize
# your requests to this script from other emails, perhaps you could send
# them with a different To: address, for example you could always use
#
# 	To: your@email.address (Email File Server)
#
# and then use a procmail recipe like
#
# :0:
# * ^To: .*Email File Server
# | email-server.pl
#
# Copyright(C) 1998 Igor Chudov, ichudov@algebra.com, 
#
#		 http://www.algebra.com/~ichudov.
#
# GNU Public License applies.
# There is NO WARRANTY WHATSOEVER. USE THIS PROGRAM AT YOUR OWN RISK.
#
######################################################################

sub read_config {
  my $config_file = "$SERVER_ROOT/.email-server.cfg";
  open( CONFIG, $config_file )
	|| die "Config file $config_file not found.";
  while( <CONFIG> ) {
    chop;
    if( ! /^#/ ) {
      my ($mode_handle, $file, @explanation) = split;

      my $mode = "r", $handle = $mode_handle; # if no mode is present that's 
                                              # the default

      if( $mode_handle =~ /:/ ) {
        ($mode, $handle) = split( /:/, $mode_handle );
      }

      print STDERR "File $file served by email server does not exist in $SERVER_ROOT\n"
        if( ! -e "$SERVER_ROOT/$file" );

      print STDERR "Mode must be rw or r" 
        if( $mode ne "r" && $mode ne "rw" );

      $served_files{$handle} = $file;
      $explanations{$handle} = join( " ", @explanation );
      $file_modes{$handle} = $mode;
    }
  }
  close( CONFIG );
}

sub init {

  die "HOME is not defined!!!"
    if not defined $ENV{'HOME'};

  $SERVER_ROOT = $ENV{'HOME'};

  &read_config;
  open( PASSWORD, "$SERVER_ROOT/.email-server.pwd" );
  $password = <PASSWORD>;
  chop $password if( $password =~ /\n$/ );
  close( PASSWORD );

  if( defined $ENV{'EMAIL_SERVER_ADDRESS'} ) {
    $email_server_address = $ENV{'EMAIL_SERVER_ADDRESS'};
  } else {
    $email_server_address = "bad_address\@stump.algebra.com (WRONG ADDRESS)";
  }

  my @sendmail_dirs = ("/bin", "/usr/bin", "/usr/sbin", "/usr/lib" );

  $sendmail = "/bin/mail"; # last resort...

  foreach (@sendmail_dirs) {
    $sendmail = "$_/sendmail"
      if( -x "$_/sendmail" );
  }

  $short_help = "\nSend email with 'help' in subject field to receive an\n" .
                "explanation on how to work with this email server.\n";
  $long_help = "

Hi there, 

Thanks for asking for help! Here it is.

I am an automated email server. I am here to help you manage your files
remotely without the need to log in and use Unix commands to edit your
configuration files.

You can retrieve this help message by sending me an email with the only
word 'help' in the Subject: field of your message.

I process your commands. I do a limited set of simple tasks, such as
retrieving and modifying text configuration files. Only certain files
can be retrieved and modified; this is done for your own security.

Whenever you retrieve a file or want to modify a file, you will have
to provide a password to me, as well as the command that I will execute.
Passwords are used to ensure that only authorized users can perform
important operations; however, anyone can request and receive this
help message.

IF YOU DO NOT KNOW THE PASSWORD, you have to ask the 
administrator of my account to provide you with one.

All commands, along with passwords, should be specified in the Subject: 
field of your messages. A password always goes first, followed by the
command. For example, if your password is 'xyzzy' and the command is
'get moderators' (more on commands later), then the Subject: field 
should be

	Subject: xyzzy: get moderators

Both commands and passwords are NOT case sensitive. You can mix uppercase
with lowercase as you wish.

COMMANDS: 

Right now, there are three kinds of commands:

1. help. This command requests help. Requires no password.

2. get filename. This command requests a file to be sent from the 
   server to you. The body of your message is ignored. 

   Example (assuming your password is xyzzy):

   Subject: xyzzy: get bad.guys.list

   Note that for certain files, their \"names\" may consist of
   directory name, followed by a \"/\" (slash) character and the name
   of the file. For example, a get command may be of form:

   Subject: xyzzy: get messages/offtopic

3. set filename. This command requests that the contents of the file be set
   to the text in the body of your message. 
 
   Example (assuming your password is xyzzy):
 
   Subject: xyzzy: set bad.guys.list

   spammer\@cyberpromo.com
   flamer\@netcom.com
   <END OF MESSAGE>

   Note that for certain files, their \"names\" may consist of
   directory name, followed by a \"/\" (slash) character and the name
   of the file. For example, a set command may be of form:

   Subject: xyzzy: set messages/offtopic

   Thanks for submitting your article to comp.sys.foobars.moderated. Your
   article is offtopic and is being rejected. Have a nice day!

FILES THAT CAN BE RETRIEVED AND CHANGED.

The following are the file names (that you can mention in set and get 
commands) that are supported by this installation:

NAME OF FILE               Explanation

";

  foreach( keys %served_files ) {
    $long_help .= $_ . substr( "                    ", length( $_ ), 100 );

    my $mode = $file_modes{$_};
    if( $mode eq "r" ) { $long_help .= "(Read-Only) "; }
    else { $long_help .= "(Read-Write) "; }

    $long_help .= $explanations{$_} . "\n";

    my $file = "$SERVER_ROOT/$served_files{$_}";

    if( ! -e $file ) {
      $long_help .= "(this file does NOT exist)\n";
    } elsif( -d $file ) {
      $long_help .= "$_ is a DIRECTORY. Available files are: \n";
      opendir( DIR, $file );
      my $dir = $_;
      my $fn;
      while( $fn = readdir( DIR ) ) {
        my $file1 = "$file/$fn";
        if( ! /^\./  && -f $file1 && -r $file1 ) {
          $long_help .= "\t$dir/$fn\n";
        }
      }
      closedir( DIR );
    }
  }
}

sub reply {
  my $msg = pop( @_ );

  my $address = $From;
  $address =~ s/^From: //i;

  if( defined $ReplyTo ) {
    $address = $ReplyTo;
    $address =~ s/^Reply-To: //i;
    $address =~ s/`//g;
    $address =~ s/;//g;
  }

  open( SENDMAIL, "|$sendmail '$address'" ) 
	|| die "Could not start sendmail in $sendmail";

  print SENDMAIL "From: $To\n" or die $!;
  print SENDMAIL "To: $address\n" or die $!;
  print SENDMAIL "Subject: Re: $Subject\n" or die $!;

  print SENDMAIL "\n" or die $!;

  print SENDMAIL "$msg\n" or die $!;

  close( SENDMAIL ) or die "$? $!";

}

sub user_error {
  my ($msg) = pop( @_ );
  &reply( "You made a mistake:\n\n$msg\n$short_help\n" .
          "Message Follows:\n\n$Headers\n$Body\n" );
  exit 0;
}

sub readMessage {

  while(<STDIN>) {
    s/^From />From /;
    last if( /^$/ );
    $Headers .= $_;
    chop;
    if( /^Subject: / ) {
      $Subject = $_;
      $Subject =~ s/^Subject: //;
      $Subject = "\L$Subject";
    } elsif( /^From: / ) {
      $From = $_;
      $From =~ s/^From: //;
    } elsif( /^To: / ) {
      $To = $_;
      $To =~ s/^To: //;
    } elsif( /^Reply-To: / ) {
      $ReplyTo = $_;
      $ReplyTo =~ s/^Reply-To: //;
    } 
  }

  while( <STDIN> ) {
    s/^From />From /;
    $Body .= $_;
  }
}

sub file_from_arg {
  my $arg = pop( @_ );

  if( $arg =~ /\// ) {
    my ($dir, $file) = split( /\//, $arg );
    # now clean $file
    $file =~ s/\///g;
    $file =~ s/^\.//g;

    if( defined $served_files{$dir} ) {
      my $fullpath = "$SERVER_ROOT/$served_files{$dir}/$file";
      return $fullpath if( -f $fullpath );
    }

  } else {
    if( defined $served_files{$arg} ) {
      my $fullpath = "$SERVER_ROOT/$served_files{$arg}";
      return $fullpath if( -f $fullpath );
    }
  }
}

sub mode_from_arg {
  my $arg = pop( @_ );
  if( $arg =~ /\// ) {
    my ($dir, $file) = split( /\//, $arg );
    return $file_modes{$dir} if( defined $file_modes{$dir} );
  } else {
    return $file_modes{$arg};
  }
}

sub command_get {
  my $arg = pop( @_ );
  my $file = &file_from_arg( $arg );

  &user_error( "File $arg is not in the list of available files. Perhaps\n" .
               "it is a directory or maybe you just misspelled its name." )
    if( !$file );

  if( -r $file ) {

    my $reply_body = "";

    open( FILE, $file ) or die $!;
    $reply_body .= $_ while( <FILE> );
    close( FILE );

    &reply( $reply_body );

  } else { 
    &user_error( "File $arg does not exist or is not readable" );
  }
}

# sub command_set {
#   my $arg = pop( @_ );
# 
#   my $file = &file_from_arg( $arg );
#   my $mode = &mode_from_arg( $arg );
# 
#   &user_error( "File $arg is not in the list of available files." )
#     if( !$file );
# 
#   if( -w $file && -f $file && $mode eq "rw" ) {
# 
#     my $reply_body = "Succeeded in writing to file '$arg':\n\n$Body";
# 
#     if( open( FILE, ">$file" ) ) {
#       print FILE $Body;
#       close( FILE );
#     } else {
#       $reply_body = "Failed to write to file $arg:\n\n$Body";
#     }
# 
#     &reply( $reply_body );
# 
#   } else { 
#     &user_error( "File $arg does not exist or is not writable" );
#   }
# }

sub main {
  &init;
  &readMessage;
  &user_error( "No Subject: field provided in your message" ) if( !$Subject );

  if( $Subject =~ /^help/ ) {
    &reply( $long_help );
  } elsif( $Subject =~ /:/ ) {
    my ($pass, $command) = split( /:/, $Subject );

    &user_error("Invalid Password") if( "\L$pass" ne "\L$password" );

    $command =~ s/^ +//;

    my @command = split / /, $command;
    $command = shift @command;
    $command = "\L$command"; # lowercase

    my $argument = shift @command;
    $argument = "\L$argument";

    if( $command eq "get" ) {
      &command_get( $argument );
    } elsif( $command eq "set" ) {
      &command_set( $argument );
    } else {
      &user_error( "Invalid command: $command" );
    }
  }
}

######################################################################
&main;
