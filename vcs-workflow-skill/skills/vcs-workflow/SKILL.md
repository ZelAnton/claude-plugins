---
name: vcs-workflow
description: Use whenever a new user request touches a version-controlled repository (`.jj` or `.git`). Classifies the request as continuation / scope-shift / new work, runs the matching jj or git command to set the change scope BEFORE editing, and on push targets the active branch/bookmark's own upstream — not `main` by default. Covers jj-colocated, pure-jj, and pure-git layouts.
---

# vcs-workflow

Per-prompt version-control discipline for AI coding agents. Use this skill at the **start of every new user request** that involves edits in a tracked repository — not at commit time.

> **Portability note.** On Claude Code this skill ships alongside a `UserPromptSubmit` hook that re-injects the same reminder on every turn (so the rule doesn't decay). On clients without a per-prompt hook (Cursor, Codex, Gemini, Windsurf, Cline, etc.), the skill is loaded once at session start — re-read this file at the top of each new user request to compensate.

## Step 1 — Detect the repo type

From the project root, check filesystem only (no jj/git binary needed):

| Has `.jj` | Has `.git` | Repo type | Dialect to use |
|---|---|---|---|
| ✓ | ✓ (at same root) | **jj-colocated** | jj commands; do **not** drive raw git |
| ✓ | ✗ | **pure-jj** | jj commands |
| ✗ | ✓ | **pure-git** | git commands |
| ✗ | ✗ | not tracked | skip — nothing to do |

When the layout is ambiguous (e.g. nested submodules, worktrees), ask the user.

## Step 2 — Inspect current state

- **jj** (colocated or pure): `jj st` — note the active change's description and which bookmark sits nearest to `@`.
- **git**: `git status` and `git branch --show-current` — note the working tree state and current branch.

## Step 3 — Classify this prompt

Decide which bucket the user's request falls into **before editing**:

- **Continuation** — same topic, refinement, or follow-up of in-progress work.
  - *jj*: just work; jj folds edits into the current change.
  - *git*: keep working on the current branch; group related edits into one logical commit.

- **Scope shift** — same change, but the goal has been refined or expanded.
  - *jj*: `jj describe -m "<refined summary>"`.
  - *git*: stay on the branch but keep history coherent — reword the pending commit, or split unrelated edits into their own commit before committing.

- **New work** — orthogonal topic or a different area.
  - *jj*: `jj new -m "<concise summary>"` (descendant), or `jj new @- -m "..."` (sibling, if current work is unfinished).
  - *git*: start a fresh branch off the base — `git switch -c <name> <base-branch>` — so unrelated work doesn't pile onto the current branch.

If unclear which bucket this prompt falls in, **ask the user** before editing.

## Step 4 — When pushing, target the active branch's own upstream — never `main` by default

- **jj** — the active bookmark is the nearest bookmark in `::@`:
  ```
  jj log -r 'heads(::@ & bookmarks())' -T 'bookmarks'
  ```
  Advance it when ready (`jj bookmark move <name> --to @`) and push only it:
  ```
  jj git push -b <name>
  ```
  This goes to that bookmark's own upstream. Touch `main` only if `main` itself is the active bookmark.
- **git** — push the branch you are on:
  ```
  git push -u origin HEAD   # first time, sets upstream
  git push                  # subsequently
  ```
  Don't commit to or push `main` unless `main` is the branch you're working on and the user asked. If the work belongs on a feature branch, create one first (`git switch -c <name>`).

## Step 5 — Colocated repos: drive through `jj`, not raw `git`

In a jj-colocated repo, raw git writes (`git commit`, `git checkout`, `git reset`, `git merge`) can desync the jj working copy. Prefer the jj equivalent. If a raw git write is unavoidable (e.g. an external tool insists on it), follow it with:

```
jj git import
```

so the jj view reconverges with the git refs.
