#!/bin/sh

set -e

# Paths to the backlight "files"
warm_path='/sys/class/backlight/backlight_warm/'
cool_path='/sys/class/backlight/backlight_cool/'

# IPC key to use. (Change this if it conflicts with something else.)
plug_key=1337

# Original and max values (to pass to yad on startup)
warm_orig=`cat ${warm_path}brightness`
warm_max=`cat ${warm_path}max_brightness`
cool_orig=`cat ${cool_path}brightness`
cool_max=`cat ${cool_path}max_brightness`

# Figure out where to put our FIFO
if [ -z "$XDG_RUNTIME_DIR" ]; then
    fifo_path="/tmp/.backlightfifo"
else
    fifo_path="${XDG_RUNTIME_DIR}/backlightfifo"
fi

# Remove an existing FIFO if there is one
rm -f "${fifo_path}"
# Make it!
mkfifo "${fifo_path}"
# Open it! (Use file descriptor 3)
exec 3<>"${fifo_path}"
# We don't need the FIFO file anymore (?!!)
rm -f "${fifo_path}"

# Clear out anything else that's using the same IPC key, just in case.
ipcrm -M ${plug_key} 2>/dev/null || true

case "$1" in
    "--separate" | "")
	# Create the cool slider
	yad --plug=${plug_key} --tabnum=1 --text="Cool" \
	    --scale --inc-buttons --step=8 --print-partial \
	    --min-value 0 --max-value $cool_max --value $cool_orig \
	    --image=weather-clear-night | sed -ue 's/^/cool /' >&3 &
	# Create the warm slider
	yad --plug=${plug_key} --tabnum=2 --text="Warm" \
	    --scale --inc-buttons --step=8 --print-partial \
	    --min-value 0 --max-value $warm_max --value $warm_orig \
	    --image=weather-clear | sed -ue 's/^/warm /' >&3 &
	# Read the sliders' values, and set them as we get them
	while read which value; do
	    case ${which} in
		cool)
		    echo ${value} | sudo tee ${cool_path}brightness >/dev/null&
		    ;;
		warm)
		    echo ${value} | sudo tee ${warm_path}brightness >/dev/null&
		    ;;
		*)
		    echo "We're confused!"
		    ;;
	    esac
	done <&3 &
	;;
    "--ratio")
	if [ $warm_orig -gt $cool_orig ]; then
	    brightness_orig=$warm_orig
	    ratio_orig=$((100 - cool_orig * 100 / warm_orig))
	else
	    brightness_orig=$cool_orig
	    ratio_orig=-$((100 - warm_orig * 100 / cool_orig))
	fi
	brightness=${brightness_orig}
	ratio=${ratio_orig}
	# Create the brightness slider
	yad --plug=${plug_key} --tabnum=1 --text="Brightness" \
	    --scale --inc-buttons --step=8 --print-partial \
	    --min-value 0 --max-value 255 --value $brightness_orig \
	    --image=weather-clear-night | sed -ue 's/^/brightness /' >&3 &
	# Create the ratio slider
	yad --plug=${plug_key} --tabnum=2 --text="ratio" \
	    --scale --inc-buttons --step=8 --print-partial \
	    --min-value -100 --max-value 100 --value $ratio_orig \
	    --image=weather-clear | sed -ue 's/^/ratio /' >&3 &
	# Read the sliders' values, and set them as we get them
	while read which value; do
	    case ${which} in
		brightness)
		    brightness=${value}
		    ;;
		ratio)
		    ratio=${value}
		    ;;
		*)
		    echo "We're confused!"
		    ;;
	    esac
	    # Set the values according to the new brightness and/or ratio
	    if [ $ratio -gt 0 ]; then
		warm=$brightness
		cool=$((brightness * (100 - ratio) / 100))
	    else
		cool=$brightness
		warm=$((brightness * (100 - -ratio) / 100))
	    fi
	    echo $cool | sudo tee ${cool_path}brightness > /dev/null &
	    echo $warm | sudo tee ${warm_path}brightness > /dev/null &
	done <&3 &
	;;
    *)
	echo "Usage: backlight.sh --separate OR --ratio"
	echo "default is --separate"
	exit 1
	;;
esac

# Link them together in one window
yad --paned --orient=vertical --key=${plug_key} \
	--title 'Set backlight levels:' \
	--width 500 --height 120 --fixed --center \
	--sticky --mouse --on-top --close-on-unfocus \
	--escape-ok --button OK

