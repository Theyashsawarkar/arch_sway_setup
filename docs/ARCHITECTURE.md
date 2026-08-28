# How this repo works

## The model

One repo, managed with [GNU Stow](https://www.gnu.org/software/stow/). Every top-level
directory except `packages/` and `docs/` is a **stow package**: its internal path
structure mirrors where it belongs under `$HOME`, and `stow <package>` symlinks it into
place. `tmux/.config/tmux/tmux.conf` becomes `~/.config/tmux/tmux.conf -> ../dotfiles/tmux/.config/tmux/tmux.conf`.
Nothing here is copied onto the live system — it's all symlinks, so editing
`~/.config/tmux/tmux.conf` and editing the file in this repo are the same action.

`packages/pacman.txt` and `packages/aur.txt` are the exception: plain package-name
manifests, not something stow ever touches.

## Package map

| Package    | Where it lands                         | What it's for |
| ---------- | --------------------------------------- | ------------- |
| `sway`     | `~/.config/sway/`                       | Window manager, keybindings, lock/idle config |
| `waybar`   | `~/.config/waybar/`                     | Top status bar |
| `wofi`     | `~/.config/wofi/`                       | App launcher / dmenu-style prompts |
| `nwg-bar`  | `~/.config/nwg-bar/`                    | Two small button-grid popup menus, both sharing one `style.css`: the power button (`bar.json`: Lock/Logout/Suspend/Reboot/Shutdown) and `docker.json`. See the changelog for why this isn't wofi -- its `--dmenu` mode hit several real, separately-confirmed limits for a *button-grid* popup specifically (no CSS cursor support, `--columns` capped at 2, `--hide-search` breaks rendering, `close_on_focus_loss` fights `focus_follows_mouse`) -- though wofi's `--dmenu` mode works fine for a plain scrolling list, see `networkmanager-dmenu`/`wifi-picker.py`/`bluetooth-picker.py` below. **Important, and it bit twice**: nothing in the `nwg-bar` invocation chain goes through a shell -- neither its own `exec` commands (`exec.Command()` directly, confirmed by reading the source) nor its `-t`/`-s` flag values (confirmed by testing `env nwg-bar -t '~/...'` directly -- it doesn't even detect a non-absolute path the way it does for the `icon` field, it just concatenates onto its default config dir and fails outright). **Never use `~` anywhere in an `nwg-bar` invocation or its JSON `exec` fields — always the absolute path.** Icons: either an absolute file path, or a name from the system icon theme (`createPixbuf()` falls back to `gtk.IconThemeGetDefault().LoadIcon()`) -- verify a given icon name actually exists in the installed theme (`find /usr/share/icons/<theme> -iname '<name>.svg'`) before using it, the same discipline as verifying Nerd Font codepoints elsewhere in this repo. **`volume.json`, `wifi.json`, and `bluetooth.json` used to exist here too, all three removed** -- `nwg-bar` only renders static buttons from a fixed JSON file (confirmed reading its Go source: no scale/slider/dynamic-list widget type exists in its schema at all, and its `launch()` fires a 150ms auto-`gtk.MainQuit()` after *every* click), so anything needing a live scan (Wi-Fi/Bluetooth devices) or continuous adjustment (volume) is architecturally impossible here -- looked like broken commands but was really just the wrong tool for the job. Volume/brightness, Wi-Fi, and Bluetooth are all handled below instead. |
| `bluetooth-picker.py` | `~/.local/bin/bluetooth-picker.py` (`scripts/` package) | Bluetooth device picker triggered from waybar's `bluetooth` module `on-click`, replacing `nwg-bar`'s static bluetooth.json (On/Off/Manager buttons, no device list). Same modal approach as `wifi-picker.py` deliberately -- wofi `--dmenu`, category colors, active-connection border-stand-in marker -- but fully self-contained rather than wrapping a third-party tool: checked first, and the only wofi/dmenu-adjacent Bluetooth picker that exists at all is a 3-year-stale rofi-specific AUR package (`rofi-bluetooth-git`), not worth depending on over a ~150-line direct script built on `bluetoothctl` (bluez 5.87 on this machine; confirmed via `bluetoothctl --help` that `devices Paired`/`devices Connected`/`info <mac>`/`--timeout <n> scan on` all exist and work as expected before writing anything against them -- note `paired-devices` is *not* a valid command in this bluez version, `devices Paired` is). Menu: power toggle, scan (bounded `--timeout 8` non-interactive scan, then relaunches itself to show a fresh list -- same self-relaunch pattern `networkmanager_dmenu` uses after its own rescan), Bluetooth Manager shortcut, paired devices (click connects/disconnects, whichever applies), and any device bluez currently knows about but hasn't paired with yet (`bluetoothctl devices` bare, minus the already-paired set -- populated by a scan; without this "Scan for Devices" would run a scan and then have nothing new to act on). Colors mirror `wifi-picker.py`'s categories directly: Sky for a paired device, Teal for a nearby-but-unpaired one (same meaning as `wifi-picker.py`'s "saved" Teal -- known/available, not the thing you're actively connected to), Peach for a command -- deliberately does not surface any WiFi-specific action, the same way `wifi-picker.py` now excludes the Bluetooth toggle it used to inherit from upstream (see the changelog). Selecting a nearby device pairs, trusts, and connects in one go, bounded to a 20s timeout -- most consumer audio/BLE gear uses passkey-less "just works" pairing and completes well within that, but a device that genuinely needs an interactive PIN prompt has nowhere for that prompt to go in this flow and will just time out with a message pointing at Bluetooth Manager instead. `run()` centrally catches `subprocess.TimeoutExpired` on every `bluetoothctl` call (connect/disconnect/pair can all hang waiting on a device that never responds) and turns it into an ordinary non-zero return code, rather than an uncaught traceback crashing the picker. |
| `networkmanager-dmenu` | `~/.config/networkmanager-dmenu/` | Wi-Fi picker triggered from waybar's `network` module `on-click` -- replaced `nwg-bar`'s static wifi.json (On/Off/Settings buttons, no scan list) with a real scan → click a network → password-prompt-if-needed → connect flow, plus Wi-Fi on/off toggle and a `nm-connection-editor` shortcut, all in one menu. From the official `extra` repo, not AUR. Uses `wofi --dmenu` as its menu backend (`dmenu_command = wofi` in `config.ini`) -- confirmed via reading the tool's own source (`networkmanager_dmenu`, the Python script itself) that it has first-class wofi support, not just generic dmenu-protocol compatibility: it auto-detects `wofi` and appends wofi's own `-P`/`--password` flag for the passphrase prompt (masks input, confirmed via `wofi --help` that flag exists locally), and has wofi-specific highlight markup for the currently-connected network. Smoke-tested `wofi --dmenu` with a piped test list before wiring this up, given this repo's prior history of real wofi `--dmenu` bugs (see the `nwg-bar` row above) -- rendered a normal solid popup with no issue, since those earlier bugs were specifically about forcing a *button-grid* layout through `--dmenu`, not this tool's plain vertical list usage. List entries show icon+name only (`format = {icon}  {name}` in `config.ini`) -- no visible signal%/bars/security text, `wifi_icons` (5 Material Design strength glyphs, `U+F092F`..`U+F0928`, verified present in the installed font via `fc-query` the same way every other icon in this repo is verified) carries the strength instead. **Wofi's dmenu list has no per-item hover-tooltip support at all** (checked: no such feature exists in wofi) -- so "see full detail on hover" genuinely isn't achievable with this tool, not a partial implementation of it. |
| `wifi-picker.py` | `~/.local/bin/wifi-picker.py` (`scripts/` package) | Themed wrapper around the installed `networkmanager_dmenu` -- waybar's `network` module `on-click` runs this instead of calling `networkmanager_dmenu` directly. Adds category-based colors (Sky for a real network, Peach for a command like Rescan/Enable/Disable/Launch-Editor, Teal for a saved connection) so the menu's different kinds of rows are visually distinguishable at a glance -- upstream only colors the single active/connected line, everything else renders identically. Loads `/usr/bin/networkmanager_dmenu` at runtime via `importlib` (`spec_from_loader` with an explicit `SourceFileLoader`, since `spec_from_file_location` can't infer a loader for a file with no `.py` extension -- returns `None` silently rather than raising, confirmed by hitting it) and monkeypatches exactly two functions (`get_wofi_highlight_markup`, `get_selection`) rather than forking the whole ~1500-line script -- every actual NetworkManager interaction still runs the real, maintained upstream code. Category is detected via `Action.func` identity (`process_ap` == a real network; `toggle_wifi`/`rescan_wifi`/`launch_connection_editor`/`delete_connection`/`show_wifi_password`/`prompt_saved` == a command) plus the `":SAVED"` suffix upstream already appends to saved-connection names -- wrapped in a `try/except AttributeError` so an upstream refactor degrades to "no color" instead of crashing the whole picker. **A real, confirmed pitfall while verifying this**: a background-launched test process reliably vanished between one tool call and the next in this remote session (`setsid ... &` in one shell invocation, checked with `pgrep` in a separate one) even though `setsid` should detach it -- the remote execution environment doesn't appear to preserve backgrounded processes across separate calls the way a persistent terminal would. This produced a false "the colors aren't rendering" result once, from screenshotting a stale/empty window. The real fix for testing this kind of thing here: launch, wait, and screenshot all within one single tool call -- confirmed correct rendering (Sky/Mauve/Teal all found via pixel search in a live window) once tested that way. |
| `mako`     | `~/.config/mako/`                       | Notifications |
| `kitty`    | `~/.config/kitty/`                      | Terminal, incl. the Nerd Font setting everything else depends on |
| `tmux`     | `~/.config/tmux/`, `~/.tmux/scripts/`   | Multiplexer config + the docker status-bar script |
| `nvim`     | `~/.config/nvim/`                       | Editor |
| `zed`      | `~/.config/zed/`                        | GUI editor |
| `zsh`      | `~/.zshrc`, `~/.p10k.zsh`                | Shell + prompt (oh-my-zsh and its plugins are bootstrapped by `install.sh`, not vendored — see below) |
| `scripts`  | `~/.local/bin/`                         | Utility scripts wired into sway keybindings and the wallpaper timer |
| `systemd`  | `~/.config/systemd/user/`               | User units: daily wallpaper fetch, optional detached tmux session |
| `gtk`      | `~/.config/gtk-{3,4}.0/`                | GTK theme selection (Catppuccin Mocha) |
| `xdg`      | `~/.config/mimeapps.list`               | Default app associations (browser, image viewer, etc.) |


## Why some things *aren't* here

Not everything under `~/.config` is vendored. Deliberately excluded:

- **Auth/session state**: `gh`, `github-copilot`, `.claude*`, `.gemini`, browser
  profiles (`BraveSoftware`, `chromium`, `google-chrome`, `mozilla`, `zen`). These
  contain credentials or get regenerated the first time you log into each tool — they
  don't belong in a public repo and `install.sh` doesn't try to restore them.
- **Caches/generated state**: `dconf` (mostly — see below), `go`, `yarn`, `npm`,
  `pgcli`/`btop`/`lazygit` app state, `xfce4` (only contained Thunar's stock example
  custom action, not real configuration).
- **Secrets**: never committed, ever. See "Secrets" below.

If you add a new tool and aren't sure which bucket it falls into: does deleting it
lose your login, or just some cache/history you don't mind rebuilding? If the former,
leave it out.

## Secrets

Convention (already the one in the README before this was written up): anything
machine-specific or sensitive goes in a `*local` file that isn't part of any stow
package and is gitignored (`?*.local` in `.gitignore` — note the `?*`, not `*`; a bare
`*.local` glob would also match a directory literally named `.local`, which is exactly
what `scripts/.local/bin/` needs to exist as).

Example already in use: `zsh/.zshrc` ends with
```sh
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```
and `~/.zshrc.local` (not in the repo) holds `export GEMINI_API_KEY=...`. Follow the
same pattern for anything else that needs a real secret.

## `install.sh`, step by step

Entry point for a from-scratch machine (see README's Quick Start). Runs as your normal
user, `sudo` where it needs root:

1. Install `git`, `stow`, `base-devel`.
2. Clone this repo to `~/dotfiles` (or `git pull --ff-only` if it's already there —
   the whole script is meant to be re-run safely).
3. Build the package list dynamically: every top-level directory except `packages/`
   and dotfiles (`.git`, ...). This is why adding a new stow package to this repo
   needs no change to `install.sh` itself.
4. Install every package in `packages/pacman.txt`, then bootstrap `yay` if missing and
   install `packages/aur.txt`. Both use `xargs -a file command` rather than piping a
   package list on stdin — deliberate, see the changelog for why.
5. Dry-run `stow -n` against every package first, to catch anything real (not a
   symlink) already sitting at a target path — a fresh Arch install's skeleton
   `.bashrc` etc. would otherwise make the real `stow` call abort. Anything real gets
   moved to `~/.dotfiles-backup/` before the real `stow` runs.
6. `stow` everything for real.
7. `chsh` to zsh if it isn't already the shell.
8. Bootstrap oh-my-zsh (official installer, `RUNZSH=no CHSH=no KEEP_ZSHRC=yes` so it
   doesn't launch a shell or clobber the `.zshrc` stow just placed), then clone
   Powerlevel10k + the two zsh plugins referenced in `.zshrc`'s `plugins=(...)` list.
9. Clone TPM (tmux's plugin manager) if missing.
10. Download the ZedMono Nerd Font straight from its own upstream release (the URL is
    documented inside the font's own bundled `README.md` — this repo doesn't vendor
    the ~700MB of font files, since none of the standard Arch/AUR packages ship this
    particular one).
11. Bootstrap Homebrew if missing, then `brew install gh pnpm`.
12. Enable + start the services this machine actually runs (`NetworkManager`, `iwd`,
    `bluetooth`, `docker`, `power-profiles-daemon`, `ufw`); `sddm` is *enabled* but not
    started immediately, since starting a display manager mid-script would hijack the
    console you're running the script from — it takes over on the reboot the script's
    final message tells you to do anyway.
13. Add yourself to the `docker` group.
14. Enable the `wallpaper.timer` user unit.
15. Apply the GTK theme via `dconf write` — the `gtk/` package's `settings.ini` sets
    the theme *name*, but GNOME-aware apps actually read the active theme/color-scheme
    from dconf, so both need to happen for the theme to actually show up.

It has been syntax-checked, had its trickier logic (the stow conflict-detection
parser, the `.gitignore` glob, a full 13-package stow simulation against realistic
`/etc/skel` files) verified in isolated sandboxes, every package name in
`packages/*.txt` confirmed to actually resolve (`pacman -Si`/`yay -Si`), every external
URL confirmed reachable, and every systemd service name it enables confirmed to exist.
That verification pass found and fixed a real install-breaking bug: `pacman.txt` had
15 AUR-only packages duplicated into it (from how the manifests were first generated —
see the changelog), and `pacman -S` aborts its *entire* transaction if even one target
doesn't exist in the official repos, so the original file would have failed to install
anything at all on a truly fresh machine. What's still missing is a single, real,
uninterrupted run against an actual blank machine — this machine already has
everything it does in place, so a live run here would be a no-op, and that one gap
genuinely needs a spare VM or drive to close.

## exec order matters: dbus-update-activation-environment must come first

`sway/config`'s very first `exec` is `dbus-update-activation-environment --all`. This
has to run before *anything* that starts a systemd `--user` service (`swayidle.service`,
`sway-audio-idle-inhibit.service`) — those services run under the systemd user
manager, a separate process from sway with its own environment, and it has no idea
`WAYLAND_DISPLAY`/`SWAYSOCK` exist until this command imports them. Get the order
wrong and those services crash-loop with "Unable to connect to the compositor" —
happened for real once, see the changelog. If you add another systemd `--user`
service that needs to talk to sway, its `exec systemctl --user start ...` line needs
to come after this one.

Note this only matters at sway's actual startup: plain `exec` lines (unlike
`exec_always`) don't re-run on `swaymsg reload`, so testing an exec-order fix via
reload alone won't catch an actual ordering bug — it only shows up on a real fresh
login.

## Idle management: swayidle as a systemd user service, plus caffeine mode

`swayidle` (screen dimming, lock, suspend timeouts — `sway/.config/sway/idle/config`)
runs as a systemd user service, `systemd/.config/systemd/user/swayidle.service`, not a
raw `exec` line. `sway/config` starts it with `exec systemctl --user restart
swayidle.service` rather than launching the process directly.

This exists specifically so caffeine mode — the coffee-cup icon in waybar,
`custom/caffeine` — can be trivial and reliable: on is `systemctl --user stop
swayidle.service`, off is `systemctl --user start swayidle.service`. No PID files, no
state tracking; systemd's own active/inactive state *is* the caffeine state, which
`caffeine-status.sh` just reads back for the waybar icon. Stopping the whole service
(rather than e.g. a `systemd-inhibit` suspend lock) is deliberate — an inhibitor
wouldn't stop swayidle's own `timeout 600 swaymsg output * dpms off` line, since that
never goes through logind at all. Only actually stopping swayidle keeps the screen on.

An earlier version managed this with raw `pkill`/background-and-`disown` instead of
systemd, and hit a real hang: the backgrounded process ended up stuck as a direct
child of the toggle script (visible via `pstree` and `/proc/<pid>/wchan` = `do_wait`).
Systemd unit start/stop doesn't have that failure mode.

## The wallpaper pipeline is the ONLY wallpaper pipeline

There used to be a second, untracked script (`~/scripts/fetch-bing.sh`) firing on
every sway reload via `exec_always`, independent of the `wallpaper.timer`-driven one
below. It's gone now (see the 2026-08-23 changelog entry for the full story) --
`fetch_wallpaper.sh` via the daily timer is the only thing that changes the wallpaper.
If you ever see wallpaper-related `exec`/`exec_always` lines back in `sway/config` in
the future, that's a regression, not a feature.

## The wallpaper pipeline, and why it can't crash sway anymore

`systemd/.config/systemd/user/wallpaper.timer` fires `wallpaper.service` once a day,
which runs `scripts/.local/bin/fetch_wallpaper.sh`. The manual `output * bg ... fill`
line in `sway/.config/sway/config` only sets the background once, at sway startup —
this script is what keeps it updated day to day, and what applies it live via
`swaymsg` without needing a sway restart.

It's built so that no single failure — API downtime, a malformed response, no network,
or a totally fresh machine with no wallpaper history yet — can leave sway without a
background or crash `swaybg` (the helper process sway delegates background rendering
to; a bad image crashes *it*, not sway itself, but the visible symptom — background
gone, needs a reload to fix — reads the same from the outside):

1. **Network check** (`nmcli networking connectivity check`) skips a doomed attempt
   outright; not authoritative on its own, since the download's own timeouts are the
   real check.
2. **Download with retries** (3 attempts, `--connect-timeout 10 --max-time 20` so a
   flaky connection fails fast instead of hanging).
3. **Validate the response is actually an image** (`file --mime-type`, not just
   "non-empty") before it's allowed anywhere near `current.jpg` or `swaymsg`. This is
   the fix for the actual historical bug: the API occasionally returns a JSON status
   blob instead of image bytes, which used to sail straight through to `swaybg` and
   crash it.
4. **Three-tier fallback** if 1–3 don't produce a valid image: today's download →
   `.last_good.jpg` (a stable copy kept outside the `Active/`/`Archive/` rotation,
   updated only after a successful validation, so a bad day can never overwrite or
   archive it away) → a plain solid color via `swaybg -c`/`solid_color` mode, which has
   no image to parse and therefore can't itself fail. Tier 3 is what makes a from-scratch
   machine safe on day one, before any fetch has ever succeeded.
5. **`flock`** so the timer and a manual run can't race each other.

**Logging**: `~/.local/state/fetch-wallpaper/fetch-wallpaper.log` (rotated at ~1MB,
one previous copy kept) has every attempt, failure reason, and which fallback tier
fired. Also visible live via `journalctl --user -u wallpaper.service`. If the wallpaper
ever looks stale or wrong, that log is the first thing to check — it will say exactly
which of the three tiers actually ran, rather than leaving you guessing.

## Volume and brightness: real controls, not nwg-bar buttons

Both used to be `nwg-bar` button popups (`volume.json`, and no popup at all for
brightness). Neither belongs in a button grid -- adjusting volume/brightness is
fundamentally a "drag to a value" interaction, and `nwg-bar` categorically can't
render one (buttons only, confirmed reading its Go source). Replaced with:

- **`pulseaudio` waybar module**: click = mute/unmute (`sway/.config/sway/scripts/volume_osd.sh
  mute-toggle`), right-click = `pavucontrol` (a real GTK mixer with per-device drag
  sliders and separate Playback/Recording/Output Devices/Input Devices tabs -- this is
  where output *and* microphone device selection actually happens, for free, and it
  already renders in Catppuccin Mocha since the GTK3 theme is applied system-wide, no
  extra CSS needed), scroll = +-5% (`volume_osd.sh +5%`/`-5%`).
- **`backlight` waybar module**: click = `scripts/.local/bin/brightness-slider.sh`, a
  `zenity --scale --print-partial` dialog -- `--print-partial` streams the live value
  on every drag frame, piped into `brightnessctl set "${value}%"` per line, so it's a
  genuine real-time slider rather than a set-once popup. Needs `zenity` (in
  `packages/pacman.txt`, official `extra` repo). Scroll = +-5%
  (`brightness_osd.sh`), unchanged.
- Both `volume_osd.sh` and `brightness_osd.sh` (`sway/.config/sway/scripts/`) are
  shared between the `XF86Audio*`/`XF86MonBrightness*` keybindings *and* the waybar
  scroll bindings now, so there's exactly one place that fires the progress-bar mako
  notification for each, not two copies drifting apart. `volume_osd.sh` also
  auto-unmutes before applying a delta (raising/lowering volume should always be
  audible) and gained a `mute-toggle` mode used by both the `XF86AudioMute` key and
  the waybar click. `XF86AudioMicMute` was added alongside it
  (`pactl set-source-mute @DEFAULT_SOURCE@ toggle`) -- there wasn't a microphone-mute
  keybinding at all before.

### The scroll flood, and why on-scroll needs `smooth-scrolling-threshold`

Scrolling on the volume/brightness pills looked broken -- confirmed via
`/tmp/waybar.log`, which had 249 lines of `Connection failure: Connection
terminated` and `Value "" of hint "value" could not be parsed as type "int"` after
one scroll session. Root cause, found in waybar's own man pages
(`man waybar-pulseaudio`, `man waybar-backlight`): defining `on-scroll-up`/
`on-scroll-down` "replaces the default behaviour" *and* neither module had
`smooth-scrolling-threshold` set (default is unset/0). A touchpad emits continuous
fractional scroll deltas (kinetic/smooth scrolling), not one discrete tick per
gesture -- with the threshold at 0, waybar fired the script on every single delta,
so one real scroll gesture spawned dozens of `pactl`/`brightnessctl`/`notify-send`
processes within milliseconds, flooding mako's D-Bus connection and racing each
other reading volume/brightness mid-write. Fixed by adding
`"smooth-scrolling-threshold": 1` to both modules, so waybar accumulates a full
scroll unit before firing once.

**Forcing the same burst manually (30 concurrent invocations) also surfaced a real,
separate danger**: `pactl set-sink-volume @DEFAULT_SINK@ +5%` does **not** clamp at
100% on its own -- the 30-way race drove the sink to 1494% (confirmed no audio was
actively playing at the time, via `pactl list sink-inputs short`, so nothing was
physically blasted, but it would have been audible/damaging if something had been).
`brightnessctl` does self-clamp (`set 1000%` lands at exactly 100%, confirmed by
testing), so no equivalent overdrive risk there, but concurrent calls can still
stack out of order. Both scripts now serialize their read-current -> compute-target
-> apply sequence behind `flock` (`/tmp/volume_osd.lock` / `/tmp/brightness_osd.lock`),
and `volume_osd.sh` computes and clamps the target to 0-100 itself rather than
trusting pactl's relative math. Re-ran the identical 30-concurrent-call burst after
the fix: clamps land exactly at 100%/0% instead of overshooting, and the waybar log
stayed at zero errors.

## The tmux status bar's dependency chain

Worth calling out on its own, since it broke in layers (see changelog): the rounded
separators and the session/docker icons are Nerd Font Private-Use-Area glyphs. They
need *both* the exact right codepoint in `tmux.conf`/`docker_status.sh` *and* a Nerd
Font actually installed and selected in your terminal (`kitty.conf`'s `font_family`).
Missing either one renders as a blank box, and the two failure modes look identical —
if a fresh machine shows boxes, check the font first (`fc-query -f '%{charset}' <font
file>`, and confirm the codepoint tmux is using is actually in there) before assuming
the config is wrong.

## The one true font: JetBrainsMono Nerd Font

Every config that renders text with icons — `kitty`, `tmux`, `sway` (window
title/border font), `mako`, `wofi`, `zed`, `waybar` — uses `"JetBrainsMono Nerd Font"`.
One font, one pacman package (`ttf-jetbrains-mono-nerd`), zero manual downloads. This
used to be `ZedMono Nerd Font`, a ~700MB manual download from its own upstream nerd-fonts
release with no package-manager equivalent; migrated everything off it (see
2026-08-23 in the changelog for the full story, including a real mistake made along
the way — the font directory got deleted before every reference to it had been found).
If you're about to add a new app to this setup and it wants a monospace/icon font,
use this one unless you have a specific reason not to — consistency here is what made
the tmux/waybar glyph debugging tractable in the first place.

## Known gaps that need root, not left silently unfixed

Two things identified during an optimization pass that this environment could not
apply itself (no `sudo` access here) — flagged explicitly rather than either faking a
fix or silently skipping them:

- **Unused display managers still installed on the live machine.** `packages/pacman.txt`
  no longer lists `greetd`, `greetd-tuigreet`, or `ly` (pruned so a *fresh* install
  won't carry them forward), but they're still actually installed on this machine.
  To remove them here too:
  ```bash
  sudo systemctl disable greetd ly 2>/dev/null
  sudo pacman -R greetd greetd-tuigreet ly
  ```
- **`systemd-networkd-wait-online.service` was eating ~2 minutes of every boot**,
  waiting for `wlan0` to become "routable" through `systemd-networkd` — which can
  never happen, because `NetworkManager` already owns that interface. Separately,
  `iwd.service` was enabled and running unused (NetworkManager's real wifi backend is
  `wpa_supplicant`). Fixed in `install.sh` (no longer enables `iwd` as a service — the
  package stays, for `iwctl`'s use bootstrapping Wi-Fi from a bare TTY). **Not yet
  fixed on the live machine** — needs `sudo`:
  ```bash
  sudo systemctl disable --now iwd.service
  sudo systemctl disable --now systemd-networkd-wait-online.service systemd-networkd.service
  ```
  `systemd-resolved` is genuinely in use (confirmed via `resolvectl status`) and
  should stay enabled — don't touch it while cleaning this up.
- **Docker can bypass UFW.** Docker manipulates `iptables` directly for published
  container ports (`-p`), which UFW's rules don't see. See
  **[docs/DOCKER_SECURITY.md](DOCKER_SECURITY.md)** for the full mechanism, what was
  actually checked on this machine (no live exposure as of the last check — nothing
  published), and a concrete two-layer fix: a zero-config habit (bind to `127.0.0.1`)
  plus `docs/harden-docker.sh` + `docs/docker-user-rules.service`, a `DOCKER-USER`-chain
  script for when you do need to publish something. Neither script is auto-run by
  `install.sh` or wired into any stow package — deliberately opt-in, since it changes
  network-filtering behavior and hasn't been tested against this system (no `sudo` in
  this session).
