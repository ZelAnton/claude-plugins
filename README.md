# claude-plugins

Personal marketplace of [Claude Code](https://claude.ai/code) plugins for AI-agent coding workflows.

## Plugins

| Plugin | Purpose |
|---|---|
| [`vcs-workflow`](./vcs-workflow/) | Per-prompt reminder enforcing the describe-early / continuation / scope-shift / new-work decision tree, plus push-to-active-branch hygiene. Detects and adapts to jj-colocated, pure-jj, and pure-git repos. |

## Install (for users)

Add this marketplace to your Claude Code, then install plugins from it:

```text
/plugin marketplace add zelanton/claude-plugins
/plugin install vcs-workflow@zelanton-claude-plugins
```

Plugins activate immediately. Updates land via `/plugin update`.

## Layout

```
.claude-plugin/marketplace.json   Marketplace manifest (lists all plugins)
<plugin-name>/                    One directory per plugin
  ├── .claude-plugin/plugin.json  Plugin manifest (hooks, skills, commands…)
  ├── hooks/                      Hook scripts (when used)
  └── README.md                   Plugin-specific docs
```

## Versioning

Plugins follow rolling-`main` by default; `/plugin update` picks up new commits. Breaking changes get a git tag (`vX.Y.Z`) so users can pin if they need stability.

## License

MIT
