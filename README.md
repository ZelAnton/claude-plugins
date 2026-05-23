# claude-plugins

Personal marketplace of [Claude Code](https://claude.ai/code) plugins for AI-agent coding workflows. Also installable into ~20 other AI clients (Cursor, Codex, Gemini, Copilot, Windsurf, Cline, …) via [allagents](https://allagents.dev).

![Cover](cover.png)

## Plugins

| Plugin | Purpose | Install on |
|---|---|---|
| [`vcs-workflow`](./vcs-workflow/) | Per-prompt **hook** reminder enforcing describe-early / continuation / scope-shift / new-work decision tree, plus push-to-active-branch hygiene. Detects and adapts to jj-colocated, pure-jj, and pure-git repos. | Claude Code, GitHub Copilot, Factory |
| [`vcs-workflow-skill`](./vcs-workflow-skill/) | Same checklist as a portable **skill** (loads once at session start). Use on clients without per-prompt hook support. | Cursor, Codex, Gemini, Windsurf, Cline, OpenCode, … (~20 other clients via allagents) |

The two plugins are deliberately split so each client gets only the layer it can actually run — no duplication, no token waste.

## Install (for users)

### Claude Code

```text
/plugin marketplace add zelanton/claude-plugins
/plugin install vcs-workflow@zelanton-claude-plugins
```

Plugins activate immediately. Updates land via `/plugin update`.

### Other clients via [allagents](https://allagents.dev)

```bash
npx allagents plugin marketplace add zelanton/claude-plugins --name zelanton

# Hook-capable clients (Copilot, Factory):
npx allagents plugin install vcs-workflow@zelanton

# Everyone else (Cursor, Codex, Gemini, Windsurf, Cline, …):
npx allagents plugin install vcs-workflow-skill@zelanton
```

allagents reads the same `.claude-plugin/marketplace.json` and syncs each plugin's artifacts to its target clients' expected paths.

## Layout

```
.claude-plugin/marketplace.json    Marketplace manifest (lists all plugins)
vcs-workflow/                      Hook plugin (Claude/Copilot/Factory)
  ├── .claude-plugin/plugin.json
  ├── hooks/                       UserPromptSubmit hook script + reminder text
  └── README.md
vcs-workflow-skill/                Portable skill plugin (other ~20 clients)
  ├── .claude-plugin/plugin.json
  ├── skills/<skill>/SKILL.md      Session-start checklist
  └── README.md
```

## Versioning

Plugins follow rolling-`main` by default; `/plugin update` picks up new commits. Breaking changes get a git tag (`vX.Y.Z`) so users can pin if they need stability.

## License

MIT
