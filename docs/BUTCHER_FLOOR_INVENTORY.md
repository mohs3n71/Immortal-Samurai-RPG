# Recovered Butcher Hero ground-material inventory

Date: 2026-10-30. User asked how many floor types exist in the recovered Unity export and suggested grass, desert, snow and another type. This is a material-name and reference inventory, not a verified count of original game biomes or appearances.

Inspected `../../Butcher Hero/ButcherHeroReconstruction/unity_project/ExportedProject/Assets/Material/` for materials referring to `Assets/Shader/Mobile_Diffuse Ground.shader` (GUID `a0add8d02e881394e9837dd8a439bf78`): 52 material files and 24 distinct serialized `m_Name` values. The files include repeated names/export variants; one material name does not necessarily equal one biome or visibly unique floor. Other shaders and floor meshes may add more types.

Names: Boss_ice, Boss_ice 1, CEMETERY_front_01, CEMETERY_front_01 2, CEMETERY_front_01 3, CEMETERY_front_03, CEMETERY_front_03 2, CEMETERY_front_03 3, CandyLandFloor, CraterFloor, FactoryLevelFloor, Grass, Grass Frozen, Grass Meadowlands, GrassIsland, ItalyGrass, LostIslandsFloor, MansionFloor, PirateCoveFloor, Sand, Snow, VolcanicRock, VolcanoeFloor, WesternDirt.

Representative material references in the recovered export:

- Grass Meadowlands → `Texture2D/RGB_Grass_0.png`; also GrassIsland and Grass variants. The Meadowlands texture is already used in the Godot prototype.
- Sand, LostIslandsFloor, PirateCoveFloor → `Texture2D/sandHandpaint texture2_0.png`.
- Snow → the same `sandHandpaint texture2_0.png` source with different serialized mask colors and other material parameters. Copying that PNG alone cannot reproduce snow.
- VolcanicRock → `Texture2D/Ground_Volcanic_0.png`; VolcanoeFloor and WesternDirt → `Texture2D/Ground_1_0.png`, with different parameters. The names support volcanic and dirt variants; no original in-game appearance has been verified.
- CandyLandFloor, FactoryLevelFloor and Grass Frozen → `Texture2D/Grass_1_0.png`, with differing material properties; MansionFloor uses `Texture2D/MansionFloor1_0.png`; cemetery and ice-boss materials refer to `Texture2D/Grass_corrupted_down_0.png`.

The recovered shader is a dummy that outputs white; original material behavior is not restored. The Unity preview used Standard-shader approximations, so appearance, visual differences, region placement and completeness remain unverified. No assets were copied or game files changed for this inventory. The recovered assets are copyrighted, rights unresolved, and the source project's instructions say not to redistribute.
