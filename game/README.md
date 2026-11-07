# Movement prototype

**Current game (2026-11-06, D-071/D-072):** the project opens straight into `scenes/meadow.tscn` in portrait with Kaze (`assets/heroes/kaze/`, rebuilt with `--script res://tools/build_kaze.gd`). Kaze auto-attacks the training dummies near the village. Current tests: `tests/check_auto_attack.gd`, `tests/check_meadow_traversal.gd` and `tests/check_meadow_wander.gd` (run headless with `--fixed-fps 60`). The hero menu, Dota heroes, legacy field and their tests described further below are archived in `../archive/legacy-dota-2026-11-06/` and no longer run.

**Current field (2026-11-05, D-068):** **Enter the Field** opens the Meadowlands region (336 x 336 since D-070), `scenes/meadow.tscn`. It is composed from editor-visible nodes in `scripts/world/` and generated into `scenes/world/meadow_world.tscn` by `tools/build_meadow.gd` from the data in `tools/meadow_layout.gd`. To rebuild after editing the layout, run from the repository root:

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'game' --script 'res://tools/build_meadow.gd' -- mask
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'game' --import
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'game' --script 'res://tools/build_meadow.gd' -- scene
```

Rebuilding overwrites manual edits to `meadow_world.tscn`; small edits can instead be made directly in the editor by moving the prop, terrain and scatter nodes. Check walkable routes and blockers with `--script 'res://tests/check_meadow_traversal.gd'` (needs a window, not `--headless`). The legacy 900 x 900 five-area field described below is unchanged in `scenes/main.tscn`, and the older tests below still target it.

The Godot/GDScript prototype starts with a 12-hero selection menu. Select an official portrait at the top to see the hero's animated idle preview against a full-screen cinematic arena backdrop, then choose **Enter the Field**; use **Heroes** in the field to return to selection (D-036/D-039). All hero previews use the same camera, and each hero uses its catalog scale in the preview and twice that scale in the field (D-055); catalog values include the user’s previous adjustments (D-040/D-041/D-042). Press the steel-and-teal **sword button** at the bottom right to play the selected hero’s attack animation; movement pauses during the attack and resumes if input is still held. Attacks do not yet cause damage. Drag the on-screen joystick in any direction; on desktop, use a mouse, **WASD** or the arrow keys. The camera follows the character in the landscape isometric terrain. The initial test uses Godot 4.7.2 and the compatibility renderer; these are prototype choices, not final performance targets.

Underlord, Primal Beast and Shadow Fiend are omitted as requested. Hero equipment uses provisional bone mapping and selected idle/run clips; full animation fidelity, character size and collision fit require further review (D-035).

Hero visual scales are set per hero in the catalog; the [size audit](../docs/HERO_SCALE_AUDIT.md) records the original source multipliers and user-requested adjustments.

The field orthographic camera size is 44 units, twice its previous view height, after the user-requested zoom-out (D-053); the exact framing remains open to review.

The playable square measures 900 x 900 units. A 270 x 270 grass area sits at its center; snow lies toward negative Z, desert toward positive X, factory toward positive Z and volcanic ground toward negative X (D-057). The four outer areas and central meadow are three times their previous linear dimensions. At 30 units per second, unobstructed center-to-side travel takes 15 seconds. Recovered cliff forms mark the map edge, with continuous boundary collision; the player clamp remains a fallback. Movement animation uses actual horizontal movement, so the hero idles when blocked at the edge (D-060).

Stone walls divide neighboring areas. Eight decorated double-door gateways are fixed open; Seeded winding paths connect the meadow gates to regional junctions and the outer gates; none lead to the field boundary (D-061). Curved dirt routes connect groves and 15 curated regional sites, including meadow camps, snowy outposts, a desert settlement and mine, volcanic memorial and forge, and factory workshops; recovered cliff forms and small generated ground details add layers across the field. Meadow trees use upright Dota oak/pine assets; other props use recovered Unity meshes. Forge and factory buildings are simple assembled geometry; recovered houses and tents use approximate source materials (D-063). Solid props use mesh-derived convex colliders, landforms use bounding boxes, and tree trunks use cylinders; floor pipes, elbows, scrap, gears, platforms, very flat props and small rocks are nonblocking (D-064). The shared player capsule was widened (D-062); collider and animated-hero fit remain approximate. Layout and visuals are a second pass based on the user-supplied recording and remain less detailed than the reference; user review, target-device performance and rights remain open.

Grass, desert, factory and volcanic surfaces use recovered Unity-export textures. Snow uses the recovered sand texture with an approximate blue-white shader; the original shaders are unavailable.

Three earlier floor color alternatives are preserved in `../previews/floor-options-v001/`; the previously selected generated floor was replaced by the Meadowlands texture (D-052).

Cast shadows are disabled at the user's request (D-030); the scene retains its lighting and surface shading.

The prototype removes horizontal root travel from a runtime copy of Juggernaut's run animation so that the player controller moves him smoothly across animation loops; the imported source model is unchanged (D-025).

For Android testing, install `../builds/android-2026-10-30/MovementPrototype-Android-arm64-debug.apk` on an ARM64 phone with Android 7.0 or newer. This is a debug-signed prototype, not a store release; The previous combined-architecture APK was checked on the Android 15 emulator; the ARM64-only build has not been run on a phone (D-067).

For the standalone Windows build, extract `../builds/MovementPrototype-Windows-2026-10-30.zip` and run `MovementPrototype.exe`, keeping the PCK beside it (D-065). The packaged menu and entry into the field were checked on this machine; wider compatibility remains untested.

On this Windows machine, double-click `../Play Game.cmd` or the **Play 3D Fighter** desktop shortcut. The launcher calls `../tools/start-game.cmd`; both depend on the project-local Godot executable in `.tools/`. You can also run from the repository root:

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe' --path 'game'
```

Run the four-side terrain timing check with:

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'game' --script 'res://tests/check_terrain.gd'
```

Run the movement check from the repository root with:

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path 'game' --resolution 1280x720 --rendering-method gl_compatibility --script 'res://tests/check_movement.gd'
```

Check the five terrain areas and themed decoration placement with:

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'game' --script 'res://tests/check_five_areas.gd'
```

Check the eight gate openings and adjacent wall collisions with:

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'game' --script 'res://tests/check_gates.gd'
```

The old `tests/check_rock_collisions.gd` is historical and does not apply to the current layout.

Run the hero roster and menu checks with:

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'game' --script 'res://tests/check_hero_selection.gd'
```

To check every selected hero's live idle preview and capture desktop screenshots:

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path 'game' --resolution 1280x720 --rendering-method gl_compatibility --script 'res://tests/check_menu_preview.gd'
```

Run the camera switching check with:

```powershell
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'game' --script 'res://tests/check_camera_switching.gd'
```

`assets/juggernaut/`, `assets/heroes/` and `assets/environment/` contain runtime copies of extracted models, portraits and textures. Source files remain under the project-level character and environment asset folders. Game-use and distribution rights for Valve's assets remain unresolved. The equipment bone synchronization is adapted from the desktop experiment; full animation fidelity, target-phone performance, game controls, camera settings and asset pipeline remain to be validated. No original Source 2 visual effects are included.

The user prefers ongoing development and testing in Godot; create Android builds only when requested (D-019).
