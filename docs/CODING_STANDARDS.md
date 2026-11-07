# Coding standards

Last updated: 2026-10-29.

The user requires clean, readable code, careful naming and consistent style, without huge files or methods/functions. These practices translate that requirement into review criteria. Language-specific tools and numeric size limits have not been selected.

## Structure and readability

- Give each module, class and function a clear, cohesive responsibility. Split files when unrelated responsibilities accumulate and functions when distinct operations become difficult to follow.
- Prefer straightforward control flow and shallow nesting. Extract helpers that clarify intent, not merely to meet a line-count target.
- Keep dependencies explicit. Separate domain rules from input, rendering, persistence and networking when those concerns actually exist.
- Avoid premature abstractions and speculative frameworks. Extract shared behavior when a real repeated responsibility is evident.
- Use comments for reasons and constraints; let clear code explain routine behavior. Remove obsolete code and stale comments.

## Naming and style

- Use descriptive names that communicate purpose, domain meaning and units where relevant. Avoid unexplained abbreviations and misleading or overly generic names.
- Follow consistent language-appropriate naming and formatting conventions. Respect established conventions when editing existing code.
- Give meaningful constants clear names; keep tuning data separate from behavior where useful.
- After choosing the engine and language, document naming, folder organization, formatter and linter choices before substantial implementation. This document selects none of those tools.

## Correctness and review

- Handle expected errors explicitly at relevant boundaries; do not silently swallow failures. Keep diagnostics useful without exposing secrets.
- Keep changes focused and avoid unrelated refactoring.
- Validate behavior with checks appropriate to the change. Use meaningful automated tests for logic and regressions when executable code exists; report checks accurately.
- Measure performance on representative Android targets once selected. Record optimization evidence and tradeoffs while keeping code understandable.
- Review responsibilities, naming, dependencies, duplication, nesting and whether file/function size harms comprehension. No arbitrary numeric size ceiling is imposed.
- Update project records with decisions, checks, limitations and follow-up tasks before handing work back.

The initial standards were documentation only. Asset-authoring helpers now use the Python conventions in [tools/README.md](../tools/README.md), an assistant implementation choice for the model preview task. This does not select a game engine/language. Future language-specific additions must distinguish user requirements from assistant implementation choices.

## GDScript conventions for the first prototype

Assistant implementation choices, 2026-10-29: use Godot's standard tab indentation, snake_case for files, functions and variables, PascalCase for scene/node names and class names, and UPPER_SNAKE_CASE for constants. Use explicit types where they clarify interfaces; keep input, character motion, presentation and scene construction in focused scripts. Organize the runnable project under `game/`, with scripts and scenes grouped by purpose. Format consistently with the Godot editor; no external formatter or linter is configured yet. Check scripts by importing and running the selected Godot version and exercise user-facing movement. This is a starting convention, not a production architecture decision.

## Unity editor helper convention

For the separate Meadowlands reconstruction, the small C# editor helper uses Unity conventions: PascalCase types and methods, camelCase local names, and one focused editor-only responsibility. This is a reversible choice for this separate project, not a change to the Godot game architecture. Unity compilation remains unverified.
