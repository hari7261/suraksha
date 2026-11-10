# Security Policy

## Scope

Suraksha is an Agent Skills and security engineering knowledge repository. It
does not run background services, collect telemetry, or bundle third-party
scanner binaries.

The executable components in this repository are limited to:
- Skill installers (`install.ps1`, `install.cmd`, `install.sh`)
- Skill validation scripts (`scripts/validate_skill.py`, `scripts/validate_skill.ps1`)
- Test suites (`tests/test_skills.py`, `tests/test_installers.ps1`)

## Installer & Script Security Guarantees

- **No silent overwrites:** Existing files with differing content are never
  overwritten without `--force` / `-Force`, and backups (`.bak.<timestamp>`) are
  created before replacement.
- **Scoped modifications:** Installers only write inside the target agent's
  skill directory and record installed files with SHA-256 hashes in
  `.suraksha-install.json`. Global agent config files, shell RC files, PowerShell
  profiles, and system PATH are never modified.
- **No telemetry:** Zero network calls by default during local installation or
  validation. Remote clone occurs only when explicitly invoked without a local
  repository checkout.
- **No untrusted code execution:** Installers copy markdown/JSON skill files
  only and never execute code inside target repositories.

## Reporting a Vulnerability

If you discover a security issue in Suraksha's installers, validation scripts,
or skill instructions (for example, path traversal in an installer or an unsafe
code pattern recommended as "secure" in a reference):

1. Do **not** open a public issue with exploit details for installer/script
   vulnerabilities.
2. Open a private security advisory on GitHub (or contact the maintainer
   directly if hosting privately) with:
   - Affected file and version/commit
   - Reproduction steps
   - Impact assessment
3. For insecure guidance or typos in `skills/appsec/references/`, standard pull
   requests with standards citations are welcome.

## Self-Review Record

- Installer scripts reviewed for path normalization, conflict detection,
  hash-verified uninstall, and absence of `Invoke-Expression` / `eval` on
  untrusted data.
- Example vulnerable fixtures under `examples/vulnerable-*` are explicitly
  marked `INTENTIONALLY VULNERABLE — DO NOT DEPLOY`.

