#!/bin/bash

set -e
set -o pipefail

TMPFILE=$TMP/reply.$$

cat > $TMPFILE

(
  formail -rt -I "Reply-To: $NOACK" \
        -I "X-Webstump-Event: ack" \
	$MAILOUT_RECVACK_FORMAIL_ARGS \
     < $TMPFILE
  cat <<_EOB_
Hello,

This is an automatic acknowledgement that your message has been RECEIVED
by the robomoderation program for newsgroup $NEWSGROUP. 

This message has been queued and will be reviewed by the moderators
as necessary, and you will receive another email when a decision
about your article has been made.

If you do not want to receive automatic acknowledgments in the future,
simply reply to this message, QUOTING ITS TEXT IN FULL.

For details of the moderation arrangements see
    %GROUPURL%

_EOB_

  sanitise_and_quote_email \
      < $TMPFILE

) | sendmail -t -f $MUNGED_ADDRESS

rm $TMPFILE
