# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This is a **Claude Code plugin marketplace** — not application code. The repo is consumed by other users via `/plugin marketplace add zelanton/claude-plugins` (lowercase owner — a mixed-case owner like `ZelAnton` triggers a case-only directory-rename failure on Windows because it no longer matches the lowercase `name` in `marketplace.json`). There is no build, no test suite, no package manager. Editing here changes the plugins that Claude Code installs from this marketplace.

## Layout contract

Two manifests govern everything; they must stay in sync:

- [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) — top-level marketplace manifest. Lists each plugin with `name`, `source` (relative path), `description`, `version`. Adding a plugin requires a new entry here.
- `<plugin-name>/.claude-plugin/plugin.json` — per-plugin manifest. Declares `hooks`, `skills`, `commands`, etc. The `name` and `version` here should match the marketplace entry.

Each plugin lives in its own top-level directory (e.g. [`jj-workflow/`](jj-workflow/)) with its own `README.md` and `.claude-plugin/plugin.json`. Hook scripts go under `<plugin>/hooks/`.

## Hook authoring conventions

Hooks in this repo follow patterns set by [`jj-workflow/hooks/jj-prompt-reminder.sh`](jj-workflow/hooks/jj-prompt-reminder.sh):

- **Bash-only, cross-platform.** Hooks declare `"shell": "bash"` in `plugin.json` so they run under Git Bash on Windows. Don't reach for PowerShell or platform-specific tooling.
- **`${CLAUDE_PLUGIN_ROOT}`** is the path to the installed plugin cache. Always invoke scripts as `bash ${CLAUDE_PLUGIN_ROOT}/hooks/<script>.sh` — never assume the user's CWD.
- **Reminder text lives in a sibling `.txt` file**, not embedded in the shell script. The script reads, JSON-escapes, and emits a single line of `{"hookSpecificOutput":{"hookEventName":"<event>","additionalContext":"…"}}`. This separation lets the prose be edited without touching JSON escapes.
- **Fail silently.** A missing or malformed text file must `exit 0`, not break the user's turn. Hooks have a 5s timeout configured.
- **JSON escape order matters** in the `sed` pipeline: backslash first, then `"`, then `\t`/`\r`, then newlines via the multi-line label trick (`:a; N; $!ba; s/\n/\\n/g`). Don't reorder without testing CRLF-saved files.

## Versioning

Rolling-`main` by default; `/plugin update` pulls latest commits. Breaking changes get a git tag `vX.Y.Z`. When bumping a plugin's `version` field, update both the marketplace entry and the plugin manifest.

## This repo is itself a jj-colocated repo

`.jj/` exists alongside `.git/`. The `jj-workflow` plugin's own reminder applies when working here: classify each prompt as continuation / scope-shift / new work and run `jj describe` / `jj new` accordingly before editing.
