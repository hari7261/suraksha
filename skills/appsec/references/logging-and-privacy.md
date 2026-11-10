# Logging, Monitoring & Privacy

## 1. Objective
Capture actionable security audit trails while strictly preventing credential, token, and unnecessary PII exposure in logs, reports, error messages, and temporary artifacts.

## 2. Threat Model
- **Attackers:** Adversaries reading centralized log aggregators, CI build logs, crash reports, or browser DevTools to harvest leaked tokens/PII, or injecting newlines to forge log entries (CWE-117).
- **Attack surface:** Request/response middleware logs, exception tracebacks, SQL query logs, stdout/stderr in CI, and AI prompt/response telemetry.

## 3. Common Vulnerabilities
- **Secret & Token Logging (CWE-532):** Logging `Authorization` headers, cookies, `password`, `api_key`, `refresh_token`, or signed URLs.
- **Full Request Body / Error Logging:** Dumping raw `req.body` or `exc_info` containing PII or credentials on validation/500 errors.
- **Log Injection (CWE-117):** Writing unsanitized user strings containing `\r\n` into plaintext logs.
- **Missing Security Audit Events:** Failing to log authentication failures, role changes, API key creation, or policy overrides (insufficient auditability).
- **Unnecessary PII Retention:** Logging emails, SSNs, or full IPs where pseudonymous IDs suffice, or ignoring retention/deletion rules.

## 4. Vulnerable Example
```python
# VULNERABLE: Logs raw Authorization header, password field, and forged newlines
@app.post("/login")
def login(payload: dict, request: Request):
    logger.info(f"Login attempt headers={dict(request.headers)} body={payload}")
    ...
```

## 5. Secure Example
```python
# SECURE: Structured JSON log with explicit allowlisted fields + secret redaction
import re

SECRET_PATTERNS = [
    (re.compile(r"(?i)(bearer\s+)[a-z0-9\-._~+/]+=*"), r"\1[REDACTED]"),
    (re.compile(r"AKIA[0-9A-Z]{16}"), "[REDACTED_AWS_KEY]"),
    (re.compile(r"-----BEGIN [A-Z ]+PRIVATE KEY-----[\s\S]*?-----END [A-Z ]+PRIVATE KEY-----"), "[REDACTED_PRIVATE_KEY]"),
]

def redact(text: str) -> str:
    for pattern, repl in SECRET_PATTERNS:
        text = pattern.sub(repl, text)
    return text.replace("\r", " ").replace("\n", " ")

def log_auth_event(logger, event: str, user_id: str, outcome: str, request_id: str):
    logger.info("security_audit", extra={
        "event": event,
        "user_id": user_id,
        "outcome": outcome,
        "request_id": request_id,
    })
```

## 6. Framework Notes
- **Structured logging:** Emit JSON logs with `timestamp`, `level`, `event`, `request_id`, and `actor_id` instead of free-form string interpolation.
- **Redaction middleware:** Strip `authorization`, `cookie`, `set-cookie`, `password`, `token`, `secret`, and `x-api-key` keys before serialization.
- **AI & CI outputs:** Never echo raw secrets in AI review summaries, Markdown/SARIF reports, or GitHub Actions logs.

## 7. Detection Strategy
- Search for `logger.*(request.headers`, `logger.*(payload`, `print(token`, `console.log(req.body`, and `traceback.format_exc()` returned in HTTP responses.

## 8. Remediation
- Switch to allowlist-based structured audit fields, add central secret redaction filters, and return only opaque correlation IDs to clients on internal errors.

## 9. Testing Requirements
- Feed synthetic secrets (`AKIA...`, JWTs, `Bearer ...`, private key blocks) and CRLF payloads through error/log paths and assert zero raw secrets or injected lines appear in output.

## 10. Standards References
- OWASP Top 10 (2021) — A09:2021 Security Logging and Monitoring Failures
- OWASP ASVS 4.0.3 (V7 Error Handling and Logging)
- NIST SP 800-92 / NIST SSDF 1.1 (RV.1)
- CWE-117, CWE-209, CWE-532

