#!/bin/sh
# Revision String Generator
# Copyright 2011 Hisashi Morita
# License: Public Domain
#
# Usage:
#   vcsrev.sh [WORKING_DIR]
#   #=> Git:        a1b2c3d, a1b2c3dM, etc.
#   #=> Mercurial:  a1b2c3d, a1b2c3dM, etc.
#   #=> Bazaar:     123, 123M, etc.
#   #=> Subversion: 123, 123M, etc.

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
    HASH=` (cd "${WD}" && git describe --all --long) | \
            sed "s/^.*-g\([0-9a-z]\+\)$/\1/g"`
    IFMOD=`(cd "${WD}" && git status) | \
            grep "modified:\|added:\|deleted:" -q && \
            echo -n "M"`
    [ ! "${REV}" ] && REV=${HASH}${IFMOD}
  fi
fi

# Mercurial
which hg >/dev/null; [ x"$?" = x0 ] && HG=TRUE
if [ x"${HG}" = xTRUE ]; then
  (hg status "${WD}" >/dev/null 2>&1) && HG_WD=TRUE
  if [ x"${HG_WD}" = xTRUE ]; then
    [ ! "${REV}" ] && REV=`hg identify --id "${WD}" | sed "s/+/M/g"`
  fi
fi

# Bazaar
which bzr >/dev/null; [ x"$?" = x0 ] && BZR=TRUE
if [ x"${BZR}" = xTRUE ]; then
  (bzr status "${WD}" >/dev/null 2>&1) && BZR_WD=TRUE
  if [ x"${BZR_WD}" = xTRUE ]; then
    REVNO=`bzr revno "${WD}"`
    IFMOD=`bzr status --versioned "${WD}" \
           | grep "^[a-z]*:" -q && echo -n "M"`
    [ ! "${REV}" ] && REV=${REVNO}${IFMOD}
  fi
fi

# Subversion
which svn >/dev/null; [ x"$?" = x0 ] && SVN=TRUE
if [ x"${SVN}" = xTRUE ]; then
  (svn info "${WD}" >/dev/null 2>&1) && SVN_WD=TRUE
  if [ x"${SVN_WD}" = xTRUE ]; then
    [ ! "${REV}" ] && REV=`svnversion "${WD}" | sed "s/:/-/g"`
  fi
fi

[ ! "${REV}" ] && REV=unknown

echo -n "${REV}"
