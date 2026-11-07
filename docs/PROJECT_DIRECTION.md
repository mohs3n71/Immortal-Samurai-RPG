# Project direction

Last updated: 2026-10-29. Source: user's project brief; decisions D-003 through D-005.

## Confirmed requirements

- A 3D Android game with an isometric camera.
- Godot engine and GDScript as the initial game language (D-014); production engine version remains open.
- Use a virtual Android device for initial Android tests, per user preference (D-015); Android builds are made only when requested (D-019).
- Routine development and tests run in Godot; create Android builds when the user requests them (D-019).
- First prototype: landscape, Juggernaut walking in a location using on-screen directional controls with an isometric camera (D-018).
- Prototype terrain: a square with grass, randomly placed trees and rocks, and previously extracted cliffs at the outer border (D-024). Original center-to-side travel was 15 seconds; doubling movement speed without resizing the terrain changes this to 7.5 seconds (D-027).
- Use a flat textured grass floor without 3D clumps for now, with large solid rocks (D-032).
- No scene shadows, as requested by the user (D-030).
- Provide a prototype hero selection menu; exclude Underlord, Primal Beast and Shadow Fiend from its list (D-035).
- The selection screen should have official hero portraits across the top and the selected hero's idle animation below, with a Dota-like stylish presentation (D-036).
- The selection background fills the screen behind the portrait list, without an inset hero border; hero previews should meet the illustrated ground and use a shared camera and each hero's catalog multiplier, with subsequent user-requested adjustments (D-038/D-039/D-040/D-041/D-042).
- The desktop test prototype supports WASD and arrow-key movement, alongside the on-screen joystick (D-047).
- All 12 selectable heroes have an on-screen attack animation control (D-045/D-046); combat mechanics are not implemented.
- Begin with 3D models and animations. The first confirmed models are extracted Axe, Juggernaut and Shadow Fiend (D-009); the production animation set is not selected.
- Maintain decisions, tasks, progress, validation, limitations and unresolved questions for future contributors.
- Require clean, readable code, meaningful naming, consistent style, focused files and small cohesive functions. See [coding standards](CODING_STANDARDS.md).
- The user selected three extracted models for project use (D-009); rights, animated equipment assembly and runtime validation are unresolved. Ember Ronin remains an unapproved draft.
- User rejected the initial childish character style and requested more realism/aggression; the v002 revision is the current review candidate, not an approved final art direction for all characters.

## Gameplay candidates, not commitments

1. A Diablo-like action RPG, possibly featuring multiplayer PvE and PvP. Diablo is a gameplay reference; no particular art style, classes, loot system or world structure is approved.
2. An isometric game focused only on multiplayer PvP. Match format, combat rules and progression remain open.

Neither candidate nor a networking architecture is selected. Do not infer implementation authorization from these possibilities.

## Open choices

- Gameplay direction, core combat loop, controls and multiplayer scope.
- Exact camera angle, orthographic versus perspective projection, zoom and rotation behavior. The isometric request does not specify these settings.
- Production Godot version, modeling tools, model sources and licenses, rigging and animation workflow.
- Final first-character design/style approval and animation set. Juggernaut is the confirmed inspiration; Ember Ronin is the assistant's temporary draft name.
- Android target devices and performance budgets, including model, texture and animation constraints.
- Networking architecture, hosting and synchronization requirements if multiplayer proceeds.
- Final game name. The existing folder name is temporary, not a genre commitment.

## Next production boundary

The three selected models are copied and documented; resolve rights and scope animation assembly and engine validation before distribution or runtime adoption. Portable Blender is a reversible preview tool, not a final pipeline selection. Idle and walk remain an earlier proposed milestone, not an approved animation set.

Characters still require local README/HISTORY/TODO and concept/model sheet, fighting-stance picture and head icon under [AGENTS.md](../AGENTS.md). Artwork does not establish model, rig, animation or runtime readiness. Preserve source assets and document versions, provenance and actual checks.
