# Changelog

Notable changes to this setup, in human terms — what changed, why, and what broke
along the way. Newest first.

## 2026-08-23

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
