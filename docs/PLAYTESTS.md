# Playtest and delivery notes

## Selected experience

Build → choose a rival/arena → wind and snap → watch an autonomous match → learn from the report → change one piece → launch again. Meaningful build behavior and readable pressure take precedence over literal real-world rigid-body accuracy. Godot's native desktop runtime renders procedural pseudo-3D art; a deterministic fixed-step simulation owns combat.

## Observed play and iteration

Actual mouse/keyboard input drove title, workshop, launch, battles, reports, immediate retries, and build changes on a native Wayland window. Screenshots were inspected during play.

- A starter mirror match with a43% launch lost by spin at17.4s. Retrying the same parts with83% launch won at20.8s, awarded150credits, and advanced the ladder.
- Changing to Silent Marathon outlasted Rook's heavy guard at23.3s after an88% launch. The report made the endurance advantage and18impact damage visible.
- Changing to Crimson Hunter burst Iona's stamina build at17.9s after a91% launch. The match showed charge/discharge,24contacts,97impact damage, and the promotion to the next league.
- The first orbit implementation avoided central opponents too effectively and rarely hit them. Inward sweeps now create purposeful attack windows; the final curated matrix records18.9mean flanker contacts instead of five.
- Ring-outs were initially almost absent. Contact pressure, mass, control, wall height, remaining spin, and tilt now determine rim failure. Unforced orbiting rebounds instead of causing cheap self-eliminations.
- The presentation initially reused one guardian for every spirit. Six distinct spirit shapes, active guard/vortex visuals, aim telegraphs, animated arena hazards, a countdown, burst fragments, and ring-out travel improve anticipation and readability.
- UI checks found a SPACE press could activate a focused PAUSE button while also changing battle speed. Gameplay key edges now take precedence over GUI acceptance, and the regression is covered through actual viewport event routing.
- Launch precision now explicitly strengthens the initial burst lock, matching the launch guide. Reports use the real damage diagnostic and the actual rematched rival's identity.

These observations demonstrate the repeatable loop and useful decisions. Automated victories alone are not a claim that every matchup is equally enjoyable.

## Correctness and progression

- Curated simulation suite:240complete matches, deterministic replay, equal30/60/120Hz outcomes, finite states, telegraphed abilities, guard mitigation, tilt, ring resistance, launch lock, and Phoenix interruption. Final mean16.97s:61burst,20ring-out,159spin.
- Career suite: part ownership, costs, tier gates, loss/practice isolation, saved custom builds, sanitized input, backup recovery, champion/endgame, and settings persistence.
- Honest career run:74simulated matches including calibration, actual unlocks and purchases, achievable86%launch, two adaptation decisions, two penalty-free defeats, all12rivals, ending, and champion resume. Winning battle time232.3s. It did not grant arbitrary parts or skip progression.
- Actual-scene runtime suite:64checks across title/help/options/workshop tabs, comparisons, presets, launch controls, focused-button input, pause/resume, speed, complete matches, results, rematches, and save isolation. No engine script errors.
- Combinatorial stress snapshot:1,024varied matches +72upgraded legend rematches; every part and spirit used, no nonfinite live state, longest50.44s. This snapshot preceded the final bounded launch-lock bonus; the affected curated/campaign suites were rerun after that bonus.
- Original audio:12stereo PCM assets, peaks below0.713, no clipped samples; loops, cues, mute, crossfades, and clean shutdown exercised with Godot's Dummy audio backend.

Commands and detailed data are in [BALANCE.md](BALANCE.md) and the executable test scripts.

## Platform evidence

Development host: Debian13.6x86_64, Godot4.6.3, Mesa25.0.7llvmpipe. Native Wayland window rendering and real keyboard/pointer events were exercised on headless Sway.1280×800and1920×1080resizing, F11 fullscreen/windowed transitions, and readable workshop layout were inspected. Native X11 fallback rendered and accepted mouse input on Xvfb. A synthetic compositor's missing FIFO/icon/decor protocols produced expected capability warnings, without script errors.

The final exported executable's additional platform checks are recorded below once complete. No full KDE Plasma desktop, physical graphics card, physical speaker output, touch/gamepad support, or HiDPI scaling matrix has been claimed from these tests.

## Remaining limits and next improvements

Single-player mouse/keyboard career. No multiplayer, gamepad navigation, voice acting, or physical top model import. Angle fine-tunes entry and has a smaller effect than timing/tilt because autonomous steering recovers after entry. Very defensive pairings can be quieter and longer than attack pairings. The stress maximum was50.44s; every match is capped by simulation rules.

The next useful improvements are independent human playtests of late-career balance, more composed spirit illustrations, and testing across real KDE Plasma HiDPI/multi-monitor/GPU/audio configurations. The shipped content is complete for the intended career loop; these are further refinements.
