if $local_part_suffix is +%ABBREV%-bounces
then
	seen deliver %LOGGROUPEMAILPREFIX%+%ABBREV%+log+bounces
	finish
endif

if $local_part_suffix is +%ABBREV%-noack
then
	unseen deliver %LOGGROUPEMAILPREFIX%+%ABBREV%+log+noack
	pipe "%BASEDIR%/stump/etc/modenv stump.pl processNoack.pl"
	finish
endif

if $local_part_suffix is +%ABBREV%-internal-webstump/%KEYSTUMP2WEB%
then
	unseen deliver %LOGGROUPEMAILPREFIX%+%ABBREV%+log+stump2webstump
	unseen pipe "%BASEDIR%/xlog/bin/record stump2webstump %GROUP%"
	pipe "%BASEDIR%/webstump/scripts/file-message.pl"
	finish
endif

if $local_part_suffix is +%ABBREV%-internal-approve/%KEYWEB2STUMP%
then
	unseen deliver %LOGGROUPEMAILPREFIX%+%ABBREV%+log+webstump2stump
	unseen pipe "%BASEDIR%/xlog/bin/record webstump2stump %GROUP%"
	pipe "%BASEDIR%/stump/etc/modenv stump.pl acceptFromMod.pl"
	seen finish
endif

if $local_part_suffix is +%ABBREV%-internal-log+mailout
then
	unseen deliver %LOGGROUPEMAILPREFIX%+%ABBREV%+log+mailout
	pipe "%BASEDIR%/xlog/bin/record %PUBREJOPT% mailout %GROUP%"
	finish
endif

if $local_part_suffix is +%ABBREV%-internal-reject-copy
then
	seen deliver %REJECTIONSLIST%
	finish
endif
