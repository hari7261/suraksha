# Claude Code Integration

- **Status:** `experimental`
- **Mechanism:** Agent Skills (`SKILL.md` directory discovery)
- **Project-Local Install Path:** `.claude/skills/`
- **Global User Install Path:** `~/.claude/skills/`
- **Limitations:** Not live-tested against an installed `claude` CLI binary in this build environment; therefore `--force` is required when installing.

## Install Commands

**PowerShell:**
```powershell
.\install.ps1 --agent claude-code --scope user --force
```

**CMD:**
```cmd
install.cmd --agent claude-code --scope user --force
```

**Bash:**
```bash
./install.sh --agent claude-code --scope user --force
```

## Manual Verification
After installing, start a Claude Code session in a project and confirm `appsec`,
`secure-review`, `secure-implementation`, and `vulnerability-remediation` appear
as available skills.

