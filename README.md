# TW Claude Code Blueprint

TW-adapted fork of [aedelon/claude-code-blueprint](https://github.com/aedelon/claude-code-blueprint).

Standard Claude Code project wiring for all TW repos. Every repo gets this as
baseline with TW-specific constraints (Vault, cognate identity, External RAM,
ThinkJob discipline).

## Structure

```
.
├── CLAUDE.md                  ← Kernel template (merged with repo CLAUDE.md)
├── AUTHORITY-MATRIX.md        ← Governance: what outranks what
├── settings.template.json     ← Permissions, deny rules, hooks
├── hooks/
│   └── scripts/               ← Blueprint hooks (SEED/ADDITIVE)
│       ├── bash-guard.sh      ← TW-tuned destructive command blocker
│       ├── write-guard.sh     ← TW-tuned secret detection
│       ├── permission-git.sh  ← Git safety warnings
│       ├── session-start.sh   ← Project detection + context
│       ├── session-end.sh     ← Uncommitted file warning
│       ├── write-format.sh    ← Auto-format post-write
│       ├── stop.sh            ← Git summary on task finish
│       ├── bash-vuln.sh       ← Dependency vulnerability detection
│       ├── pre-compact.sh     ← Git state logging before compaction
│       ├── posttooluse-failure.sh ← Tool failure logging
│       └── user-prompt-secrets.sh ← Prompt secret scanning
├── rules/
│   ├── typescript.md          ← TS conventions (pnpm v10, ADR-001)
│   └── python.md              ← Python conventions (uv, ruff)
├── skills/
│   ├── anti-hallucination/    ← Zero-trust verification protocol
│   ├── commit-message/        ← TW conventional commits
│   ├── security-audit/        ← OWASP checklist
│   ├── core-protocols/        ← Debugging protocol
│   ├── code-patterns/         ← Reference patterns
│   ├── research-protocol/     ← Source triangulation
│   ├── brainstorm/            ← Multi-agent ideation
│   └── uv-workflow/           ← Python package management
├── agents/
│   ├── research-synthesizer.md ← OB1-aware research agent
│   └── prompt-engineer.md     ← Prompt/BIOS design agent
├── commands/
│   ├── agent.md               ← /agent <name> switcher
│   └── review.md              ← /review code review
└── docs/
    └── architecture.md        ← 6-layer model documentation
```

## Authority Model

See [AUTHORITY-MATRIX.md](AUTHORITY-MATRIX.md) for the full governance contract.

Every blueprint surface declares its relationship to existing TW conventions:

| Level | Meaning |
|-------|---------|
| **ADR-PROTECTED** | Architecture Decision Record governs it. Cannot replace without new ADR. |
| **TW-CANONICAL** | Authoritative TW convention. Blueprint conforms to it. |
| **SEED** | Starting point, expected to be tuned for TW. |
| **ADDITIVE** | New capability, no TW equivalent exists. |
| **DROPPED** | Not applicable to TW. |

## Rollout (TWC-1920)

Blueprint convergence uses a profile switcher for safe, reversible rollout:

| Profile | What's Active |
|---------|--------------|
| `legacy-tw` | Current EP5 `.claude/` wiring exactly as-is (default) |
| `hybrid-canary` | Legacy kernel + selected blueprint additions |
| `tw-blueprint` | Full TW-adapted blueprint wiring |

**Invariant across all profiles:** External RAM hooks (ADR-005), CLAUDE.md kernel,
AGENTS.md, cognate identity conventions.

## Deploying to a TW Repo

1. Copy desired blueprint surfaces into the repo's `.claude/` directory
2. Merge CLAUDE.md template sections into the repo's existing CLAUDE.md
3. Adapt settings.template.json to the repo's needs (start with `legacy-tw` profile)
4. Test with one cognate session before activating for all

## Linear Tracking

| Issue | Scope |
|-------|-------|
| TWC-1859 | EPIC: Blueprint convergence |
| TWC-1866 | This fork adaptation |
| TWC-1867 | EP5 deployment |
| TWC-1869 | Template for new repos |
| TWC-1920 | Switcher/rollback mechanism |

## Credits

- Original blueprint: [Aedelon/claude-code-blueprint](https://github.com/aedelon/claude-code-blueprint) (Apache 2.0)
- TW adaptation: Code 🔧 (TWC-1866)
- Governance guardrails: Gabe/Codex ⟐
- Architecture context: Glasswork

---

Built by ThinkingIdentities federation. 2026.
