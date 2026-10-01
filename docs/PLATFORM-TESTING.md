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

The mouse helper uses a persistent Wayland virtual pointer. Merely sending Sway cursor commands can report success without delivering mouse events when no physical pointer is attached. Keyboard input includes a short settling interval so Godot observes the newly-created virtual keyboard. A single `hold` keeps the same virtual keyboard connected throughout a power charge.

The harness supplies writable XDG data and cache directories under `/workspace/tooling`; career files from these tests do not belong to the shipped game. Compositor logs are `/workspace/tooling/logs/sway.log`. Native Wayland is forced explicitly, and no XWayland binary is installed in the compositor environment, so its game window cannot silently use X11.

Native X11 fallback can be tested independently with `/workspace/tooling/sysroot/usr/bin/Xvfb :99 -screen 0 1440x900x24 -ac -noreset -nolisten tcp`, then `DISPLAY=:99` and `--display-driver x11`. ImageMagick `import -window root` captures its framebuffer, and xdotool sends real input. Xvfb has no window manager; keyboard focus must be set explicitly if needed.

## Observed development checks, 2026-10-01

- Native Wayland window rendered with Mesa OpenGL 4.5, compatibility renderer. Title, workshop, launch, match, and result screenshots were captured from Sway and viewed.
- Actual mouse and Space input traversed the complete career loop. A 43% launch lost the mirror match by spin finish after 17.4 seconds. Retrying the same build with an 83% launch won after 20.8 seconds and awarded 150 credits. The next rival and saved career appeared on restart.
- In-match NOVA BREAK spirit attack displayed its actor/name and radial effects. The spin/lock/spirit HUD remained readable.
- 1280×800 title and workshop stayed within the window. A 1920×1080 fullscreen workshop stayed within the window; F11 toggled to windowed and back. The compositor output was restored to 1440×900 afterward.
- Actual native X11 fallback rendered the game in Xvfb, and mouse navigation opened the workshop.
- No script or runtime errors occurred in these loops. Sway reported missing optional icon/FIFO/decor protocols; Xvfb reported unsupported VSync. These are limitations of the test display setup.

These observations do not establish KDE-specific fractional scaling, desktop integration, GPU-driver compatibility, or real-device audio latency. Release-binary checks are recorded separately after the final export. Game balance, full-career reachability, and gameplay findings are covered by the project's playtest notes and simulation diagnostics.
