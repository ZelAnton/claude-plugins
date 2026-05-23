# jj-workflow

Per-prompt reminder for Claude Code agents working in [jj](https://jj-vcs.github.io/jj/)-colocated repositories. Injects a decision-tree checklist via `UserPromptSubmit` hook so the agent evaluates change scope **before** editing — not at commit time.

## Why

Prose-only guidance ("set the change description early!" in AGENTS.md or CLAUDE.md) doesn't reliably enforce per-prompt behaviour: the agent loads such files once at session start and the rule decays. A hook fires deterministically on every prompt and the reminder lands as a system reminder for that turn — first-class context the agent can't skip.

## What the hook injects

```
[jj-workflow] New user prompt — before any edits, evaluate the change scope:

1. Run `jj st` to see the current change description.
2. Classify this prompt:
   - **Continuation**: same topic, refinement, or follow-up → just work; jj
     folds edits into current change.
   - **Scope shift**: same change but goal refined/expanded →
     `jj describe -m "<refined summary>"`.
   - **New work**: orthogonal topic or different area →
     `jj new -m "<concise summary>"` (descendant) or
     `jj new @- -m "..."` (sibling if current work is unfinished).
3. If unclear which category this prompt falls in, ask the user before editing.
```

The text is in [`hooks/jj-prompt-reminder.txt`](./hooks/jj-prompt-reminder.txt) — edit there to tune wording for your project without touching JSON escapes.

## Install

```text
/plugin marketplace add zelanton/claude-plugins
/plugin install jj-workflow@zelanton-claude-plugins
```

After install the hook runs automatically on every user prompt — no per-project configuration.

## Requirements

- **bash** on `$PATH`. On Windows that means Git Bash (which ships with Git for Windows). The hook config sets `shell: "bash"` explicitly.
- That's it. No jj-specific dependencies — the hook only *reminds* the agent to use jj; it doesn't call jj itself.

## How it works

`.claude-plugin/plugin.json` registers a single `UserPromptSubmit` hook:

```json
{
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/jj-prompt-reminder.sh",
  "shell": "bash",
  "timeout": 5
}
```

`${CLAUDE_PLUGIN_ROOT}` resolves to the installed plugin's cache directory, so the hook works regardless of the user's current working directory.

The script reads the `.txt` file, JSON-escapes it via `sed`, and prints a single line of JSON `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"…"}}`. Claude Code surfaces `additionalContext` to the model as a system reminder for the current turn.

## Disable temporarily

```text
/plugin disable jj-workflow@zelanton-claude-plugins
```

Re-enable with `/plugin enable`. Uninstall with `/plugin uninstall`.

## Customize for your repo

The reminder text is intentionally generic. To project-tune it, install the plugin and then override the text by writing a per-project `.claude/hooks/jj-prompt-reminder.sh` of your own — Claude Code merges per-project hooks with plugin hooks, so both fire (or replace the plugin path in `.claude/settings.json` to point at your local text file).
