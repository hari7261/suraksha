# Known Limitations

Suraksha is intentionally transparent about what an Agent Skill repository can
and cannot guarantee:

1. **Guidance is not deterministic enforcement:** Skills shape AI coding agent
   behavior via instructions and reference manuals, **not** hard runtime blocking.
   Deterministic SAST/SCA/secret scanners (`semgrep`, `trivy`, `gitleaks`,
   `bandit`, `pip-audit`) and automated tests remain mandatory in CI.
2. **No bundled scanners or CLI engine:** Per project scope, Suraksha ships zero
   Python/Node libraries or scanner binaries. When an AI agent runs without local
   scanners installed, security reviews are **manual code inspection only** and
   cannot detect transitive CVEs or runtime misconfigurations.
3. **Experimental external agent adapters:** Antigravity discovery paths are
   verified against local customization specifications. Claude Code, Codex,
   Gemini CLI, Cursor, and GitHub Copilot adapters are marked `experimental`
   because live binaries for those agents were not executed in this environment.
4. **LLM non-determinism:** Even with concise `SKILL.md` files and explicit
   prohibitions, an AI model may overlook a control or ignore an instruction;
   human code review and CI gates are still required.
5. **No runtime/DAST coverage:** Skills cannot verify live TLS certificates,
   WAF rules, cloud IAM runtime evaluation, or production secret rotation.

