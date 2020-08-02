#!/bin/bash

set -e
set -o pipefail

if [ $# != 1 ]; then
	echo >&2 "wrong # args to $0: $*"
	exit 1
fi
input="$1"

(
  formail <"$input" -brt -I "Reply-To: $NOACK"	\
	        -I "X-Webstump-Event: approve"	\
		$MAILOUT_ACCEPTACK_FORMAIL_ARGS
  cat <<_EOB_
Hello,

$EXPLANATION

This is an automatic notification that your message has been APPROVED
for posting to moderated newsgroup $NEWSGROUP. 

For details of the moderation arrangements see
    %GROUPURL%

If you do not want to receive automatic acknowledgments in the future,
simply reply to this message, QUOTING ITS TEXT IN FULL.

_EOB_

  sanitise_and_quote_email \
     $@

) | sendmail -t -f $MUNGED_ADDRESS
