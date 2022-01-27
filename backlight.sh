#!/bin/sh

set -e

plug_key=1337
ipcrm -M ${plug_key} 2>/dev/null || true

warm_path='/sys/class/backlight/backlight_warm/'
warm_orig=`cat ${warm_path}brightness`
warm_max=`cat ${warm_path}max_brightness`

cool_path='/sys/class/backlight/backlight_cool/'
cool_orig=`cat ${cool_path}brightness`
cool_max=`cat ${cool_path}max_brightness`

yad --plug=${plug_key} --tabnum=1 --text="Cool" \
	--scale --inc-buttons --step=8 --print-partial \
	--min-value 0 --max-value $cool_max --value $cool_orig \
	--image=weather-clear-night \
	| sudo tee "${cool_path}brightness" > /dev/null &

yad --plug=${plug_key} --tabnum=2 --text="Warm" \
	--scale --inc-buttons --step=8 --print-partial \
	--min-value 0 --max-value $warm_max --value $warm_orig \
	--image=weather-clear \
	| sudo tee "${warm_path}brightness" > /dev/null &

yad --paned --orient=vertical --key=${plug_key} \
	--title 'Set backlight levels:' \
	--width 500 --height 120 --fixed --center \
	--sticky --mouse --on-top --close-on-unfocus \
	--escape-ok --button OK

