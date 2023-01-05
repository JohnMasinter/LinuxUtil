#!/bin/bash
# difffil.sh
#
# provide several formatted output options when diff'ing two files
#
# 1.0, 04/01/1999, initial set of formats
#
# Questions, comments, bugs, fixes to john@masinter.net
# Copyright (c) 2022 John F. Masinter, released under the MIT License.
VER="1.0"

#------------------------------------------------------------------------------------------
# various method to diff two files

diff1() {
   diff -y -W250 $1 $2 | expand | grep -E -C3 '^.{123} [|<>]( |$)' | colordiff | less -rS
   # Option -W250 makes the output wider such that I can see more data.
   # expand is necessary to convert tabs to spaces
   # -C3 adds 3 lines of context to the grep output.
   # ^.{123} matches half of the data before the side-by-side diff markers.
   # colordiff makes the output prettier to follow
   # less -rS allows ANSI colors to be interpreted (-r) and prevents wrapped lines (-S).
}

diff2() { sdiff -bBWs $1 $2 }

diff3() { diff  --unchanged-line-format="" --old-line-format="-:%dn: %L" --new-line-format="+:%dn: %L" $1 $2 }

diff4() {
   diff --expand-tabs -W 150 -y $1 $2 | \
   awk -v W=150 '(substr($0,W/2,1)=="|")
     { left=substr($0,1,(W/2)-1);print left "<";
       right=substr($0,(W/2)+1);printf "%" ((W/2)-1) "s>%s\n"," ", right;
       next;
     }1'
}

diff5() {
   format="%-50s | %-50s\n"
   comm --output-delimiter=: $1 $2 |
   while IFS= read -r line; do      
       case $line in
           ::*) line=${line#::}; printf "$format" "$line" "$line" ;;
           :*)  line=${line#:};  printf "$format" "" "$line" ;;
           *)                    printf "$format" "$line" "" ;;     
       esac
   done
}

diff6() { diff -wBu $1 $2 | colordiff | cat -n }
 
#------------------------------------------------------------------------------------------
# Main

