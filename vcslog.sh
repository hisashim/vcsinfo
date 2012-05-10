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
which git >/dev/null
if [ x"$?" = x0 ]; then
  (cd "${WD}" && git status --porcelain >/dev/null 2>&1) && GIT=TRUE
  if [ x"${GIT}" = xTRUE ]; then
    (cd "${WD}"; git log | cat)
  fi
fi

# Mercurial
which hg >/dev/null
if [ x"$?" = x0 ]; then
  (hg status "${WD}" >/dev/null 2>&1) && HG=TRUE
  if [ x"${HG}" = xTRUE ]; then
    (cd "${WD}"; hg log --rev tip:0)
  fi
fi

# Bazaar
which bzr >/dev/null
if [ x"$?" = x0 ]; then
  (bzr status "${WD}" >/dev/null 2>&1) && BZR=TRUE
  if [ x"${BZR}" = xTRUE ]; then
    (cd "${WD}"; bzr log --gnu-changelog)
  fi
fi

# Subversion
which svn >/dev/null
if [ x"$?" = x0 ]; then
  (svn info "${WD}" >/dev/null 2>&1) && SVN=TRUE
  if [ x"${SVN}" = xTRUE ]; then
    (cd "${WD}"; svn log -rBASE:0 -v)
  fi
fi
