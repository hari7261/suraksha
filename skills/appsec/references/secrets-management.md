# Secrets Management

## 1. Objective
Prevent hardcoded credentials, secret leakage across repositories, build artifacts, logs, and AI prompts, and establish safe secret injection and rotation workflows.

## 2. Threat Model
- **Attackers:** Automated bots scraping git commits/public repos within seconds, compromised CI runners, or malicious insiders reading `.env` files or debug logs.
- **Attack surface:** Source files, `.env` files, git history, CI/CD variables, Docker build args (`ARG`), frontend bundles, and exception logs.

## 3. Common Vulnerabilities
- Hardcoding API keys, JWT signing secrets, DB passwords, or private keys in code or tests.
- Committing `.env` or `credentials.json` to git (even if deleted in a later commit).
- Using fallback dev secrets in production code paths (`os.getenv("JWT_SECRET", "dev-secret")`).
- Passing secrets via Docker `ARG`/`ENV` baked into image layers or CLI flags visible in `ps`.
- Unscoped or non-expiring long-lived static keys instead of short-lived OIDC/IAM credentials.

## 4. Vulnerable Example
```python
# VULNERABLE: Hardcoded fallback secret + leaking credential in startup log
import logging, os

JWT_SECRET = os.getenv("JWT_SECRET", "super-secret-fallback-123")
STRIPE_KEY = "sk_live_example_not_real_000000000000"
logging.info("Loaded Stripe key: %s", STRIPE_KEY)
```

## 5. Secure Example
```python
# SECURE: Fail-closed missing secret + zero secret logging + secret manager / env injection
import logging, os

def require_secret(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"Missing required secret environment variable: {name}")
    return value

JWT_SECRET = require_secret("JWT_SECRET")
logging.info("Authentication configuration initialized (key_configured=%s)", bool(JWT_SECRET))
```

## 6. Framework Notes
- **Local dev:** Commit `.env.example` with empty placeholders only; keep `.env` in `.gitignore` and use synthetic dummy values for tests.
- **CI/CD:** Prefer short-lived OIDC federation (GitHub Actions -> AWS/GCP/Azure) over static long-lived keys stored in repo secrets.
- **Rotation:** Design signing keys (`kid`) and API credentials for zero-downtime dual-key rotation.

## 7. Detection Strategy
- Run `gitleaks` / `trivy fs --scanners secret` when available; check `.gitignore`, `Dockerfile`, and `env` fallbacks manually.
- Treat any real secret committed to git as **compromised**, even in private repos.

## 8. Remediation
1. **Revoke and rotate** the exposed secret immediately at the provider.
2. Move secret loading to environment injection or a vault/KMS (AWS Secrets Manager, GCP Secret Manager, HashiCorp Vault).
3. Scrub git history (`git filter-repo`) if policy requires, after rotation is complete.

## 9. Testing Requirements
- Verify application startup fails closed when required secrets are absent in production mode.
- Assert logs and error responses never contain secret patterns (`sk_live_`, `AKIA`, `BEGIN PRIVATE KEY`, Bearer tokens).

## 10. Standards References
- OWASP ASVS 4.0.3 (V2.10, V14.2)
- NIST SSDF 1.1 (PO.5, PW.4)
- CWE-798 (Use of Hard-coded Credentials), CWE-312, CWE-532

