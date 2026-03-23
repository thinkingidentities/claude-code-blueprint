---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "tsconfig.json"
  - "package.json"
---

# TypeScript Conventions

## Tooling
- Formatter: `prettier`
- Linter: `eslint`
- Tests: `vitest` (preferred) or `jest`
- Package manager: `pnpm` v10 (ADR-001 zero-trust dependency model). Never npm/yarn/bun.

## Code Style
- Strict mode: `strict: true` in tsconfig
- Prefer `interface` for object shapes, `type` for unions/intersections
- Prefer `const` assertions and `satisfies` over `as` casts
- Use discriminated unions over optional fields for variants
- Prefer `unknown` over `any`, narrow with type guards
- No enums — use `as const` objects or string literal unions

## React (when .tsx)
- Functional components only, no class components
- Props as interface: `interface ButtonProps { ... }`
- Prefer Server Components (Next.js), add `"use client"` only when needed
- Use `cn()` (clsx/tailwind-merge) for conditional classes

## Testing Patterns
- File naming: `<module>.test.ts` or `__tests__/<module>.test.ts`
- Use `describe`/`it` blocks, `expect` assertions
- Mock with `vi.mock()` (vitest) or `jest.mock()`

## Validation Command
After writing TS code, always suggest: `pnpm tsc --noEmit && pnpm test`

## TW-Specific
- Never hardcode IPs or substrate-specific paths (use hostnames, env vars)
- Vault access via `tw-vault.sh` or Vault MCP sidecar, never hardcoded tokens
- Deno for MCP servers and OB1 services (not Node.js)
