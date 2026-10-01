The exact tested SPIN//ASCEND 1.0.0 native Linux x86_64 build is in this directory.

GitHub's release asset endpoint rejected uploads, so this archive is distributed through the release's Git tag. Download the TAR.GZ using the v1.0.0 release link, then:

```sh
tar -xzf spin-ascend-1.0.0-linux-x86_64.tar.gz
cd spin-ascend-1.0.0-linux-x86_64
./play.sh
```

No Godot installation is needed. `SHA256SUMS` verifies the archive. The bundled README, license notices, and playtest notes describe controls, requirements, and actual native Wayland verification.
