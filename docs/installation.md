# Installation Guide

Suraksha requires **no Python package, no `pip install`, and no Node.js runtime**.
Install directly using `git`, PowerShell, CMD, or Bash.

## Approach 1 — One-Line Remote Install (Requires `git` in PATH)

### Windows PowerShell
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/hari7261/suraksha/main/install.ps1))) --agent antigravity --scope project
```

### macOS / Linux / Git Bash
```bash
curl -fsSL https://raw.githubusercontent.com/hari7261/suraksha/main/install.sh | bash -s -- --agent antigravity --scope project
```

*(Inspect `install.ps1` / `install.sh` before running remote scripts, or use Approach 2 below to review locally first.)*

## Approach 2 — Clone with Git & Run Installer (Recommended)

```bash
git clone https://github.com/hari7261/suraksha.git
cd suraksha
```

### Windows PowerShell
```powershell
# Preview first (no files written)
.\install.ps1 --agent antigravity --scope project --dry-run

# Install into current project (.agents/skills/)
.\install.ps1 --agent antigravity --scope project

# Or install globally for your user (~/.gemini/config/skills/)
.\install.ps1 --agent antigravity --scope user

# Experimental agents (requires --force)
.\install.ps1 --agent claude-code --scope user --force
.\install.ps1 --agent codex --scope user --force
```

### Windows CMD
```cmd
install.cmd --agent antigravity --scope project
install.cmd --agent claude-code --scope user --force
```

### macOS / Linux (Bash)
```bash
chmod +x install.sh
./install.sh --agent antigravity --scope project
./install.sh --agent claude-code --scope user --force
```

## Approach 2 — Custom Target Directory

Install into any custom workspace or shared skills directory:

```powershell
.\install.ps1 --target C:\path\to\project\.agents\skills
```

```bash
./install.sh --target /path/to/project/.agents/skills
```

## Approach 3 — Manual Git Copy

Copy the four skill directories from `skills/` (`appsec`, `secure-review`,
`secure-implementation`, `vulnerability-remediation`) into your agent's skill
folder (for example `.agents/skills/` or `~/.claude/skills/`). Note that manual
copies will not create `.suraksha-install.json` for automated upgrades or uninstalls.

## Upgrading & Uninstalling

```powershell
# Safe upgrade (verifies manifest hashes)
.\install.ps1 --agent antigravity --scope project --upgrade

# Clean uninstall (removes only manifest-tracked unmodified files)
.\install.ps1 --agent antigravity --scope project --uninstall
```

