#!/bin/sh
picom &
xrandr --output Virtual1 --mode 1920x1080 &
setxkbmap es &
nm-applet &
udiskie -t &
volumeicon &
cbatticon &