# Ember Ronin (working name)

Updated: 2026-10-29. ID: ember-ronin. Current review candidate: **v002**, more realistic/aggressive revision. **Not approved for game use.** v001 is preserved; the user rejected its childish visual style.

## Brief and identity

User requested the first game character based on Dota 2 Juggernaut, an actual 3D model and preview before confirming use. The subsequent request explicitly asks for more realism/aggression. Temporary name and specific geometry/material choices are assistant interpretations, not approved final design. No predecessor asset is adopted.

Reference: [Valve hero page](https://www.dota2.com/hero/juggernaut), [official render](references/juggernaut-official-reference.png) from https://cdn.cloudflare.steamstatic.com/apps/dota2/videos/dota_react/heroes/renders/juggernaut.png, downloaded and inspected 2026-10-29. Observed inspiration: ivory face covering, exposed muscular torso/arms, red layered waist armor, dark bracers and curved sword. Valve artwork remains reference only, not a game texture/model; rights/design clearance are not asserted.

Preserved identity: ivory mask with ember slits and central bronze seam, dark swept hair/topknot, warm skin, asymmetric crimson/charcoal armor, muted teal cloth and curved sword. v002 revises these with smaller head/hair proportions, continuous anatomical skin rather than detached muscle balls, long legs/wide planted stance, thin curved plates, dark weathered materials, narrow downward-angled eye slits and a nine-degree lowered head. Preserve this identity unless the user requests further redesign.

## Current v002 assets

| Asset | Facts |
| --- | --- |
| [Editable Blender model](models/ember-ronin-v002.blend) | Actual geometry plus studio camera/lights; full procedural materials; Blender 4.5.9 LTS |
| [Static GLB](models/ember-ronin-v002.glb) | Character/weapon only; no studio, skinning or animation; constant PBR material values |
| [Studio preview](renders/preview-v002.png) | 1600 x 1600, rendered from actual model |
| [Model sheet](renders/model-sheet-v002.png) | 2400 x 1360, orthographic front/side/back |
| [Fighting stance](renders/fighting-stance-v002.png) | 1500 x 1500, separate full-body, screen-right-facing, full sword visible |
| [Head icon](renders/head-icon-v002.png) | 1024 x 1024, square frameless RGBA with transparent background; shoulders/headband tail cropped as a portrait |
| [Turntable](renders/turntable-v002.gif) | 640 x 640, 24 rendered camera-orbit frames, 110 ms each; not a character animation clip |
| [Geometry report](models/validation-v002.json) / [export checks](models/export-checks-v002.json) | Actual counts/bounds and blend reopen / GLB reimport evidence |
| [Image checks](renders/image-checks-v002.txt) | Dimensions/alpha evidence |

Front/side/back component PNGs and 24 turntable frame PNGs are retained. renders/preview-fit-check-v002.png is an intermediate fit/material check, superseded by preview-v002.png. Exact procedural instructions are executable code, not image-generation prompts: see [tooling](../../../tools/README.md).

## Archive and limitations

v001 model, artwork, check reports and source scripts remain preserved under their original names. See [old model](models/ember-ronin-v001.blend), [old preview](renders/preview-v001.png) and [history](HISTORY.md). No current v002 design approval is inferred from the revision request.

Source is Z-up, facing -Y; GLB is glTF Y-up. Bounds in the report include sword/hair and are draft authoring meters, not approved game scale. Skin is a voxel-fused sculpt; other equipment/cloth parts remain separate and intersect in places. This remains a stylized approval draft, not a photoreal production character or deformation-ready mesh.

**Material limitation:** pores/grain/wear use Blender procedural shader nodes. They are visible in the blend/renders; the GLB retains constant base PBR values until baking. No texture maps, authored production UV layout (some primitives have default UVs), rig, weights, animation, retopology, LODs, collision, engine integration or Android performance validation exists. The higher-detail sculpt has no approved mobile budget. Further fit/detail cleanup may follow design approval.

Rendering: Cycles OptiX, denoised 64-sample stills and 24-sample turntable. No image-generation tool or external model/texture used. See [history](HISTORY.md), [tasks](TODO.md), [project instructions](../../../AGENTS.md).
