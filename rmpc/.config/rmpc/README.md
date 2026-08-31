# rmpc

Terminal music player, replacing termusic entirely -- "let's use a
better tui or cli local music player, remove this damn termusic",
reported directly once it became clear termusic's own search was going
to stay broken (the public Invidious network it depended on is dead
across the board, see `docs/ARCHITECTURE.md`). Rather than keep
termusic around as a half-used shell with `music-search.py` doing all
the actual work, swapped the player itself out too.

Directly in Arch's official `extra` repo (`packages/pacman.txt`), same
as `mpd` -- no AUR, no building Rust from source. Actively maintained
(3.3k GitHub stars, pushed days before this was set up), and its own
tagline says the thing directly: *"A beautiful and configurable TUI
client for MPD."*

## It's an MPD client, not standalone

rmpc has zero playback logic of its own -- it's purely a UI on top of
`mpd.service` (`../../mpd/`), which is the thing that actually plays
music and indexes `~/Music`. This split is a real strength for exactly
the problem that broke termusic: MPD is one of the most mature, boring,
reliable pieces of music-playing infrastructure there is, completely
decoupled from anything as fragile as a public API network. Closing
rmpc entirely wouldn't even stop playback, since MPD keeps running
independently either way.

rmpc *also* ships its own yt-dlp-based YouTube downloader
(`shared/ytdlp/` in its own source, confirmed by reading it directly --
genuinely yt-dlp-backed, not Invidious) -- a nice validation that the
same approach `music-search.py` takes was the right call, but its own
CLI picker (`dialoguer::Select`, a plain text list) has no thumbnail
support, so `music-search.py` (wofi-based, real thumbnails) stays the
actual search tool. rmpc just plays whatever lands in `~/Music`
afterward, same as any other track.

## Launch

`$mod+Shift+m` (`sway/config`) opens it in its own floating kitty
window (`kitty --class rmpc -e rmpc`, `for_window [app_id="^rmpc$"]`
sizes it to 1152x540 -- 60%/50% of this machine's actual output -- and
centers it), toggling via sway's scratchpad on a second press
(`rmpc-toggle.sh`) -- same pattern already proven for termusic before
it, still correct here: hiding the window only ever changes visibility,
playback (owned entirely by MPD, not rmpc's own process) is untouched
either way.

## Theme

`themes/catppuccin-mocha.ron` -- not an existing theme adopted from
somewhere, built from rmpc's own real defaults: `rmpc theme` dumps the
actual default theme (confirmed this is genuinely how rmpc bootstraps a
custom theme, not guessed), which turned out to be a single, deeply
nested RON structure with named colors ("blue", "yellow", "black", ...)
woven throughout the entire layout definition, not a separate flat
palette. Every named color got substituted for its Catppuccin Mocha hex
equivalent systematically (`"blue"` specifically became Mauve
`#cba6f7`, not Catppuccin's own literal Blue -- in rmpc's own default
theme, "blue" is the color used for every "this is active/current/
selected" role, exactly the role Mauve already plays everywhere else in
this desktop, so mapping it there keeps this tool visually consistent
with the rest of the setup instead of introducing a second, unrelated
accent color).

`background_color`/`header_background_color` left as `None` --
confirmed hex colors are supported at all first (`grep`'d rmpc's own
theme-parsing source for a hex test case before trusting it), then
applied the same lesson termusic's own transparency fix already
established this session: `None` here means "don't paint an explicit
background at all", letting kitty's own `background_opacity` blend
against the desktop wallpaper behind it.

That mechanism alone technically worked at kitty's global default
(0.85), but not perceptibly so on a window this large (1152x540, over
half the screen) -- direct feedback afterward was "lets make its
background glass like", i.e. 0.85 wasn't actually reading as glass in
practice. Fixed with a per-window override, not a global one --
`-o background_opacity=0.3` on rmpc's own kitty launch line
(`../../scripts/.local/bin/rmpc-toggle.sh`), leaving `kitty/kitty.conf`
itself untouched for every other terminal use. See that script's own
comment block for the full measurement methodology (whole-window pixel
averaging was tried first and proved too noisy to trust; a fixed,
confirmed-empty patch sampled at the real toggle-triggered window
position is what actually gave a reliable, repeatable signal) and the
final verified numbers.

## Verified live, not assumed correct from reading the config alone

- Triggered the real `$mod+Shift+m` keybinding via a simulated
  keypress, confirmed via `swaymsg -t get_tree` a 1152x540 floating
  window opened at the expected centered position.
- Screenshotted the running window: found Mauve (`#cba6f7`, ~26,000
  matching pixels) clearly dominant across borders/highlights, and zero
  pixels of the theme's own solid background color -- confirming
  `background_color: None` itself was correctly wired from the first
  real launch. The perceptual strength of the resulting blend still
  needed its own follow-up (see "Theme" above) once it became clear
  0.85 alone wasn't glass-like enough on a window this size.
- `rmpc debuginfo`, run directly from this same non-interactive
  session, reported the image protocol as "Block" (the crude ASCII
  fallback) rather than "Kitty" -- traced this to the session's own
  shell not actually being a real TTY (`tty` reports "not a tty" even
  with `$KITTY_WINDOW_ID` set, since the variable is just inherited,
  not backed by a real attached terminal), not a real problem: checked
  rmpc's own log from the actual `kitty -e rmpc`-launched window
  instead and found `resolved_backend="Kitty"`, `kitty_graphics="true"`
  -- the real graphics protocol is genuinely active for the actual,
  real usage path.
- Full search-to-playback loop, through `music-search.py`: downloaded a
  real track while rmpc was open, confirmed via MPD's own log it was
  auto-indexed within seconds with zero manual action.
