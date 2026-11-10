<#
.SYNOPSIS
    End-to-end installer safety tests for install.ps1 and install.cmd in isolated temp dirs.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$InstallPs1 = Join-Path $Root "install.ps1"
$InstallCmd = Join-Path $Root "install.cmd"
$TempBase = Join-Path ([System.IO.Path]::GetTempPath()) ("suraksha-test-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TempBase -Force | Out-Null

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw "ASSERTION FAILED: $Message"
    }
}

function Invoke-Ps1ExpectingFailure {
    param([string[]]$Arguments)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $InstallPs1 @Arguments 2>&1
        return @{
            ExitCode = $LASTEXITCODE
            Output   = ($out | Out-String)
        }
    } finally {
        $ErrorActionPreference = $prev
    }
}

try {
    # 1. --list succeeds
    $listOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $InstallPs1 --list
    Assert-True ($LASTEXITCODE -eq 0) "--list exited $LASTEXITCODE"
    Assert-True (($listOut -join "`n") -match "antigravity\s+\[verified\]") "--list missing antigravity verified status"

    # 2. --dry-run writes nothing
    $dryTarget = Join-Path $TempBase "dry-target"
    $dryOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $InstallPs1 --target $dryTarget --dry-run
    Assert-True ($LASTEXITCODE -eq 0) "--dry-run exited $LASTEXITCODE"
    Assert-True (-not (Test-Path $dryTarget)) "--dry-run created target directory unexpectedly"
    Assert-True (($dryOut -join "`n") -match "\[DRY-RUN\]") "--dry-run output missing [DRY-RUN]"

    # 3. Experimental adapter rejected without --force
    $expProj = Join-Path $TempBase "exp-proj"
    New-Item -ItemType Directory -Path $expProj -Force | Out-Null
    Push-Location $expProj
    try {
        $res = Invoke-Ps1ExpectingFailure -Arguments @("--agent", "claude-code", "--scope", "project")
        Assert-True ($res.ExitCode -ne 0) "Experimental adapter should fail without --force"
        Assert-True (-not (Test-Path (Join-Path $expProj ".claude/skills"))) "Experimental install created files without --force"
    } finally {
        Pop-Location
    }

    # 4. Verified antigravity project install via install.cmd
    $projDir = Join-Path $TempBase "antigravity-proj"
    New-Item -ItemType Directory -Path $projDir -Force | Out-Null
    Push-Location $projDir
    try {
        & $InstallCmd --agent antigravity --scope project | Out-Null
        Assert-True ($LASTEXITCODE -eq 0) "install.cmd failed with $LASTEXITCODE"
    } finally {
        Pop-Location
    }

    $skillsDest = Join-Path $projDir ".agents\skills"
    $manifestPath = Join-Path $skillsDest ".suraksha-install.json"
    Assert-True (Test-Path (Join-Path $skillsDest "appsec\SKILL.md")) "appsec/SKILL.md not installed"
    Assert-True (Test-Path (Join-Path $skillsDest "appsec\references\sql-security.md")) "reference missing after install"
    Assert-True (Test-Path $manifestPath) "Install manifest missing"

    $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
    Assert-True ($manifest.package -eq "suraksha") "Manifest package != suraksha"
    Assert-True ($manifest.files.Count -ge 29) "Expected >= 29 installed files, got $($manifest.files.Count)"

    # 5. Conflict detection & backup on --force
    $targetSkillMd = Join-Path $skillsDest "appsec\SKILL.md"
    Add-Content -Path $targetSkillMd -Value "`n# local edit"
    Push-Location $projDir
    try {
        $conflictRes = Invoke-Ps1ExpectingFailure -Arguments @("--agent", "antigravity", "--scope", "project")
        Assert-True ($conflictRes.ExitCode -ne 0) "Install should fail on modified file conflict without --force"

        & powershell -NoProfile -ExecutionPolicy Bypass -File $InstallPs1 --agent antigravity --scope project --force | Out-Null
        Assert-True ($LASTEXITCODE -eq 0) "Install --force failed"
    } finally {
        Pop-Location
    }

    $backups = @(Get-ChildItem -Path (Join-Path $skillsDest "appsec") -Filter "SKILL.md.bak.*")
    Assert-True ($backups.Count -ge 1) "Expected timestamped backup file after --force overwrite"

    # 6. --upgrade succeeds on clean manifest-tracked install
    Push-Location $projDir
    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $InstallPs1 --agent antigravity --scope project --upgrade | Out-Null
        Assert-True ($LASTEXITCODE -eq 0) "--upgrade failed"
    } finally {
        Pop-Location
    }

    # 7. --uninstall preserves locally modified file unless --force, then removes cleanly
    Add-Content -Path $targetSkillMd -Value "`n# modified before uninstall"
    Push-Location $projDir
    try {
        $uninstRes = Invoke-Ps1ExpectingFailure -Arguments @("--agent", "antigravity", "--scope", "project", "--uninstall")
        Assert-True ($uninstRes.ExitCode -ne 0) "--uninstall should refuse to delete locally modified file without --force"
        Assert-True (Test-Path $targetSkillMd) "Locally modified file was deleted without --force"

        & powershell -NoProfile -ExecutionPolicy Bypass -File $InstallPs1 --agent antigravity --scope project --uninstall --force | Out-Null
        Assert-True ($LASTEXITCODE -eq 0) "--uninstall --force failed"
        Assert-True (-not (Test-Path $manifestPath)) "Manifest still exists after --uninstall --force"
        Assert-True (-not (Test-Path $targetSkillMd)) "SKILL.md still exists after --uninstall --force"
    } finally {
        Pop-Location
    }

    Write-Host "OK: All 7 installer safety tests passed."
} finally {
    if (Test-Path $TempBase) {
        Remove-Item -Path $TempBase -Recurse -Force -ErrorAction SilentlyContinue
    }
}
