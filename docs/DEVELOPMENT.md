# Continuity notes

Working checkout: `/workspace/GPT-Blade`, branch `work` pushed to GitHub `main`. Work directly here; cloud tasks are already isolated, so do not create worktrees without a user request. Read UPDATES.md, PLAYTESTS.md and BALANCE.md before expanding the game.

Godot 4.6.3 compatibility renderer is the sole runtime. `main.gd` owns title/help/options, two-stage launch, battle HUD/pause, and reports; Workshop/Career own construction and persistent progression; Catalog is immutable content; BattleSim is pure deterministic 120 Hz gameplay; ArenaView/TopView/RivalPortrait draw original vector art; Sound supplies pooled cues and crossfading original scores. Keep simulation independent of frame pacing and presentation.

The strong decisions are distinct driver pathing, six telegraphed opportunities with failure/counterplay, short readable matches, forgiving losses, saved builds, and unlocks that offer specializations. The stats should never turn later parts into unconditional upgrades. Angle is fine tuning, while precision and tilt have clearer consequences. The current campaign has a real ending and upgraded rematch loop.

Cloud writable data paths are under `/workspace/tooling`. Set XDG cache/config/data before running Godot; the default home directory is read-only. Verified Linux export templates are retained in `/workspace/tooling/godot-data/godot/export_templates/4.6.3.stable`. `tools/package_linux.sh` handles them automatically on this machine. Do not commit build/, .godot/, local user saves, or sysroot tools.

The development-only compositor/input harness is described in PLATFORM-TESTING.md. Live Sway/KWin/pointer processes do not survive snapshots; restart only when actual native-window testing is needed. Use isolated data directories for playtests that modify progress. Never overwrite a player's career to set up screenshots.

Useful next improvements after 1.0: independent human testing of final leagues; composed spirit artwork/stronger attack cinematography; real Plasma HiDPI, multi-monitor, hardware GPU and audio checks; optional gamepad support. Avoid replacing the complete native desktop loop with a browser project. Any future balance change should rerun the affected campaign path and explain observed play consequences.
