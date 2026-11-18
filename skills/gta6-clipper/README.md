# GTA 6 Clipper (free Claude Code skill)

An AI that clips GTA 6 videos and streams for you. Give it a link from YouTube, Twitch or Kick, or nothing.
With nothing, it finds GTA 6 YouTube videos, finished streams, and livestreams by itself. You get ready-to-post
vertical clips: facecam on top, gameplay below, a hook title, word-by-word captions, and a post caption with hashtags.

Mac and Windows. YouTube search needs no API key.

## What it does, in 4 steps

1. **Finds the videos** when you don't paste a link, then **downloads only the audio.** A 4-hour stream is a couple hundred MB, not a giant video file.
2. **Listens to the whole video on your computer:** a transcript, where the streamer got loud, and (on YouTube replays) where chat suddenly sped up.
3. **The AI reads the transcript 12 minutes at a time** and picks what people share: first reactions, crazy discoveries, freakouts, funny fails, hot takes. Every moment gets a score, and anything that needs context gets thrown out.
4. **Downloads only the minutes it needs,** finds the facecam by itself and makes the clips, plus a caption and hashtags for each one.

3 clips per video by default. Several videos run at once.

## Way 1: your Claude subscription (best)

Plans start at $20/month. No API keys. Everything except the picking runs on your computer.

1. Put this `gta6-clipper` folder in the Claude skills folder, next to `gta6-live-clipper`.
   Mac: `~/.claude/skills/`. Windows: `%USERPROFILE%\.claude\skills\`.
2. Open Claude Code and say: **set up the GTA 6 clipper**. It checks what your computer needs, installs what's missing and tells you when it's ready.
3. Say: **clip today's GTA 6 videos**. Or: **live clip**. Or: **clip this stream** and paste a link.

## Way 2: free (no subscription, no API key)

1. Install [Ollama](https://ollama.com) and Claude Code (both free).
2. Check your memory, not your storage. Mac: Apple menu -> About This Mac -> Memory. Windows: Settings -> System -> About -> Installed RAM.
3. 16 GB -> `ollama pull qwen3.5:9b`. 32 GB or more -> `ollama pull qwen3.5:27b`.
4. In a terminal: `ollama launch claude` and pick your model.
5. Same prompts as Way 1.

Honest take: the free model isn't Claude. It's slower, the picks are rougher, and expect some back and forth. It still beats scrubbing a video by hand.

## Good to know

- Mac and Windows.
- Age-restricted YouTube videos (common with GTA) and Kick need your browser login: tell Claude to use `--cookies chrome` (or `edge`, `firefox`, `brave`). On Windows, close that browser first. Safari is Mac only.
- YouTube streams that are still live can be clipped once the replay is up. Twitch archives work while live. Say **live clip** to clip a livestream as it happens, with no link.
- Twitch in the search is optional: create a free app at dev.twitch.tv/console and put `TWITCH_CLIENT_ID=` and `TWITCH_CLIENT_SECRET=` in `gta6-clipper/.env`. Without it, search uses YouTube and you can still paste any Twitch link.
- Clip streamers who are fine with clipping, and watch every clip before you post it.
- YouTube ad money needs the Partner Program, and YouTube can refuse it for reposted, mass-made content. Add something of your own.

## Files

```
SKILL.md                 instructions Claude follows
references/picking.md    how the AI picks and scores moments
scripts/setup.sh         Mac setup (ffmpeg, whisper.cpp, yt-dlp, OpenCV...)
scripts/setup.ps1        Windows setup (winget + whisper.cpp)
scripts/gta6.sh          Mac / Git Bash launcher
scripts/gta6.ps1         Windows launcher
scripts/gta6clip.py      discover / prep / status / render / open
~/GTA6-Clips/<run>/      transcript, chunks, picks, clips/ (live runs in ~/GTA6-Clips/live/)
```

On Windows the clips folder is `%USERPROFILE%\GTA6-Clips`.
