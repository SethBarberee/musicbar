#!/bin/sh

# Include the other scripts/modules/functions in this directory
_include()
{
	DIR="$(dirname $0)"
	FILE="$DIR/$1"

	if [ -f "$FILE" ]; then
		. "$FILE"
	else
		printf "\033[33m%s\033[0m: Not Found\n" "$FILE" && exit 1
	fi
}

if test ! "$(pgrep mpd)"; then
	printf '\033[33m%s:\033[0m process not found\n' 'mpd'
elif test ! "$(pgrep spotify)"; then
	printf '\033[33m%s:\033[0m process not found\n' 'spotify'
else
	printf '\033[33m%s:\033[0m music player\n' 'incompatible' && exit 1
fi

# Fetches color via xrdb
_include "modules/barcolr"
# Prints the respective icons that are present in the siji font
_include "modules/icon"
# Draw a Progress bar for total played time using mkb
_include "modules/progressbar"
# Draw a Progress bar for the current volume level using mkb
_include "modules/volbar"

# Module loader that loads files respective to each program
if test "$(pgrep mpd)"; then	
	# Clickable Media Keys for playback controls with icons
	_include "modules/mpdctrl"
	# MPD info fetcher
	_include "modules/mpdinfo"
	# Determine mpd's state and set the music icon's color and pause message
	_include "modules/mpdstate"
elif test "$(pgrep spotify)"; then 
	# Spotify info fetcher
	_include "modules/spotifyinfo"
	# Spotify Control Media keys with icons
	_include "modules/spotifyctl"
	# Spotify state
	_include "modules/spotifystate"
fi

# Update interval, see sleep(1) for more details
T=0.2

PROGNAME="$(basename $0)"

# Font for the iconic glyphs: https://github.com/stark/siji/
siji="-wuncon-siji-medium-r-normal--10-100-75-75-c-80-iso10646-1"
# Text font
neepmod='-jmk-neepmod-medium-r-normal--11-100-75-75-c-60-iso8859-1'

FONTS="-f $neepmod  -f $siji"
# Background Color
BG="$(barcolr bg)"
# Foreground Color
FG="$(barcolr 7)"

OFFX=0
OFFY=0
HEIGHT=20
WIDTH=$(xrandr | grep '*' | cut -d 'x' -f1)

# lemonbar geomtery
GEOMETRY=${WIDTH}x${HEIGHT}+${OFFX}+${OFFY}

# mkb char
BCHAR=

_bar()
{
	OPTS="-d -p -B $BG -F $FG $FONTS -u 2 -g $GEOMETRY -a 15"

	lemonbar $OPTS
}

_fgcolr()
{
	local COLOR=$1
	local TEXT="$2"

	echo "%{F$(barcolr $COLOR)}$TEXT%{F-}"
}

_print()
{
	# Icon color when paused/playing
	STATE_ICON="$(_music_state icon)"
	# Pause Message
	STATE_MSG="$(_music_state msg)"
	# Now Playing
	NP="$(_fgcolr 15 "`_music_info title`") $(_fgcolr 8 by) $(_fgcolr 14 "`_music_info artist`")"
	# Playback Control Keys
	MKEYS="$(_music_ctrl prev) $(_music_ctrl rwd) $(_music_ctrl toggle) $(_music_ctrl fwd) $(_music_ctrl next)"
	# Progress bar
	PBAR="$(_music_info played) $(progressbar) $(_music_info total)"
	# Volume up
	V_UP="$(_fgcolr 2 "`_music_ctrl vup`")"
	# Volume down
	V_DOWN="$(_fgcolr 3 "`_music_ctrl vdn`")"
	# Volume bar
	VBAR="$V_DOWN $(volbar) $V_UP"

	# Left Side
	L="%{l}$STATE_ICON $NP $STATE_MSG"
	# Center
	C="%{c}$MKEYS  $PBAR"
	# Right Side
	R="%{r}$(icon vol) $(_fgcolr 14 `_music_info vol`) $VBAR %{A3:killall -g -15 $PROGNAME:}$(icon opt)%{A} "

	echo "${L} ${C} ${R}"
}

# The spell that binds everything together
while [ $? -eq 0 ]; do
	_print && sleep $T
done | _bar | sh > /dev/null

exit 0
