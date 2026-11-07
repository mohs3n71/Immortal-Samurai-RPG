# Prototype hero size audit

The values and comparisons below record earlier work. D-055 retains catalog/menu values and doubles each assembled hero visual only in the field; field collision fit remains open.


Date: 2026-10-29. The initial audit below records the earlier unit-scale implementation; D-040 later replaced it with extracted Dota multipliers, as detailed at the end.

At the time of the initial audit, all 12 `Visual` nodes had scale `(1, 1, 1)`; `game/scripts/character_visual.gd` did not assign hero-specific scale. The imported models and their equipment nevertheless have different dimensions and poses. `game/tests/inspect_hero_scale.gd` reports each body's imported mesh bounds in visual-local coordinates. Body bounds omit equipment and may not represent the animated silhouette; for example, Juggernaut's pants and Abaddon's mount are separate attachments.

For a more directly visible comparison, `game/tests/capture_hero_scales.gd` rendered each assembled hero in one sampled idle pose on the same 1280 × 720 viewport, with the same orthographic camera size 22 and terrain location. Captured the scene once with the hero hidden, then used Pillow to compute each image's difference from that background, ignoring per-pixel brightness differences of 12/255 or less. The following approximate screen-space bounding heights include visible weapons, wings, mounts and tails. They are not physical heights, do not cover animation, and should not be treated as desired scale targets.

| Hero | Visible bounding height (pixels) |
| --- | ---: |
| Juggernaut | 124 |
| Abaddon | 202 |
| Axe | 180 |
| Centaur Warrunner | 196 |
| Doom | 270 |
| Earthshaker | 183 |
| Elder Titan | 306 |
| Mars | 346 |
| Riki | 104 |
| Sand King | 213 |
| Tidehunter | 199 |
| Undying | 147 |

The much taller silhouettes of Mars and Elder Titan include long weapons; sizes vary by character and pose even with the same camera and node scale. Differences can contribute to a perception of changing zoom, but this does not establish the cause of the user's earlier reported first-selection behavior (T-041). The shared collision capsule also does not account for all these shapes (T-040). After the user reported distorted relative sizes in the menu, D-039 replaced preview-only per-hero camera zooms with one common camera and unit visual scale, retaining the models' imported relative sizes. This changes presentation, not the actual model scales or the unresolved production gameplay sizing decision (T-043).

## Dota 2 source settings and limitations

The user asked whether Mars is actually taller than Tidehunter in Dota 2. The local extractor's metadata, outside this repository under `../Hero Extractor/Dota2-Model-Extractor/outputs/metadata/scripts/npc/heroes/`, lists `ModelScale` 0.90 for Mars and 0.84 for Tidehunter; it also lists `LoadoutScale` 0.90 and 0.84 respectively. Those are per-hero multipliers applied to different base meshes, not absolute heights. At the time of this inquiry the prototype used unit scale and did not apply these Dota settings; the later D-040 change applies them but does not by itself prove authentic Dota proportions.

The earlier Godot inspection found raw imported body-mesh bind-pose AABB heights of approximately 6.17 units for Mars and 5.41 for Tidehunter. These bounds exclude separate equipment and do not establish their actual posed, scaled or rendered in-game height. The scale metadata and bind-pose bounds alone do not establish a definitive in-game height comparison. Confirm with a controlled same-camera in-game view, matching game version, default appearance, poses and modifiers (T-049). No hero sizes or source files were changed during this inquiry.

## Applied model multipliers (D-040)

The user requested using the extracted `ModelScale` for all selectable heroes in both contexts. The original D-040 source values below came from each `assets/characters/<id>/source/gltf-v001/manifest.json`-linked extractor hero script under `../Hero Extractor/Dota2-Model-Extractor/outputs/metadata/scripts/npc/heroes/`. `character_visual.gd` applies the multiplier to the assembled visual, including equipment. The common collision capsule is unchanged. D-041 and D-042 subsequently adjusted catalog values as recorded below; desktop tests verify the current field and menu nodes for all heroes.

| Hero | ModelScale | Source hero script |
| --- | ---: | --- |
| Juggernaut | 0.85 | `npc_dota_hero_juggernaut.txt` |
| Abaddon | 0.78 | `npc_dota_hero_abaddon.txt` |
| Axe | 1.00 | `npc_dota_hero_axe.txt` |
| Centaur Warrunner | 0.74 | `npc_dota_hero_centaur.txt` |
| Doom | 0.86 | `npc_dota_hero_doom_bringer.txt` |
| Earthshaker | 0.93 | `npc_dota_hero_earthshaker.txt` |
| Elder Titan | 0.75 | `npc_dota_hero_elder_titan.txt` |
| Mars | 0.90 | `npc_dota_hero_mars.txt` |
| Riki | 0.87 | `npc_dota_hero_riki.txt` |
| Sand King | 0.84 | `npc_dota_hero_sand_king.txt` |
| Tidehunter | 0.84 | `npc_dota_hero_tidehunter.txt` |
| Undying | 0.93 | `npc_dota_hero_undying.txt` |

A multiplier scales its own base model; it is not an absolute height. Exact Dota presentation and per-hero collision fit remain unverified.

## User-requested runtime adjustments (D-041)

These D-041 changes were relative to the original values above and applied in both the menu and field; D-042 subsequently revised three of them and adjusted two other heroes.

| Hero | Source scale | Requested change | Runtime scale |
| --- | ---: | --- | ---: |
| Juggernaut | 0.85 | 20% bigger | 1.02 |
| Centaur | 0.74 | 5% bigger | 0.777 |
| Doom | 0.86 | 5% smaller | 0.817 |
| Earthshaker | 0.93 | 5% bigger | 0.9765 |
| Riki | 0.87 | 10% bigger | 0.957 |
| Tidehunter | 0.84 | 10% bigger | 0.924 |

The shared gameplay collision capsule remains unchanged; per-hero collision fit is still open (T-040).

## Further runtime adjustments (D-042)

The following increases are relative to the D-041 runtime values and apply in both menu and field.

| Hero | Previous scale | Increase | Current scale |
| --- | ---: | ---: | ---: |
| Juggernaut | 1.02 | 10% | 1.122 |
| Abaddon | 0.78 | 5% | 0.819 |
| Riki | 0.957 | 15% | 1.10055 |
| Tidehunter | 0.924 | 10% | 1.0164 |
| Undying | 0.93 | 5% | 0.9765 |

