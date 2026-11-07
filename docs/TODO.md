# Tasks

Last updated: 2026-10-29. The user confirmed three extracted starting character models (D-009); rights and runtime readiness remain unresolved. Ember Ronin is a separate draft pending review. Remaining implementation items are proposals unless explicitly marked authorized.

- [x] T-001 Initialize separate 3D project and continuity documentation.
- [x] T-002 Define first model milestone: Juggernaut-inspired character, static 3D approval draft, editable Blender source/GLB, previews, model sheet, right-facing stance and transparent icon. References/checks are recorded under assets/characters/ember-ronin/. No animation milestone approved.
- [x] T-003 Select first-draft workflow: original procedural geometry in portable Blender 4.5.9, blend/GLB exports, official Valve PNG for visual reference only. Provenance/rights limitations recorded; no claim of clearance or final production-pipeline approval.
- [ ] T-004 First character production model/rig. Static approval draft is created and validated; design/game-use approval pending ER-005. Rig and production preparation remain proposed, not authorized. Complete only when approved production scope, versioned files and model/rig checks exist.
- [ ] T-005 Validate idle and walk with consistent proportions, ground contact and weapon attachment where applicable. Proposed animation set, not approved; depends on T-004. Complete when the approved clip set is exported and checked with results recorded.
- [ ] T-006 Select engine and Android prototype scope. Godot and GDScript confirmed (D-014); initial movement prototype requested and implemented (D-018). Production version, later physical targets and production acceptance criteria remain open. Complete when these are recorded.
- [ ] T-007 User-requested: add existing project folder to Codex sidebar. Previously blocked on manual UI registration; not rechecked this session. Complete when project listing includes this folder.
- [x] T-008 Document user's 3D Android/isometric direction, gameplay candidates, documentation-only boundary and clean-code requirements. Completed in PROJECT_DIRECTION.md, CODING_STANDARDS.md and continuity records.
- [ ] T-009 Choose gameplay and multiplayer scope. Open user decision, not implementation authorization. Complete when direction and PvE/PvP scope are recorded; preserve both candidates until then.
- [x] T-010 Establish initial GDScript naming, formatting and code organization conventions. Documented in CODING_STANDARDS.md; Godot imported and ran the prototype. No external formatter/linter configured; revisit as the project grows.
- [ ] T-011 Define exact camera behavior and Android asset/performance targets when needed for production. Proposed; depends on asset/prototype scope. Complete when projection, camera behavior and measurable constraints are recorded.

- [ ] T-012 Review first character preview and confirm/revise design before game use. User rejected v001's childish style and requested more realism/aggression (D-008); v002 is the revision candidate. Game-use confirmation remains pending; see ER-005/ER-008 in assets/characters/ember-ronin/TODO.md.

Ongoing requirements: maintain continuity records and follow CODING_STANDARDS.md. Each character requires local README/HISTORY/TODO, concept/model sheet, separate fighting stance and head icon under AGENTS.md. First character work is authorized by D-006; other characters and game implementation are not implied.

- [x] T-013 Copy and register Axe, Juggernaut, and Shadow Fiend as user-confirmed starting models; retain source, records and mandatory character artwork; verify copies. See D-009 and individual records.
- [ ] T-014 Resolve rights/permission for use and distribution of the copied Dota 2 models and textures; complete when applicable rights are documented.
- [ ] T-015 Establish and validate equipment assembly through selected animations and engine import for the three confirmed characters. Juggernaut Godot test sampled idle, walk, attack and spin-related clips with test bone mapping; continuous review and other characters remain open. Complete when a reproducible assembly is tested across approved clips.
- [ ] T-016 User-requested: set up Google Android Emulator with an Android virtual phone, verify acceleration, boot and adb connection, and document use. Android 15 virtual phone has booted and connected; Android Studio Device Manager remains pending. See ANDROID_EMULATOR.md.
- [x] T-017 User-requested: first landscape movement prototype with Juggernaut, an isometric camera, a location and on-screen directional movement. Godot movement checks and initial emulator smoke test passed; user review and production readiness remain open.
- [x] T-018 User-requested: copy the nine new extractor character sets in glTF and GLB formats, retaining animation data and verifying copies. See D-020 and ASSETS.md. Required artwork is tracked separately in T-019.
- [ ] T-019 Required: nine model sheets, right-facing idle-pose stance candidates and transparent head icons are created and inspected. Verify combat-ready stance and equipment fidelity for each character and revise as necessary before considering the required concept sets complete. See character-local C-002 tasks.
- [x] T-020 Copy new extractor output for Abaddon, Earthshaker, Elder Titan and three trees/three rocks, preserving both formats and dependencies, and verify copies. See D-021 and ASSETS.md.
- [ ] T-021 Required: verify combat-ready stances and attachment fidelity for Abaddon, Earthshaker and Elder Titan; candidate sheets, right-facing idle poses and icons exist. Environment models were imported and visually checked in the prototype (D-024). See character-local C-002 and assets/environment/README.md.
- [x] T-022 Copy the newly extracted three-variant grass pack with both formats, textures and reports; verify source hashes and references. See D-022.
- [ ] T-023 Grass imported and visually checked in the terrain prototype (D-024); investigate alpha appearance and measure performance on representative targets. Resolve rights before distribution (T-014).
- [x] T-024 Copy the three extracted cliff-wall sections with both formats, dependencies and reports; verify source hashes and references. See D-023.
- [ ] T-025 Cliff sections are placed and visually checked in the prototype (D-024); review joins and collision approach against the eventual map scope. Resolve rights before distribution (T-014).
- [x] T-026 User-requested: create the grassy square terrain with randomly placed trees and rocks, and 15-second center-to-side travel. Godot movement and cardinal timing checks passed; visual review and device performance remain open under T-027.
- [ ] T-027 Await user review of the terrain and refine as requested; inspect cliff joins, obstacle collision fidelity and performance on selected target devices. Completion requires recorded review and relevant measurements.
- [x] T-028 Fix user-reported run animation jump: remove duplicate horizontal root travel from the runtime clip and check continuous movement across multiple loops in Godot. User said the result is good; broader animation review remains open in Juggernaut C-006.
- [x] T-029 User-requested: zoom the prototype camera out and check the view in Godot. The selected amount is provisional pending user review (D-026).
- [x] T-030 User-requested: double movement speed and check movement, run looping and terrain timing in Godot. User review of the faster movement and animation feel remains open in Juggernaut C-006.
- [x] T-031 User-requested: extend the grassy floor beneath the cliff border; visually check the sides and corners in Godot. Cliff corner gaps and edge occlusion remain under T-025/T-027.
- [x] T-032 User-requested: make grass clumps substantially denser and visually inspect the Godot scene. User review and target-device performance remain open under T-023/T-027.
- [x] T-033 User-requested: remove scene shadows and visually check the result in Godot. Maintain the no-shadows direction for future scene work (D-030).
- [x] T-034 User-requested: temporarily remove floor grass for a test and check the result in Godot; the clump setup and ground texture remain restorable (D-031).
- [x] T-035 User chose a textured grass floor without 3D clumps after the grass-free test (D-032).
- [x] T-036 User-requested: add textured grass floor, enlarge rocks and fix rock collisions; check appearance, all rock collisions and movement in Godot. User review and target-device performance remain open (T-027/T-011).
- [x] T-037 User-reported: prevent Juggernaut's head entering rocks; add clearance and test all rocks with sampled run poses (D-033). Other animation poses remain unverified.
- [x] T-038 User chose the greener floor preview; applied its tint and visually checked it in Godot (D-034). See ASSETS.md.
- [x] T-039 User-requested: create a hero-selection menu excluding Underlord, Primal Beast and Shadow Fiend, load selected heroes into the field and provide a return path. Godot roster, clips and scene transition checks passed; see D-035.
- [ ] T-040 Review each selectable hero's animation, equipment alignment, size and obstacle-collision fit throughout movement; correct issues found and record checks. The shared capsule and provisional bone synchronization are not production validation. Target-device performance and rights remain open (T-011/T-014).
- [ ] T-041 Investigate the user's possible first-selection camera zoom difference: desktop scene-switch tests for all 11 other heroes and a rendered Axe/Juggernaut/Axe comparison did not reproduce a change. If it recurs, capture the hero, exact steps and window/device conditions; complete when the observed cause is confirmed and any needed fix verified, or the user confirms it no longer occurs.
- [x] T-042 User-requested: check all selectable heroes' applied scale and compare their visible sizes under the same camera. See HERO_SCALE_AUDIT.md; no hero sizes were changed.
- [ ] T-043 Determine the user's desired relative hero sizes before resizing; if requested, adjust models and collision fit and verify representative poses (T-040). No normalization is yet approved.
- [x] T-044 User-requested: download the 12 official hero portraits, preserve existing artwork, document sources and use them in the redesigned menu. Valve artwork rights remain unresolved (T-014).
- [ ] T-045 User review of the Dota-like selection screen and all animated previews; refine any reported visual, framing, animation or usability problems. Device performance and touch behavior remain open (T-011/T-040).
- [x] T-046 User-requested: make the selection screen less plain; add and inspect a cinematic backdrop and refined preview presentation. The resulting design remains for user review (T-045).
- [x] T-047 User-requested: make the arena background full-screen behind portraits, remove the showcase border, align hero previews to its floor and make preview sizes more consistent. Checked all 12 sampled idle views in Godot; user review and other poses/aspect ratios remain open under T-045.
- [x] T-048 User-reported: correct inconsistent hero preview scales across the full roster. Replaced per-hero camera zoom with one shared camera and unit model scale; verified all 12 in Godot. User review remains open (T-045).
- [ ] T-049 Compare actual Dota 2 per-hero proportions using a controlled same-camera view with matching model version, pose and modifiers. Extracted `ModelScale` values now apply in the prototype (D-040), but do not alone prove authentic relative heights. See HERO_SCALE_AUDIT.md.
- [x] T-054 Add and desktop-test an on-screen attack button and animation for Juggernaut (D-045); user review and continuous equipment fidelity remain open.
- [x] T-055 Add the attack control and an existing attack clip for all 12 heroes; Godot checks passed (D-046). User review, touch and continuous equipment fidelity remain open.
- [x] T-058 User selected option 4; created and implemented the steel-and-teal attack button and verified desktop activation in Godot (D-048). User and physical-device review remain open.
- [x] T-057 Add and Godot-test desktop WASD movement alongside existing arrow keys and joystick (D-047).
- [ ] T-056 User review: test all hero attack animations and feel; targeting, hit detection and damage remain undefined.
- [x] T-053 Provide an easy Windows launcher for the prototype; root launcher and desktop shortcut created and launcher verified (D-043).
- [x] T-052 Increase Juggernaut, Abaddon, Riki, Tidehunter and Undying relative to their current sizes in menu and field and verify in Godot (D-042); size acceptance is recorded in D-044; other presentation review remains under T-045.
- [x] T-051 Apply user-requested relative size changes for Juggernaut, Centaur, Doom, Earthshaker, Riki and Tidehunter in menu and field and verify in Godot (D-041); size acceptance is recorded in D-044; other presentation review remains under T-045.
- [x] T-050 Apply the extracted Dota `ModelScale` for all 12 selectable heroes in both the field and menu; verify each in Godot (D-040).

- [x] T-059 Superseded by D-050: user stopped the Godot conversion. Original request: recreate the recovered Butcher Hero Unity scene in the Godot project, copying needed files. User selected Meadowlands first (D-049); a provisional subtree and its mesh/material references are indexed. Convert meshes and materials, implement the scene and visually validate it, then record limitations and asset provenance. No scene has been imported yet. See BUTCHER_SCENE_ASSESSMENT.md.

- [ ] T-060 User-requested: reconstruct Meadowlands in separate Unity project. Unity 6000.6.7f1 imported the copied project and rendered a provisional scene with approximate materials, camera and light. The preview includes ground and an arena, but surrounding environment and exact region boundaries are incomplete. Investigate and restore relevant objects from recovered Main; address the 10 null mesh and two missing material references where possible; refine materials, compare with original references and obtain user review. Effects, collisions and gameplay remain omitted. No Android build made.

- [x] T-061 User-requested: replace the Godot field floor with the Unity Meadowlands texture and remove grass clumps and scattered rocks. Godot imported the texture, visual captures were inspected, and movement and four-side travel checks passed. Trees and cliff border remain; user review and Android performance remain open under T-027/T-011.

- [x] T-062 User-requested: remove all trees and their collision bodies and double the field camera view size; inspect Godot center and edge screenshots and verify movement and camera switching. User review and device/aspect-ratio testing remain open (T-027/T-011).

- [x] T-063 User-requested: inventory recovered Unity ground material names and representative texture references. Found 52 files with 24 names using one ground shader; counts are not a complete biome count. See BUTCHER_FLOOR_INVENTORY.md.

- [x] T-064 User-requested: clear the field and create a larger four-section grass/desert/snow/volcanic floor. Godot verified section layout, movement, four-side travel and center rendering. User visual review, source-material fidelity, asset rights and Android performance remain open.

- [x] T-065 User-requested: triple hero movement speed and double hero visual size in the field while retaining selection-screen sizes. All 12 menu/field scales, movement directions, run/idle transitions and four side travel checks passed in Godot. User review, run animation feel, collision fit and device performance remain open (T-040/T-011).

- [x] T-066 User-requested: create a central grass field surrounded by snow, desert, volcanic and factory areas with matching extracted decoration. Godot checked five zone groups, prop placement and clear routes, movement and sample views. User review, prop collision fit, original material fidelity, rights and target-device performance remain open (T-027/T-011).

- [ ] T-067 User-requested: refine field based on `screen-20261030-112808.mp4`: triple each area’s linear dimensions, correct meadow trees and prop scale, add walls and doors, and arrange meaningful themed decoration. User found the first pass too empty. A denser second pass includes themed backcountry, paths, cliff forms and landmarks; Godot checked all eight gate openings and four cardinal routes. User review of beauty, composition and scale remains required; off-road samples still show simpler scenery than the recording. Further scene dressing, collision fit, animation of doors if desired, and target-device performance remain open.

- [x] T-068 User-requested: ensure gates connect all neighboring regions and paths lead to them. Eight existing gates retained; two road branches connect each outer gate to adjoining regions. Godot checked eight route corridors, all gate openings and four player crossings. Visual review and mobile performance remain open under T-067/T-011.

- [x] T-069 User-requested: mark the field edge with rocks or cliffs and prevent running in place against its invisible limit. Added continuous biome-colored collision borders with recovered rock forms; checked four sides, corner collision samples and player idle at each edge. User review of joins and visuals and target-device performance remain open (T-067/T-011).

- [x] T-070 User-requested: replace straight roads with winding paths that lead to open gates and never to the outer border. Sixteen seeded curve segments connect all eight gates; Godot checked gate connections, sampled collision clearance and distance from the outer border. User visual review and mobile performance remain open (T-067/T-011).

- [ ] T-071 User-reported: heroes can pass through rocks and other objects. Screenshots: `previews/user-reports-2026-10-30/desert-rock-overlap.png` and `previews/user-reports-2026-10-30/factory-object-overlap.png`. User subsequently requested fixes: mesh-derived prop colliders, larger roadside landform colliders and a wider hero capsule were implemented; four-sided physics checks passed for a desert rock, factory barrel and factory rock. Factory pipes became intentionally walkable in D-064. User review, other objects and other hero poses remain open.

- [ ] T-072 User-reported: the terrain-edge cliffs do not look like cliffs; see `previews/user-reports-2026-10-30/desert-border-appearance.png`. User subsequently requested a fix: the flat generated perimeter was replaced with overlapping recovered cliff forms; desktop views and collision checks passed. User review and refinement remain open.

- [x] T-073 User-requested: enrich all five regions with distinct object types and buildings. Added 15 curated locations, imported 14 additional recovered mesh sets and constructed simple workshop/forge buildings; desktop placement, gate, movement and representative collision checks passed. User review, visual refinement and device performance remain open under T-067/T-011.

- [x] T-074 User-requested: let heroes walk across flat ground debris and very small rocks. Factory pipe/elbow/scrap/gear types, low props and small scaled rocks are nonblocking; Godot tested representative passage and larger solid objects, routes and movement. User review remains open under T-071.

- [x] T-075 User-requested: create a Windows PC prototype build. Added Windows x86-64 export preset, packaged EXE and PCK in `builds/MovementPrototype-Windows-2026-10-30.zip`, checked ZIP integrity and launched the packaged hero menu and field. User play review and broader Windows compatibility remain open under T-067/T-011.

- [x] T-076 User-requested: create an Android APK of the current prototype. Godot exported and debug-signed ARM64/x86-64 APK, signature and package contents were checked, and Android 15 emulator menu, field and simulated joystick movement were smoke-tested with host graphics. Phone compatibility and performance remain open under T-011.

- [ ] T-077 Partly authorized and completed: user requested ARM64 only, and the smaller phone APK is exported (D-067). Further model/animation and texture optimization remains proposed, not yet authorized. Current 190,378,410-byte debug APK includes roughly 94.3 MiB imported scenes (Mars alone 32.6 MiB), 27.4 MiB x86-64 libraries, 24.7 MiB ARM64 libraries and 27.0 MiB imported textures. Consider safe animation/model and texture optimization, then validate the entire roster and target devices. Do not remove heroes without approval.

- [x] T-078 User-requested: create ARM v8-only Android APK. Godot exported debug-signed ARM64-only APK; package architecture, included catalog and signature verified. Physical ARM64 device testing remains open under T-011.

- [x] T-079 User-authorized (D-068): build a compact 168 x 168-unit Meadowlands region from reusable elevation pieces (terrace and ramp, cliff borders, bridge, stream and pond, crop plots, scatter) in `game/scenes/meadow.tscn`; legacy field preserved. Traversal and regression checks passed.

- [x] T-080 User-authorized (D-068): add blob contact shadows and revised lighting without enabling cast shadows. User confirmation that blob shadows fit D-030 is pending under T-083.

- [x] T-081 User-authorized (D-068): unify meadow environment style with generated low-poly trees, bushes, rocks, grass, flowers, crops and haystacks.

- [x] T-082 User-authorized (D-068): review gameplay-camera screenshots after each pass; images in `previews/meadow-v001-2026-11-05/`.

- [ ] T-083 User review: play the Meadowlands region and judge composition, density, scale, blob shadows, colors and whether 30 units/second feels too fast for the compact map. Complete when the user approves or requests changes.

- [ ] T-084 Proposal, not authorized: rebuild snow, desert, volcanic and factory as compact regions with the same kit, connected through the closed south track or new exits.

- [ ] T-085 Proposal, not authorized: measure Meadowlands performance on an ARM64 phone (see T-011); reduce scatter counts or merge meshes if needed.

- [x] T-086 User-reported: meadow ground rendered grey and the hero got stuck in the farm. Fixed the launch-time import, material parameters and non-climbable rounded colliders (D-069). Traversal and wander tests pass; user retest pending under T-083.

- [x] T-087 User-requested: ARM64 debug APK with the Meadowlands (`builds/android-2026-11-05/`, version 0.2). Signature, architecture and contents verified; phone testing open under T-011/T-085.

- [x] T-088 User-requested: make the Meadowlands region 2x bigger without adding a region (D-070). Now 336 x 336 with the original meadow in the centre; traversal and wander tests pass. User review pending under T-083; the APK needs rebuilding to include it.

- [x] T-089 User-requested: create an original samurai hero (Kaze) in the scene's style, then make him chunkier and more fun with a more detailed hat (D-071).

- [x] T-090 User-requested: remove Dota hero selection, start in the meadow with Kaze, portrait orientation, and auto-attack instead of an attack button (D-072). Dota and legacy files archived; tests pass.

- [ ] T-091 User review: play Kaze in portrait and judge his look, scale, auto-attack feel (reach, 45% movement while swinging) and the floating joystick.

- [x] T-092 (done as D-078) Proposal: real enemies to replace or join the training dummies (for example from the Butcher Hero enemy list or bought packs), with enemy health, hero health and rewards.

- [x] T-093 User-requested: rebuilt the ARM64 APK for the portrait Kaze build (`builds/android-2026-11-06/`, version 0.3, 32.6 MB). Phone test pending.

- [x] T-094 User-reported: stuck at the terrace shrine and uncomfortable ramps. The joystick now activates anywhere; ramps are wider, longer and gentler, with sloped banks. Tests pass; APK 0.4 built. User retest on phone pending.

- [x] T-095 User-reported: weird rendering at the bottom of the screen (fixed, D-073) and low fps on a Samsung A14 (performance pass, D-074). APK 0.6 built.

- [ ] T-096 User retest: frame rate on the Samsung A14 with APK 0.6. If it is still low, next options are fewer grass tufts, cheaper ground shader, lower render scale, or shorter view distance for cliff-top forests.

- [x] T-097 User-requested: Samurai II: Vengeance-style attack combos for Kaze (D-075). Four-step auto combo with finisher, trails, hit counter, hit-stop and shake. Auto-attack and traversal tests pass; APK 0.7 built. User review on phone pending.

- [ ] T-098 Proposal, not authorized: optional quick/strong attack buttons and a dodge roll, so different button orders give different combos (as in Samurai II), alongside or instead of auto-attack.

- [ ] T-099 User retest: A14 frame rate with APK 0.9 (per-vertex lighting, 65% render scale, D-076).


- [x] T-100 User-requested: Toony Tiny soldiers, one per clearing, different types (D-078). APK 0.11.
- [ ] T-101 User review: soldier difficulty, sizes, animations and hero health on the A14.
- [ ] T-102 Proposal, not authorized: bake the original Toony Tiny animations in the Unity Editor on the user's PC; add the mounted knight with a horse; rewards or a counter for defeated soldiers.

- [x] T-103 User-requested: progression rules, Reaper, Blood Knight, Plague Knight, hero experience and levels (D-080). APK 0.13.
- [ ] T-104 User review on the A14: balance (soldier health versus 1 starting damage, experience curve), NPC placement, HUD readability.
- [x] T-105 In-game reset progress button (D-086, v0.20).

- [x] T-106 User-requested: region final boss and gate, 1 hour for region 1 and +1 hour per region, 30 s fight rule (D-085). APK 0.19.
- [ ] T-107 User review: boss difficulty and timing in real play; whether the Blood Knight "fall every swing" farming should be limited.
- [ ] T-108 Next region content (the gate currently shows "coming soon").
