# Suraksha Agent Skills

Suraksha provides four modular Agent Skills compliant with the
[Agent Skills specification](https://agentskills.io/).

## Which Skill to Load When

| Skill | When to Use | Path |
|---|---|---|
| `appsec` | Primary skill for building features securely (Mode A) or conducting broad security engineering tasks with progressive disclosure across all 19 reference manuals. | [skills/appsec/SKILL.md](appsec/SKILL.md) |
| `secure-implementation` | Focused companion when implementing a new endpoint, auth flow, database query, upload handler, or AI tool integration. | [skills/secure-implementation/SKILL.md](secure-implementation/SKILL.md) |
| `secure-review` | Reviewing existing files, pull requests, or git diffs for security flaws and missing controls without silently mutating unrelated code. | [skills/secure-review/SKILL.md](secure-review/SKILL.md) |
| `vulnerability-remediation` | Consuming security findings (from Semgrep, Trivy, Gitleaks, Bandit, or human review), writing regression tests, and verifying fixes. | [skills/vulnerability-remediation/SKILL.md](vulnerability-remediation/SKILL.md) |

## Progressive Disclosure Design

Do **not** read all reference files into context at once. Each skill instructs
the AI coding agent to:
1. Inspect the task and detected tech stack first.
2. Load only the matching domain references under `skills/appsec/references/`.
3. Run whatever deterministic tools exist in the user's environment (never
   fabricating scan output if none are installed).

