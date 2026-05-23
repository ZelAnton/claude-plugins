# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This is a **Claude Code plugin marketplace** — not application code. The repo is consumed by other users via `/plugin marketplace add zelanton/claude-plugins` (lowercase owner — a mixed-case owner like `ZelAnton` triggers a case-only directory-rename failure on Windows because it no longer matches the lowercase `name` in `marketplace.json`). There is no build, no test suite, no package manager. Editing here changes the plugins that Claude Code installs from this marketplace.

## Layout contract

Two manifests govern everything; they must stay in sync:

- [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) — top-level marketplace manifest. Lists each plugin with `name`, `source` (relative path), `description`, `version`. Adding a plugin requires a new entry here.
- `<plugin-name>/.claude-plugin/plugin.json` — per-plugin manifest. Declares `hooks`, `skills`, `commands`, etc. The `name` and `version` here should match the marketplace entry.

Each plugin lives in its own top-level directory with its own `README.md` and `.claude-plugin/plugin.json`. Hook scripts go under `<plugin>/hooks/`; portable skills go under `<plugin>/skills/<skill-name>/SKILL.md`.

## Two-plugin split for cross-client distribution

The `vcs-workflow` capability is deliberately split into two sibling plugins because there's no plugin-side way to route artifacts per client:

- [`vcs-workflow/`](vcs-workflow/) — **hook only**. Targets Claude Code, GitHub Copilot, Factory (the three clients with per-prompt hook contracts).
- [`vcs-workflow-skill/`](vcs-workflow-skill/) — **skill only**. Targets the remaining ~20 [allagents](https://allagents.dev)-supported clients (Cursor, Codex, Gemini, Windsurf, Cline, OpenCode, …) where only `skills/` loads.

Why split and not co-ship: a single plugin with both `hooks/` and `skills/` causes duplication on Claude/Copilot/Factory — those clients auto-discover both, so the same reminder is delivered twice (once per prompt via the hook, once at session start via the skill). [Claude Code's plugin manifest has no opt-out](https://code.claude.com/docs/en/plugins-reference.md) for skill auto-discovery, and allagents' per-client routing is configured user-side in `workspace.yaml`, not plugin-side. Splitting into two plugins is the only way for the plugin author to ship clean per-client behaviour.

Practical consequences when editing:

- **The hook reminder text** lives under `vcs-workflow/hooks/reminder-*.txt`.
- **The skill body** lives under `vcs-workflow-skill/skills/vcs-workflow/SKILL.md`.
- **Keep them semantically in sync.** Both encode the same continuation / scope-shift / new-work + push-to-active-branch checklist; if one is edited, mirror the substantive change in the other.
- `SKILL.md` requires YAML frontmatter with `name` (≤128 chars) and `description` (required). The description is the trigger — it must say *when* the skill applies.

## Two consumers of `.claude-plugin/marketplace.json`

- **Claude Code** reads `marketplace.json` directly (`/plugin marketplace add …`). Users install `vcs-workflow` here.
- **[allagents](https://allagents.dev)** (`npx allagents plugin marketplace add …`) reads the *exact same* `marketplace.json` and syncs each plugin's artifacts to its target clients' paths. Users install `vcs-workflow` (Copilot/Factory) or `vcs-workflow-skill` (everyone else).

## Hook authoring conventions

Hooks in this repo follow patterns set by [`vcs-workflow/hooks/workflow-reminder.sh`](vcs-workflow/hooks/workflow-reminder.sh):

- **Bash-only, cross-platform.** Hooks declare `"shell": "bash"` in `plugin.json` so they run under Git Bash on Windows. Don't reach for PowerShell or platform-specific tooling.
- **`${CLAUDE_PLUGIN_ROOT}`** is the path to the installed plugin cache. Always invoke scripts as `bash ${CLAUDE_PLUGIN_ROOT}/hooks/<script>.sh` — never assume the user's CWD.
- **Reminder text lives in sibling `.txt` file(s)**, not embedded in the shell script. `workflow-reminder.sh` detects the repo type (jj-colocated / pure-jj / pure-git) by walking up from `$PWD` for `.jj`/`.git`, picks the matching `reminder-*.txt`, JSON-escapes it, and emits a single line of `{"hookSpecificOutput":{"hookEventName":"<event>","additionalContext":"…"}}`. This separation lets the prose be edited without touching JSON escapes.
- **Fail silently.** A missing or malformed text file must `exit 0`, not break the user's turn. Hooks have a 5s timeout configured.
- **JSON escape order matters** in the `sed` pipeline: backslash first, then `"`, then `\t`/`\r`, then newlines via the multi-line label trick (`:a; N; $!ba; s/\n/\\n/g`). Don't reorder without testing CRLF-saved files.

## Versioning

Rolling-`main` by default; `/plugin update` pulls latest commits. Breaking changes get a git tag `vX.Y.Z`. When bumping a plugin's `version` field, update both the marketplace entry and the plugin manifest.

## This repo is itself a jj-colocated repo

`.jj/` exists alongside `.git/`. The `vcs-workflow` plugin's own reminder applies when working here: classify each prompt as continuation / scope-shift / new work and run `jj describe` / `jj new` accordingly before editing.

When pushing, target the **active bookmark's upstream** — not `main` by default. The active bookmark is the nearest bookmark in `::@`; advance it (`jj bookmark move <name> --to @`) and push only it (`jj git push -b <name>`). Touch `main` only when `main` is itself the active bookmark.
