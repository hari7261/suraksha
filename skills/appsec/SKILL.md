---
name: appsec
description: |
  Application security engineering skill for AI coding agents. Loads
  task-scoped security references via progressive disclosure and enforces
  deterministic review checks when implementing or auditing security-sensitive code.
license: Apache-2.0
version: 0.1.0
min_engine_version: 0.1.0
activation_triggers:
  - keywords: [auth, login, signup, password, jwt, session, oauth]
  - keywords: [api, endpoint, route, graphql, webhook, cors]
  - keywords: [sql, query, database, orm, migration, postgres, mysql, sqlite]
  - keywords: [upload, file, path, download, deserialize, subprocess]
  - keywords: [permission, role, admin, authorization, rbac, idor, tenant]
  - keywords: [secret, key, credential, token, env, encrypt, hash]
  - keywords: [llm, rag, agent, mcp, tool, prompt, embedding, vector]
  - keywords: [docker, kubernetes, terraform, iac, ci, cd, cloud, iam]
  - keywords: [mobile, android, ios, react-native, expo, deep-link, webview]
  - keywords: [scan, audit, vulnerability, security review, threat model]
---

# Suraksha AppSec Skill

You are operating with **Suraksha AppSec** guidance. Apply security engineering
disciplines proportionally to the task and detected technology stack. Do **not**
preload every reference file; load only the references required for the current
change.

## Canonical Activation Logic

Always start with [security-principles.md](references/security-principles.md)
for the canonical routing table. Load domain references strictly on demand:

| Task / Stack Signal | Reference to Load |
|---|---|
| Threat model, trust boundaries, design review | [threat-modeling.md](references/threat-modeling.md) |
| SQL queries, ORMs, migrations, raw SQL | [sql-security.md](references/sql-security.md) |
| Login, passwords, MFA, JWT, sessions, OAuth/OIDC | [authentication.md](references/authentication.md) |
| RBAC, ABAC, IDOR/BOLA, tenant isolation | [authorization.md](references/authorization.md) |
| REST/GraphQL endpoints, rate limits, SSRF, webhooks | [api-security.md](references/api-security.md) |
| React, Next.js, DOM, XSS, CSRF, CSP, cookies | [frontend-security.md](references/frontend-security.md) |
| Uploads, command execution, path traversal, errors | [backend-security.md](references/backend-security.md) |
| DB privileges, TLS, encryption at rest, backups | [database-security.md](references/database-security.md) |
| Hashing, symmetric/asymmetric crypto, randomness | [cryptography.md](references/cryptography.md) |
| API keys, `.env`, vault/KMS, key rotation | [secrets-management.md](references/secrets-management.md) |
| Lockfiles, CVEs, supply chain, SBOM | [dependency-security.md](references/dependency-security.md) |
| React Native, Expo, Android, iOS, Keychain/Keystore | [mobile-security.md](references/mobile-security.md) |
| AWS/Azure/GCP IAM, storage buckets, network rules | [cloud-security.md](references/cloud-security.md) |
| Dockerfiles, Kubernetes contexts, CI/CD secrets | [container-security.md](references/container-security.md) |
| Tool-calling agents, prompt injection, sandboxing | [ai-agent-security.md](references/ai-agent-security.md) |
| Vector search, document ACLs, data poisoning | [rag-security.md](references/rag-security.md) |
| MCP servers, tool permissions, untrusted resources | [mcp-security.md](references/mcp-security.md) |
| Audit logs, PII redaction, error sanitization | [logging-and-privacy.md](references/logging-and-privacy.md) |

## Required Agent Workflow

1. **Identify scope:** Clarify affected files, endpoints, models, and trust boundaries.
2. **Inspect conventions:** Read existing project auth, validation, and config patterns first.
3. **Detect stack:** Identify languages, frameworks, databases, and infra from manifests.
4. **Select references:** Load only the matching files from `references/` above.
5. **Implement securely:** Use framework-native safe APIs and secure defaults.
6. **Check dangerous patterns:** Audit both new and modified code for injection, auth bypass, secret exposure, and unsafe I/O.
7. **Run deterministic checks:** When a shell is available, run locally installed tools on changed scope (e.g., `semgrep`, `bandit`, `gitleaks`, `trivy`, `pip-audit`, `npm audit`, `pytest`). Never fabricate results if no tool is installed.
8. **Review diff:** Inspect your final diff for unintended privilege, CORS, or config changes.
9. **Explain concisely:** Summarize key security decisions in 1–2 sentences each without lecturing.
10. **Report gaps honestly:** List unresolved risks, skipped/unavailable checks, and manual verification items. Use templates in [templates/](templates/security-review.md) when structured reports are requested.

## Explicit Prohibitions

NEVER do any of the following, even in "quick prototypes" or tests:
- Hardcode secrets, API keys, passwords, tokens, or private keys.
- Store plaintext passwords or use fast/reversible hashes (MD5, SHA-1, plain SHA-256) for passwords.
- Build SQL queries via string concatenation, f-strings, or template literals.
- Disable TLS/SSL certificate verification (`verify=False`, `NODE_TLS_REJECT_UNAUTHORIZED=0`).
- Trust client-side authorization checks or client-supplied role/tenant claims.
- Expose internal stack traces, SQL errors, or secrets in API responses.
- Log credentials, bearer tokens, session IDs, or unredacted sensitive request bodies.
- Join or open user-supplied file paths without canonicalization and root-boundary checks.
- Execute shell commands with user-controlled strings (`shell=True`, `exec(userInput)`).
- Grant AI agents unrestricted shell, filesystem, or external tool permissions.
- Present LLM-generated review text as deterministic scan evidence.
- Silently rewrite unrelated application code when fixing a security issue.

## Output Templates

- Security Review: [templates/security-review.md](templates/security-review.md)
- Threat Model: [templates/threat-model.md](templates/threat-model.md)
- Remediation Plan: [templates/remediation-plan.md](templates/remediation-plan.md)

