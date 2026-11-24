# AMX Mod X Round Win Sounds

[![Build](https://github.com/PixelSam123/amxmodx-round-win-sounds/actions/workflows/build.yml/badge.svg)](https://github.com/PixelSam123/amxmodx-round-win-sounds/actions/workflows/build.yml)

Play custom sounds after winning a round in a Counter-Strike 1.6 server.
Each player picks a sound from an in-game menu, and the sound for the winning
team is chosen from the last player to get a kill that round.

## Features

- Per-player sound selection through `.winsound` / `.ws`.
- The last killer on the winning team decides the sound.
- If the round ends without a kill, the first player on the winning team with
  a non-`None` choice is used.
- Configured with two arrays in the source; recompile after changing them.
- Linux and Windows CI builds; tagged releases attach the compiled `.amxx`.

## How the sound is chosen

1. Every `DeathMsg` records the last killer for T and CT.
2. When `SendAudio` reports `terwin` or `ctwin`, the plugin looks up the last
   killer for that team.
3. If that player is still connected, still on the winning team, and has a
   non-`None` choice, their sound plays.
4. Otherwise, the first connected player on the winning team with a non-`None`
   choice is used.
5. If nobody on the winning team has a choice, nothing plays.

The choice is stored per player in memory and resets when they reconnect.

## Requirements

- AMX Mod X 1.10+ (tested with 1.10.0.5481)
- Counter-Strike 1.6

## Installation

1. Download `roundwinsounds.amxx` and the source zip from the
   [latest release](https://github.com/PixelSam123/amxmodx-round-win-sounds/releases/latest).
2. Copy the plugin:

   ```
   roundwinsounds.amxx -> cstrike/addons/amxmodx/plugins/roundwinsounds.amxx
   ```

3. Copy the sounds:

   ```
   sound/customroundwin/*.wav -> cstrike/sound/customroundwin/
   ```

4. Add the plugin to `cstrike/addons/amxmodx/configs/plugins.ini`:

   ```
   roundwinsounds.amxx
   ```

5. Restart the server or `changelevel` to a map, then verify:

   ```
   amxx plugins
   ```

   `Round Win Sounds` should be listed as running.

The `.amxx` is platform-independent; the Linux and Windows CI jobs are a
compiler sanity check.

### Folder layout

```
addons/
  amxmodx/
    scripting/
      roundwinsounds.sma
sound/
  customroundwin/
    sound1.wav
    sound2.wav
    sound3.wav
```

## Player commands

Players choose a sound in chat with either:

- `.winsound`
- `.ws` (short alias)

Both `say` and `say_team` are supported. The commands are case-sensitive.
Typing one opens:

```
Select Round Win Sound:
1. None [Selected]
2. Candyland
3. Sorry
4. Who is Donk?
```

The labels are examples; edit `g_SoundDisplayNames` to change them.

## Sound variations

Sounds live in `cstrike/sound/customroundwin/`. The plugin precaches every
entry in `g_SoundFiles` (except index 0, `None`) during `plugin_precache()`.

```pawn
#define NUM_VARIATIONS 4

new const g_SoundFiles[NUM_VARIATIONS][] =
{
    "",
    "sound1.wav",
    "sound2.wav",
    "sound3.wav"
};

new const g_SoundDisplayNames[NUM_VARIATIONS][] =
{
    "None",
    "Candyland",
    "Sorry",
    "Who is Donk?"
};
```

- Index 0 must stay `None` / `""`.
- `NUM_VARIATIONS` must match the array size.
- Keep filenames short: `MAX_SOUND_PATH` is 64 characters including
  `customroundwin/`.

### Replacing the placeholders

The bundled `.wav` files are valid **silent** placeholders so the plugin
works out of the box. They are not the songs implied by the example labels.
Replace them with audio you have the rights to distribute.

Recommended format: 16-bit PCM WAV, mono, 22050 Hz. The engine only accepts
`.wav` files under `sound/`; paths are relative to `cstrike/sound/`.

Do not commit copyrighted audio to this repository.

### Regenerating the silent placeholders

A 0.25-second silent file can be generated with Python's standard library:

```python
import wave

with wave.open("sound1.wav", "wb") as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(22050)
    wav.writeframes(b"\x00\x00" * 5512)
```

## Building

### CI

Push to `main` or open a pull request. The `Build AMXX Plugin` workflow
downloads AMX Mod X 1.10.0.5481, verifies its SHA256 checksum, and compiles the
plugin on Linux and Windows. Artifacts are available from the workflow run.

Tagged builds (`v*`) also publish a GitHub release with the compiled plugin,
a source archive, and `SHA256SUMS`.

### Local

With an AMX Mod X 1.10 installation:

Linux:

```bash
mkdir -p addons/amxmodx/scripting/compiled
LD_LIBRARY_PATH="<amxmodx>/addons/amxmodx/scripting:$LD_LIBRARY_PATH" \
  <amxmodx>/addons/amxmodx/scripting/amxxpc \
  addons/amxmodx/scripting/roundwinsounds.sma \
  -oaddons/amxmodx/scripting/compiled/roundwinsounds.amxx \
  -i<amxmodx>/addons/amxmodx/scripting/include
```

Windows:

```powershell
New-Item -ItemType Directory -Force addons/amxmodx/scripting/compiled | Out-Null
& "<amxmodx>\addons\amxmodx\scripting\amxxpc.exe" `
  "addons\amxmodx\scripting\roundwinsounds.sma" `
  "-oaddons\amxmodx\scripting\compiled\roundwinsounds.amxx" `
  "-i<amxmodx>\addons\amxmodx\scripting\include"
```

Or use AMXX Studio / the VS Code Pawn extension with the AMX Mod X includes.

## Troubleshooting

- **No sound plays** - check that the `.wav` files exist under
  `cstrike/sound/customroundwin/`, that the names match exactly (Linux paths
  are case-sensitive), and that the server console has no precache errors.
- **The menu does not open** - the chat commands are case-sensitive; use
  `.winsound` or `.ws` with `say` or `say_team`.
- **Selection resets** - choices are intentionally in-memory and reset on
  reconnect.
- **Wrong sound plays** - the last killer on the winning team wins; if they
  selected `None`, the first eligible teammate is used.
- **No sound on a kill-less round** - the fallback needs at least one player
  on the winning team with a non-`None` choice.

## License

Licensed under the [GNU General Public License v3.0 or later](LICENSE)
(`GPL-3.0-or-later`).

This plugin is a derivative work of
[AMX Mod X](https://github.com/alliedmodders/amxmodx) and relies on AMX Mod X's
plugin exception, which permits derivative works such as Pawn plugins to be
licensed under GPL-2.0-or-later or GPL-3.0-or-later. No AMX Mod X source files
are redistributed.

The bundled silent WAV placeholders are dedicated to the public domain under
CC0-1.0; see [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).

## Disclaimer

Counter-Strike, Steam, and Valve are trademarks of Valve Corporation. This
project is not affiliated with or endorsed by Valve, AMX Mod X, or any server
community.
