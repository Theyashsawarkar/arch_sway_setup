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
sizes it to 1152x648 -- 60%/60% of this machine's actual output -- and
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

That first pass was a literal, uniform substitution -- every "blue"
became the same Mauve, every "yellow" the same Yellow, everywhere --
which left almost the whole UI reading as one or two colors (Mauve +
Yellow, plus Red/Green/Pink only in the rarely-seen debug log levels).
Direct follow-up feedback: "improve the theming... use some colors like
our status bar and make it more aesthetic." Revisited with the actual
goal being richness and consistency with `waybar/style.css`'s own
palette, not just "has hex colors" -- waybar deliberately assigns a
*different* hue per module (Sapphire for dark mode, Sky for wifi, Peach
for capslock, Teal for numlock, Maroon for the volume/pulseaudio
module, Lavender for notifications, dim gray `#6c7086` for every "off"
state) rather than one accent color doing every job, and rmpc's theme
didn't have any of that variety yet. Recolored by role instead of by
literal string match this time:

- **Song title** (`components.title`) -- had no color at all before,
  just Bold on the default text color, on what's the single most-looked-
  at line in the whole UI. Now Sky `#89dceb`.
- **Artist** (`components.artist_and_album`) -- was the same Yellow as
  the `[Playing]` state badge right above it, no differentiation
  between the two. Now Lavender `#b4befe`.
- **Volume number/%** (`components.volume`) -- was generic Mauve. Now
  Maroon `#eba0ac` -- not a new pick, this is *literally* the color
  `#pulseaudio` (waybar's own volume module) already uses, the most
  direct "use our status bar's colors" match available.
- **Repeat/Random/Consume/Single toggles** (`components.states`) -- all
  four shared one identical Yellow-on/Mauve-dim-off pair before, no way
  to tell which toggle was which by color alone. Now each gets its own
  waybar-matched hue when on -- repeat Teal `#94e2d5`, random Peach
  `#fab387`, consume Sapphire `#74c7ec`, single Lavender `#b4befe` --
  and every *off* state moved from a dimmed Mauve to waybar's own
  literal off-state gray, `#6c7086`, instead of a dimmed accent color.
- **`level_styles.info`** (rmpc's own internal log pane, low-visibility
  but still themed) -- was Mauve, now Sapphire `#74c7ec`, freeing Mauve
  to stay what it already is everywhere else in this theme and this
  desktop: the one "this is selected/active/interactive" accent
  (`current_item_style`, `borders_style`, `tab_bar.active_style`,
  waybar's own hover color) -- diversifying the rest didn't touch that.
- **Every `#1e1e2e` (Catppuccin's plain "Base") swapped for `#11111b`**
  (modal background, all five `level_styles` backgrounds, and the dark
  text used for contrast against Mauve/Green highlights) -- grepped the
  whole repo first to confirm `#11111B` really is the one shared dark
  surface everywhere else (waybar, mako, wofi, nwg-bar, even the sway
  window-border scheme all already use it) before assuming rmpc should
  match it too; it was the only place in this desktop still using the
  lighter Base tone for that role.

Verified live, not just eyeballed: relaunched rmpc through the real
`$mod+Shift+m` keybinding, confirmed its own log had zero parse errors
for the edited theme, screenshotted the running window, and pixel-
matched specific coordinates against the exact target hex values --
title, artist, and volume all came back an *exact* RGB match
(`(137,220,235)`, `(180,190,254)`, `(235,160,172)` respectively, zero
color distance from the theme's own values). The off-state toggle
cluster came back a dim, low-contrast blue-gray in the right position
and color family, consistent with `#6c7086` plus the terminal's own
"Dim" modifier blending it further -- not a hex-exact match on
anti-aliased glyph-edge pixels, but qualitatively confirmed rather than
assumed.

**Second follow-up**, immediately after: "can't we add some more
colors to this tui and make it more colorfull like our status bar?" --
the first pass had only touched the playback header and toggle
cluster; everything else (the file browser, table column headers,
preview metadata, tab bar, scrollbar, elapsed/bitrate line) was still
plain default text. Went through every remaining unstyled field in the
theme and colored it, reusing the same waybar-matched hues plus the
two waybar colors nothing had used yet (`#89b4fa` Blue -- waybar's
`#clock.time`, and `#f5e0dc` Rosewater -- waybar's wallpaper-refresh
button):

- `symbols.song_style`/`dir_style`/`playlist_style` (the browser's
  per-row-type marker color, all three previously `None`): Sky, Blue,
  Rosewater.
- `browser_song_format`'s Artist/Title fields (the actual row text in
  the file browser, previously unstyled): Lavender and Sky, matching
  the playback header's own colors for the same two fields -- ties the
  browser directly to "now playing" visually.
- `song_table_format`'s column headers (Playlists/Search tabs, all four
  previously unstyled): Artist Lavender, Title Sky, Album Rosewater,
  Duration Peach -- header row only, left the actual song rows in each
  column mostly neutral so a full table of many songs stays scannable
  rather than turning into a wall of competing colors.
- `tab_bar.inactive_style` (previously empty, default text): waybar's
  own literal off-gray `#6c7086` -- doubles as a real legibility win,
  not just decoration, since active (Mauve bg) vs. inactive tabs now
  actually read differently instead of only differing by which one has
  a filled background.
- `preview_metadata_group_style` (previously identical Yellow to its
  own label): Blue, so the label and the actual value read as two
  different things.
- `elapsed_and_bitrate` (previously zero color, plain text): Green
  `#a6e3a1`.
- `scrollbar.ends_style` (previously empty): the same off-gray as the
  inactive tabs.

Verified the same way as the first pass: relaunched, confirmed zero
theme-parse errors and the process still alive, screenshotted, and
pixel-matched. Song title/dir marker (Blue only shows on the
Directories tab, so switched to it with a real simulated keypress
first) and the elapsed-line Green all came back exact RGB matches;
inactive tabs came back the right off-gray family across 575 sampled
pixels once actually on a multi-tab screen.

`background_color`/`header_background_color` left as `None` --
confirmed hex colors are supported at all first (`grep`'d rmpc's own
theme-parsing source for a hex test case before trusting it), then
applied the same lesson termusic's own transparency fix already
established this session: `None` here means "don't paint an explicit
background at all", letting kitty's own `background_opacity` blend
against the desktop wallpaper behind it.

That mechanism alone technically worked at kitty's global default
(0.85), but not perceptibly so on a window this large (1152x648, over
half the screen) -- direct feedback afterward was "lets make its
background glass like", i.e. 0.85 wasn't actually reading as glass in
practice. First fix attempt lowered opacity per-window instead
(`-o background_opacity=0.3`) -- that did move the pixels, but what
showed through at low opacity was the wallpaper completely sharp and
unblurred, which reads as "see-through window", not glass. The actual
fix was real compositor-level blur: `blur enable` on rmpc's own
`for_window` rule in `sway/config` (SwayFX, same `scenefx0.4`
mechanism wofi's `layer_effects` rule already uses, just reached
differently -- rmpc is a plain toplevel window, not a layer-shell
surface, so it's a regular `for_window`-settable property, no
`layer_effects` block needed, and deliberately without `blur_xray`,
which SwayFX's own README says is for layer-shell panels specifically
and not recommended for floating toplevel windows). Once blur was
doing the actual smoothing, the per-window opacity override became
unnecessary and was removed -- back to kitty's global 0.85, matching
wofi's own real working ratio (`wofi/style.css` runs its glass panel at
0.85 alpha too) instead of a separately-tuned value.

**Third follow-up**: "the active item should not get the background
color but instead have a rounded colored border. and that queue
directories artists row elements should be colored each differently
right also same goes for that normal text as well." Pulled rmpc's own
source (`ui/dirstack/mod.rs`, `ui/panes/queue.rs`,
`config/theme/style.rs`) rather than guess at what's actually possible,
since a request like "a rounded border around one list row" needed a
real answer, not an attempt:

- **No real per-item border exists.** `current_item_style` compiles
  down to a plain ratatui `Style` (`fg`/`bg`/`modifiers` only, confirmed
  reading `StyleFile`'s own struct definition) applied via `.style()` on
  a `ListItem`/`Row` -- there is no border concept for an individual row
  anywhere in rmpc's renderer, only around whole panes. Closest honest
  substitute: dropped `bg` entirely and switched to
  `fg: "#cba6f7", modifiers: "Bold | Underlined"` -- no solid fill, an
  accent-colored underline standing in for the "outline" that isn't
  actually renderable here.
- **A real, serious bug found in the process of building that**: wrote
  the modifiers as `"Bold, Underlined"` (comma-separated) first --
  syntactically valid RON, but semantically wrong for how the
  `modifiers` field actually deserializes. rmpc uses the `bitflags`
  crate (v2) for `Modifiers`, whose serde support parses combined flags
  in its own `Flag | Flag` format, not comma-separated -- confirmed by
  reading the `bitflags!` macro invocation directly rather than
  guessing. The real, serious part: this wasn't a "that one field falls
  back to a default" failure -- it silently broke the **entire** config
  load, not just the theme. Traced this by comparing `rmpc debuginfo`
  (run standalone, correctly resolved every path) against the actual
  running instance's own log, whose `Resolved config` line showed
  `cache_dir: None` (a `config.ron`-level setting, untouched by any
  theme edit) and every color as a plain ANSI name (`.yellow()`, rmpc's
  own literal built-in default) instead of any of this theme's real hex
  values -- meaning a bad theme file doesn't just lose its own styling,
  it takes the *entire* config down with it, silently, no error or
  warning logged anywhere. Fixed by using the format the crate actually
  expects: `"Bold | Underlined"`.
- **Queue/Playlists/Search tables now genuinely colored per column, not
  just their headers**: traced `song_table_format`'s actual row
  rendering (`queue.rs`'s `as_line_ellipsized`/`as_line_scrolling` ->
  `song_ext.rs`'s `as_line`) and confirmed it **does** apply each
  column's `prop.style` to real row content, not just `label_prop`
  headers -- so Artist/Title/Album/Duration row text now matches each
  column's own header color (Lavender/Sky/Rosewater/Peach) instead of
  only Album having an (redundant, same-as-default) explicit color.
- **A real, unfixable-via-config limit found for the browser tabs**
  (Directories/Artists/Album Artists/Albums): traced the *other* render
  path songs take there (`dirstack/mod.rs`'s `to_list_item`) and
  confirmed it calls `Property<SongProperty>::as_string`, which
  discards `style` entirely -- so `browser_song_format`'s per-field
  colors (set in the first theming pass) are genuinely dead
  configuration for actual song rows in these tabs; only the one-
  character type marker before each name (`symbols.song_style`/
  `dir_style`/`playlist_style`, already colored) is real there. Left
  the inert `style:` fields in place with a comment explaining exactly
  why, rather than silently deleting config that looks like it should
  work.

Verified live the same way as every pass before it: relaunched, hit the
exact "silently falls back to defaults" bug live (confirmed via the log
comparison above) before finding the real cause, fixed it, relaunched
again, and confirmed via the log's `Resolved config` dump that real hex
`Rgb(...)` values were present again (not `.yellow()`-style ANSI
names) and `cache_dir` was back to the real configured path.
Screenshotted the Queue tab with one real song queued (added it
directly through rmpc's own UI, not assumed) and pixel-matched all four
column colors -- exact RGB matches. Confirmed row-by-row pixel-count
distribution around the selected row to rule out a leftover solid
background block (a real, full-width match only appears at the pane's
own horizontal border line, not across the row itself).

## Verified live, not assumed correct from reading the config alone

- Triggered the real `$mod+Shift+m` keybinding via a simulated
  keypress, confirmed via `swaymsg -t get_tree` a 1152x648 floating
  window opened at the expected centered position.
- Screenshotted the running window: found Mauve (`#cba6f7`, ~26,000
  matching pixels) clearly dominant across borders/highlights, and zero
  pixels of the theme's own solid background color -- confirming
  `background_color: None` itself was correctly wired from the first
  real launch. The perceptual strength of the resulting blend still
  needed its own follow-up (see "Theme" above) once it became clear
  0.85 alone wasn't glass-like enough on a window this size.
- Real blur, confirmed with a clean, position-matched pixel test rather
  than trusting the config reloaded without error: screenshotted the
  live window and the same exact screen region with the window hidden,
  found the highest-texture 40x40 block in the wallpaper-only shot
  (real edge detail, pixel luminance swinging from ~4 to ~151), then
  compared local horizontal-gradient energy in that identical region
  between the two shots -- the window's own rendering of that spot
  averaged 0.83 vs. the wallpaper's own 9.85, a ~92% drop, and the
  actual pixel values there were a smooth, consistent blended tone
  (~24, 33, 46) rather than either the sharp original texture or a flat
  theme color -- genuine blur, not just alpha dimming or a solid pane
  happening to sit there.
- Text legibility reconfirmed directly afterward (ASCII luminance dump
  of real rendered text with both blur and 0.85 opacity active) --
  glyphs stayed crisp and high-contrast.
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
