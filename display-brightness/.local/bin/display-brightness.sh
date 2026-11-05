#!/bin/zsh
# Sets external display backlight and white point to match the macOS
# appearance. Dark mode gets full brightness, which low-nit panels need, and
# a neutral white. Light mode gets a dimmer backlight and a warmer white, so
# large white areas are less glaring while text keeps its contrast: the
# monitor lowers its own blue and green gain in hardware, unlike Night Shift
# or software dimming. BetterDisplay applies the changes over DDC and must be
# running; the gains take effect only in the monitor's User color preset.
#
# Acts only when the appearance changes, so settings you change by hand stay
# until the next switch. Run with --force to apply the current mode now.
# Each value can be overridden for a trial run, e.g.
#   DISPLAY_RGB_LIGHT=50,45,35 display-brightness.sh --force

DARK_BRIGHTNESS="${DISPLAY_BRIGHTNESS_DARK:-100}"
LIGHT_BRIGHTNESS="${DISPLAY_BRIGHTNESS_LIGHT:-65}"
# Red, green, blue gain, each 0-100; 50 is LG's neutral default.
DARK_RGB="${DISPLAY_RGB_DARK:-50,50,50}"
LIGHT_RGB="${DISPLAY_RGB_LIGHT:-50,46,38}"
# Per-panel corrections added to those gains in both modes, as
# serial=red,green,blue, so monitors of the same model look alike. 587562
# (left) runs pink with the same gains as the others.
RGB_OFFSETS="${DISPLAY_RGB_OFFSETS:-587562=-4,0,0}"
DISPLAY_NAME="${DISPLAY_BRIGHTNESS_NAME:-LG HDR 4K}"
BETTERDISPLAY=/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay
STATE="$HOME/.local/state/display-brightness/mode"

if [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == Dark ]]; then
	mode=dark brightness=$DARK_BRIGHTNESS rgb=$DARK_RGB
else
	mode=light brightness=$LIGHT_BRIGHTNESS rgb=$LIGHT_RGB
fi

[[ "$1" == --force ]] || [[ "$(cat "$STATE" 2>/dev/null)" != "$mode" ]] || exit 0

# Without a running instance the binary would launch the app instead of
# applying the setting; leave the state unrecorded so the next run retries.
pgrep -xq BetterDisplay || exit 0

# ddc <target> <vcp> <value>, where target is a BetterDisplay identifier
# option such as -serial=587562.
ddc() {
	"$BETTERDISPLAY" set "$1" -feature=ddc "-vcp=$2" "-value=$3"
}

# Serial numbers of the connected displays whose product name matches.
# BetterDisplay lists productName before serial in each display's entry.
serials() {
	"$BETTERDISPLAY" get -identifiers 2>/dev/null | awk -v want="$DISPLAY_NAME" -F'" : "' '
		/"productName"/ { sub(/",?$/, "", $2); match_ = ($2 == want) }
		/"serial"/ && match_ { sub(/",?$/, "", $2); print $2; match_ = 0 }'
}

# Writes one display at a time with a pause between commands: LG monitors
# drop DDC writes that arrive back to back, which left one panel tinted when
# all three were written at once.
apply() {
	local gains serial offset delta found=0
	gains=("${(@s:,:)rgb}")
	for serial in $(serials); do
		found=1
		delta=(0 0 0)
		for offset in ${(s: :)RGB_OFFSETS}; do
			[[ ${offset%%=*} == "$serial" ]] && delta=("${(@s:,:)${offset#*=}}")
		done
		# Red, green and blue video gain (VCP 0x16, 0x18, 0x1A), then backlight.
		ddc "-serial=$serial" 0x16 $((gains[1] + delta[1])) && sleep 0.2 &&
			ddc "-serial=$serial" 0x18 $((gains[2] + delta[2])) && sleep 0.2 &&
			ddc "-serial=$serial" 0x1A $((gains[3] + delta[3])) && sleep 0.2 &&
			ddc "-serial=$serial" luminance "$brightness" && sleep 0.2 || return 1
	done
	(( found ))
}

if apply; then
	mkdir -p "${STATE:h}"
	print -r -- "$mode" >"$STATE"
	echo "$(date '+%F %T') $mode: $DISPLAY_NAME brightness $brightness, RGB gain $rgb"
else
	echo "$(date '+%F %T') failed to apply $mode to $DISPLAY_NAME" >&2
	exit 1
fi
