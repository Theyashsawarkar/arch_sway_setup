# Power menu icons

Local copies of nwg-bar's own stock icons (`/usr/share/nwg-bar/images/*.svg`),
not the system ones directly -- `bar.json` points here instead of
`/usr/share/nwg-bar/images/`, so a package update to nwg-bar can't silently
change how this menu looks.

Plain, matching stock nwg-bar's own appearance (`fill:none` on each icon's
background circle, same as upstream ships it) -- deliberately **not**
recolored. An earlier pass here painted a different Catppuccin color into
each icon's own circle fill; reported back directly that "colors" meant
follow the status bar's own palette treatment, not repaint the glyphs
themselves. Per-action color now lives on the *button* instead
(`style.css`'s own per-`nth-child` border tints) -- the same layer waybar
itself uses for module identity, not the icon layer. See `style.css` for
the actual color mapping and reasoning.

Kept as local copies rather than reverting to the system path outright,
since that's still worth having independent of nwg-bar package updates --
just with the same visual result as stock for now.
