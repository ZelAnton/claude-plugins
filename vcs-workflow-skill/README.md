# vcs-workflow-skill

Portable, hook-free counterpart to [`vcs-workflow`](../vcs-workflow/). Ships a single [`SKILL.md`](./skills/vcs-workflow/SKILL.md) that codifies the same continuation / scope-shift / new-work decision tree and the "push to the active branch's upstream, not `main`" rule — but as a session-start skill instead of a per-prompt hook.

## Who this is for

AI coding clients **without** a per-prompt hook mechanism — i.e. anything except Claude Code, GitHub Copilot, and Factory. That covers Cursor, Codex, Gemini, OpenCode, Windsurf, Cline, Continue, Roo, Kilo, Trae, Augment, Zencoder, Junie, OpenHands, Kiro, Replit, Kimi, Amp Code, VSCode (≈17 clients).

If you're on Claude Code (or Copilot/Factory), install [`vcs-workflow`](../vcs-workflow/) instead — the hook re-injects the checklist on every turn, so the rule never decays mid-session.

## Install via [allagents](https://allagents.dev)

```bash
npx allagents plugin marketplace add zelanton/claude-plugins --name zelanton
npx allagents plugin install vcs-workflow-skill@zelanton
```

allagents will sync `skills/vcs-workflow/SKILL.md` into each client's expected skills path (e.g. `.cursor/skills/`, `.codex/skills/`, `.gemini/skills/` …).

## Trade-off vs the hook plugin

A skill is loaded once at session start. The rule it carries decays as the conversation grows — that's the original problem `vcs-workflow` solves with a per-prompt hook. This plugin is the next-best thing where hooks aren't available; the skill body explicitly asks the agent to re-read the checklist at the top of each new user request to compensate.

## How it works

A single [`skills/vcs-workflow/SKILL.md`](./skills/vcs-workflow/SKILL.md) with YAML frontmatter (`name`, `description`) marks it as an available skill in any allagents-supported client. The description is the trigger — clients load it when a new user request touches a tracked repository (`.jj` or `.git`).
