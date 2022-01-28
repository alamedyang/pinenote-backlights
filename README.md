# PineNote backlight controls

Most utilities want to interact with a maximum of one backlight, period. Hence this shell script!

### Setup

1. Install `yad`
2. You'll need to add yourself to the sudoers file so this script can change the contents of `brightness` without a password:
	1. Run `sudo visudo` to open the sudoers file in the default text editor
	2. Inside somewhere, put `USER_NAME ALL=NOPASSWD: /usr/bin/tee /sys/class/backlight/backlight_warm/brightness` (with your username in place of `USER_NAME`)
	3. Do the same thing again, but for `backlight_cool`
3. Run the script and the sliders will update the backlight levels live!

### Modes

There are two modes. Run with `--separate` to control the absolute values of the cool and warm lights, and `--ratio` to control the overall brightness and the ratio of the lights. (`--ratio` is default.)

### Personalization

Toward the top of the shell script are variables you can use to set the slider icons. The icons I've been using are from "Treepata," an icon set based on Xfce's "High Contrast" icons, available [here](https://www.xfce-look.org/p/1015854).

You can use `yad`'s Icon Browser to find the names of icons you like.

### Acknolwedgements

Thanks to SolraBizna for help with the advanced shell stuff!

Written for XFCE on Debian (which was prepared following the instructions in https://musings.martyn.berlin/cross-compiling-the-linux-kernel-for-the-pinenote-or-other-arm-device)
