#!/bin/sh
# Branch Name Detecter
# Copyright 2014 Hisashi Morita
# License: Public Domain
#
# Usage:
#   vcsbranch.sh [WORKING_DIR]
#   #=> Git:        master, etc.
#   #=> Mercurial:  default, default-foo (named branch + bookmark), etc.
#   #=> Bazaar:     trunk, etc. (branch nick) (bzrtools required)
#   #=> Subversion: trunk, etc.

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
    [ ! "${BRANCH}" ] && BRANCH=`(cd ${WD}; git rev-parse --abbrev-ref HEAD)`
  fi
fi

# Mercurial
which hg >/dev/null; [ x"$?" = x0 ] && HG=TRUE
if [ x"${HG}" = xTRUE ]; then
  (hg status "${WD}" >/dev/null 2>&1) && HG_WD=TRUE
  if [ x"${HG_WD}" = xTRUE ]; then
    NB=`(cd ${WD}; hg branch)`
    BM=`(cd ${WD}; hg bookmarks | grep '^ \* ' \
        | sed 's/^ \* \([^ ]*\) *[^ ]*$/\1/g')`
    [ ! "${BRANCH}" ] && BRANCH=`(cd ${WD}; \
        [ ! ${BM} ] && echo ${NB} || echo ${NB}-${BM})`
  fi
fi

# Bazaar
which bzr >/dev/null; [ x"$?" = x0 ] && BZR=TRUE
if [ x"${BZR}" = xTRUE ]; then
  bzr heads --help >/dev/null; [ x"$?" = x0 ] && BZR_HEADS=TRUE
  if [ x"${BZR_HEADS}" = xTRUE ] ; then
    (bzr status "${WD}" >/dev/null 2>&1) && BZR_WD=TRUE
    if [ x"${BZR_WD}" = xTRUE ]; then
      [ ! "${BRANCH}" ] && BRANCH=`(cd ${WD}; bzr heads \
          | grep '^ *branch nick: ' | sed 's/^ *branch nick: \(.*\)$/\1/g')`
    fi
  fi
fi

# Subversion
which svn >/dev/null; [ x"$?" = x0 ] && SVN=TRUE
if [ x"${SVN}" = xTRUE ]; then
  (svn info "${WD}" >/dev/null 2>&1) && SVN_WD=TRUE
  if [ x"${SVN_WD}" = xTRUE ]; then
    [ ! "${BRANCH}" ] && BRANCH=`cd ${WD}; \
        svn info | grep '^URL' | xargs -I{} basename {}`
  fi
fi

[ ! "${BRANCH}" ] && BRANCH=unknown

echo -n "${BRANCH}"
