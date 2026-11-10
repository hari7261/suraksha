# Suraksha Roadmap

Suraksha is intentionally focused as a **pure, zero-dependency Agent Skills
repository** that installs cleanly via `git`, PowerShell, CMD, or Bash.

## Current Release (v0.1.0)

- Core Agent Skills: `appsec`, `secure-review`, `secure-implementation`, `vulnerability-remediation`
- 19 complete 10-part security engineering references + 3 templates
- Cross-platform installers (`install.ps1`, `install.cmd`, `install.sh`) with
  manifest tracking (`.suraksha-install.json`), `--dry-run`, `--upgrade`, and `--uninstall`
- Verified Antigravity workspace/global paths; documented experimental paths for
  Claude Code, Codex, Gemini CLI, Cursor, and GitHub Copilot
- Offline skill validation (`validate_skill.py`, `validate_skill.ps1`) and tests

## Planned Additions

### v0.2.0 — Live Agent Verification & Expanded Examples
- Live verification of `claude-code`, `codex`, `cursor`, `gemini-cli`, and
  `github-copilot` skill discovery across current agent releases.
- Additional framework-specific examples (Next.js App Router, FastAPI, Go Gin,
  React Native / Expo).
- Human evaluation benchmark runs following `docs/skill-evaluation.md`.

### v0.3.0 — Domain Skill Packs & Localized Checklists
- Optional specialized sub-skills for Terraform/IaC hardening and Kubernetes
  admission policies.
- Framework-specific quick-check cards (Django, NestJS, Spring Boot).
- Community skill contribution templates and automated link/anchor checking.

### Explicitly Out of Scope
- Building or shipping a Python/Node runtime library or CLI package.
- Hosting a SaaS backend, telemetry service, or remote rule server.
- Bundling third-party scanner binaries in this repository.

