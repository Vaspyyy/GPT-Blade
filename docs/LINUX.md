# SPIN//ASCEND on Linux

Download the Linux x86_64 archive from the GitHub release and extract it. No Godot installation, browser, Wine, or Proton is needed.

```sh
tar -xzf spin-ascend-1.0.0-linux-x86_64.tar.gz
cd spin-ascend-1.0.0-linux-x86_64
./play.sh
```

For the ZIP archive, extract it and run `chmod +x play.sh spin-ascend.x86_64` if your archive tool did not preserve executable permissions.

The launcher selects native Wayland when a Wayland session is detected, including KDE Plasma Wayland. To select explicitly, run `./play.sh --wayland`. An optional `./play.sh --x11` starts the native X11 backend for troubleshooting; that needs an X server or XWayland. If launch fails, run it from a terminal to see the graphics or display error.

## Requirements

- x86_64 Linux with glibc 2.28 or newer; current Debian, Ubuntu, Fedora, Arch, and openSUSE satisfy this baseline.
- A working Wayland desktop and OpenGL 3.3 / OpenGL ES 3.0 graphics driver. The game uses Godot's compatibility renderer. Mesa software rendering is usable for diagnostic tests.
- Normal desktop runtime libraries, including libwayland-client, libxkbcommon, libEGL/libGL, libc, and libstdc++. PulseAudio/PipeWire or ALSA provides sound.
- A mouse and keyboard; 1280×800 or larger is recommended. The window can be resized.

The native executable contains the game data. It does not download anything or require a network connection during play.

## Controls and save files

Use the mouse to browse and equip parts, select rivals, and set the launch. Follow the on-screen launch instructions. The battle runs autonomously after launch. Space advances launch timing, Escape opens pause/navigation, and the on-screen buttons provide the same actions. See the game README for the complete control list.

Your career is stored in Godot's user-data folder, normally `~/.local/share/godot/app_userdata/SPIN--ASCEND/`. The in-game reset action resets career progress; ordinary losses do not destroy parts.

## Building from source

Install the official Godot 4.6.3 editor and its matching 4.6.3 export templates. Then, from the repository root:

```sh
GODOT=/path/to/Godot_v4.6.3-stable_linux.x86_64 tools/package_linux.sh
```

`GODOT_DATA_HOME` can point to an alternate XDG data directory containing `godot/export_templates/4.6.3.stable`. The packaging script imports assets, exports a native release executable with its pack embedded, includes license notices and a Wayland-aware launcher, and creates TAR.GZ, ZIP, and SHA256SUMS in `build/`.

Run `tools/platform_check.sh /path/to/spin-ascend.x86_64 --smoke` for host diagnostics and a real window startup test. This checks startup; interactive launch and match testing remains separate.

## Verification scope

The release verification notes in `docs/PLAYTESTS.md` distinguish observed Linux/Wayland results from platform assumptions. The development cloud has no KDE Plasma installation or physical GPU. Native Wayland can be verified on a headless Sway compositor, including rendered screenshots and keyboard/mouse input. This does not establish that KDE-specific scaling, window decorations, or every graphics driver has been tested.
