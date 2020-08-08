# Please check if all the paths in PATH are reachable, remove the ones that
# are not.

SCRM_ROOT=$HOME/live-%ABBREV%

MAILDIR=$HOME/Mail	# You'd better make sure it exists
DEFAULT=$MAILDIR/mbox

# VERBOSE=ON
LOGFILE=$MAILDIR/approved.log
LOCKFILE=$HOME/.lockmail

:0:
$SCRM_ROOT/archive/approved
