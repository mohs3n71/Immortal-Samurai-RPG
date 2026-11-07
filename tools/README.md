# Character draft tooling

For the nine Dota 2 source-reference renders, `prepare_extracted_reference.py` stages copies of glTF files and selects one idle clip; `render_extracted_reference.py` renders posed views and a head icon with Blender 4.5.9. `render_extracted_head_refine.py` creates a tighter v002 head view without obstructing weapon or shield meshes. These helpers run from the repository root, target character IDs and write into their `artwork/` folders; use new filenames/versions before rerunning to avoid overwriting current references. The samples show one pose and do not establish a production rig. Model sheets were composed from the three renders using Pillow; exact per-character pose names and limitations are in their local histories.

These are asset-authoring helpers, not a chosen game stack. Python follows descriptive snake_case functions/variables, PascalCase only if classes become necessary, four-space indentation, and small cohesive modules. No game architecture is selected.

- `character_geometry.py`: reusable simple mesh primitives and materials.
- `ember_ronin.py`: the v001 character geometry and draft palette.
- `render_character.py`: export, actual-geometry rendering and statistics.
- `validate_character.py`: reopen blend and reimport GLB; check triangle consistency and absence of studio objects in GLB.
- `package_character.py`: Pillow model-sheet layout, GIF encoding and image/alpha checks. Run with Python plus Pillow after rendering.
- `ronin_v002_body.py`: continuous torso/anatomy, joined skin remesh, adult legs/hands.
- `ronin_v002_surfaces.py`: worn materials and thin curved armor surfaces.
- `ronin_v002_equipment.py`: mask, hair, fitted harness, layered armor and katana.
- `render_ronin_v002.py`: v002 build/export/render pipeline, preserving v001 deliverables.

For the user-requested mature v002 revision:

```powershell
& ./.tools/blender-4.5.9-windows-x64/blender.exe --background --python tools/render_ronin_v002.py
& ./.tools/blender-4.5.9-windows-x64/blender.exe --background --python tools/validate_character.py -- v002
python tools/package_character.py --version v002
```

The last command needs Pillow. The scripts intentionally target versioned outputs. Use a new version for later reviewed revisions. v002's full procedural surface detail is in the blend source; GLB contains constant PBR fallback values until texture baking. These sources create an approval sculpt and do not create a production rig, animation or optimized Android mesh.

Run from the project root using portable Blender 4.5.9:

```powershell
& ./.tools/blender-4.5.9-windows-x64/blender.exe --background --python tools/render_character.py
```

This recreates **v001** and its renders. Preserve current deliverables and change the version/path constants before authoring a future version. Do not silently overwrite a reviewed reference. The source has no imported Dota model or texture. All character geometry is procedural; Valve's PNG is a separately stored visual reference only.

`.tools/` contains an ignored, local portable authoring download, not a permanent system installation. Blender 4.5.9 Windows x64 ZIP official SHA-256 verified: `41da973b9bf95bb312cbeff4d1982feb13259b43c821686b9bafea4dfe5477cf`. Source: https://download.blender.org/release/Blender4.5/ and its `blender-4.5.9.sha256` file. No Blender binaries need to accompany the game asset. Source project and GLB remain the portable deliverables.
