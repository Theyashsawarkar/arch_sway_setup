#!/usr/bin/env python3
"""Themed wrapper around the system's networkmanager_dmenu (see
ARCHITECTURE.md's networkmanager-dmenu entry). Adds category-based Pango
colors -- network / saved connection / command -- on top of upstream's
existing active-connection highlight, so the different kinds of rows in
the menu ("connect to this network" vs "a saved connection" vs "a command
like Rescan/Enable/Disable") are visually distinguishable at a glance
instead of all rendering the same color.

Monkeypatches exactly two functions (get_wofi_highlight_markup,
get_selection) on the real installed module rather than forking the whole
script -- everything else (NetworkManager interaction, connecting,
scanning, password prompts) still comes from the real, maintained
upstream package. Category detection is by Action.func identity
(process_ap == a real network) plus the ":SAVED" suffix upstream already
puts on saved-connection action names -- both are core to how the tool
actually works, not incidental detail likely to silently change, but
wrapped defensively (_category() swallows any AttributeError) so a future
upstream refactor degrades to "no color" rather than a crash.

get_selection is simplified from upstream to the wofi-only code path
(upstream branches on rofi/wofi/plain-dmenu; this repo only ever uses
wofi, dmenu_command=wofi is hardcoded in config.ini) -- kept otherwise as
close to a literal copy as possible, since the line-generation and
selection-matching have to stay in exact sync or clicking an entry either
does nothing or fires the wrong action.
"""
import importlib.machinery
import importlib.util
import sys

NMDM_PATH = "/usr/bin/networkmanager_dmenu"

# spec_from_file_location can't infer a loader for a file with no .py
# extension (it returns None rather than raising, which then fails
# confusingly one line later) -- has to be given an explicit loader.
_loader = importlib.machinery.SourceFileLoader("networkmanager_dmenu", NMDM_PATH)
spec = importlib.util.spec_from_loader(_loader.name, _loader)
nmdm = importlib.util.module_from_spec(spec)
_loader.exec_module(nmdm)

# Catppuccin Mocha, matching the rest of the bar's palette.
CATEGORY_COLORS = {
    "network": "#89DCEB",  # Sky -- matches waybar's own network.wifi color
    "saved": "#94E2D5",    # Teal -- calm, "known and ready, not live-scanned"
    "command": "#FAB387",  # Peach -- "this changes something" energy
}

_COMMAND_FUNC_NAMES = (
    "toggle_wifi",
    "toggle_networking",
    "toggle_bluetooth",
    "toggle_wwan",
    "launch_connection_editor",
    "delete_connection",
    "rescan_wifi",
    "show_wifi_password",
    "prompt_saved",  # the "Saved connections" row that opens the submenu
)
_COMMAND_FUNCS = {
    getattr(nmdm, name) for name in _COMMAND_FUNC_NAMES if hasattr(nmdm, name)
}


def _category(action):
    try:
        if str(action).endswith(":SAVED"):
            return "saved"
        if action.func in _COMMAND_FUNCS:
            return "command"
        if action.func is getattr(nmdm, "process_ap", None):
            return "network"
    except AttributeError:
        pass
    return None


def themed_markup(action):
    """Replacement for nmdm.get_wofi_highlight_markup -- colors every line
    by category. The active connection still gets the original
    highlight_fg/bg/bold treatment from config.ini on top, checked first
    so it always wins over the category color."""
    style = ""
    if action.is_active:
        highlight_fg = nmdm.CONF.get("dmenu", "highlight_fg", fallback="")
        highlight_bg = nmdm.CONF.get("dmenu", "highlight_bg", fallback="")
        highlight_bold = nmdm.CONF.getboolean(
            "dmenu", "highlight_bold", fallback=True
        )
        if highlight_fg:
            style += f'foreground="{highlight_fg}" '
        if highlight_bg:
            style += f'background="{highlight_bg}" '
        if highlight_bold:
            style += 'weight="bold" '
    else:
        color = CATEGORY_COLORS.get(_category(action))
        if color:
            style += f'foreground="{color}" '

    if not style:
        return str(action)
    return f"<span {style}>" + str(action) + "</span>"


def themed_get_selection(all_actions):
    inp = [themed_markup(action) for action in all_actions]
    active_lines = [
        index for index, action in enumerate(all_actions) if action.is_active
    ]

    prompt = nmdm.CONF.get("dmenu", "prompt", fallback="Networks")
    command = nmdm.dmenu_cmd(f"{prompt} ", active_lines=active_lines)
    sel = nmdm.run_dmenu(command, "\n".join(inp)).stdout

    if not sel.rstrip():
        sys.exit()

    action = [
        i
        for i in all_actions
        if str(i).strip() == sel.strip() or themed_markup(i) == sel.strip()
    ]
    if len(action) != 1:
        raise ValueError(f"Selection was ambiguous: '{str(sel.strip())}'")
    return action[0]


nmdm.get_wofi_highlight_markup = themed_markup
nmdm.get_selection = themed_get_selection

if __name__ == "__main__":
    nmdm.main()
