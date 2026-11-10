# Antigravity Integration

- **Status:** `verified`
- **Mechanism:** Agent Skills (`SKILL.md` progressive disclosure)
- **Project-Local Install Path:** `.agents/skills/` (or `.agent/skills/`)
- **Global User Install Path:** `~/.gemini/config/skills/`
- **Verified Date:** 2026-11-10
- **Verification Basis:** Local Antigravity customization specification (`agy-customizations`)

## Install Commands

**PowerShell (project-local):**
```powershell
.\install.ps1 --agent antigravity --scope project
```

**PowerShell (global user):**
```powershell
.\install.ps1 --agent antigravity --scope user
```

**CMD:**
```cmd
install.cmd --agent antigravity --scope project
```

**Bash (macOS / Linux):**
```bash
./install.sh --agent antigravity --scope project
```

## Notes
- Workspace skills under `.agents/skills/` take highest discovery precedence
  and can be committed or shared per repository.
- Global skills under `~/.gemini/config/skills/` apply across all workspaces
  for your user account without modifying `skills.json` or global IDE settings.

