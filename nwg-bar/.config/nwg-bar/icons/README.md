# Power menu icons

Not nwg-bar's own stock icons -- reported back directly that Suspend in
particular ("a circle with a vertical rod in the middle") wasn't a
meaningful shape, and asked for better ones generally. Four of the five
are now Adwaita's own symbolic icon set (GNOME's, clean and widely
recognized) instead:

| Action   | Source | Shape |
| -------- | ------ | ----- |
| Lock     | Adwaita `system-lock-screen-symbolic` | a real padlock |
| Logout   | Adwaita `system-log-out-symbolic` | an exit arrow through a broken ring |
| Suspend  | Papirus `weather-clear-night-symbolic`'s own crescent, recolored | a crescent moon -- the universal "sleep" symbol, not another ring |
| Reboot   | Adwaita `system-reboot-symbolic` | a circular refresh/restart arrow |
| Shutdown | unchanged, this repo's own | the real ISO power/standby symbol (ring + vertical line) -- already correct from the previous pass, not touched |

Papirus's own `system-suspend-symbolic` was checked first and rejected --
it's the *same* ring-plus-dash shape as what was already there, so
switching to it wouldn't have actually fixed anything. A moon is a
completely different, unambiguous concept instead.

Every source icon ships with a hardcoded fill meant for *light* GNOME
toolbars (`#2e3436`, a dark charcoal) -- same "designed for the wrong
background" issue this repo already found and fixed for mako's own
notification icons. Recolored to `#CDD6F4` (Clean Silver, this bar's own
established text color) before use, not left at the stock color, so
they're actually visible against this card's dark background.

Kept flat, single-fill, no per-icon color -- that's still deliberately
the button's job (`style.css`'s own per-`nth-child` border tints), not
the icon's. Verified live: launched `nwg-bar` directly and read every
icon's rendered pixels back as ASCII art, not assumed correct from the
source SVGs alone.
