#!/bin/bash
# rm.sh
# Alias this to "rm" to safely handle file deletes.
# Moves files to a ~/.deleted, rather than deleting them.
# Do not overwrite previously deleted files of the same name.
# Delete oldest files from ~/.deleted as it hits some limit.
#
# Questions, comments, bugs, fixes to john@masinter.net
# Copyright (c) 2022 John F. Masinter, released under the MIT License.
#
# HISTORY
# 1.0, 1/1/2020, initial version
VER="1.0"

#-------------------------------------------------------------------------------
TRASH=~/.deleted   # location of trash folder
LIMIT=1000         # leave only this many files, remove oldest first
VERSION="0.2"
VERB="-v"
WARN=1
DBUG=

#-------------------------------------------------------------------------------
# usage
if [ $# -eq 0 ] ; then
   printf "\n\
Usage: rm.sh [files...]\n\
\n\
This will move files to $TRASH instead of deleting them.\n\
It will limit the size consumed by only keepin $LIMIT files.\n\
The oldest files are deleted first.\n\
Ver $VERSION, John Masinter, 13-Sep-2008.\n\
\n"
   exit 1
fi

#-------------------------------------------------------------------------------
# create trash sub-dir if it doesn't exist
if [ ! -d $TRASH ] ; then
    echo "Creating directory $TRASH"
    mkdir $TRASH;
    if [ $? -ne 0 ] ; then
       echo "ERROR: Unable to create dir: $TRASH. Deleting UNSAFELY."
    fi
fi

#-------------------------------------------------------------------------------
# attempting "-rf" ?
if [ $WARN -gt 0 ] ; then
   if [ "$1" == "-r" ] || [ "$1" == "-rf" ] ; then
      printf 'rm.sh can not save whole directories. Permanently delete? [y/N]: '
      read ans
      if [ "_$ans" == "_y" ] || [ "_$ans" == "_Y" ] ; then
         echo /bin/rm -rf $@
         /bin/rm -rf $@
         exit $?
      else
         echo "Exiting..."
         exit 1
      fi
   fi
fi

#-------------------------------------------------------------------------------
# move all files to trash dir
for file in $@; do
    if [ -e $TRASH/$file ] ; then
        mv $DBUG $TRASH/$file $TRASH/$file.$RANDOM
    fi
    mv $VERB $file ~/.deleted/
done

#-------------------------------------------------------------------------------
# periodically clean up
TMP=$TRASH/t.$RANDOM
ls -1tr $TRASH > $TMP # oldest first
#cnt=`wc -l $TMP | cut -d' ' -f1`
cnt=`wc -l $TMP | awk '{ print $1 }'`
if [ $cnt -gt $LIMIT ] ; then
   old=$((cnt-LIMIT))
   printf "Found $cnt files in trash folder. Removing $old to leave only $LIMIT.\n"
   for i in `head -$old $TMP` ; do
      rm -rf $VERB $TRASH/$i
   done
fi
rm $DBUG $TMP

#-------------------------------------------------------------------------------
# Main

