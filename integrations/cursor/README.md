# Cursor Integration

- **Status:** `experimental`
- **Mechanism:** Agent Skills (`.cursor/skills/`) — legacy Cursor versions use `.cursor/rules/*.mdc`
- **Project-Local Install Path:** `.cursor/skills/`
- **Global User Install Path:** `~/.cursor/skills/`
- **Limitations:** Cursor desktop runtime is not installed in this environment. If your Cursor version only reads `.cursor/rules/`, create a thin rule pointing to `skills/appsec/SKILL.md` in your repository.

## Install Commands

```powershell
.\install.ps1 --agent cursor --scope project --force
```

```bash
./install.sh --agent cursor --scope project --force
```

