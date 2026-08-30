# Power menu icons

Local copies of nwg-bar's own stock icons (`/usr/share/nwg-bar/images/*.svg`),
not the system ones directly -- `bar.json` points here instead of
`/usr/share/nwg-bar/images/`.

Two real problems with the stock icons, found by actually reading the SVG
source rather than assuming a stock icon pack would just work:

1. **Every icon's colored background circle was invisible.** Each SVG has
   both a presentation attribute (`fill="#c2352a"` etc.) *and* an inline
   `style="fill:none;fill-opacity:1"` on the same `<circle>` element -- CSS
   `style` wins over the plain attribute, so the circle never actually
   rendered any color, regardless of theme. Every action (Lock, Logout,
   Suspend, Reboot, Shutdown) showed as the same flat white ring-shaped
   glyph with no fill behind it -- reported directly as icons needing
   "some color" and "proper meaningful icons".
2. **Suspend and Shutdown shipped with the exact same red** (`#c2352a`),
   despite being very different actions (one soft/reversible, one final)
   -- no color distinction between the two even if the circles had
   rendered.

nwg-bar itself gives buttons no individual CSS name/class to target per
action (confirmed from its own source, noted in `style.css`), so per-action
color can't be done at the CSS layer here the way it is everywhere else
in this bar -- it has to live in the icon files themselves.

Fixed both: removed the `fill:none` override so each circle actually
shows, and recolored every one to this desktop's own Catppuccin Mocha
palette instead of the stock pack's arbitrary colors, so they read as
part of the same visual language as every other module rather than
their own thing:

| Action   | Color               | Why |
| -------- | -------------------- | --- |
| Lock     | Sapphire `#74C7EC`   | calm, protective -- matches this bar's other "safe/connected" contexts (wifi) |
| Logout   | Peach `#FAB387`      | ending the session, not destructive -- matches battery/backlight's "warm but not alarming" use |
| Suspend  | Teal `#94E2D5`       | restful, fully reversible -- matches battery-full/numlock's calm precedent |
| Reboot   | Yellow `#F9E2AF`     | in progress / caution -- matches battery-charging's precedent |
| Shutdown | Red `#F38BA8`        | the one genuinely final, hard-to-reverse action here -- matches every "destructive/final" use elsewhere in this desktop (dnd mode, dialog-error, battery-critical) |

The glyph shapes themselves were already correct and left untouched --
Shutdown in particular is the real ISO 7000-0001 power/standby symbol
(a ring with a vertical line through the top), not swapped for anything
else, just given back its color.

Verified live: launched `nwg-bar` directly, screenshotted the real
rendered card, and read the actual pixels back as ASCII art (thresholded
by color/brightness, not assumed) for both Shutdown and Lock -- confirmed
a solid colored circle with the correct white glyph cut cleanly out of
the middle for each, not just "a color exists somewhere in the file".
