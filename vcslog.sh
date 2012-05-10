#!/bin/sh
# ChangeLog Generator
# Copyright 2011 Hisashi Morita
# License: Public Domain
#
# Usage:
#   changelog.sh [WORKING_DIR] > ChangeLog

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
    (cd "${WD}"; git log | cat)
  fi
fi

# Mercurial
which hg >/dev/null; [ x"$?" = x0 ] && HG=TRUE
if [ x"${HG}" = xTRUE ]; then
  (hg status "${WD}" >/dev/null 2>&1) && HG_WD=TRUE
  if [ x"${HG_WD}" = xTRUE ]; then
    (cd "${WD}"; hg log --rev tip:0)
  fi
fi

# Bazaar
which bzr >/dev/null; [ x"$?" = x0 ] && BZR=TRUE
if [ x"${BZR}" = xTRUE ]; then
  (bzr status "${WD}" >/dev/null 2>&1) && BZR_WD=TRUE
  if [ x"${BZR_WD}" = xTRUE ]; then
    (cd "${WD}"; bzr log --gnu-changelog)
  fi
fi

# Subversion
which svn >/dev/null; [ x"$?" = x0 ] && SVN=TRUE
if [ x"${SVN}" = xTRUE ]; then
  (svn info "${WD}" >/dev/null 2>&1) && SVN_WD=TRUE
  if [ x"${SVN_WD}" = xTRUE ]; then
    (cd "${WD}"; svn log -rBASE:0 -v)
  fi
fi
