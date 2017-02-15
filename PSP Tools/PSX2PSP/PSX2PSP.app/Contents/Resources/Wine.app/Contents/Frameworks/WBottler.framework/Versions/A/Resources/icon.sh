#!/usr/bin/env bash

PATH_TO_EXECUTABLE=$(echo "$PATH_TO_EXECUTABLE" | sed s'/\\/\//g')
MAINICON=$(echo $(wrestool -l --type=group_icon "$PATH_TO_EXECUTABLE") | awk '{print $2}' | sed 's/--name=//')
MAINICON=$(echo "$MAINICON" | sed s/\'//g)

rm /tmp/MAINICON.ico &> /dev/null
wrestool -x --type=group_icon --output=/tmp/MAINICON.ico --name="$MAINICON" "$PATH_TO_EXECUTABLE" &> /dev/null
wait
sips -s format icns /tmp/MAINICON.ico --out "$PATH_TO_ICON" &> /dev/null
wait
rm /tmp/MAINICON.ico &> /dev/null

