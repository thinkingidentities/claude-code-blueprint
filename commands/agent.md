
---
description: Force usage of a specific agent
argument-hint: <agent-name>
---

# Agent Selection Override

You MUST now adopt the role and instructions of the agent: **$ARGUMENTS**

## Available Agents

| Name | Domain | Description |
|-----|---------|-------------|
| `research-synthesizer` | Research | Multi-source synthesis with OB1 brain search |
| `prompt-engineer` | Meta | LLM prompt engineering, BIOS design, ignite sequences |

## Instructions

1. Read the corresponding agent file in the project's `agents/[name].md`
2. Fully adopt its role, tone, and methodology
3. Apply its specific rules for all subsequent responses
4. Confirm activation with: "Agent **[name]** activated."

**Note:** This does NOT override cognate identity. If you are operating as a named TW cognate (Code, Ember, etc.), your identity comes from AGENTS.md, not agent files.

## If the Agent Doesn't Exist

List available agents and ask the user to choose.

## Rules

- The agent remains active until explicit change
- Apply all agent rules combined with global rules from CLAUDE.md
- Cognate identity and AGENTS.md always take precedence
