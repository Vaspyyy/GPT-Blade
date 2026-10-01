# Development updates

## 2026-10-01 — Concept and native foundation

SPIN//ASCEND is an original, anime-inspired spinning-top career game. Godot 4.6.3 with the compatibility renderer targets native Linux, including a Wayland session. Four interchangeable part families shape autonomous behavior; the player masters launch timing and chooses builds against a ladder of rivals.

Implementation is split into deterministic simulation, career/workshop, original synthesized audio, and arena presentation. The existing empty checkout is used directly. Playtest evidence and remaining limitations will be recorded here as builds mature.

## 2026-10-01 — Complete playable career loop

The workshop now supports 36 interchangeable parts, whole-build comparisons, three starter archetypes, persistent custom build slots, four arena practice choices, and a twelve-rival career with league unlocks. Six automatic spirit attacks telegraph before resolving. A two-stage ripcord launch combines power and precision; angle and tilt create tactical tradeoffs. Original stereo scores and ten sound cues accompany native procedural art.

First actual native Wayland playtest: the starter mirror match lost after a 43% launch, then won after an 83% launch with the same parts. The loss led directly to a useful retry and victory awarded150CR/advanced the ladder. Window/fullscreen and1280×800/1920×1080 display tests passed on the available Sway compositor; X11 fallback also rendered and accepted mouse input. KDE Plasma itself is not installed in this machine.

Initial balance weakness was underpowered flankers and almost no ring-outs. Mobility/impact tuning produced distinct counters:240 sampled matches averaged16.92s, with62burst/20ring/158spin finishes. Runtime integration exercises63 assertions through workshop, launch, pause, match, reports, and rematch. Presentation iteration adds a countdown, distinct spirit shapes, persistent guard/vortex visuals, and animated heat/pulse warning rings. Remaining work: stress/campaign validation, native release export, presentation review, and final polish.

## 2026-10-01 — Career playtesting and final game polish

An honest 74-match campaign run reached champion using real ownership, tier gates and credits at 86% launch quality, with two build adaptations and two penalty-free defeats. Final simulation tuning averages 16.97 seconds across the curated 240 matches. A broader stability snapshot covered 1,024 varied builds and 72 stronger legend rematches; every state stayed finite and every matchup terminated.

Actual native play confirmed two different counter-builds: Silent Marathon outlasted Rook at 23.3 seconds; Crimson Hunter burst Iona at 17.9 seconds and earned promotion. Reports now show actual impact damage and identify the rival used in a practice rematch. Defeated rivals can be selected again from Career; the Lab keeps three custom creations.

Polish adds twelve original rival portraits, individually sculpted blade silhouettes and spirit emblems, a launch countdown, active shield/vortex effects, distinct spirit manifestations, visible heat/pulse warnings, burst fragments, and ring-out travel. Launch precision now also protects the initial burst lock. A keyboard-focus regression was fixed: SPACE cannot also click a focused PAUSE button. The actual-scene suite now passes 64 checks. Career reset uses an explicit in-game confirmation and preserves options. Native release export has succeeded; final artifact display checks and publication remain.

## 2026-10-01 — Release candidate verified on native Wayland and KDE's compositor

The exported Linux executable completed real workshop, keyboard launch, countdown, battle, result, and progression flows on Sway and KWin 6.3.6. KWin also rendered the icon/decorations and accepted fullscreen controls. Its actual career match defeated Rook at 20.4 seconds after a 92% launch and awarded 180 credits. Sway additionally verified practice isolation and an 8.5-second ring-out finish. This tests KDE's compositor, while a full Plasma shell, physical GPU/audio hardware and HiDPI remain unverified.

Release testing exposed an Enter/P transition bug: Workshop accessed its viewport after removing itself during a match signal. Events are now consumed before changing screens, and real exported keyboard flows pass. The development harness now uses a persistent fixed-layout keyboard, avoiding a separate ad hoc keymap issue in nested compositors. The scene suite expanded to 78 passing checks, including safe reset/preserved settings. A final 1,096-match stress rerun passes after all gameplay changes, with no invalid state and a 50.44-second maximum. Practice reports now clearly describe unchanged progression.

Reusable installation/start instructions are saved in the cloud environment draft. The Linux package includes standalone executable, Wayland launcher, instructions, playtest/balance notes, and license notices. Final source/artifacts and exact checksums are being published as v1.0.0.
