# OpenAI Codex Integration

- **Status:** `experimental`
- **Mechanism:** Agent Skills (`SKILL.md` discovery)
- **Project-Local Install Path:** `.codex/skills/`
- **Global User Install Path:** `~/.codex/skills/`
- **Limitations:** Codex CLI runtime is not installed in this build environment; path follows documented Codex skill conventions and requires `--force` until live-verified.

## Install Commands

**PowerShell:**
```powershell
.\install.ps1 --agent codex --scope user --force
```

**CMD:**
```cmd
install.cmd --agent codex --scope user --force
```

**Bash:**
```bash
./install.sh --agent codex --scope user --force
```

