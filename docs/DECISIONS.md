# Decisions

## D-104 - Butcher Hero gates, Reaper and knight minimap icons, no fast travel in a fight

- Date: 2026-11-07. Status: implemented in v0.34.
- Source: user: knights and Reaper should have their icons on the minimap; use the gate artworks from the Butcher Hero project for the gates; while fighting an enemy fast travel shouldn't work and an appropriate message with good UI should be shown.
- Gates: the Unity export's gate meshes (unity-meadowlands/Assets/Mesh: MetalGates, FrozenGatesPuk, FrozenGatesPuk.002/.003 door leaves) were decoded with tools/decode_unity_mesh.py into game/assets/environment/butcher-props/ (metal-gate-posts, frozen-gate-posts, gate-door-a/b .obj; MainMat atlas jungle-gate-color.png via gate-artwork.mtl). scripts/world/gate_artwork.gd rebuilds them with the transforms of the Unity scene's "gates Italy1" / "gates Frozen1" objects (Unity to Godot: x mirrored): stone-and-metal posts with an arched double door for the Meadowlands gate, icy spiked posts for the Frostlands gate, scale 1.1 to fill the 14-unit gateway. The doors swing open when the boss falls; the red barrier fits the arch. Replaces the single jungle-gate post. The meadow orchard moved to (80, -117), 2 x 5 trees, so it no longer hides the gate.
- Minimap: the Reaper and both knights carry round portrait markers (tutorial portraits in a coloured ring: red Blood Knight, green Plague Knight, purple Reaper) instead of enemy dots; off the minimap they sit on the rim in their direction.
- Combat lock: main.gd in_combat() = any living enemy within 40 chasing or attacking Kaze. While true the fast travel icon is dimmed with a crossed-swords badge; tapping it does not travel, shakes the icon and shows a red-rimmed card under the HUD buttons: "Can't fast travel in a fight - Win the fight or get away from the enemy first." (about 2.6 s).
- Tests: check_regions adds the fight lock (no travel, card shown) and the three minimap portraits. tests/capture_gateway.gd and tests/capture_combat_lock.gd take screenshots. All 10 suites pass.

## D-103 - One map: regions joined by real gateways

- Date: 2026-11-07. Status: implemented in v0.33.
- Source: user: regions should be on the same map, connected to each other with actual gateways that open by killing the boss.
- Map: the Frostlands world is placed in the same scene as the Meadowlands, north of it, at offset (62, 0, -268) (Travel.OFFSETS); its ground shader mask origin has the offset baked in. Layouts gained a LINK constant: the Meadowlands' north border and the Frostlands' south border are now short bands (to 134 from each region's centre) that meet at world z -134, and a 14-unit corridor is cut through both at the Bone Warlord's gate (world x 62), with the path painted through it. Linked borders are built low (like the south/east ones) so they never hide Kaze; forest and cliff-base scatter keep the corridor clear; ground planes are clipped so they do not overlap. The orchard moved from the gate to (74, -117). scenes/frost.tscn is retired (moved to _to_delete); the frost theme only builds scenes/world/frost_world.tscn.
- Gate: the region gate's barrier blocks the corridor until the boss falls; then Kaze simply walks north into the Frostlands (no loading). The Frost Tyrant's gate to region 3 still says "Coming soon".
- Game: main.gd loads both worlds (each with its own palette), spawns both rosters and both bosses (enemy_roster returns world positions), and tracks the region Kaze is standing in (z < -134 is region 2). Crossing over fades the sky, ambient and sun to that region's light (read from its world scene; the second world's own lights are removed) and saves current_region; a game saved in the Frostlands resumes just inside its gateway. Kaze is kept inside the two play squares plus the corridor (Travel.AREAS, player.walkable_areas). The minimap shows both regions' images (north of the seam the Frostlands one). Guide and minimap marker pick the first unbeaten boss, then its open gate, then the next boss (guide_order). The quest card follows progress: after the Bone Warlord it switches to "Defeat the Frost Tyrant". Fast travel and the return portal are in-world teleports in both regions; HOW TO PLAY is available everywhere.
- Tests: check_regions rewritten for the single map (both rosters and bosses present, sealed gateway holds, open gateway walked through and back, guide/quest/light follow, fast travel + portal from the Frostlands, resume in region 2); check_frost_traversal now loads the shared map and shifts its coordinates by the offset; check_enemies counts region 1 soldiers; check_boss uses the guide order. tests/capture_gateway.gd screenshots the gateway. All 10 suites pass.

## D-102 - The tutorial shows itself only once

- Date: 2026-11-07. Status: implemented in v0.33.
- Source: user: the tutorial is shown to the user one time; after that it never appears again automatically unless the user taps it in the UI.
- Decision: tutorial_done is saved as soon as the tutorial starts (not when it finishes), so quitting midway does not bring it back, and RESET no longer clears it. HOW TO PLAY replays it at any time. check_tutorial covers it.

## D-101 - Knights have the 30-second fight window; bosses resized

- Date: 2026-11-07. Status: implemented in v0.32.
- Source: user: when you start fighting a knight, like the bosses, you have only 30 s to defeat him or he goes back to full health.
- Decision: the fight window moved into enemy.gd (fight_window, fight_left, in_fight, update_fight_window) and both the bosses and the Blood / Plague Knights use it: 30 s from the start of a fight, then full health and a new window; leaving the fight also refills. The knights' label shows the countdown under "Lv N". Tutorial knight steps mention the 30 s.
- Balance: tools/simulate_progression.py models the knight window. The fastest strategy found is now: Reaper whenever ready, try the lower knight for one window, switch to the other knight if he refills (falls keep adding damage meanwhile). Boss health re-fitted just above that strategy's best 30 s damage before each target: region 1 1.11M (was 1.2M), region 2 3.26M (was 2.44M), region 3 6.51M (was 3.99M); later regions 3.26M x (minutes / 75)^1.16. Simulated earliest kills 30, 75, 137, 212 min (targets 30, 75, 135, 210).
- Tests: check_progression checks the knight timer label, damage kept within the window, refill after 30 s and on leaving; check_boss and check_regions use the new healths. All 10 suites pass.

## D-100 - Region 2: the Frostlands, frozen undead, Frost Tyrant, fast travel and return portal

- Date: 2026-11-07. Status: implemented in v0.31.
- Source: user: second scene, icy looking, different enemy types, a final boss, a fast travel icon to go back to the Reaper and knights, and a portal back to where you were.
- Map: tools/make_frost_layout.py generates tools/frost_layout.gd from the Meadowlands layout, mirrored left to right (a tested, walkable ground plan) and dressed for winter: desert/stone buildings become snow houses and lodges, sand walls frozen walls, green crystals ice crystals, leafy trees snow pines, haystacks and carts snow crates; no farm fields, orchard, training dummies or start arenas. tools/build_meadow.gd now takes a theme ("-- mask frost", "-- scene frost"): layout, output scenes (scenes/frost.tscn, scenes/world/frost_world.tscn), snow floor and packed-snow path textures, ice-water and snow colours, cold lighting; the lake drains through the west border (WATER_EXIT_WEST). Generated trees, bushes, grass, rocks and cliffs take a "frost" palette at runtime (StylizedMeshes.palette, TerrainBlock.palette: snow on top faces, dark evergreen below, blue-grey stone, snow cliff lips), set by the region before its world loads; the prop mesh cache is keyed by palette. Textures: tools/make_frost_assets.py. Minimap image: tools/minimap_image.py <raw> <out> <layout> snow.
- Enemies: 11 frozen undead from the Toony Tiny undead kit (Skeleton_Elite prefab, --root=Enemies, --keep=parts) in icy atlases (tools/glb_retexture.py): Frost Zombie, Ice Ghoul, Snow Acolyte (cast) / Ice Vampire, Frozen Brute, Rime Cultist, Frost Witch (cast) / Vampire Reaver, Bone Sentinel / Glacier Lord, Frozen Warden. Same ranks and group rule (25 in total) at region 1's clearings mirrored; they take 1.5x region 1's swings to beat. Boss: the Frost Tyrant (2.44M health, D-096), arena (-62, -99.6), gate to region 3 (-62, -115.6, "Coming soon").
- Region-aware game: main.gd exports region and palette; per-region roster, boss, gate, minimap, quest card ("Region 2 quest - Defeat the Frost Tyrant", its portrait, hint "Fast travel to the knights and Reaper to grow stronger."). No Reaper, knights or tutorial in region 2 (HOW TO PLAY hidden).
- Travel (scripts/world/travel.gd): the opened region 1 gate leads into the Frostlands. Fast travel icon in the HUD (always in region 2; in region 1 when more than 40 from the village) takes Kaze to the village by the Reaper and knights; a glowing return portal ("Back to the Frostlands") appears there and returns him to the exact spot, in either region. current_region and the waiting portal are saved; the game reopens in the saved region.
- Tests: check_regions (19 checks: roster, boss, no knights/Reaper, quest, minimap, fast travel both ways, portal, gate travel) and check_frost_traversal (routes, water/cliff/edge blocks, every path both ways, trap scans), added to Run Walking Test.cmd (10 suites, all pass). tests/capture_travel.gd checks real scene changes.

## D-099 - Fall reward as icons

- Date: 2026-11-07. Status: implemented in v0.30.
- Source: user: the fall card shows "+x max health" as text; both rewards should be icons.
- Decision: new icon assets/ui/icon_max_health.png (red heart with a green up arrow, drawn by tools/make_stat_icons.py in the same style). The fall card is now [max-health icon] +1  [damage icon] +N, numbers only, no words.

## D-098 - Fall reward card and knight LEVEL UP placement

- Date: 2026-11-07. Status: implemented in v0.29.
- Source: user screenshot: "+1 MAX HEALTH +14 DAMAGE" and "LEVEL UP!" were in a bad place.
- Causes: the reward label was positioned relative to the HUD's left edge instead of its centre, so it ran off screen over the map; the knight's "LEVEL UP!" was drawn at the height of its name and level lines.
- Decision: the fall reward is a small HUD card under RESET / HOW TO PLAY ("FALL  +1 MAX HEALTH  [damage icon] +N"), popping in for about 2 s; a new fall replaces it instead of stacking. The knight's "LEVEL UP!" is bottom-aligned above its name and level. The quest card's hint is shorter ("Fall, level the knights, visit the Reaper.") so it covers less of the map. tests/capture_popups.gd screenshots both.

## D-097 - Tutorial portraits inside the card layout; HOW TO PLAY button

- Date: 2026-11-07. Status: implemented in v0.28.
- Source: user: in the tutorial the talking characters' heads and their text overlap; there should be a button to play the tutorial again.
- Decision: portraits are no longer placed by hand on the card edge. Story cards put the portrait above the title inside the card; step cards put it beside the text in a row. Cards are positioned every frame from their real size (centred, or just above the thumb zone), so any screen shape works. A HOW TO PLAY button next to RESET replays the tutorial from the start without touching progress; the button and the quest card hide while it runs and return after.
- Tests: check_tutorial adds the replay (progress kept, button hidden then back) and a layout check that no label touches its portrait and every card fits on screen, for every step.

## D-096 - Regions take 30, 45 and 60 minutes

- Date: 2026-11-07. Status: implemented in v0.27. Replaces the timing part of D-095.
- Source: user: region 2 should take 45 minutes and region 3 60 (totals 30, 75, 135).
- Decision: region n takes 15 x (n + 1) minutes (30, 45, 60, 75 ...; totals 30, 75, 135, 210). Boss health is just above the best 30 s damage the simulator's best strategy reaches before each total: region 1 1.2M, region 2 2.44M, region 3 3.99M (BOSS_HEALTHS). The strategy's damage grows in steps, so the earliest simulated kills are 33, 81 and 149 minutes. Region 4+ use 2.23M x (minutes / 60)^0.72 with the new totals.
- Tests: check_boss checks the three healths and the 30 / 75 / 135 totals.

## D-095 - First boss needs at least 30 minutes (was 1 hour)

- Date: 2026-11-07. Status: implemented in v0.26.
- Source: user: lower the minimum gameplay for the first boss from 1 hour to 30 minutes.
- Decision: region 1 boss health 1.2M (was 2.23M): the simulator's best strategy (Reaper whenever ready, knights at equal levels) first reaches it at 33 min; the next step down (1.1M) would allow 29 min. Later regions keep the "region n needs n more hours" rule on top of the shorter start: 30, 150, 330, 570 minutes in total; their health still follows 2.23M x (minutes / 60)^0.72 (region 2 4.32M, earliest 173 min; region 3 7.62M, earliest 383 min).
- Tests: check_boss updated (1.2M, 30 / 150 / 330 min). All suites pass.

## D-094 - Interactive tutorial and region quest

- Date: 2026-11-06. Status: implemented in v0.25.
- Source: user: an interactive tutorial at the start (Kaze is immortal, falling makes him stronger, the ways to do it and to get powerful), a quest per region telling the player to grow strong enough to beat its boss, with good graphics, UI and UX.
- Tutorial (scripts/ui/tutorial.gd): two story cards (dimmed screen, portrait, gold button): "The undying blade" and "Every fall makes you stronger" (the three stat icons explained). Then 7 hands-on steps, each a card above the thumb zone that waits for the action and turns green with "DONE!": move (animated drag hint), meet the Blood Knight, fall once (damage icon glows), level the Blood Knight (damage-per-fall icon), level the Plague Knight (enemy-hit icon), take the Reaper's strike, defeat a soldier (level bar glows). A bouncing gold arrow marks the target (screen-edge arrow when off screen). Last card: "Your quest". SKIP TUTORIAL is always at the top. Finishing or skipping saves tutorial_done; RESET clears it.
- Quest card (scripts/ui/quest_panel.gd), under the minimap: "Region 1 quest - Defeat the Bone Warlord" with a power bar: Kaze's damage in one 30 s boss window (effective damage x 1.25 x 30 / attack interval) against the boss's health; it says what to do, pulses gold with "You are ready!" when full, and turns green "Complete" after the win. It slides in when the tutorial ends. The boss screen-edge pointer waits until then.
- Look: scripts/ui/ui_style.gd (dark wood panels, gold rim, Inter Black / ExtraBold / SemiBold in assets/ui/fonts), round portraits rendered from the game models (tests/capture_portraits.gd -> assets/ui/portraits). Touches on buttons and cards no longer start the joystick (group "touch_ui").
- Tests: new suite tests/check_tutorial.gd (17 checks: start, each step waits then completes, quest reveal, power fraction, ready/complete states, never returns, skip). Added to Run Walking Test.cmd (8 suites, all pass). tests/capture_tutorial.gd screenshots every step.

## D-093 - Smaller map (about 70 %) and 25 soldiers

- Date: 2026-11-06. Status: implemented in v0.24.
- Source: user: "the map is too big, lets make it smaller and also increase number of soldiers"; chose about 70 % (half the area) and "3 for low level and 1 for higher ones".
- Map: tools/shrink_layout.py rewrote tools/meadow_layout.gd (original kept in archive/meadow_layout_before_D-093.gd). Within 40 units of the centre (village, start arenas, spawn) nothing moved; beyond it, square distance from the centre is compressed linearly so the border went from +/-168 to +/-118. Clearings and arenas keep their size; props near a clearing, and the pond with its rocks and reeds, move as one piece so they stay around it; solid props are pushed off the paths; water, crop plots, groves (55 % of the trees) and the orchard shrink with the land; one tree in the high shrine was dropped (it left a pocket by the corner). Boss arena (62, -99.6) and gate (62, -115.6) keep their 16-unit spacing. Map, ground mask, minimap image (now 260 units across) rebuilt.
- Soldiers: the 7 recruit and soldier clearings hold a group of 3 (the clearing's soldier plus two others of the same rank, all different types), 4.6 from the centre and turned until on open ground; the 4 captain and commander clearings keep one. 25 in total. Enemies step apart when they overlap, so a group surrounds Kaze instead of stacking.
- Tests: walking, ramp and wander tests moved to the new coordinates (all pass); the wander test no longer lifts Kaze while he pushes against a wall (that let it "climb" a boulder). check_enemies: 25 soldiers, all 11 types, each group mixed, all on the ground at home. All 7 suites pass.

## D-092 - Every enemy hits for 1 + Plague Knight level

- Date: 2026-11-06. Status: implemented in v0.23. Supersedes the hit parts of D-084 (knight hits x 1.35 per level), D-085 (boss hit 170 x enemy hit) and D-091 (rank multipliers).
- Source: user: "every enemy without a exception should hit hero same damage"; confirmed it follows the Plague Knight level.
- Decision: enemy.hit_damage() is Progression.enemy_hit() = 1 + Plague level for soldiers of every rank, both knights and the boss. The Reaper is unchanged (his swing halves max health, it is not damage).
- Boss re-sized: with flat hits progression is much slower (knight health 1.6^L outgrows damage), so the old 8.67M boss would need over 6 h. tools/simulate_progression.py was rewritten for these rules. Best strategy found: Reaper whenever ready, knights kept at equal levels. Boss health = 2.23M x (minutes / 60)^0.72: region 1 2.23M (earliest 64 min), region 2 4.93M (194 / 180), region 3 8.12M (383 / 360), region 4 11.7M (664 / 600).
- Tests: check_enemies (all ranks equal), check_progression (knights equal), check_boss (boss hits 1 + Plague; new health). All 7 suites pass.

## D-091 - Soldiers scale with Kaze

- Date: 2026-11-06. Status: implemented in v0.22.
- Source: user: "the soldiers are still too easy to kill".
- Why scaling: Kaze's damage grows exponentially (falls x Blood level), so any fixed health becomes trivial within minutes.
- Decision: a soldier's health is "swings" x Kaze's base damage x 1.25 (combo average), locked when it spawns, never below the old tier health. Swings: recruit 12, soldier 20, captain 32, commander 48 (about 8 to 34 s each). Hero levels are left out, so they still speed kills up. Hits by rank: 2 / 3 / 5 / 8 x the enemy hit. Experience still uses the fixed tier health (15 / 40 / 90 / 180), so the boss timing of D-085 holds: simulator earliest kills are now 66 min (region 1), 217 (region 2), 413 (region 3), all at or above the targets.
- Tests: check_enemies checks 60K / 15K health at 1000 damage, the hit multipliers, and that health stays fixed until respawn.

## D-090 - Guide to the region boss

- Date: 2026-11-06. Status: implemented in v0.22.
- Source: user: a guide toward the boss in each region, a flash or something on the minimap that is always visible.
- Decision: the boss is in group "guide_target" (after its defeat, the open gate; the gate drops out once Kaze reaches it). The minimap always shows its skull badge: at its real spot, or pinned to the rim with a gold pointer, pulsing. While it is off screen, scripts/guide_pointer.gd draws a pulsing badge, gold arrow and distance ("86m") on the screen edge in its direction, kept clear of the HUD and joystick.
- Tests: check_boss checks the target, the pointer from the village, the pointer hiding near the boss, and the gate taking over after the win. tests/capture_guide.gd screenshots.

## D-089 - Stat icons instead of words

- Date: 2026-11-06. Status: implemented in v0.22.
- Source: user: good icons for Damage, Damage per Fall and Enemy hit, no text.
- Decision: tools/make_stat_icons.py draws them (sword with an impact star; skull, sword and green up arrow; heart with three claw cuts) into assets/ui/. The HUD stats row is icon + number for each; the hero-level bonus shows as a small "+N%". Number format fix: 999,995 shows as 1.00M, not 1000.00K.

## D-088 - 30 s respawn with countdown, labels that never overlap

- Date: 2026-11-06. Status: implemented in v0.21.
- Source: user: "each enemy should respawn after 30 secs, the cool down should be shown at the place of enemy"; "name of enemy, health of enemy and timer should not colide" (screenshot of the Bone Warlord label over its bar).
- Decision: soldiers come back 30 s after defeat whatever Kaze's distance (the old extra rule "only when Kaze is 40 units away" is gone). While down, "<Name> / back in Ns" shows at its home. The knights keep their instant 1.8 s return (D-080) and the boss stays defeated. Overhead labels (knights, boss, Reaper) are bottom-aligned just above the health bar, so extra lines grow upwards; the gate's "Sealed" sign moved onto the barrier and is depth-tested so it can't draw over the boss's label.
- Tests: check_enemies checks the countdown at 30 s and 10 s and the return with Kaze nearby. tests/capture_labels.gd screenshots the labels.

## D-087 - Longer reach and solid bodies

- Date: 2026-11-06. Status: implemented in v0.21.
- Source: user: attack range of hero and enemies should be bigger, and they must not get close enough for bodies to go inside each other.
- Decision: Kaze reach 5.6 -> 7.5, finisher radius 7 -> 9, lunge stops at 5.6. Enemy reach chop 5.2 -> 7.0, thrust 6.6 -> 8.6, cast 8 -> 10, knights 7.0 (aggro 7.5 -> 9.5), boss 9 -> 11.5, Reaper 6.5 -> 8.5. Body footprints: Kaze 1.8, enemies 0.3 x height (recruit 2.2 ... boss 4.5), Reaper 2.8. player.gd removes movement into any living body (group "bodies") and pushes Kaze back out after lunges.
- Tests: check_enemies pushes Kaze with the joystick into three soldiers and checks the gap stays at least the two radii while they fight. check_meadow_traversal ignores the frozen soldiers' bodies (it tests the ground). tests/capture_spacing.gd screenshots the closest allowed distance.

## D-086 - Float knight health, no hit knockback, reset button

- Date: 2026-11-06. Status: implemented in v0.20 (APK builds/android-2026-11-06-v0.20, SHA-256 2b957ec5...51f4).
- Source: user reported Plague Knight Lv 20 "unkillable" and Blood Knight Lv 151 dying to one hit; asked for a reset button.
- Causes: (1) level_knight.max_health() cast 6 x 1.6^(L-1) to int, which wraps to a negative number from about Lv 92, so the knight died to any blow (and could be farmed, which is how the save reached Blood Lv 151). (2) Every enemy hit knocked Kaze back 22 units/s; strong knights pushed him out of reach and out of their 7-unit arena, so the knight went home and idled with its health unchanged.
- Decision: enemy max_health() returns float everywhere; knight hits are capped at 1e15 so the int health maths stays safe; player.take_damage no longer knocks Kaze back; numbers past 1e15 show as 2.49e31. HUD gets a RESET button under the stats line: first tap arms it for 3 s ("TAP AGAIN TO RESET"), the second calls Progression.reset() and reloads the level.
- Tests: check_progression adds Lv 151 health > 1e30, a Lv 20 Plague Knight beaten while Kaze falls in place, the reset button arming/disarming and reset values. All 7 suites pass.

## D-085 - Region final boss and gate, sized for 1 hour (+1 hour per region)

- Date: 2026-11-06. Source: user: each region has a final boss whose defeat unlocks the gate to the next region; region 1 needs at least 1 hour of play, and each region one hour more than the last (region 2: 2 hours in region 2). Follow-up rule from the user: when the fight starts the player has 30 s, then the boss's health is full again.
- Boss: Bone Warlord (giant Toony Tiny undead skeleton, `assets/enemies/undead/bone-warlord.glb`), `scripts/enemies/region_boss.gd`, in a new arena at (88, -148) on a branch path from the outpost road, in front of the sealed gate at (88, -164) (`scripts/world/region_gate.gd`, jungle-gate arch with a glowing barrier that blocks the way). Shared attack speed (D-082), never flinches, hits boss hit x (1 + Plague Knight level). Fight rule: 30 s after the fight starts (and every 30 s after) the boss refills its health; falls do not heal it; leaving the arena ends the fight. The label shows health and the timer. Defeat is permanent (`Progression.bosses_defeated`), opens the gate and gives no experience. Beyond the gate: "Region 2 coming soon".
- Sizing (`game/tools/simulate_progression.py`, mirrored in `enemy_roster.gd boss_stats`): the simulator plays the rules at swing resolution for two efficient strategies (grind the Blood Knight; Blood Knight plus soldiers). Boss health = 1.1 x the damage the best strategy can deal in 30 s at the region's target time (60, 180, 360 ... minutes in total), using an upper-envelope fit damage(t) = 147,152 x (t / 60)^1.265. Region 1: 8.67M health, hit 170; region 2: 34.8M, hit 510; region 3: 83.6M, hit 1,020. Simulated earliest kills: region 1 at 66 min, region 2 at 207 min (about 2.5 h in region 2), region 3 at 402 min (about 3.25 h in region 3). Re-run the simulator when new regions bring new rules.
- Big numbers are shortened (12.3K, 4.56M) on the HUD and labels.
- Finding worth a design decision: the fastest growth comes from standing at the Blood Knight and falling almost every swing.
- Tests: new `game/tests/check_boss.gd`; `Run Walking Test.cmd` runs it. All seven suites PASS.
- APK 0.19 (`builds/android-2026-11-06-v0.19/`), 34,210,972 bytes, SHA-256 `d896104d2d320baf8ce778aad5f72b749e6411e39128798052c37103c7667eee`.

## D-084 - Tougher soldiers; knights grow exponentially

- Date: 2026-11-06. Source: user: soldiers far too easy; knight level-ups must make them harder and harder to kill.
- Soldier health about 5x: recruit 15, soldier 40, captain 90, commander 180 (experience by D-081: 21, 80, 180, 360).
- Knights (`level_knight.gd`): health round(6 x 1.6^(level-1)) (Lv1 6, Lv3 15, Lv5 39, Lv10 about 410); hits ceil(enemy hit x 1.35^(level-1)) (3.3x at Lv5, 15x at Lv10).
- Open question: with the larger experience values, levels (5 x n) come quickly; the curve may need raising after play.
- APK 0.18 (`builds/android-2026-11-06-v0.18/`), SHA-256 `e4b6e3bf6f30baf407f735026104f7c04e4e83a763a52563f5a073df4be0dc9c`; includes D-083. Progression and enemy tests PASS.

## D-083 - Dying enemies finish their swing

- Date: 2026-11-06. Source: user: even when enemies are dying their attacks must not be interrupted and must hit the hero.
- Decision: an enemy (soldier or knight) defeated after starting a swing but before its blow lands keeps swinging; the blow lands as usual (if Kaze is in reach), then it falls, gives experience or levels up. While finishing it counts as defeated, so Kaze targets someone else and takes no further hits on it. `enemy.gd` (`_dying`).
- Check: `check_progression.gd` kills a soldier mid-swing: it keeps swinging, Kaze loses health, then it falls. All suites PASS.
- APK 0.17 (`builds/android-2026-11-06-v0.17/`), SHA-256 `56c9ccbea1134e2ae2449e6c051a8a17a1f6567c639059b4fed21100a508e0e8`.

## D-082 - One shared attack speed; Kaze's hits never interrupt enemy attacks

- Date: 2026-11-06. Source: user: the hero's attacks must never interrupt an enemy attack, and hero and enemies must have exactly the same attack speed (future attack-speed items must speed up enemies too).
- Decision: `Progression.attack_speed` (saved, default 1.0) and `attack_interval()` = 0.7 s / attack_speed. Every swing by Kaze (each combo step), every soldier and knight attack, and the Reaper's swing is played in exactly one interval, blows land at the same fraction of the swing, and the next swing starts on the same beat (leftover time carried over). Soldier cooldowns and Kaze's combo chain timings and rests are gone. Enemies no longer flinch (stagger removed), and a soldier mid-swing is not knocked back.
- Feel: Kaze swings every 0.7 s (his combo averaged about 0.5 s before); enemies attack every 0.7 s while in reach (about 2.4 s before), so fights are faster and more dangerous.
- Check: `check_progression.gd` counts swings over 4.2 s at attack speed 1x (Kaze 6, soldier 6) and 2x (10 and 10; hit-stop pauses both equally). All suites PASS.
- APK 0.16 (`builds/android-2026-11-06-v0.16/`), 34,144,874 bytes, SHA-256 `513ae2660040950e648fe80cbd0fab4d9981cf1c82ac84d2c493249157579d4a`.

## D-081 - Experience grows with enemy health

- Date: 2026-11-06. Source: user: the more health an enemy has, the more experience it should give, with a fair formula.
- Decision: XP = round(H x (1 + min(H, 40) / 40)), H = the enemy's max health (`Progression.experience_for`). The linear part pays for effort (hits needed grow with health), the bonus pays for longer, riskier fights and stops at +100% from 40 health. Soldiers: 3 -> 3, 6 -> 7, 10 -> 13, 16 -> 22. Replaces the fixed tier experience of D-080. Level n still needs 5 x n.
- APK 0.14 (`builds/android-2026-11-06-v0.14/`), SHA-256 `96930da7f28d5ec082baf1691b4689a2790df242eca151fa5a96051955fc9444`. Progression and enemy tests PASS.

## D-080 - Progression: falls make Kaze stronger; Reaper, Blood Knight, Plague Knight; hero levels

- Date: 2026-11-06. Source: user gameplay design (rules confirmed by the user), with follow-ups: no death animation, experience from soldiers, the Reaper can never be attacked.
- Rules (`game/scripts/progression.gd`, saved to `user://progress.json`, permanent):
  - Kaze starts with 1 max health and 1 damage.
  - At 0 health he "falls" with no animation: +1 max health, +(1 + Blood Knight level) damage, back to full health and keeps fighting where he stands (`main.gd`, `player.gd`).
  - Every enemy hit costs 1 + Plague Knight level health (soldiers ignore their old tier damage).
  - Reaper (hooded cultist with a big axe, `scripts/enemies/reaper.gd`): when Kaze enters his arena he swings once and halves Kaze's max health (minimum 1), then waits 20 s; the cooldown or "Ready" is shown above his head. He is not in the "enemies" group and has no take_hit, so Kaze never targets or damages him.
  - Blood Knight (vampire knight) and Plague Knight (zombie knight), `scripts/enemies/level_knight.gd`: hold their arenas, return 1.8 s after being defeated with a permanent level (shown above their heads). Each level: health 3 x level, hits (enemy hit + level - 1). Blood Knight levels raise the damage gained per fall; Plague Knight levels raise every enemy hit.
  - Experience: soldiers give 2 / 4 / 8 / 15 experience by tier (knights and the Reaper give none); level n needs 5 x n; each hero level adds +1% to base damage (`effective_damage`). Combo steps deal step multiplier x effective damage; enemy health is fractional.
- Start area (`tools/meadow_layout.gd`): three 6.5-radius arenas off the village square on short spur paths: Reaper west (-21, 2), Blood Knight north (4, -20), Plague Knight south-west (-12, 25). The two lodges, the tent and the statue moved, one barrel removed; the arena rule (D-079) keeps them clear. Mask, map and minimap rebuilt.
- HUD (`hero_hud.gd`): health numbers on the bar, hero level and experience bar, and a stats line (damage, damage per fall, enemy hit). Pop-ups for falls, hero level-ups, knight level-ups and the Reaper strike.
- Models: `game/assets/enemies/undead/` converted from the Toony Tiny undead kit (`tt_soldier_to_glb.py` gained per-part atlases, `--root` and `--keep`).
- Tests: new `game/tests/check_progression.gd` (19 checks); all tests use an in-memory progression and never touch the save. `Run Walking Test.cmd` runs it.
- Note: the PC build also keeps a save; there is no in-game reset yet.

## D-079 - Fight arenas kept clear

- Date: 2026-11-06. Source: user screenshot of the stone circle with a crystal in the middle: keep the inside of fight areas clean.
- Decision: `game/tools/build_meadow.gd` skips any prop within 75% of the radius of a fight clearing (every entry in `Layout.PLAZAS` except the village square, which has no soldier), and bushes, rocks and boulders keep out of 95% of the radius. Props ringing the rim stay. Removed: three crystals in the stone circle, the terrace shrine statue at (-60, -68), campfires at the terrace shrine, woodcutter camp, ranger outpost, hunter camp and high shrine, and a log at the ranger outpost. Scatter tiles now store only the holes that overlap them (scene file 458 KB, was 483 KB). Minimap picture re-rendered.
- Rule for the future: new props or layout edits must keep fight arenas empty; the builder prints what it skipped.
- APK 0.12 (`builds/android-2026-11-06-v0.12/`), SHA-256 `f7c0db31bc92b264daf1f01f9afc2bd8e3ee083378219d10af29bb7f4753c2a9`. All five test suites pass.

## D-078 - Toony Tiny RTS soldiers guard the Meadowlands clearings; Kaze gets health

- Date: 2026-11-06. Source: user asked for Toony Tiny soldiers in this region, one enemy per dirt clearing, with different enemy types.
- Assets: 11 soldier prefabs from the Butcher Hero extraction (`unity-meadowlands/Assets`), all Toony Tiny RTS (Polygonmaker) parts on the shared Bip001 rig, converted by `game/tools/tt_soldier_to_glb.py` into `game/assets/enemies/toony-tiny/*.glb` (35-56 KB each) plus one shared colour atlas. Rights: extracted from a commercial game; fine for this private test, a public release needs the purchased packs.
- Animation: the extracted clips are Unity humanoid muscle curves, which cannot be retargeted outside Unity, so idle, walk, chop, thrust, cast, hit and death are original clips authored in `game/scripts/enemies/soldier_animations.gd` (model-space keys converted per bone). Baking the original clips in the Unity Editor on the user's PC remains an option.
- Roster (`game/scripts/enemies/enemy_roster.gd`), one per clearing except the village square: recruits (axe, pike, hammer and shield) near the village; soldiers (sword, spear, broadsword, battle mage); captains (halberd, morningstar); commanders (iron, warhammer) furthest out, the warhammer commander on the upper terrace. The mounted knight was left out because a horse needs much more hand animation. Tiers set health (3/6/10/16), damage (8/12/16/22 of Kaze's 100), size and aggro range; captains and commanders only flinch from the finisher.
- Behaviour (`game/scripts/enemies/enemy.gd`): idle at home, chase when Kaze comes close, attack in reach, give up and walk home (healing) when he leaves the 34-unit leash, do not walk off plateau edges, health bar when hurt, white hit flash, knockback, death topple, respawn after 30 s when Kaze is away. Sleeps beyond 95 units to save phone CPU. Mage attacks are a short-range purple burst.
- Kaze: 100 health, health bar with heart top left (`game/scripts/hero_hud.gd`), red screen-edge flash and knockback when hit; at zero he falls, the screen fades and he respawns in the village at full health while soldiers return home.
- Tuning: Kaze's lunge now stops 4.4 units from the target (was 3.6) so soldiers are not hidden under his hat.
- Tests: `game/tests/check_enemies.gd`; the walking tests pause soldiers. `Run Walking Test.cmd` runs it too.
- Previews: `previews/toony-tiny-soldiers-2026-11-06/`.

## D-077 - Minimap

- Date: 2026-11-06. Source: user asked for a minimap.
- Decision (assistant implementation choices, reversible): a round minimap (220 px across in the 720-wide portrait layout) in the top-right corner, `game/scripts/minimap.gd`, added by `main.gd`. It shows a pre-rendered top-down picture of the Meadowlands (`game/assets/ui/minimap-v001.png`, 512 px, rendered with `tests/capture_overview.gd` and shaded by `tools/minimap_image.py`: plateaus outlined, outside the map darkened), turned to match the isometric camera so up on the minimap is up on screen, 120 world units across. Kaze is a white arrow showing his facing; training dummies (any "enemies" node) are red dots, grey when knocked down. It ignores touches, so the joystick still works underneath it. The picture must be re-rendered if the map layout changes.
- Also: ramp tops now wind their triangles to face upward (`terrain_ramp.gd`). The D-076 normal fix had made them dark with per-pixel lighting on PC.
- Preview: `previews/kaze-combo-2026-11-06/minimap-preview.png`.

## D-076 - Second phone speed-up: per-vertex lighting and 65% render scale

- Date: 2026-11-06. Source: user said the A14 runs better with APK 0.6 and asked for 10-15% more.
- Decision (assistant implementation choices, reversible): on phones only, lighting is computed per vertex instead of per pixel (`rendering/shading/overrides/force_vertex_shading.mobile=true` in `game/project.godot`), and 3D renders at 65% resolution instead of 70% (`MOBILE_3D_SCALE` in `game/scripts/main.gd`, about 14% fewer pixels). PC builds are unchanged. Ramp tops now keep their upward normals (`terrain_ramp.gd`); generated normals pointed down and showed up dark with per-vertex lighting.
- Evidence: a side-by-side render (`previews/kaze-combo-2026-11-06/vertex-lighting-compare.png`) shows the look unchanged apart from slightly darker ramp side banks. The gain could not be measured here: the cloud workspace renders in software, which does not reflect a phone GPU (`game/tests/bench_render_time.gd` showed no clear difference). The user retests on the A14.
- Consequences: slightly softer image on phones.

## D-075 - Samurai II-style auto combo for Kaze

- Date: 2026-11-06. Source: user likes the attack combos of the old Android game Samurai II: Vengeance and wants similar combos for Kaze.
- Decision (assistant implementation choices, reversible): an original four-step combo that runs on auto-attack, still with no attack button. Steps: `slash_1` right-to-left cut, `slash_2` backhand cut, `slash_3` crouch and rising cut, `slash_4` finisher (leap and two-handed slam, 2 damage, hits every enemy within 6 units, ground shockwave). Each swing cuts into the recovery of the previous one at its `chain` time; a pause longer than 0.55 s restarts the chain. Swings step Kaze toward the target (lunge). Feedback: crescent sword trails, a floating "N HITS" counter, hit-stop (0.045 s, finisher 0.09 s) and camera shake. Steps are data in `hero_catalog.json` ("combo": clip, hit, chain, damage, trail, finisher). Training dummies now have 5 health so a full combo topples one on the finisher. Animations are new and original (no copied game assets).
- Files: `game/tools/build_kaze.gd` (clips), `game/scripts/auto_attack.gd`, `game/scripts/slash_fx.gd`, `game/scripts/character_visual.gd`, `game/scripts/player.gd` (lunge), `game/scripts/world/training_dummy.gd`.
- Not done: Samurai II used two buttons (quick and strong) plus a dodge roll, with different button orders giving different combos. Optional buttons for that remain a proposal (T-098).
- Previews: `previews/kaze-combo-2026-11-06/`.
- Amendment (same day, user request): much bigger katana (blade about 1.25 units); reach 5.6, finisher radius 7; APK 0.8.

## D-074 - Low-end phone performance pass

- Date: 2026-11-06. Source: user reported a very low frame rate on a Samsung Galaxy A14.
- Decision (assistant implementation choices, reversible): `game/scripts/world/static_batcher.gd` runs after the world loads and merges identical static models and all blob shadows into one MultiMesh per 48-unit tile. Colliders are untouched and training dummies are skipped. Bridges and crop-field soil are built as single vertex-colored meshes. Scatter uses one mesh variant per kind for most layers. Phones render 3D at 70% resolution (`MOBILE_3D_SCALE`) and skip the environment colour-adjustment pass. The frame rate is capped at 60.
- Measured (llvmpipe, 720 x 1280, 10 spots): draw calls 72-102, down from 115-185; triangles roughly unchanged at 57k-135k. Actual phone frame rate is unmeasured; the user retests on the A14.
- Consequences: phones look slightly softer and a little less saturated. Fewer scatter variants means slightly less variety.

## D-073 - Camera moved back to stop bottom-of-screen clipping

- Date: 2026-11-06. Source: user reported weird rendering in about the lower 10% of the screen on phone and PC.
- Cause: in portrait the visible area is much taller, and with the old camera distance the bottom of the view started almost at ground level at the camera, so the near clipping plane sliced nearby objects. Fix: the orthographic camera sits three times further back along the same direction (identical picture), with near 1 and far 600. Before/after: `previews/kaze-v001-2026-11-06/bottom-clipping-before-after.png`.

## D-072 - Portrait, boot straight into the meadow with Kaze, auto-attack, Dota assets archived

- Date: 2026-11-06. Source: the user asked to remove all Dota 2 hero selection, start the game with the new hero in the scene, switch from landscape to portrait, and replace the attack button with auto-attack when the hero reaches an enemy.
- Decision: `run/main_scene` is now `res://scenes/meadow.tscn`. There is no hero menu, HEROES button or attack button. The catalog contains only Kaze. The project is portrait (720 x 1280 viewport, handheld orientation portrait, aspect expand; 450 x 800 desktop window). The field camera keeps a 40-unit world width. The joystick floats: it appears wherever the thumb touches the lower 60% of the screen.
- Auto-attack: `game/scripts/auto_attack.gd` swings at the nearest node in the `enemies` group within 4.6 units, turning the hero to face it, and lands the hit 0.22 seconds into the swing. While swinging, the hero still moves at 45% speed, so the player can always walk away.
- There were no enemies yet, so three original straw training dummies (`game/scripts/world/training_dummy.gd`) stand near the village to exercise auto-attack. They have 3 health, topple when beaten and stand back up after 3.5 seconds. This is an assistant addition and easy to remove.
- All Dota assets and everything that served only the menu or the legacy 900 x 900 field were moved, not deleted, to `archive/legacy-dota-2026-11-06/game/` with their original paths: the 12 Dota heroes, Juggernaut parts, Dota trees/rocks/cliffs/grass, menu and attack-button art, the hero menu and preview, the legacy field scene, its scripts and biome floors, and 30+ legacy tests. The game folder shrank from about 189 MB to about 8 MB.
- Consequences: legacy decisions and tests that refer to the hero menu, Dota heroes or the 900 x 900 field no longer apply to the running game. They can be restored from the archive. There is no APK of this version yet.

## D-071 - Kaze, an original ronin hero

- Date: 2026-11-06. Source: the user asked for an original, not chunky samurai hero inspired by Juggernaut in the Butcher-like style. On review they asked for him to be a little chunkier and more fun, with a more detailed hat that reads better from the isometric camera.
- Decision: Kaze is an original design, not a copy of any existing character. He wears a wide woven straw hat (striped bands, ribs, rim, red knot and chin cord), a teal cloth mask with large expressive eyes, an indigo kimono under a pale open coat, a mustard sash, dark wide trousers with cream wraps, and a long teal scarf. He carries a katana and a scabbard. Proportions are chunky, with a big head. He is generated in code by `game/tools/build_kaze.gd` into `game/assets/heroes/kaze/kaze.tscn`: a 20-bone skeleton, one rigidly skinned flat-shaded mesh, and idle, run and two-handed attack clips, with no third-party files. Field scale is 2.5.
- Consequences: Kaze uses the same hero interface (`character_visual.gd`) as earlier heroes. Re-running the builder overwrites `kaze.tscn`.

## D-070 - Enlarge the Meadowlands to 336 x 336 without adding a region

- Date: 2026-11-06. Source: user asked to make the current region 2x bigger without adding another region.
- Interpretation (assistant choice, reversible): double the side length. The playable area grows from 168 x 168 to 336 x 336 units (4x area). The original meadow stays unchanged in the centre; the old inner cliff ring is replaced by an outer ring of new meadow places at similar density.
- Additions: a larger north-west terrace with a higher 15-unit tier and second ramp (high shrine); north ruins; a ranger outpost with a fruit orchard; a 4.5-unit east plateau with a stone circle; a lake with an island and fishing hut fed by the pond outflow; a south market crossroads; a pasture farm; and a pine forest with a hunter's camp. Generated groves with trunk colliders keep spacing from paths, water, props, ramps and cliff edges. Bridges are placed automatically where paths cross water.
- Builder changes: data-driven plateaus (can stand on other plateaus), automatic bridges, tiled grass/flower scatter for culling, plateau-aware path warnings. Ramps now reach full height before their top end, so jagged cliff lips cannot snag the hero; this also changes the original terrace ramp slightly.
- Consequences: crossing the region takes about 11 seconds at 30 units/second. Measured cost per frame did not rise (see PROGRESS). Re-running the builder still overwrites manual edits to the world scene.

## D-069 - Meadow fixes: asset import on launch and non-climbable rounded props

- Date: 2026-11-05. Source: user reported that the meadow grass rendered as a flat grey ground and that the hero got stuck between objects in the farm (screenshot in that session).
- Decision: `tools/start-game.cmd` now runs Godot's headless `--import` before launching, because launching the game directly never imports newly added files. The new ground mask had never been imported, so the whole ground material failed to load. The ground material no longer stores null shader parameters. Generated rocks, boulders, haystacks and stumps now use upright cylinder colliders, and authored worlds limit walkable slopes to 35 degrees (the ramp peaks near 28). The village bonfire and bench logs moved out of the crossroads, and one farm haystack moved away from a fence. These are reversible implementation choices.
- Consequences: each launch spends a few seconds checking imports. Heroes can no longer climb rounded props or wedge against them.

## D-068 - Compact hand-composed Meadowlands region

- Date: 2026-11-05. Source: user asked for a review of why earlier assistants had not produced a rich scene, then authorized all five proposed steps without further questions: shrink the playable area, build reusable pieces with real elevation, restore depth without full shadows, unify the environment art style, and review screenshots after each pass.
- Decision (assistant implementation choices within that authorization, all reversible): add a separate 168 x 168-unit playable Meadowlands region (`game/scenes/meadow.tscn`) and make **Enter the Field** open it. Preserve the 900 x 900 field unchanged in `game/scenes/main.tscn` (its tests still target it). Compose the region from reusable editor-visible `@tool` nodes in `game/scripts/world/` (props, cliff plateaus, ramp, arched bridge, water barriers, crop plots, MultiMesh scatter, shared ground shader) into `game/scenes/world/meadow_world.tscn`, generated by `game/tools/build_meadow.gd` from the data in `game/tools/meadow_layout.gd`. Add an 8-unit walkable terrace reached by a ramp, 12-unit cliffs on the far (north/west) borders and 3-unit banks on the camera-side (south/east) borders so cliffs never hide the hero. Enable gravity and floor snapping for the player only in authored worlds.
- Shadows: real shadow casting remains disabled as D-030 requested. Soft blob contact shadows (flat transparent quads) are added under props, trees and the hero. This is a partial relaxation of D-030's intent that needs user confirmation. Lighting adds a warm sun, a weak blue sky fill light and filmic tone mapping.
- Art style: environment trees, bushes, rocks, grass, flowers, crops and haystacks in the meadow are generated flat-shaded low-poly meshes (`game/scripts/world/stylized_meshes.gd`) matching the recovered Butcher Hero props. Dota tree models are no longer used in the meadow; heroes are unchanged.
- Consequences: the other four biomes are not yet rebuilt in this style and remain only in the legacy field. At the current 30 units/second, crossing the compact region takes about 5.6 seconds, which may feel fast. Re-running the builder overwrites manual edits to the generated world scene. Device performance is unmeasured; rights to recovered assets remain unresolved. User review is required (T-083).

## D-067 - ARM64-only Android build

- Date: 2026-10-30. Source: user said only ARM v8 is needed after asking about APK size.
- Decision: add an ARM64-only Android export preset and provide a separately named debug APK. Preserve the existing combined ARM64/x86-64 APK and emulator preset for testing. Asset/animation changes and further size optimizations are not implied by this selection.
- Consequences: x86-64 emulator binaries are omitted from the phone build, reducing its size. It requires an ARM64 Android device; the existing x86-64 emulator cannot directly validate it. Physical device compatibility and performance remain open.

## D-066 - Android debug APK

- Date: 2026-10-30. Source: user requested an Android APK.
- Decision: export the current prototype as a debug-signed APK with Godot 4.7.2, ARM64 and x86-64 support, and the runtime JSON catalog. Reuse the existing sword button artwork as a provisional launcher icon. Signing type, package name and icon are prototype implementation choices, not a production-release decision.
- Consequences: this is for testing, not a release-signed store build. The Android 15 emulator was checked with host graphics; physical phone compatibility, performance, battery use and asset rights remain open. Routine Android exports remain on request (D-019).

## D-065 - Windows desktop prototype build

- Date: 2026-10-30. Source: user requested a Windows PC build.
- Decision: add a Windows x86-64 release export preset using Godot 4.7.2, include the runtime JSON catalog and all imported resources, and provide the executable and data pack together in a ZIP. The target and packaging are implementation choices for this requested prototype build, not a production platform decision.
- Consequences: the Windows build can run without the project or editor when its executable and matching PCK stay together. It contains third-party assets with unresolved usage and distribution rights; production readiness and wider PC compatibility are unverified. Android builds remain on request (D-019).

## D-064 - Walkable low debris

- Date: 2026-10-30. Source: user requested that flat objects lying on the ground, exemplified by factory pipes and scrap in `previews/user-reports-2026-10-30/walkable-factory-debris.png`, and very small rocks should not block heroes.
- Decision: mark factory pipes, elbows, scrap, gears and the existing platform as nonblocking; also omit colliders for other objects at most 0.7 units high and rock variants no wider than 2.5 units and no taller than 1.5 units after scaling. These thresholds are reversible prototype choices. Large rocks, buildings and upright objects retain their existing collision behavior; generated pebbles were already nonblocking.
- Consequences: revises D-062's collision policy for low debris. The rule and visual sense of what should be walkable need user review; collision and animation fit remain incomplete for the full roster.

## D-063 - Distinct regional locations and buildings

- Date: 2026-10-30. Source: user requested richer regions using new object types and buildings rather than merely repeating more props.
- Decision: create three curated locations in each region, using additional recovered structures and props with two simple assembled building designs for volcanic and factory work sites. Their location, layouts, colors and asset choices are reversible implementation choices; recovered props are approximate imports. Keep the existing gates and curved routes clear.
- Consequences: the field has more recognizable sites, but the custom buildings and source materials remain simplified; artistic direction, scene composition, prop collision fit and target-device performance need review. Source asset rights remain unresolved.

## D-062 - Improve object collision and perimeter cliffs

- Collision policy for flat debris and small rocks was revised by [D-064](#d-064---walkable-low-debris).

- Date: 2026-10-30. Source: user authorized fixing the reported object clipping and cliff appearance (T-071/T-072).
- Decision: use mesh-derived convex collision shapes for solid non-tree props, full-footprint boxes for roadside landforms, and a wider shared player capsule; tree trunks continue to block while their canopies remain walkable, and small ground details and decorative factory platforms remain nonblocking. Replace the generated flat-topped outer wall with overlapping recovered cliff meshes and retain a continuous perimeter collider. The factory border reuses a tinted cliff form; foreground sides remain lower to reduce camera occlusion. Specific dimensions and approximation choices are reversible.
- Consequences: collider shapes remain approximations, especially for concave objects and animated hero equipment. User review, other heroes and obstacle approaches, cliff repetition and device performance remain open. D-060 perimeter wall appearance and earlier prop-collision assumptions are superseded.

## D-061 � Winding paths between gates

- Date: 2026-10-30. Source: user requested random curves in the paths and no paths leading to the outer border, only to open gates.
- Decision: replace the straight cardinal and outer paths with 16 curved segments connecting the central junction, four meadow gates, four regional junctions and four outer-region gates. Curves use a fixed random seed so scenery and road geometry stay consistent on each run. Road width, curve shape and junction positions are reversible implementation choices. Keep decorations and landforms clear of the new routes.
- Consequences: the eight existing gates remain the road network's boundary crossings; no road reaches the outer cliffs. Supersedes the straight road geometry and junction locations in D-059. Gate styling and static-open behavior remain. Visual polish, user review and mobile performance remain open.

## D-060 � Visible collidable outer border

- The generated perimeter wall appearance was replaced by [D-062](#d-062---improve-object-collision-and-perimeter-cliffs).

- Date: 2026-10-30. Source: user requested rocks or cliffs at the field's outer border because the end was invisible and the character kept running against it.
- Decision: add continuous biome-colored cliff walls and recovered outcrops around the existing 450-unit limit, with collision at the visible boundary. Keep the south and east sides lower to reduce camera occlusion. Use actual horizontal movement to select walking animation, with a small threshold to ignore collision jitter. Wall styling, heights and animation threshold are reversible implementation choices.
- Consequences: the field edge is now visible and physically blocks the player; running against a stationary wall changes to idle. Perimeter composition, corner joins, mesh/collision fit and device performance still need user review and refinement. The previous movement clamp remains a fallback.

## D-059 � Connect paths through every neighboring region gate

- Straight path geometry was superseded by [D-061](#d-061--winding-paths-between-gates); all eight gates remain connected.

- Date: 2026-10-30. Source: user requested gates between connected regions and paths leading to them.
- Decision: retain the existing four meadow gates and four outer-region gates; add two routes to each outer gate, one from each adjoining region's cardinal road. Route positions and six-unit overlaps at the gate are reversible implementation choices. Clear props, cliff forms and small ground details from the route corridors.
- Consequences: all eight gates have connecting paths; gates remain decorative and fixed open. Road tint transitions are approximate, visual refinement and target-device performance remain open.

## D-058 � Denser reference-guided field dressing

- Date: 2026-10-30. Source: user said the previous field still looked insufficient, with much empty land, and requested another look at the game video. This requests further refinement, not approval of the current composition.
- Implementation choices: retain the D-057 map and gates; add irregular textured routes, region-specific cliff forms, denser themed clusters and destination sites across the backcountry, small generated meadow grass tufts and biome-colored ground details. Snow and volcanic floor colors are approximate. This changes D-057 placement and D-032's no-3D-grass choice; the earlier extracted dense clump system remains unused.
- Consequences: current scenery is a prototype interpretation, not a replica; further composition, original material fidelity, collision fit, Android performance and user review remain open. Recovering more source meshes does not resolve rights.

## D-057 — Reference-guided larger field and gateways

- Date: 2026-10-30. Status: user requested 3x larger sections, improved prop scale and purposeful placements, walls and doors between areas, and a visual direction informed by `screen-20261030-112808.mp4`. The interpretation of 3x as linear dimensions, selected layout, gate styling, cluster locations and asset choices are reversible implementation choices.
- Decision: make the playable field 900 x 900 with a 270 x 270 meadow center, retain the four cardinal outer areas, and add collidable section walls with eight static open double-door gateways. Replace tilted meadow tree pieces with upright extracted Dota oak/pine, and arrange recovered props as themed groves, camps, work sites and snow houses near paths. Maintain camera, 30-unit/second movement and field hero scale.
- Consequences: supersedes D-056 field size and random-scatter design. This is a first reference-guided interpretation, not a replica or confirmation of desired final quality. Doors remain open and do not animate; collision fit, varied set dressing, performance and user visual review remain open. Recovered asset and recording rights are unresolved.


## D-056 — Decorated five-area field

- The field layout, prop placement and size were superseded by [D-057](#d-057--reference-guided-larger-field-and-gateways).

- Date: 2026-10-30. Status: user requested a new field with grass at the center, four surrounding floors including factory, and matching extracted decorations; exact replication is not required.
- Decision: replace the four-quadrant field with a central 90-by-90 grass square surrounded by snow, desert, factory and volcanic areas in a 300-by-300 playable square. Add biome-appropriate static props exported from the recovered Unity project, approximate cylinder collisions and clear cardinal routes. Layout, counts, scale, seed and material approximations are reversible implementation choices. Keep current hero controls, movement speed, field scales and camera.
- Consequences: supersedes D-054 terrain layout. The factory floor uses recovered `FactoryGround1_0.png`, an approximation rather than a recreation of the original missing shader; snow still uses a shader approximation. Imported prop materials approximate the recovered shader, collision shapes are provisional, and user review, fidelity, rights and target-device performance remain open.


## D-055 — Triple movement speed and double field hero size

- Date: 2026-10-30. Status: user requested 3x hero movement speed and 2x hero size inside the field.
- Decision: increase shared field movement speed from 10 to 30 units per second and multiply each selected hero’s assembled field visual by 2. Menu/catalog scales, run animation playback speed and shared player collision capsule remain unchanged.
- Consequences: the 150-unit center-to-side distance now takes 5 seconds at full input. This supersedes the earlier shared field/menu scale behavior in D-040–D-044 and speed in D-027, while preserving menu values. Collision fit, faster animation feel, user review and device performance remain open.


## D-054 — Four-section enlarged field

- Superseded by the five-area layout in [D-056](#d-056--decorated-five-area-field).

- Date: 2026-10-30. Status: user requested clearing the field and creating a bigger field with the four discussed floor types.
- Decision: replace the previous terrain and cliff border with a 300-by-300-unit playable square split into equal grass, desert, snow and volcanic quadrants, meeting at the center. Preserve the player, controls and existing 44-unit field camera. Quadrant arrangement, size, tile scales and an 80-unit outer visual margin are reversible implementation choices.
- Consequences: D-052’s grass floor is retained only for the grass quadrant, and D-053’s cliff border is removed. The grass, desert and volcanic textures are recovered from the Unity export; snow uses a blue-white shader approximation of the recovered sand texture because the original shader is missing. Original source assets remain preserved, visual fidelity and rights remain unresolved, and gameplay/device review is open.


## D-053 — Clear trees and double field camera view

- The retained cliff border was later removed by [D-054](#d-054--four-section-enlarged-field); the field camera size remains.

- Date: 2026-10-30. Status: user requested removing all trees and zooming out 2x more in the Godot field.
- Decision: remove the 105 scattered trees and their collision bodies, retain the cliff border, and double the orthographic field camera size from 22 to 44. Move the camera back on the same sightline and extend the floor margin to avoid clipping and visible floor edges in the sampled views.
- Consequences: supersedes the retained tree placement in D-052 and field zoom in D-026. Source tree assets remain available. Camera framing remains for user review; other aspect ratios and device performance are unverified.


## D-052 — Meadowlands floor in the Godot field

- The single floor and retained cliff border were superseded by [D-054](#d-054--four-section-enlarged-field); the grass texture remains in one quadrant.

- Tree placement was subsequently removed by [D-053](#d-053--clear-trees-and-double-field-camera-view); the Meadowlands floor and cliff border remain.

- Date: 2026-10-30. Status: user requested removing the existing grass and rocks from the field and making the floor like the Unity project.
- Decision: use the recovered Meadowlands grass texture from the Unity preview for the flat Godot floor, remove scattered rock instances and their collisions, and keep the 3D grass clumps disabled. Trees and cliff walls remain; a 45-unit texture tile is a reversible visual approximation.
- Consequences: supersedes the generated floor tint in D-034 and the active rock placement/collision behavior in D-033. Preserved source assets remain available. The original Unity shader is unavailable and exact visual fidelity is unverified; recovered artwork rights are unresolved.


## D-051 — Unity Meadowlands preview materials

- Date: 2026-10-30. Status: reversible assistant implementation choice for the requested reconstruction.
- Decision: use installed Unity 6000.6.7f1 to import the separate copy and create a preview scene with Standard-shader approximations from recovered texture/color properties, retaining the original extracted static scene and source materials. The preview uses a directional light without shadows and an orthographic camera.
- Consequences: the copy was upgraded from 6000.2.6f2; the original export and Godot project remain separate. Shader behavior and visual fidelity are not restored, and the initial region lacks surroundings; T-060 remains open.


## D-050 — Separate Unity Meadowlands reconstruction

- Date: 2026-10-30. Status: user requested stopping the Godot scene conversion, keeping the Godot project, and creating a separate Unity project for the scene.
- Decision: use a separate Unity copy for the Meadowlands reconstruction, retaining the Godot prototype. Preserve the recovered source export. The static-only scene and omission of recovered scripts in the working copy are reversible implementation choices; this does not change the selected engine for the existing game (D-014).
- Consequences: the recovered export has dummy shaders and has not been validated in Unity; visual reconstruction, camera setup and user review are still required.


## D-049 — Start with Meadowlands

- Date: 2026-10-30. Status: user selected Meadowlands as the first region to reconstruct from the recovered Butcher Hero scene.
- Decision: start with Meadowlands. The recovered `map/island (1)` subtree is a provisional identification based on its `Grass Meadowlands` material; its boundaries require visual confirmation.
- Consequences: scene reconstruction and validation remain outstanding under T-059. The current playable field is retained.


## D-048 — Steel and teal attack button

- Date: 2026-10-30. Status: user selected option 4 from the attack button concept sheet.
- Decision: use a transparent steel-and-teal sword button based on option 4 for the existing attack control. Placement, 155-unit square hit area and pressed tint are reversible implementation choices.
- Consequences: visual choice applies to all selectable heroes; existing attack behavior is unchanged. Physical touch and target-device performance remain untested.


## D-047 — WASD movement for desktop testing

- Date: 2026-10-29. Status: user requested keyboard WASD movement for the PC test version.
- Decision: add physical W, A, S and D movement actions alongside the existing arrow keys and on-screen joystick, using the same camera-relative movement and attack behavior. Joystick input takes precedence when active.
- Consequences: WASD is based on physical key positions. This is a desktop prototype control choice, not a final mobile or production control design.


## D-046 — Attack controls for all selectable heroes

- Date: 2026-10-29. Status: user requested the same attack control for all 12 heroes. Selecting one existing base attack clip per hero is a reversible prototype implementation choice.
- Decision: catalog an existing attack animation for every selectable hero, reusing the D-045 on-screen button, one-shot playback, stop-during-swing and movement/idle transitions. The attack clip per hero is documented in the catalog and character-local records.
- Consequences: attacks are animation controls only; targeting, hits, damage, gameplay rules, production clip choices, continuous equipment fidelity and real-device touch remain unverified. Original models and animation assets are unchanged.


## D-045 — First attack control for Juggernaut

- D-046 extends the same control to all 12 selectable heroes.

- Date: 2026-10-29. Status: user requested an attack button for Juggernaut first. The clip choice, stop-during-swing behavior and button styling are reversible prototype implementation choices.
- Decision: show a bottom-right Attack button only for Juggernaut, using his imported `attack` clip once per press. Stop movement during the swing and resume idle or held movement afterward. Ignore repeated presses while swinging.
- Consequences: this is an animation/control prototype; no target, hit detection, damage, combat rules or other heroes' attacks are implemented. Continuous attachment fidelity, touch devices, production gameplay and user review remain open.


## D-044 — Accept prototype hero scales

- The accepted field sizes were subsequently doubled by [D-055](#d-055--triple-movement-speed-and-double-field-hero-size); menu scales remain.

- Date: 2026-10-29. Status: user-confirmed.
- Decision: the current hero scales are good enough for the prototype after the adjustments in D-040 through D-042.
- Consequences: retain the current catalog values in the menu and field. This does not settle production sizing, equipment or collision fit, or other aspects of the selection screen.


## D-043 — Convenient Windows prototype launcher

- Date: 2026-10-29. Status: user requested an easy way to run the game; using a root launcher and desktop shortcut is an assistant implementation choice.
- Decision: add `Play Game.cmd`, which invokes the existing `tools/start-game.cmd`, and create a Windows desktop shortcut to it on this machine. The launcher uses the existing project-local Godot 4.7.2 installation.
- Consequences: the desktop shortcut uses an absolute path and must be recreated if the project moves or on another computer; the project-relative root launcher can move with the project but requires `.tools/godot-4.7.2/` to be present. No Android build is involved.


## D-042 — Further hero size adjustments

- Date: 2026-10-29. Status: user requested further increases after reviewing the prototype.
- Decision: multiply the current runtime scales by 1.10 for Juggernaut, 1.05 for Abaddon, 1.15 for Riki, 1.10 for Tidehunter and 1.05 for Undying, in both menu and field. Other heroes retain their previous values.
- Consequences: these values supersede the corresponding runtime values in D-040/D-041; source multipliers and earlier adjustments remain in `docs/HERO_SCALE_AUDIT.md`. The common collision capsule is unchanged, and per-hero fit remains open (T-040).


## D-041 — Hand-adjust selected hero sizes

- D-042 supersedes the Juggernaut, Riki and Tidehunter runtime values with further increases; the remaining D-041 values stay active.

- Date: 2026-10-29. Status: user requested manual relative size adjustments after testing D-040.
- Decision: multiply the existing runtime scales by 1.20 for Juggernaut, 1.05 for Centaur, 0.95 for Doom, 1.05 for Earthshaker, 1.10 for Riki and 1.10 for Tidehunter. Apply the resulting catalog values to the complete visual in both menu and field. The other six heroes retain their previous values.
- Consequences: the adjusted runtime values supersede the six unmodified Dota multipliers from D-040; source values remain recorded in `docs/HERO_SCALE_AUDIT.md`. The shared collision capsule is unchanged; per-hero fit remains open (T-040).


## D-040 — Apply extracted Dota model multipliers

- D-041 supersedes six of the resulting runtime values with user-requested adjustments; the shared application remains.

- Date: 2026-10-29. Status: user requested using each hero's Dota `ModelScale` in both the game and selection menu.
- Decision: record the 12 extracted values in `game/assets/hero_catalog.json` and apply each to the common visual node, including equipment, in both contexts. The common preview camera remains; this supersedes D-039's unit visual scale only.
- Consequences: source model multipliers do not establish authentic Dota height or presentation by themselves; exported model geometry, animation, pose and other modifiers still matter. The existing gameplay collision capsule is unchanged and per-hero collision fit remains open (T-040). See `docs/HERO_SCALE_AUDIT.md`.


## D-039 — Common scale for hero previews

- D-040 supersedes the unit-scale part of this decision; the shared camera remains.

- Date: 2026-10-29. Status: user-requested scale correction; common preview camera is an assistant implementation choice pending user review.
- Source: user reported that Riki appeared far too large and Mars too small in the idle previews and asked to check all heroes.
- Decision: replace per-hero silhouette normalization with one fixed orthographic preview camera (size 11, same transform) and unit-scale visual nodes for all selectable heroes. This preserves their imported relative model sizes in the menu; the field models and gameplay camera are unchanged.
- Consequences: heroes of different source dimensions and poses appear at different sizes, as expected with a common scale; equipment can affect their silhouettes. Desktop tests confirmed the same camera and model scale and advancing idle animations for all 12; contact and visual presentation remain for user review. Production character-scale choices remain open (T-043).

## D-038 — Full-screen backdrop and consistent preview framing

- Date: 2026-10-29. Status: user-requested full-screen background, no showcase border, grounded feet and more consistent idle-preview scale; exact preview framing is an assistant implementation choice.
- Decision: display the existing arena image across the full menu behind the portraits and remove the showcase panel border. Adjust per-hero preview-only camera size and position so sampled idle silhouettes including equipment have similar displayed heights and meet the illustrated floor. Keep the actual in-game hero model scales unchanged; the desired relative gameplay sizes remain open (T-043).
- Consequences: the background uses aspect-preserving cover, which may crop on different aspect ratios. Desktop 1280 × 720 samples were checked for all 12 heroes; poses, weapons and aspect ratios can affect apparent size or contact over time. Touch and Android performance are untested.
- The per-hero size normalization was superseded by the common preview camera in [D-039](#d-039--common-scale-for-hero-previews); the full-screen background and border removal remain active.

## D-037 — Cinematic hero selection backdrop

- Date: 2026-10-29. Status: user-requested visual refinement; the generated arena setting and UI treatment are assistant design choices pending review.
- Source: user liked the previous menu but said it was too plain and requested changes.
- Decision: add a generated dark fantasy arena background and richer framing behind the existing portrait strip and live 3D idle showcase; adjust preview-only camera framing to align heroes with the illustrated stage. See `assets/ui/README.md` for exact generation prompt and asset provenance.
- Consequences: menu content and gameplay hero scales are unchanged; no real-time shadows are introduced. Desktop menu and all 12 idle previews were checked; user feedback and Android performance remain open.
- The inset background and showcase border were superseded by the full-screen layout in [D-038](#d-038--full-screen-backdrop-and-consistent-preview-framing); the generated arena image remains in use.

## D-036 — Official portraits and animated hero showcase

- Date: 2026-10-29. Status: user-requested official images, Dota-like styling, top portrait list and animated selected-hero preview; layout and preview framing are assistant implementation choices.
- Decision: download Valve's official 256 × 144 hero portraits for the 12 selectable heroes, preserve existing character artwork, and display the portraits in a top row. A dedicated Godot 3D viewport displays the selected model and its existing idle clip below; the field transition and exclusions from D-035 remain. Preview-only camera framing does not change gameplay hero scale. Shadows remain disabled (D-030).
- Consequences: portraits and source models are Valve assets with unverified use and distribution rights (T-014). Desktop selection and idle playback were checked for all 12; full animation fidelity, user review and mobile performance remain open. Abaddon's preview-only mount emission was reduced to avoid a blown-out appearance.

## D-035 — Prototype hero selection menu

- Date: 2026-10-29. Status: user-requested menu and explicit exclusions; arrangement, initial clips and prototype assembly are assistant implementation choices.
- Decision: start with a 12-hero selection menu, excluding Underlord, Primal Beast and Shadow Fiend; the separate unapproved Ember Ronin draft is not included. Selecting a hero enters the existing field, and a Heroes button returns to the menu. Include the available extracted heroes and their default equipment in a prototype roster; this is not a final production roster decision.
- Consequences: imported models and equipment use provisional bone-name synchronization; run root movement is removed at runtime for root bones. Per-hero clips, poses, collision fit, effects and full equipment fidelity remain to be reviewed; Android performance and Valve rights are unresolved. Existing source assets remain preserved.

## D-034 — Choose greener grass

- Superseded for the active floor by [D-052](#d-052--meadowlands-floor-in-the-godot-field).

- Date: 2026-10-29. Status: user-confirmed selection.
- Source: user initially favored the warmer preview, then corrected the choice to greener grass.
- Decision: apply the greener preview's `Color(0.60, 1.0, 0.65)` tint to the existing generated ground texture. Keep the floor as one textured plane, with 3D grass clumps disabled.
- Consequences: desktop Godot capture was checked; target-device performance remains unmeasured. The previous preview choices are retained for reference.

## D-033 — Rock head clearance and floor previews

- Superseded for active rocks by [D-052](#d-052--meadowlands-floor-in-the-godot-field).

- Date: 2026-10-29. Status: user-requested rock clearance and floor options; 1.2-unit clearance and preview color choices are assistant implementation choices.
- Decision: extend rock box colliders 1.2 world units on each horizontal side to account for the hero's forward-leaning head. Present three in-engine floor color previews based on the existing texture; the current floor remains active until the user chooses.
- Consequences: the larger approximate boxes stop the player farther from rocks. Four directions and four sampled run phases passed against all 90 rocks using a 0.35-unit head clearance approximation; this does not validate every animation pose. Android performance remains unmeasured.
- Floor selection completed in [D-034](#d-034--choose-greener-grass); the head-clearance decision was later superseded by D-052.

## D-032 — Textured grass floor and solid large rocks

- The generated floor and active rock placement were superseded by [D-052](#d-052--meadowlands-floor-in-the-godot-field); disabled clumps and tree collisions remain.

- Date: 2026-10-29. Status: user-requested textured floor, large rocks and collision fix; exact sizes and collision approximation are assistant implementation choices.
- Decision: use one repeating procedural grass texture on the existing ground plane, with no 3D grass clumps; enlarge each rock to about 3.5–4.5 units across its largest horizontal local dimension and give it a box collider matching its mesh bounds. Trees retain their existing cylinder collisions.
- Consequences: the plain-floor test (D-031) is replaced. Rock box corners can block movement outside the visible irregular mesh, but all 90 were tested from four directions. The grass texture and source rock models remain unchanged assets; texture generation is runtime code. No Android performance claim is established.

## D-031 — Temporarily remove floor grass for a test

- Date: 2026-10-29. Status: user-requested test; plain brown ground and the implementation switch are assistant choices.
- Decision: disable both the 3D clumps and grass-colored ground texture and display a plain ground surface for this test. Preserve the grass models and generation code; `SHOW_FLOOR_GRASS` in `game/scripts/terrain.gd` can restore both.
- Consequences: D-028 and D-029 grass appearance is temporarily inactive, not discarded. Trees, rocks, cliffs, playable boundaries and the no-shadows direction remain. Review the test result with the user before assuming the grass should be permanently removed.
- Superseded by [D-032](#d-032--textured-grass-floor-and-solid-large-rocks): user chose a textured grass floor without the 3D clumps.

## D-030 — Remove scene shadows

- Date: 2026-10-29. Status: user-requested.
- Decision: disable shadow casting by the prototype's directional light. The scene's grass batches already had shadow casting disabled; lighting and surface shading remain in place.
- Consequences: desktop Godot captures show no cast shadows from the hero, trees, rocks or cliffs. Further lights or shadow-producing effects should respect the user's direction. Mobile performance impact has not been measured.

## D-029 — Denser grass clumps

- Date: 2026-10-29. Status: user-requested increase; exact density is an assistant implementation choice pending review.
- Decision: increase the three extracted grass variants from 1,100 to 8,000 instances each, for 24,000 clumps across the playable square. Preserve the existing MultiMesh batching, source models, randomized placement and scale.
- Consequences: Godot desktop captures show a substantially denser floor; visual preference and Android rendering performance remain unverified. Tune the amount when requested or supported by performance measurements.
- Temporarily inactive for the user-requested test in [D-031](#d-031--temporarily-remove-floor-grass-for-a-test).

## D-028 — Grass beneath cliff borders

- Date: 2026-10-29. Status: user-requested grass at cliff floors; ground extension is an assistant implementation choice.
- Decision: extend the procedural grassy ground 32 units past each playable boundary, with texture scale adjusted to retain its previous density. Playable bounds, cliff placement and movement speed are unchanged.
- Consequences: the border floor is grass in desktop Godot captures. Cliff corner gaps and character occlusion near some edges remain open for later review; target-device performance is not measured.
- The grass surface is temporarily inactive for the user-requested test in [D-031](#d-031--temporarily-remove-floor-grass-for-a-test); the extended ground plane remains.

## D-027 — Double prototype movement speed

- The field speed was subsequently tripled by [D-055](#d-055--triple-movement-speed-and-double-field-hero-size).

- Date: 2026-10-29. Status: user-requested speed increase; preserving map dimensions and animation playback rate are assistant implementation choices.
- Decision: increase movement speed from 5 to 10 units per second while retaining the 150 x 150-unit terrain and the existing run animation playback rate. The center-to-side-midpoint travel time is now 7.5 seconds at full input, superseding the original 15-second prototype timing in D-024. More distant or obstructed routes take longer.
- Consequences: map size no longer depends on movement speed. Godot tests cover cardinal travel, run looping and directional controls; user review of the faster movement and animation feel remains open. No Android build was requested.

## D-026 — Zoom out prototype camera

- The field camera size was subsequently superseded by [D-053](#d-053--clear-trees-and-double-field-camera-view).

- Date: 2026-10-29. Status: user-requested zoom-out; exact amount is an assistant implementation choice pending review.
- Decision: increase the orthographic camera size from 16 to 22 units, showing 37.5% more scene height while retaining its isometric angle and follow behavior. Production projection and camera settings remain open.
- Consequences: Godot desktop screenshot and movement checks were performed; user review and target-device testing remain open.

## D-025 — Run animation in place

- Date: 2026-10-29. Status: assistant implementation choice in response to the user-reported running jump.
- Source: the imported `run_walk` root moves approximately 6.32 units on its horizontal Z axis during its 0.667-second cycle and resets on loop, while the player controller already handles movement.
- Decision: duplicate the runtime animation and fix the root's horizontal position at its first key, preserving vertical motion and the rest of the animation. Original GLB assets stay unchanged. The player controller remains responsible for movement.
- Consequences: the Godot regression checked eight loops and continuous movement, but user visual review, broad animation fidelity and equipment validation remain open. This is a prototype adjustment, not a final animation pipeline decision.

## D-024 — First grassy square terrain

- Date: 2026-10-29. Status: user-requested terrain; layout and measurements are assistant implementation choices.
- Source: user requested a square terrain with grass, randomly placed trees and rocks, and 15 seconds' walking from the center to each end. The earlier cliff extraction was intended for the outer border (D-023).
- Decision: use a 150 x 150-unit square at 5 units/second, giving 15 seconds to each side midpoint at full input. Seed prop placement, keep the four center-to-side routes clear, and add grass and the extracted cliffs. Diagonal paths to corners take longer; obstacles and partial input can extend travel time.
- Consequences: terrain, collision cylinders, generated floor texture, grass batching, tinted stone materials and edge position clamps are prototype choices, not final production design. Godot desktop checks passed; user review, cliff joins, performance and Valve asset rights remain open. No Android build was requested.
- The original 15-second travel time was superseded by the speed increase in [D-027](#d-027--double-prototype-movement-speed); terrain dimensions remain unchanged.

## D-001 — Start a new project based on 3D models

- Date: 2026-10-29. Status: confirmed.
- Source: user explicitly requested marking the previous project failed and starting a new project based on 3D models.
- Decision: establish a separate project using 3D models; preserve the failed predecessor.
- Consequences: no previous assets or roster automatically adopted. No engine, provider, camera or production pipeline selected.

## D-002 — Initial organization

- Date: 2026-10-29. Status: assistant implementation choice.
- Decision: use android-3d-fighter as a temporary folder name; retain predecessor documentation and character-artwork obligations.
- Rationale: portable continuity and separate workspace.
- Consequences: Android fighting-game context is a working assumption rather than newly confirmed platform direction. Final game name undecided.
- Superseded in part by [D-003](#d-003--3d-android-game-with-an-isometric-camera): platform and camera are now confirmed. Temporary naming and separation from the predecessor still apply.

## D-003 — 3D Android game with an isometric camera

- Date: 2026-10-29. Status: user-confirmed.
- Source: user explicitly requested a 3D Android game with an isometric camera.
- Decision: use this as the project direction, replacing the initial platform assumption and open camera direction in D-002.
- Consequences: side-view and rendered-sprite alternatives are no longer active direction choices. Exact projection and camera behavior remain open. Diablo-like ARPG with possible multiplayer PvE/PvP and multiplayer PvP-only are candidate gameplay directions, neither selected. No engine or networking solution is implied.

## D-004 — Document now; models and animations in later tasks

- Date: 2026-10-29. Status: user-confirmed.
- Source: user wants to start with models and animations but explicitly instructed creating only documents now and said tasks will follow later.
- Decision: record the brief and future work without starting asset generation, coding or tool setup.
- Consequences: first asset, rig, animation set and workflow still need task-specific direction. Prior idle/walk milestone remains proposed. Continue mandatory durable documentation for all subsequent work.
- Superseded for the first character model/preview task by [D-006](#d-006--first-character-model-and-approval-preview). Unselected rig/animation/gameplay scope remains open.

## D-005 — Clean code, meaningful naming and consistent style

- Date: 2026-10-29. Status: user-confirmed requirement; supporting review practices are assistant implementation choices.
- Source: user explicitly requires clean-code principles, readable code, careful naming/style and avoiding huge files, methods and functions.
- Decision: persist the requirement in AGENTS.md and CODING_STANDARDS.md.
- Rationale: preserve the user's maintainability requirements for future contributors.
- Consequences: review code for focused responsibilities and comprehension; choose specific language conventions/tooling after engine selection. No numeric size limit, engine, architecture or tool is approved by this decision.

## Open choices

Gameplay selection and multiplayer scope, precise camera settings, first-character design approval, production engine version, final production tools/pipeline, animation scope, Android performance targets and networking architecture. See PROJECT_DIRECTION.md and TODO.md.

## D-006 — First character model and approval preview

- Date: 2026-10-29. Status: user-confirmed task authorization; design and game use pending confirmation.
- Source: user requested a first character based on Dota 2 Juggernaut, a 3D model, and a preview for confirmation before using it.
- Decision: authorize this asset task and required supporting artwork/authoring work. This supersedes D-004's documentation-only boundary for this task; historical restrictions remain recorded there.
- Consequences: create an actual editable mesh and previews; maintain separate concept/model sheet, fighting stance and transparent head icon under AGENTS.md. No game engine, gameplay, networking, rig or animation set is selected. User approval is still needed before adopting the design for the game.

## D-007 — Reversible first-draft workflow

- Date: 2026-10-29. Status: assistant implementation choice, pending design review.
- Decision: temporary character ID ember-ronin; procedural static stylized geometry authored with official portable Blender 4.5.9; native blend and GLB delivery; preview/artwork rendered directly from that mesh. No predecessor assets or third-party meshes/textures used.
- Rationale: available tools had no direct 3D generator or installed Blender; editable local source and GLB provide concrete geometry for review without choosing an engine or external asset service.
- Consequences: segmented approval mesh requires later production preparation before rigging/Android use. Python conventions are in tools/README.md; these asset helpers do not select the game's language. Official Juggernaut PNG is a reference only, not licensed production content; rights to Valve's artwork/character are not asserted. Original geometry does not establish clearance of the derivative design.
- v001's toy-like visual direction was rejected by the user; superseded for current design direction by D-008. The original files and tooling remain preserved.

## D-008 — More realistic and aggressive first character

- Date: 2026-10-29. Status: user-confirmed revision request; resulting design/use still requires review.
- Source: user described v001 as too childish and requested a more realistic/aggressive character.
- Decision: revise actual 3D geometry and its artwork, preserving v001. Adult proportions, continuous anatomy, narrower severe eyes, thinner armor, muted weathered materials and a lowered head are assistant implementation choices for v002.
- Consequences: v002 becomes the current review candidate once verified; v001 remains archived. Preserve ivory masked-swordsman/crimson armor/curved sword identity. This does not approve the finished design or game use, or authorize rigging/engine implementation. Procedural Blender surface grain is not yet baked into GLB; communicate that limitation.

## D-009 — Confirm three extracted starting character models

- Date: 2026-10-29. Status: user-confirmed selection and copying; licensing remains unresolved.
- Source: user accepted the corrected previews and requested Axe, Juggernaut and Shadow Fiend as the project's first confirmed character models.
- Decision: retain both extracted glTF and GLB sets and their default equipment in character-local folders, preserving the supplied originals and the separate Ember Ronin draft.
- Consequences: this supersedes D-006's scope as the sole current character authorization, but does not imply approval of Ember Ronin, an engine, animation pipeline, distribution rights or runtime readiness. Equipment was matched for a static preview; animation binding needs validation.

## D-010 — Engine evaluation and recommendation

- Date: 2026-10-29. Status: assistant recommendation; user selection pending.
- Source: user requested a free, powerful engine with good performance for this project.
- Recommendation: evaluate Godot first for Android 3D because its MIT license allows commercial use without engine royalties or revenue-based subscription tiers, and it provides mobile rendering and glTF support. Its license notice must accompany redistribution. Performance is not established; benchmark the actual scene, assets and target devices before committing to budgets.
- Alternatives: Unity Personal is free subject to eligibility, currently a $200,000 financial threshold; Unity's game Runtime Fee was canceled. Unreal Engine is free to start but game royalties can apply after $1 million in lifetime gross product revenue. Both are capable Android options; terms and practical tradeoffs differ.
- Sources checked: [Godot license](https://godotengine.org/license/), [Godot renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html), [Unity pricing](https://unity.com/products/pricing-updates), [Unreal mobile licensing](https://www2.unrealengine.com/uses/mobile-games).
- Consequences: no engine, version, language, renderer, networking architecture, prototype scope or installation is selected by this recommendation. Existing character import and equipment assembly remain unvalidated.

## D-011 — Test Juggernaut in Godot

- Date: 2026-10-29. Status: user-authorized evaluation, not final engine selection.
- Source: user agreed to test Juggernaut in Godot first.
- Decision: conduct an isolated desktop import and animation experiment using portable Godot 4.7.2 and GDScript test helpers, with copied assets and a reversible bone-name pose mapping. These are assistant choices for the test, not production engine version, language, renderer or animation decisions.
- Consequences: inspect idle, walk and attack; continue testing equipment and Android performance before drawing production conclusions. Rights remain unresolved. See `experiments/juggernaut-godot-test/README.md` and T-015.

## D-012 — Blade Fury and clip browsing in the experiment

- Date: 2026-10-29. Status: user-requested evaluation; preview technique is an assistant implementation choice.
- Source: user expressed happiness with the initial result and requested checking other animations, specifically Juggernaut's Blade Fury.
- Decision: expose the imported clips in the desktop viewer and preview `attack_spin` with additional whole-character rotation; the raw clip largely holds a pose. The rotation speed is an approximation and does not assert reconstruction of Dota's original behavior.
- Consequences: preview only; original particle effects, gameplay behavior, continuous equipment fidelity and Android performance remain unverified. No production animation or engine selection implied.

## D-013 — Godot is a leading candidate after preview

- Date: 2026-10-29. Status: user-expressed preference; final selection pending.
- Source: user described the result positively and said Godot is very possible for continuing.
- Decision: treat Godot as the leading candidate for further evaluation. This is not an unambiguous final engine selection or authorization for a game implementation.
- Consequences: retain the desktop experiment for further review; Android device performance, animation and equipment fidelity, rights and prototype scope remain open. See T-006, T-014 and T-015.
- Superseded as an open engine choice by [D-014](#d-014--godot-and-gdscript-confirmed); evaluation findings remain historical.

## D-014 — Godot and GDScript confirmed

- Date: 2026-10-29. Status: user-confirmed.
- Source: after evaluating the Juggernaut preview, Android export and language performance, the user explicitly confirmed starting with Godot and GDScript.
- Decision: use Godot as the game engine and GDScript as the initial game programming language.
- Consequences: establish GDScript conventions before substantial game code, and define prototype scope, production Godot version and target devices. Existing Godot 4.7.2 viewer remains an experiment. This choice does not select gameplay, networking, animation scope or authorize asset distribution; Android performance and Valve asset rights are unverified.

## D-015 — Virtual Android device for initial tests

- Date: 2026-10-29. Status: user-confirmed testing preference.
- Source: user has two Android devices but prefers a virtual device for tests for now.
- Decision: plan initial Android tests on an emulator. The emulator product, configuration and prototype test scope are not selected.
- Consequences: physical phone tests can be considered later; emulator results do not establish real-device performance, heat, battery life or hardware compatibility. No emulator setup or test is implied by this preference.

## D-016 — Android Emulator recommendation

- Date: 2026-10-29. Status: assistant recommendation in response to user request to choose; user confirmation pending.
- Recommendation: Google's Android Emulator with an Android Virtual Device managed through Android Studio. It supports Android SDK and adb workflows and configurable hardware and graphics acceleration; it fits Godot Android export testing. Sources: [Android emulator acceleration](https://developer.android.com/studio/run/emulator-acceleration) and [Godot Android export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).
- Consequences: choose the image, API level, graphics settings and actual installation path during setup. Emulator rendering and acceleration need a practical check; frame rate, thermals and compatibility on physical phones remain unverified. No emulator or SDK was installed or selected by the user yet.
- Recommendation confirmed for setup by [D-017](#d-017--android-emulator-setup).

## D-017 — Android Emulator setup

- Date: 2026-10-29. Status: user-confirmed emulator selection and setup request; specific configuration is an assistant implementation choice.
- Source: user accepted Google's Android Emulator and requested setup. User subsequently authorized using a network proxy to address connection problems.
- Decision: use Google's Android Emulator and an Android 15 x86_64 virtual device; the standard Android image without Google Play is adequate for initial app tests. Keep SDK and virtual-device files local under `.tools/`. Android Studio's Device Manager remains the intended GUI management option if the download is available.
- Consequences: emulator graphics and boot must be verified, and Google Play services will need a different image if required later. Real phone performance, thermal behavior and compatibility remain unmeasured.

## D-018 — First movement prototype

- Date: 2026-10-29. Status: user-authorized prototype; presentation details are assistant implementation choices.
- Source: user requested first code: landscape, Juggernaut in a location, movement in every direction using on-screen controls and an isometric camera.
- Decision: create a Godot/GDScript prototype in `game/` with a temporary bounded arena, follow camera, virtual joystick and idle/walk animation. Godot 4.7.2, orthographic camera settings, compatibility renderer, arena layout, desktop arrow-key support and speed are test choices rather than final design commitments.
- Consequences: this authorizes the described prototype, not a gameplay mode, networking, final assets or distribution. Rights and full animation fidelity remain unresolved; emulator or desktop behavior does not prove performance on phones.

## D-019 — Godot-first testing; Android builds on request

- Date: 2026-10-29. Status: user-confirmed workflow preference.
- Source: user said there is no need to build an APK and test every change on Android; continue developing/testing in Godot and make Android builds at points the user requests.
- Decision: use Godot/desktop tests for routine work; prepare and test Android builds when explicitly requested.
- Consequences: an initial debug APK and emulator test had already been performed for the movement prototype before this preference was given. Do not automatically repeat Android builds for later changes. Physical-device performance remains unverified.

## D-020 — Copy nine new extracted character sets

- Date: 2026-10-29. Status: user-authorized copying; roster and game-use approval not established.
- Source: user reported new models and animations in the previously used extractor folder and asked to copy them into this project.
- Decision: copy complete glTF and GLB outputs for Primal Beast, Centaur Warrunner, Undying, Underlord, Tidehunter, Mars, Doom, Riki and Sand King into versioned character-local source folders. Preserve original files and existing models; copy includes separately exported equipment, alternate forms and animation data.
- Consequences: extractor clip counts and successful file copies do not establish animation playback, attachment alignment or runtime readiness. Valve asset rights remain unresolved; no automatic game integration or final roster approval is implied. Each character needs required artwork and local records under AGENTS.md.

## D-021 — Copy three heroes and six environment models

- Date: 2026-10-29. Status: user-reported assets; copying is an assistant action inferred from the preceding copy workflow.
- Source: user reported new extracted heroes and three tree and three rock models in the same extractor workflow.
- Decision: preserve Abaddon, Earthshaker and Elder Titan glTF/GLB sets and the complete tree/rock extraction under project assets, including original and filtered tree variants. No automatic roster or level-placement decision is implied.
- Consequences: animation, equipment, visual quality and Godot runtime readiness need validation; Valve rights remain unresolved. Static reference artwork for the three heroes is a candidate, with combat-ready pose and equipment checks remaining.

## D-022 — Copy extracted grass pack

- Date: 2026-10-29. Status: user-reported assets; copying inferred from the preceding asset-copy workflow.
- Source: user reported extracting grass models after the previous environment copy.
- Decision: retain the complete three-variant grass pack in a separate versioned environment folder, preserving glTF, GLB, texture dependencies and extractor metadata.
- Consequences: no automatic scene placement or final visual approval. Alpha-cutout appearance, performance and Godot import remain untested; Valve game-use and distribution rights are unresolved.

## D-023 — Cliff walls for the map border

- Date: 2026-10-29. Status: user-stated intended use; copying inferred from the preceding asset workflow.
- Source: user reported extracting cliff walls for the outer border of the map.
- Decision: preserve all three extracted cliff-wall sections and their glTF/GLB dependencies in a separate versioned environment folder; the intended use is the outer map border.
- Consequences: placement, joins, collision, appearance and performance remain untested and are not implemented by the copy. Valve game-use and distribution rights remain unresolved.
