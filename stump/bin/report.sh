#!/bin/bash
# posts a nice report
#
# $Id: report.sh,v 1.2 2007/05/03 23:47:49 rram Exp $
# Modified to work with GPG

set -e
set -o pipefail

TODAY="`date`"
DATE6="`date +%y%m%d`"

LOGFILE="$HOME/Mail/from"
LOGFILE_ARCHIVED="$MNG_ROOT/archive/old/from.$DATE6"

Report() {
  echo Subject: $NEWSGROUP report for $TODAY
  echo Newsgroups: $NEWSGROUP
  echo To: $SUBMIT
  echo From: $ADMIN
  echo Reply-To: $ADMIN
  echo Organization: CrYpToRoBoMoDeRaToR CaBaL
  echo ""

(
  echo Subject: $NEWSGROUP report for $TODAY
  echo Newsgroups: $NEWSGROUP
  echo Date: $TODAY
  echo ""

cat << _EOB_
This is an automated report about activity of our newsgroup
$NEWSGROUP. It covers period between the 
previous report and the current one, ending 
on $TODAY.

Note that we do not report the number of articles cancelled
after they got approved, because the cancellations are done
manually. Typically messages get cancelled by requests of
posters themselves.

Lastly, the statistics below are skewed towards higher numbers because
there are always some test messages from moderators themselves who
approve and reject them to make sure that our robomoderator functions
properly.

_EOB_

  stump-report.pl $LOGFILE
) | stump-pgp --clearsign --textmode --armor --batch --user $PMUSER_APPROVAL --passphrase "$PMPASSWORD" 2>/dev/null
}

Report | sendmail -t

mv $LOGFILE $LOGFILE_ARCHIVED
gzip -9 $LOGFILE_ARCHIVED &
