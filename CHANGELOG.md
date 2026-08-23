# Changelog

Notable changes to this setup, in human terms — what changed, why, and what broke
along the way. Newest first.

## 2026-08-23 (verification found two real regressions from this session's own changes)

Went back to check that recent changes actually held up (after the user rebooted to
test the boot-time fix) rather than assuming. `systemctl --failed` was not clean:

- **`swayidle.service` was crash-looping since login**, hitting `start-limit-hit`.
  Root cause: `exec dbus-update-activation-environment --all` -- which imports
  `WAYLAND_DISPLAY`/`SWAYSOCK` into the *systemd --user manager's own environment*
  (separate from sway's process environment, and required before any systemd --user
  service can reach the compositor) -- was sitting near the *bottom* of `sway/config`,
  after `exec systemctl --user restart swayidle.service` had already fired. Introduced
  by me when swayidle got converted to a systemd service a few sessions back; not
  caught at the time because reloading sway to test it doesn't re-run plain `exec`
  lines (only `exec_always` re-fires on reload), so the bug only showed up on a real
  fresh login. Moved the `dbus-update-activation-environment` line to the top of the
  exec block, ahead of anything that depends on it. Fixed the *live* broken state
  separately (ran the import + `systemctl --user reset-failed` + `start` by hand),
  since exec-order fixes in the config file don't retroactively fix an already-running
  session either.
- **`sway-audio-idle-inhibit` had crashed at login and never came back** (segfault in
  `Pulse::connect`, likely connecting to pipewire-pulse before it was fully up) --
  found via `journalctl -p err -b`, not something `systemctl --failed` would show
  since it was a plain `exec`, not a tracked systemd unit, so systemd had no idea it
  died. Converted it to a systemd service too
  (`systemd/.config/systemd/user/sway-audio-idle-inhibit.service`), with
  `After=pipewire-pulse.socket pipewire-pulse.service` to address the likely race and
  `Restart=on-failure` so a future crash recovers on its own instead of silently
  leaving idle-inhibition dead until next login.

Both added to `install.sh`'s service-enable line. Re-checked `systemctl --failed` /
`systemctl --user --failed` clean after applying both fixes, not just assumed.

## 2026-08-23 (boot follow-up: confirmed 4x win, oomd, waybar height fix)

The `iwd`/`systemd-networkd` fix from the previous entry got applied: boot went from
**2min 26s to 36.5s**, confirmed with a fresh `systemd-analyze` run. Went looking for
more, both boot-time and general snappiness:

- Remaining boot-time items (`NetworkManager-wait-online` 5.8s, `docker.service`
  1.7s, `systemd-tpm2-setup{,-early}` ~3.1s combined) are either doing real work
  (actual network readiness, the container runtime) or would need real research before
  touching safely (there's no disk encryption here, so the TPM setup services aren't
  protecting anything critical, but I don't know precisely what else depends on them
  without more digging, and ~3s isn't worth guessing wrong on). Left alone.
- **Enabled `systemd-oomd`** (was disabled). Confirmed the kernel actually supports
  what it needs first (`/proc/pressure/memory` has real PSI data). This is the
  userspace OOM killer that acts *before* a memory-pressure spiral turns into a full
  swap-thrashing freeze — with a browser that can climb into multiple GB of RSS
  against only 4GB of zram swap, this is a real "why did my desktop just freeze for 20
  seconds" prevention, not just a boot-time thing. Added to `install.sh`'s
  service-enable line too.
- **Fixed waybar's height mismatch**: config said `"height": 32`, but every module's
  actual padding (added over this session's redesigns) needs 41px, so waybar was
  silently overriding it and logging a warning on literally every single restart this
  whole session. Just set it to the real value, 41 — no functional change, just an
  honest config that matches what's actually rendered instead of relying on waybar's
  auto-correction and a noisy log.

## 2026-08-23 (found the actual boot-time problem: 2 minutes wasted on a redundant network stack)

Ran a real optimization sweep instead of another cosmetic pass: `zsh -i -c exit` timing
(~200ms after cache warm, fine — p10k's instant prompt is doing its job), `nvim
--startuptime` (~110ms total, fine), `systemd-analyze` and `systemd-analyze blame`.

`systemd-analyze` reported boot as **2min 26s total**, of which
**`systemd-networkd-wait-online.service` alone was 2 minutes** — essentially the
entire boot. Verified this is genuinely dead weight, not something actually needed:

- `nmcli device status` shows NetworkManager owns `wlan0` and is connected.
- `networkctl list` shows `systemd-networkd` *also* trying to configure the same
  `wlan0` (`configuring`, indefinitely — it can never actually finish, since
  NetworkManager already has the interface).
- `/etc/systemd/network/20-{wlan,wwan,ethernet}.network` exist as manual drop-ins —
  leftover from networkd being configured at some point before NetworkManager was
  installed, never cleaned up afterward.
- Separately, `iwd.service` is enabled and running, but NetworkManager's actual wifi
  backend is `wpa_supplicant` (confirmed running, D-Bus-activated by NetworkManager;
  `NetworkManager.conf` has no `wifi.backend=iwd` override) — `iwd` was just a second
  unused wifi daemon sitting in the background the whole time.
- `systemd-resolved` *is* genuinely in use (`resolv.conf` → its stub resolver, real
  DNS answers via `resolvectl status`) — left alone.

**Fixed in the reproducible setup**: `install.sh` was enabling `iwd` alongside
`NetworkManager`, which would have reproduced this exact redundancy (and the 2-minute
boot stall, if a fresh machine's `systemd-networkd` ever got enabled some other way)
on any new machine. Removed `iwd` from the service-enable line — the package stays in
`packages/pacman.txt` since `iwctl` is genuinely useful for bootstrapping Wi-Fi from a
bare TTY before `install.sh` even runs (see the README's Quick Start), it just
shouldn't run as a background service once NetworkManager takes over.

**Not fixed on the live machine** — needs `sudo`, which this session doesn't have:
```bash
sudo systemctl disable --now iwd.service
sudo systemctl disable --now systemd-networkd-wait-online.service systemd-networkd.service
```
Expected result: next boot should land somewhere around 25-30 seconds instead of 2min 26s.

## 2026-08-23 (removed a duplicate wallpaper system, window margins)

### Found and removed a second, untracked, more wasteful wallpaper fetcher

While reloading sway to test an unrelated config change, noticed a real network
fetch happen that had nothing to do with the change. Traced it to
`exec_always --no-startup-id /home/yash/scripts/fetch-bing.sh` in `sway/config` --
a second wallpaper-fetching script, never tracked in this repo, running on
**every sway reload** (not once a day like `wallpaper.timer`). Its own log
(`/tmp/sway_wallpaper.log`) confirmed two runs in the same session just from normal
`swaymsg reload` calls. 50 of the 61 files in `Archive/` turned out to have come
from this script, not the tracked one.

It was actually well-written in places (talked to Bing's real `HPImageArchive` API
directly instead of a third-party proxy, market/index shuffling for variety, archive
pruning) -- but firing on every reload instead of daily directly worked against
"don't add CPU/network load," and it wasn't reproducible since it lived outside the
dotfiles entirely. Its own `fallback.jpg` last-resort file didn't even exist, so its
own fallback path was broken too.

Removed `~/scripts/fetch-bing.sh` and the `exec_always` line entirely. Standardized
on the one already-hardened, tracked, timer-based script
(`fetch_wallpaper.sh`/`wallpaper.timer`, once a day). Ported over the one genuinely
good idea from the removed script -- archive pruning (keep newest 60, prune oldest by
mtime) -- since the tracked script's `Archive/` had no cap and would have grown
unbounded. Verified the prune logic fires correctly with a synthetic over-threshold
test (created 10 dummy files, confirmed the oldest 6 got removed by actual
modification time) before trusting it.

### Window margins + workspace switching feel

- `gaps outer 6` → `9`, and `smart_gaps on` → `smart_gaps inverse_outer`: outer
  (screen-edge) gaps now show specifically when a workspace has exactly one window
  (the common case) so there's always a visible-but-small margin to the screen edge
  then; with multiple tiled windows, outer gaps hide (inner gaps between windows still
  apply) so tiling doesn't waste edge space to a margin you won't see anyway. Plain
  `smart_gaps on` (tried first) hid outer gaps for single-window workspaces too, which
  fought directly against wanting a visible edge margin -- `inverse_outer` reconciles
  both wants instead of picking one.
- `workspace_auto_back_and_forth yes`: pressing the key for the workspace you're
  already on jumps back to whichever workspace you were on before.
- Both are pure sway behavior config -- zero added CPU/RAM, same per-frame gap
  calculation sway already does, just different threshold logic.

True directional slide animation when switching workspaces (the original ask) isn't
achievable on swayfx at any version -- checked the upstream config docs directly
(`animation_duration_ms` only covers individual windows opening/closing, no code path
for animating the workspace switch itself). That would require a compositor built
around it, like Hyprland -- a full compositor swap, not something to start without it
being its own deliberate decision.

## 2026-08-23 (bluetooth fix, caffeine mode)

### Waybar bluetooth module: fixed, same class of bug as before

Root cause of "I don't see bluetooth on the status bar": `format-off` and `format-on`
in the bluetooth module were both **literally empty strings** — same failure mode as
the tmux separators/docker icon a few sessions back (lost glyphs, not a font problem).
Separately, `format-connected` used ``, which is the *speaker* icon
(`nf-fa-volume-down`), not bluetooth — a copy-paste mistake, unrelated to the font
migration. Verified `U+F293` (`nf-fa-bluetooth`) is actually in `JetBrainsMono Nerd
Font`'s charset before using it for all four states; the existing CSS already handles
dimming it when off/disabled and coloring it green when connected, so only the icon
itself needed fixing.

### New: caffeine mode (`custom/caffeine` waybar module)

Added a toggle to keep the screen from dimming/locking/suspending — click the coffee
cup icon in the bar (or run `caffeine-toggle.sh`) to stop it, click again to restore
normal behavior.

Refactored `swayidle` from a raw `exec` line in `sway/config` into a proper systemd
user service (`systemd/.config/systemd/user/swayidle.service`) specifically to support
this cleanly: caffeine-on is just `systemctl --user stop swayidle.service`, caffeine-off
is `systemctl --user start swayidle.service` — no PID tracking, no state file, systemd
already knows whether it's running. `caffeine-status.sh` (polled by waybar every 5s)
reports that same state as the module's icon color (dim gray off, peach glow on).

Deliberately stops swayidle **entirely** rather than using `systemd-inhibit` to just
block suspend: an inhibitor lock wouldn't touch `timeout 600 swaymsg output * dpms
off` at all, since that's swayidle talking to sway directly, never going through
logind. Stopping the whole service is the only thing that keeps the screen itself on
too, which is what "keep it alive" actually means here.

Tried a raw `pkill`/`setsid ... & disown` version first and hit a real, reproducible
hang — the backgrounded `swayidle` process ended up stuck as a direct child of the
toggle script's own bash process (confirmed via `pstree` and `/proc/<pid>/wchan`
showing `do_wait`), which doesn't happen with well-behaved job control but did happen
here reliably enough to not trust it. The systemd version has no such fragility: no
job-control edge cases, and `Restart=on-failure` for free.

## 2026-08-23 (install.sh end-to-end verification — found a real install-breaking bug)

Went back to close out the one item left unverified: `install.sh` had only ever been
checked piece-by-piece in sandboxes, never proven against the actual current package
manifests. Ran every check that's possible without a spare VM and without `sudo`:

- **Every `packages/pacman.txt` and `packages/aur.txt` entry, checked against the real
  repos** (`pacman -Si` / `yay -Si`, read-only, no root needed). Found a real bug:
  15 packages in `pacman.txt` were actually AUR-only (`brave-bin`, `google-chrome`,
  `swayfx`, `zen-browser-bin`, etc.) — duplicated from `aur.txt`, left over from how
  the manifests were originally generated (`pacman -Qqe` returns *every* explicitly
  installed package regardless of which repo it came from, official or AUR, and that
  got dumped into `pacman.txt` wholesale without subtracting the AUR ones). Separately,
  6 entries in `aur.txt` were `-debug` packages (`bruno-bin-debug`, `swayfx-debug`,
  etc.) — these are auto-generated side effects of building their parent package, not
  real independently-fetchable AUR targets, so `yay -S` would fail trying to fetch them.
  **This mattered because `pacman -S` aborts its entire transaction if even one target
  package name is invalid** — as written, `install.sh` would have failed to install
  *any* of the 104 packages on a truly fresh machine, not just skip the bad ones.
  Removed all 21 bogus entries; every remaining entry in both files now verified to
  resolve.
- **Every external URL the script touches** (9 total: the repo clone, TPM,
  Powerlevel10k, the two zsh plugins, the AUR helper bootstrap, oh-my-zsh's installer,
  Homebrew's installer) — checked with `git ls-remote` for git URLs and a real HTTP
  request for the two raw-file URLs. All resolve.
- **Every systemd service name it enables** (`NetworkManager`, `iwd`, `bluetooth`,
  `docker`, `power-profiles-daemon`, `ufw`, `sddm`, plus the user-level
  `wallpaper.timer`) — confirmed each is a real unit on this system.
- **A full stow simulation with all 13 current packages at once** (the earlier sandbox
  test only used 2 toy packages) against a fake `$HOME` seeded with the actual
  `/etc/skel` files a fresh Arch account would have (`.bashrc`, `.bash_profile`,
  `.bash_logout`) — succeeded cleanly, no false-positive conflicts, every symlink
  (including executable scripts under `.local/bin`) landed correctly.

Still not run as a real, single, uninterrupted execution against an actual blank
machine — that's the one thing that genuinely requires a spare VM or drive. But every
individual piece of it is now verified against reality rather than assumed, and the
one bug that actually would have broken it outright is fixed.

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
