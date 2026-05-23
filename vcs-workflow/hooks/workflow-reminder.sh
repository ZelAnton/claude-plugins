#!/usr/bin/env bash
# ============================================================================
# UserPromptSubmit hook — detects the repo's version-control type and injects
# the matching workflow reminder into Claude's context on every new prompt.
#
# Detection (walking up from $PWD; filesystem checks only — no jj/git binary):
#   .jj + top-level .git at the same root  -> jj-colocated
#   .jj only (git backend lives inside .jj) -> pure-jj
#   .git only                               -> pure-git
#   neither                                 -> emit nothing
#
# Reminder prose lives in sibling reminder-*.txt files so it can be edited
# without touching JSON escapes. A missing/unreadable file fails silently.
#
# Output: one line of JSON wrapping the reminder in
# `hookSpecificOutput.additionalContext`, surfaced to the model this turn.
# ============================================================================

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Locate the repo root(s) by walking up from the working directory -------
jj_root=""
git_root=""
dir="$PWD"
while :; do
    [ -z "$jj_root" ] && [ -d "$dir/.jj" ] && jj_root="$dir"
    if [ -z "$git_root" ] && { [ -d "$dir/.git" ] || [ -f "$dir/.git" ]; }; then
        git_root="$dir"
    fi
    parent="$(dirname "$dir")"
    [ "$parent" = "$dir" ] && break   # reached the filesystem root
    dir="$parent"
done

# --- Choose the reminder for this repo type ---------------------------------
if [ -n "$jj_root" ]; then
    if [ "$jj_root" = "$git_root" ]; then
        TEXT_FILE="${SCRIPT_DIR}/reminder-jj-colocated.txt"
    else
        TEXT_FILE="${SCRIPT_DIR}/reminder-jj.txt"
    fi
elif [ -n "$git_root" ]; then
    TEXT_FILE="${SCRIPT_DIR}/reminder-git.txt"
else
    exit 0   # not a tracked repo — nothing to remind
fi

[ -f "$TEXT_FILE" ] || exit 0   # fail silently on a missing text file

# JSON-escape the file contents. Order matters:
#   backslash -> \\ , double-quote -> \" , tab -> \t , CR -> \r (CRLF files),
#   then fold newlines to \n via the multi-line hold trick.
escaped=$(
    sed \
        -e 's/\\/\\\\/g' \
        -e 's/"/\\"/g' \
        -e 's/\t/\\t/g' \
        -e 's/\r/\\r/g' \
        "$TEXT_FILE" \
    | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'
)

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$escaped"
