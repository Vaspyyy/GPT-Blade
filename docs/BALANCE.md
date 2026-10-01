# Simulation playtest notes

## What was run

Godot 4.6.3 headless executes the same `BattleSim` used by the native game. `tests/test_sim.gd` runs 240 complete matches: six deliberately different archetypes, every pair, four deterministic footwork phases, and four arenas. Player quality is 0.80; rival quality is 0.78. These are mechanical tests, not evidence that the presentation is fun.

The same test checks exact replay equality and identical outcomes/history at 30/60/120 frame updates, finite match bounds and meters, catalog completeness, every spirit's anticipation and activation, precise launches starting with stronger burst locks, guard damage mitigation, tilt tradeoffs, mass-dependent ring-out resistance, and interruptible Phoenix recovery.

Run from the repository:

```sh
mkdir -p /tmp/spin-tests/{data,config,cache}
XDG_DATA_HOME=/tmp/spin-tests/data XDG_CONFIG_HOME=/tmp/spin-tests/config XDG_CACHE_HOME=/tmp/spin-tests/cache godot --headless --path . --script tests/test_sim.gd
```

## Observed final matrix

Average battle length **16.97 seconds**. Finishes: **61 burst / 20 ring-out / 159 spin**. Strong launch quality 0.96 won 10/12 default mirror matches; quality 0.25 won 1/12. Footwork phase does not roll damage, critical hits, or a winner.

| Build | Loadout | Wins / 80 | Mean distance | Mean contacts | Mean spirits |
|---|---|---:|---:|---:|---:|
| Balanced | Comet / Halo / Rush / Nova | 33 | 8.8 | 23.3 | 1.3 |
| Attacker | Fang / Reactor / Surge / Thunder | 54 | 6.9 | 26.6 | 1.1 |
| Guard | Bastion / Keel / Counter / Aegis | 30 | 5.5 | 29.2 | 1.0 |
| Survivor | Lotus / Gyre / Needle / Phoenix | 55 | 4.1 | 19.7 | 0.7 |
| Flanker | Talon / Feather / Orbit / Eclipse | 41 | 15.3 | 18.9 | 1.4 |
| Control | Meteor / Anvil / Rebound / Vortex | 27 | 9.3 | 13.7 | 1.1 |

These builds mix unlock tiers and deliberately amplify strengths and weaknesses. The goal is counterplay, not equal performance against every opponent. The survivor and attack examples win frequently, but have clear opponents that defeat them:

- Heavy control defeats the attacker 16/16; the attacker defeats survivor 16/16.
- Survivor defeats guard and heavy control 16/16.
- Guard defeats heavy control 16/16 and flanker 11/16.
- Balanced defeats guard 16/16 but loses most matches against flanker.
- Flanker defeats heavy control 15/16 but loses most matches against survivor.

## Iterations driven by results

Initial orbit drivers rarely touched central opponents, producing five contacts and only 20% wins for the light flanker. Explicit inward sweeps now produce 18.9 contacts and roughly 51% wins. Their longer paths, lighter mass, and weak lock remain costs.

Initial rim rules almost never produced ring-outs (one in 240). Rim recovery now depends on recent contact pressure, outward momentum, wall height, mass, control, remaining spin, and tilt. Unforced orbital motion rebounds. This produced 20 ring-outs in the final matrix without replacing other finish types.

Initial hunters stuck together near center. Short recovery arcs now separate clashes so they have approaches and returns. High-stamina tops must survive real lock pressure rather than simply wait for the attack driver's spin to expire.

Tilt follows the launch UI: zero conserves spin and keeps orbital radius tighter; one increases contact force, widens orbit, consumes spin, and reduces rim stability. The default 0.35 is a moderate compromise. Launch angle is radians; zero points from the player's left-hand launch position toward the rival.

A final clarity pass made the help screen's burst-lock claim concrete: initial lock is `clamp(68 + burst × 0.17 + quality × 20, 0, 100)`. A precise launch starts with more lock reserve as well as more spin. Rival quality 0.78 remains nearly unchanged (+0.6 lock compared with the previous rule). The final matrix above and the campaign below were rerun after this correction.

## Final career verification

`tests/test_campaign.gd` reached champion using real credits, unlock tiers, owned parts, and achievable launch quality **0.86**. It ran **74 matches**, including independent seeds used to validate adaptations. The successful path took **232.3 seconds of winning battle time**, two build adaptations, and two defeats that removed neither money nor progress. Purchases never overdrew the wallet. The ending, champion rematch, and saved winning build survived a profile reload.

The observed path began with Comet / Halo / Rush / Nova, adapted to Comet / Anvil / Anchor / Aegis for Jax and the following circuit, and then Fang / Gyre / Counter / Aegis for the last three rivals. This is one viable route, not a claim that all builds can clear every rival.

## Next useful checks

Watch actual matches with effects and sound: ensure the first spirit charge is legible, a clash's displayed impact matches force, and an orbit top's inward sweep reads as intentional. The career test separately checks unlock economy and achievable launch quality. Arena heat/pulse events need clear renderer telegraphs. Ring-outs should remain uncommon enough to feel dramatic, and short decisive losses should still communicate the counter-build worth trying.

## Combinatorial stability and endgame checks

The extensive stress and control sweep below were recorded before the final bounded launch-lock bonus. The final correction was subsequently covered by the full matrix, targeted launch-lock assertions, and honest campaign rerun above; the earlier performance and outcome statistics remain identified as that observed snapshot.

`tests/test_stress.gd` adds coverage beyond the curated matrix: **1,024 varied legal part combinations**, all four arenas, quality/power/tilt extremes, full-circle stress angles, live meter/vector bounds, and **72 real champion rematches** using `Career.current_rival()` rebuilt loadouts. Every part appeared. All matches terminated, with no nonfinite or out-of-range live state. Median duration was **18.94 seconds**, average **18.89**, shortest **3.96**, longest **50.44**. The longest is an unusual reserve-heavy matchup; the shortest occurs among deliberately extreme launch/build combinations. Finishes were 923 spin, 116 burst, and 57 ring-out.

Every rebuilt legend had two to five winning coherent counter-builds among six candidates at achievable launch quality **0.86**. This verifies viable answers rather than equal difficulty. The separate campaign test verifies actual purchases, ownership, and unlock progression.

All six spirits activated in both victories and defeats. For each spirit, some winners had activated while more than five spin behind. This observes comebacks; it does not establish that the spirit alone caused the reversal. Phoenix was interrupted ten times naturally. Nova sometimes missed all empowered contacts, Aegis sometimes protected no contacts, and Thunder sometimes discharged out of range. Abilities create opportunities, not guaranteed hits or wins.

The 1,096 match suite executed 2,484,161 fixed ticks in 35.27 seconds on the development machine: **14.20 microseconds per tick including test assertions**, about 587 times simulated realtime. This is a headless gameplay benchmark; rendered performance and Wayland behavior require their own checks.

A focused control sweep ran 32 paired matchups with identical builds, quality, rival, arena, and seed. Opposite entry angles within the actual ±55° UI range changed one winner and produced a mean absolute duration difference of 1.21 seconds. Stable versus aggressive tilt changed eight winners and a mean 3.40 seconds. **Entry angle has a modest effect compared with tilt and timing**, because drivers recover their autonomous paths after launch. The game should present it as fine tuning rather than a mandatory precision puzzle.

Run the stress suite with the same XDG variables shown above and `--script tests/test_stress.gd`. For the focused control sweep only, append `-- --controls-only`.
