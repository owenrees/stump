#
#
# This library of functions is used for filtering messages.
#


# processes approval decision.
#
# Arguments: 
#
# Subject, newsgroup, ShortDirectoryName, decision, comment

sub process_approval_decision {
  my $cathow = @_>=6 ? pop(@_) : "UNKNOWN";
  my $comment = pop( @_ );
  my $decision = pop( @_ );
  my $ShortDirectoryName = pop( @_ );
  my $newsgroup = pop( @_ );
  my $Subject = pop( @_ );
  my $now = time;

  my $address = $newsgroups_index{$newsgroup};

  my $message = "To: $newsgroups_index{$newsgroup}\n" .
		"Subject: $Subject\n" .
                "Organization: http://www.algebra.com/~ichudov/stump\n";

  $message .= "\n# $cathow\n";
  $message .= "\n$decision\n";
  $message .= "comment $comment\n" if $comment;
  &email_message( $message, $address );

  my $sanisubj= $Subject;
  $sanisubj =~ s/.*\:\://;

print STDERR "DECISION: $newsgroup | $ShortDirectoryName | $decision | $cathow | $now | $sanisubj\n";

  &rmdir_rf( &article_file_name( $ShortDirectoryName ) );

}


###################################################################### checkAck
# checks the string matches one of the substrings. A name is matched
# against the substrings as regexps and substrings as literal substrings.
#
# Arguments: address, listname

sub name_is_in_list { # address, listname
  my $listName = pop( @_ );
  my $address = pop( @_ );

  my $item = "";
  my $Result = "";

  open( LIST, &full_config_file_name( $listName ) ) || return "";

  while( $item = <LIST> ) {

    chomp $item;

    next unless $item =~ /\S/;
    next if $item =~ /^\s*\#/;

    if ($listName eq 'good.posters.list') {
	if( lc $address eq lc $item ) {
	    $Result = $item;
	}
    } else {
	if( eval { $address =~ /$item/i; } ) {
	    $Result = $item;
	}
    }
  }

  close( LIST );

  return $Result;
}

######################################################################
# checks the string matches one of the patterns in the named list. The
# list is a file of patterns, one per line that are matched as regexps
# against the supplied string. If the line containing the match is
# quoted from an approved post to the specified newsgroup then the
# match is ignored.
#
# Arguments: string, newsgroup, listname
# Result: matched items joined with commas (true) or empty string if no
#         matches survived the filter.

sub name_is_in_list_unquoted {
  my ($string, $newsgroup, $listName) = @_;
  my $item = "";
  my $lines = {};
  my %unquoted = ();
  my $archivedir = "$webstump_home/../archive";

  open( LIST, &full_config_file_name( $listName ) ) || return "";

  while( $item = <LIST> ) {

    chomp $item;

    next unless $item =~ /\S/;
    next if $item =~ /^\s*\#/;

    # Catch failures caused by bad $item values, ignoring that item
    eval {
      # capture all the lines containing a watched word for filtering later
      while( $string =~ /^(?<quote>(?:>[ ]?)*)\s*(?!>)(?=\S)(?<line>.*$item(?:.*\S)?)\s*$/img ) {
        # All the '>' or '> ' quote markers have been stripped from the front of the line as has
        # leading and trailing whitespace.
        # We require at least one quote but we lose the ability to check quote depth here.
        printf STDERR "Matched $item in '%s' '%s'\n", $+{quote} || "", $+{line};
        if ($+{quote}) {
          $lines->{$+{line}}->{$item} = 1;
        } else {
          $unquoted{$item} = 1;
        }
      }
    }
  }

  close( LIST );
  # Search the archive of approved messages and remove lines that match
  # lines in approved posts. Check the live archive and the latest old archive.
  if(scalar(keys(%$lines))) {
    remove_matching_lines($newsgroup, $lines, "<", "$archivedir/approved");
  }
  if(scalar(keys(%$lines))) {
    remove_matching_lines($newsgroup, $lines, "-|", "zcat $archivedir/old/approved.current");
  }
  # deduplicate the list of items that were found.
  foreach my $v (values(%$lines)) {
    foreach my $k (keys(%$v)) {
      $unquoted{$k} = 1;
    }
  }
  return sort(keys(%unquoted));
}

######################################################################
# Searches the specified file for lines that match the set provided
# removing any that are found in posts to the specified group. The file
# is in mbox format containing multiple messages.

sub remove_matching_lines {
  my ($newsgroup, $lines, $openmode, $file) = @_;
  my %message = ();
  # print STDERR "Removing lines found in $file\n";
  # If the file cannot be opened just do nothing
  my $opened = open(my $fh, $openmode, $file);
  if (!$opened) {
    # Expected if archive has just been rotated or has never
    # been rotated - file does not exist.
    print STDERR "Failed: open $openmode $file $!\n";
    return;
  }
  while (my $line = <$fh>) {
    chomp $line;
    if ( $line =~ m/^From /) {
      # We should not get a header continuation line before the first
      # header but if we do it is captured in $message{' '}
      %message = (':', ' ');
      next;
    }
    # Process the headers looking for newsgroups and message-id
    if (!$message{body}) {
      # Match a header line capturing hader name and content with leading and
      # trailing whitespace stripped
      if ($line =~ m/(?<header>[^\s:]+:)\s*(?<content>(?:\S(?:.*\S)?)?)\s*$/) {
      	my $header = lc($+{header});
        $message{':'} = $header;
        $message{$header} = $+{content};
        next;
      }
      # Deal with header continuation line including whitespace only
      if ($line =~ m/^\s+(?<continued>(?:\S(?:.*\S)?)?)\s*$/) {
        $message{$message{':'}} .= $+{continued};
        next;
      }
      # blank line signals end of headers
      if ($line =~ m/^$/) {
        # is the message in the group we want?
        if ($message{"newsgroups:"} =~ m/(?:^|,)\Q$newsgroup\E(?:,|$)/) {
          $message{thisgroup} = 1;
        }
        $message{body} = 1;
        next;
      }
    } else {
      # just skip the body if in the wrong group
      if (!$message{thisgroup}) {
        next;
      }
      # See note above: $lines contains lines with all leading '>' stripped
      # and also leading and trailing whitespace stripped.
      # Do the same to the line we are processing
      $line =~ m/^(?<quote>(?:>[ ]?)*)\s*(?!>)(?=\S)(?<line>\S(?:.*\S)?)\s*$/im;
      # delete the entry - does nothing if it is not there
      my $deleted = delete($lines->{$+{line}});
      # printf(STDERR "Delete line %s '%s'\n", $deleted ? 'Y' : 'N', $+{line});
      if (!keys(%{$lines})) {
        # No lines left check so we can stop here.
        last;
      }
    }
  }
  close $fh;
}
######################################################################
# reviews incoming message and decides: approve, reject, keep
# in queue for human review
#
# Arguments: Newsgroup, From, Subject, Message, Dir
#
# RealSubject is the shorter subject from original posting
sub review_incoming_message { # Newsgroup, From, Subject, RealSubject, Message, Dir
  my $dir = pop( @_ );
  my $message = pop( @_ );
  my $real_subject = pop( @_ );
  my $subject = pop( @_ );
  my $from = pop( @_ );
  my $newsgroup = pop( @_ );

  if( &name_is_in_list( $from, "bad.posters.list" ) ) {
    &process_approval_decision( $subject, $newsgroup, $dir, "reject blocklist", "", "auto bad poster" );
    return;
  }

  if( &name_is_in_list( $real_subject, "bad.subjects.list" ) ) {
    &process_approval_decision( $subject, $newsgroup, $dir, "reject thread", "", "auto bad subject" );
    return;
  }

  if( &name_is_in_list( $message, "bad.words.list" ) ) {
    &process_approval_decision( $subject, $newsgroup, $dir, "reject charter", 
    "Your message has been autorejected because it appears to be off topic
    based on our filtering criteria. Like everything, filters do not
    always work perfectly and you can always appeal this decision.",
                                "auto bad word" );
    return;
  }

  my $warning_file = &article_file_name( $dir ) . "/stump-warning.txt";
  my $highlight_file = &article_file_name( $dir ) . "/stump-highlight.txt";
  my $match;

  $ignore_demo_mode = 1;

  if( $match = &name_is_in_list( $from, "watch.posters.list" ) ) {
    &append_to_file( $warning_file, "Warning: poster '$from' matches '$match' from the list of suspicious posters\n" );
print STDERR "Filing Article for review because poster '$from' matches '$match'\n";
    return; # file message
  }

  if( $match = &name_is_in_list( $real_subject, "watch.subjects.list" ) ) {
    &append_to_file( $warning_file, "Warning: subject '$real_subject' matches '$match' from the list of suspicious subjects\n" );
print STDERR "Filing Article for review because subject '$subject' matches '$match'\n";
    return; # file message
  }

  if( $match = &name_is_in_list( $message, "watch.words.list" ) ) {
    &append_to_file( $warning_file, "Warning: article matches '$match' from the list of suspicious words\n" );
print STDERR "Filing Article for review because article matches '$match'\n";
    return; # file message
  }

  my @matches = &name_is_in_list_unquoted( $message, $newsgroup, "watch.unquoted.words.list" );
  if( my $match = join(',', @matches) ) {
    &append_to_file( $warning_file, "Warning: article matches '$match' from the list of suspicious words outside a quote from an approved article.\n" );
print STDERR "Filing Article for review because article matches '$match' unquoted\n";
    &append_to_file( $highlight_file, join("\n", @matches));
    return; # file message
  }

  if( &name_is_in_list( $from, "good.posters.list" ) ) {
    &process_approval_decision( $subject, $newsgroup, $dir, "approve", "",
                                "auto good poster" );
    return;
  }

  if( &name_is_in_list( $real_subject, "good.subjects.list" ) ) {
    &process_approval_decision( $subject, $newsgroup, $dir, "approve", "",
                                "auto good subject" );
    return;
  }

  # if the message remains here, it is stored for human review.

}

1;
