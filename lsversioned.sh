#!/bin/sh
# Version Controlled Files List Generator
# Copyright 2011 Hisashi Morita
# License: Public Domain
#
# Usage:
#   lsversioned.sh [WORKING_DIR]

if [ "$1" ]; then
  WD="$1"
else
  WD="."
fi

# Subversion
which svn >/dev/null
if [ x"$?" = x0 ]; then
  (svn info "${WD}" >/dev/null 2>&1) && SVN=TRUE
  if [ x"${SVN}" = xTRUE ]; then
    [ ! "${FILES}" ] && \
      FILES=`cd "${WD}" && svn status --non-interactive -v . \
             | grep -v '^?' | cut -c10- | awk '{ print \$4 }' \
             | xargs -n 1 -I{} find {} -maxdepth 0 ! -type d | sort`
  fi
fi

# Git
which git >/dev/null
if [ x"$?" = x0 ]; then
  (cd "${WD}" && git status --porcelain >/dev/null 2>&1) && GIT=TRUE
  if [ x"${GIT}" = xTRUE ]; then
    [ ! "${FILES}" ] && FILES=`cd "${WD}" && git ls-files | sort`
  fi
fi

# Mercurial
which hg >/dev/null
if [ x"$?" = x0 ]; then
  (hg status "${WD}" >/dev/null 2>&1) && HG=TRUE
  if [ x"${HG}" = xTRUE ]; then
    [ ! "${FILES}" ] && \
      FILES=`cd "${WD}" && hg status --all | grep -v '^?' | cut -c3- | sort`
  fi
fi

echo -n "${FILES}"
