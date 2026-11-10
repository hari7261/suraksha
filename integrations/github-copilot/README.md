# GitHub Copilot Integration

- **Status:** `experimental`
- **Mechanism:** Workspace `.github/skills/` (newer Copilot Agent Skills) or `.github/copilot-instructions.md` adapter
- **Project-Local Install Path:** `.github/skills/`
- **Global User Install Path:** `~/.copilot/skills/`
- **Limitations:** Not all Copilot IDE versions discover `.github/skills/` natively. If your IDE only loads `.github/copilot-instructions.md`, copy or reference the workflow from `skills/appsec/SKILL.md` there without claiming native progressive disclosure.

## Install Commands

```powershell
.\install.ps1 --agent github-copilot --scope project --force
```

```bash
./install.sh --agent github-copilot --scope project --force
```

