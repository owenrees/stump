#
# install with
#  ssh webstump@chiark live-mtm/install-aggregates
#
#m h  d m dow
50 7  * * 1	savelog -p live-%ABBREV%/xlog/log/%GROUP%/event.log
51 7  12 * *	savelog -p live-%ABBREV%/errs
52 7  12 * *	savelog -p live-%ABBREV%/webstump/log/webstump.log
53 7  * * 1	find live-%ABBREV%/xlog/log/%GROUP%/public -mtime +14 -type f -print0 | xargs -r0 rm --
51     *  * * *	cd %BASEDIR% && probes/modrelays-probe all
3-59/5 *  * * *	cd %BASEDIR% && probes/modrelays-probe report
