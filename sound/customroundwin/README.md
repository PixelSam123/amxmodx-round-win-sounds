# Round win sound placeholders

The three `.wav` files in this directory are valid 0.25-second silent
placeholders (22050 Hz, mono, 16-bit PCM). They let the plugin precache and
run out of the box.

Replace them with audio you have the rights to distribute. Recommended format:
16-bit PCM WAV, mono, 22050 Hz. Keep the filenames in sync with
`g_SoundFiles` in `addons/amxmodx/scripting/roundwinsounds.sma`, or edit the
array and recompile.

Do not commit copyrighted audio to this repository.

To regenerate a silent placeholder with Python:

```python
import wave

with wave.open("sound1.wav", "wb") as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(22050)
    wav.writeframes(b"\x00\x00" * 5512)
```
