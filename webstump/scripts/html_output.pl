#
# This is a module with functions for HTML output.
#
# I separate it from the main STUMP stuff because these functions are
# bulky and not very interesting.
#
#

use POSIX;
use CGI qw/escapeHTML/;

sub begin_html {
  my $title = pop( @_ );
  print 
"Content-Type: text/html\n\n
<TITLE>$title</TITLE>
<BODY>
<H1>$title</H1>\n\n";

  if( &is_demo_mode ) {
    print "<B> You are operating in demonstration mode. User actions will have no effect.</B><HR>\n";
  }
  
}

sub end_html {
  print "\n<HR>Thank you for using <A HREF=$STUMP_URL>STUMP Robomoderator</A>.
<!-- <BR>
Click <A HREF=$base_address>here</A> to return to WebSTUMP. -->
";
}

# prints a link to help
# accepts topic id and topic name.
#
sub link_to_help {
  my $topic_name = pop( @_ );
  my $topic = pop( @_ );

  #&print_image( "help.gif", "" );

  print "<A HREF=$base_address?action=help&topic=$topic TARGET=new>Click here for help on $topic_name</A>\n";
}

#
# prints image and an alt text
#
sub print_image { # image_file, alt_text
  my $alt = pop( @_ );
  my $file = pop( @_ );

  print "<IMG SRC=$base_address_for_files/images/$file ALT=\"$alt\" ALIGN=BOTTOMP>\n";
}

# prints the welcome page and login screen.
sub html_welcome_page {
  &begin_html( "Welcome to WebSTUMP" );

  print 

"Welcome to WebSTUMP, the moderators' front end for <A
HREF=http://www.algebra.com/~ichudov/stump>STUMP</A> users -- USENET newsgroup
moderators. Only authorized users are allowed to log into this
program.

<HR>";

  my $motd_file = "$webstump_home/config/motd";

  if( -f $motd_file && -r $motd_file ){
    open( MOTD, $motd_file );
    print "<B>Message of the Day:</B><BR><PRE>\n";
    print while( <MOTD> );
    close( MOTD );
    print "</PRE><HR>\n";
  }

  print "
Newsgroups Status:<BR>
<TABLE BORDER=3>\n";

  for( sort @newsgroups_array ) {
    print "<TR><TD>";
    
    my $count = &get_article_count( $_ );

    print " <A HREF=$base_address?action=login_screen\&newsgroup=$_>$_</A>";
    &print_image( "smiley.gif", "" ) if $count;
    print "</TD>";


    print "<TD>$count messages in queue<BR></TD>";
#    print "<TD><A HREF=$base_address?action=init_request_newsgroup_creation\&newsgroup=$_>Request creation</A></TD>\n";
  }

  print "</TABLE>\n";
  print "<HR>Note: click on the newsgroup to login in as moderator. 
<!-- Click on 'Request Creation' to ask a sysadmin at a specific domain
to carry your newsgroup. -->\n<HR>
<A HREF=$base_address?action=admin_login>Click here to administer this WebSTUMP installation</A>
";
  &end_html;
}

# prints the login screen for newsgroup.
sub html_login_screen {
  my $newsgroup = $request{'newsgroup'} || &error( "newsgroup not defined" );

  my $count = &get_article_count( $newsgroup );


  if( $count ) {
    &begin_html( "$count articles in queue for $newsgroup" );
  } else {
    &begin_html( "Empty Queue for $newsgroup" );
  }

  print
" Welcome to the Moderation  Center for  $newsgroup. Please bookmark
this page. <HR>";


  my $color = "", $end_color = "";

  if( $count ) {
    $color = "<font color=red>";
    $end_color = "<font color=black>";
  }

  print 
"<FORM METHOD=$request_method action=$base_address>
 <INPUT NAME=action VALUE=moderation_screen TYPE=hidden>
  $color ($count ";
  
  &print_image( "new_tiny2.gif", "new" ) if $count;

  print " articles available)<BR> $end_color
 Login: <INPUT NAME=moderator VALUE=\"\" SIZE=20>
 <BR>
 Password: <INPUT NAME=password TYPE=password VALUE=\"\" SIZE=20>
 <BR>
 <INPUT TYPE=submit VALUE=\"Proceed with Login\">
 <INPUT TYPE=reset VALUE=\"Reset\">
 <INPUT NAME=newsgroup VALUE=\"$newsgroup\" TYPE=hidden>
 </FORM><HR>
  Please log into $newsgroup. You can only log in if you know your login id
  and know the secret password. You should not give your password to any
  unauthorized user. Your login id and password are NOT case sentitive, 
  which means that,
  for example, \"xyzzy\" and \"XyZZY\" are equally valid.<P>
";

#  print "
# Log in as \"admin\" if you want to 
#<UL>
#  <LI> edit filtering lists.";
#
#  &link_to_help( "filter-lists", "Filter Lists" );
#
#  print "
#  <LI> add/delete users or change their passwords.
#  <LI> First Time Users: You have to log in as admin and add a moderator user
#  who will be able to moderate the newsgroup. Then log in again as that
#  user. If you are a new user, you have to have your admin password assigned to
#  you by the administrator.
#</UL>
#
#";
  &end_html;
}

# prints the login screen for newsgroup.
sub admin_login_screen {
  &begin_html( "Administrative login" );

  print
"
Attention: this page is only for the maintainer of the whole WebSTUMP
installation. Please return to the main page if you are not the maintainer
of this installation. <HR>
";

  print 
"<FORM METHOD=$request_method action=$base_address>
 <INPUT NAME=action VALUE=webstump_admin_screen TYPE=hidden>
 Password: <INPUT NAME=password TYPE=password VALUE=\"\" SIZE=20>
 <BR>
 <INPUT TYPE=submit VALUE=\"Proceed with Login\">
 <INPUT TYPE=reset VALUE=\"Reset\">
 </FORM>
";

  &end_html;
}

# main moderation page -- old version
sub html_moderate_article {
  my $newsgroup = &required_parameter( 'newsgroup' );
  my $moderator = $request{'moderator'};
  my $password = $request{'password'};
  my $file = shift @_ || &required_parameter('file');

  &begin_html( "Main Moderation Screen: $newsgroup" );
  print "<HR>\n";

  &read_rejection_reasons;

  my $dir = "$queues_dir/$newsgroup";

  if( -d "$dir/$file" && open( TEXT_FILES, "$dir/$file/text.files.lst" ) ) {

      print "<HR>\n" if &print_article_warning( $file );

      print "<PRE>\n";
      my $filename;
      my $inhead= 1;
      while( $filename = <TEXT_FILES> ) {
        open( ARTICLE, "$dir/$file/$filename" );
        while( <ARTICLE> ) {
	  $embolden= m/^(?:from|subject)\s*\:/i;
	  s/\&/&amp;/g;
          s/</&lt;/g;
          s/>/&gt;/g;
	  $_= "<strong>$_</strong>" if $embolden;
          print;
	  $inhead= 0 unless m/\S/;
        }
        close( ARTICLE );
	$inhead= 0;
      }

      print "\n</PRE>\n\n";

      &print_images( $newsgroup, "$dir/$file", $file);

  } else {
    print "This message ($dir/$file) no longer exists -- maybe it was " .
          "approved or rejected by another moderator.";
  }

      print "<HR>
<FORM NAME=decision METHOD=$request_method action=$base_address>
";

  print "
<INPUT NAME=action VALUE=approval_decision TYPE=hidden>";
  &html_print_credentials;
  print "<SELECT NAME=\"decision_$file\">
<OPTION VALUE=\"approve\">Approve</OPTION>
<OPTION VALUE=\"leave\" SELECTED>Put to back of queue</OPTION>
<OPTION VALUE=\"consider\">Back of queue, adding mark requesting further consideration</OPTION>
";

      foreach (sort(keys %rejection_reasons)) {
        print "<OPTION VALUE=\"reject $_\">Reject -- $rejection_reasons{$_}</OPTION>\n";
      }

      print "<BR>";

      print "</SELECT><BR> Comment: <INPUT NAME=comment VALUE=\"\" SIZE=80><BR>";

  print "<BR>
<INPUT TYPE=radio NAME=poster_decision VALUE=nothing CHECKED>Don't change poster's status</INPUT>
<INPUT TYPE=radio NAME=poster_decision VALUE=preapprove 
>Preapprove poster</INPUT>
<INPUT TYPE=radio NAME=poster_decision VALUE=ban 
  ONCLICK=\"alert( 'Banning a poster is a controversial practice'); \"
> Ban All Posts by this Person (Careful!)</INPUT>
<BR><BR>
<INPUT TYPE=radio NAME=thread_decision VALUE=nothing CHECKED>Don't change thread's status</INPUT>
<!-- <INPUT TYPE=radio NAME=thread_decision VALUE=preapprove>Preapprove thread, by Subject:</INPUT> -->
<BR>

<INPUT TYPE=radio NAME=thread_decision VALUE=ban
  ONCLICK=\"alert( 'Banning a thread is a controversial practice'); \"
>Ban Entire Thread By Subject (Careful!)</INPUT>
<INPUT TYPE=radio NAME=thread_decision VALUE=watch>Put Entire thread on a Watch, by Subject:</INPUT>

<BR><BR>
<I>
NOTE: Decisions to ban and preapprove posters and threads can be reversed by 
logging in as \"admin\" and editing respective lists of preapproved
and banned threads  and posters.
";

  &link_to_help( "filter-lists", "automatic filtering and filter lists, blacklisting and preapproved threads." );

  print "Be really careful about blacklisting of everyone except spammers.</I><BR><BR>

<INPUT TYPE=radio NAME=next_screen VALUE=single CHECKED> 
	Review ONE article in next screen
<INPUT TYPE=radio NAME=next_screen VALUE=multiple> 
	Review multiple articles in next screen
<HR>

<INPUT TYPE=submit VALUE=\"Submit\">
<INPUT TYPE=submit NAME=skip_submit VALUE=\"Skip\">
<INPUT TYPE=reset VALUE=\"Reset\">
";

      print "</FORM>\n\n";
  print "<BR><A HREF=$base_address?action=change_password&newsgroup=$newsgroup&" .
        "moderator=$moderator&password=$password>Change Password</A>";

  closedir( QUEUE );
  &end_html;
}

# WebSTUMP administrative screen
sub webstump_admin_screen {

  &verify_admin_password;

  my $password = $request{'password'};

  &begin_html( "WebSTUMP Administration" );
  print "
<FORM METHOD=$request_method action=$base_address>
<INPUT NAME=action VALUE=admin_add_newsgroup TYPE=hidden>
<INPUT NAME=password VALUE=\"$password\" TYPE=hidden>\n";


  print "
<HR>
Create a new newsgroup on the server:<BR>

Newsgroup:<BR> <INPUT NAME=newsgroup_name VALUE=\"\" SIZE=50><BR>
Address to send approved/rejected messages <BR>
	<INPUT NAME=newsgroup_approved_address VALUE=\"\" SIZE=30><BR>
Admin Password For this group:<BR> <INPUT NAME=newsgroup_password VALUE=\"\" SIZE=10><BR>
<INPUT TYPE=submit VALUE=\"Submit\">
<INPUT TYPE=reset VALUE=\"Reset\"><HR>
";

      print "</FORM>\n\n<PRE>\n";

  &end_html;
}

# WebSTUMP "add newsgroup" function
sub admin_add_newsgroup {

  &verify_admin_password;

  my $newsgroup = &required_parameter( 'newsgroup_name' );

  $newsgroup =~ s/\///g;
  $newsgroup = &untaint( $newsgroup );

  my $address = &required_parameter( 'newsgroup_approved_address' );
  my $password = &required_parameter( 'newsgroup_password' );

  &user_error( "Newsgroup $newsgroup already exists" )
    if defined $newsgroups_index{$newsgroup};

  &user_error( "Password may only contain letters and digits" )
    if( ! ($password =~ /^[a-zA-Z0-9]+$/ ) );

  &begin_html( "WebSTUMP Administration: Newsgroup created" );

  print "<PRE>\n\n";

  print "Adding $newsgroup to $webstump_home/config/newsgroups.lst...";
  mkdir "$webstump_home/queues/$newsgroup", 0755;
  print " done.\n";
  
  $dir = "$webstump_home/config/newsgroups/$newsgroup";
  
  print "Creating $dir...";
  mkdir $dir, 0755;
  print " done.\n";
  
  print "Creating files in $dir...";
  
  &append_to_file( "$dir/address.txt", "$address\n" );
  &append_to_file( "$dir/moderators", "ADMIN \U$password\n" );
  &append_to_file( "$dir/rejection-reasons",
"offtopic::a blatantly offtopic article, spam
harassing::message of harassing content
charter::message poorly formatted
" );
  print " done.\n";


  print "</PRE>\n";

  &end_html;
}

#
#
sub print_images {
  $web_subdir = pop( @_ );
  $subdir = pop( @_ );
  $newsgroup = pop( @_ );

  opendir( SUBDIR, $subdir );

  my $count = 0;

  while( $_ = readdir( SUBDIR ) ) {
    my $file = "$subdir/$_";
    next if( ! -f $file || ! -r $file );
    my $extension = $file;
    $extension =~ s/^.*\.//;
    $extension = "\L$extension";
    
    if( $extension eq "gif" || $extension eq "jpg" || $extension eq "jpeg" ) {
      print "<CENTER> <IMG SRC=$base_address_for_files/queues/$newsgroup/$web_subdir/$_></CENTER><HR>\n";
      $count++;
    } else {
      my $filename = $_;
      $filename =~ s/^.*\///;
      next if $filename eq "skeleton.skeleton" 
	      || $filename eq "headers.txt"
              || $filename eq "full_message.txt"
	      || $filename eq "text.files.lst"
	      || $filename eq "stump-prolog.txt"
	      || $filename eq "stump-warning.txt"
	      || $filename =~ /msg-.*\.doc/;
      
      &print_image( "no_image.gif", "security warning" );
      print "<B>Non-image attachment:</B><CODE>$filename</CODE> NOT SHOWN for security reasons.<BR>\n";
    }
  }
  return $count;
}

# prints warning if there is warning stored about the article
sub print_article_warning { # short-subdir
  my $file = pop( @_ );

  my $warning_file = &article_file_name( $file ) . "/stump-warning.txt";

  if( -r $warning_file ) {
    open( WARNING, $warning_file );
    while ($warning = <WARNING>) {
	next unless $warning =~ m/\S/;
	$warning =~ s/\&/&amp;/g;
	$warning =~ s/</&lt;/g;
	$warning =~ s/>/&gt;/g;
	&print_image( "star.gif", "warning" );
	print "<FONT COLOR=red>$warning</FONT><br>\n";
    }
    close( WARNING );
    return 1;
  }

  return 0;
}

sub get_queue_list ($) {
    my ($newsgroup) = @_;
    my $dir = "$queues_dir/$newsgroup";
    my %sortkeys;

    opendir(QUEUED, $dir) or &error("could not open directory $dir");

    for (;;) {
	$!=0;
	my $subdir= scalar readdir(QUEUED);
	last unless defined $subdir;

	my $subpath= "$dir/$subdir";
	next if $subdir =~ /^\.+/;
	next unless -d $subpath;
	my $sortkey;
	if (!stat "$subpath/stump-warning.txt") {
	    $!==&ENOENT or die "$subpath $!";
	    $sortkey= 0;
	} else {
	    $sortkey= (stat _)[9];
	}
	$sortkeys{$subdir}= $sortkey;
    }
    closedir( QUEUED );
    my @articles= sort { $sortkeys{$a} <=> $sortkeys{$b} } keys %sortkeys;
    return ($dir, @articles);
}

# main moderation page
sub html_moderation_screen {
  my $newsgroup = &required_parameter( 'newsgroup' );
  my $moderator = $request{'moderator'};
  my $password = $request{'password'};


  if( $request{'next_screen'} eq 'single' ) {
    # we show a single article if the user so requested.
    # just get the first article from the queue if any, otherwise show 
    # an empty main screen.
   
    my ($dir, @articles)= get_queue_list($newsgroup);

    my $i;
    for ($i=0; $i<@articles; $i++) {
	my $subdir= shift @articles;
	push @articles, $subdir;
	last if $request{"decision_$subdir"};
    }

    while( $subdir = shift @articles ) {
      if( -d "$dir/$subdir" && !($subdir =~ /^\.+/) 
          && open( PROLOG, "$dir/$subdir/stump-prolog.txt" ) ) {
	      &html_moderate_article( $subdir );
	      return;
      }
    }
  } else {
	# otherwise just show the moderator an empty main screen.
  }
    
  &begin_html( "Main Moderation Screen: $newsgroup" );
  print "Welcome to the main moderation screen. Its main purpose is to 
help you process most messages extremely quickly. For every message, it 
presents you who sent it, as well as the first three non-blank lines.
For those messages where the decision is obvious, simply select your
decision (approve/reject etc) and click submit. For those messages which
you would like to review in more details, do not select anything and
use Review/Comment function from this screen or from a subsequent screen.
Remember that if you do not make any decision, the article would stay in the
queue.\n";

  &read_rejection_reasons;

  my ($dir, @articles)= get_queue_list($newsgroup);

  print "
  <FORM METHOD=$request_method action=$base_address>
  <INPUT NAME=action VALUE=approval_decision TYPE=hidden>";
    &html_print_credentials;
  
  my $file, $subject = "No Subject", $from = "From nobody";
  my $form_not_empty = "";
  my $article_count = 0;
  my $warning = "";
  while( ($subdir = shift @articles) && $article_count++ < 40 ) {
    $file=$subdir;
    if( -d "$dir/$subdir" && !($subdir =~ /^\.+/) 
        && open( PROLOG, "$dir/$subdir/stump-prolog.txt" ) ) {
        while( <PROLOG> ) {
          chop;
          if( /^Real-Subject: /i ) {
	    s/\&/&amp;/g;
            s/</&lt;/g;
            s/>/&gt;/g;
            s/^Real-Subject: //g;
            $subject = substr( $_, 0, 50 );
          } elsif( /^From: /i ){
	    s/\&/&amp;/g;
            s/</&lt;/g;
            s/>/&gt;/g;
            $from = substr( $_, 0, 50 );
          } elsif( /^$/ ) {
            last;
          }
        }

        print "<HR><B>$from: $subject</B>(";
        print "<A HREF=$base_address?action=moderate_article&newsgroup=$newsgroup&" .
              "moderator=$moderator&password=$password&file=$subdir>Review/Comment/Preapprove</A>)<BR>\n";
        print "<INPUT TYPE=radio NAME=\"decision_$file\" VALUE=approve>Approve\n";
        print "<INPUT TYPE=radio NAME=\"decision_$file\" VALUE=skip>Leave\n";
        print "<INPUT TYPE=radio NAME=\"decision_$file\" VALUE=leave>Back of queue\n";
        foreach (@short_rejection_reasons) {
          print "<INPUT TYPE=radio NAME=\"decision_$file\" VALUE=\"reject $_\">Reject \u$_\n";
        }

	print "<BR>\n";

        &print_article_warning( $file );

        print "<PRE>\n";

        my $i = 0;

        while( ($_ = <PROLOG>) && $i < 5 ) {
            chop;
	    next if m/^\>/;
	    s/\&/&amp;/g;
            s/</&lt;/g;
            s/>/&gt;/g;
            if( $_ ne "" ) {
              print "]  " . substr( $_, 0, 75 ) . "\n";
              $i++;
            }
        }

        print "</PRE>";
        $form_not_empty = "yes";
        close( PROLOG );
        $article_count += &print_images( $newsgroup, "$dir/$subdir", $subdir );
    }
  }

  if( $form_not_empty ) {
    print "<HR> <INPUT TYPE=submit VALUE=Submit>
<INPUT TYPE=reset VALUE=Reset>
";
  } else {
    print "
<HR>
No articles present in the queue
<INPUT TYPE=submit VALUE=Refresh>
<HR>\n";
  }

  print "<A HREF=$base_address?action=change_password&newsgroup=$newsgroup&" .
        "moderator=$moderator&password=$password>Change Password</A>";

  print "</FORM>\n\n";

  print "<FORM METHOD=$request_method action=$base_address>";
  &html_print_credentials;
  print "<INPUT NAME=action VALUE=moderator_admin TYPE=hidden>
         <INPUT TYPE=submit VALUE=\"Management\">
         </FORM>";

  &end_html;
}

# prints hidden fields -- credentials
sub html_print_credentials {
  my $newsgroup = $request{'newsgroup'};
  my $moderator = $request{'moderator'};
  my $password = $request{'password'};

  print "
 <INPUT NAME=newsgroup VALUE=\"$newsgroup\" TYPE=hidden>
 <INPUT NAME=moderator VALUE=\"$moderator\" TYPE=hidden>
 <INPUT NAME=password VALUE=\"$password\" TYPE=hidden>\n";
}

# logs

sub scanlogs ($$$) {
    my ($forwards, $gotr, $callback) = @_;
    my $dir= "$webstump_home/..";
    opendir LOGSDIR, "$dir" or die "$dir $!";
    my $num= sub {
        local ($_) = @_;
        return $forwards * (
            m/^errs$/ ? 1 :
            m/^errs\.(\d+)(?:\.gz)?$/ ? ($1+2) :
            0
                           );
    };
    foreach my $leaf (
                      sort { $num->($a) <=> $num->($b) }
	              grep { $num->($_) }
                      readdir LOGSDIR
                      ) {
        my $file= "$dir/$leaf";
        if ($file =~ m/\/errs.*\.gz$/) {
            open LOGFILE, "zcat $file | tac |" or die "zcat $file | tac $!";
        } elsif ($file =~ /errs/) {
            open LOGFILE, "tac $file |" or die "tac $file $!";
        } else {
	    die "Unexpected filename in scanlogs: $file";
	}
        while (<LOGFILE>) {
            my $tgot= $callback->();
            next unless $tgot;
            $$gotr= $tgot if $tgot > $$gotr;
            last if $tgot > 1;
        }
        $!=0; $?=0; close LOGFILE or die "$file $? $!";
        last if $$gotr > 1;
    }
    closedir LOGSDIR or die "$dir $!";
}        

sub html_search_logs {
  &begin_html("Search logs for $request{'newsgroup'}");
  my $reqnum;
  my $forwards=1;
  my $min= 9;
  if ($request{'download_logs'}) {
      print "<h2>Complete log download</h2>\n";
      $min= 2;
  } elsif ($request{'messagenum'} =~ m/^\s*(\d+)\s*$/) {
      $reqnum= $1;
      $forwards= -1;
      $min= 1;
      print "<h2>Log entry for single message $reqnum</h2>\n";
  } else {
      print "<h2>Log lookup - bad reference</h2>
Please supply the numerical reference as found in the \"recent activity\"
log or message headers.  Reference numbers consist entirely of digits,
and are often quoted in message headers in [square brackets].<p>
        ";
      &end_html;
      return;
  }
  if ($mod_log_access < $min) {
      print "Not permitted [$mod_log_access<$min].  Consult administrator.\n";
      &end_html;
      return;
  }

  my $sofar= 0;
  &scanlogs($forwards, \$sofar, sub {
      return 0 unless chomp;
      return 0 unless m/^DECISION: /;
      my @vals = split / \| /, $';
      return 0 unless @vals >= 5;
      my $subj= pop @vals;
      my ($group,$dir,$act,$reason,$timet) = @vals;
      my $date= $timet ? (strftime "%Y-%m-%d %H:%M:%S GMT", gmtime $timet)
          : "(unknown)";
      return 0 unless $group eq $request{'newsgroup'};
      return 0 unless $subj =~ m,/(\d+)$,;
      my $treqnum= $1;
      return 0 if defined($reqnum) and $treqnum ne $reqnum;
      print "<table rules=all><tr><th>Date<th>Reference<th>Disposal<th>Reason</tr>\n"
          unless $sofar;
      print "<tr>", (map { "<td>".escapeHTML($_) }
                     $date,$treqnum,$act,$reason);
      print "</tr>\n";
      return defined($reqnum) ? 2 : 1;
  });
  if ($sofar) {
      print "</table>" if $sofar;
      print "\n";
  } else {
      print "Reference not found.".
          "  (Perhaps message has expired, or is still in the queue?)";
  }
  &end_html;
}

# newsgroup admin page
sub html_newsgroup_management {
  &begin_html( "Administer $request{'newsgroup'}" );

  print "All usernames and passwords are not case sensitive.\n";
  print "<HR>Use this form to add new moderators or change passwords:<BR>
 <FORM METHOD=$request_method action=$base_address>
 <INPUT NAME=action VALUE=add_user TYPE=hidden>";
  &html_print_credentials;
  print "
 Username: <INPUT NAME=user VALUE=\"\" SIZE=20>
 <BR>
 Password: <INPUT NAME=new_password VALUE=\"\" SIZE=20>
 <BR>
 <INPUT TYPE=submit VALUE=\"Add/Change\">
 <INPUT TYPE=reset VALUE=Reset>
 </FORM>
";

  print "<HR>Use this form to delete moderators:<BR>
 <FORM METHOD=$request_method action=$base_address>
 <INPUT NAME=action VALUE=delete_user TYPE=hidden>";
  &html_print_credentials;
  print "
 Username: <INPUT NAME=user VALUE=\"\" SIZE=20>
 <BR>
 <INPUT TYPE=submit VALUE=\"Delete Moderator\">
 <INPUT TYPE=reset VALUE=Reset>
 </FORM><HR>

 <FORM METHOD=$request_method action=$base_address>
 <INPUT NAME=action VALUE=edit_list TYPE=hidden>";
  &html_print_credentials;
  print "
  Configuration List: <SELECT NAME=list_to_edit>

    <OPTION VALUE=good.posters.list>Good Posters List
    <OPTION VALUE=watch.posters.list>Suspicious Posters List
    <OPTION VALUE=bad.posters.list>Banned Posters List
    <OPTION VALUE=good.subjects.list>Good Subjects List
    <OPTION VALUE=watch.subjects.list>Suspicious Subjects List
    <OPTION VALUE=bad.subjects.list>Banned Subjects List
    <OPTION VALUE=watch.words.list>Suspicious Words List
    <OPTION VALUE=watch.unquoted.words.list>Suspicious Unquoted Words List
    <OPTION VALUE=bad.words.list>Banned Words List

  </SELECT>
  <INPUT TYPE=submit VALUE=\"Edit\">
  <INPUT TYPE=reset VALUE=Reset>";

  &link_to_help( "filter-lists", "filtering lists" );

  print "</FORM><HR>";

  if ($mod_log_access) {
      print "<form>
        Use this form to search logs of past moderation decisions:
        <br>
        <form method=$request_method action=$base_address>
        <input name=action value=search_logs type=hidden>";

      &html_print_credentials;

      print "
        Reference number: <input name=messagenum size=30>
        <input type=submit value=\"Lookup\">";

      print "
        <input type=submit value=\"Download all logs\" name=\"download_logs\">"
        if $mod_log_access >= 2;

      print "</form><hr>\n";
  }

  print "

  List of current moderators:<P>

  <UL>\n";

  foreach (keys %moderators) {
      print "<LI> $_\n";
  }

  print "</UL>\n";

  &end_html;
}


# edit config list
sub edit_configuration_list {

  my $list_to_edit = &required_parameter( 'list_to_edit' );

  $list_to_edit = &check_config_list( $list_to_edit );

  my $list_file = &full_config_file_name( $list_to_edit );

  my $list_content = "";

  if( open( LIST, $list_file ) ) {
    $list_content .= $_ while( <LIST> );
    close( LIST );
  }

  $list_content =~ s/\&/&amp;/g;
  $list_content =~ s/</&lt;/g;
  $list_content =~ s/>/&gt/g;

  &begin_html( "Edit $list_to_edit" );

  print
" <FORM METHOD=$request_method action=$base_address>
 <INPUT NAME=action VALUE=set_config_list TYPE=hidden>
 <INPUT NAME=list_to_edit VALUE=$list_to_edit TYPE=hidden>";
  &html_print_credentials;
  &link_to_help( $list_to_edit, "$list_to_edit" );
  print "
 Edit this list: <HR>
<TEXTAREA NAME=list rows=20 COLS=50>
$list_content</TEXTAREA>

 <BR>
 <INPUT TYPE=submit VALUE=\"Set\">
 </FORM>
";

  &end_html;
}

# password change page
sub html_change_password{
  &begin_html( "Change Password" );

  print "All usernames and passwords are not case sensitive.\n";
  print "<HR>Use this form to change your password:<BR>
 <FORM METHOD=$request_method action=$base_address>
 <INPUT NAME=action VALUE=validate_change_password TYPE=hidden>";
  &html_print_credentials;
  print "
 <BR>
 New Password: <INPUT NAME=new_password VALUE=\"\" SIZE=20>
 <BR>
 <INPUT TYPE=submit VALUE=Submit>
 <INPUT TYPE=reset VALUE=Reset>
 </FORM>
";

  &end_html;
}


# newsgroup creation form
sub init_request_newsgroup_creation{
  my $newsgroup = &required_parameter( 'newsgroup' );

  &begin_html( "Request Creation of $newsgroup" );

  print "This page helps you ask the system administrator of your domain
to create <B>$newsgroup</B> on your server. Type in your domain name and
click SUBMIT. An email will be sent to news\@domain and usenet\@domain
and postmaster\@domain
asking them to create your newsgroup. Please do NOT abuse this system.
NOTE: You can give the URL of this page to your group readers so that 
they could request creation of their newsgroups by themselves.\n";

  print "<HR>
 <FORM METHOD=$request_method action=$base_address>
 <INPUT NAME=action VALUE=complete_newsgroup_creation_request TYPE=hidden>\n";
  &html_print_credentials;
  print "
 <BR>
 Domain Name ONLY: <INPUT NAME=domain_name VALUE=\"\" SIZE=40>
 <BR>
 <INPUT TYPE=submit VALUE=Submit>
 <INPUT TYPE=reset VALUE=Reset>
 </FORM>
";

  &end_html;
}


# newsgroup creation completion
sub complete_newsgroup_creation_request{
  my $newsgroup = &required_parameter( 'newsgroup' );
  my $domain_name = &required_parameter( 'domain_name' );

  if( !($domain_name =~ /(^[a-zA-Z0-9\.-_]+$)/) ) {
    &user_error( "invalid domain name" );
  }

  $domain_name = $1;


  my $request = "To: news\@$domain_name, usenet\@$domain_name, postmaster\@$domain_name
Subject: Please create $newsgroup (Moderated)
From: devnull\@algebra.com ($newsgroup Moderator)
Organization: stump.algebra.com

Dear News Administrator:

A user of $domain_name has requested that you create a newsgroup

	$newsgroup (Moderated) 

on your server. $newsgroup
is a legitimately created moderated newsgroup that is available worldwide.

Thank you very much for your help and cooperation.

Sincerely,

	- Moderator of $newsgroup.

";

  &email_message( $request, "news\@$domain_name" );
  &email_message( $request, "usenet\@$domain_name" );
  &email_message( $request, "postmaster\@$domain_name" );

  &begin_html( "Request to create $newsgroup sent" );

  print "The following request has been sent:<HR><PRE>\n";

  print "$request</PRE>\n";

  &end_html;
}

# displays help
sub display_help {
  my $topic_name = &required_parameter( "topic" );

  $topic_name =~ s/\///g;
  $topic_name =~ s/\.\.//g;
  $topic_name = &untaint( $topic_name );

  my $file = "$webstump_home/doc/help/$topic_name.html";

  &error( "Topic $topic_name not found in $file." ) 
	if ! -r $file;

  open( FILE, "$file" );
  my $help = "";
  $help .= $_ while( <FILE> );
  close( FILE );

  $help =~ s/##/$base_address?action=help&topic=/g;

  &begin_html( "$topic_name" );

  print $help;

  print "<HR>";
}







1;
