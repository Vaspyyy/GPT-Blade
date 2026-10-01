# Playtest and delivery notes

## Selected experience

Build → choose a rival/arena → wind and snap → watch an autonomous match → learn from the report → change one piece → launch again. Meaningful build behavior and readable pressure take precedence over literal real-world rigid-body accuracy. Godot's native desktop runtime renders procedural pseudo-3D art; a deterministic fixed-step simulation owns combat.

## Observed play and iteration

Actual mouse/keyboard input drove title, workshop, launch, battles, reports, immediate retries, and build changes on a native Wayland window. Screenshots were inspected during play.

- A starter mirror match with a 43% launch lost by spin at 17.4 seconds. Retrying the same parts with an 83% launch won at 20.8 seconds, awarded 150 credits, and advanced the ladder.
- Changing to Silent Marathon outlasted Rook's heavy guard at 23.3 seconds after an 88% launch. The report made the endurance advantage and 18 impact damage visible.
- Changing to Crimson Hunter burst Iona's stamina build at 17.9 seconds after a 91% launch. The match showed charge/discharge, 24 contacts, 97 impact damage, and the promotion to the next league.
- The first orbit implementation avoided central opponents too effectively and rarely hit them. Inward sweeps now create purposeful attack windows; the final curated matrix records 18.9 mean flanker contacts instead of five.
- Ring-outs were initially almost absent. Contact pressure, mass, control, wall height, remaining spin, and tilt now determine rim failure. Unforced orbiting rebounds instead of causing cheap self-eliminations.
- The presentation initially reused one guardian for every spirit. Six distinct spirit shapes, active guard/vortex visuals, aim telegraphs, animated arena hazards, a countdown, burst fragments, and ring-out travel improve anticipation and readability.
- UI checks found a SPACE press could activate a focused PAUSE button while also changing battle speed. Gameplay key edges now take precedence over GUI acceptance, and the regression is covered through actual viewport event routing.
- Launch precision now explicitly strengthens the initial burst lock, matching the launch guide. Reports use the real damage diagnostic and the actual rematched rival's identity.
- The exported build exposed a workshop shortcut transition bug: its viewport was accessed after the screen had been removed. Keyboard events are now consumed before screen changes; Enter and P are covered through real viewport routing.

These observations demonstrate the repeatable loop and useful decisions. Automated victories alone are not a claim that every matchup is equally enjoyable.

## Correctness and progression

- Curated simulation suite: 240 complete matches, deterministic replay, equal 30/60/120 Hz outcomes, finite states, telegraphed abilities, guard mitigation, tilt, ring resistance, launch lock, and Phoenix interruption. Final mean 16.97 seconds: 61 burst, 20 ring-out, 159 spin.
- Career suite: part ownership, costs, tier gates, loss/practice isolation, saved custom builds, sanitized input, backup recovery, champion/endgame, and settings persistence.
- Honest career run: 74 simulated matches including calibration, actual unlocks and purchases, achievable 86% launch, two adaptation decisions, two penalty-free defeats, all 12 rivals, ending, and champion resume. Winning battle time 232.3 seconds. It did not grant arbitrary parts or skip progression.
- Actual-scene runtime suite: 78 checks across title/help/options/workshop tabs, comparisons, presets, launch controls, focused-button input, safe Enter/P shortcuts, pause/resume, speed, complete matches, reports, rematches, confirmed reset, preserved settings, and save isolation. No engine script errors.
- Final combinatorial stress run: 1,024 varied matches + 72 upgraded legend rematches after the launch-lock correction; every part and spirit used, no nonfinite live state, longest 50.44 seconds, mean 18.82 seconds. All six spirits appeared in wins, losses, and matches with a comeback. None guaranteed a hit or victory.
- Original audio: 12 stereo PCM assets, peaks below 0.713, no clipped samples; loops, cues, mute, crossfades, and clean shutdown exercised with Godot's Dummy audio backend.

Commands and detailed data are in [BALANCE.md](BALANCE.md) and the executable test scripts.

## Platform evidence

Development host: Debian 13.6 x86_64, Godot 4.6.3, Mesa 25.0.7 llvmpipe. Native Wayland window rendering and real keyboard/pointer events were exercised on headless Sway. Resizing at 1280×800 and 1920×1080, F11 fullscreen/windowed transitions, and readable workshop layout were inspected. Native X11 fallback rendered and accepted mouse input on Xvfb. A synthetic compositor's missing FIFO/icon/decor protocols produced expected capability warnings, without script errors.

The exported native Linux ELF was played directly on both Sway and **KWin 6.3.6**, KDE's actual Wayland compositor, nested on the test display. KWin rendered the game icon and server-side decorations, accepted physical keyboard/pointer events, toggled F11 fullscreen, and completed the workshop → launch → match → result flow. A 92% launch defeated Rook by spin at 20.4 seconds, showing 34 contacts, one spirit attack, 41 impact damage, and a 180-credit career reward. This exercises the KDE compositor; a full Plasma shell/session was not installed.

The corrected export also passed Enter → career launch and P → practice launch on Sway. A practice match with a 94% launch defeated Rook at 20.3 seconds; credits and rung stayed unchanged. SPACE changed speed and ESC paused/resumed. Earlier in the exported build's career testing, a 74% launch won a ring-out at 8.5 seconds, with visible Nova attacks and a valid 150-credit progression reward. Persisted progress was checked separately. The package contains an embedded-data ELF and Wayland-aware launcher, with no engine installation needed.

The final regenerated executable was played once more on KWin. Restart restored 510 credits, two wins, and Iona as the next rival. A 99% launch still lost to her stamina at 23.2 seconds, and the practice report correctly described unchanged progress and suggested a build change. This confirms that launch skill helps without replacing counter-build decisions. The exact tested executable's SHA256 is `48549e9de16b5ec2b120bc1b1fe10653ec61c55f5157ba25e4118d357f1c767b`.

Rendered FPS counters were requested but were not emitted by this release runtime; no rendered FPS number is claimed. The headless simulation benchmark in BALANCE.md measures a different capability.

The final runtime suite covers the screen-transition fix and career reset. No physical graphics card, physical speaker output, touch/gamepad support, full Plasma shell integration, or HiDPI scaling matrix has been claimed from these tests.

## Remaining limits and next improvements

Single-player mouse/keyboard career. No multiplayer, gamepad navigation, voice acting, or physical top model import. Angle fine-tunes entry and has a smaller effect than timing/tilt because autonomous steering recovers after entry. Very defensive pairings can be quieter and longer than attack pairings. The stress maximum was 50.44 seconds; every match is capped by simulation rules.

The next useful improvements are independent human playtests of late-career balance, more composed spirit illustrations, and testing across real KDE Plasma HiDPI/multi-monitor/GPU/audio configurations. The shipped content is complete for the intended career loop; these are further refinements.
