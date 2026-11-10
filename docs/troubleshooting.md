# Troubleshooting

## PowerShell Execution Policy Blocks `install.ps1`
If Windows PowerShell reports `running scripts is disabled on this system`:
- Use the CMD wrapper (uses process-scoped `-ExecutionPolicy Bypass` safely):
  ```cmd
  install.cmd --agent antigravity --scope project
  ```
- Or run PowerShell directly with process-only bypass:
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 --agent antigravity --scope project
  ```

## "Adapter '<name>' is marked experimental"
Unverified agent adapters require explicit opt-in via `--force`:
```powershell
.\install.ps1 --agent claude-code --scope user --force
```

## "Conflict on existing file ... Pass --force to back up and overwrite"
A file with different content already exists in the destination skill folder.
- Pass `--force` to create a timestamped `.bak.<timestamp>` backup before overwriting.
- Or pass `--upgrade` if you previously installed Suraksha and want a clean update
  verified against `.suraksha-install.json`.

## "Uninstall incomplete: N modified file(s) preserved"
You edited one or more installed skill files after installation. Suraksha refuses
to delete locally modified files unless you pass `--force`:
```powershell
.\install.ps1 --agent antigravity --scope project --uninstall --force
```

