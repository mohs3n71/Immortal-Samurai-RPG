# Butcher Hero scene assessment

Date: 2026-10-30. User requested recreating the scene from the separate `ButcherHeroReconstruction` Unity project in this Godot project and authorized copying needed files. This is an assessment, not an implementation.

The supplied reconstruction at `../../Butcher Hero/ButcherHeroReconstruction/` contains an AssetRipper export with `Assets/Scenes/Boot.unity` and `Main.unity`. Its source records describe the export as unvalidated, with dummy shaders; the original XAPK must remain untouched and recovered assets must not be redistributed. Source project records are external to this folder.

The supplied transform index lists 14,900 Main transforms. Traversal of parent IDs finds 12,521 transforms under `map`, with 44 direct children. These include LostIslands, VolcanicLevel, PirateCoveLevel, Italy, SwampIsland, Cemetery, FrozenForest, FrozenLands, CandyLandLevel, SandLands, ArcticLevel, WildWest and FactoryLevel, along with shared water, portals and other objects. This is a collection of regions, so the desired initial view/region needs clarification. A Main scene text count found 8,836 MeshFilter, 8,439 MeshRenderer and 64 SkinnedMeshRenderer records; these are not counts of successfully recoverable or visible objects.

Mesh files under the export's `Assets/Mesh` are Unity `.asset` YAML; at least the inspected example stores compressed vertex, UV and index data. Godot cannot directly use these as native meshes. Reconstruction requires resolving scene object/mesh/material GUID links, decoding or exporting mesh data, handling hierarchy and coordinate conversion, mapping textures and approximating missing shaders, and choosing a suitable camera and integration with the existing prototype. Active flags, collisions, scripts, effects, animation, complete material fidelity and original runtime behavior remain unverified. The transform index contains local rather than world transforms. No conversion, asset copying, Godot import, or visual comparison has occurred.

T-059 tracks the requested work. Keep the existing field intact until the reconstructed scene is implemented and checked. Rights to the recovered game content remain unresolved.

## Meadowlands selection

The user selected Meadowlands first (D-049). The material `Grass Meadowlands_0.mat` is referenced by eight land meshes under `map/island (1)` and by a pond object under `map/camp`; this supports a provisional subtree identification, not an authoritative region boundary. The index at `../assets/environment/butcher-meadowlands/scene-index.json` lists the subtree local transforms and resolved source references. Its 767 mesh filters comprise 713 external references, 44 Unity built-in references and 10 null meshes; 802 material references resolve. No actual geometry, material conversion or rendering has been verified.

## Separate Unity draft

D-050 supersedes the Godot conversion request: the user requested a separate Unity reconstruction and retaining the Godot project. See `../unity-meadowlands/README.md` and T-060. The generated static scene retains the identified subtree but remains unimported and visually unverified; dummy shaders require material repair.

## Unity import and visual check

Unity 6000.6.7f1 imported the separate working copy and rendered `../previews/meadowlands-unity/material-preview.png`. The provisional subtree shows the Meadowlands ground and an arena, but lacks surrounding environment. Approximate Standard materials use recovered texture/color properties; original shader fidelity is not established. Unity reopened the preview and reported 10 null meshes and two missing material slots; see T-060 and PROGRESS.md for details.
