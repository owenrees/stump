if $local_part_suffix is +%ABBREV%+%KEYSUBMIT%
or $local_part_suffix is +%ABBREV%+test-submission
then
	unseen pipe "mail -s submission %LOGGROUPEMAILPREFIX%+%ABBREV%+log+submissions"
	if $header_X-WebSTUMP-Relay-Probe: contains %GROUP% then
		pipe "%BASEDIR%/probes/modrelays-probe received %BASEDIR%"
		finish
	endif
	unseen pipe "%BASEDIR%/xlog/bin/record submission %GROUP%"
	pipe "%BASEDIR%/stump/etc/modenv stump.pl submission.pl"
	finish
endif

