#!/bin/bash
# diffdir.sh
# compare files in two dirs recursively, and report any files that have changed.
# see Usage() below for more details.
#
# v0.1, 04/20/2004, simple crude first version
# v0.2, 07/14/2008, add the difference type +/-/*
# v0.3, 04/19/2013, add Fast/Slow modes of compare
# v0.4, 09/20/2013, add option to generate test dirs
#
# Questions, comments, bugs, fixes to john@masinter.net
# Copyright (c) 2022 John F. Masinter, released under the MIT License.
VER="1.0"

# Mode is the criteria by which files are compared:
# (F)ast: compare only date/size, sometimes inaccurate results
# (S)low: byte-by-byte compare, always accurate (Default)
Mode="S"

#--------------------------------------------------------------------------------
# print usage and exit
Usage() {
   printf '
Usage: diffdir.sh {-s|-f|-t} [dir1] [dir2]

Compare files from first dir (dir1) to second dir (dir2).

Type: Optional, default (F)ast:
   -s   Slow compare, Default, always 100% accurate, byte-by-byte
   -f   Fast compare, only filesize, sometimes changes missed
   -t   Testing only, create two dirs with sample same/diff files

Report any changes: new files, deleted files, changed files.
The output show the delta from dir1 to dir2, similar to diff:
"+" dir1 file added in dir2
"-" dir1 file deleted in dir2
"*" dir1 file different in dir2

Example: View what files someone else has updated on a shared project:

$ diffdir.sh ~/src/widget ~mike/src/widget
+ blah.c
+ blah.h
- blah.old
* app.c

John Masinter, 2012
'
   exit 1
} # Usage

#--------------------------------------------------------------------------------
# -t opt, create all possible file same/different cases for testing
TstFil() {
   # dirs
   D1="diffdir1"; D2="diffdir2"
   [ -d $D1 ] || mkdir $D1
   [ -d $D2 ] || mkdir $D2
   rm -f $D1/* $D2/*

   # diff size
   echo "different" >$D1/d1.txt
   echo "files"     >$D2/d1.txt
   # same size/date, diff data
   echo "different" >$D1/d2.txt
   echo "filesgood" >$D2/d2.txt

   # same contents
   echo "thesameee" >$D1/s1.txt
   echo "thesameee" >$D2/s1.txt
   # same size/data, diff date
   echo "thesameee" >$D1/s2.txt; sleep 2
   echo "thesameee" >$D2/s2.txt

   echo "test file dirs:  $D1  $D2"
   exit 1
} # TstFil

#--------------------------------------------------------------------------------
SetCmd() {
   # correct md5sum method for Linux & OSX
   if [ "$(uname -s)" == "Darwin" ] ; then
      MD5="md5 -r"
      STAT="stat -f %z"
   else
      MD5="md5sum"
      STAT="stat -c %s"
   fi

} # SetCmd

#--------------------------------------------------------------------------------
# parse command line args
Parse() {
   [ "$1" == "-t" ]      && TstFil   # hidden option, create test files
   [ "$1" == "-f" ]      && Mode="F" # user select Slow mode, defaults to Fast if not given.
   [ "${1:0:1}" == "-" ] && shift    # if option given, step past it
   if [ $# -ne 2 ] ; then echo; echo "ERROR: Requires two or three arguments." ; Usage; fi
   if [ ! -d $1 ]  ; then echo; echo "ERROR: Not a valid directory: $1" ; Usage; fi
   if [ ! -d $2 ]  ; then echo; echo "ERROR: Not a valid directory: $2" ; Usage; fi
   Y="$1" # your directory
   M="$2" # my directory
   SetCmd
} # Parse

#--------------------------------------------------------------------------------
# get size and date of file
SizDat() {
 F="$1"
 S=$($STAT "$F")
 #D=$(date -r "$F" '+%s')
} # SizDat

#--------------------------------------------------------------------------------
# compare two files using Fast method (date/size)
DiffFast() {
   F1="$1"; F2="$2"

   # get size & date of both files
   SizDat "$F1"; S1=$S; #D1=$D
   SizDat "$F2"; S2=$S; #D2=$D
   #printf "DiffFast\n$F1  $S1  $D1\n$F2  $S2  $D2\n"; break # Debug

   # don't use date anymore. different dates but same contents == same
   #if [ "$S1" == "$S2" ] && [ "$D1" == "$D2" ] ; then

   if [ "$S1" == "$S2" ] ; then
      return 0; # files are the same
   else
      return 1; # files are different
   fi

} # DiffFast

#--------------------------------------------------------------------------------
# compare two files using Slow method (md5)
DiffSlow() {
   F1="$1"; F2="$2"

   # gnu cmp is faster than md5
   cmp -s "$F1" "$F2"; rc=$?
   #printf "DiffSlow: $rc $F1 $F2\n"; break # Debug

   if [ $rc -eq 0 ] ; then
      return 0; # files are the same
   else
      return 1; # files are different
   fi
   
} # DiffSlow

#--------------------------------------------------------------------------------
# compare two files using Slow method (md5)
DiffSlow2() {
   F1="$1"; F2="$2"

   # calc hash of both files
   S1=$($MD5 "$F1" | cut -d' ' -f1)
   S2=$($MD5 "$F2" | cut -d' ' -f1)
   #printf "DiffSlow\n$F1  $S1\n$F2  $S2\n"; break # Debug

   if [ "$S1" == "$S2" ] ; then
      return 0; # files are the same
   else
      return 1; # files are different
   fi
   
} # DiffSlow2

#--------------------------------------------------------------------------------
# compare two files
DiffFil() {
   F1="$1"; F2="$2"

   # always fast compare of files first, "different" result 100% accurate.
   DiffFast "$F1" "$F2"
   rc=$?

   # if "same" result, then doulbe check via slow compare (if -s slow mode)
   if [ $rc -eq 0 ] && [ "$Mode" == "S" ]; then
      DiffSlow "$F1" "$F2"
      rc=$?
      #echo "Debug: $rc $F1 $F2"
   fi

   return $rc
} # DiffFil

#--------------------------------------------------------------------------------
# perform compare and echo result for one file
DiffOne() {
      F1="$Y/$f"; F2="$M/$f"

      # skip any dirs
      if [ -d "$F1" -a -d "$F2" ] ; then continue ; fi

      # remove leading "./" to make output nicer
      if [ "${f:0:1}" == "." -a "${f:1:1}" == "/" ] ; then
         f="${f:2}"
         F1="$Y/$f"; F2="$M/$f"
      fi

      # file missing in dir2
      if [ ! -f "$F1" ] ; then echo "- $f"

      # file added in dir2
      elif [ ! -f "$F2" ] ; then echo "+ $f"

      # modified file?
      elif ! DiffFil "$F1" "$F2" ; then echo "* $f"

      fi
} # DiffOne

#--------------------------------------------------------------------------------
# get file list from both dirs, only keep unique filenames
FileList() {
   # get a list of files in first dir
   P=/var/tmp/diffdir.tmp.1.$RANDOM
   (cd $Y ; find .  >$P)
   (cd $M ; find . >>$P)
   T=/var/tmp/diffdir.tmp.2.$RANDOM
   sort <$P | grep -v "/\.svn" | uniq >$T
   rm -f $P
} # FileList

#--------------------------------------------------------------------------------
# compre files in two directories. see help above for full docs.
# Y = first directory i.e. Yours, M = second dir, i.e. Mine
DiffDir() {
   FileList
   # examine one file at a time
   while read f ; do
      DiffOne
   done <$T
   rm -f $T
} # DiffDir

#--------------------------------------------------------------------------------
# Main
Parse $*
DiffDir

