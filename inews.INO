#!/bin/sh
set -e

export NNTPSERVER=nnrp.chiark.greenend.org.uk
export NNTPAUTH='md5cookie1way chiark'

trap 'rm -f "$tf"' 0

tf=`mktemp`

sed '${ /^$/d }' >$tf

set +e
output=`
	set -e
	exec 2>&1
	if [ x%DIVERTPOSTINGS% = x ]; then
		perl -pe '
			next unless ($.==1)../^$/;
 s/^(?:X-Trace|NNTP-Posting-(?:Date|Host)|X-Complaints-To|Injection-Info)/X-$&/;
		' $tf | inews -h -Q -R
	else
		(set -e
		 echo "Newsgroups: %DIVERTPOSTINGS%"
		 sed 's/^Newsgroups:/X-Would-Newsgroups:/' $tf) | inews -h
	fi
`
rc=$?
set -e

if [ $rc = 0 ]
then
	echo 'posted ok!'
 	%BASEDIR%/xlog/bin/record posted %GROUP% <$tf
 	exit 0
fi

(
	printf "Errors: %s" "$output"
	echo
	echo ======================
	cat $tf
) | mail -s "lost moderated newsgroup submission %ABBREV%" webstump
