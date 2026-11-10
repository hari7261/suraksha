# Changelog

All notable changes to Suraksha are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-10

### Added
- Pure Agent Skills repository structure (zero library/runtime dependencies).
- Four core Agent Skills following the Agent Skills specification:
  - `appsec` (main engineering skill with progressive disclosure)
  - `secure-review` (code and diff security review skill)
  - `secure-implementation` (preventive secure coding skill)
  - `vulnerability-remediation` (finding triage and verified fix skill)
- Complete 19 security engineering reference manuals in `skills/appsec/references/`,
  each following the 10-part standard structure with versioned OWASP/CWE/NIST citations.
- Three structured output templates in `skills/appsec/templates/`.
- Cross-platform zero-dependency installers:
  - `install.ps1` (Windows PowerShell 5.1+ / 7+)
  - `install.cmd` (Windows Command Prompt wrapper)
  - `install.sh` (macOS / Linux POSIX shell)
  - Supports `--dry-run`, `--force` (with timestamped backups), `--upgrade`,
    `--uninstall` (hash-verified via `.suraksha-install.json`), and `--list`.
- Agent integration guides for Antigravity, Claude Code, OpenAI Codex,
  Gemini CLI, Cursor, and GitHub Copilot, plus `docs/agent-compatibility-matrix.md`.
- Schemas (`schemas/skill.schema.json`, `schemas/metadata.schema.json`),
  zero-dependency validators (`scripts/validate_skill.py`, `scripts/validate_skill.ps1`),
  and offline test suites (`tests/test_skills.py`, `tests/test_installers.ps1`).
- Intentionally vulnerable and clean reference examples in `examples/`.
- GitHub Actions workflow `.github/workflows/skill-validation.yml`.

