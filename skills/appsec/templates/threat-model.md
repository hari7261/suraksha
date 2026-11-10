# Threat Model

**System / Feature:** `<name>`  
**Owner:** `<team or developer>`  
**Date:** `<YYYY-MM-DD>`

---

## 1. Assets & Data Classification
| Asset | Sensitivity | Storage / Transit |
|---|---|---|
| `<e.g., Session tokens, PII, API keys>` | `<Public / Internal / Confidential / Restricted>` | `<TLS 1.3, Encrypted DB>` |

## 2. Actors & Trust Boundaries
- **Unauthenticated Internet User** -> Edge API Gateway (Trust Boundary 1)
- **Authenticated Tenant User** -> Application Service -> Database (Trust Boundary 2)
- **AI Agent / External Tool** -> MCP / Tool Runner (Trust Boundary 3)

## 3. STRIDE Threat Analysis

| Threat Category | Scenario | Mitigation / Control | Verification |
|---|---|---|---|
| **Spoofing** | `<e.g., Forged JWT or weak session>` | `<Verify signature, alg allowlist, aud/iss/exp>` | `<Unit + integration test>` |
| **Tampering** | `<e.g., Mass assignment or SQLi>` | `<Explicit allowlist DTO, parameterized SQL>` | `<Negative test>` |
| **Repudiation** | `<e.g., Unlogged admin changes>` | `<Structured audit log with actor & timestamp>` | `<Log assertion>` |
| **Info Disclosure** | `<e.g., IDOR across tenants>` | `<Server-side tenant_id scope on every query>` | `<Cross-tenant test>` |
| **Denial of Service** | `<e.g., Unbounded upload or GraphQL depth>` | `<Body size limits, pagination, rate limits>` | `<Limit test>` |
| **Elevation of Privilege** | `<e.g., Role claim trusted from client>` | `<Server-side RBAC lookup + deny-by-default>` | `<403 test>` |

## 4. Open Risks & Assumptions
- `<List any unverified controls or accepted risks>`

