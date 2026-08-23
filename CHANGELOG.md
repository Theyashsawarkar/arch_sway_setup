# Changelog

Notable changes to this setup, in human terms — what changed, why, and what broke
along the way. Newest first.

## 2026-08-23 (Docker + UFW writeup, kitty cleanup)

- **`docs/DOCKER_SECURITY.md`** (new): the full explanation of why Docker bypasses UFW
  (it inserts its own `iptables` rules in `DOCKER`/`DOCKER-ISOLATION-STAGE-*`, ahead of
  where UFW's rules apply), exactly what was checked on this machine (`docker ps` —
  nothing running, nothing published, no live exposure), and a concrete fix in two
  layers: bind future publishes to `127.0.0.1` (zero config), or run the new
  `docs/harden-docker.sh` for an actual `DOCKER-USER`-chain-based restriction (allow
  loopback + RFC1918 ranges, drop everything else), with `docs/docker-user-rules.service`
  to make it survive `docker.service` restarts (which reset `DOCKER-USER` to empty).
  Neither script runs automatically anywhere — this couldn't be tested against a real
  container without `sudo`, so it's opt-in with explicit testing steps in the doc
  rather than something applied silently.
- `kitty.conf`: dropped `hide_tab_bar_if_only_one_tab` and `startup_mode` — confirmed
  via `man kitty.conf` that neither exists in kitty 0.48.2 at all (not deprecated
  aliases, just gone). The tab-bar behavior they wanted is kitty's default now
  (`tab_bar_min_tabs 2`); `startup_mode` never mapped to a real directive.

## 2026-08-23 (kitty remote control)

Enabled `allow_remote_control yes` + `listen_on unix:/tmp/kitty-{kitty_pid}` in
`kitty.conf` — `kitty @ ...` / kittens couldn't control the running instance at all
before this (`{"ok": false, "error": "Remote control is disabled"}`), which blocks
live config/font reloads without a full restart. Not force-restarting the running
kitty instance to apply it — this session's remote shell very likely runs *through*
that same kitty window, and killing it would cut the connection. Needs a manual full
quit/reopen of kitty (not just `ctrl+shift+f5`, since `listen_on` sets up a socket at
startup) to actually take effect. Also re-audited the whole live system (not just this
repo) for stray `ZedMono` references post-migration — none found; the font is
consistent across every app that renders it.

## 2026-08-23 (optimization pass)

Went looking for what could be optimized/improved system-wide and fixed what could
safely be fixed without root access (this session's tools have no sudo on this
machine — see the two items at the end that need the user to run them).

### Font: dropped ZedMono Nerd Font entirely

Scoped this as "switch tmux/kitty off the 700MB manual font download" and then found,
partway through, that **ZedMono Nerd Font was actually the primary font across sway,
mako, wofi, zed, and waybar too** — not just kitty/tmux. Deleted the font directory
before catching that (a `grep --include="*.conf" --include="*.sh"` missed the plain
`sway/config`/`mako/config` files with no extension, and the `.css`/`.json` configs
entirely) — a real mistake, caught immediately by re-grepping with no filter, and
since `rm -rf` on ext4 has no undo, the only responsible path forward was finishing
the migration properly everywhere rather than leaving it half-broken.

Switched every reference to `JetBrainsMono Nerd Font` — already a pacman package
(`ttf-jetbrains-mono-nerd`, already in `packages/pacman.txt`), verified via
`fc-query -f '%{charset}'` to cover every codepoint the tmux status bar actually uses
before relying on it. Updated: `kitty.conf`, `sway/config`, `mako/config`,
`wofi/style.css`, `zed/settings.json`, `waybar/style.css`'s font fallback chain, and
removed the now-dead ZedMono download step from `install.sh` entirely — one less
external dependency and one less thing that could fail on a fresh install.

### Committed four "pending WIP" files that turned out to be finished work

These had been sitting uncommitted for a while and were deliberately left alone in
every earlier session on the assumption they might be someone's mid-edit. Actually
reading the diffs this time: all four were complete, coherent work, not unfinished --

- `sway/config`: wires up `swayidle` and `sway-audio-idle-inhibit` automatically at
  startup (previously had to be started manually), plus idle-timeout inhibition for
  fullscreen windows (videos won't get the screen locked mid-playback).
- `waybar/config` + `style.css`: a full redesign -- Nerd Font glyph icons replacing
  emoji throughout, a `network#speed` module added, floating-pill styling reworked
  with real design rationale in the comments (logical module grouping, one consistent
  hover accent instead of per-module colors, tooltips matching the theme).
- `nvim/lazy-lock.json`: routine plugin version bump from normal `nvim` use.

### Display managers: pruned to just the one actually in use

`packages/pacman.txt` had `sddm` (the one actually enabled and running), plus
`greetd` + `greetd-tuigreet` + `ly` installed and unused -- leftovers from earlier
experimentation. Removed the three unused ones from the manifest so a fresh install
doesn't carry them forward. **Not yet removed from this live machine** -- that needs
`sudo`, which this session doesn't have; see the note in `docs/ARCHITECTURE.md`.

### Docker + UFW: documented, not silently "fixed"

Docker manipulates `iptables` directly and can bypass UFW's rules for published
container ports -- a real gap, but checked `docker ps` first and confirmed **no
containers are currently running and no ports are currently published**, so there's
no live exposure today. Given that, and given this session has no `sudo` to test a
firewall change against, writing a specific `iptables`/`ufw` rule I can't verify would
be worse than not touching it -- a wrong firewall rule is a worse outcome than a
correctly-scoped gap. Documented the mechanism and the safe default (bind future
`-p` publishes to `127.0.0.1` explicitly) in `docs/ARCHITECTURE.md` instead.

## 2026-08-13

### Made the wallpaper fetcher bulletproof

Root cause of "sometimes the wallpaper script just crashes sway and I have to keep
reloading": found live in `journalctl --user -u wallpaper.service` — the Bing wallpaper
API occasionally returns a JSON status blob (`[{"success": true}]`) instead of image
bytes. The old script only checked the response was non-empty (`[ -s "$FILEPATH" ]`),
so that JSON got saved as `wallpaper-*.jpg`, symlinked to `current.jpg`, and handed
straight to `swaymsg output * bg ... fill` — which crashes `swaybg` (the process sway
actually delegates background rendering to) since it isn't a real image. The output
goes blank until something reapplies a valid background, which is what "reloading sway
until it works" was actually doing.

Rewrote `scripts/.local/bin/fetch_wallpaper.sh` around three fixes:

- **Actually validate the response is an image** (`file --mime-type`, not just
  non-empty) before it ever touches `current.jpg` or gets near `swaymsg`.
- **Check network connectivity first** (`nmcli networking connectivity check`) and
  give the download itself real timeouts (`--connect-timeout 10 --max-time 20`) and
  3 retries — previously an unreachable network meant an unbounded hang or a fast
  false failure, depending on how DNS/connect behaved that day.
- **Three-tier fallback**, in order: today's freshly-validated download → the last
  known-good wallpaper (`.last_good.jpg`, a stable copy outside the daily
  Active/Archive rotation so it can't itself get archived away or overwritten by a bad
  run) → a plain solid color via `swaybg`'s native `-c`/`solid_color` mode, which needs
  no image file at all and therefore cannot itself fail to parse. A brand-new machine
  with no wallpaper history yet and no network still gets a valid background, never a
  crash.
- Also fixed a latent bug in the *old* script's archiving order: it moved whatever was
  in `Active/` to `Archive/` **before** attempting the new download, so a bad response
  got archived right alongside the real history. Now archiving only happens after the
  new file is confirmed valid.
- Added `flock`-based locking (manual trigger and the daily timer could otherwise race
  each other) and structured logging to `~/.local/state/fetch-wallpaper/fetch-wallpaper.log`
  (simple size-based rotation) — every attempt, failure reason, and fallback decision is
  now visible there instead of the script being a black box between "works" and "crashed
  and I don't know why."

Verified against four scenarios before trusting it live: the real API (happy path), a
fake endpoint returning JSON (the actual historical failure, confirmed it falls back
instead of applying the bad response), an unreachable host (confirmed retry + fallback
to last-known-good), and a from-scratch machine with neither network nor prior
wallpaper history (confirmed the solid-color tier). Then ran it for real on this
machine and confirmed `swaybg` picked up the result correctly.

## 2026-08-13

### Tmux status bar: redesigned and fixed

- **Rebuilt the status bar around a single Catppuccin Mocha palette.** It had drifted
  into a mix of One Dark colors (session/window segments), unrelated Catppuccin accents
  (date/time), and a near-white docker pill (`#E5E9F0`) that clashed with everything
  around it. Now: Mauve (session) / Surface1+Green (windows) / Yellow (docker) / Peach
  (date) / Blue (time) — one dark ink color (`#1e1e2e`) for all pill text.
- **Fixed `bind r`** — it reloaded `~/.tmux.conf`, which hasn't existed since the config
  moved to `~/.config/tmux/tmux.conf`.
- **Fixed the actual glyphs, three times**, because each fix surfaced a new layer of
  the same problem:
  1. Two `.context/*.md` reference docs a redesign was based on turned out to have
     already lost their powerline-separator and docker-icon glyphs — saved as empty
     strings (`@sep_left ""`, `icon=$''`). Copying them verbatim just reproduced the
     loss, not a working config.
  2. Re-typing the glyphs directly into a file-write call *also* silently dropped
     them — something in that write path strips Private-Use-Area Unicode characters.
     Worked around it by writing the codepoints as `\uXXXX` escapes inside a Python
     heredoc run over the shell instead (plain ASCII in transit, decoded to real
     UTF-8 bytes at write time, which does survive).
  3. Once real bytes were landing, the docker icon still rendered as a tofu box —
     wrong codepoint, not a missing font. `U+F395` ("fa-docker") doesn't exist in
     `ZedMonoNerdFont-Regular.ttf`; verified the font's actual glyph coverage with
     `fc-query -f '%{charset}'` before picking a replacement, and switched to
     `U+F308` (`nf-linux-docker`), which the font does contain.
- Added a terminal icon (`U+F489`) in front of the session name — there wasn't one —
  and widened the gap after it once it looked cramped.
- `@continuum-boot` → `off`.

### Made the whole system reproducible from one command

Starting point: a stow-managed dotfiles repo (`~/dotfiles`) covering only
kitty/mako/nvim/sway/tmux/waybar/wofi/zed/zsh, no install script, and several real
(non-symlinked) files quietly living outside the repo entirely.

- **Found and fixed a live secret before it reached GitHub**: `zsh/.zshrc` had
  `GEMINI_API_KEY` hardcoded — uncommitted, but about to go out with the next push.
  Moved it to `~/.zshrc.local` (gitignored, matching the convention the README already
  documented) and had `.zshrc` source that file instead.
- **Vendored everything real-but-untracked**, converting each into a proper stow
  symlink once it was added to the repo:
  - `~/.tmux/scripts/docker_status.sh` → `tmux/.tmux/scripts/`
  - `~/.p10k.zsh` → `zsh/.p10k.zsh`
  - `~/.local/bin/{wf-recorder-toggle,wofi-calc,fetch_wallpaper}.sh` → new `scripts/` package
  - `~/.config/systemd/user/{wallpaper.timer,wallpaper.service,tmux.service}` → new `systemd/` package
  - `~/.config/gtk-{3,4}.0/settings.ini` → new `gtk/` package
  - `~/.config/mimeapps.list` → new `xdg/` package
- **Captured the full package set**: `packages/pacman.txt` (104 official packages) and
  `packages/aur.txt` (22 AUR packages), from `pacman -Qqe` / `pacman -Qqm`.
- **Wrote `install.sh`**, a single idempotent bootstrap script (see
  [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for what it actually does). Bugs
  caught before they shipped — each verified against real command behavior, not
  assumed:
  - `stow -n`'s actual conflict message format didn't match the first draft's parser;
    combined with `set -e -o pipefail` this would have aborted the whole script on the
    very first package, conflicting or not. Verified the real format in an isolated
    `/tmp` sandbox before trusting the parser.
  - `stow */` (both in the script and in the README's own manual instructions) would
    have tried to stow `.git` and `packages/` into `$HOME` — neither is a real
    package. Now built from an explicit, filtered directory listing.
  - `yay`'s stdin syntax for a package list isn't documented/verified the way
    `pacman -S -` is (confirmed straight from `pacman`'s own man page); switched both
    installs to `xargs -a` instead of trusting an unverified assumption about `yay`.
  - `sddm` was going to be `enable --now`'d mid-script, which would hijack the
    console before the rest of the script finished running. Now just `enable`d — it
    takes over on the reboot the script already tells you to do at the end.
  - The `*.local` gitignore rule (for override files like `.zshrc.local`) also matched
    a directory literally named `.local` — which silently swallowed the entire new
    `scripts/.local/bin/` package from `git status` without any error. Tightened the
    glob to `?*.local` (requires a real prefix before `.local`).
- **Theming**: GTK's `settings.ini` sets the theme *name*, but GNOME-aware apps read
  the active theme from dconf. Added `dconf write` calls for `gtk-theme` and
  `color-scheme` to the end of `install.sh` so a fresh install doesn't end up with the
  theme installed but not actually applied.
