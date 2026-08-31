#!/usr/bin/env python3
"""Search + download a song straight from YouTube, no Invidious involved.

Built to replace termusic's own `s` (youtube_search) popup, which turned
out to be entirely dependent on the public Invidious instance network --
confirmed dead across the board (checked the live instance directory
directly: 0 of 11 currently-listed public instances have their API
enabled at all), not something a termusic upgrade would fix either
(checked upstream's own changelog -- still Invidious-based, no
alternative backend exists). yt-dlp itself was independently confirmed
to search and download from YouTube directly with zero involvement from
that broken network, so this rebuilds "search, pick a result, get an
mp3 in ~/Music" on top of that instead -- matching this repo's own
established pattern (wifi-picker.py, bluetooth-picker.py) of building a
small, self-contained script when no existing tool actually does the
job reliably.

Flow: wofi prompt for a query -> yt-dlp search (fast, ~2-3s, --flat-playlist
so it only fetches search-result-page metadata, not per-video detail) ->
wofi list of results (title, uploader, duration -- duration shown
specifically because search results can include multi-hour livestreams
alongside actual songs, confirmed by literally downloading one by
accident once while testing this) -> download the picked one as mp3
into ~/Music, with embedded cover art and metadata, using its own
thumbnail as the completion notification's icon (same "use the real
fetched image as its own icon" pattern fetch_wallpaper.sh already uses).

`--extractor-args "youtube:player_client=android"` on the download step
specifically: confirmed directly, not assumed, that yt-dlp's default
web-client extraction hit YouTube's "Sign in to confirm you're not a
bot" wall on 2 of 3 real test downloads, while the exact same URLs
downloaded cleanly every time with this flag -- a known, standard
workaround (the android player API isn't gated behind the same
web-based verification), not something invented here.

Termusic doesn't auto-detect new files while running (no filesystem
watcher in its source, confirmed by reading it -- library scanning only
happens at startup and on explicit navigation) -- a track downloaded
here while termusic is already open won't appear until you navigate out
of the music root and back in, or restart it. Not solved further here;
just worth knowing rather than assuming it "just works".
"""
import glob
import json
import os
import subprocess
import sys

MUSIC_DIR = os.path.expanduser("~/Music")

# Absolute paths, not theme names -- same reasoning as every other icon
# fix this session: mako has no GTK-style theme resolution, and these
# are Papirus's real-fill `status` icons, confirmed present before use.
ICON_INFO = "/usr/share/icons/Papirus/48x48/status/dialog-information.svg"
ICON_ERROR = "/usr/share/icons/Papirus/48x48/status/dialog-error.svg"
ICON_WARNING = "/usr/share/icons/Papirus/48x48/status/dialog-warning.svg"


def notify(title, body, icon=ICON_INFO, urgency="normal"):
    subprocess.run(
        ["notify-send", "-u", urgency, "-i", icon, title, body], check=False
    )


def get_query():
    result = subprocess.run(
        ["wofi", "--show", "dmenu", "--prompt", "Search YouTube...", "--lines", "1"],
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def search(query, count=10):
    """Search-only, via yt-dlp directly -- no Invidious. --flat-playlist
    keeps this fast (~2-3s for 10 results) since it only reads the
    search-results page itself, not each video's own full metadata."""
    proc = subprocess.run(
        [
            "yt-dlp",
            f"ytsearch{count}:{query}",
            "--flat-playlist",
            "--dump-json",
            "--no-warnings",
        ],
        capture_output=True,
        text=True,
        timeout=20,
    )
    results = []
    for line in proc.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        results.append(d)
    return results


def format_duration(seconds):
    if not seconds:
        return "?:??"
    seconds = int(seconds)
    return f"{seconds // 60}:{seconds % 60:02d}"


def pick_result(results):
    lines = []
    lookup = {}
    for d in results:
        title = (d.get("title") or "?").replace("\n", " ")
        uploader = d.get("uploader") or d.get("channel") or "?"
        dur = format_duration(d.get("duration"))
        line = f"{title}  --  {uploader}  ({dur})"
        lines.append(line)
        lookup[line] = d

    proc = subprocess.run(
        [
            "wofi",
            "--dmenu",
            "--insensitive",
            "--matching",
            "fuzzy",
            "--prompt",
            "Pick a track...",
            "--lines",
            "10",
        ],
        input="\n".join(lines),
        capture_output=True,
        text=True,
    )
    sel = proc.stdout.strip()
    return lookup.get(sel)


def download(video_id, title):
    url = f"https://youtube.com/watch?v={video_id}"
    notify("Music search", f"Downloading: {title}", icon=ICON_INFO)

    proc = subprocess.run(
        [
            "yt-dlp",
            "-x",
            "--audio-format",
            "mp3",
            "--embed-thumbnail",
            "--add-metadata",
            "--write-thumbnail",
            # See module docstring -- confirmed directly this avoids the
            # "Sign in to confirm you're not a bot" wall the default web
            # client hits on a real fraction of videos.
            "--extractor-args",
            "youtube:player_client=android",
            "--no-warnings",
            "-o",
            os.path.join(MUSIC_DIR, "%(title)s.%(ext)s"),
            url,
        ],
        capture_output=True,
        text=True,
        timeout=180,
    )

    if proc.returncode != 0:
        # Bot-check and other yt-dlp failures land here -- surfaced
        # honestly rather than silently swallowed, with enough of the
        # real error visible to actually act on (e.g. try a different
        # result if this one specifically is blocked).
        err = proc.stderr.strip().splitlines()[-1] if proc.stderr.strip() else "unknown error"
        notify("Music search failed", err[:200], icon=ICON_ERROR, urgency="critical")
        return

    # Use the track's own thumbnail as the completion notification's
    # icon -- same "the real fetched image is its own icon" pattern
    # fetch_wallpaper.sh already uses. Deliberately *not* reconstructing
    # the expected filename from `title` -- a real bug caught by testing
    # this directly: yt-dlp's own filesystem sanitization doesn't match
    # the raw title string (confirmed on a real download -- the search
    # JSON's title had a plain ASCII "|", the file yt-dlp actually wrote
    # had a fullwidth "｜" in its place, U+FF5C, since a literal pipe
    # isn't filesystem-safe), so a glob built from `title` silently
    # matched nothing and left the thumbnail undeleted. Finding the
    # newest image file in MUSIC_DIR instead sidesteps needing to
    # predict yt-dlp's own sanitization rules at all -- safe here since
    # this script only ever runs one download at a time.
    thumb_icon = ICON_INFO
    thumbs = sorted(
        (
            p
            for ext in ("jpg", "jpeg", "webp", "png")
            for p in glob.glob(os.path.join(MUSIC_DIR, f"*.{ext}"))
        ),
        key=os.path.getmtime,
        reverse=True,
    )
    if thumbs:
        thumb_icon = thumbs[0]
        thumbs = thumbs[:1]

    notify("Music search", f"Downloaded: {title}", icon=thumb_icon)

    # The separate thumbnail file's only purpose was this notification
    # icon -- the mp3 already has the same art embedded
    # (--embed-thumbnail above). Removing it afterward keeps ~/Music a
    # clean folder of just tracks for termusic's own library scan,
    # instead of a stray image file sitting next to every song.
    for t in thumbs:
        try:
            os.remove(t)
        except OSError:
            pass


def main():
    os.makedirs(MUSIC_DIR, exist_ok=True)

    query = get_query()
    if not query:
        return

    try:
        results = search(query)
    except subprocess.TimeoutExpired:
        notify("Music search", "Search timed out", icon=ICON_WARNING, urgency="critical")
        return

    if not results:
        notify("Music search", f"No results for \"{query}\"", icon=ICON_WARNING)
        return

    picked = pick_result(results)
    if not picked:
        return

    title = (picked.get("title") or "?").replace("\n", " ")
    video_id = picked.get("id")
    if not video_id:
        notify("Music search", "Couldn't get a video id for that result", icon=ICON_ERROR, urgency="critical")
        return

    try:
        download(video_id, title)
    except subprocess.TimeoutExpired:
        notify("Music search", f"Download timed out: {title}", icon=ICON_ERROR, urgency="critical")


if __name__ == "__main__":
    sys.exit(main())
