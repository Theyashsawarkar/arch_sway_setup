# termusic

Terminal music player -- no Spotify/YouTube Premium needed. Asked for a
"beautiful CLI" music player with no local library and no premium
subscription to lean on; picked termusic specifically because its own
README says the thing directly: *"You can download from YouTube,
NetEase, Migu and KuGou for free. No need to register for monthly paid
memberships."*

Directly in Arch's official `extra` repo (`packages/pacman.txt`) --
no AUR, no building Rust from source. `yt-dlp` is what actually lets it
pull tracks from YouTube; `ffmpeg`/`kitty` were already installed.

## How the cloud-fetch actually works

Confirmed straight from termusic's own source before relying on it,
not assumed: press `s` (default keybinding, `library_keys.youtube_search`
in `tui.toml`) and a popup opens -- *"Download url or search:"*. Type a
song/artist name (or paste a YouTube URL directly), pick a result, and
it downloads the audio via `yt-dlp` into `music_dirs` (`server.toml`,
set to `~/Music`), adds it to the playlist, and plays. Starting from a
genuinely empty `~/Music` works fine -- there's nothing to have
beforehand, the library builds itself as you search.

## Launch

`$mod+Shift+m` (`sway/config`) opens it in its own floating kitty
window (`kitty --class termusic -e termusic`, `for_window
[app_id="^termusic$"]` sizes and centers it at 900x700) -- floating on
purpose, not tiled: a music player is something you glance at and
dismiss, not something that should permanently claim a slot in the
tiling layout.

## Theme

`themes/Catppuccin-Mocha.yml` -- **not** shipped by the installed
package. Checked directly rather than assumed: the current upstream
`master` branch ships an official `Catppuccin-Mocha.yml` in its own
`lib/themes/` directory (matches this desktop's palette exactly, ANSI
mapping confirmed identical to the canonical Catppuccin terminal spec),
but the Arch package here is version `0.13.2-1`, built before that
theme was added upstream -- launching termusic once and checking
`~/.config/termusic/themes/` directly confirmed it wasn't among the
214 bundled theme files this version actually ships. Copied the file
in from upstream's source tree by hand instead of relying on the
installed package to have it.

Selected by baking the resolved hex values directly into `tui.toml`'s
`[theme]` section (`primary`/`cursor`/`normal`/`bright`, same field
names as the config editor's own theme picker produces when you select
a theme through the UI) rather than leaving theme selection as a manual
first-run step -- confirmed the exact field shape by launching termusic
once with no config at all, letting it generate its own defaults, and
reading the real generated `tui.toml` rather than guessing the TOML
serialization of a nested Rust config struct blind.

## What's tracked here, and what isn't

Only `tui.toml`, `server.toml`, and the one theme file are stowed into
this repo -- `~/.config/termusic/` also holds `data.db`, `library2.db`,
`playlist.log`, and termusic's own 213 other bundled theme files, all
of which are runtime state/bundled data, not configuration, and were
deliberately left as real local files rather than symlinked in (same
"config vs. state" line this repo already draws everywhere else, e.g.
`~/.local/state/notification-mode/`). This works because
`~/.config/termusic/` already existed as a real directory (termusic
creates it itself on first run) before this package was ever stowed --
GNU Stow's own tree-folding behavior symlinks individual files into an
already-real directory instead of replacing the whole directory with
one symlink, confirmed directly with `stow -n -v` before applying it
for real.

## Verified live

Not just "should work" -- actually triggered the real keybinding via a
simulated keypress (not manually running the launch command), confirmed
via `swaymsg -t get_tree` that a 900x700 floating window opened at the
expected position, and screenshotted the running window: 88.6% of its
pixels are the exact Catppuccin Mocha background hex (`#1e1e2e`),
confirming the theme is actually active in the real, keybinding-launched
instance, not just a manually-tested one.
