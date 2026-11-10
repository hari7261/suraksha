# AI & Agent Security

## 1. Objective
Secure LLM-powered applications and tool-calling AI agents against direct/indirect prompt injection, excessive agency, unsafe tool execution, and sensitive data leakage.

## 2. Threat Model
- **Core Rule:** **Treat model output and retrieved content as untrusted. A system prompt is not a defense against injection.**
- **Attackers:** Malicious users crafting prompts, external web pages/emails/docs embedding hidden indirect injections, or compromised peer agents.
- **Attack surface:** Tool calls (`exec`, SQL, HTTP, filesystem), agent memory/state, multi-agent delegation, and unvalidated model outputs rendered in UI or passed to sinks.

## 3. Common Vulnerabilities
- **Direct & Indirect Prompt Injection (LLM01):** Untrusted user text or external documents hijacking model instructions to invoke unintended tools or exfiltrate secrets.
- **Excessive Agency (LLM06):** Granting agents unrestricted shell, write, delete, email-send, or payment tools without scoping or human-in-the-loop approval.
- **Unsafe Tool Execution:** Passing model-generated strings straight to `eval()`, `subprocess(..., shell=True)`, raw SQL, or unvalidated file paths.
- **Cross-User Memory Leakage:** Sharing conversation memory, caches, or scratch directories across tenants/users.
- **Missing Budgets / Loops:** Unbounded recursion, tool loops, or token spend causing availability/cost DoS.

## 4. Vulnerable Example
```python
# VULNERABLE: Model controls arbitrary shell command + relies on system prompt for security
def run_agent_step(user_prompt: str, llm_client):
    system = "You are a helpful assistant. Never run dangerous commands."  # NOT a security boundary!
    tool_call = llm_client.generate_tool_call(system, user_prompt)
    if tool_call.name == "bash":
        return subprocess.check_output(tool_call.args["cmd"], shell=True)  # RCE via prompt injection!
```

## 5. Secure Example
```python
# SECURE: Allowlisted read-only tools, strict schema validation, human approval for mutations, sandboxing
from pydantic import BaseModel, Field

class ReadTicketArgs(BaseModel):
    ticket_id: int = Field(gt=0)

ALLOWED_TOOLS = {"read_ticket"}

def execute_tool(actor, tool_name: str, raw_args: dict, approved: bool = False):
    if tool_name not in ALLOWED_TOOLS:
        raise PermissionError(f"Tool not permitted: {tool_name}")
    args = ReadTicketArgs(**raw_args)  # strict schema validation
    # Enforce caller's own permissions, never the LLM's "judgment"
    return ticket_repo.get_for_user(ticket_id=args.ticket_id, user_id=actor.id)
```

## 6. Framework Notes
- **Authorization:** Every tool call executes with the **authenticated user's** least-privilege permissions — never ambient service-wide admin credentials.
- **Human Approval Gates:** Require explicit user confirmation before destructive, financial, external-network, or privilege-changing actions.
- **Budgets & Audit Logs:** Enforce max steps, max tokens, per-tool timeouts, and immutable audit logs recording actor, tool, validated args, and outcome.
- **Output Handling (LLM05):** Escape/sanitize model output before rendering in HTML/Markdown, executing code, or passing to downstream parsers.

## 7. Detection Strategy
- Audit all tool definitions for `shell`, `eval`, arbitrary HTTP fetch (SSRF), or unscoped filesystem write access.
- Verify system prompts are never relied upon as the sole access-control or injection defense.

## 8. Remediation
- Narrow tools to purpose-built typed APIs with Pydantic/Zod validation, enforce caller-scoped authz inside tool implementations, isolate execution in sandboxes, and isolate memory per user/session.

## 9. Testing Requirements
- Run adversarial prompt-injection test cases (including instructions hidden inside simulated retrieved documents/tool outputs) asserting unauthorized tools are rejected by code, not just prompt wording.

## 10. Standards References
- OWASP Top 10 for LLM Applications (2025) — LLM01, LLM02, LLM05, LLM06
- OWASP Agentic AI Threats and Mitigations
- NIST AI Risk Management Framework (AI RMF 1.0)
- CWE-78, CWE-94, CWE-285

