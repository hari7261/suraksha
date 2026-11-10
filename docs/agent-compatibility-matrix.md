# Agent Compatibility Matrix

Honest verification status for AI coding agent integrations. No adapter is
marked `verified` unless its discovery path and skill loading format have been
confirmed.

| Agent | Mechanism | Install Path (Project / User) | Verified Date | Verified By | Supported Version Range | Status | Limitations |
|---|---|---|---|---|---|---|---|
| Antigravity | Agent Skills (`SKILL.md`) | `.agents/skills/` / `~/.gemini/config/skills/` | 2026-11-10 | Local `agy-customizations` spec check | Current | `verified` | Workspace `.agents/skills/` overrides global `~/.gemini/config/skills/`. |
| Claude Code | Agent Skills (`SKILL.md`) | `.claude/skills/` / `~/.claude/skills/` | — | Unverified locally | — | `experimental` | `claude` CLI runtime not installed in build env; requires `--force`. |
| OpenAI Codex | Agent Skills (`SKILL.md`) | `.codex/skills/` / `~/.codex/skills/` | — | Unverified locally | — | `experimental` | `codex` CLI runtime not installed in build env; requires `--force`. |
| Gemini CLI | Agent Skills (`SKILL.md`) | `.gemini/skills/` / `~/.gemini/skills/` | — | Unverified locally | — | `experimental` | `gemini` CLI runtime not installed in build env; requires `--force`. |
| Cursor | Agent Skills (`.cursor/skills/`) | `.cursor/skills/` / `~/.cursor/skills/` | — | Unverified locally | — | `experimental` | Older Cursor builds use `.cursor/rules/*.mdc` instead of Agent Skills. |
| GitHub Copilot | `.github/skills/` or `.github/copilot-instructions.md` | `.github/skills/` / `~/.copilot/skills/` | — | Unverified locally | — | `experimental` | Native Agent Skills discovery depends on IDE/Copilot version; legacy versions require `.github/copilot-instructions.md`. |

