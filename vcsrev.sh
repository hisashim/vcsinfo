#!/bin/sh
# Revision String Generator
# Copyright 2011 Hisashi Morita
# License: Public Domain
#
# Usage:
#   revstr.sh [WORKING_DIR]
#   #=> Subversion: 123, 123M, etc.
#   #=> Git:        a1b2c3d, a1b2c3dM, etc.
#   #=> Mercurial:  a1b2c3d, a1b2c3dM, etc.
#   #=> Bazaar:     123, 123M, etc.

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
    [ ! "${REV}" ] && REV=`svnversion "${WD}" | sed "s/:/-/g"`
  fi
fi

# Git
which git >/dev/null
if [ x"$?" = x0 ]; then
  (cd "${WD}" && git status --porcelain >/dev/null 2>&1) && GIT=TRUE
  if [ x"${GIT}" = xTRUE ]; then
    HASH=` (cd "${WD}" && git describe --all --long) | \
            sed "s/^.*-g\([0-9a-z]\+\)$/\1/g"`
    IFMOD=`(cd "${WD}" && git status) | \
            grep "modified:\|added:\|deleted:" -q && \
            echo -n "M"`
    [ ! "${REV}" ] && REV=${HASH}${IFMOD}
  fi
fi

# Mercurial
which hg >/dev/null
if [ x"$?" = x0 ]; then
  (hg status "${WD}" >/dev/null 2>&1) && HG=TRUE
  if [ x"${HG}" = xTRUE ]; then
    [ ! "${REV}" ] && REV=`hg identify --id "${WD}" | sed "s/+/M/g"`
  fi
fi

# Bazaar
which bzr >/dev/null
if [ x"$?" = x0 ]; then
  (bzr status "${WD}" >/dev/null 2>&1) && BZR=TRUE
  if [ x"${BZR}" = xTRUE ]; then
    REVNO=`bzr revno "${WD}"`
    IFMOD=`bzr status --versioned "${WD}" \
           | grep "^[a-z]*:" -q && echo -n "M"`
    [ ! "${REV}" ] && REV=${REVNO}${IFMOD}
  fi
fi

[ ! "${REV}" ] && REV=unknown

echo -n "${REV}"
