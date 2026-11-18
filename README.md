# GTA 6 Clipper

Two free Claude Code skills that turn GTA 6 streams and YouTube videos into ready-to-post vertical clips.

- **gta6-clipper** clips a video or a stream that has finished. Give it a YouTube, Twitch or Kick link, or nothing. With nothing, it finds GTA 6 YouTube videos, finished streams, and livestreams by itself.
- **gta6-live-clipper** clips a stream while it is still live. Give it a link, or nothing. With nothing, it finds the biggest GTA 6 livestream and starts recording it. A clip is ready about 5 to 8 minutes after the moment happens.

Every clip comes out 1080x1920: facecam on top, gameplay below, a hook title, word-by-word captions, and a post caption with hashtags.

**Mac and Windows.**

You do not need a YouTube API key. Twitch in the search is optional (see below).

## Install

### Option A: paste this into Claude Code (easiest)

```text
Install the GTA 6 Clipper skills from https://github.com/Bastiveka/clipper-gta6.
Clone the repo to a temporary folder, then copy BOTH folders inside its skills/ folder
(gta6-clipper and gta6-live-clipper) into the Claude skills folder so they sit side by side.
- Mac: ~/.claude/skills/
- Windows: %USERPROFILE%\.claude\skills\
Then run setup:
- Mac: bash ~/.claude/skills/gta6-clipper/scripts/setup.sh
- Windows: powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\gta6-clipper\scripts\setup.ps1"
Tell me what it installed and whether it says READY. Then remind me to restart Claude Code.
```

### Option B: as a Claude Code plugin

In Claude Code, add the marketplace for the GitHub repository you cloned (the original Mac-only release is `vossashtonai/gta6-clipper`; this copy is the Mac and Windows one):

```text
/plugin marketplace add Bastiveka/clipper-gta6
/plugin install gta6-clipper@ashtonvossai
```

Then say **set up the GTA 6 clipper**. On Windows, setup runs `scripts/setup.ps1`.

### Option C: by hand

Mac:

```bash
git clone https://github.com/Bastiveka/clipper-gta6.git /tmp/gta6-clipper
cp -R /tmp/gta6-clipper/skills/gta6-clipper /tmp/gta6-clipper/skills/gta6-live-clipper ~/.claude/skills/
bash ~/.claude/skills/gta6-clipper/scripts/setup.sh
```

Windows (PowerShell):

```powershell
git clone https://github.com/Bastiveka/clipper-gta6.git $env:TEMP\gta6-clipper
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse -Force $env:TEMP\gta6-clipper\skills\gta6-clipper, $env:TEMP\gta6-clipper\skills\gta6-live-clipper "$env:USERPROFILE\.claude\skills\"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\gta6-clipper\scripts\setup.ps1"
```

Setup checks what the computer needs and installs what's missing: FFmpeg, whisper.cpp, Deno, a Python environment (yt-dlp, OpenCV, Pillow) and the Whisper speech model (~465 MB). On a Mac that goes through Homebrew. On Windows it uses winget, plus a Windows build of whisper.cpp. Re-run it any time downloads start failing; it updates yt-dlp.

## Use it

Open Claude Code and say:

- **clip today's GTA 6 videos** (no link: it searches YouTube)
- **live clip** (no link: it finds a GTA 6 livestream and records it)
- **clip this stream** `<link>` when you already have one

Clips land in a `GTA6-Clips` folder in your home folder (`~/GTA6-Clips` on Mac, `C:\Users\<you>\GTA6-Clips` on Windows). Each one has an `.mp4` and a `.txt` with the title, caption and hashtags.

## How it works

| Step | Finished video or stream | Live stream | Tools |
|---|---|---|---|
| 0. Find it | YouTube search, no API key. Twitch if `.env` is set | Same search, Live tab only | yt-dlp |
| 1. Get the video | Downloads the audio only (4 h ≈ 220 MB) | Records 1-minute pieces, keeps the last 15 min | yt-dlp, FFmpeg |
| 2. Speech to text | Whole video in one go | Each minute as it lands | FFmpeg, Whisper |
| 3. Find the hype | Loud seconds + YouTube replay chat speed | Loud seconds + live Twitch chat speed | FFmpeg, chat |
| 4. Pick the moments | Claude reads 12-min chunks, best 3 scoring 7+ | Claude reads each 5-min window, any 7.5+ | Claude Code |
| 5. Make the clip | Downloads only those minutes | Cuts from the pieces already on disk | OpenCV, Whisper, Pillow, FFmpeg |

Chat is counted, never read: 10-second buckets, a spike is 8+ messages at 2.5x the normal rate. Loud means 9 dB above the streamer's own normal. The facecam is found by looking for a face, and box edges, that stay still while the gameplay moves.

## Run it free

Picking (step 4) is the only part that uses AI. Everything else runs on your computer. To run without a Claude subscription:

1. Install [Ollama](https://ollama.com).
2. Check your memory. Mac: Apple menu → About This Mac → Memory. Windows: Settings → System → About → Installed RAM. 16 GB: `ollama pull qwen3.5:9b`. 32 GB or more: `ollama pull qwen3.5:27b`.
3. In a terminal: `ollama launch claude` and pick the model.
4. Same prompts as above.

The free model is slower and its picks are rougher than Claude's. Expect some back and forth.

## Good to know

- Age-restricted YouTube videos and Kick need your browser login. Tell Claude to use `--cookies chrome` (or `edge`, `firefox`, `brave`). On Windows, close that browser first or the cookie copy fails. Safari is Mac only.
- YouTube streams that are still live can be clipped by the finished-stream skill once the replay is up. Twitch past broadcasts work while the stream is still going.
- Twitch in "find streams" is optional: create a free app at [dev.twitch.tv/console](https://dev.twitch.tv/console) and put `TWITCH_CLIENT_ID` and `TWITCH_CLIENT_SECRET` in `skills/gta6-clipper/.env` (see `.env.example`). YouTube search does not need this.
- Live clipping needs the Claude Code session to stay open, and run at most 2 streams at once on a 16 GB computer.
- Clip streamers who are fine with clipping, and watch every clip before you post it.
- YouTube ad money needs the Partner Program, and YouTube can refuse it for reposted, mass-made content. Add something of your own.

## Made by

[Ashton Voss AI](https://www.youtube.com/@ashtonvossai). More free AI systems in the AI Alliance Community.

Windows support and automatic YouTube search were added on top of that project. MIT licensed.
