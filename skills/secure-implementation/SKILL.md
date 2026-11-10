---
name: secure-implementation
description: |
  Preventive secure-coding skill for AI agents implementing new features,
  endpoints, auth flows, database queries, uploads, cloud configs, or AI tool
  integrations using framework-native secure defaults.
license: Apache-2.0
version: 0.1.0
min_engine_version: 0.1.0
activation_triggers:
  - keywords: [implement, build, create, add endpoint, feature, auth flow, upload, query]
---

# Suraksha Secure Implementation Skill

Use this skill during feature creation (**Mode A — Preventive Engineering**) to
design and write secure code from the start rather than patching flaws later.

## Implementation Workflow

1. **Discover conventions:** Read existing project structure, middleware,
   validators, ORMs, and secret-loading patterns before writing new code.
2. **Load only task-relevant references:** Use [security-principles.md](../appsec/references/security-principles.md)
   to pick the exact guides needed (for example, [sql-security.md](../appsec/references/sql-security.md)
   for DB work, [frontend-security.md](../appsec/references/frontend-security.md) for UI,
   [ai-agent-security.md](../appsec/references/ai-agent-security.md) / [mcp-security.md](../appsec/references/mcp-security.md) for AI tools).
3. **Apply secure-by-default controls:**
   - Deny-by-default authorization on every route and object lookup.
   - Strict schema validation on all inputs (types, bounds, allowlists).
   - Parameterized queries, safe path canonicalization, and `argv`-only subprocesses.
   - Secrets loaded from environment/secret managers, never committed defaults.
   - Generic user-facing errors paired with redacted structured logs.
4. **Write security tests alongside feature tests:** Test negative/unauthorized
   cases (401/403, invalid input, path traversal, cross-tenant access).
5. **Self-review diff & summarize:** Check touched files against prohibitions in
   [appsec SKILL.md](../appsec/SKILL.md), run available local tests/linters, and
   concisely document security assumptions and remaining manual checks.

## Prohibitions

- Never introduce hardcoded fallback secrets (`os.getenv("KEY", "dev-secret")` in prod paths).
- Never skip server-side ownership/tenant checks because a UI hides a button.
- Never disable TLS verification, CSRF protection, or CORS origin checks to fix a dev error.
- Never expose stack traces or raw database errors to HTTP clients.

