<#
.SYNOPSIS
    Suraksha Agent Skills Installer for Windows (PowerShell 5.1+ / 7+).

.DESCRIPTION
    Installs, upgrades, or uninstalls Suraksha Agent Skills into supported AI
    coding agent skill directories without Python, Node.js, or library dependencies.
    Writes a .suraksha-install.json manifest for hash-verified upgrades and uninstalls.
    Never modifies global agent config files, PowerShell profiles, or shell RC files.

.EXAMPLE
    .\install.ps1 --agent antigravity --scope project
    .\install.ps1 --agent claude-code --scope user --force
    .\install.ps1 --agent antigravity --scope project --dry-run
    .\install.ps1 --agent antigravity --scope project --upgrade
    .\install.ps1 --agent antigravity --scope project --uninstall
    .\install.ps1 --list
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SurakshaVersion = "0.1.0"
$DefaultRepoUrl = "https://github.com/hari7261/suraksha.git"
$ManifestName = ".suraksha-install.json"
$SkillNames = @("appsec", "secure-review", "secure-implementation", "vulnerability-remediation")

$Adapters = @{
    "antigravity" = @{
        Status  = "verified"
        Project = ".agents/skills"
        User    = Join-Path (Join-Path (Join-Path $HOME ".gemini") "config") "skills"
        Notes   = "Verified against Antigravity customization discovery specification."
    }
    "claude-code" = @{
        Status  = "experimental"
        Project = ".claude/skills"
        User    = Join-Path (Join-Path $HOME ".claude") "skills"
        Notes   = "Path follows Claude Code skills convention; not live-tested in this environment."
    }
    "codex" = @{
        Status  = "experimental"
        Project = ".codex/skills"
        User    = Join-Path (Join-Path $HOME ".codex") "skills"
        Notes   = "Path follows OpenAI Codex skills convention; not live-tested in this environment."
    }
    "gemini-cli" = @{
        Status  = "experimental"
        Project = ".gemini/skills"
        User    = Join-Path (Join-Path $HOME ".gemini") "skills"
        Notes   = "Path follows Gemini CLI convention; not live-tested in this environment."
    }
    "cursor" = @{
        Status  = "experimental"
        Project = ".cursor/skills"
        User    = Join-Path (Join-Path $HOME ".cursor") "skills"
        Notes   = "Cursor skill discovery varies by version; see integrations/cursor/README.md."
    }
    "github-copilot" = @{
        Status  = "experimental"
        Project = ".github/skills"
        User    = Join-Path (Join-Path $HOME ".copilot") "skills"
        Notes   = "Copilot traditionally uses .github/copilot-instructions.md; see integrations/github-copilot/README.md."
    }
}

function Show-Usage {
    Write-Host @"
Suraksha Agent Skills Installer v$SurakshaVersion

Usage:
  .\install.ps1 --agent <name> [--scope project|user] [options]
  .\install.ps1 --target <path> [options]
  .\install.ps1 --list

Options:
  -Agent, --agent <name>      Target agent: antigravity, claude-code, codex,
                              gemini-cli, cursor, github-copilot
  -Scope, --scope <scope>     Install scope: project (default) or user
  -Target, --target <path>    Custom skill destination directory (overrides --agent/--scope)
  -DryRun, --dry-run          Preview all actions without writing or deleting files
  -Force, --force             Overwrite modified files (creates .bak.<timestamp>) and
                              allow installing experimental adapters
  -Upgrade, --upgrade         Upgrade an existing Suraksha install using manifest hashes
  -Uninstall, --uninstall     Remove only files recorded in $ManifestName
  -List, --list               List supported agents, status, and destination paths
  -RepoUrl, --repo-url <url>  Git URL used only when running outside a local checkout
  -Branch, --branch <name>    Git branch for remote install (default: main)
  -Help, --help               Show this help message

Examples:
  .\install.ps1 --agent antigravity --scope project
  .\install.ps1 --agent antigravity --scope user --dry-run
  .\install.ps1 --agent claude-code --scope user --force
  .\install.ps1 --agent antigravity --scope project --uninstall
"@
}

function Show-Adapters {
    Write-Host "Supported Agents (Suraksha v$SurakshaVersion):"
    Write-Host ""
    foreach ($key in ($Adapters.Keys | Sort-Object)) {
        $info = $Adapters[$key]
        Write-Host ("  {0,-16} [{1}]" -f $key, $info.Status)
        Write-Host ("    project: {0}" -f $info.Project)
        Write-Host ("    user:    {0}" -f $info.User)
        Write-Host ("    notes:   {0}" -f $info.Notes)
    }
}

function Parse-Arguments {
    param([string[]]$RawArgs)
    $opts = @{
        Agent     = ""
        Scope     = "project"
        Target    = ""
        DryRun    = $false
        Force     = $false
        Upgrade   = $false
        Uninstall = $false
        List      = $false
        Help      = $false
        RepoUrl   = $DefaultRepoUrl
        Branch    = "main"
    }

    $i = 0
    while ($i -lt $RawArgs.Count) {
        $arg = $RawArgs[$i]
        $norm = $arg.TrimStart('-').ToLowerInvariant()
        switch ($norm) {
            "agent" {
                $i++
                if ($i -ge $RawArgs.Count) { throw "Missing value for $arg" }
                $opts.Agent = $RawArgs[$i].ToLowerInvariant()
            }
            "scope" {
                $i++
                if ($i -ge $RawArgs.Count) { throw "Missing value for $arg" }
                $opts.Scope = $RawArgs[$i].ToLowerInvariant()
            }
            "target" {
                $i++
                if ($i -ge $RawArgs.Count) { throw "Missing value for $arg" }
                $opts.Target = $RawArgs[$i]
            }
            "repo-url" {
                $i++
                if ($i -ge $RawArgs.Count) { throw "Missing value for $arg" }
                $opts.RepoUrl = $RawArgs[$i]
            }
            "repourl" {
                $i++
                if ($i -ge $RawArgs.Count) { throw "Missing value for $arg" }
                $opts.RepoUrl = $RawArgs[$i]
            }
            "branch" {
                $i++
                if ($i -ge $RawArgs.Count) { throw "Missing value for $arg" }
                $opts.Branch = $RawArgs[$i]
            }
            "dry-run"   { $opts.DryRun = $true }
            "dryrun"    { $opts.DryRun = $true }
            "force"     { $opts.Force = $true }
            "upgrade"   { $opts.Upgrade = $true }
            "uninstall" { $opts.Uninstall = $true }
            "list"      { $opts.List = $true }
            "help"      { $opts.Help = $true }
            "h"         { $opts.Help = $true }
            default     { throw "Unknown argument: $arg (use --help for usage)" }
        }
        $i++
    }
    return $opts
}

function Get-FileSha256 {
    param([string]$FilePath)
    return (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Resolve-TargetDirectory {
    param($Opts)
    if ($Opts.Target) {
        return [System.IO.Path]::GetFullPath($Opts.Target)
    }
    if (-not $Opts.Agent) {
        return ""
    }
    if (-not $Adapters.ContainsKey($Opts.Agent)) {
        $supported = ($Adapters.Keys | Sort-Object) -join ", "
        throw "Unsupported agent '$($Opts.Agent)'. Supported: $supported"
    }
    if ($Opts.Scope -notin @("project", "user")) {
        throw "Invalid scope '$($Opts.Scope)'. Must be 'project' or 'user'."
    }
    $adapter = $Adapters[$Opts.Agent]
    $rawPath = if ($Opts.Scope -eq "project") {
        Join-Path (Get-Location).Path $adapter.Project
    } else {
        $adapter.User
    }
    return [System.IO.Path]::GetFullPath($rawPath)
}

function Assert-ChildPath {
    param([string]$RootPath, [string]$CandidatePath)
    $resolvedRoot = [System.IO.Path]::GetFullPath($RootPath).TrimEnd('\', '/')
    $resolvedCandidate = [System.IO.Path]::GetFullPath($CandidatePath)
    if (-not $resolvedCandidate.StartsWith($resolvedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -and
        $resolvedCandidate -ne $resolvedRoot) {
        throw "Unsafe path outside target directory: $CandidatePath"
    }
}

function Invoke-Uninstall {
    param([string]$TargetDir, [bool]$DryRun, [bool]$Force)
    $manifestPath = Join-Path $TargetDir $ManifestName
    if (-not (Test-Path $manifestPath)) {
        throw "No install manifest found at $manifestPath. Nothing to uninstall."
    }
    $manifest = Get-Content -Path $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $skippedModified = 0

    foreach ($entry in $manifest.files) {
        $rel = $entry.path -replace '/', [System.IO.Path]::DirectorySeparatorChar
        $fullPath = Join-Path $TargetDir $rel
        Assert-ChildPath -RootPath $TargetDir -CandidatePath $fullPath
        if (-not (Test-Path $fullPath)) {
            continue
        }
        $currentHash = Get-FileSha256 -FilePath $fullPath
        if ($currentHash -ne $entry.sha256 -and -not $Force) {
            Write-Warning "Skipping locally modified file (pass --force to remove): $rel"
            $skippedModified++
            continue
        }
        if ($DryRun) {
            Write-Host "[DRY-RUN] Remove $fullPath"
        } else {
            Remove-Item -Path $fullPath -Force
            Write-Host "Removed $rel"
        }
    }

    if ($skippedModified -gt 0) {
        throw "Uninstall incomplete: $skippedModified modified file(s) preserved. Re-run with --force to remove them."
    }

    if ($DryRun) {
        Write-Host "[DRY-RUN] Remove $manifestPath"
        return
    }

    Remove-Item -Path $manifestPath -Force
    foreach ($skill in $SkillNames) {
        $skillDir = Join-Path $TargetDir $skill
        if (Test-Path $skillDir) {
            $dirs = Get-ChildItem -Path $skillDir -Directory -Recurse | Sort-Object { $_.FullName.Length } -Descending
            foreach ($d in $dirs) {
                if (@(Get-ChildItem -Path $d.FullName -Force).Count -eq 0) {
                    Remove-Item -Path $d.FullName -Force
                }
            }
            if (@(Get-ChildItem -Path $skillDir -Force).Count -eq 0) {
                Remove-Item -Path $skillDir -Force
            }
        }
    }
    Write-Host "Uninstalled Suraksha skills from $TargetDir"
}

function Invoke-InstallOrUpgrade {
    param(
        [string]$SourceSkillsRoot,
        [string]$TargetDir,
        $Opts
    )

    if (-not $Opts.Target -and $Opts.Agent) {
        $adapter = $Adapters[$Opts.Agent]
        if ($adapter.Status -eq "experimental" -and -not $Opts.Force -and -not $Opts.DryRun -and -not $Opts.Upgrade) {
            throw "Adapter '$($Opts.Agent)' is marked experimental ($($adapter.Notes)). Pass --force to install, or --dry-run to preview."
        }
    }

    $manifestPath = Join-Path $TargetDir $ManifestName
    $oldHashes = @{}
    if (Test-Path $manifestPath) {
        $existingManifest = Get-Content -Path $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($item in $existingManifest.files) {
            $oldHashes[$item.path] = $item.sha256
        }
    } elseif ($Opts.Upgrade) {
        throw "Cannot upgrade: no existing manifest at $manifestPath. Run without --upgrade for a fresh install."
    }

    $sourceFiles = @()
    foreach ($skill in $SkillNames) {
        $skillSrc = Join-Path $SourceSkillsRoot $skill
        if (-not (Test-Path $skillSrc)) {
            throw "Expected skill directory missing: $skillSrc"
        }
        $files = Get-ChildItem -Path $skillSrc -File -Recurse
        foreach ($f in $files) {
            $relFromSkills = $f.FullName.Substring($SourceSkillsRoot.Length).TrimStart('\', '/')
            $relUnix = $relFromSkills -replace '\\', '/'
            $sourceFiles += [PSCustomObject]@{
                SrcFull = $f.FullName
                RelUnix = $relUnix
                RelOS   = $relFromSkills
                Hash    = (Get-FileSha256 -FilePath $f.FullName)
            }
        }
    }

    # Pre-flight conflict & local modification check
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    foreach ($sf in $sourceFiles) {
        $destFull = Join-Path $TargetDir $sf.RelOS
        Assert-ChildPath -RootPath $TargetDir -CandidatePath $destFull
        if (Test-Path $destFull) {
            $destHash = Get-FileSha256 -FilePath $destFull
            if ($destHash -ne $sf.Hash) {
                $wasTrackedClean = $oldHashes.ContainsKey($sf.RelUnix) -and ($oldHashes[$sf.RelUnix] -eq $destHash)
                if ($Opts.Upgrade -and $wasTrackedClean) {
                    continue
                }
                if (-not $Opts.Force) {
                    throw "Conflict on existing file '$($sf.RelUnix)' (content differs). Pass --force to back up and overwrite."
                }
            }
        }
    }

    if (-not $Opts.DryRun -and -not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    $manifestEntries = @()
    foreach ($sf in $sourceFiles) {
        $destFull = Join-Path $TargetDir $sf.RelOS
        $destParent = Split-Path -Path $destFull -Parent
        if (Test-Path $destFull) {
            $destHash = Get-FileSha256 -FilePath $destFull
            if ($destHash -ne $sf.Hash) {
                $wasTrackedClean = $oldHashes.ContainsKey($sf.RelUnix) -and ($oldHashes[$sf.RelUnix] -eq $destHash)
                if (-not ($Opts.Upgrade -and $wasTrackedClean)) {
                    $backupPath = "$destFull.bak.$timestamp"
                    if ($Opts.DryRun) {
                        Write-Host "[DRY-RUN] Backup $destFull -> $backupPath"
                    } else {
                        Copy-Item -Path $destFull -Destination $backupPath -Force
                        Write-Host "Backed up $($sf.RelUnix) -> $($sf.RelUnix).bak.$timestamp"
                    }
                }
            }
        }

        if ($Opts.DryRun) {
            Write-Host "[DRY-RUN] Copy $($sf.RelUnix) -> $destFull"
        } else {
            if (-not (Test-Path $destParent)) {
                New-Item -ItemType Directory -Path $destParent -Force | Out-Null
            }
            Copy-Item -Path $sf.SrcFull -Destination $destFull -Force
        }
        $manifestEntries += @{
            path   = $sf.RelUnix
            sha256 = $sf.Hash
        }
    }

    # Remove stale files on upgrade if they are clean relative to old manifest
    if ($Opts.Upgrade -and $oldHashes.Count -gt 0) {
        $newPathSet = @{}
        foreach ($sf in $sourceFiles) { $newPathSet[$sf.RelUnix] = $true }
        foreach ($oldPath in $oldHashes.Keys) {
            if (-not $newPathSet.ContainsKey($oldPath)) {
                $staleFull = Join-Path $TargetDir ($oldPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                Assert-ChildPath -RootPath $TargetDir -CandidatePath $staleFull
                if (Test-Path $staleFull) {
                    $curHash = Get-FileSha256 -FilePath $staleFull
                    if ($curHash -eq $oldHashes[$oldPath] -or $Opts.Force) {
                        if ($Opts.DryRun) {
                            Write-Host "[DRY-RUN] Remove stale file $staleFull"
                        } else {
                            Remove-Item -Path $staleFull -Force
                        }
                    }
                }
            }
        }
    }

    $manifestObj = [ordered]@{
        package      = "suraksha"
        version      = $SurakshaVersion
        agent        = if ($Opts.Agent) { $Opts.Agent } else { "custom" }
        scope        = if ($Opts.Target) { "custom" } else { $Opts.Scope }
        installed_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        skills       = $SkillNames
        files        = $manifestEntries
    }

    if ($Opts.DryRun) {
        Write-Host "[DRY-RUN] Write manifest $manifestPath ($($manifestEntries.Count) files)"
        return
    }

    $manifestJson = $manifestObj | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($manifestPath, $manifestJson + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Installed Suraksha skills ($($manifestEntries.Count) files) into $TargetDir"
    Write-Host "Manifest written to $manifestPath"
}

# --- Main ---
$opts = Parse-Arguments -RawArgs $args

if ($opts.Help) {
    Show-Usage
    exit 0
}
if ($opts.List) {
    Show-Adapters
    exit 0
}

$targetDir = Resolve-TargetDirectory -Opts $opts
if (-not $targetDir) {
    Show-Usage
    exit 0
}

if ($opts.Uninstall) {
    Invoke-Uninstall -TargetDir $targetDir -DryRun $opts.DryRun -Force $opts.Force
    exit 0
}

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$localSkills = Join-Path $scriptDir "skills"
$hasLocalSuraksha = Test-Path (Join-Path $localSkills "appsec\SKILL.md")
$tempClone = $null

try {
    if (-not $hasLocalSuraksha) {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw "Local 'skills/' directory not found and 'git' is unavailable. Clone the Suraksha repo first and run .\install.ps1 from inside it."
        }
        $tempClone = Join-Path ([System.IO.Path]::GetTempPath()) ("suraksha-src-" + [System.Guid]::NewGuid().ToString("N"))
        Write-Host "Fetching Suraksha skills from $($opts.RepoUrl) ($($opts.Branch))..."
        & git clone --depth 1 --branch $opts.Branch $opts.RepoUrl $tempClone | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "git clone failed with exit code $LASTEXITCODE"
        }
        $localSkills = Join-Path $tempClone "skills"
    }

    Invoke-InstallOrUpgrade -SourceSkillsRoot $localSkills -TargetDir $targetDir -Opts $opts
} finally {
    if ($tempClone -and (Test-Path $tempClone)) {
        Remove-Item -Path $tempClone -Recurse -Force -ErrorAction SilentlyContinue
    }
}
