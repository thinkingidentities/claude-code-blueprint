# TW Authority / Merge Matrix

Every imported blueprint surface must declare its relationship to existing TW conventions.
This matrix is the governance contract for blueprint convergence (TWC-1859).

## Authority Levels

| Level | Meaning |
|-------|---------|
| **ADR-PROTECTED** | Governed by an Architecture Decision Record. Cannot be replaced without new ADR. |
| **TW-CANONICAL** | Authoritative TW convention. Blueprint must conform to it, not outrank it. |
| **SEED** | Blueprint content adopted as starting point. Expected to be tuned for TW. |
| **ADDITIVE** | New capability from blueprint. No TW equivalent exists. Added alongside TW canon. |
| **DROPPED** | Blueprint content not applicable to TW. Removed from fork. |

## Layer 1: Kernel (CLAUDE.md)

| Blueprint Surface | TW Surface | Authority | Notes |
|---|---|---|---|
| `CLAUDE.md` (generic kernel) | `CLAUDE.md` (ThinkJob, cognate identity, External RAM, Vault, worktree discipline) | **TW-CANONICAL** | TW CLAUDE.md is the kernel. Blueprint CLAUDE.md sections merged only where they add missing coverage (anti-hallucination protocol, confidence levels, compact preservation). TW sections always win on conflict. |
| `AGENTS.md` (n/a in blueprint) | `AGENTS.md` (cognate roles, worktree discipline, substrate declarations) | **TW-CANONICAL** | No blueprint equivalent. Preserved as-is. Future: aligns with Cognate Registry (TWC-1921). |

## Layer 2: Memory & Rules

| Blueprint Surface | TW Surface | Authority | Notes |
|---|---|---|---|
| `memory/` directory | `.external-ram/` + `.claude/memory/` (auto-memory) | **ADR-PROTECTED** | ADR-005 establishes two-tier memory: External RAM (TW-BIOS continuity kernel) + OB1 (broad federated recall). Blueprint `memory/` maps to `.claude/memory/` (auto-memory), which is a third, lighter layer. All three coexist. External RAM hooks are invariant. |
| `rules/typescript.md` | (none — implicit in CLAUDE.md) | **SEED** | Adopt and extend with TW-specific: pnpm v10 (ADR-001), Vault patterns, DGX path conventions. |
| `rules/python.md` | (none — implicit) | **SEED** | Adopt. uv + ruff matches TW toolchain. Add TW-specific: checkpoint.py patterns, External RAM script conventions. |

## Layer 3: Skills

| Blueprint Surface | TW Surface | Authority | Notes |
|---|---|---|---|
| `skills/anti-hallucination/` | (none) | **ADDITIVE** | Aligns with TW zero-trust epistemics. Adopt with TW framing (SHOW don't SAY). |
| `skills/commit-message/` | CLAUDE.md commit conventions | **SEED** | Adapt to TW conventional commits (feat/fix/chore/docs + TWC-NNN references). |
| `skills/security-audit/` | (none) | **ADDITIVE** | Useful for infrastructure code. Adopt. |
| `skills/code-patterns/` | (none) | **SEED** | Adopt as reference. Tune patterns for TW stack (Deno, Supabase, Matrix SDK). |
| `skills/core-protocols/` | (none) | **ADDITIVE** | Debugging protocol. Adopt. |
| `skills/research-protocol/` | (none) | **SEED** | Adopt. Tune source hierarchy for TW (OB1 search, External RAM, Linear). |
| `skills/brainstorm/` | (none) | **ADDITIVE** | Multi-agent brainstorming. Adopt — fits cognate federation model. |
| `skills/uv-workflow/` | (none) | **SEED** | Python-specific. Adopt for Python services. |

## Layer 4: Agents

| Blueprint Surface | TW Surface | Authority | Notes |
|---|---|---|---|
| `agents/research-synthesizer.md` | (none) | **SEED** | Adapt as generic research agent stub. TW cognate identity comes from AGENTS.md + Cognate Registry, not agent .md files. |
| `agents/prompt-engineer.md` | (none) | **SEED** | Useful capability. Adapt for TW. |
| `agents/finance-advisor.md` | (none) | **DROPPED** | Not applicable to TW. |
| `agents/midjourney-expert.md` | (none) | **DROPPED** | Not applicable to TW. |

## Layer 5: Security (Settings + Hooks)

| Blueprint Surface | TW Surface | Authority | Notes |
|---|---|---|---|
| `settings.template.json` allow rules | `.claude/settings.json` (narrow: `python3:*` only) + `.claude/settings.local.json` (per-seat extensions) | **TW-CANONICAL** | TW's narrow posture is intentional. Blueprint allow rules adopted only where they match TW toolchain. Seat-specific allows stay in `settings.local.json`. |
| `settings.template.json` deny rules | (none — gap) | **ADDITIVE** | Blueprint deny rules fill a real gap. Adopt and extend with TW-specific: Vault token paths, Matrix secrets, DGX credential files, `.external-ram/` write protection (read OK, no delete). |
| `hooks/session-start.sh` | `.claude/hooks/external-ram-hydrate.sh` | **ADR-PROTECTED** | TW hook is ADR-005 protected. Blueprint session-start adds project detection — merge as additive context alongside External RAM hydration, never replacing it. |
| `hooks/pre-compact.sh` | `.claude/hooks/external-ram-compact-warn.sh` | **ADR-PROTECTED** | TW hook is ADR-005 protected. Blueprint pre-compact adds git state logging — merge as additive, never replacing. |
| `hooks/bash-guard.sh` | (none — gap) | **SEED** | Adopt. Needs TW tuning: allow Vault CLI, DGX SSH, checkpoint.py, External RAM scripts. Generic privilege escalation patterns are good baseline. |
| `hooks/write-guard.sh` | (none — gap) | **SEED** | Adopt. Needs TW tuning: add Vault token regex, Matrix access tokens, OB1 API keys, homeserver.yaml paths. |
| `hooks/permission-git.sh` | CLAUDE.md git safety rules | **ADDITIVE** | Reinforces existing TW git discipline with runtime enforcement. Adopt. |
| `hooks/write-format.sh` | (none) | **SEED** | Adopt. May need TW tuning for formatter paths. |
| `hooks/stop.sh` | (none) | **ADDITIVE** | Git summary on task finish. Supports "verify don't trust" principle. Adopt. |
| `hooks/session-end.sh` | (none) | **ADDITIVE** | Uncommitted file warning. Adopt. |
| `hooks/bash-vuln.sh` | (none) | **SEED** | Dependency vuln detection. Adopt as-is. |
| `hooks/posttooluse-failure.sh` | (none) | **ADDITIVE** | Tool failure logging. Adopt. |
| `hooks/user-prompt-secrets.sh` | (none) | **ADDITIVE** | Prompt secret scanning. Adopt. |

## Layer 6: MCP

| Blueprint Surface | TW Surface | Authority | Notes |
|---|---|---|---|
| `mcp__context7__*` | (not used) | **DROPPED** | TW uses OB1, Linear, GitHub MCPs instead. |
| `mcp__fetch__*` | (available via WebFetch) | **DROPPED** | Already available natively. |
| `mcp__git__*` | (via Bash git) | **DROPPED** | TW uses git via Bash with permission-git hook guard. |
| (none) | Linear MCP, GitHub MCP, OB1 MCP, Corpus Callosum MCP | **TW-CANONICAL** | TW MCP servers are seat-specific, configured in `.claude/settings.local.json`. Not templated. |

## Layer 7: Commands

| Blueprint Surface | TW Surface | Authority | Notes |
|---|---|---|---|
| `commands/review.md` | (none) | **ADDITIVE** | Code review command. Adopt. |
| `commands/docs.md` | (none — depends on Context7) | **DROPPED** | Depends on Context7 MCP which TW doesn't use. |
| `commands/agent.md` | (none) | **SEED** | Agent switcher. Adapt for TW cognate agent model. |
| (none) | `.claude/commands/agent-os/*` (shape-spec, discover-standards, etc.) | **TW-CANONICAL** | Existing TW commands preserved. Not in blueprint. |

## Profile Switcher Contract (TWC-1920)

The blueprint convergence uses a profile switcher to manage rollout:

| Profile | What's Active | Purpose |
|---|---|---|
| `legacy-tw` | Current EP5 `.claude/` wiring exactly as-is | Default. Zero behavior change. Safe fallback. |
| `tw-blueprint` | Full TW-adapted blueprint wiring | Target state after validation. |
| `hybrid-canary` | Legacy kernel + selected blueprint additions (deny rules, guards) | Incremental adoption. Test new surfaces one at a time. |

**Invariant across all profiles:** External RAM hooks (ADR-005), CLAUDE.md kernel, AGENTS.md, cognate identity conventions.

## Governance

- This matrix is a living document. Update it when authority changes.
- Any change from TW-CANONICAL or ADR-PROTECTED requires Jim's approval.
- SEED content can be tuned by any cognate with commit access.
- ADDITIVE content can be adopted or dropped by the implementing cognate.
- DROPPED content can be reconsidered if TW needs change.

---

*Created by Code 🔧 for TWC-1866. Reviewed against Gabe/Codex guardrails (TWC-1859 comment, 2026-03-23).*
