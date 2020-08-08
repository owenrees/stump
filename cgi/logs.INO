#!/bin/bash
set -e
cd %BASEDIR%/xlog/log
exec ../bin/report %LOGREPORTOPTS% %GROUP% %STATICFILESURL%/g.%ABBREV%/messages "$@"
