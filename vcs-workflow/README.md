# vcs-workflow

Per-prompt version-control workflow reminder for Claude Code agents. On every prompt a `UserPromptSubmit` hook detects the repo's VCS type and injects a decision-tree checklist so the agent evaluates change scope **before** editing — not at commit time — and pushes to the right branch.

Supports three repo layouts:

| Repo type        | Detected by                       | Reminder dialect                         |
|------------------|-----------------------------------|------------------------------------------|
| **jj-colocated** | `.jj` + top-level `.git`          | jj commands + "don't mix raw git" note   |
| **pure-jj**      | `.jj` only (git backend in `.jj`) | jj commands                              |
| **pure-git**     | `.git` only                       | git commands                             |

In any other directory (no `.jj` and no `.git`) the hook emits nothing.

## Why

Prose-only guidance ("set the change description early!" in AGENTS.md or CLAUDE.md) doesn't reliably enforce per-prompt behaviour: the agent loads such files once at session start and the rule decays. A hook fires deterministically on every prompt and the reminder lands as a system reminder for that turn — first-class context the agent can't skip.

## What the hook injects

The shared shape across all three dialects:

```
[vcs-workflow] New user prompt (<repo type>) — before any edits, evaluate the change scope:

1. Inspect current state (`jj st` / `git status`).
2. Classify this prompt: Continuation / Scope shift / New work — and act
   (describe, new change, or a fresh branch) accordingly.
3. If unclear which category, ask the user before editing.
4. Pushing — target the active branch's own upstream, never `main` by default.
```

The git dialect maps the jj concepts to branches/commits; the colocated dialect adds a note to prefer `jj` over raw `git`. Each dialect's prose lives in its own file under [`hooks/`](./hooks/) (`reminder-jj-colocated.txt`, `reminder-jj.txt`, `reminder-git.txt`) — edit there to tune wording without touching JSON escapes.

## Install

### Claude Code

```text
/plugin marketplace add zelanton/claude-plugins
/plugin install vcs-workflow@zelanton-claude-plugins
```

The hook runs automatically on every user prompt — no per-project configuration.

### GitHub Copilot / Factory via [allagents](https://allagents.dev)

```bash
npx allagents plugin marketplace add zelanton/claude-plugins --name zelanton
npx allagents plugin install vcs-workflow@zelanton
```

These three clients (Claude, Copilot, Factory) support the per-prompt hook contract.

### Other clients (Cursor, Codex, Gemini, Windsurf, Cline, …)

This plugin does **not** apply — install [`vcs-workflow-skill`](../vcs-workflow-skill/) instead. Same checklist, loaded once at session start. The two plugins are deliberately split so each client gets only the layer it can actually run.

## Requirements

- **bash** on `$PATH`. On Windows that means Git Bash (which ships with Git for Windows). The hook config sets `shell: "bash"` explicitly.
- That's it. No jj/git **binary** dependency — detection only checks for `.jj`/`.git` directories on disk; the hook never invokes jj or git.

## How it works

`.claude-plugin/plugin.json` registers a single `UserPromptSubmit` hook:

```json
{
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/workflow-reminder.sh",
  "shell": "bash",
  "timeout": 5
}
```

`${CLAUDE_PLUGIN_ROOT}` resolves to the installed plugin's cache directory, so the hook works regardless of the user's current working directory.

`workflow-reminder.sh` walks up from `$PWD` looking for `.jj` and a top-level `.git`, picks the matching `reminder-*.txt`, JSON-escapes it via `sed`, and prints a single line of JSON `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"…"}}`. Claude Code surfaces `additionalContext` to the model as a system reminder for the current turn.

## Disable temporarily

```text
/plugin disable vcs-workflow@zelanton-claude-plugins
```

Re-enable with `/plugin enable`. Uninstall with `/plugin uninstall`.

## Customize for your repo

The reminder text is intentionally generic. To project-tune it, edit the relevant `hooks/reminder-*.txt` in your installed copy, or point `.claude/settings.json` at a local hook script with your own text file — Claude Code merges per-project hooks with plugin hooks.
