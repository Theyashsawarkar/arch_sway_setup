# Changelog

Notable changes to this setup, in human terms — what changed, why, and what broke
along the way. Newest first.

## 2026-08-28 (wallpaper refresh icon in waybar, left of docker)

New `custom/wallpaper` module, placed right before `custom/docker` in
`modules-right` as asked. Reuses the existing `fetch_wallpaper.sh` pipeline
directly rather than writing a new one -- it already had everything needed
(download, retry, real image validation, safe fallback, `flock` so a manual
click can't race the daily timer), just needed a trigger and some feedback.

Added `notify-send` calls at the points that matter -- start ("Fetching a
new one..."), success (using the new wallpaper itself as the notification
icon via `-i`), fallback used, and total failure -- since the script used to
be silent, log-file only. Fine for an unattended daily timer, not fine for a
manual click that gives zero feedback for the several seconds a real
download takes. Benefits the daily timer too, not just this new button.

Icon is `md-wallpaper` (`f0e09`), a genuine dedicated "wallpaper" glyph,
colored Rosewater -- the one hue in this palette that was still completely
unused anywhere in the bar, fitting for a personalization action rather than
reusing a status color that already means something else. No `exec`/
`interval` on the module at all -- confirmed via `man waybar-custom` that
`exec` isn't mandatory, a static `format` + `on-click` is a valid custom
module on its own, since there's no changing state to poll for a plain
action button.

Caught the same recurring codepoint-corruption issue immediately (`"format":
""` landed empty from a raw pasted glyph) and forgot the module wasn't in
any of the shared pill-styling CSS selector lists at first, which left it
rendering as bare unstyled text -- added `#custom-wallpaper` to the
background/border list, the padding-override list, and the hover-accent
list, matching every other module.

Verified thoroughly: pixel-sampled the pill's actual background boundary
(clean dark tone x1430-1444, real wallpaper colors immediately outside on
both sides -- not just eyeballing a noisy full-height ASCII render, which
initially looked ambiguous), and ran the on-click script exactly as waybar
would invoke it (`sh -c`) -- real download succeeded, wallpaper genuinely
changed live on the machine, log confirms the full pipeline ran clean.

## 2026-08-28 (active workspace matches the focused window border: both Red)

Asked to make the workspace indicator match the focused window border's
color, changing the workspace side. `#workspaces button.focused` switched
from Sapphire to Red, matching `client.focused` in `sway/config` -- both
"this is the active one" signals now use the same hue instead of two
different "active" colors in different parts of the setup. Mauve stays
untouched as the bar's one hover/interactive accent elsewhere.

Verified live: switched to workspace 1, pixel-searched the workspace
region -- Red present at exactly the number-glyph and underline positions
(y13-33), Sapphire completely gone from that area.

## 2026-08-28 (backlight icons: real empty-to-full pie fill, not MDI's sun-ray set)

User reported the dimmest icon (1% brightness) looked like a full circle --
checked this for real rather than assuming the percentage-tiering math was
wrong (it wasn't): set brightness to a genuine 1% via `brightnessctl`,
screenshotted, and rendered the actual icon as an ASCII brightness map. It
really was a solid, densely-filled disk with zero rays or partial elements --
confirmed the root cause is the icon choice itself, not a tiering bug.
`md-brightness_1` (the MDI "sun ray count" icon this repo picked earlier) is
apparently just a plain solid dot in MDI's own design language (the "base," no
rays yet) -- reads as "complete/full" to anyone who doesn't already know that
convention, the opposite of what a status icon should communicate.

Switched to `md-circle_slice_1` through `_8` (picked 1/3/5/7/8 for a 5-tier
spread) -- a genuine pie-chart fill progression, same visual language as
battery/volume/wifi's own "empty container gradually fills up" icons already
used elsewhere in this bar, instead of a ray-count metaphor that doesn't read
the same way.

Verified live, not just by eye: rendered the actual icon as a detailed ASCII
brightness map at real 1% (mostly hollow ring, one small filled wedge visible,
pixel count dropped from 104 to 10 compared to the old icon at the same
brightness) and real 90% (densely filled disk, just a thin unfilled outline
remaining) -- a genuine, intuitive empty-to-full contrast between the two,
confirmed from the actual rendered pixels rather than assumed from the icon
names.

## 2026-08-28 (focused window border: Red, the actually-dominant pick)

Clock time/date (Blue/Maroon) landed well; the border's Mauve didn't --
asked for something more "dominant." Red is the single boldest, most
commanding hue in this palette. Named the real trade-off before shipping it
rather than after: Red is reserved everywhere else in this setup for actual
alerts (network disconnected, battery critical, the power button), and this
is the fourth different border color tried in a row (Mauve -> Sapphire ->
Lavender -> Mauve -> Red) -- worth being explicit that a persistent "this
window is focused" fixture reads differently from a transient alert pill,
rather than silently hoping that distinction holds.

Verified live against the same real window as every prior border-color
entry: Red renders at 1245 pixels along the top border (consistent with the
1244 every previous color measured at), Mauve completely gone from that
position.

## 2026-08-28 (royal color trio: window border, clock time, clock date)

Asked for "royal colors" specifically across the window border, clock time,
and clock date, and to stop iterating on Lavender for the border. Went with
an actual regal color story instead of three unrelated picks:

- **Window border** -> Mauve. This repo's own earlier comments already
  nicknamed it "Royal Mauve" -- it's the literal royal purple of this
  palette. Overrode the earlier concern about it double-booking waybar's
  universal hover accent -- that reasoning was about avoiding meaning
  overload, not about beauty, and beauty is what was asked for this time.
  The two contexts (a persistent window border vs a brief waybar hover
  flash) don't actually read as confusable in practice.
- **Clock time** -> Blue, not Sapphire. Sapphire was already tried once on
  the *date* in an earlier pass and rejected specifically for reading too
  close to Sky (network.wifi) despite not sitting adjacent to it -- reusing
  it here would've repeated a mistake this repo already learned from. Blue
  is a properly saturated, distinct "royal blue" without that problem.
- **Clock date** -> Maroon. Burgundy/wine, historically a royal-robe color,
  already used elsewhere in this bar (pulseaudio, bluetooth.on) without
  issue since neither sits near the center clock.

Verified live: pulled the real focused window's rect again (same window,
same x17/y58 as the last two border-color entries), confirmed Mauve renders
at exactly the same 1244 pixel positions Lavender and Sapphire occupied
before it. Confirmed Blue and Maroon both land at the clock's established
x-positions (time ~x830+, date ~x928+, matching every prior clock-color
verification in this file).

## 2026-08-28 (focused window border: Lavender, take two on "beautiful")

Asked to just pick something beautiful for the focused window border, rather
than continuing to iterate on Sapphire. Considered Mauve first -- it's
Catppuccin's own flagship accent and the most common community choice for
exactly this -- but it already has a specific job as waybar's one universal
hover/interactive signal, and doubling it here would blur that meaning even
though window borders and waybar hovers are physically separate contexts.
Landed on Lavender: barely used anywhere else (just the clock's time text and
one workspace hover state), genuinely one of the more elegant hues in this
palette, and free to mean one clean thing here -- this is the active window.
Sapphire stays workspace-only in waybar, untouched.

Verified live against the same real open window as the previous entry (same
rect, x17/y58/1886x1005): Lavender now renders at the exact same 1244 pixel
positions Sapphire occupied at the top border, and Sapphire itself is
completely gone from that location (0 matching pixels) -- confirms a clean
swap, not a partial/leftover state.

## 2026-08-28 (focused window border: Sapphire, tighter gaps)

Real sway window borders this time (`client.focused` in `sway/config`), not
waybar -- distinct from the workspace indicator's own earlier Mauve ->
Sapphire change. Same reasoning applied here too: Mauve stays waybar's one
universal hover/interactive accent, so the focused window (same "this is
where you are right now" meaning as the focused workspace) gets its own
color instead of sharing Mauve for both. `client.focused`'s border,
indicator, and child_border all switched to Sapphire (`#74C7EC`);
background/text left alone.

"Margin" read as gaps -- the config's own existing comments already use
"Margins / Gaps" interchangeably (`### Window Geometry (Margins / Gaps)`,
and a later comment about outer gaps: "there's always a visible margin to
the screen edge"), so that's the established vocabulary in this repo, not
a guess. Reduced both `gaps inner` (8 -> 4) and `gaps outer` (9 -> 4).

Verified live against a real open window, not just a clean reload: pulled
its actual rect via `swaymsg -t get_tree` (x17,y58, 1886x1005), screenshotted,
and pixel-searched right at those exact boundary coordinates -- found Sapphire
solidly along both the top edge (1244 matching pixels at y58) and the left
edge (400 matching pixels at x17), confirming the real border color, not just
that the config parsed.

## 2026-08-28 (battery: real charging icon with the lightning bolt built in)

Follow-up: wanted the charging icon to actually show a bolt again, from "the
same family" as the plain battery icon, not just rely on color. Previous entry
concluded this wasn't possible because `format-icons` looked like a single flat
array shared by every format variant -- wrong, caught by reading waybar's
actual source (`ALabel::getIcon`, `src/ALabel.cpp`) rather than trusting the
man page summary alone this time: `format-icons` can be an **object**, and the
battery module builds a lookup-key list `{status+"-"+state, status, state}`
(confirmed `status` gets lowercased with spaces turned into dashes before this,
matching the `#battery.charging` CSS class already in use) -- falling back to
a `"default"` key. Critically, each value in that object can *itself* be an
array, independently capacity-tiered exactly like the flat form. So
`{"charging": [...5 icons...], "default": [...5 icons...]}` genuinely works:
whichever status is active picks its own tiered set.

Used a real "battery with a bolt inside" icon family (`md-battery_charging_10`
through `_100`, verified present in the font) for the `"charging"` key, and
switched `"default"` to the matching plain `md-battery_*` set instead of the
old FontAwesome one, so charging/non-charging read as the same visual family
with just the bolt as the distinguishing detail, not two unrelated icon styles
stitched together.

Hit the raw-glyph corruption bug again, but in a new form -- `\U000fXXXX`
8-digit escapes (needed for these supplementary-plane codepoints, all above
`U+FFFF`) got silently truncated in transport this time: `\U000f089c` landed
as `\uf089` (4 digits) plus a stray literal `c` character, valid JSON but
wrong content, caught only by checking codepoints after writing -- the same
discipline that already caught the plain raw-character version of this bug
several times earlier in this session. Confirmed via an isolated `python3 -c`
call that the escape syntax itself is correct in isolation; something in this
specific heredoc's transport mangled it. Fixed by sidestepping escape-literal
parsing entirely -- built the strings with `chr(0xf089c)` etc. instead, which
can't be misinterpreted the way a backslash sequence can.

Verified live: valid JSON, clean waybar reload with no errors (confirms the
object-keyed `format-icons` syntax parsed correctly), and the battery pill
still renders Green at the real current capacity (90%, discharging) with a
comparable icon pixel count to prior checks -- consistent with a real glyph
rendering, not a blank/missing one. Could not force an actual charging session
to visually confirm the bolt icon itself renders -- same real limitation as
the previous entry, still resting on the mechanism being correctly wired
rather than a live A/B screenshot of it charging.

## 2026-08-28 (battery: real percentage gradient, icon now tiers while charging too)

Checked the actual live state first rather than guessing: real capacity 93-94%,
genuinely `Discharging`. Confirmed via pixel search it *was* already rendering
correctly (Green, the healthy-discharging color from an earlier pass) -- so the
color mechanism itself wasn't broken, but two real gaps explain what looked like
"not changing": color only had two emergency breakpoints (warning at 30%,
critical at 15%) with everything from 31% to 100% rendering the exact same flat
Green, and the icon was completely static (`format-charging`/`format-plugged`
had a hardcoded bolt glyph, no `{icon}`) whenever actually plugged in --
capacity-tiering only ever worked while discharging.

**Color**: `states` turns out to accept arbitrary names, not just
warning/critical (`man waybar-states`: "Every entry consists of a `<name>` and
a `<value>`"). Added a third tier, `"moderate": 60` -> Yellow, between the
existing warning (Peach) and critical (Red), positioned in the stylesheet
between `.full` and `.warning` so a genuinely low battery still overrides it via
the same source-order logic already used for the other states. Now: >60% Green,
31-60% Yellow, 16-30% Peach, <=15% Red -- an actual gradient instead of two
thresholds plus one flat color for the other 70 points of range.

**Icon while charging**: `format-icons` turns out to be a single array shared
by every format variant (confirmed: no per-status icon set exists in the
battery module's schema) -- so a dedicated MDI `battery_charging_10..100` tiered
set (found and verified present in the font, but not usable here since waybar
can't switch icon arrays by status) wasn't the fix. Real fix:
`format-charging`/`format-plugged` now use `{icon}` too, pulling from the same
tiered array `format` already used -- same "icon shape = one concept (capacity),
color = another (status)" split already used elsewhere in this bar (e.g. the
volume mute icon). Trade-off: lost the static bolt glyph's obvious "this is
charging" shape, but color already carries that signal clearly (Yellow while
charging, Teal when full) -- flagged in case that trade isn't wanted back.

Verified live: reloaded clean, pixel-confirmed battery still renders Green at
the real 93% capacity (correctly *not* falsely triggering the new 60% Yellow
tier). Couldn't verify the moderate/warning/critical Yellow/Peach/Red bands or
the charging icon's tiering with real live A/B tests -- would need the actual
battery to drain into those ranges or to actually be plugged in, neither of
which could be forced from here -- this rests on the states mechanism already
being independently proven correct in an earlier pass, not a fresh live test
of every band.

## 2026-08-28 (whole bar reorganized: status indicators left, controls right)

Full layout reorder, requested as a coherent principle rather than a one-off
tweak: status/indicator modules (workspace, bluetooth, wifi, network speed)
read left to right on the left side, clock stays centered, and everything you
actually click or toggle (lock states, docker, caffeine, brightness, volume,
battery, power) lives on the right, in that order. Caps/num lock explicitly
placed right before docker per the request.

```
Left:   [workspaces] · [bluetooth][network][network#speed]
Center: [time][date]
Right:  [caps/num lock][docker][caffeine] · [backlight][pulseaudio] · [battery] · [power]
```

Just reordering `modules-left`/`modules-right` wasn't enough on its own --
several margin/grouping CSS rules were written assuming the *old* adjacencies
(docker used to mark "start of the left status group", bluetooth used to mark
its end). Re-derived the grouping margins for the new clusters: bluetooth now
starts the left connectivity cluster (was docker's old role), caffeine now
ends the new device-controls cluster on the right (docker+caffeine+lock
states tight together, gap before brightness/volume) instead of bluetooth
ending a group that no longer exists in that position.

Verified live rather than trusting the reorder on paper: screenshotted the
reloaded bar and pixel-searched for six different modules' known colors
across the full bar width. Every ordering signpost landed where it should --
workspace (Sapphire) at the far left (x12), wifi (Sky) starting only after a
gap consistent with bluetooth preceding it (x242+), time/date centered
(x830-1078), docker (Blue) now clearly in the right portion (x1480-1492), and
the power button (Red) as the absolute rightmost element, right at the
screen edge (x1894-1904).

## 2026-08-28 (capslock/numlock: hidden entirely when off, not just dimmed)

Wanted them to disappear completely (zero bar space) when off, each
independently -- only one showing if only one is locked. Found the exact
mechanism in `man waybar-custom`: `hide-empty-text` ("Disables the module
when output is empty") removes the whole module from the layout, not just
blanks its text. Added it to both `custom/capslock`/`custom/numlock`, and
`keylock-status.sh` now outputs `"text":""` for the normal unlocked state
(previously a dim gray icon+badge). A genuine error case (no LED device
found at all) still shows something rather than silently vanishing --
that's a real problem, not an "off" state.

This broke the "one merged pill" look from two entries ago -- that treatment
(capslock rounded-left-only, numlock rounded-right-only, touching with no
seam) assumed both are always present. With either now able to disappear on
its own, a half-rounded pill with its open edge flat would look visibly cut
off whenever only one shows -- the common case now, not an edge case.
Reverted to two independent full pills rather than attempting fragile
sibling-aware CSS to conditionally re-merge them only when both happen to be
visible, which wasn't practical to verify reliably. Correctness over keeping
a cosmetic that no longer fits the new behavior.

Hit the same raw-glyph-paste corruption bug again while editing
`keylock-status.sh` -- `ICON=$''` landed as a genuinely empty string,
caught by checking `hex(ord(ch))` codepoints immediately after writing
rather than assuming the paste worked (established discipline in this repo,
paid off again). Fixed using bash's own `$'\uXXXX'` ANSI-C-quote escape
syntax instead -- plain ASCII text in the file, bash itself decodes it to
the real character at runtime, so there's nothing for the paste to corrupt.
Verified directly: `bash -c "echo -n \$'\uf023'"` piped through Python
confirmed the exact right UTF-8 bytes.

Verified live: pixel-sampled the row from workspaces through where
capslock/numlock used to sit -- one continuous dark pill-background tone
the whole way, transitioning directly into docker's own small intended gap,
instead of the ~150px both indicators used to occupy together.

## 2026-08-28 (network speed fixed width; capslock recolored off pale Yellow)

Two separate asks. First: battery was checked and turned out fine -- at the
time (38%, genuinely `Discharging` per `/sys/class/power_supply/BAT1/status`,
not charging), neither the warning (30%) nor charging color applied because
neither condition was true; it should render Green (the healthy-discharging
state added earlier), not nothing.

**Network speed**: `{bandwidthDownBytes}`/`{bandwidthUpBytes}` change digit
count constantly (12KB vs 1.2MB vs 999B), which was making the whole pill
visibly grow and shrink every couple seconds. Measured the actual live
rendered width first (177px) rather than guessing, then set `min-width:
200px` on `#network.speed`/`#network-speed` for real headroom. Verified live:
pixel-sampled the pill's background boundary after reload, found it now
spans ~204px, matching the new fixed width instead of the old content-only
177px.

**Capslock color**: was Yellow (`#F9E2AF`), read as washed-out/whitish --
Catppuccin Mocha's whole palette is pastel by design and Yellow specifically
is one of its palest members, and the glow's blur softened it further.
Switched to Peach (`#FAB387`) -- meaningfully more saturated (warm orange,
not pale cream) while keeping the same "warm heads-up, not alarming" feeling
Yellow was going for. Num Lock's Teal is unchanged (not pale in the same way,
no complaint raised about it).

## 2026-08-28 (capslock/numlock: merged into one pill instead of two)

Asked to put both in a single group rather than two separate pills sitting
side by side. Kept them as two independently clickable custom modules
underneath (merging into one module would lose per-key on-click, the thing
just added) but made them visually read as one: capslock is the left half
(rounded left corners only, no right border), numlock is the right half
(mirror image), touching with no seam. Needed the same negative-margin trick
already used for the clock/time pair -- config's top-level `"spacing": 5`
puts 5px between every pair of sibling modules regardless of their own
margins, so `margin-left: 0` alone would've still left a visible gap.

Verified properly this time rather than trusting a single noisy scan: the
wallpaper bleeding through gaps between pills made a broad region search
unreliable (same class of issue hit before), so sampled raw pixel values
along a row instead. From capslock's start to numlock's end, every sampled
pixel stayed in a tight dark range (17-30 per channel) with no jump to
wallpaper brightness anywhere -- confirmed continuous. Then sampled the same
way from numlock into docker as a positive control, specifically to prove
the method would actually catch a real gap: found exactly that, colors
jumping to (183,167,131)-range wallpaper tones in the real gap before
docker. Confirms the capslock/numlock merge is genuinely seamless, not just
an assumption that the CSS technique worked.

## 2026-08-28 (capslock/numlock: click to toggle, hover tooltip, real cursor)

Wanted mouse click-to-toggle, a hover tooltip saying which lock it is, and a
pointer cursor on hover. None of that is possible with waybar's built-in
`keyboard-state` module -- checked `man waybar-keyboard-state` first rather
than fighting CSS against it: no `on-click`, no `tooltip`, nowhere in its
config schema at all. Replaced it with `custom/capslock`/`custom/numlock`,
backed by two new scripts (same `{text,class,tooltip}` JSON pattern already
used for `custom/caffeine`/`custom/docker`), which support all three natively.

`keylock-status.sh` reads `/sys/class/leds/*::capslock|numlock/brightness`
directly -- the real kernel LED state, confirmed correct against actual live
state (numlock genuinely on, capslock genuinely off) at the time.

`keylock-toggle.sh` needed real investigation, not just wiring an `on-click`.
`wtype -k Caps_Lock` -- already used elsewhere in this repo -- does not
actually toggle the real lock state here (confirmed: the LED file stayed `0`
straight through it), because it injects through the `virtual-keyboard-
unstable-v1` Wayland protocol, which doesn't drive the same XKB lock-latch
machinery a real key event does on this compositor. Switched to `ydotool`
instead (official `extra` repo, added to `packages/pacman.txt`) -- injects
through `/dev/uinput`, indistinguishable from real hardware to the same
input pipeline, so it actually works. Checked the Arch package's file
listing before trusting it: ships its own systemd **user** service (no root
needed at runtime) and its own udev rule for `/dev/uinput` permissions --
clean, standard, not a loose workaround.

**Not yet installed** -- needs `sudo pacman -S ydotool`, a udev reload, and
`systemctl --user enable --now ydotool.service` (all three commands in
`docs/ARCHITECTURE.md`). Until then, clicking either indicator fails with a
clear `notify-send` telling you exactly which of those steps is missing,
rather than a silent no-op or a cryptic `ydotool` error -- verified this
fallback path directly.

Cursor needed no extra work at all: waybar shows a pointer automatically for
any module with `on-click`, standard GTK behavior, same as every other
already-clickable pill in this bar. Unrelated to the wofi popups' own cursor
limitation documented elsewhere -- different code path entirely.

## 2026-08-28 (capslock/numlock: fixed two real problems from the last pass)

1. **Couldn't tell which lock was which.** Sharing one padlock shape between
   caps/num (previous entry) meant color alone had to carry "which key is
   this" -- fine once memorized, not self-evident. Added a plain letter badge
   in the config's per-key `format` string alongside `{icon}`: `"A {icon}"`
   for capslock, `"# {icon}"` for numlock. Icon shape/color (padlock,
   Yellow/Teal) unchanged, just no longer the only signal.
2. **Activating a lock grew the whole bar's height.** Real regression from
   the previous pass's `font-size: 19px` bump on the locked state -- waybar's
   configured `"height": 41` didn't hard-clip the over-tall label, so the bar
   visibly grew the moment a lock activated and shrank back when it didn't.
   Removed the font-size change entirely; the `text-shadow` glow stays (it's
   paint-only, doesn't participate in layout/box-height calculation at all,
   confirmed via CSS fundamentals -- this is why it was never the actual
   cause), so the "damn noticeable" glow treatment survives without the size
   change that broke the bar.

Confirmed via `swaymsg` reload the bar reports back its configured height
(`Bar configured (width: 1920, height: 41)`) and `font-size` no longer
appears anywhere in the capslock/numlock CSS rules. Could not force a real
capslock/numlock toggle to visually confirm the height stays fixed while
actually locked (the same `wtype` limitation hit earlier -- synthetic
Caps_Lock presses don't flip the real LED/modifier state in this
environment) -- this rests on the CSS box-model reasoning (text-shadow
cannot affect height, font-size was the only property that could and is now
gone) rather than a live A/B screenshot.

## 2026-08-28 (capslock/numlock, take three -- real padlock, deliberately loud)

Neither prior attempt was noticeable enough. Switched to a real closed-padlock
icon (`fa-lock`, `f023`) for locked, open padlock (`fa-unlock`, `f09c`) for
unlocked -- back to waybar's shared `format-icons` pool (same icon set for
every key, per `man waybar-keyboard-state`) rather than a per-key hardcoded
glyph, since color (Yellow/Teal, unchanged) already tells capslock and numlock
apart and a genuine padlock shape reads faster than an arrow or a hashtag ever
would.

Made the locked state deliberately louder than the rest of the bar's own
restraint calls for: `font-size: 19px` (up from the bar's normal 15px) plus a
two-layer `text-shadow` glow (tight 8px + wide 14px halo, matching each key's
own color). A locked modifier key is more urgent than a passive status icon,
worth breaking the "everything the same size, no glow" convention for. Still
no filled background block, per the earlier explicit ask -- the glow carries
the emphasis instead of a solid fill.

## 2026-08-28 (capslock/numlock icons, take two -- simpler glyphs)

First attempt (`md-caps_lock`/`md-numeric`) didn't land well visually. Swapped
for simpler, more minimal glyphs instead of another detailed Material Design
icon: capslock is now U+21EA (⇪, "UPWARDS WHITE ARROW FROM BAR") -- the actual
ISO keycap symbol printed on real physical Caps Lock keys, standard Unicode
rather than a Nerd Font PUA glyph, so no font-coverage risk at all. Numlock is
`fa-hashtag` (`f292`, a plain `#`) instead of a cluttered "123" icon at bar
size -- clean, single-glyph, immediately reads as "numbers" without the visual
noise a multi-digit icon has this small.

## 2026-08-28 (capslock/numlock: icons instead of "CAPS"/"NUM" text)

Was `"format": "{name} {icon}"` with a shared locked/unlocked icon pair
(`format-icons`) -- per `man waybar-keyboard-state`, that icon pool is the same
set for every key ("the same set of icons is used for number, caps, and scroll
lock"), so simply dropping `{name}` would've left capslock and numlock showing
the *identical* generic lock glyph, impossible to tell apart without the text.

Real fix needed distinct icons per key, not just fewer characters. `format`
turns out to also accept a per-key object (confirmed in the same man page:
`{"numlock": ..., "capslock": ..., "scrolllock": ...}`), so each key now gets
its own hardcoded, purpose-specific icon instead of routing through the shared
locked/unlocked pool at all: `md-caps_lock` (`f0a9b`) for capslock,
`md-numeric` (`f03a0`) for numlock -- both verified present in the installed
font via `fc-query` first. Lock state is still conveyed by color exactly as
before (Yellow/Teal when locked, dim gray when unlocked -- that CSS was
untouched and already independently verified working in an earlier pass), just
no longer duplicated in a text label too.

## 2026-08-28 (active workspace: Sapphire instead of Mauve)

Asked for a different color on the active workspace than Mauve, suggesting
Sapphire or wifi's color. Went with Sapphire: Mauve stays the bar's one
universal "you're pointing at something interactive" hover accent everywhere
else, so giving the workspace's own resting focused state a different hue
keeps those two meanings distinct rather than overloading Mauve for both.
Also ties it into the blue "connectivity" family already established for the
network module (Sapphire = ethernet, Sky = wifi) instead of an arbitrary new
hue. Text color and underline both switched together.

Verified live: pixel-searched the workspace area after switching to
workspace 1, found Sapphire at the number glyph (y13-14/23-24) and the
underline (y32-33), zero Mauve remaining there.

## 2026-08-28 (workspace numbers: one shared container, not N separate buttons)

`#workspaces` (the group wrapper) already had the shared pill treatment every
other module gets -- dark background, Mauve hairline border -- but each number
button *also* had its own smaller background-color and border-radius layered
on top, which read as "several small buttons sitting inside a pill" instead of
one unified group. Removed the per-button background/radius entirely; numbers
now sit directly in the one shared container. Colors, spacing, and the
hover/focused underline accent from the previous change are all untouched --
this was specifically about the idle-state look, not a redesign of the states
themselves.

Verified live: pixel-scanned the workspace area's background after reload,
found one consistent dark tone throughout (no lighter per-button patches
standing out), while the Mauve underline (y32-33) and number glyph (y13-24)
from the previous change both still render correctly.

## 2026-08-28 (workspace switcher: fixed a real toggle bug, added an underline accent)

**Bug**: pressing `$mod+1` while already on workspace 1 jumped back to whatever
workspace you'd been on before -- an alt-tab-style toggle, not "go to/stay on
workspace 1." Root cause: `workspace_auto_back_and_forth yes`, added earlier this
session as a deliberate feature ("like alt-tab for workspaces"). Reverted --
removed the line entirely rather than setting it to `no` explicitly, since `no`
is sway's own documented default (`man 5 sway`: "Default is no"). Verified with
the exact reported reproduction: switched to workspace 1, then repeated the same
switch command -- workspace 1 stayed focused both times (previously the second
call would have jumped to workspace 2).

**Look**: added a 2px underline accent to hover/focused workspace buttons --
translucent Lavender on hover, solid Mauve when focused, same colors already in
use, just a second visual cue (like an active browser/editor tab) on top of the
existing bold-colored-number treatment. Widened button padding one notch (7px ->
8px) so the underline doesn't read as cramped. A transparent `border-bottom`
placeholder on the idle state reserves the same 2px vertical space always, so
the chip doesn't visibly shift height the moment an underline actually appears.
Verified live: pixel-searched after switching to workspace 1, found a solid
~40px-wide horizontal Mauve line at the chip's bottom edge (y32-33), distinct
from the small number-glyph pixels above it (y13-24) -- confirms a real
underline, not just a coincidental color match.

## 2026-08-28 (caffeine mode now actually survives a reboot)

Caffeine mode silently reset to off on every reboot regardless of what it was
left at. Root cause: `swayidle.service` is `enabled` (`WantedBy=default.target`,
confirmed via `systemctl --user is-enabled`), so systemd's user manager
auto-starts it at every login *on its own* -- completely independent of sway.
The old `exec systemctl --user restart swayidle.service` line in `sway/config`
had no way to know caffeine had been left on, so it just reasserted "start"
every time.

Fixed with a persisted marker file, `~/.local/state/caffeine/enabled`.
`caffeine-toggle.sh` now writes/removes it alongside stopping/starting the
service. New `scripts/.local/bin/swayidle-startup.sh` -- what sway's `exec`
line calls now instead of the bare `systemctl restart` -- reads the marker at
startup and is the single source of truth for swayidle's state: stops the
service if caffeine was left on (overriding whatever systemd's default.target
just auto-started), otherwise does the same restart this line always did.

Verified the actual failure mode end to end rather than trusting the fix on
paper: toggled caffeine on, manually replayed what systemd's auto-start would
do at the next login (`systemctl --user start swayidle.service`), confirmed
the service came back active exactly as it incorrectly would pre-fix, then ran
the new startup script the way sway's `exec` line would and confirmed it
correctly stopped it again. Verified the off case and `caffeine-status.sh`'s
reporting through a full toggle sequence too. No literal reboot was performed
to avoid disrupting the live session -- this rests on an exact functional
simulation of the real startup sequence.

## 2026-08-28 (workspace/capslock/numlock: text color instead of a filled block)

Active workspace and locked capslock/numlock indicators used a solid
background-color fill + dark text for contrast. Asked to keep the background
neutral and just recolor the text/number instead. Same hues kept throughout
(Mauve for the active workspace, Yellow for capslock, Teal for numlock) --
just moved from `background-color` fill to `color` text, with `font-weight:
800` added to each so the now-unfilled state still reads as emphasized rather
than losing prominence entirely.

Verified the workspace change live: pixel-searched for Mauve in the
workspace region after reload, found a small ~10-pixel cluster sized like a
single bold glyph (the old filled-block version would have produced hundreds
of hits across a whole chip) -- confirms text-only rendering, not a background
block. Tried to verify capslock the same way but `wtype -k Caps_Lock`'s
synthetic key press doesn't actually toggle the real lock LED state
(`/sys/class/leds/*capslock*/brightness` stayed at 0 through it) -- a testing-tool
limitation, not something to chase further, since capslock/numlock use the
exact same CSS mechanism (state selector + `color` instead of
`background-color`) already confirmed working for the workspace case.

## 2026-08-28 (icons that never actually changed state: volume mute, brightness, wifi signal)

Volume's mute icon and its low-volume tier icon were the literal same codepoint
(`f026`, FontAwesome's `volume_off`/`volume_x`/`volume_xmark` -- confirmed via
nerd-fonts' own glyphnames.json that all three names alias to one codepoint), so
muting while already at low volume showed no visible change at all, and even at
higher volume the "off" icon read ambiguously close to the low-tier one. Backlight
had a single static sun icon the whole time -- no tiering existed at all. The
main waybar network pill's wifi icon was likewise a single static glyph, never
reflecting signal strength (only the wifi *picker* dropdown had tiered icons,
added earlier -- the always-visible bar pill never did).

Switched volume to a full, consistent Material Design Icons set instead of
patching around FontAwesome's ambiguity: `volume_low`/`volume_medium`/`volume_high`
for the tiers, `volume_mute` (a genuinely different codepoint, `f075f`) for muted.
Backlight gained a real 5-tier `format-icons` (`brightness_1`..`brightness_5`,
`f00da`-`f00de`). Network's `format-wifi` now uses `{icon}` against the same
5-tier wifi-strength set (`wifi_strength_outline`/`_1`/`_2`/`_3`/`_4`) already
verified for the wifi picker, so the bar pill and the picker's icons finally
match instead of the bar staying static.

Caught a real hallucination while researching this: an earlier WebFetch summary
of nerd-fonts' glyphnames.json invented `fa-volume_mute` at `f131` -- sounded
completely plausible, wasn't real. Downloaded the actual JSON directly to the
machine and grepped it myself before trusting anything this time (`curl` +
`python3 -c "import json..."` against the real 545KB file) -- that's also just a
more reliable method going forward than relying on a small model's summary of a
huge file, independent of this specific miss. Every codepoint used here was
independently confirmed present in the installed font via `fc-query` afterward,
same discipline as everywhere else in this repo.

Verified all three live, not just "JSON parses": muted vs unmuted at the same 65%
volume now render two clearly different glyph shapes (screenshotted, rendered as
ASCII brightness maps to compare, confirmed genuinely different silhouettes, not
just eyeballed); brightness at 10% vs 90% likewise render distinguishably
different icons (fewer vs more visible sun-rays). Wifi's tiered icon couldn't be
forced to a specific signal strength for a live A/B test the same way (real
hardware, real signal), so that one rests on the codepoint verification plus a
clean waybar reload with no errors, not a live visual diff.

Battery was checked too and turned out already correct -- its `format-icons`
(`battery_empty` through `battery_full`, 5 genuinely distinct FontAwesome
codepoints) never had this bug, confirmed by inspecting the config before
assuming it needed the same fix.

## 2026-08-28 (cursor theme was never actually configured anywhere; wofi hover-cursor investigated)

User reported the cursor doesn't turn into a pointer hovering over entries in the
WiFi/Bluetooth pickers. Checked `man wofi`/`man wofi-style` (well, the actual
`wofi.5`/`wofi.7`/`wofi.1` man pages -- there's no separate wofi-style one) for any
"cursor" mention at all: zero hits anywhere in wofi's own documentation. This
matches an already-documented finding from this repo's own history (the power-menu
build): "no CSS cursor support" in wofi's `--dmenu` mode.

Before accepting that at face value again, checked something adjacent that turned
out to be a real, separate, worthwhile gap: **no cursor theme was configured
anywhere on this system at all** -- not in any env var (`XCURSOR_THEME` was
entirely absent, only `XCURSOR_SIZE=24` existed from some other default),
not in `sway/config` (no `seat ... xcursor_theme` line existed), not in
`gtk-3.0/settings.ini` or `gtk-4.0/settings.ini` (`gtk-cursor-theme-name` was
never set). `/usr/share/icons/default` already resolves to Adwaita
(confirmed: `Inherits=Adwaita` in its `index.theme`), so a sane default cursor
theme was always *available*, just never explicitly told to anything. Fixed
with `seat seat0 xcursor_theme Adwaita 24` in `sway/config` and
`gtk-cursor-theme-name=Adwaita` / `gtk-cursor-theme-size=24` in both GTK
settings files.

**Tested whether this fixes the actual reported issue, rather than assuming**:
launched wofi fresh after `swaymsg reload` and checked its real environment
(`/proc/<pid>/environ`) -- still no `XCURSOR_THEME` there, meaning sway's
env-var export for the seat's cursor theme apparently only happens at sway's
own actual startup, not on a soft reload (same class of caveat this repo
already has documented for plain `exec` lines not re-running on reload --
will take full effect after next login, not before). The `gtk-cursor-theme-name`
half should already apply immediately though, since wofi is a real GTK3 app
(confirmed via `ldd`) reading `gtk-3.0/settings.ini` fresh on every launch, no
caching involved.

**The actual "no pointer on hover" complaint is a separate thing from theme
configuration, and isn't fixed by any of this**: a cursor theme controls which
glyph set gets used for whatever shape is requested, not whether a shape change
gets requested in the first place. If wofi's dmenu list rows never ask the
compositor for a "pointer" cursor on hover (which is what "no CSS cursor
support" means), a correctly-configured theme changes nothing about that --
there's no shape-change request to render *from* that theme. Real, structural
wofi limitation, same class as the missing hover-tooltip found earlier -- not
fixable through config here. The honest options: live with it (matches the
rest of this bar's wofi-based UI language), or switch the picker backend to
something with fuller cursor support (e.g. rofi) at the cost of visual
consistency with everything else that already matches wofi's theme.

## 2026-08-28 (Bluetooth gets its own picker; WiFi picker no longer shows it)

Four asks in one go: WiFi's menu shouldn't show Bluetooth actions, keyboard focus
should land in the search box automatically, Bluetooth should get "the same modal
approach" with its own unique options (not WiFi's), and the connected entry should
read as more than just a different text color.

**Keyboard focus**: tested this directly before assuming it needed a fix --
launched the picker with zero clicks, typed `wtype "Maha"` into it, screenshotted
before/after. ~7800 pixels differed in the content region, confirming the typed
text reached wofi's search box and filtered the list immediately. This already
works, nothing to change.

**WiFi menu, Bluetooth-free**: `wifi-picker.py` now monkeypatches
`create_other_actions` too (previously only `get_wofi_highlight_markup` and
`get_selection`) to drop the Bluetooth toggle entry by `Action.func` identity
(`is not nmdm.toggle_bluetooth`) before it ever reaches the menu.

**Bluetooth picker**: new `scripts/.local/bin/bluetooth-picker.py`, same modal
approach as the WiFi one (wofi --dmenu, category colors) but fully self-contained
on `bluetoothctl` rather than wrapping a third-party tool -- checked first, and
the only wofi/dmenu-adjacent Bluetooth picker that exists at all is a 3-year-stale
rofi-specific AUR package, not worth the dependency over ~180 lines. Verified
every `bluetoothctl` subcommand against this machine's real bluez (5.87) before
writing anything against it -- caught that `paired-devices` isn't a valid command
in this version (`devices Paired` is), and confirmed `--timeout <n> scan on`
works non-interactively. Menu: power toggle, bounded 8s scan (relaunches itself
after, same self-relaunch pattern upstream networkmanager_dmenu uses for its own
rescan), Bluetooth Manager shortcut, paired devices (click connects/disconnects),
and -- added after noticing the "nearby" color was defined but nothing used it,
which would've made "Scan for Devices" a dead button -- devices bluez has seen
but not paired with yet, click to pair+trust+connect in one go. Every
`bluetoothctl` call bounded with a timeout that's now caught centrally in `run()`
(returns an ordinary failed result instead of an uncaught traceback) since
connect/pair/disconnect can all hang waiting on a device that needs interactive
PIN confirmation, which has nowhere to go in a dmenu flow -- documented as a real
limitation (falls back to suggesting Bluetooth Manager) rather than silently
dropped. waybar's `bluetooth` on-click now points here; deleted the now-fully-
superseded `nwg-bar/bluetooth.json`.

**Connected-entry border**: Pango `<span>` markup has no border attribute at all
(checked: foreground/background/underline/strikethrough/weight/style/size exist,
border does not) -- a literal CSS-style border around the connected entry isn't
achievable through this rendering path. Closest honest approximation, applied to
both pickers: a "┃ " heavy-vertical-line prefix inside the same highlighted span,
same idea as an active-indicator sidebar tick in a lot of TUI/statusline designs,
layered on top of the existing filled-background highlight rather than replacing
it.

## 2026-08-28 (Wi-Fi picker: color-coded rows -- networks vs saved vs commands)

Networks, saved connections, and commands (Rescan/Enable/Disable/etc.) all
rendered identically in the wofi menu -- upstream `networkmanager-dmenu` only
colors the single active/connected line, everything else is plain default text.
Couldn't fix this via config.ini (no per-category color hook exists there --
checked the tool's actual config schema first, not just assumed), so wrote
`scripts/.local/bin/wifi-picker.py`, a themed wrapper waybar now calls instead of
`networkmanager_dmenu` directly.

Loads the real installed script via `importlib` and monkeypatches exactly two
functions (`get_wofi_highlight_markup`, `get_selection`) rather than forking the
whole ~1500-line file -- all real NetworkManager interaction still runs upstream's
own maintained code. Colors: Sky for an actual network (matches the wifi icon's
own color elsewhere in the bar), Peach for a command, Teal for a saved connection
-- detected via `Action.func` identity plus the `:SAVED` name suffix upstream
already uses internally, both real signals the tool relies on for its own logic,
not incidental strings I'm guessing at.

Hit a real, worth-remembering bug while verifying this: `importlib.util.
spec_from_file_location` returns `None` (not an error) when it can't infer a
loader for a file with no `.py` extension, which `/usr/bin/networkmanager_dmenu`
is -- failed one line later with a confusing `'NoneType' object has no attribute
'loader'`. Fixed with an explicit `SourceFileLoader`.

Second, more confusing bug while testing: a background-launched wofi process
reliably vanished by the time a *separate* tool call checked on it, even under
`setsid`, producing a false "colors aren't rendering" result from a screenshot of
a stale/empty window. Real cause: this remote session's execution environment
doesn't preserve backgrounded processes across separate tool calls the way an
actual terminal session would. Fix for testing this class of thing here: launch,
wait, and screenshot all within one single call -- retested that way and
confirmed Sky/Mauve/Teal all render correctly in the live window via pixel
search, matching what direct instrumentation of the patched functions had
already shown (correct markup, correct wofi command with `-m` for pango markup).

## 2026-08-28 (waybar's network pill: dropped the visible signal percentage too)

Follow-up: the "%" the user didn't want turned out to be on the always-visible
waybar pill itself (`format-wifi`), not the wofi dropdown from the previous
entry -- two different places both showing signal info, only one had been fixed.
`format-wifi` went from `"  {essid}  {signalStrength}%"` back to `"  {essid}"`.
Left `tooltip-format-wifi` untouched -- it already has the full detail (signal%,
dBm, frequency, IP, gateway) and, unlike wofi's dmenu list, waybar's tooltips are
real GTK tooltips that actually work on hover. So the bar now genuinely has the
"just the name, full detail on hover" behavior that wofi's list couldn't deliver.

## 2026-08-28 (Wi-Fi picker UI: icons instead of signal-strength text)

Follow-up on the Wi-Fi picker from earlier today: wanted the list to just show
network names, not signal%/bars text, with strength conveyed by icon instead
(reads faster, takes less horizontal space) -- plus wanted full detail
available on hover.

Did the icon part: `format` went from `{name}  {sec}  {bars}` to
`{icon}  {name}`, and set `wifi_icons` to the 5-tier Material Design
wifi-strength glyphs (`networkmanager-dmenu` already ships a default set of
these in its own example config, just commented out) -- verified each of the
5 codepoints (`U+F092F` through `U+F0928`) is actually present in the
installed font via `fc-query`, same discipline as every other icon in this
repo, rather than trusting the upstream default blindly.

Couldn't do the hover-detail part -- checked wofi's actual capabilities first
rather than assuming: its dmenu list has no per-item tooltip support at all,
nothing to hook into. Said so plainly rather than silently dropping that half
of the request or pretending a workaround exists. The list is icon+name only
now; full detail (exact %, security type) isn't surfaced anywhere in this UI as
a result, which is the real tradeoff of asking for a compact list.

## 2026-08-28 (real Wi-Fi picker instead of the nwg-bar On/Off/Settings popup)

Wanted: click the network icon, see available networks, pick one, get prompted
for the password if it needs one, connect. `nwg-bar`'s wifi.json couldn't do any
of that -- confirmed (again, same root cause as the volume popup fix earlier)
that it's a static button grid with no dynamic content support at all, reading
its Go source. Architecturally impossible there, not a config problem.

Replaced with `networkmanager-dmenu` (official `extra` repo, not AUR) --
scan/connect/password-prompt/on-off-toggle/nm-connection-editor-shortcut all in
one menu, using `wofi --dmenu` as its backend. Read the tool's actual Python
source before trusting it: confirmed real, dedicated wofi support (not just
generic dmenu-protocol compatibility) -- it detects `wofi` specifically and
appends wofi's own `-P`/`--password` flag for the passphrase prompt (masks
input), plus has wofi-specific highlight markup for the connected network.

Given this repo's history of real, confirmed wofi `--dmenu` bugs (the power-menu
work a while back -- no CSS cursor support, `--columns` capped at 2, etc.),
smoke-tested `wofi --dmenu` here first rather than assuming it'd just work:
piped a sample network list into it, screenshotted, and confirmed a normal
solid popup rendered center-screen with no issue. Those earlier bugs turned out
to be specific to forcing a *button-grid* layout through `--dmenu` -- a plain
vertical scrolling list (what this tool actually does) hits none of them.

Config: `networkmanager-dmenu/.config/networkmanager-dmenu/config.ini` (new stow
package), `dmenu_command = wofi`, Mauve highlight to match the rest of the bar.
Waybar's `network` module `on-click` now runs `networkmanager_dmenu` directly
instead of the old `nwg-bar -t .../wifi.json ...` invocation. Deleted
`nwg-bar/.config/nwg-bar/wifi.json` -- fully superseded, nothing else referenced
it.

**Not yet installed on the live machine** -- `networkmanager-dmenu` needs `sudo
pacman -S networkmanager-dmenu`, this session has no `sudo`. Everything here is
verified as far as it can be without the actual binary present (config syntax,
waybar JSON validity, the wofi backend smoke test, reading the tool's real
source for wofi support) but the actual end-to-end click-to-connect flow is
unverified until it's installed and clicked for real.

## 2026-08-28 (color pass, part 5: date color, take three)

Sky (matching network.wifi exactly) was rejected as a literal duplicate. Tried
Sapphire next -- still a cool cyan-blue like Sky, close enough in the same "family"
that it still read as basically the same color at a glance. Landed on Flamingo: a
genuinely different hue (warm coral, not blue at all), so there's no ambiguity with
wifi, and it pairs as a warm/cool contrast against time's Lavender instead of two
blues sitting side by side.

Verified live: pixel-clustered date/wifi/time after reload -- Flamingo/date at
x927-1078, Sky/wifi at x1151-1354 (no overlap in position or color), Lavender/time
at x830-898 immediately to date's left, unchanged.

Also hit the remote session's connection dropping mid-verification on the previous
attempt (Sapphire) -- the CSS change had already landed and waybar had already
reloaded clean before the drop, confirmed by grep once the connection came back,
but the pixel-screenshot step and this commit hadn't happened yet. Nothing was
lost, just delayed to this entry.

## 2026-08-28 (color pass, part 4: clock reorder/recolor, docker count -> white)

Follow-up feedback on part 3: Rosewater on the date "doesn't look good", and asked
for the time to sit to the left of the date instead of the right.

- Swapped `modules-center` to `["clock#time", "clock"]` -- time first, date
  second. The negative margin that pulls the pair visually together (offsetting
  the bar's own 5px inter-module spacing) moved from `clock#time` to `#clock`
  accordingly, since it's the second element now that needs to pull left toward
  the first, not the other way around.
- Date recolored Rosewater -> Sky, matching the wifi module's color and the
  time's existing Lavender rather than the pale pink that wasn't landing well.
- Docker's container count is now white (Catppuccin's Text color, `#CDD6F4` --
  kept consistent with the theme rather than a stark pure `#FFFFFF`) instead of
  the running/idle Green-or-gray split from the previous pass. That state signal
  didn't disappear, it just moved: the `running`/`idle` class still exists and
  still drives the pill's border-color tint, same as before, just no longer
  duplicated in the count's own text color.

Verified live: reloaded, screenshotted, pixel-clustered Sky and Lavender --
Lavender (time) lands first at x830-898, Sky (date) right after at x927-1078,
distinctly separate from the network module's own Sky wifi text further right
(x1124-1327), confirming the reorder and the reuse aren't colliding into one
cluster.

## 2026-08-28 (color pass, part 3: battery charge states, clock split, docker/volume rework)

- **Battery**: only had colors for the two emergency thresholds (warning/critical)
  plus charging -- the normal "healthy, running on battery" state (`Discharging`,
  confirmed via `cat /sys/class/power_supply/BAT1/status`) fell through to plain
  silver. Added `#battery.discharging` (Green) and `#battery.full` (Teal, topped
  off and plugged in) using the `#battery.<status>` classes waybar derives from the
  kernel's power_supply status file (`waybar-battery(5)`) -- now every real charge
  state has its own color: Green healthy, Yellow charging, Teal full, Peach warning,
  Red critical. Placed before the existing warning/critical/charging rules in the
  stylesheet since they share selector specificity -- source order is what makes
  the low-battery colors win when both a status and a capacity-state class apply
  at once.
- **Pulseaudio**: Pink -> Maroon. Asked for something "dark/dominating" instead of
  a pastel -- Maroon is deep and grounded, distinct from Yellow on backlight right
  next to it, and its other use (bluetooth.on) sits in the opposite group so there's
  no adjacency clash.
- **Clock**: date and time are now two different colors (Rosewater / Lavender).
  First attempt used two `{:...}` placeholders in one format string with inline
  Pango spans -- waybar rejected it outright ("invalid arg-id in format string"),
  confirming the clock module only accepts one datetime placeholder per instance.
  Real fix: split into two module instances, `clock` (date, full pill) and
  `clock#time` (time, plain floating text next to it, no background of its own) --
  same "boxed pill + adjoining plain-colored text" pattern network/network#speed
  already established, not a new one.
- **Docker**: icon is now a constant Blue (was tied to running/idle state before),
  count switches Green/gray depending on whether anything's actually running --
  colored independently via inline Pango spans in `docker-status.sh` rather than
  one flat color for the whole label. The `running`/`idle` class still exists on
  the module, now driving a border-color tint on the pill instead of duplicating
  the count's own color signal.

Caught one real bug while writing this: a code comment mentioning the literal
path `power_supply/*/status` broke waybar's CSS parser outright (`'/*' in comment
block` at style.css:288) -- the `*/` inside that path silently closed the CSS
comment early. Waybar wouldn't even start until this was reworded. Also had to
rebuild `/tmp/pngdecode.py` a second time -- a mid-session connection drop wiped
`/tmp` entirely, same as every other time this has come up.

Verified every color live: reloaded, screenshotted, pixel-clustered all six new
colors against their expected x-position in the bar (clock date/time correctly
split into adjacent clusters at x834-985/x1016-1084, battery's new Green at
x1795-1846 near the power button, docker's Blue icon narrowed to just x343-355
now that the count isn't also blue, pulseaudio's Maroon confirmed distinct from
backlight's Yellow right beside it).

## 2026-08-27 (color pass, part 2: every remaining module gets its own hue)

Finished the "bar is too monochrome" pass -- clock, backlight, pulseaudio, docker,
and bluetooth's idle-but-on state were all still plain silver (`#CDD6F4`), the only
modules left without an identity color after the network pass. Picked with color
psychology in mind rather than arbitrarily:

- `clock` -> Rosewater. Glanced at constantly, so it gets the calmest, warmest hue
  rather than anything that reads as a status/alert.
- `backlight` -> Flamingo. Warm glow tone for light/comfort, deliberately not the
  Yellow already spoken for by capslock/battery-charging so brightness doesn't
  visually compete with those "heads up" moments.
- `pulseaudio` -> Pink. Audio is the most expressive/personal control in the bar,
  so it gets the most vivid hue left in the palette.
- `custom/docker` -> Blue when containers are actually running (matches Docker's
  own brand blue), dim gray when idle -- previously always showed the same static
  color regardless of whether anything was running. Needed a real script change,
  not just CSS: `docker ps -q | wc -l` piped straight into `format` had no way to
  carry a class, so wrote `scripts/.local/bin/docker-status.sh` (same
  `{"text","class","tooltip"}` JSON pattern as `caffeine-status.sh`) and switched
  the module to `"return-type": "json"`.
- `bluetooth.on` -> Maroon. This is the "powered on, nothing connected" state --
  was falling through to plain silver before, same gap as everything else here.
  Distinct from `.disabled` (gray) and `.connected` (green).

Verified every state live, not just visually glanced at: screenshotted and
pixel-searched for each of the six colors (four resting states plus docker's two),
confirming each cluster lands at the module's actual x-position in the bar (clock
dead center at x834-1084, bluetooth in the left group at x469-478, etc.). Docker's
`.running` state needed an actual running container to verify, so spun up
`docker run --rm -d alpine sleep 20` as a self-cleaning test -- confirmed the Blue
cluster appears at x343-376 while it's up, and `docker ps -a` shows nothing left
over once it exits on its own.

## 2026-08-27 (network module: color, signal strength, richer tooltip)

First piece of the wider "the bar is too monotone" color pass, scoped to `network`/
`network#speed` since that's what got asked about. Read `man waybar-network` before
touching anything -- it documents state-based CSS classes (`#network.wifi`,
`#network.ethernet`, `#network.disabled`, `#network.disconnected`, `#network.linked`)
and a full set of format placeholders that weren't being used at all before
(`{signalStrength}`, `{signaldBm}`, `{frequency}`, `{gwaddr}`, `{cidr}`).

- `#network.wifi` -> Sky `#89DCEB`, `#network.ethernet` -> Sapphire `#74C7EC` (same
  blue family since both mean "connected", distinct enough to tell wifi from wired
  at a glance), `#network.disabled` (rfkill-blocked) -> the same dim gray every other
  "off" state in the bar already uses. `#network.disconnected` (red) was already
  there and untouched.
- `format-wifi` now shows signal strength inline (`{essid}  {signalStrength}%`)
  instead of just the SSID.
- Tooltip went from nothing useful to real diagnostics: SSID/signal/dBm/frequency
  for wifi, interface/IP/gateway for ethernet, explicit disabled/disconnected text.
- `network#speed`'s down/up arrows are now two different colors via inline Pango
  markup (`<span color='...'>`, confirmed supported: `man waybar` -> "MODULE FORMAT"
  section) -- green for download, peach for upload -- rather than one flat color for
  both directions.

Verified for real, not just "JSON parses": reloaded waybar live, screenshotted with
`grim`, and pixel-searched the render (had to rewrite `/tmp/pngdecode.py` from
scratch again -- it's `/tmp`, doesn't survive a session/reboot, no PIL/imagemagick
available to install without sudo). Found Sky-colored pixels exactly where the
`network` module sits (x1121-1307), and two separate color clusters in the speed
module's x-range -- green at x1376-1444 (download), peach at x1495-1562 (upload) --
confirming the Pango spans render as two colors, not one blended block. The
`network.ethernet` rule can't be live-verified the same way (this machine's on wifi,
not ethernet, right now) -- taken on the man page's word that the class exists,
same discipline as everywhere else in this repo, just flagged as unverified live.

## 2026-08-27 (scroll was flooding waybar, and briefly drove volume to 1494%)

User reported scroll-to-adjust "wasn't working" on the volume/brightness pills.
`/tmp/waybar.log` had 249 lines of `Connection failure: Connection terminated` and
`Value "" of hint "value" could not be parsed as type "int"` -- real evidence, not a
guess. Root cause, found in `man waybar-pulseaudio`/`man waybar-backlight`: custom
`on-scroll-up`/`on-scroll-down` "replaces the default behaviour", and neither module
had `smooth-scrolling-threshold` set (default 0). Touchpads emit continuous
fractional scroll deltas, not discrete ticks, so with the threshold at 0 every
micro-delta from one scroll gesture fired the script separately -- dozens of
concurrent `pactl`/`brightnessctl`/`notify-send` processes within milliseconds,
flooding mako's D-Bus connection. Fixed with `"smooth-scrolling-threshold": 1` on
both modules.

Reproducing the flood manually (30 concurrent script calls) also caught a second,
more serious bug: `pactl set-sink-volume ... +5%` doesn't clamp at 100% -- the burst
drove the sink to **1494%**. Confirmed nothing was actually playing at the time
(`pactl list sink-inputs short` was empty), so nothing got physically blasted, but
it would have been genuinely dangerous if something had been. `brightnessctl` does
self-clamp (tested: `set 1000%` lands at exactly 100%), so brightness only had the
flood risk, not an overdrive risk. Fixed both scripts with `flock`-serialized
read-compute-apply, and `volume_osd.sh` now computes and clamps its own 0-100
target instead of trusting pactl's relative math. Re-ran the identical 30-call
burst after the fix: lands exactly at the 100%/0% boundary, zero waybar log errors.
Volume/brightness were reset back to their pre-test values (50%/5%) afterward.

## 2026-08-27 (volume/brightness: real sliders and device selection, not nwg-bar buttons)

The volume popup's Vol-/Vol+ buttons "didn't work" -- tested the underlying `pactl`
commands directly first (`env pactl set-sink-volume @DEFAULT_SINK@ -5%`, confirmed
90%->85%, worked fine), so the bug wasn't the command. Read `nwg-bar`'s `launch()`
in its Go source instead: it fires `glib.TimeoutAdd(150, gtk.MainQuit)` after *every*
click, so the whole popup closed ~150ms after each Vol-/Vol+ press -- no way to make
several incremental adjustments without reopening the menu each time. Root cause was
the widget, not the command: `nwg-bar` only has buttons (no scale/slider in its JSON
schema at all), and volume/brightness are drag-to-a-value interactions.

Replaced both:

- `pulseaudio` waybar module: click = mute/unmute, right-click = `pavucontrol` (real
  drag sliders, plus Output/Input device tabs -- microphone selection included, for
  free), scroll = +-5%. `pavucontrol` was already installed and already renders in
  Catppuccin Mocha (the GTK3 theme is applied system-wide via `gtk-3.0/settings.ini`),
  so no new styling work was needed.
- `backlight` waybar module: click = a new script, `scripts/.local/bin/brightness-slider.sh`,
  wrapping `zenity --scale --print-partial | while read v; do brightnessctl set
  "${v}%"; done` -- `--print-partial` streams every drag frame, so it's a real-time
  slider, not a set-once dialog. Needs `zenity` (added to `packages/pacman.txt`,
  official `extra` repo -- **not yet installed on the live machine**, this session
  has no `sudo`: `sudo pacman -S zenity`).
- Deleted `nwg-bar/.config/nwg-bar/volume.json` -- the button-popup it drove is gone.
- `sway/.config/sway/scripts/volume_osd.sh` gained a `mute-toggle` mode (used by both
  the waybar click and the `XF86AudioMute` key, replacing an inline `pactl && notify-send`
  one-liner that had drifted out of sync with the script) and now auto-unmutes before
  applying a volume delta, so scrolling/raising always changes what you actually hear.
  Added `XF86AudioMicMute` (`pactl set-source-mute @DEFAULT_SOURCE@ toggle`) -- there
  was no microphone-mute keybinding before this.
- `brightness_osd.sh`'s scroll path is unchanged in behavior, just now also wired to
  the waybar `backlight` module's `on-scroll-up`/`on-scroll-down` (previously those
  called raw `brightnessctl` directly, with no OSD notification at all).

Verified end to end with `sh -c` invocations matching exactly what waybar itself runs
(not just running the scripts directly): mute-toggle round-trips correctly
(`Mute: no` -> `yes` -> `no`), scroll volume goes 90%->85%, scroll brightness goes
0%->5%, `pavucontrol` resolves on `$PATH`. `brightness-slider.sh` itself needed a
`stow -R scripts` to actually land the new symlink in `~/.local/bin/` -- caught this
because the first `env` test of the exact waybar-invoked absolute path 404'd until
the restow.

## 2026-08-23 (same nwg-bar treatment for volume/wifi/bluetooth/docker -- found the tilde bug again)

Extended the power-menu pattern to four more waybar modules, reusing `nwg-bar` +
the same `style.css` (same glass-card look) rather than inventing a new mechanism per
module:

- `custom/docker` -> **Stats** (`kitty -e docker stats`), **Stop All** (a new wrapper
  script, `scripts/.local/bin/docker-stop-all.sh` -- `$(docker ps -q)` needs a real
  shell, which nwg-bar's `exec` never provides, so this couldn't be inlined in the
  JSON the way Stats could)
- `network` -> **Wi-Fi On/Off** (`nmcli radio wifi on|off`), **Settings**
  (`nm-connection-editor`)
- `bluetooth` -> **BT On/Off** (`bluetoothctl power on|off`), **Manager**
  (`blueman-manager`)
- `pulseaudio` -> **Mute**, **Vol -/+** (`pactl ...`), **Mixer** (`pavucontrol`)

Icons: none of these had bundled SVGs the way the power actions did, but `nwg-bar`'s
`createPixbuf()` (checked the source again) falls back to the system icon theme by
name when the icon string isn't an absolute path -- used standard freedesktop
`-symbolic` names (`audio-volume-high-symbolic`, `network-wireless-symbolic`,
`bluetooth-symbolic`, etc.), all confirmed present in the installed Adwaita theme
before using them, same discipline as verifying Nerd Font glyphs elsewhere. No new
icon assets bundled in this repo.

**Found the exact same class of bug again, in a new place**: waybar's `on-click`
strings used `~/.config/nwg-bar/wifi.json` for the `-t`/`-s` flags. Tested it the same
way as the Lock bug (no-shell invocation via `env`) before trusting it, and found
`nwg-bar`'s own flag parsing doesn't expand `~` either -- worse, it doesn't even
detect it isn't an absolute path the way it does for the `icon` field, so it
concatenated it onto its default config directory and produced a nonsensical path
that failed outright (`open .../nwg-bar/~/.config/nwg-bar/volume.json: no such file or
directory`). Fixed by using absolute paths in all four `on-click` strings, same as
the earlier Lock fix. Re-tested all four (`env nwg-bar -t /home/yash/... -s
/home/yash/...`) and confirmed each loads its correct item count with no errors.

## 2026-08-23 (nwg-bar robustness audit: found and fixed a real "Lock silently does the wrong thing" bug)

Asked to make sure the power button is robust and has no surprises, now that `nwg-bar`
is actually installed. Tested it for real rather than just checking it launches:

- **The Lock button would have shown a bare, unstyled swaylock screen instead of the
  configured one, with no error to explain why.** Read `nwg-bar`'s own Go source
  (`launch()` in `tools.go`): it calls `exec.Command()` directly on the split command
  string, with no shell involved at all -- so `~` in `swaylock -C
  ~/.config/sway/lockconfig` is never expanded, unlike every other place this exact
  command appears in this setup (sway's own `exec` keybinding, `swayidle`'s config),
  which all go through an actual shell. Verified this precisely, not just from reading
  the source: ran `swaylock -C '~/.config/sway/lockconfig'` (literal tilde, no shell,
  the exact byte string `nwg-bar` would pass) and watched it log `Found config at
  ~/.config/sway/lockconfig` immediately followed by `Failed to read config. Running
  without it.` -- swaylock treats the unexpanded tilde as a literal filename, fails
  silently, and falls back to a plain lock screen with none of the configured
  wallpaper/clock/Catppuccin colors. Fixed by using the absolute path
  (`/home/yash/.config/sway/lockconfig`) instead, and confirmed the fix with the same
  test: full config now parses line by line, wallpaper and all.

  (Incidentally locked this machine's real session for a few seconds running that
  first test, since it's genuine `swaylock` with PAM auth, not a mock -- unlocked it
  immediately afterward, no harm done, but worth knowing this class of test isn't
  fully inert.)

- Confirmed all other `exec` commands (`swaymsg exit`, `systemctl suspend/reboot/poweroff`)
  have no path/tilde dependencies, so they're not affected by the same no-shell
  behavior.
- Tested double-launching `nwg-bar` (simulating an accidental double-click on the
  waybar button): only one instance ends up running, no overlapping bars or errors.
- Swept the whole repo for leftover cruft from the wlogout/wofi iterations: no
  dangling references anywhere, `packages/*.txt` clean, and every script in the
  `scripts/` package is confirmed actually referenced from somewhere (sway config,
  waybar config, or a systemd unit) -- nothing orphaned.

## 2026-08-23 (power menu: switched tools -- wofi's dmenu mode wasn't built for this)

User feedback: alignment still off, no pointer cursor, click-outside still not
working -- fair, after five rounds of patching wofi's `--dmenu` mode, each fix
uncovered another real limitation in the same tool rather than converging:

- No CSS `cursor` property support in this GTK version (confirmed via a real GTK
  parse error, not a guess) -- can't give hover feedback via cursor shape at all in
  wofi's dmenu entries.
- `--columns` capped at 2 per row no matter the width or invocation method.
- `--hide-search` breaks entry rendering entirely when combined with `--dmenu`.
- `close_on_focus_loss` can't distinguish "clicked elsewhere" from "hovered near
  another window" while sway's `focus_follows_mouse` (global-only) is on, which it is
  by default.

Each of these is a real, separately-confirmed limitation of wofi's dmenu mode for
this specific use case (a small button-grid popup), not a config mistake -- so
continuing to patch around them wasn't going to converge. Researched purpose-built
alternatives instead of iterating further on the same tool.

**Switched to `nwg-bar`** (part of the nwg-shell project, official Arch `extra` repo --
no AUR build needed): read its actual Go source before committing to it, not just the
README --

- Real `gtk.ButtonNew()` widgets for every entry -- proper pointer-cursor hover
  behavior comes for free from GTK, unlike wofi's list/flow entries.
- Closes on `leave-notify-event` with a genuine 500ms debounce that's cancelled by
  `enter-notify-event` if the pointer comes back -- solves the "closes mid-hover"
  problem architecturally, since it's the bar's own pointer-leave event, not tied to
  sway's global focus model at all.
- Escape also closes it (`key-release-event` checking `KEY_Escape`).
- Its own default template *is* a sway exit menu (Lock/Logout/Reboot/Shutdown) --
  built for exactly this.
- One real limitation found before writing the config, not after: buttons get no
  individual CSS name/class in nwg-bar's source, so per-action accent colors (a
  different hover color for Lock vs Shutdown, like the earlier wlogout attempt) aren't
  possible here. Used one consistent Mauve accent instead, matching how most other
  waybar modules already work.

New `nwg-bar` stow package: `bar.json` (5 entries, referencing the icon SVGs the
`nwg-bar` package itself ships at `/usr/share/nwg-bar/images/` -- no icon assets
bundled in this repo) and `style.css` (same glass-card material as everywhere else:
kitty's 0.85 opacity, Mauve border/radius). Added to `packages/pacman.txt`. Removed
the wofi-based `power-menu.sh` and `power-style.css` entirely.

**Not yet verified visually** -- `nwg-bar` isn't installed on this machine and
installing it needs `sudo`, which this session doesn't have:
```bash
sudo pacman -S nwg-bar
```
Waybar's power button already points at it (`"on-click": "nwg-bar"`); it just won't
do anything until the package above is installed.

## 2026-08-23 (power menu: single row via orientation=horizontal, click-outside dropped for good)

Two things: confirmed in real use (not a synthetic test this time) that the popup was
closing whenever the pointer moved toward *any* window, not just on an actual click --
exactly the `focus_follows_mouse` interaction flagged two entries back, which my
`swaymsg`-based test hadn't actually reproduced (it forced a focus change directly,
which isn't the same as merely hovering causing one). And a request to switch from the
2-column grid to a single row with centered icons, shorter overall.

- Removed `close_on_focus_loss` for good this time. There's no way to get "click
  elsewhere closes it, hover elsewhere doesn't" out of this option while
  `focus_follows_mouse` is `yes` (sway's default, and global-only per `sway.5` -- no
  per-window override), so the honest fix here is to not use it. Dismissing is Escape
  or picking an option, matching every other wofi popup in this setup.
- Switched from `--columns 2` to `-D orientation=horizontal`: a different wofi layout
  mechanism, not subject to the 2-per-row cap `--columns` hit repeatedly in earlier
  entries. Puts all 5 icons in one row directly. Width 560->650, height 460->150 (one
  row needs far less vertical space than a 3-row grid). Verified: 649x149px against a
  requested 650x150, with all 5 tiles visible in a single centered row.

## 2026-08-23 (power menu: fit all tiles, no scrollbar, re-verified click-outside)

More feedback: not all 5 tiles were visible without scrolling, wanted the scrollbar
gone, wanted a pointer cursor on hover, and "click outside doesn't work at all" (true
-- the previous entry removed `close_on_focus_loss` entirely based on untested
reasoning about `focus_follows_mouse`).

- Width 460->560, height 280->460 -- 460px wasn't tall enough for 3 full rows of
  44px-icon tiles with 26px padding, so the third row (the 5th item) was getting cut
  off, forcing a scroll. Added `--hide-scroll` for the scrollbar itself. Verified: all
  5 tiles visible with room to spare, no scrollbar, 559x449px against a requested
  560x460.
- Tried `cursor: pointer` in CSS for the hand-cursor request -- GTK itself reported
  `Theme parsing error: 'cursor' is not a valid property name`, a real warning, not
  silently ignored. GTK3 controls cursor shape at the widget/GDK level, not via CSS,
  so this isn't fixable from the stylesheet. Removed the invalid property rather than
  leave dead CSS with a warning attached.
- **Actually tested `close_on_focus_loss` this time** instead of reasoning about it
  abstractly: opened a real window, confirmed the popup stays open with no action,
  then shifted focus to that window via `swaymsg` (simulating a genuine click
  elsewhere) and confirmed the popup closed immediately. It works correctly -- the
  previous entry's removal was based on untested theory about
  `focus_follows_mouse` that didn't hold up under an actual test. Re-added it.

## 2026-08-23 (power menu: wider, and click-outside removed for a real reason)

Two more requests: more width, and "moving the cursor away closes it" -- reported as a
bug, but it's a direct consequence of `close_on_focus_loss` (added in the previous
entry) interacting with sway's `focus_follows_mouse`, which defaults to `yes` when
unset (confirmed -- it's not set anywhere in `sway/config`). With hover-focus, moving
the mouse off the popup at all counts as losing focus, not just an actual click
elsewhere -- so the popup was closing on mere hover-away, not just clicks.

Checked whether `focus_follows_mouse` could be scoped to just this popup (`sway.5`
confirms it's a global-only command, no `for_window` equivalent) -- fixing this
properly would mean click-to-focus for the *entire* desktop, a far bigger change than
was asked for. Removed `close_on_focus_loss` instead: dismissing now works the same
way as every other wofi popup in this setup (app launcher, calculator, emoji picker)
already does -- Escape or picking an option, no click-outside.

Width 360->460 (height unchanged at 280). Verified: 459x279px against a requested
460x280.

## 2026-08-23 (power menu: bigger, no search bar, click-outside dismisses it)

Three more requests: more width and bigger buttons, remove the search bar, and close
on click-outside instead of requiring Escape.

- Width 220->360, height 320->280 (shorter now that the search bar's gone), tile
  padding 16px->26px, icon font-size 30px->44px. Verified via the same
  screenshot-and-measure approach: 359x279px against a requested 360x280.
- `close_on_focus_loss=true` (via `-D`, a real documented wofi config option, not
  guessed) makes wofi quit when it loses focus -- which is what happens when you
  click anywhere else. Confirmed the flag is actually present on the running
  process's command line; couldn't fully simulate a mouse click to test it end-to-end
  since `ydotool` isn't installed and `wtype` only does keyboard input, and installing
  a new package just for this one test wasn't worth it.
- Tried wofi's own `--hide-search` flag for the search bar first -- **broke entry
  rendering entirely** when combined with `--dmenu` in this wofi version (confirmed
  by testing side by side: identical command minus that one flag rendered the grid
  fine, with it the popup was empty). Worked around it by visually collapsing `#input`
  via CSS instead (`min-height: 0`, `opacity: 0`) -- keeps the widget functionally
  present, which avoids whatever code path the flag itself breaks, while still being
  invisible.

## 2026-08-23 (power menu: actual grid layout, not a vertical list)

Follow-up feedback: wanted the buttons in a real grid, and the popup ("too small but
kind of quite correct") nudged slightly bigger to fit one. wofi supports this
natively via `columns=`/`--columns` -- not something requiring a different tool this
time.

- Switched entries from "icon + text label" to icon-only. With text labels, columns
  rendered at uneven widths (a "Suspend" entry is wider than "Lock"), which is what
  broke the grid look initially.
- Requested `--columns 3` first. Tested it at three different popup widths (300, 400,
  700px), via both the CLI flag and an explicit `--conf` file, and it rendered as
  **exactly 2 columns every single time** -- confirmed this is a real cap in this
  wofi build (v1.5.3) for `--dmenu` mode specifically, not a sizing mistake, by also
  confirming `--columns 1` correctly renders a single column (so the setting isn't
  ignored outright, just capped above 2 here).
- Settled on `--columns 2`: 5 icons give a clean 2+2+1 grid. Verified the final
  popup's actual dimensions by screenshotting it and searching for the Mauve border
  color: 219×319px against a requested 220×320, and confirmed visually (rendered as
  an ASCII brightness map) that it's a real 2-column, 3-row grid, not another uneven
  wrap.
- Restyled `#entry` in `wofi/.config/wofi/power-style.css` for square-ish icon tiles
  (equal padding, larger icon font) now that there's no text label taking up
  horizontal space.

## 2026-08-23 (replaced wlogout with a compact wofi power menu)

User feedback on the fixed wlogout modal: wanted it transparent like kitty's terminal
(0.85 opacity) and much smaller, on the scale of a wofi popup, not a screen-spanning
modal. Tried to get there with wlogout first, hit a real architectural wall rather
than a styling problem:

- Measured (with a synthetic lime-green marker background, same technique as the
  caffeine padding fix, since the wallpaper's own colors made a plain Mauve-color
  search unreliable) that even with tiny 84px buttons, the 5 buttons still spanned
  1438×598px on screen -- three times wider than intended.
- Confirmed via wlogout's own `main.c` that its `GtkGrid` is a plain, unnamed grid
  with no size constraint in the code -- but GTK still expands it to fill the entire
  layer-shell surface (a widget property set at the C level, not something CSS
  `grid { ... }` can override in GTK3).
- Tried `--column-spacing 0 --row-spacing 0` explicitly -- **identical** 1438×598
  measurement, proving the spread isn't about spacing at all; wlogout's grid divides
  the full screen width into N equal columns regardless of button size or spacing
  flags. This is fundamental to how it lays out, not a config mistake.

Given the user's own size reference was wofi's popup, and wofi is already proven in
this exact setup to render at a precise, compact size (verified the app launcher's
600x400 elsewhere) -- switched the whole power menu to a `wofi --dmenu` list instead
of fighting a tool whose layout model doesn't support what was asked:

- New `scripts/.local/bin/power-menu.sh`: prints 5 lines (icon + label) to
  `wofi --dmenu --width 280 --height 260 --style ~/.config/wofi/power-style.css`,
  then runs the matching action from the selection -- same commands already used
  elsewhere in this setup (lock uses the identical
  `swaylock -C ~/.config/sway/lockconfig`).
- New `wofi/.config/wofi/power-style.css`: same visual language as the existing app
  launcher stylesheet, at kitty's 0.85 opacity instead of the launcher's 0.95, so it
  reads as the same "glass" material as the terminal.
- Verified the actual rendered popup by screenshotting it and searching for the Mauve
  border color within the expected center region: **279×259px**, matching the
  requested 280×260 almost exactly.
- Removed the `wlogout` stow package and its `packages/aur.txt` entry entirely --
  abandoned approach, not worth keeping around unused.

## 2026-08-23 (wlogout: fixed a genuinely broken modal, not just restyled it)

User feedback: "the UI of the popup modal is too crud." Investigated with the same
screenshot-and-measure discipline as the caffeine padding fix, rather than guessing at
CSS tweaks -- found real bugs, not just aesthetic ones:

- **The `wlogout` stow package had never actually been `stow`'d.** `~/.config/wlogout/`
  didn't exist at all -- wlogout had been silently falling back to `/etc/wlogout/`'s
  system-default layout and CSS this entire time. Every earlier CSS/layout edit had
  zero effect, because wlogout was never reading any of those files. Caught by running
  it with an explicit `-C`/`-l` path and seeing `Failed to open .../layout` in stderr;
  confirmed by checking `~/.config/wlogout` was simply missing. Now stowed.
- **wlogout's default `--buttons-per-row` isn't 5.** With exactly 5 buttons and no
  explicit `-b`, one button rendered as a proper large card and the other four were
  cramped into a fraction of the row -- confirmed visually via `grim` screenshots
  rendered as ASCII-art brightness maps (no image viewer available in this session).
  Fixed by passing `-b 5` explicitly in the waybar `on-click` command
  (`wlogout -b 5`), which wlogout's own layout math then distributes evenly.
- Tried centering each icon within its card via the `width`/`height` fields
  documented in `wlogout(5)` -- this triggered real `Gtk-CRITICAL` assertion failures
  (`gtk_label_set_yalign/xalign: assertion 'GTK_IS_LABEL (label)' failed`) and only
  marginally improved icon position. Reverted to the default (no `width`/`height`
  override) once confirmed clean and warning-free -- not worth a real GTK error for a
  small positioning tweak.
- Also hit the raw-glyph-gets-silently-stripped issue from earlier sessions many times
  while iterating on this -- inconsistently, sometimes 8+ consecutive identical
  attempts failed before one landed. Every glyph in the final `layout` file was
  written as a `\uXXXX` Python escape and verified by codepoint after writing, not
  trusted on the first attempt.
- Kept the `min-width`/`min-height: 220px` CSS sizing from the first pass as a safety
  net alongside `-b 5`, so card size stays consistent even if buttons-per-row ever
  changes.

Verified the final result with a clean screenshot: 5 evenly-sized floating cards, no
warnings in wlogout's own output.

## 2026-08-23 (power menu: waybar button + wlogout modal)

Added a power button to the far right of the waybar bar (`custom/power`, after
`battery`) that opens `wlogout` — a proper centered floating modal with five large
icon buttons (Lock, Logout, Suspend, Reboot, Shutdown), not a text dmenu list, since
that's what was actually asked for ("very aesthetic... floating... modal").

- New `wlogout` stow package: `layout` (5 buttons, each action wired to what's already
  used elsewhere in this setup -- `swaylock -C ~/.config/sway/lockconfig` for lock,
  matching the manual lock keybind and idle-lock config exactly) and `style.css`
  (Catppuccin Mocha, matching the rest of the desktop: Deep Midnight translucent
  backdrop, floating cards with the same hairline Mauve border as the waybar pills,
  large Nerd Font glyphs standing in for icons instead of bundled image assets --
  consistent with how every other module in this setup does icons).
- Each button gets a distinct hover accent, deliberately breaking from "one consistent
  accent everywhere" (the rule stated for every other waybar module): Mauve for lock,
  Lavender for logout, Teal for suspend, Peach for reboot, Red for shutdown. A power
  menu is the one place where distinguishing "gentle" from "final" by color is real
  feedback, not decoration -- same reasoning already used for workspace hover states.
- Verified every icon glyph (lock, logout, suspend, reboot, shutdown, and the waybar
  trigger's power-off icon) actually exists in JetBrainsMono Nerd Font's charset
  before using it, same discipline as every other icon added this session. Hit the
  raw-character-gets-silently-stripped issue (documented earlier for the tmux
  separators) twice more while building this -- inconsistently this time, sometimes a
  raw pasted glyph survived and sometimes it didn't with no clear pattern -- so
  switched fully to writing `\uXXXX` escapes in Python source and verifying the
  landed codepoints after every single write, rather than trusting either approach
  blindly.
- Added `wlogout` to `packages/aur.txt`. **Not yet installed on this machine** -- AUR
  package installation needs `sudo`, which this session doesn't have:
  ```bash
  yay -S wlogout
  ```
  The waybar button and config are ready; the button will just do nothing until the
  package above is installed.

## 2026-08-23 (audio/video/brightness robustness audit — found a battery safety gap)

Asked to make sure audio, display, and brightness are all robust and won't
unexpectedly "shut off." Audited each:

- **Brightness was at 1%** (`brightnessctl`: 655/65535) — looked alarming (screen
  effectively looks off) but isn't a bug: `systemd-backlight@backlight:amdgpu_bl1.service`
  is systemd's own brightness persistence (saves on shutdown, restores on boot) working
  exactly as designed. The *previous* session just happened to end at 1%. Bumped it to
  60% for practical use; nothing to fix in config.
- **Audio (pipewire/pipewire-pulse/wireplumber)**: all active, sound plays, volume/mute
  controls work. Clean.
- **Display/GPU**: `dmesg` clean of amdgpu errors or resets, `eDP-1` output active with
  DPMS on. Clean.
- **`batsignal` (battery warnings + forced-suspend-on-danger) was completely broken,
  possibly since it was first configured.** The exec line's comment said "Forces
  Suspend at 5%" but passed `-f` — which is actually batsignal's "battery **full**
  notification" flag (fires when *charging* completes) and requires a percentage
  argument it was never given. Result: `batsignal: Option -f requires an argument.` and
  immediate exit, every single time sway started it. There was no low-battery warning
  and no forced-suspend safety net at all -- a real battery-depletion event would have
  been an uncontrolled power-loss shutdown, not a graceful suspend.

  Fixed with the actual correct flag: `-D COMMAND` ("run COMMAND at the danger level"),
  wired to `-D "systemctl suspend"`. Verified the fix two ways, not just assumed: ran
  the corrected command line directly first (confirmed it starts and finds the battery
  instead of erroring instantly), then after converting to a systemd service, inspected
  `/proc/<pid>/cmdline` (NUL-separated, unlike `ps`) to confirm systemd's unit-file
  quoting actually kept `"systemctl suspend"` as one argument to `-D` rather than
  splitting it into two.

  Also converted to a systemd service (`systemd/.config/systemd/user/batsignal.service`,
  `Restart=on-failure`) rather than a raw `exec`, matching swayidle and
  sway-audio-idle-inhibit from earlier today -- this is exactly the kind of daemon
  where a silent, unnoticed crash has real consequences (no restart = no warning before
  the battery just dies), so it gets the same auto-recovery treatment.

Added to `install.sh`'s service-enable line.

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
