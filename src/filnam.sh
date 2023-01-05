#!/bin/bash
# filnam.sh
# Rename files, replacing white space and spcial chars with dash.
# 
# Questions, comments, bugs, fixes to john@masinter.net
# Copyright (c) 2022 John F. Masinter, released under the MIT License.
#
# HISTORY
# 1.0 - simplest form, just a few lines to replace special chars
# 1.1 - break into functios, add recursive opt, 02/15/2019, john@masinter.net
# 1.2 - enhance arg parsing to allow "-lvr" in addtion to "-l -v -r"
VER="1.2"

#--------------------------------------------------------------------------------
# temp file for dir recursion
Tmp="/tmp/filnam.$RANDOM.tmp"

# args
args=""  # cmd line args as array
argc=""  # num of args
argi=0   # idx of current arg in args

# opts
aL="" # Y=live (-l)
aV="" # Y=verbose logging
aX="" # Y=also rename dirs
aR="" # Y=recurse (-r) implies aX
aE="" # assigned exception string, if any
aA="" # assigned alternate replace char, if any
aT="" # create tree of files & dirs for testing
aD="" # Y=debug (-d)

# stats
sT=0 # total file count
sU=0 # total dirs count
sV=0 # total files changed
sW=0 # total dirs changed

#--------------------------------------------------------------------------------
# Usage - display help and quit
#--------------------------------------------------------------------------------
Usage() {
   echo '
Usage: filnam [-l] [-v] [-r] [-d] [file|directory] ... 

Rename list of files and directories that contains special chars.
Each unwanted char is transformed to a dash "-".
This includes spaces, tabs. Repeating chars are reduced to one.

-l  live run, perform renaming, without this only display actions.
-v  verbose, display every rename action, without this output only dots.
-x  also rename directories  
-r  recurse into subdirectories, implies -x
-e  exception string, e.g. "()" means do not replace parens
-a  alternate replacement char, e.g. instead of "-" maybe "_"
-t  make tree of files and dir for testing and debug use
-d  debug, display call path for each item, unrelated to live or not.

'"Version $VER, bugs to John Masinter, john@masinter.net"'
'
   exit 1
} # Usage

#--------------------------------------------------------------------------------
# display value of indicated option
#--------------------------------------------------------------------------------
Aprn() {
   if [ "$aD" ]; then
      case "$1" in
         l) echo "-l live run enabled" ;;
         v) echo "-v verbose logging enabled" ;;
         x) echo "-x also rename dirs" ;;
         r) echo "-r recurse dirs" ;;
         e) echo "-e exception string \"$aE\"" ;;
         a) echo "-a alternate replace char \"$aA\"" ;;
         t) echo "-t make test tree of files & dirs" ;;
         d) echo "-d debug output enabled" ;;
         *) echo "Aprn: Unrecognized option '$1'" ;;
      esac
   fi
} # Aprn

#--------------------------------------------------------------------------------
# Args - parse command line args
#--------------------------------------------------------------------------------
Args() {
   # early debugging from env var, before -d parsed
   if [ "$eBug" == "yes" ]; then
      aD="Y"
      echo "Early debugging enabled."
   fi

   # too few args? display usage.
   [ $argc -lt 1 ] && Usage

   # get terminal width to display renames
   C=$((COLUMNS/2-2));
   S="%${C}s %-${C}s\n" # e.g. "%40s %-40s"
   [ "$aD" ] && echo "printf columns '$S'"

   # debug
   [ "$aD" ] && echo "argc=$argc, argi=$argi, args[0]=${args[0]}, args*=${args[*]}"
   
} # Args

#--------------------------------------------------------------------------------
# make tree of a few dirs and files for testing
#--------------------------------------------------------------------------------
MakTree() {
   mkdir t; cd t

   for F in f1 f2 "f3 1"; do
      echo "blah" > "$F"
   done

   for D in d1 d2 d3 "d3/d3 1"; do
      mkdir "$D"
      for F in f1 f2 "f3 1"; do
         echo "blah" > "$D/$F"
      done
   done

   echo "Testing tree of dirs and files created: t"; echo
   exit 0
} # MakTree

#--------------------------------------------------------------------------------
# parse one opt arg
#--------------------------------------------------------------------------------
Aone() {
   [ "$aD" ] && echo "Aone '$a'"

   i=1                 # next char index after "-"
   c="${a:$i:1}"       # start char
 
   # parse each char in this one arg, e.g. "-lvr" etc.
   while [ "$c" ]; do
      case "$c" in
         l) aL="Y"; Aprn "l" ;;  # live run
         v) aV="Y"; Aprn "v" ;;  # verbose output
         x) aX="Y"; Aprn "x" ;;  # also rename dirs
         r) aR="Y"; Aprn "r" ;;  # recurse dirs
         e) aE="Y"; echo "note: -e exception string not yet implemented" ;;
         a) aA="Y"; echo "note: -a relacement char  not yet implemented" ;;
         t) aT="Y"; Aprn "t" ;;  # make test tree of files & dirs
         d) aD="Y"; Aprn "d" ;;  # debug execution path
         *) echo "warning: skip unrecognized option '$c'" ;;
      esac
      ((i++))       # next char
      c="${a:$i:1}" # char into var
   done # while each char in current arg

   # -t special case, just make test tree and exit
   [ "$aT" ] && MakTree

} # Aone

#--------------------------------------------------------------------------------
# input: one char, output: repeating sequences of that char, reduced to one char
#--------------------------------------------------------------------------------
ProcStr() {
   g1=1; g2=0;
   # loop until no change in length occurs
   while [ $g1 -ne $g2 ] ; do
      g1=${#b}
      # note this is not "//" for a reason! That would remove all '_' and not even leave one.
      b="${b/$1$1$1/$1}"
      b="${b/$1$1/$1}"
      g2=${#b}
   done
   b="${b/#$1/}" # remove a leading  $1 char, if any
   b="${b/%$1/}" # remove a trailing $1 char, if any
} # ProcStr

#--------------------------------------------------------------------------------
# input: a file or dir name, if special chars found, then rename it
#--------------------------------------------------------------------------------
ProcNam() {
   [ "$aD" ] && echo "ProcNam '$a'"

   # only look at last token in path "a/b/c"
   # do proc "a/b/c 1", do not proc "a 1/b/c"
   A="$a" # save orig
   a=$(basename "$A") # must quote A, e.g. "a/b/c 1" --> "c 1"
   D=$(dirname "$A")  # must quote A, e.g. "a/b/c 1" --> "a/b"

   # a = orig, b = new
   b="$a"

   # multi chars translations first
   b="${b//_-_/-}"
   b="${b//%20/-}"
   b="${b// /-}"

   # reduce repeating chars to one char
   ProcStr "_"
   ProcStr "-"
   ProcStr "."

   # single char translations last
   b="${b//\'/}"
   b="${b//\"/}"
   b="${b//\#/}"
   b="${b//\\/}"
   b="${b//,/_}"
   b="${b//\&/_}"
   b="${b//_./.}"

   if [ "$a" != "$b" ] ; then
      a="$D/$a"; b="$D/$b"
      [ -f "$a" ] && ((sV++))                # count files
      [ -d "$a" ] && ((sW++))                # count dirs
      [ "$aV" ] && printf "$S" "'$a'" "'$b'" # -v verbose
      [ "$aL" ] && mv "$a" "$b" && a="$b"    # -l live
   fi
} # ProcNam

#--------------------------------------------------------------------------------
# process dir, and maybe recursively
#--------------------------------------------------------------------------------
ProcDir() {
   [ "$aD" ] && echo "ProcDir '$a'"

   # skip if no opt to proc dirs
   [ ! "$aR" ] && [ ! "$aX" ] && return

   # proc only dir name if no dir recursion
   ProcNam

   # recurse dirs?
   if [ "$aR" ] ; then
      find -d "$a/"* > $Tmp # do not pipe this to while! do not use $a/.
      while read a ; do
         if   [ -f "$a" ] ; then ((sT++)); ProcNam
         elif [ -d "$a" ] ; then ((sU++)); ProcNam
         elif [ "$aD" ]   ; then echo "Skip $a"
         fi
      done < $Tmp
   fi

} # ProcDir

#--------------------------------------------------------------------------------
# process one file or dir name
#--------------------------------------------------------------------------------
ProcOne() {
   # skip special dir names
   [ "$a" == "." ] || [ "$a" == ".." ] && return

   [ "$aD" ] && echo "ProcOne '$a'"
   c="${a:0:1}"      # first char of arg

   if   [ -f "$a" ]; then ((sT++)); ProcNam
   elif [ -d "$a" ]; then ((sU++)); ProcDir
   elif [ "$c" == "-" ]; then Aone # parse opts anywhere in arg list
   elif [ "$aD" ];   then echo "Skip $a"
   fi
} # ProcOne

#--------------------------------------------------------------------------------
# process all args
#--------------------------------------------------------------------------------
ProcAll() {
   [ "$aD" ] && echo "ProcAll: $argc args"
   a="${args[argi]}" # put arg into simple var

   # process each arg, one at a time
   while   [ -n "$a" ] ; do
      ProcOne           # proc arg
      ((argi++))        # next arg
      a="${args[argi]}" # get  arg
   done
} # ProcAll

#--------------------------------------------------------------------------------
# main entry point
# carful to always ref args in quotes, as they may contain spaces
#--------------------------------------------------------------------------------

# must put cmd line args into array here in main to handle args with spaces
args=("$@")      # make array of cmd line args
argc=${#args[@]} # argc = count of args
argi=0;          # argi = index of current working arg

echo
Args     # parse cmd line args
ProcAll  # proc all args

echo "Examined $sT Files, $sU Dirs, changed $sV files, $sW dirs."
if [ $sV -gt 0 ] || [ $sW -gt 0 ]; then
   [ ! "$aL" ] && echo "* No changes made, add -l for live run."
fi
echo
rm -f $Tmp

exit 0
#--------------------------------------------------------------------------------

