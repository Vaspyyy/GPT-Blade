# Native Linux display verification

The game targets Linux desktop directly. The cloud test host is Debian 13.6 x86_64 with Mesa 25.0.7 llvmpipe software rendering. It has no KDE Plasma session or physical GPU. Verification uses the real Godot executable and compositor framebuffer, rather than headless rendering alone.

## Reproduce the cloud display harness

These are development tools, not runtime dependencies shipped to players. On this Debian cloud, `tools/prepare_platform_test.sh` downloads packages through apt, preserving archive signatures and package hashes, and extracts them into `/workspace/tooling/sysroot`. It does not require system package installation. The virtual-pointer protocol source is pinned to a wlr-protocols commit.

```sh
tools/prepare_platform_test.sh
tools/platform_headless.sh start
tools/platform_headless.sh run godot --path . --display-driver wayland \
  --rendering-method gl_compatibility --resolution 1440x900 --audio-driver Dummy
```

From another terminal, actual native input and screenshots:

```sh
tools/platform_headless.sh capture /tmp/spin-title.png
tools/platform_headless.sh click 212 652
tools/platform_headless.sh hold space 1450
tools/platform_headless.sh key space
tools/platform_headless.sh key Escape
tools/platform_headless.sh key F11
tools/platform_headless.sh resize 1280x800
```

The helper uses a persistent Wayland virtual pointer and keyboard with a fixed US keymap. Merely sending Sway cursor commands can report success without delivering mouse events when no physical pointer is attached. The fixed keyboard sends real evdev codes (Enter 28, Space 57, Escape 1, F11 87). Tools that construct a new keymap per command can remap every requested key to physical code 1; nested KWin may then receive Escape. A single `hold` keeps the same keyboard connected throughout a power charge.

The harness supplies writable XDG data and cache directories under `/workspace/tooling`; career files from these tests do not belong to the shipped game. Compositor logs are `/workspace/tooling/logs/sway.log`. Native Wayland is forced explicitly, and XWayland is disabled in the Sway harness.

For a real KDE compositor check, `PLATFORM_TEST_KWIN=1 tools/prepare_platform_test.sh` also extracts signed KWin 6.3.6 packages. Start KWin nested on Sway with its own D-Bus session, local Qt plugin/data paths, and `--wayland-display wayland-1 --socket spin-kwin --no-lockscreen --no-global-shortcuts --no-kactivities`. Launch the game with `WAYLAND_DISPLAY=spin-kwin` and `--display-driver wayland`; outer Sway screenshot/input tools pass through KWin. This verifies the actual KWin Wayland window manager, decorations, focus, and rendering; it does not start the full Plasma shell.

Native X11 fallback can be tested independently with `/workspace/tooling/sysroot/usr/bin/Xvfb :99 -screen 0 1440x900x24 -ac -noreset -nolisten tcp`, then `DISPLAY=:99` and `--display-driver x11`. ImageMagick `import -window root` captures its framebuffer, and xdotool sends real input. Xvfb has no window manager; keyboard focus must be set explicitly if needed.

## Observed development checks, 2026-10-01

- Native Wayland window rendered with Mesa OpenGL 4.5, compatibility renderer. Title, workshop, launch, match, and result screenshots were captured from Sway and viewed.
- Actual mouse and Space input traversed the complete career loop. A 43% launch lost the mirror match by spin finish after 17.4 seconds. Retrying the same build with an 83% launch won after 20.8 seconds and awarded 150 credits. The next rival and saved career appeared on restart.
- In-match NOVA BREAK spirit attack displayed its actor/name and radial effects. The spin/lock/spirit HUD remained readable.
- 1280×800 title and workshop stayed within the window. A 1920×1080 fullscreen workshop stayed within the window; F11 toggled to windowed and back. The compositor output was restored to 1440×900 afterward.
- Actual native X11 fallback rendered the game in Xvfb, and mouse navigation opened the workshop.
- No script or runtime errors occurred in these loops. Sway reported missing optional icon/FIFO/decor protocols; Xvfb reported unsupported VSync. These are limitations of the test display setup.

## Observed exported Linux build

The official 4.6.3 release template produced an x86_64 ELF with the game pack embedded. Native Wayland release playtests on Sway traversed title, workshop, launch, countdown, spirit attack, pause/resume, speed control, match report, and persisted career restart. Enter and P shortcuts were retested after fixing a real scene-transition input error.

The actual KWin 6.3.6 compositor also completed the real-input career loop: a 92% launch defeated Rook Iron by spin finish at 20.4 seconds, awarding 180 credits. Restart loaded 510 credits, two wins, and Iona Wisp as the next rival. Fullscreen, mouse focus, keyboard navigation, window icon, and server-side decorations were observed.

The final exported executable SHA256 is `48549e9de16b5ec2b120bc1b1fe10653ec61c55f5157ba25e4118d357f1c767b`. This exact file completed another KWin practice match: a 99% launch lost to Iona's stamina at 23.2 seconds; the report offered concrete build advice and displayed “PRACTICE COMPLETE / IDEA TESTED.” Credits, career record, and ladder stayed unchanged. Closing through the title's Quit button exited normally. No script or runtime errors occurred. `--print-fps` did not emit counters from this release template, so no measured frame-rate claim is made.

These observations do not establish KDE-specific fractional scaling, a full Plasma shell session, hardware GPU-driver compatibility, or real-device audio latency. Game balance, full-career reachability, and gameplay findings are covered by the project's playtest notes and simulation diagnostics.
