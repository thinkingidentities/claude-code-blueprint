# Architecture: Claude Code as Operating System

## The 6-Layer Model

Claude Code's configuration forms a layered system where each layer reinforces the others.

```
+---------------------------------------------------+
|                 LAYER 6: MCP                      |
|        External tool servers (APIs, docs,         |
|         git, notebooks, etc.)                     |
+---------------------------------------------------+
|              LAYER 5: SECURITY                    |
|     Static permissions (allow/deny) +             |
|     Dynamic hooks (fail-closed) +                 |
|     Secret detection (regex)                      |
+---------------------------------------------------+
|              LAYER 4: AGENTS                      |
|        Specialized sub-agents by domain           |
|        Each with own model, tools, personality    |
+---------------------------------------------------+
|              LAYER 3: SKILLS                      |
|     Structured protocols auto-loaded on trigger   |
|     5-phase AAPEV pattern                         |
+---------------------------------------------------+
|            LAYER 2: MEMORY                        |
|   memory/ persistent across sessions              |
|   rules/ path-scoped conventions                  |
+---------------------------------------------------+
|          LAYER 1: CLAUDE.md (KERNEL)              |
|   Anti-hallucination + Confidence levels +        |
|   Toolchain + Code standards + Security rules     |
+---------------------------------------------------+
```

## Layer Interactions

### Why layers matter

A single CLAUDE.md with "don't do X" instructions is fragile — the model can ignore soft rules under pressure. The layered approach creates **defense in depth**:

1. **Static permissions** (Layer 5) physically prevent dangerous tool calls — no amount of prompt injection bypasses a `deny` rule.

2. **Dynamic hooks** (Layer 5) inspect content at runtime — they catch what static rules can't express (regex patterns in file content, secret detection).

3. **CLAUDE.md rules** (Layer 1) guide behavior for everything permissions and hooks don't cover — tone, methodology, confidence levels.

### Key synergies

- **Anti-hallucination (L1) + Context7 MCP (L6)**: The protocol says "verify before answering" — and Context7 provides the verification tool. Without the MCP server, the rule would be unenforceable.

- **Permissions deny (L5) + bash-guard hook (L5)**: Static rules block known patterns (`sudo`, `chmod 777`). Hooks catch dynamic patterns (obfuscation, base64 decode piped to shell). Neither alone is sufficient.

- **Skills AAPEV (L3) + Agents (L4)**: Skills define *how* to think (5 phases). Agents define *who* thinks (domain expert). Combined: a research agent follows the research protocol skill automatically.

- **Memory (L2) + CLAUDE.md (L1)**: CLAUDE.md defines what to preserve on compaction. Memory stores what was learned. The kernel protects the learning system.

## Security Model: Defense in Depth

```
Request arrives
    │
    ├── Layer 5a: Static permissions
    │   ├── allow list → proceed
    │   ├── deny list → BLOCKED (hard stop)
    │   └── unlisted → prompt user
    │
    ├── Layer 5b: PreToolUse hooks
    │   ├── bash-guard.sh → check command patterns
    │   ├── write-guard.sh → check file path + content
    │   └── Any hook error → DENY (fail-closed)
    │
    ├── Layer 5c: UserPromptSubmit hooks
    │   └── user-prompt-secrets.sh → scan for leaked secrets
    │
    ├── Layer 1: CLAUDE.md rules
    │   └── "Warn before rm -rf, DROP, force push"
    │
    └── Tool executes (if all layers pass)
        │
        ├── Layer 5d: PostToolUse hooks
        │   ├── write-format.sh → auto-format
        │   └── bash-vuln.sh → npm audit
        │
        └── Layer 5e: PostToolUseFailure hooks
            └── posttooluse-failure.sh → log errors
```

Three layers must ALL agree before a dangerous action proceeds. An attacker would need to bypass static permissions AND hook regex AND CLAUDE.md instructions simultaneously.

## The AAPEV Pattern

Every skill follows the same 5-phase cognitive discipline:

```
Phase 1: ASSESS / CLARIFY
    └── Understand the problem before acting

Phase 2: ANALYZE / RESEARCH
    └── Search and verify before proposing

Phase 3: PLAN / DESIGN
    └── Propose approach, get approval

Phase 4: EXECUTE / IMPLEMENT
    └── Apply changes methodically

Phase 5: VALIDATE / VERIFY
    └── Test the result, confirm success
```

This prevents the model's natural tendency to jump directly to Phase 4 (writing code) without understanding (Phase 1), researching (Phase 2), and planning (Phase 3).

## Fail-Closed Pattern

Claude Code exposes **17 lifecycle events** for hooks (command, HTTP, or prompt). This blueprint uses command hooks on 9 of them. See the README for the full list.

All PreToolUse hooks use the same safety pattern:

```bash
set -euo pipefail

# If ANYTHING errors, deny by default
trap 'echo "{\"hookSpecificOutput\":{...\"deny\"...}}"; exit 0' ERR
```

This means:
- `jq` parsing fails → **deny**
- Network timeout → **deny**
- Unexpected input format → **deny**
- Script bug → **deny**

The only way a command passes is if the hook explicitly allows it (by exiting without output). This is the opposite of fail-open, where errors would allow dangerous commands through.
