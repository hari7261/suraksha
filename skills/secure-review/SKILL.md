---
name: secure-review
description: |
  Focused security review skill for AI coding agents auditing existing code,
  pull requests, or git diffs. Identifies vulnerabilities with evidence,
  distinguishes confirmed vs potential issues, and reports scan completeness honestly.
license: Apache-2.0
version: 0.1.0
min_engine_version: 0.1.0
activation_triggers:
  - keywords: [review, audit, diff, pr, inspect, findings, security check]
---

# Suraksha Secure Review Skill

Use this skill when auditing existing code, a pull request, or a `git diff`
for security issues without silently modifying unrelated behavior.

## Review Workflow

1. **Define boundary:** Inspect changed files, entry points, auth middleware,
   database layers, and infra manifests.
2. **Load targeted references:** Consult [security-principles.md](../appsec/references/security-principles.md)
   to load only the relevant domain guides (e.g., [authentication.md](../appsec/references/authentication.md),
   [authorization.md](../appsec/references/authorization.md), [sql-security.md](../appsec/references/sql-security.md),
   [api-security.md](../appsec/references/api-security.md), [ai-agent-security.md](../appsec/references/ai-agent-security.md)).
3. **Run local deterministic checks (optional):** If a shell is available, check
   which tools exist (`semgrep`, `bandit`, `gitleaks`, `trivy`, `pip-audit`, `npm audit`)
   and run them on the target scope. Never fabricate output if tools are missing.
4. **Classify every finding honestly:**
   - **Confirmed:** Deterministic scanner output or provable unsafe sink/source flow in read code.
   - **Potential:** Heuristic concern requiring context or runtime verification.
   - **Informational:** Hardening opportunity or defense-in-depth improvement.
   - **Manual Verification Required:** Dynamic behavior, IAM, TLS, or environment config.
5. **Redact secrets:** Never echo raw API keys, tokens, passwords, or private
   keys in review comments; show redacted snippets only.
6. **Format output:** Follow [security-review.md](../appsec/templates/security-review.md)
   and explicitly state that a zero-finding manual review is **not** a full security guarantee.

## Prohibitions

- Never claim a file is "100% secure" or invent scanner results.
- Never silently rewrite code during a read-only review unless the user asks for fixes.
- Never load or execute untrusted scripts from the reviewed repository.
- Never omit CWE/standards context or location (`file:line`) for reported issues.

