# Suraksha

**Universal Application Security Engineering Skills for AI Coding Agents**

**Build securely. Review continuously. Remediate cleanly.**

Suraksha is an open-source, **zero-dependency Agent Skills repository** that teaches AI coding assistants (Antigravity, Claude Code, OpenAI Codex, Gemini CLI, Cursor, GitHub Copilot) to prevent, detect, explain, and remediate application security vulnerabilities across web, backend, database, mobile, cloud, container, and AI/RAG/MCP stacks.

No Python library, no `pip install`, no runtime daemon, and no telemetry — install directly with **Git**, **PowerShell**, **CMD**, or **Bash**.

---

## Why Suraksha Exists

Code that compiles and passes functional tests is frequently insecure. AI coding agents omit authentication checks, tenant boundaries, parameterized SQL, path canonicalization, or prompt-injection defenses unless guided with domain-specific context.

Suraksha solves this through **progressive disclosure**:
1. **Mode A — Preventive Engineering (`appsec`, `secure-implementation`):** The agent detects your task and tech stack, loads *only* the matching reference manuals from [`skills/appsec/references/`](skills/appsec/references/), and implements secure defaults.
2. **Mode B — Security Review & Remediation (`secure-review`, `vulnerability-remediation`):** The agent audits code/diffs, runs any deterministic scanners already installed in your environment (without ever fabricating missing scanner output), writes regression tests, and verifies fixes.

> **Important:** Agent Skills guide AI behavior — they are **not** a replacement for deterministic SAST/SCA/secret scanners in CI. See [docs/limitations.md](docs/limitations.md).

---

## Quick Install

### Option A — One-Line Remote Install (Requires `git`)

**Windows PowerShell:**
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/hari7261/suraksha/main/install.ps1))) --agent antigravity --scope project
```

**macOS / Linux / Git Bash:**
```bash
curl -fsSL https://raw.githubusercontent.com/hari7261/suraksha/main/install.sh | bash -s -- --agent antigravity --scope project
```

### Option B — Clone with Git & Run Installer (Recommended)

```bash
git clone https://github.com/hari7261/suraksha.git
cd suraksha
```

### 2. Install via Windows PowerShell
```powershell
# Preview what will be installed (writes nothing)
.\install.ps1 --agent antigravity --scope project --dry-run

# Install into current project (.agents/skills/)
.\install.ps1 --agent antigravity --scope project

# Or install globally for your user (~/.gemini/config/skills/)
.\install.ps1 --agent antigravity --scope user

# Install into experimental agents (requires --force)
.\install.ps1 --agent claude-code --scope user --force
.\install.ps1 --agent codex --scope user --force
```

### 3. Install via Windows CMD
```cmd
install.cmd --agent antigravity --scope project
install.cmd --agent claude-code --scope user --force
```

### 4. Install via macOS / Linux (Bash)
```bash
chmod +x install.sh
./install.sh --agent antigravity --scope project
./install.sh --agent claude-code --scope user --force
```

### 5. Install into Any Custom Directory
```powershell
.\install.ps1 --target C:\path\to\my-project\.agents\skills
```

For full upgrade (`--upgrade`) and manifest-verified uninstall (`--uninstall`) instructions, see [docs/installation.md](docs/installation.md) and [docs/quickstart.md](docs/quickstart.md).

---

## Included Skills & Knowledge Base

| Skill | Purpose | Entrypoint |
|---|---|---|
| `appsec` | Primary security engineering skill with progressive-disclosure routing | [`skills/appsec/SKILL.md`](skills/appsec/SKILL.md) |
| `secure-implementation` | Preventive secure coding defaults during feature creation | [`skills/secure-implementation/SKILL.md`](skills/secure-implementation/SKILL.md) |
| `secure-review` | Diff and codebase security audit with honest classification | [`skills/secure-review/SKILL.md`](skills/secure-review/SKILL.md) |
| `vulnerability-remediation` | Finding triage, minimal patches, regression tests, and verification | [`skills/vulnerability-remediation/SKILL.md`](skills/vulnerability-remediation/SKILL.md) |

`skills/appsec/references/` includes **19 complete 10-part engineering manuals** covering:
`security-principles`, `threat-modeling`, `sql-security`, `authentication`, `authorization`, `api-security`, `frontend-security`, `backend-security`, `database-security`, `cryptography`, `secrets-management`, `dependency-security`, `mobile-security`, `cloud-security`, `container-security`, `ai-agent-security`, `rag-security`, `mcp-security`, and `logging-and-privacy`, plus 3 structured report templates in [`skills/appsec/templates/`](skills/appsec/templates/).

---

## Supported AI Agents

| Agent | Status | Project Path | User Path |
|---|---|---|---|
| Antigravity | `verified` | `.agents/skills/` | `~/.gemini/config/skills/` |
| Claude Code | `experimental` | `.claude/skills/` | `~/.claude/skills/` |
| OpenAI Codex | `experimental` | `.codex/skills/` | `~/.codex/skills/` |
| Gemini CLI | `experimental` | `.gemini/skills/` | `~/.gemini/skills/` |
| Cursor | `experimental` | `.cursor/skills/` | `~/.cursor/skills/` |
| GitHub Copilot | `experimental` | `.github/skills/` | `~/.copilot/skills/` |

See [docs/agent-compatibility-matrix.md](docs/agent-compatibility-matrix.md) for verification dates and limitations.

---

## Local Validation & Tests (Zero Dependencies)

```powershell
# PowerShell (no Python required)
.\scripts\validate_skill.ps1
.\tests\test_installers.ps1
```

```bash
# Python 3.11+ stdlib only
python3 scripts/validate_skill.py
python3 -m unittest discover -s tests -p "test_*.py" -v
```

---

## License & Governance

- **License:** [Apache-2.0](LICENSE) ([NOTICE](NOTICE))
- **Security Policy:** [SECURITY.md](SECURITY.md)
- **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md)
- **Code of Conduct:** [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- **Roadmap & Status:** [ROADMAP.md](ROADMAP.md) · [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md)
