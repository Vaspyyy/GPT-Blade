# Simulation playtest notes

## What was run

Godot 4.6.3 headless executes the same `BattleSim` used by the native game. `tests/test_sim.gd` runs 240 complete matches: six deliberately different archetypes, every pair, four deterministic footwork phases, and four arenas. Player quality is 0.80; rival quality is 0.78. These are mechanical tests, not evidence that the presentation is fun.

The same test checks exact replay equality and identical outcomes/history at 30/60/120 frame updates, finite match bounds and meters, catalog completeness, every spirit's anticipation and activation, guard damage mitigation, tilt tradeoffs, mass-dependent ring-out resistance, and interruptible Phoenix recovery.

Run from the repository:

```sh
mkdir -p /tmp/spin-tests/{data,config,cache}
XDG_DATA_HOME=/tmp/spin-tests/data XDG_CONFIG_HOME=/tmp/spin-tests/config XDG_CACHE_HOME=/tmp/spin-tests/cache godot --headless --path . --script tests/test_sim.gd
```

## Observed final matrix

Average battle length **16.92 seconds**. Finishes: **62 burst / 20 ring-out / 158 spin**. Strong launch quality 0.96 won 10/12 default mirror matches; quality 0.25 won 1/12. Footwork phase does not roll damage, critical hits, or a winner.

| Build | Loadout | Wins / 80 | Mean distance | Mean contacts | Mean spirits |
|---|---|---:|---:|---:|---:|
| Balanced | Comet / Halo / Rush / Nova | 34 | 8.8 | 23.2 | 1.3 |
| Attacker | Fang / Reactor / Surge / Thunder | 53 | 6.8 | 26.4 | 1.1 |
| Guard | Bastion / Keel / Counter / Aegis | 30 | 5.5 | 29.2 | 1.0 |
| Survivor | Lotus / Gyre / Needle / Phoenix | 54 | 4.1 | 19.7 | 0.7 |
| Flanker | Talon / Feather / Orbit / Eclipse | 42 | 15.2 | 18.9 | 1.4 |
| Control | Meteor / Anvil / Rebound / Vortex | 27 | 9.3 | 13.6 | 1.1 |

These builds mix unlock tiers and deliberately amplify strengths and weaknesses. The goal is counterplay, not equal performance against every opponent. The survivor and attack examples win frequently, but have clear opponents that defeat them:

- Heavy control defeats the attacker 16/16; the attacker defeats survivor 16/16.
- Survivor defeats guard and heavy control 16/16.
- Guard defeats heavy control 16/16 and flanker 11/16.
- Balanced defeats guard 16/16 but loses most matches against flanker.
- Flanker defeats heavy control 15/16 but loses most matches against survivor.

## Iterations driven by results

Initial orbit drivers rarely touched central opponents, producing five contacts and only 20% wins for the light flanker. Explicit inward sweeps now produce 18.9 contacts and 52.5% wins. Their longer paths, lighter mass, and weak lock remain costs.

Initial rim rules almost never produced ring-outs (one in 240). Rim recovery now depends on recent contact pressure, outward momentum, wall height, mass, control, remaining spin, and tilt. Unforced orbital motion rebounds. This produced 20 ring-outs in the final matrix without replacing other finish types.

Initial hunters stuck together near center. Short recovery arcs now separate clashes so they have approaches and returns. High-stamina tops must survive real lock pressure rather than simply wait for the attack driver's spin to expire.

Tilt follows the launch UI: zero conserves spin and keeps orbital radius tighter; one increases contact force, widens orbit, consumes spin, and reduces rim stability. The default 0.35 is a moderate compromise. Launch angle is radians; zero points from the player's left-hand launch position toward the rival.

## Next useful checks

Watch actual matches with effects and sound: ensure the first spirit charge is legible, a clash's displayed impact matches force, and an orbit top's inward sweep reads as intentional. The career test separately checks unlock economy and achievable launch quality. Arena heat/pulse events need clear renderer telegraphs. Ring-outs should remain uncommon enough to feel dramatic, and short decisive losses should still communicate the counter-build worth trying.
