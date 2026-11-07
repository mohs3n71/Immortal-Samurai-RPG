# Character documentation checklist

For every character, create the following three documents inside assets/characters/<character-id>/ beside its assets. Use relative links. Replace placeholders with known facts and mark unknowns explicitly.

## Required artwork

- [ ] Separate head icon saved and inspected against the character reference. Record identity features, exact prompt, version, dimensions, alpha and limitations. Default: square frameless portrait with transparent background; final UI sizes remain a separate decision.

- [ ] Concept/model sheet saved and inspected.
- [ ] Separate full-body fighting-stance picture saved and inspected, right-facing by default like masked-swordsman. Preserve the current design and weapon; record both assets, prompts, versions and validation. Missing stance artwork is required pending work.

## README.md — Current character reference

- Stable folder ID and display name; identify temporary names.
- Current stage and last-updated date.
- User-confirmed brief and intended use.
- Visual identity: silhouette, proportions, face/mask, hair, costume, colors, weapon, and style.
- Features to preserve for continuity; distinguish observations from approved requirements.
- Asset table with relative links, versions, reference relationships, current/superseded status, and readiness.
- Technical facts when verified: dimensions, alpha, layers, orientation, pivot, animation frames/timing, export format.
- Open decisions and known limitations.
- Links to local HISTORY.md and TODO.md and the root AGENTS.md.

## HISTORY.md — Append-only record

For each creation or edit record:

- Date and entry ID.
- Request and decision source: user-confirmed / assistant implementation choice / proposed.
- Input assets and their roles; exact filenames.
- Exact prompt and tool/settings when available. Label summaries or unknown settings honestly.
- Output files and version relationship; preserve earlier references.
- Changes made and identifying features retained.
- Checks performed, their results, and limitations.
- Follow-up tasks and open questions.

## TODO.md — Local work queue

- Stable IDs scoped to the character, for example C-001.
- Separate completed work, approved active work, and proposed work.
- Each open item has a completion criterion and relevant dependencies.
- Link to global task IDs for shared engine/pipeline decisions instead of duplicating their status.

After creating or changing a character, update docs/ASSETS.md and docs/PROGRESS.md. Record project-wide decisions in docs/DECISIONS.md; keep character-only detail in the local history.


