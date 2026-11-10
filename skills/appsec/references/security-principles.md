# Security Principles & Reference Routing

## 1. Objective
Establish the foundational engineering principles, canonical reference-selection logic, and evidence standards that govern all Suraksha Agent Skills.

## 2. Threat Model
- **AI-assisted implementation drift:** Coding agents optimize for "happy-path works" and omit authentication, authorization, validation, or redaction unless guided proportionally.
- **Context overload:** Loading every security document at once dilutes attention and causes missed domain-specific controls.
- **False assurance:** Treating LLM intuition as equivalent to deterministic verification hides exploitable defects.

## 3. Common Vulnerabilities
- Missing server-side enforcement behind UI-only validation.
- Implicit trust of user input, HTTP headers, client claims, or retrieved AI context.
- Mixing secret material into source code, logs, or error messages.
- Over-broad permissions on APIs, databases, containers, and AI tool runners.

## 4. Vulnerable Example
```python
# Anti-pattern: trusting client-supplied role and skipping deterministic checks
def update_user_role(request_json):
    # No caller auth check, no schema validation, echoes raw internal errors
    return db.execute(f"UPDATE users SET role='{request_json['role']}' WHERE id={request_json['id']}")
```

## 5. Secure Example
```python
# Secure pattern: explicit caller authz, validated schema, parameterized query
def update_user_role(actor, target_user_id: int, new_role: str):
    if actor.role != "admin":
        raise PermissionError("Forbidden")
    if new_role not in {"viewer", "editor"}:
        raise ValueError("Invalid role")
    db.execute("UPDATE users SET role = %s WHERE id = %s", (new_role, target_user_id))
```

### Canonical Reference Selection Routing
Load **only** the references matching the task and detected stack:
- `auth`, `login`, `signup`, `password`, `passwords`, `jwt`, `session`, `sessions`, `oauth` -> `authentication.md`
- `permission`, `permissions`, `role`, `roles`, `admin`, `rbac`, `abac`, `idor`, `tenant` -> `authorization.md`
- `sql`, `query`, `queries`, `database`, `databases`, `orm`, `migration`, `migrations`, `postgres`, `mysql`, `sqlite` -> `sql-security.md`, `database-security.md`
- `api`, `endpoint`, `endpoints`, `route`, `graphql`, `webhook`, `cors`, `ssrf` -> `api-security.md`
- `react`, `nextjs`, `html`, `dom`, `xss`, `csrf`, `csp`, `cookie`, `cookies` -> `frontend-security.md`
- `upload`, `uploads`, `file`, `files`, `path`, `download`, `subprocess`, `deserialize` -> `backend-security.md`
- `encrypt`, `decrypt`, `hash`, `hmac`, `tls`, `random`, `token`, `tokens` -> `cryptography.md`
- `secret`, `secrets`, `key`, `keys`, `credential`, `credentials`, `env`, `vault`, `kms` -> `secrets-management.md`
- `package`, `packages`, `lockfile`, `dependency`, `dependencies`, `cve`, `sbom`, `npm`, `pip` -> `dependency-security.md`
- `mobile`, `android`, `ios`, `react-native`, `react native`, `expo`, `webview`, `deep-link` -> `mobile-security.md`
- `aws`, `azure`, `gcp`, `iam`, `terraform`, `bucket`, `s3` -> `cloud-security.md`
- `docker`, `dockerfile`, `kubernetes`, `k8s`, `container`, `containers`, `helm`, `ci`, `cd` -> `container-security.md`
- `llm`, `agent`, `agents`, `tool`, `tools`, `prompt`, `sandbox` -> `ai-agent-security.md`
- `rag`, `vector`, `embedding`, `embeddings`, `retrieval`, `chunk` -> `rag-security.md`
- `mcp`, `model context protocol`, `mcp server` -> `mcp-security.md`
- `log`, `logs`, `logging`, `audit`, `pii`, `privacy`, `redact`, `error`, `errors` -> `logging-and-privacy.md`
- `threat model`, `architecture`, `design review` -> `threat-modeling.md`

## 6. Framework Notes
- Always inspect existing project middleware, ORM, and validation libraries before introducing new patterns.
- Prefer framework-built protections (Django CSRF/ORM, FastAPI Pydantic schemas, React JSX escaping, Prisma parameterized queries) over custom regex filters.

## 7. Detection Strategy
- Pair manual code inspection with deterministic tools available in the user's environment (`semgrep`, `bandit`, `gitleaks`, `trivy`, `pip-audit`, `npm audit`).
- Explicitly classify findings as `Confirmed`, `Potential`, `Informational`, or `Manual Verification Required`.

## 8. Remediation
- Apply least privilege, deny-by-default, defense-in-depth, and fail-closed error handling.
- Preserve existing API contracts and never modify unrelated files silently.

## 9. Testing Requirements
- Every security control requires both positive (authorized/valid) and negative (unauthorized/malicious) automated tests.
- Never report a fix as verified without running the test suite or re-checking affected paths.

## 10. Standards References
- OWASP Top 10 (2021)
- OWASP ASVS 4.0.3 (V1 Architecture, Design and Threat Modeling)
- NIST SSDF 1.1 (PW.1, PW.4, PW.8)
