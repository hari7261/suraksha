# Threat Modeling

## 1. Objective
Identify assets, actors, trust boundaries, and high-impact attack paths early during design or architectural changes so controls are built in before implementation.

## 2. Threat Model
- **Trust boundary crossings:** Unauthenticated internet -> API gateway; tenant A -> shared database; LLM output -> tool executor.
- **STRIDE categories:** Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege.

## 3. Common Vulnerabilities
- Designing features around happy-path data flows while omitting abuse cases.
- Implicit trust between internal microservices or between an AI model and privileged tools.
- Unbounded resource consumption on public or webhook endpoints.
- Missing audit trails on privilege or configuration changes.

## 4. Vulnerable Example
```yaml
# Anti-pattern: implicit trust across boundary without authz or rate limits
architecture:
  public_webhook: -> directly invokes internal admin_worker(payload)
  llm_planner: -> unrestricted shell_exec(model_generated_cmd)
```

## 5. Secure Example
```yaml
# Secure design: explicit trust boundaries, signature verification, and least privilege
architecture:
  public_webhook:
    controls: [hmac_signature_check, timestamp_window, schema_validation, rate_limit]
    forwards_to: scoped_job_queue
  llm_planner:
    controls: [allowlisted_tools, pydantic_arg_validation, human_approval_for_writes]
    sandbox: read_only_workspace
```

## 6. Framework Notes
- **Web APIs:** Map every route's authentication requirement, authorization rule, and rate limit before writing handlers.
- **AI / Agentic apps:** Treat prompts, retrieved documents, and tool responses as untrusted external inputs crossing a privilege boundary.

## 7. Detection Strategy
- Review architecture diagrams, route tables, IAM policies, and `skills/appsec/templates/threat-model.md`.
- Flag any unauthenticated route, cross-tenant query, or privileged sink reachable from external input.

## 8. Remediation
- Insert explicit authentication, object-level authorization, schema validation, and rate limiting at every trust boundary.
- Segregate high-privilege admin/destructive operations behind separate roles or human approval gates.

## 9. Testing Requirements
- Map every high-risk STRIDE row to at least one automated integration or security test.
- Revisit the threat model whenever a new external integration, auth flow, or AI tool is added.

## 10. Standards References
- OWASP ASVS 4.0.3 (V1.1, V1.2)
- NIST SSDF 1.1 (PO.3, PW.1)
- MITRE ATT&CK Matrix (Initial Access, Privilege Escalation)

