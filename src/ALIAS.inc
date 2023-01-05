# ALIAS.sh
# 1. setup aliases to these scripts
# 2. source ALIAS.sh  ## do not execute in sub-shell
# 3. do not chmod +x, to prevent execute as sub-shell
# 4. leave this file in the ~/bin dir

# execute in ~/bin dir
cd $(dirname $0)

# many .sh files
SH="mp.sh mpall.sh filnam.sh"
for S in $SH ; do
   [ -x $S ] && alias ${S/.sh/}=$S
done

# many .py files
PY="mailit.py"
for S in $PY ; do
   [ -x $S ] && alias ${S/.py/}=$S
done

# my helpful shortcuts
alias .=source
alias al="aspell list | sort | uniq"
alias rm="rm.sh"
alias rmrf="/bin/rm -rf"
alias poweroff="poweroff.sh"
alias auth="~/bin/auth.sh"
alias vi="echo Please use vim"
alias dir='echo "Please use ls instead."'
alias dirl='echo "Please use ll or l. instead."'
alias cp='cp -p'

# media files, images, video, audio, all
MyImg='*.jpg *.jpeg *.png *.gif *.webp *.bmp *.svg *.tiff *.heif *.eps *.psd *.xcf *.indd *.ai *,raw'
MyAud='*.mp3 *.wav *.ape *.aac *.ogg *.flac *.alac *.aiff *.dsd *.pcm'
MyVid='*.mp4 *.mov *.avi *.wmv *.flv *.webm *.mkv *.h264 *.h265'
MyAll="$MyImg $MyAud $MyVid"
alias lm="/bin/ls    $MyAll 2>/dev/null"  # ls media files
alias LM="/bin/ls -l $MyAll 2>/dev/null"  # ll media files
# sed 's/ \*\.[a-z]*[0-9]*//g' # filter any "*.blah" warnings

# file listing
alias ls='/bin/ls -FG'          # ls with color and type
alias ll='/bin/ls -ohFG'        # ll with color and type
alias le='/bin/ls -l /etc/'     # list /etc to fill screen
alias la='/bin/ls -aohFG'       # ll and  hidden
alias l.='/bin/ls -FladhG .*'   # ll only hidden
alias lg='ll | grep -i '        # ll with grep 
alias lt='find . -type f -exec /bin/ls -lthon {} +'  # sort all sub-dirs newest first
# dir listing
lf() { /bin/ls -ohG $1 | grep --color=always "^d"; }
lF() { F="$1"; [ -z "$F" ] && F="."; find $F -type d -maxdepth 1 | xargs /bin/ls -Gd; }
LF() { F="$1"; [ -z "$F" ] && F="."; find $F -type d -maxdepth 1 | xargs /bin/ls -ohGd; }

#alias vi="/opt/local/bin/vim"
#alias view="/opt/local/bin/view"
#alias screen="/opt/local/bin/screen"
alias sc="screencapture -i Screenshot.png"
alias ss="sudo open -a /System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app"
#alias swim=swim.sh
#alias eject="drutil eject"
alias mpa=$HOME/bin/mpall.sh
alias ldd="otool -L"
alias bash5=/opt/local/bin/bash

