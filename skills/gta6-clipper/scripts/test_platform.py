#!/usr/bin/env python3
"""Offline checks for discovery rules and Windows path handling. No network, no models."""
import os, sys, tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gta6clip as g


def kind(title, duration=0, live_status="", source=None):
    entry = {
        "id": "abcdefghijk", "title": title, "duration": duration, "live_status": live_status,
        "view_count": 100, "concurrent_view_count": 50, "channel": "Tester",
    }
    if source:
        entry["_source"] = source
    row = g.classify_youtube(entry)
    return None if row is None else row["kind"]


CHECKS = [
    ("GTA 6 full stream with friends", 3 * 3600, "not_live", None, "stream"),
    ("GTA VI gameplay night", 15 * 60, "not_live", None, "video"),
    ("GTA 6 launch", 4000, "is_live", None, "live"),
    ("GTA 6 trailer", 90, "", None, None),
    ("Minecraft survival", 3600, "", None, None),
    ("GTA-6 funny moments", 12 * 60, "", None, "video"),
    ("GTA six playthrough", 0, "", None, "stream"),
    ("GTA 6 highlights", 0, "", None, None),
    ("GTA 6 night shift", 0, "", "live", "live"),
    ("GTA vibe check", 20 * 60, "", None, None),
    ("gta64 speedrun", 20 * 60, "", None, None),
    ("Grand Theft Auto VI full game", 40 * 60, "", None, "stream"),
    ("GTA 6 premiere tonight", 0, "is_upcoming", None, None),
    ("GTA6 #shorts compilation", 20 * 60, "", None, None),
    ("GTAVI day one", 25 * 60, "", None, "stream"),
]


def main():
    failed = 0
    for title, dur, status, source, expect in CHECKS:
        got = kind(title, dur, status, source)
        if got != expect:
            print(f"FAIL {title!r}: got {got}, expected {expect}")
            failed += 1
        else:
            print(f"ok   {expect}  {title}")

    assert g.GTA_RE.search("GTAVI")
    assert g.GTA_RE.search("gta_6")
    assert g.GTA_RE.search("grand theft auto six")
    assert not g.GTA_RE.search("gta 5")
    assert not g.GTA_RE.search("gta64")
    assert not g.GTA_RE.search("gta vibe")

    line = g.ffmpeg_concat_line(Path("/tmp/it's a clip.mp4"))
    assert line.startswith("file '"), line
    assert "it'\\''s" in line, line
    assert "\\tmp" not in line, line
    assert "/tmp/it" in line, line

    assert g.pid_alive(os.getpid())
    assert not g.pid_alive(0)
    assert not g.pid_alive("nope")
    assert g.which_tool("definitely-missing-tool-xyz") == "definitely-missing-tool-xyz"

    folder = Path(tempfile.mkdtemp())
    target = folder / "t.txt"
    target.write_text("GTA 6 \U0001f62d\nline\n")
    data = target.read_bytes()
    assert "\U0001f62d".encode() in data
    assert b"\r\n" not in data
    assert target.read_text() == "GTA 6 \U0001f62d\nline\n"

    real_yt, real_tw = g.discover_youtube, g.discover_twitch

    def fake_yt(*_a, **_k):
        return [
            {"platform": "youtube", "kind": "video", "id": "aaaaaaaaaaa", "streamer": "Ada",
             "title": "a", "viewers": 10, "url": "https://y/a", "live_now": False},
            {"platform": "youtube", "kind": "live", "id": "bbbbbbbbbbb", "streamer": "Ada",
             "title": "live", "viewers": 5, "url": "https://y/b", "live_url": "https://y/b", "live_now": True},
            {"platform": "youtube", "kind": "video", "id": "ccccccccccc", "streamer": "Ada",
             "title": "c", "viewers": 99, "url": "https://y/c", "live_now": False},
        ]

    def fake_tw(*_a, **_k):
        return []

    g.discover_youtube, g.discover_twitch = fake_yt, fake_tw
    try:
        picked = g.discover_streams(limit=5, warn=lambda *_a, **_k: None)
        assert [p["id"] for p in picked] == ["bbbbbbbbbbb", "ccccccccccc"], picked
        live = g.discover_streams(limit=5, live_only=True, warn=lambda *_a, **_k: None)
        assert [p["id"] for p in live] == ["bbbbbbbbbbb"], live

        def fake_mix(*_a, **_k):
            lives = [{"platform": "youtube", "kind": "live", "id": f"l{i}aaaaaaaaa", "streamer": f"L{i}",
                      "title": "t", "viewers": 100 - i, "url": f"https://y/l{i}", "live_now": True} for i in range(4)]
            vids = [{"platform": "youtube", "kind": "video", "id": f"v{i}aaaaaaaaa", "streamer": f"V{i}",
                     "title": "t", "viewers": 50 - i, "url": f"https://y/v{i}", "live_now": False} for i in range(2)]
            return lives + vids

        g.discover_youtube = fake_mix
        mixed = g.discover_streams(limit=4, warn=lambda *_a, **_k: None)
        assert [p["kind"] for p in mixed] == ["live", "live", "video", "video"], mixed
    finally:
        g.discover_youtube, g.discover_twitch = real_yt, real_tw

    if failed:
        sys.exit(1)
    print("ALL OK")


if __name__ == "__main__":
    main()
