# App Note: Claude Code Hook Patterns & Operational Insights

Extracted from the Aedelon blueprint source code by Code 🔧 for TW cognates.
These are the implementation details that aren't obvious from the file structure.

## 1. The Fail-Closed ERR Trap

The most important pattern in the entire blueprint. Every PreToolUse hook uses:

```bash
set -euo pipefail
trap 'echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Hook error - fail-closed\"}}"; exit 0' ERR
```

**Why this matters:** If `jq` fails to parse input, if the JSON format changes between Claude Code versions, if a regex is malformed, if any command returns non-zero — the hook **denies the operation**. The only way a command passes is if the hook runs to completion without error and exits without output.

**The trap MUST `exit 0`.** Claude Code treats non-zero hook exits as hook failures, not as denials. The denial must come through the JSON output, not the exit code.

**TW implication:** When tuning bash-guard or write-guard patterns, a regex typo doesn't create a gap — it creates a block. You'll notice immediately because operations start failing, not because secrets leak. This is the right failure mode for a zero-trust system.

## 2. Hook Input/Output Protocol

Each hook lifecycle event receives different JSON on stdin and expects different JSON output. Getting these wrong means the hook silently does nothing.

| Event | stdin contains | Output format | Effect |
|---|---|---|---|
| PreToolUse | `tool_input.command`, `tool_input.file_path`, `tool_input.content`, `tool_input.new_string` | `{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"..."}}` | Blocks the operation |
| PostToolUse | `tool_input.*` + `tool_response`/`stdout` | `{"systemMessage":"..."}` | Injects warning into context |
| UserPromptSubmit | `prompt` | `{"systemMessage":"..."}` | Injects warning before processing |
| SessionStart | `session_id`, `cwd`, `source` | `{"hookSpecificOutput":{"additionalContext":"..."}}` | Adds context to session |
| PreCompact | (minimal) | `{"systemMessage":"..."}` | Injects reminder before compaction |
| PermissionRequest | `tool_input.*` | `{"systemMessage":"..."}` | Adds warning (does NOT block) |
| Stop | (none meaningful) | stdout text | Displayed to user |
| SessionEnd | (minimal) | stdout text | Displayed to user |
| PostToolUseFailure | `tool_name`, `error`/`stderr` | (none expected) | Side-effect only (logging) |

**Key distinction:** Only PreToolUse hooks can DENY operations. All other hooks can only WARN via `systemMessage` or ADD CONTEXT via `additionalContext`. PermissionRequest hooks warn but don't block — the user still gets the approval prompt.

## 3. Hook Timeout Tuning

The author's timeout choices encode operational experience:

| Hook | Timeout | Why |
|---|---|---|
| session-start | 5s | Reads git state, detects project type, lists commands |
| session-end | 3s | Just git status check |
| user-prompt-secrets | 2s | Pure regex, no I/O |
| bash-guard | 3s | Pure regex on command string |
| write-guard | 3s | Regex on file path + content |
| write-format | **15s** | Must invoke external formatter (prettier/ruff) |
| permission-git | 2s | Pure regex |
| bash-vuln | 3s | Grep on stdout, no external calls |
| pre-compact | 5s | Git state + file write |
| stop | 5s | Git status + diff |
| posttooluse-failure | 3s | Log write |

**The outlier is write-format at 15s.** If `npx prettier` needs to download on first use, it can take several seconds. On subsequent calls it's fast (cached). If your formatter isn't installed and npx tries to fetch it every time, this hook will add latency to every write. Consider pre-installing formatters in your environment.

**TW-specific:** Our External RAM hydration hook has 10s timeout because it reads JSON files and runs Python. This is generous but justified — if hydration times out, the cognate starts without context, which is worse than a slow start.

## 4. Pre vs Post: Placement Matters

| Pattern | When | Why |
|---|---|---|
| bash-guard | **Pre**ToolUse | Must block BEFORE the command runs. A post-check on `rm -rf /` is too late. |
| write-guard | **Pre**ToolUse | Must block BEFORE secrets are written to disk. |
| write-format | **Post**ToolUse | Format AFTER the write succeeds. The file must exist before prettier can format it. |
| bash-vuln | **Post**ToolUse | Check for vulns AFTER install completes. The audit data only exists post-install. |
| permission-git | **Permission**Request | Warn when user is prompted for approval, not before or after. Gives user context for their decision. |

**Design principle:** Pre hooks are gates (can deny). Post hooks are quality checks (can warn). Permission hooks are advisories (inform the user's decision).

## 5. The Smart Exclusion Pattern

`user-prompt-secrets.sh` detects secret mentions but excludes questions ABOUT secrets:

```bash
if echo "$prompt" | grep -qiE '(password|api.?key|secret|token|credential)'; then
    if ! echo "$prompt" | grep -qiE '(how|help|what is)'; then
        echo '{"systemMessage":"Warning: your prompt mentions sensitive information."}'
    fi
fi
```

**Why:** "How do I rotate my API key?" should not trigger a warning. "Here's my API key: sk-ant-..." should. The exclusion pattern prevents the hook from crying wolf on legitimate security questions.

**TW adaptation opportunity:** We could extend the exclusion list with TW-specific patterns: "vault", "keychain", "credential rotation", "token refresh" — all legitimate operational discussions that mention secrets without exposing them.

## 6. Silent vs Loud Failure

The blueprint uses two distinct failure strategies:

**Silent failure (`|| true`):** write-format.sh. If prettier isn't installed, the file just doesn't get formatted. No error, no warning, no block. This is correct — formatting is nice-to-have, not a safety gate.

**Loud failure (fail-closed trap):** bash-guard.sh, write-guard.sh. If regex parsing fails, the operation is denied. This is correct — security is a hard requirement, not a nice-to-have.

**TW principle:** Match failure mode to consequence. Security hooks fail loud. Quality hooks fail silent. Never the reverse.

## 7. Cross-Platform Portability

`posttooluse-failure.sh` handles macOS vs Linux `stat`:
```bash
stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null
```

**TW implication:** We run on Mac (Code's primary substrate) and DGX (Linux). Every hook script that uses platform-specific commands needs this pattern. Watch for: `stat`, `sed` (BSD vs GNU), `date` flags, `readlink` vs `realpath`.

## 8. The Three-Layer Security Model

Static permissions, dynamic hooks, and CLAUDE.md rules are three independent layers:

```
Static permissions (settings.json deny list)
  → Catches: known dangerous tool patterns
  → Bypass: impossible (enforced by Claude Code runtime)
  → Weakness: can only match tool name + argument prefix

Dynamic hooks (bash-guard, write-guard)
  → Catches: content patterns, obfuscation, context-dependent threats
  → Bypass: only if hook script has a regex gap
  → Weakness: regex is imperfect, can false-positive or false-negative

CLAUDE.md rules (kernel instructions)
  → Catches: behavioral patterns (warn before force push, explain before destructive)
  → Bypass: prompt injection, context pressure, instruction-following limits
  → Weakness: soft enforcement, model can ignore under pressure
```

**An attacker needs to bypass ALL THREE simultaneously.** Static permissions can't be bypassed at all — they're enforced at the runtime level, not the model level. This means even a successful prompt injection still can't run `sudo` or write to `~/.ssh/`.

## 9. Environment Variable Tuning

```json
"BASH_DEFAULT_TIMEOUT_MS": "300000",
"MAX_MCP_OUTPUT_TOKENS": "25000"
```

- **300s bash timeout:** Long builds, test suites, DGX operations can take minutes. The default (120s) kills legitimate long-running commands.
- **25k MCP output tokens:** Large MCP responses (Linear issue lists, OB1 thought dumps) get truncated at the default. 25k gives room for substantial responses without context blowout.

## 10. The Matcher Pattern

```json
{"matcher": "Write|Edit", "hooks": [...]}
{"matcher": "Bash", "hooks": [...]}
```

Without a `matcher`, hooks run on ALL tool calls. This matters for performance:
- write-guard should NOT run on Bash calls (wasted work, potential false positives on command strings)
- bash-guard should NOT run on Write calls
- write-format should NOT run on Read calls

**Always scope hooks to the tools they inspect.** An unscoped PreToolUse hook that shells out to an external tool adds latency to EVERY tool call.

## 11. Operational Data from the Author's Article

The following insights come from Delanoe Pirard's Medium article (Mar 3, 2026) and represent
field-tested observations from daily use, not just code analysis.

### Hook latency: sub-100ms in practice

> "In practice, my hooks execute in under 100ms."

Only `write-format.sh` is slow (calls external formatter). All security hooks (bash-guard,
write-guard, permission-git, user-prompt-secrets) are pure regex on stdin — effectively
instant. **TW implication:** hook latency is not a concern for our security gates. The only
hook that might cause perceptible delay is write-format, and only if npx needs to fetch
prettier on first use.

### Skill loading: 2-4 active simultaneously

> "In practice, 2 to 4 skills are loaded simultaneously, rarely more."

Despite 32 skills existing, lazy loading keeps context lean. The `description` field in
skill frontmatter is the trigger — Claude matches it against conversation context.
**TW implication:** we can add many skills without context bloat, as long as descriptions
are precise and don't overlap.

### Agent verbosity: less is more

The author started with 18 agents, trimmed to 10. Three code-focused agents (python-expert,
typescript-expert, frontend-developer) were replaced entirely by Claude Code plugins.
Remaining agents were trimmed **-70% in verbosity** on average.

> "An agent doesn't need a novel to be effective. It needs a precise description
> and the right tools."

**TW implication:** our cognate agent stubs should stay lean. The identity and capability
come from AGENTS.md + Cognate Registry, not from verbose agent .md files. This validates
our SEED approach — keep agent files minimal, let the governance layer carry the weight.

### Debugging hooks: stderr is your friend

> "Hooks write to stderr for debugging (invisible to Claude but visible in logs).
> I add `echo "DEBUG: ..." >&2` during development."

stderr output from hooks is invisible to Claude's context but visible in the terminal
and log files. This is the correct debugging channel — it doesn't consume tokens or
pollute the conversation.

### Known fragility: jq + JSON format dependency

> "Hooks depend on jq, grep, and a stable JSON format from Claude Code. An update
> to the input format could break the system. I don't have automated tests for
> the hooks themselves."

The author has NO automated tests for hooks. This is an acknowledged gap. If Anthropic
changes the JSON schema for hook stdin, every hook breaks simultaneously. The fail-closed
trap catches this (denies rather than allows), but it means a Claude Code update could
block ALL operations until hooks are fixed.

**TW mitigation:** the TWC-1920 switcher. If hooks break after a Claude Code update,
revert to `legacy-tw` profile (which has only External RAM hooks, battle-tested).
This is exactly the rollback path Gabe called for.

### Regex is not security — it's a heuristic

> "A base64-encoded or multi-line secret would pass through. This is not a
> substitute for a secrets manager."

The author explicitly acknowledges write-guard's limits. Regex catches the most common
accidental leaks but not determined obfuscation. **TW implication:** this reinforces
our Vault-first architecture. write-guard is a safety net, not a vault. Vault is the
vault. The hook catches accidents; Vault prevents them.

### HTTP hooks: future observability channel

> "HTTP hooks open interesting possibilities: send every tool failure to a Slack
> webhook, push security metrics to a dashboard, or delegate allow/deny decisions
> to a centralized service."

Claude Code hooks support `"type": "http"` — POST JSON to a URL, receive JSON back.
**TW opportunity:** we could route PostToolUseFailure events to a Matrix room via
the CC bridge, giving the federation real-time observability on tool failures across
all cognate sessions. Not urgent, but architecturally interesting for Phase 3+.

### Agent Teams = TW's cognate federation

> "Instead of a single Claude Code instance orchestrating silent sub-agents,
> multiple instances collaborate in parallel with direct communication between
> teammates."

The author sees `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` as the evolution from
single-core to multi-core OS. This maps directly to TW's cognate federation model.
The difference: TW already has governance (AGENTS.md, cognate identity, MCR) where
the blueprint author is just discovering the coordination problem. TW is ahead here.

---

*Extracted by Code 🔧 from Aedelon/claude-code-blueprint source code + author's Medium article, 2026-03-23.*
*For TW federation cognates operating on or extending the blueprint wiring.*
