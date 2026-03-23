#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PreToolUse - Bash Guard (TW-adapted)
# =============================================================================
# Blocks dangerous bash commands before execution.
# TW tuning: allows Vault CLI, DGX SSH, checkpoint.py, External RAM scripts.
#
# Input: JSON via stdin with tool_input.command
# Output: JSON with permissionDecision deny if dangerous
#
# Authority: SEED (see AUTHORITY-MATRIX.md)
# Origin: Aedelon/claude-code-blueprint, adapted for TW by Code 🔧
# =============================================================================

set -euo pipefail

# Fail-closed: if anything errors, deny by default
trap 'echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Hook error - fail-closed\"}}"; exit 0' ERR

# Read stdin JSON
input=$(cat)

# Extract command from tool_input
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

[ -z "$command" ] && exit 0

# === 1. Privilege escalation (block, not just warn) ===
# Catches: sudo, su, doas, pkexec — at start of command or after ; && || $( `
if echo "$command" | grep -qE '(^|;|&&|\|\||\$\(|`)\s*(sudo|su |doas |pkexec)'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Privilege escalation blocked."}}'
    exit 0
fi

# === 2. Destructive patterns ===
# TW-tuned: blocks recursive force delete, device writes, permission bombs,
# fork bombs, pipe-to-shell, data destruction
dangerous_patterns='rm -rf /|rm -rf ~|rm -rf \*|:()\{ :\|:& \};:|curl.*\| *(sh|bash)|wget.*\| *(sh|bash)|mkfs\.|dd if=.*of=/dev|truncate|shred|chmod -R 777|chmod \+s'

if echo "$command" | grep -qE "$dangerous_patterns"; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Dangerous command pattern detected"}}'
    exit 0
fi

# === 3. Indirect execution / obfuscation ===
obfuscation_patterns='eval .*\$|base64 -d.*\|.*(sh|bash)|sed.*e .*[^\\]|awk.*system\(|bash <\('

if echo "$command" | grep -qE "$obfuscation_patterns"; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Obfuscated execution pattern detected"}}'
    exit 0
fi

# === 4. TW-specific: External RAM protection ===
# Never delete external-ram content (lab notebook rule)
if echo "$command" | grep -qE '(rm|git clean|git checkout --).*\.external-ram'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"External RAM is protected (lab notebook rule). Never delete .external-ram/ content."}}'
    exit 0
fi

exit 0
