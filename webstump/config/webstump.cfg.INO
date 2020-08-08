#
# This file contains the complete configuration for WebSTUMP 2.0.
#
# You have to define these variables:
#
# $supporter: email address of the person who supports this installation
#
# $base_address: base URL for webstump
#

###################################################################### WebSTUMP
# set it to your email address. Do NOT leave my address here!!!
$supporter = "%OURUSER%\@%DOMAIN%";

# set it to the URL for "wrapper" program. Usually should be something
# like http://www.provider.net/~username/cgi-bin/webstump-wrapper
# where webstump-wrapper is a symlink from your cgi-bin directory 
# to the wrapper executable.
$base_address = "%CGIBASEURL%/g.%ABBREV%/webstump";

# Should we use MIME extensions? Note that if you keep "yes" here, you
# have to install several Perl modules:
#
# MIME::Tools
# Convert::UU
#
# as well as everything that they in turn require.

$use_mime = "no"; # unless you plan to moderate picture newsgroups,
                  # set it to "no". Set it to "yes" (lowercase)
		  # if you actually want to use MIME and show pictures
		  # as pictures.


# Now THIS is the BASE address for WebSTUMP. It should point to 
# the directory called "webstump". It is used to acxcess images
# under "queues" directory.

$base_address_for_files = "%STATICFILESURL%/g.%ABBREV%";

# one of the possible locations for sendmail
@sendmail = ("/usr/lib/sendmail", "/usr/bin/sendmail", "/usr/sbin/sendmail" );

############################################################ GateKeeper

# posting gateway -- address for STUMP mail2news gateway.
# uncomment this line if you do not have a local spool dir (see next entry)
# $posting_gateway = "ichudov@stump.algebra.com";

# directory for spooling approved article. Comment thisline out if
# you do not have a program that regularly picks up files from there.
$posting_spool_dir = "%BASEDIR%/stump-post/spool";

##################################### do not modify anything below this line

$mod_log_access= '%MODLOGDOWNLOAD%' eq 'true' ? '2 download' :
                 '%MODLOGSEARCH%'   eq 'true' ? '1 search' :
                                                 0;

$STUMP_URL="http://www.algebra.com/~ichudov/stump";

$queues_dir = "$webstump_home/queues";
$request_method="post";

die "Directory $queues_dir does not exist! Check out 
$webstump_home/config/webstump.cfg, 
and define variable \$secret_queues_name
properly. "
	if( ! -d $queues_dir );


1;
