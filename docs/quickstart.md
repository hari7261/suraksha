# Quick Start (< 5 Minutes)

1. **Clone Suraksha** (or open your local checkout):
   ```powershell
   git clone https://github.com/hari7261/suraksha.git
   cd suraksha
   ```

2. **Preview installation** with `--dry-run`:
   ```powershell
   .\install.ps1 --agent antigravity --scope project --dry-run
   ```

3. **Install into your project workspace**:
   ```powershell
   .\install.ps1 --agent antigravity --scope project
   ```
   *(Or use `install.cmd --agent antigravity --scope project` in CMD, or `./install.sh --agent antigravity --scope project` on macOS/Linux.)*

4. **Test it with your AI coding agent**:
   - **Preventive coding:** *"Build a login and invoice endpoint using Suraksha appsec guidance."*
     The agent loads `appsec`, selects `authentication.md`, `authorization.md`, and `sql-security.md` without dumping unrelated docs into context.
   - **Security review:** *"Review `src/api/` using Suraksha secure-review."*
   - **Remediation:** *"Fix the SQL injection finding using Suraksha vulnerability-remediation and add a regression test."*

5. **Verify the repository locally** (optional, zero dependencies):
   ```powershell
   .\scripts\validate_skill.ps1
   ```

