#!/bin/sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
# while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

#Launch Polybar, using default config ~/.config/polybar/config
polybar example &
#symlink spotify config
ln -s /tmp/polybar_mqueue.$! /tmp/ipc-bottom

echo message >/tmp/ipc-bottom

# Launch bar1 and bar2
polybar bottom &
polybar top

echo "Bars launched..."