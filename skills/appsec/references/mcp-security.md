# MCP (Model Context Protocol) Security

## 1. Objective
Secure MCP servers, clients, tool schemas, external resources, and OAuth/token flows so connected servers cannot escalate privileges or inject malicious instructions.

## 2. Threat Model
- **Core Rule:** **Connected ≠ trusted.** Every MCP server, tool description, resource payload, and tool output crosses a trust boundary.
- **Attackers:** Malicious or compromised remote MCP servers, rug-pulling tool definitions ("tool poisoning"), or untrusted data returned from external MCP resources.
- **Attack surface:** Tool metadata/descriptions, tool input arguments, MCP resource URIs, OAuth tokens, and local stdio/HTTP server transports.

## 3. Common Vulnerabilities
- **Malicious tool descriptions (Tool Poisoning):** Hidden prompt instructions inside a tool's `description` field instructing the host agent to read `~/.ssh` or exfiltrate tokens via another tool.
- **Token passthrough / over-scoped OAuth:** Forwarding a user's broad session token to an untrusted third-party MCP server instead of issuing audience-restricted, least-privilege scoped tokens.
- **Unvalidated tool inputs/outputs:** MCP servers trusting LLM-supplied file paths, URLs, or SQL fragments without validation; clients trusting server responses verbatim.
- **Confused deputy / cross-server chaining:** A low-trust external MCP server influencing an agent to invoke a high-trust local filesystem/Git/cloud MCP tool.
- **Unpinned third-party servers:** Running `npx -y untrusted-mcp-server@latest` automatically without version pinning or review.

## 4. Vulnerable Example
```python
# MCP Server — VULNERABLE: unvalidated path + no auth/scope check + raw shell execution
@mcp.tool()
def read_repo_file(file_path: str) -> str:
    return open(file_path, "r", encoding="utf-8").read()  # reads /etc/passwd or ~/.ssh/id_rsa!
```

## 5. Secure Example
```python
# MCP Server — SECURE: canonical root containment, symlink check, size limit, explicit audit log
from pathlib import Path

WORKSPACE_ROOT = Path("/srv/workspace").resolve()
MAX_BYTES = 128_000

@mcp.tool()
def read_repo_file(relative_path: str) -> str:
    """Read a UTF-8 file strictly within the workspace root."""
    candidate = (WORKSPACE_ROOT / relative_path).resolve()
    if not candidate.is_relative_to(WORKSPACE_ROOT) or candidate.is_symlink():
        raise ValueError("Access denied: path escapes workspace root")
    if not candidate.is_file() or candidate.stat().st_size > MAX_BYTES:
        raise ValueError("File missing or exceeds size limit")
    audit_log.info("mcp_tool_read", extra={"path": str(candidate.relative_to(WORKSPACE_ROOT))})
    return candidate.read_text(encoding="utf-8")
```

## 6. Framework Notes
- **Server Identity & Transport:** Use authenticated TLS for remote MCP HTTP/SSE transports; verify OAuth `aud` / scopes per MCP specification; never pass raw host credentials into untrusted servers.
- **Permission Scoping:** Restrict MCP servers to the minimum workspace directories, read-only database roles, and explicit tool allowlists; require human confirmation for state-changing tools.
- **Tool Description & Output Hygiene:** Treat third-party tool descriptions and outputs as untrusted text; inspect/pin MCP server versions before enabling them.

## 7. Detection Strategy
- Review `mcp_config.json` / server registrations for remote unauthenticated URLs, broad filesystem roots (`/` or `~`), unpinned `npx @latest`, and destructive tools lacking confirmation gates.

## 8. Remediation
- Enforce root-path canonicalization, input schemas, OAuth scope separation, per-tool timeouts, and structured audit logging on every MCP server.

## 9. Testing Requirements
- Test path traversal (`../../.env`), symlink escapes, oversized resource responses, unauthorized OAuth scopes, and cross-tool injection scenarios.

## 10. Standards References
- Model Context Protocol (MCP) Authorization & Security Best Practices
- OWASP Top 10 for LLM Applications (2025) — LLM01, LLM06
- OWASP ASVS 4.0.3 (V4, V5, V12)
- CWE-22, CWE-284, CWE-862

