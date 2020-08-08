#!/bin/bash
###
#
# MAIN CONFIGURATION FILE
#
# ### Administrators of STUMP robomoderator systems:
#
# set environment variables according to config of your site. 
# this script is normally invoked from procmail, as a wrapper
# to real moderation scripts. Follow the instructions.
#

set -e

umask 007

#######################################################################
# this is the root directory where moderation software & config
# resides. Make sure that sendmail is in the PATH.
# (most likely it is in /usr/lib/sendmail).
#

MNG_ROOT=%BASEDIR%/stump
exec >>%BASEDIR%/errs 2>&1

printf "============ %s " "$*"
date

export MNG_ROOT BASEDIR

# Add bin and local/bin to PATH
PATH=$MNG_ROOT/bin:$MNG_ROOT/local/bin:$MNG_ROOT/etc:$PATH:/usr/sbin
PATH=$PATH:/usr/local/bin:/bin:/usr/bin:/usr/sbin:$HOME/bin
export PATH

#######################################################################
# Name of moderated group. Put the name of your group in here.
#

NEWSGROUP="%GROUP%"; export NEWSGROUP

#######################################################################
# Email handling and mangling

MAILOUT_RECVACK_FORMAIL_ARGS='
	-I Bcc:%OURUSER%+%ABBREV%-internal-log+mailout@%DOMAIN%
'
MAILOUT_ACCEPTACK_FORMAIL_ARGS='
	-I Bcc:%OURUSER%+%ABBREV%-internal-log+mailout@%DOMAIN%
'
MAILOUT_REJECT_FORMAIL_ARGS='
	-I Bcc:%OURUSER%+%ABBREV%-internal-log+mailout@%DOMAIN%
	-I Bcc:%OURUSER%+%ABBREV%-internal-reject-copy@%DOMAIN%
'
export MAILOUT_RECVACK_FORMAIL_ARGS
export MAILOUT_ACCEPTACK_FORMAIL_ARGS
export MAILOUT_REJECT_FORMAIL_ARGS

#######################################################################
# STUMP enforces limitations on the maximum number of newsgroups
# used in Newsgroups: header line. The default value is 5. I
# You can change this value. If you do not want to enforce limitations 
# on crossposting, set MAX_CROSSPOSTS to 1000.
# 
MAX_CROSSPOSTS=1
export MAX_CROSSPOSTS


######################################################################
# Do you really want to use PGP? PGP (Pretty Good Privacy) is a 
# program that allows you (among other things) digitally sign messages
# and check digital signatures.
#
# It can make certain transactions more non-repudiable and secure.
# however, for most newsgroups the benefits of security are not as
# important and many users prefer not to use PGP. 
#
# Those users may set PGP to "none" (lowercase). 
#
# This ENTIRELY DISABLES use of PGP. That also disables PGPMoose, a 
# program that relies on PGP to digitally sign all approvals. 
# PGP Moose can help you combat forged approvals.
#
# My suggestion is, if you are not comfortable with PGP and have other
# things on your plate, set PGP to "none" and set it up later when
# time permits. Get other stuff working first.
#
# Alternatively, you could set PGP to the path to the actual PGP executable,
# as in:
#
# PGP=/usr/local/bin/pgp262
#
# Note that STUMP _requires_ pgp v. 2.6.2.
#

PGP="gpg"
export PGP

######################################################################
# for pmapp - digital signing

######################################################################
# PGP key names.
# PMUSER must be exactly as the PGP key named in the keyring
# Refer to the online documentation on how to create PGP keys.
#
# *IF* you do not plan to use PGP at all, define it like this:
# PMUSER_APPROVAL="SCRM Moderators <scrm-board@algebra.com>"
# and make sure that PMAPP is defined as "cat".
#
# this MUST be dfined EVEN if PGP is set to "none".
# This goes into your Approved: field.
PMUSER_APPROVAL="%GROUP% approval key <%MODEMAIL%>"
export PMUSER_APPROVAL

######################################################################
# type in the passphrase for PGP Moose (passphrase for the Approval Key
# named right above that you generated)
# ONLY if pgp moose is used
#
# (in turn, PGP Moose is used only if PGP is NOT set to "none")
#
PMPASSWORD=""
export PMPASSWORD

######################################################################
#
# PMAPP is the name of the PGP Moose signing program. If you do not
# want to use it, define PMAPP as "cat", like this: 
# PMAPP="cat"; export PMAPP
#
# otherwise, use "pmapp":
# PMAPP="pmapp"; export PMAPP
#
# NOTE!!! PMApp is disabled if PGP is set to "none"!
#

PMAPP="pmapp"; export PMAPP

######################################################################
#
# DECISION_ADDRESS is the address for approved AND rejected submissions
# Used by ModScape subsystem only.
#
#DECISION_ADDRESS=scrm-approved@algebra.com
#export DECISION_ADDRESS

######################################################################
# put a munged address for your group here. It should best resolve to
# a devnulled address, since a lot of rejections/acks will bounce
# and there is no need for a human being to see the bounces.
#
MUNGED_ADDRESS=%OURUSER%+%ABBREV%-bounces@%DOMAIN%
export MUNGED_ADDRESS


######################################################################
# Where to submit ready and signed articles
# You do not need this if you set RNEWS (below) to sendmail, as
# instructed.
#IHAVE_SERVER=news.uu.net; export IHAVE_SERVER

######################################################################
# Path: suffix for news
# Put something similar here, it is not a very important value.
#
PATH_SUFFIX="%GROUP%-moderators!robomod!not-for-mail"; export PATH_SUFFIX

######################################################################
# Do we want to work in paranoid PGP mode? YES or NO
#
# NOTE: it means more work for the maintainer
#
# I suggest STRONGLY that you should set it to NO!!!!!!!!!!
#
# This is disabled If PGP is set to "none".
#
STUMP_PARANOID_PGP=NO
export STUMP_PARANOID_PGP

######################################################################
# reachable email address of a real person who is responsible
# for maintaining the robomoderator.
#
ADMIN=%ADMIN%; export ADMIN

######################################################################
# Address of the moderator's board (little private mailing list
# for moderators only) where posters can send their complaints about the
# moderation policy.
#
BOARD=%MODEMAIL%; export BOARD

######################################################################
# address for the no-ack requests.
NOACK=%OURUSER%+%ABBREV%-noack@chiark.greenend.org.uk
export NOACK

######################################################################
# Official address for submissions to the newsgroup.
#
SUBMIT=%OURUSER%+%ABBREV%+%KEYSUBMIT%@chiark.greenend.org.uk; export SUBMIT

###################################################################### Flags
#
# ATTENTION!!! Flags must be YES or NO, in capital letters.
#

######################################################################
# set this flag to YES if you want to REQUIRE all preapproved
# posters to use PGP to sign their messages. Typically you
# do not want to do it, unless your group has
# been SEVERELY invaded by malicious forgers.
#
# disabled if PGP is set to "none"
#
WHITELIST_MUST_SIGN=NO; export WHITELIST_MUST_SIGN

########################################################## where is your rnews
# find out where is rnews program in your system - there may be
# several ones called `rnews'. Yours must be setuid or setgid, 
# typically.
#
# Below are several variants of defining RNEWS. The simplest one involves
# use of my mail2news gateway for STUMP users.
#
# Use this one if you want to use my gateway -- SIMPLEST way to do it.
# RNEWS="sendmail -f devnull@stump.algebra.com news-gateway@stump.algebra.com"
#
# Note that the -f flag is used to prevent any antispamming system from
# rejecting email to the news gateway.
#
# Use this only if you want to use your own rnews -- a pain in the
# neck if you do not know well how news servers work.
# RNEWS="/usr/lib/news/rnews -h $IHAVE_SERVER -S $IHAVE_SERVER "
#
# OR may be something like this if you have inews only:
# [you may have problems with "hostname" on bsd-derived systems]
#RNEWS="/usr/lib/news/inews -h "; export RNEWS
RNEWS="%BASEDIR%/inews"

#RNEWS="sendmail -f devnull@stump.algebra.com news-gateway@stump.algebra.com"
export RNEWS

# ATTENTION!!!
# MORE ABOUT RNEWS/INEWS: unfortunately, these programs differ on many
# systems. Some of the BSD-derived systems have "broken" inews and rnews
# that does not like another program "hostname".
#
# If you see error messages about "hostname" in ~/Mail/from, you should 
# either disregard them, or use the "hostname" shell script provided in 
# stump/etc. Do the following: 
#
# cd $HOME/stump/etc
# mv hostname.REPLACEMENT hostname
#
# Edit "hostname" and set your host name and fully qualified hostname.
#

############################################################ Internal vars
#
# Do NOT change this section
#

if [ "$PGP" = "none" ] ; then
  PMAPP=cat
  export PMAPP
fi

#######################################################################
# Directory for temp files. This directory must NOT be writable by general
# public, for security reasons. I suggest keeping this intact.
#

TMP=$MNG_ROOT/tmp; export TMP

BEGIN_PGP_SIGNED_MESSAGE="-----BEGIN PGP SIGNED MESSAGE-----"
BOT_SUBJECT_PREFIX="KEGHF894ND50MJ"

export BEGIN_PGP_SIGNED_MESSAGE BOT_SUBJECT_PREFIX


################################################################# Invocation
#
# DO NOT EDIT
#
# I use `antivirus' program as additional protection from all sorts
# of attempts to exploit bugs in moderation programs. Antivirus replaces
# all suspicious characters by '_' and splits too long lines.
#

if [ "x$1" != "x" ]; then
  antivirus | decodeBase64 | "$@"
fi
