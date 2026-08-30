#!/usr/bin/env bash
# Toggles between light and dark mode for every app that reads the
# standard GNOME/GTK dconf keys (gtk-theme, color-scheme, icon-theme) --
# the vast majority of regular GUI apps (file managers, browsers' GTK
# chrome, settings dialogs, GTK-based editors) detect and follow this
# automatically, which is the actual mechanism behind "apps detect OS
# dark mode" -- confirmed both palettes exist before wiring this up
# (catppuccin-gtk-theme-latte alongside the already-installed -mocha,
# see packages/aur.txt).
#
# Deliberately does NOT touch this desktop's own bar/launcher/
# notification styling (waybar/wofi/mako's style.css, sway's window
# border colors) -- those are hand-built throughout this whole repo to
# one specific Catppuccin Mocha palette, a deliberate aesthetic choice,
# not something meant to flip with a generic light/dark toggle. Making
# them do that would mean maintaining a full parallel light variant of
# every custom stylesheet in this repo -- a much bigger undertaking than
# what was actually asked for here.
#
# No sudo needed at toggle-time: Papirus-Dark/-Light are both real,
# complete icon sets shipped by the base papirus-icon-theme package, and
# their folder colors were already recolored to match (mauve, both
# palettes) once during install.sh, where sudo was already in use for
# other steps. papirus-folders itself needs root every single time it
# runs (confirmed by reading its own source before relying on that), so
# it's never invoked here -- this script only ever flips which
# already-colored variant is referenced.
#
# Also worth knowing, not something this script can fix: dconf changes
# apply live to apps that are already running and subscribed to
# gsettings-changed (most modern GTK3/GTK4 apps), but some apps only
# read theme state once at their own startup and won't visibly change
# until relaunched -- a real, standard limitation of this whole
# mechanism, not specific to this script.
set -uo pipefail

scheme=$(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null | tr -d "'")

if [ "$scheme" = "prefer-light" ]; then
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
    dconf write /org/gnome/desktop/interface/gtk-theme "'catppuccin-mocha-mauve-standard+default'"
    dconf write /org/gnome/desktop/interface/icon-theme "'Papirus-Dark'"
    notify-send -u low -i weather-clear-night-symbolic "Theme" "Switched to dark mode"
else
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
    dconf write /org/gnome/desktop/interface/gtk-theme "'catppuccin-latte-mauve-standard+default'"
    dconf write /org/gnome/desktop/interface/icon-theme "'Papirus-Light'"
    notify-send -u low -i weather-clear-symbolic "Theme" "Switched to light mode"
fi
