# Security Review Report

**Scope Reviewed:** `<files, PR, or commit range>`  
**Detected Stack:** `<languages, frameworks, databases, infrastructure>`  
**Date:** `<YYYY-MM-DD>`  
**Deterministic Tools Executed:** `<e.g., semgrep 1.x, bandit 1.x — or "None executed (no local scanners available)">`  
**Completeness:** `<FULL | PARTIAL | MANUAL_ONLY>`

> **Note:** A zero-finding review or scan is not a complete security assurance. Items requiring runtime or environment verification are listed explicitly below.

---

## Summary

| Classification | Critical | High | Medium | Low | Info |
|---|---:|---:|---:|---:|---:|
| Confirmed | 0 | 0 | 0 | 0 | 0 |
| Potential | 0 | 0 | 0 | 0 | 0 |

## Findings

### [ID-001] `<Title>` (`<Severity>` / Confidence: `<High|Medium|Low>` / `<Confirmed|Potential>`)
- **Location:** `<path/to/file.ext:line>`
- **CWE / Standard:** `<CWE-XXX, OWASP ASVS x.y.z>`
- **Source:** `<deterministic tool + rule OR manual code inspection>`
- **Evidence (redacted):**
  ```text
  <redacted snippet>
  ```
- **Risk:** `<1–2 sentences explaining exploitability and impact>`
- **Remediation:** `<concrete fix referencing framework-native safe pattern>`

## Skipped / Unavailable / Manual Verification Items

- `<e.g., Runtime IAM permissions, TLS termination, and rate limiting at edge gateway require live environment verification.>`

