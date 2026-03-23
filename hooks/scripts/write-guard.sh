#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PreToolUse - Write/Edit Guard (TW-adapted)
# =============================================================================
# Blocks writes to protected files AND detects secrets in written content.
# TW tuning: Vault tokens, Matrix access tokens, OB1 API keys, homeserver.yaml.
#
# Input: JSON via stdin with tool_input.file_path, tool_input.content, tool_input.new_string
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

# === 1. Protected file paths ===
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

if [ -n "$file_path" ]; then
    # TW-tuned protected patterns:
    # - Environment files (.env, .env.production, .env.local)
    # - SSH keys (id_rsa, id_ed25519)
    # - TLS certificates (.pem, .key)
    # - Cloud credentials (.aws/, .docker/config.json)
    # - Git credentials (.git-credentials)
    # - TW-specific: homeserver.yaml, synapse-data/, Vault token files
    protected_patterns='\.env($|\.)|\.ssh/|id_rsa|id_ed25519|\.pem$|\.key$|\.p12$|\.pfx$|\.aws/|\.docker/config\.json|\.git-credentials|\.netrc|\.npmrc|\.pypirc|\.pgpass|\.htpasswd|homeserver\.yaml|synapse-data/|vault-token|\.vault-token'

    if echo "$file_path" | grep -qiE "$protected_patterns"; then
        echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Cannot write to protected file: $file_path\"}}"
        exit 0
    fi
fi

# === 2. Secret detection in content ===
content=$(echo "$input" | jq -r '(.tool_input.content // "") + (.tool_input.new_string // "")' 2>/dev/null || echo "")

if [ -n "$content" ]; then
    # TW-tuned secret patterns:
    # - Anthropic API keys (sk-ant-)
    # - OpenAI API keys (sk-)
    # - GitHub tokens (ghp_, gho_, ghu_, ghs_, ghr_)
    # - Vault tokens (hvs.)
    # - Matrix access tokens (syt_)
    # - PEM private keys
    # - Generic long base64 tokens after common key prefixes
    # - OB1/Supabase keys (eyJ — JWT prefix)
    secret_patterns='sk-ant-[a-zA-Z0-9]{20,}|sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|ghu_[a-zA-Z0-9]{36}|ghs_[a-zA-Z0-9]{36}|ghr_[a-zA-Z0-9]{36}|hvs\.[a-zA-Z0-9]{20,}|syt_[a-zA-Z0-9]{20,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|xox[bpsar]-[a-zA-Z0-9-]+'

    if echo "$content" | grep -qE "$secret_patterns"; then
        echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Potential secret/API key detected in content. Use Vault or env vars instead."}}'
        exit 0
    fi
fi

exit 0
