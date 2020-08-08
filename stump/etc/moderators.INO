#######################################################################
#
# This file contains a database of current moderators. Any moderator
# can be either in "active" or "inactive" status. (frequently the
# inactivbe status is called "vacation" :). The format of this
# file is: 
#
# email                             Active?      Mode
#
# (of course, with no leading "#" sign). Any line with the first
# character equal to # sign is ignored. 
#
# Flag 1 means that the moderator is active, flag 0 means that the 
# moderator is in vacation.
#
# Mode NO_ADVICE_LIST means that the moderator is not interested in the
# moderators-advice mailing list from isc.org. If you have not started
# receiving this list, do not worry -- you will find out whether you
# want to receive messages or not, later.
#
# Mode NOKOI means that the moderator is unable to read the upper part
# of the ascii table. Most likely it is NOT something that is of interest
# to you.
#
# EMPTY LINES ARE NOT ALLOWED!!!

%MODEMAIL%					0 NO_BOARD_LIST,NO_ADVICE_LIST
%OURUSER%+%ABBREV%-internal-webstump/%KEYSTUMP2WEB%@%DOMAIN%		1 NO_BOARD_LIST,NO_ADVICE_LIST
