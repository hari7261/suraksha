# Suraksha Architecture

Suraksha is a **pure Agent Skills repository** compliant with the
[Agent Skills specification](https://agentskills.io/). It contains zero library
or runtime dependencies and installs directly via PowerShell, CMD, Bash, or `git`.

## 1. Preventive Flow (Mode A — During Implementation)

```text
Developer request
  -> AI coding agent discovers Suraksha skills (SKILL.md frontmatter)
  -> Agent inspects existing project conventions & manifests
  -> Progressive disclosure: agent reads references/security-principles.md
     and loads ONLY task- and stack-relevant files under skills/appsec/references/
  -> Agent implements using framework-native secure defaults
  -> Agent self-reviews its diff against Explicit Prohibitions
  -> Agent runs locally installed deterministic tools if available (optional)
  -> Agent reports security decisions, unresolved risks, and skipped checks
```

## 2. Audit & Remediation Flow (Mode B — Reviewing Existing Code)

```text
Developer asks for a security review or remediation
  -> Agent activates secure-review or vulnerability-remediation skill
  -> Agent scopes files/diffs and loads matching domain references
  -> Agent runs locally installed scanners if present (never fabricates results)
  -> Agent classifies findings: Confirmed | Potential | Informational | Manual Verification
  -> Agent redacts secrets before outputting reports (templates/security-review.md)
  -> For fixes: minimal patch + regression test + verification re-check
```

## 3. Repository Layout

- `skills/` — Four canonical Agent Skills (`appsec`, `secure-review`, `secure-implementation`, `vulnerability-remediation`), 19 10-part references, and 3 report templates.
- `install.ps1`, `install.cmd`, `install.sh` — Zero-dependency installers with `.suraksha-install.json` manifest tracking, conflict protection, timestamped backups, upgrade, and hash-verified uninstall.
- `integrations/` — Per-agent adapter documentation.
- `schemas/` — JSON Schemas (`skill.schema.json`, `metadata.schema.json`).
- `scripts/` & `tests/` — Offline stdlib/PowerShell validation and installer safety tests.
- `examples/` — Intentionally vulnerable and clean reference samples.

