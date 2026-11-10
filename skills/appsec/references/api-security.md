# API Security

## 1. Objective
Protect REST, GraphQL, and webhook APIs against broken object/function authorization, SSRF, abuse/DoS, permissive CORS, and excessive data exposure.

## 2. Threat Model
- **Attackers:** Automated scanners, malicious API consumers, webhook spoofers, and SSRF exploiters targeting cloud metadata endpoints.
- **Attack surface:** Public/authenticated endpoints, GraphQL queries, URL-fetching webhooks/previewers, pagination parameters, and CORS preflight responses.

## 3. Common Vulnerabilities
- **SSRF (CWE-918):** Server fetching arbitrary user-supplied URLs (reaching `169.254.169.254`, `127.0.0.1`, or internal VPC services).
- **Permissive CORS:** `Access-Control-Allow-Origin: *` paired with `Access-Control-Allow-Credentials: true`, or reflecting arbitrary `Origin` headers.
- **Unbounded resource consumption:** Missing rate limits, unbounded `limit=1000000` pagination, or unguarded GraphQL query depth/complexity.
- **Unsigned webhooks:** Accepting webhook payloads without HMAC signature + timestamp replay checks.
- **Excessive data exposure:** Returning full DB models including internal flags, password hashes, or PII.

## 4. Vulnerable Example
```python
# VULNERABLE: SSRF + permissive CORS + unbounded pagination
import requests
from fastapi import FastAPI

app = FastAPI()

@app.get("/fetch-preview")
def fetch_preview(url: str):
    return requests.get(url, timeout=10).text  # SSRF to cloud metadata / internal services
```

## 5. Secure Example
```python
# SECURE: Strict scheme + resolved-IP SSRF guard + bounded pagination + HMAC webhook verification
import hmac, hashlib, ipaddress, socket
from urllib.parse import urlparse

def validate_external_url(raw_url: str) -> str:
    parsed = urlparse(raw_url)
    if parsed.scheme != "https" or not parsed.hostname:
        raise ValueError("Only HTTPS URLs with valid hosts are permitted")
    for info in socket.getaddrinfo(parsed.hostname, 443, type=socket.SOCK_STREAM):
        ip = ipaddress.ip_address(info[4][0])
        if ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_reserved or ip.is_multicast:
            raise ValueError("Target resolves to a non-public IP")
    return raw_url

def verify_webhook_signature(secret: bytes, timestamp: str, body: bytes, signature: str) -> bool:
    expected = hmac.new(secret, f"{timestamp}.".encode() + body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)
```

## 6. Framework Notes
- **CORS:** Explicitly list allowed origins; never reflect `req.headers.origin` dynamically without an exact allowlist.
- **GraphQL:** Enforce max query depth, max complexity/cost, disable introspection in production if not public, and enforce authorization per resolver.
- **API Keys:** Scope keys by permission, hash stored API keys (SHA-256 + prefix lookup), and never pass keys in URL query strings.
- **Serialization:** Define explicit response schemas (`response_model` in FastAPI, Zod/DTO serializers in Node) so extra DB columns cannot leak.

## 7. Detection Strategy
- Inspect outbound HTTP client calls (`requests`, `httpx`, `fetch`, `axios`) for user-controlled URLs and disable automatic redirects across trust boundaries.
- Check CORS middleware config, pagination `limit` caps, and webhook routes lacking signature verification.

## 8. Remediation
- Enforce strict schema validation, cap pagination (`max_limit = 100`), apply rate limiting per IP/user/key, and route outbound fetches through an egress proxy or IP-validated client with redirects disabled.

## 9. Testing Requirements
- Test SSRF payloads (`http://169.254.169.254/latest/meta-data/`, `http://127.0.0.1:8080`, DNS rebinding/redirects).
- Test invalid CORS origins, missing/expired webhook signatures, and oversized pagination `limit`.

## 10. Standards References
- OWASP API Security Top 10 (2023) — API1–API10
- OWASP ASVS 4.0.3 (V13 API and Web Service)
- CWE-918 (SSRF), CWE-346 (Origin Validation), CWE-770 (Allocation Without Limits)

