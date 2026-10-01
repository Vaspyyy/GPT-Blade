All music and cues here are original synthesized audio for SPIN//ASCEND.
No recordings, sample packs, franchise sounds, or third-party audio are used.

Regenerate with `python3 tools/generate_audio.py` from the repository. The
generator uses only Python's standard library and deterministic random seeds.
Music loops are sample-exact stereo PCM at 32 kHz: `menu.wav` is a 38.4-second,
16-bar 100 BPM arrangement; `battle.wav` is a 30-second, 16-bar 128 BPM
arrangement. Both use original minor-key chord progressions and melodic phrases,
with synthesized bass, pads, plucks, bells and percussion. Sound cues cover
click, countdown, launch, charge, telegraph, clash, ability, burst, win and lose.

The shipped WAVs peak below 0.713 full scale. Cue ends have short anti-click
fades. Music loops wrap their instrument and delay tails into the next cycle.
Godot plays these assets directly; Python is unnecessary for playing the game.

Validation: `godot --headless --audio-driver Dummy --path . --script
tools/check_audio.gd` exercises imports, looping, crossfades, all cue loads,
volume changes, mute, stop, and shutdown. This confirms playback behavior with
the native engine; it does not claim an audition through physical speakers.
