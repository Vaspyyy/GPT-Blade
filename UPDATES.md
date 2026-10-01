# Development updates

## 2026-10-01 — Concept and native foundation

SPIN//ASCEND is an original, anime-inspired spinning-top career game. Godot 4.6.3 with the compatibility renderer targets native Linux, including a Wayland session. Four interchangeable part families shape autonomous behavior; the player masters launch timing and chooses builds against a ladder of rivals.

Implementation is split into deterministic simulation, career/workshop, original synthesized audio, and arena presentation. The existing empty checkout is used directly. Playtest evidence and remaining limitations will be recorded here as builds mature.

## 2026-10-01 — Complete playable career loop

The workshop now supports 36 interchangeable parts, whole-build comparisons, three starter archetypes, persistent custom build slots, four arena practice choices, and a twelve-rival career with league unlocks. Six automatic spirit attacks telegraph before resolving. A two-stage ripcord launch combines power and precision; angle and tilt create tactical tradeoffs. Original stereo scores and ten sound cues accompany native procedural art.

First actual native Wayland playtest: the starter mirror match lost after a 43% launch, then won after an 83% launch with the same parts. The loss led directly to a useful retry and victory awarded150CR/advanced the ladder. Window/fullscreen and1280×800/1920×1080 display tests passed on the available Sway compositor; X11 fallback also rendered and accepted mouse input. KDE Plasma itself is not installed in this machine.

Initial balance weakness was underpowered flankers and almost no ring-outs. Mobility/impact tuning produced distinct counters:240 sampled matches averaged16.92s, with62burst/20ring/158spin finishes. Runtime integration exercises63 assertions through workshop, launch, pause, match, reports, and rematch. Presentation iteration adds a countdown, distinct spirit shapes, persistent guard/vortex visuals, and animated heat/pulse warning rings. Remaining work: stress/campaign validation, native release export, presentation review, and final polish.
