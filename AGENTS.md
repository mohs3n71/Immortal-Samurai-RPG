# Project continuity instructions

These instructions apply throughout this repository. Any AI assistant working here should follow them. If your tool does not automatically read AGENTS.md, read it manually.

## Mandatory for every AI agent

This is an explicit user requirement for ALL AI agents and tools, not only Codex. Documentation is part of completing the task. Record all project-relevant decisions, progress, edits, creations, checks, failures that affect future work, todos, and unresolved questions. Update the records before handing work back; do not rely on chat history or private tool memory. If unable to write documentation, state that limitation and provide the exact pending updates in the handoff. Never claim documentation was updated when it was not.

## Start every session

1. Read docs/START_HERE.md, then docs/STATUS.md and docs/TODO.md.
2. Read docs/DECISIONS.md and the recent entries in docs/PROGRESS.md before proposing changes.
3. Inspect the relevant files. Documentation records intent; verify implementation against the actual project.
4. Do not assume that a proposal, generated concept, or unchecked task is approved or implemented.
5. Before editing a character, read its own README.md, HISTORY.md, and TODO.md inside assets/characters/<character-id>/.

## Required character artwork

- For every character, always create a separate head icon preserving its current visual identity. Save it in the character folder, version it, inspect it against the references, and document it. A square, frameless head portrait with transparent background is the default export choice unless the user specifies otherwise.
- For every character, always create a separate fighting-stance picture alongside its concept/model sheet, following the first masked-swordsman character as the precedent.
- Use a full-body, right-facing combat-ready pose by default, preserving the current character design and weapon. Read the character records and reference images first; save versioned artwork and document its provenance and checks.
- A character concept set is incomplete until the concept/model sheet, fighting-stance picture, and head icon all exist. Track missing required artwork as required work, not an optional proposal. This does not imply animation or runtime-sprite readiness.

## Character documentation

- Every new character MUST have README.md, HISTORY.md, and TODO.md in its own asset folder. Create these alongside the first asset, using docs/CHARACTER_TEMPLATE.md as the checklist.
- README.md records identity, design references, appearance to preserve, current asset versions, intended use, technical facts, and unknowns. Distinguish observed design details from user-approved requirements.
- HISTORY.md records dated creations, edits, decisions and their sources, input/reference filenames, exact generation/edit prompts when available, tool used, output filenames, validation, and limitations. Label reconstructed historical prompt summaries explicitly; never invent exact prompts or settings.
- TODO.md records character-specific work with stable local IDs, approval status, and completion criteria.
- Read the current reference images before visual edits. Preserve identifying features unless the user requests a redesign. Save new versions without silently overwriting references and identify which version is current.
- Update character documentation whenever its design, assets, animation, or requirements change. Add a short entry to the project progress log and update the global asset inventory. Keep detailed character history local and link to it globally.

## Keep the project transferable

- Record every meaningful project decision, completed change, validation result, remaining task, and blocker in the appropriate document before ending a work session.
- Update STATUS.md with the current state and a specific next step. Keep it short enough to scan quickly.
- Track work in TODO.md with stable IDs. Distinguish approved work from proposals that still need a decision. Do not silently expand scope.
- Append decisions to DECISIONS.md with their source, rationale, and consequences. Distinguish user-confirmed decisions from reversible implementation choices made by an assistant. Never invent user approval or rationale.
- Append a dated entry to PROGRESS.md describing what changed, relevant paths, checks and their results, and unfinished work. Record failed attempts when they affect future work; avoid raw tool transcripts.
- When a decision changes, preserve the old entry and mark it superseded with a link to its replacement.
- Update docs/ASSETS.md when adding, moving, or replacing assets. Preserve original artwork unless replacement or deletion is requested.
- Keep documentation consistent with file paths and actual results. Never report tests or implementation that did not happen.
- Use project-relative paths in documentation so the folder can move between computers.
- Use ISO dates. Historical entries may group work across dates if precise timing is unavailable. The user's timezone is Asia/Tehran.
- Do not put secrets, credentials, or private account data in project documentation.
- Documentation should capture outcomes and reasons, not private reasoning or a verbatim conversation archive.

## Current boundaries

User-confirmed direction as of 2026-10-29: a 3D Android game with an isometric camera, using Godot and GDScript (D-014). Gameplay remains undecided between a Diablo-like ARPG potentially featuring multiplayer PvE and PvP, and an isometric multiplayer PvP-only game. Neither option nor a networking architecture is approved. Exact camera projection and controls remain open. Game name, production engine version, modeling tools and final animation workflow remain undecided. The previous 2D project is failed and preserved separately; do not resume it or adopt assets automatically.

Current authorization (2026-10-29): create the first character based on Dota 2 Juggernaut, an actual 3D model and a preview for user confirmation before game use. This supersedes the earlier documentation-only boundary for this asset task. Required character artwork and supporting authoring tools are within the task. Design/game-use approval remains pending; gameplay, rigging and animation scope are not selected. See docs/PROJECT_DIRECTION.md and assets/characters/ember-ronin/.

## Code quality requirements

Before adding or modifying code, read docs/CODING_STANDARDS.md. The user requires readable, clean code, meaningful consistent naming and style, focused files, and small cohesive methods/functions. Avoid huge files and functions. Establish language-specific conventions before substantial implementation; do not invent an architecture. Documentation maintenance is part of task completion.

## End-of-session checklist

- [ ] Relevant decisions and tasks recorded.
- [ ] Progress entry includes validation and any limitations.
- [ ] Status and next step reflect the actual files.
- [ ] Asset inventory and documentation links updated when needed.
- [ ] Every affected character's README, history, and tasks updated as applicable.





Current authorization update (2026-10-29): user selected extracted Axe, Juggernaut and Shadow Fiend as the first confirmed character models. See docs/DECISIONS.md D-009 and their local records. Rights and animation/runtime readiness remain unresolved; Ember Ronin remains a separate unapproved draft.

Current workflow update (2026-10-29): the first landscape Juggernaut movement prototype is authorized (D-018). Develop and test routinely in Godot; make and test Android builds only when the user requests them (D-019).
