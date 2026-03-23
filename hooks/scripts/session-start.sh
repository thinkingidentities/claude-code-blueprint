#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: SessionStart (TW-adapted)
# =============================================================================
# Injects project context into Claude session.
# TW tuning: detects TW repo type, ThinkJob worktrees, cognate identity.
# NOTE: This runs ALONGSIDE the External RAM hydration hook (ADR-005 protected).
#       It does NOT replace external-ram-hydrate.sh.
#
# Authority: SEED (see AUTHORITY-MATRIX.md)
# Origin: Aedelon/claude-code-blueprint, adapted for TW by Code 🔧
# =============================================================================

set -euo pipefail

# Read stdin JSON (required by Claude Code)
input=$(cat)

# Extract working directory from stdin or use cwd
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null || pwd)
cd "$cwd" 2>/dev/null || true

# Build context message
context="Session started $(date '+%Y-%m-%d %H:%M:%S')"

# TW repo detection
if [ -f CLAUDE.md ] && [ -f AGENTS.md ]; then
    context="$context | TW federated repo"
elif [ -f CLAUDE.md ]; then
    context="$context | Claude Code project"
fi

# Standard project detection
if [ -f package.json ]; then
    name=$(jq -r '.name // "project"' package.json 2>/dev/null || echo "project")
    if jq -e '.dependencies.next // .devDependencies.next' package.json >/dev/null 2>&1; then
        context="$context | $name (Next.js)"
    else
        context="$context | $name (Node.js)"
    fi
elif [ -f pyproject.toml ]; then
    name=$(grep '^name' pyproject.toml 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)".*/\1/' || echo "project")
    context="$context | ${name:-project} (Python)"
elif [ -f Cargo.toml ]; then
    name=$(grep '^name' Cargo.toml 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)".*/\1/' || echo "project")
    context="$context | ${name:-project} (Rust)"
elif [ -f deno.json ] || [ -f deno.jsonc ]; then
    context="$context | Deno project"
fi

# Git info
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || echo 'detached')
    changes=$(git status --short 2>/dev/null | wc -l | tr -d ' ')

    # ThinkJob worktree detection
    if echo "$cwd" | grep -qE 'twc-[0-9]+'; then
        twc_id=$(echo "$cwd" | grep -oE 'twc-[0-9]+' | tail -1)
        context="$context | ThinkJob: $twc_id"
    fi

    if [ "$changes" -gt 0 ]; then
        context="$context | Branch: $branch ($changes uncommitted)"
    else
        context="$context | Branch: $branch (clean)"
    fi
fi

# Available project commands
project_cmd_dir="$cwd/.claude/commands"
if [ -d "$project_cmd_dir" ]; then
    cmds=$(find "$project_cmd_dir" -name "*.md" -maxdepth 2 2>/dev/null | xargs -I {} basename {} .md | sort | tr '\n' ' ' || echo "")
    if [ -n "$cmds" ]; then
        context="$context | Commands: $cmds"
    fi
fi

# Output JSON
escaped_context=$(echo "$context" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' ' ')

echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"$escaped_context\"}}"

exit 0
