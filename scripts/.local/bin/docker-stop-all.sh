#!/usr/bin/env bash
# Stops every running container. Exists as its own script (rather than
# being inlined in nwg-bar's docker.json) because nwg-bar runs exec
# commands with no shell involved (confirmed the hard way with the
# power menu's Lock button -- see CHANGELOG.md) -- $(docker ps -q)
# command substitution needs a real shell to work at all.

running=$(docker ps -q)
if [ -n "$running" ]; then
    docker stop $running
    notify-send -i utilities-terminal "Docker" "Stopped all running containers"
else
    notify-send -i utilities-terminal "Docker" "No containers were running"
fi
