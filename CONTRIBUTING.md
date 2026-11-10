# Contributing to Suraksha

Thank you for helping improve Suraksha! Suraksha is a pure Agent Skills
repository designed to install cleanly with `git`, PowerShell, CMD, or Bash —
with zero third-party package dependencies.

## Ways to Contribute

1. **Improve security references** in `skills/appsec/references/`
2. **Refine skill instructions** in `skills/*/SKILL.md`
3. **Add or verify agent integrations** in `integrations/` and `docs/agent-compatibility-matrix.md`
4. **Enhance installers or validators** (`install.ps1`, `install.cmd`, `install.sh`, `scripts/`)
5. **Add safe educational examples** in `examples/`

## Authoring Rules

### 1. Editing `SKILL.md` Files
- Keep every `SKILL.md` concise (**<= 250 lines**) to preserve progressive disclosure.
- Frontmatter must conform to `schemas/skill.schema.json` (no unknown keys).
- Preserve all explicit prohibitions and evidence-over-assertion rules.
- Never instruct an AI agent to bypass security controls, disable TLS, or fabricate scan results.

### 2. Authoring Security References
Every file under `skills/appsec/references/` MUST include all 10 standard sections:
1. `## 1. Objective`
2. `## 2. Threat Model`
3. `## 3. Common Vulnerabilities`
4. `## 4. Vulnerable Example`
5. `## 5. Secure Example`
6. `## 6. Framework Notes`
7. `## 7. Detection Strategy`
8. `## 8. Remediation`
9. `## 9. Testing Requirements`
10. `## 10. Standards References` (cite exact versions, e.g., `OWASP ASVS 4.0.3`, `CWE-89`)

### 3. Adding or Updating Agent Adapters
- Do **not** mark an agent adapter as `verified` unless you tested it on that
  specific agent version and recorded the version, path, and date in
  `docs/agent-compatibility-matrix.md`.
- Mark unverified paths as `experimental`.

### 4. Testing Before Opening a PR
Run the zero-dependency validation and test suites:

**Windows (PowerShell):**
```powershell
.\scripts\validate_skill.ps1
.\tests\test_installers.ps1
python scripts/validate_skill.py
python -m unittest discover -s tests -p "test_*.py" -v
```

**macOS / Linux (or with Python 3.11+):**
```bash
python3 scripts/validate_skill.py
python3 -m unittest discover -s tests -p "test_*.py" -v
```

Checklist:
- [ ] All `SKILL.md` files pass schema & line-budget checks (`<= 250` lines)
- [ ] All relative markdown links resolve
- [ ] All 19 references retain the 10-part structure
- [ ] Installer dry-run, install, upgrade, and uninstall tests pass
- [ ] Any vulnerable code sample is inside `examples/vulnerable-*` with an explicit `INTENTIONALLY VULNERABLE — DO NOT DEPLOY` notice
