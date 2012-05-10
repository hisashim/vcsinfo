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

# Git
which git >/dev/null; [ x"$?" = x0 ] && GIT=TRUE
if [ x"${GIT}" = xTRUE ]; then
  (cd "${WD}" && git status --porcelain >/dev/null 2>&1) && GIT_WD=TRUE
  if [ x"${GIT_WD}" = xTRUE ]; then
    [ ! "${FILES}" ] && FILES=`cd "${WD}" && git ls-files | sort`
  fi
fi

# Mercurial
which hg >/dev/null; [ x"$?" = x0 ] && HG=TRUE
if [ x"${HG}" = xTRUE ]; then
  (hg status "${WD}" >/dev/null 2>&1) && HG_WD=TRUE
  if [ x"${HG_WD}" = xTRUE ]; then
    [ ! "${FILES}" ] && \
      FILES=`cd "${WD}" && hg status --all | grep -v '^?' | cut -c3- | sort`
  fi
fi

# Bazaar
which bzr >/dev/null; [ x"$?" = x0 ] && BZR=TRUE
if [ x"${BZR}" = xTRUE ]; then
  (bzr status "${WD}" >/dev/null 2>&1) && BZR_WD=TRUE
  if [ x"${BZR_WD}" = xTRUE ]; then
    [ ! "${FILES}" ] && \
      FILES=`cd "${WD}" \
             && (bzr ls --versioned --recursive --kind file; \
                 bzr ls --versioned --recursive --kind symlink) | sort`
  fi
fi

# Subversion
which svn >/dev/null; [ x"$?" = x0 ] && SVN=TRUE
if [ x"${SVN}" = xTRUE ]; then
  (svn info "${WD}" >/dev/null 2>&1) && SVN_WD=TRUE
  if [ x"${SVN_WD}" = xTRUE ]; then
    [ ! "${FILES}" ] && \
      FILES=`cd "${WD}" && svn status --non-interactive -v . \
             | grep -v '^?' | cut -c10- | awk '{ print \$4 }' \
             | xargs -n 1 -I{} find {} -maxdepth 0 ! -type d | sort`
  fi
fi

echo -n "${FILES}"
