# Extracted environment models

Last updated: 2026-10-29. The user reported three extracted trees and three rocks alongside newly extracted heroes; the complete extractor output was copied to [extracted-dota-v001](extracted-dota-v001/README.md). These are Valve/Dota 2 assets; game-use and distribution rights are unresolved (T-014). The copy does not select them as final level assets.

| Model | glTF | GLB |
| --- | --- | --- |
| Oak tree | [oak.gltf](extracted-dota-v001/trees/oak/usable/gltf/oak.gltf) | [oak.glb](extracted-dota-v001/trees/oak/usable/glb/oak.glb) |
| Pine tree | [pine.gltf](extracted-dota-v001/trees/pine/usable/gltf/pine.gltf) | [pine.glb](extracted-dota-v001/trees/pine/usable/glb/pine.glb) |
| Dire tree | [dire.gltf](extracted-dota-v001/trees/dire/usable/gltf/dire.gltf) | [dire.glb](extracted-dota-v001/trees/dire/usable/glb/dire.glb) |
| Land rock | [land_rock.gltf](extracted-dota-v001/rocks/land_rock/gltf/land_rock.gltf) | [land_rock.glb](extracted-dota-v001/rocks/land_rock/glb/land_rock.glb) |
| River rock | [river_rock.gltf](extracted-dota-v001/rocks/river_rock/gltf/river_rock.gltf) | [river_rock.glb](extracted-dota-v001/rocks/river_rock/glb/river_rock.glb) |
| Dire rock | [dire_rock.gltf](extracted-dota-v001/rocks/dire_rock/gltf/dire_rock.gltf) | [dire_rock.glb](extracted-dota-v001/rocks/dire_rock/glb/dire_rock.glb) |

The complete copy includes the extractor's original unfiltered and `usable` tree variants, reports, manifest and ZIP. The extractor identifies the `usable` trees as filtered static meshes; no wind animation is included. Keep adjacent PNG and BIN files with the models, including GLBs that refer to external textures. Extractor manifest absolute paths are historical, not portable references.

Copies were SHA-256 checked and external references verified. These variants were imported and visually checked in the desktop terrain prototype (D-024); performance remains unmeasured. The extractor's validation report is retained as historical evidence.

## Grass clumps

The user reported newly extracted grass models; the complete [grass pack v001](grass-extracted-dota-v001/README.md) was copied separately without replacing the tree/rock set. It contains three static grass-card variants, with glTF, GLB, textures, reports and a ZIP:

| Model | glTF | GLB |
| --- | --- | --- |
| Grass clump A | [grass_clump_00a.gltf](grass-extracted-dota-v001/grass/grass_clump_00a/gltf/grass_clump_00a.gltf) | [grass_clump_00a.glb](grass-extracted-dota-v001/grass/grass_clump_00a/glb/grass_clump_00a.glb) |
| Grass clump B | [grass_clump_00b.gltf](grass-extracted-dota-v001/grass/grass_clump_00b/gltf/grass_clump_00b.gltf) | [grass_clump_00b.glb](grass-extracted-dota-v001/grass/grass_clump_00b/glb/grass_clump_00b.glb) |
| Grass clump C | [grass_clump_00c.gltf](grass-extracted-dota-v001/grass/grass_clump_00c/gltf/grass_clump_00c.gltf) | [grass_clump_00c.glb](grass-extracted-dota-v001/grass/grass_clump_00c/glb/grass_clump_00c.glb) |

All 32 files match their originals by SHA-256 and dependencies in the six model files resolve. Extractor records describe alpha-cutout materials and static geometry without wind effects; all three were imported and visually checked in the prototype. Performance remains open. The same unresolved Valve rights apply.

## Cliff walls

The user extracted cliff walls for the map's outer border. The complete [cliff pack v001](cliff-extracted-dota-v001/README.md) is preserved separately, including textures, BIN files, reports and ZIP:

| Section | glTF | GLB |
| --- | --- | --- |
| Cliff wall 001 | [cliff_wall001.gltf](cliff-extracted-dota-v001/cliffs/cliff_wall001/gltf/cliff_wall001.gltf) | [cliff_wall001.glb](cliff-extracted-dota-v001/cliffs/cliff_wall001/glb/cliff_wall001.glb) |
| Cliff wall 002 | [cliff_wall002.gltf](cliff-extracted-dota-v001/cliffs/cliff_wall002/gltf/cliff_wall002.gltf) | [cliff_wall002.glb](cliff-extracted-dota-v001/cliffs/cliff_wall002/glb/cliff_wall002.glb) |
| Cliff wall 003 | [cliff_wall003.gltf](cliff-extracted-dota-v001/cliffs/cliff_wall003/gltf/cliff_wall003.gltf) | [cliff_wall003.glb](cliff-extracted-dota-v001/cliffs/cliff_wall003/glb/cliff_wall003.glb) |

All 38 copied files match their originals by SHA-256, and external references in all six model files resolve. The extractor identifies these as static terrain props. All three were imported and placed along the prototype border; visuals were checked in Godot. Joins, the collision approach and performance require further review; Valve game-use and distribution rights remain unresolved.

## Prototype runtime copies

`game/assets/environment/` contains previously copied GLB/PNG assets and new recovered static props under `butcher-props/`. The current field uses a center meadow and four decorated outer areas, with perimeter cliffs built from existing recovered meshes (D-062); original tree, rock, grass and cliff assets remain preserved. The playable square measures 900 x 900; desktop Godot layout, movement and gate checks passed. Prop collisions are approximate, and target-device performance remains unmeasured.

## Five-area prop and factory assets

[factory-floor-v001.png](butcher-meadowlands/factory-floor-v001.png) is an unchanged copy of `unity-meadowlands/Assets/Texture2D/FactoryGround1_0.png`; the runtime copy matches by SHA-256. This is an approximation of a factory floor, not proof of the original missing material appearance.

Fifty-five static OBJ/MTL/PNG prop sets under `game/assets/environment/butcher-props/` were exported from recovered Unity meshes and color textures by `unity-meadowlands/Assets/Editor/Meadowlands/MeadowlandsPropExport.cs`, which lists each source mesh and material. Unity Editor 6000.6.7f1 wrote converted coordinates and handedness; Godot imported and rendered them. The current field uses upright previously copied Dota oak/pine for the meadow and snow-shaded pine in snow, plus recovered Arctic trees/crates/houses, desert cacti/wagons, volcanic rocks and arches, factory machinery and platforms, mine entrances, region-specific cliff forms and gate posts. Small generated grass tufts and pebbles supplement the recovered objects. The latest 14 sets include recovered houses, a tent, crystals, factory equipment, a skull and a grave marker; 15 themed locations use a selection of them (D-063). The mining-house mesh is incomplete and is not placed. Unused candidates remain preserved for possible future use. Two simple factory/forge buildings are generated in `game/scripts/field_sites.gd`. Missing Unity shaders, original effects, fine collision fit and full visual fidelity are not reconstructed. The recovered game assets are copyrighted, rights unresolved, and the source project's instructions prohibit redistribution.

## Meadowlands floor texture

[meadowlands-floor-v001.png](butcher-meadowlands/meadowlands-floor-v001.png) is an unchanged copy of `unity-meadowlands/Assets/Texture2D/RGB_Grass_0.png`, recovered from the user-supplied Butcher Hero Unity export. The runtime copy is `game/assets/environment/meadowlands-floor-v001.png`. Both match the Unity file by SHA-256. Its use in the flat Godot floor is an approximation of the Unity preview; original shader behavior is unavailable. Recovered artwork is copyrighted, rights are unresolved, and the source project says not to redistribute it.

## Desert and volcanic floor textures

[desert-floor-v001.png](butcher-meadowlands/desert-floor-v001.png) and [volcanic-floor-v001.png](butcher-meadowlands/volcanic-floor-v001.png) are unchanged copies of `unity-meadowlands/Assets/Texture2D/sandHandpaint texture2_0.png` and `Ground_Volcanic_0.png`, respectively. Runtime copies are under `game/assets/environment/` and match those Unity sources by SHA-256. The snow quadrant uses the sand texture with an approximate Godot blue-white shader, since the recovered Unity shader is a placeholder. Recovered artwork is copyrighted, rights unresolved; the source project says not to redistribute it.

## Dirt paths

[dirt-path-v001.png](butcher-meadowlands/dirt-path-v001.png) and `game/assets/environment/dirt-path-v001.png` are unchanged copies of `unity-meadowlands/Assets/Texture2D/Ground_1_0.png`; all three SHA-256 hashes are `66589e55ccec0e79a2e37b664c98d1efc301c38f572681604b2e25c015285a85`. The Godot path shader colors and softens this texture per region; it is an approximation, not the recovered shader. Source mesh mappings are in `unity-meadowlands/Assets/Editor/Meadowlands/MeadowlandsPropExport.cs`. Recovered asset rights remain unresolved.
