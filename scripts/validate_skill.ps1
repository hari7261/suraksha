<#
.SYNOPSIS
    Zero-dependency PowerShell validator for Suraksha Agent Skills.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$SkillsDir = Join-Path $Root "skills"
$MaxSkillLines = 250
$RequiredSections = @(
    "## 1. Objective",
    "## 2. Threat Model",
    "## 3. Common Vulnerabilities",
    "## 4. Vulnerable Example",
    "## 5. Secure Example",
    "## 6. Framework Notes",
    "## 7. Detection Strategy",
    "## 8. Remediation",
    "## 9. Testing Requirements",
    "## 10. Standards References"
)

$Errors = New-Object System.Collections.Generic.List[string]
$SkillDirs = @(Get-ChildItem -Path $SkillsDir -Directory)

if ($SkillDirs.Count -eq 0) {
    $Errors.Add("No skill directories found under $SkillsDir")
}

foreach ($sdir in $SkillDirs) {
    $skillMd = Join-Path $sdir.FullName "SKILL.md"
    $metaJson = Join-Path $sdir.FullName "metadata.json"

    if (-not (Test-Path $skillMd)) {
        $Errors.Add("Missing SKILL.md in $($sdir.Name)")
        continue
    }

    $lines = Get-Content -Path $skillMd -Encoding UTF8
    if ($lines.Count -gt $MaxSkillLines) {
        $Errors.Add("$($sdir.Name)/SKILL.md exceeds $MaxSkillLines lines ($($lines.Count))")
    }

    $raw = Get-Content -Path $skillMd -Raw -Encoding UTF8
    if ($raw -notmatch "(?s)^---\r?\n.*?\r?\n---") {
        $Errors.Add("$($sdir.Name)/SKILL.md missing valid YAML frontmatter block")
    }
    if ($raw -notmatch "(?m)^name:\s*$($sdir.Name)\s*$") {
        $Errors.Add("$($sdir.Name)/SKILL.md frontmatter 'name' must match '$($sdir.Name)'")
    }
    foreach ($req in @("description:", "license:", "version:", "min_engine_version:")) {
        if ($raw -notmatch "(?m)^$req") {
            $Errors.Add("$($sdir.Name)/SKILL.md missing required frontmatter key '$req'")
        }
    }

    # Check relative markdown links
    $linkMatches = [regex]::Matches($raw, '\[[^\]]+\]\(([^)#]+)(?:#[^)]*)?\)')
    foreach ($m in $linkMatches) {
        $target = $m.Groups[1].Value.Trim()
        if ($target -match '^(https?://|mailto:)') { continue }
        $resolved = Join-Path $sdir.FullName ($target -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path $resolved)) {
            $Errors.Add("$($sdir.Name)/SKILL.md has broken relative link: $target")
        }
    }

    if (-not (Test-Path $metaJson)) {
        $Errors.Add("Missing metadata.json in $($sdir.Name)")
    } else {
        $meta = Get-Content -Path $metaJson -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($meta.name -ne $sdir.Name) {
            $Errors.Add("$($sdir.Name)/metadata.json name '$($meta.name)' != '$($sdir.Name)'")
        }
        foreach ($rel in $meta.references) {
            $resolved = Join-Path $sdir.FullName ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            if (-not (Test-Path $resolved)) {
                $Errors.Add("$($sdir.Name)/metadata.json broken reference: $rel")
            }
        }
        foreach ($rel in $meta.templates) {
            $resolved = Join-Path $sdir.FullName ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            if (-not (Test-Path $resolved)) {
                $Errors.Add("$($sdir.Name)/metadata.json broken template: $rel")
            }
        }
    }
}

$refsDir = Join-Path (Join-Path $SkillsDir "appsec") "references"
$refFiles = @(Get-ChildItem -Path $refsDir -Filter "*.md")
if ($refFiles.Count -lt 19) {
    $Errors.Add("Expected at least 19 references under appsec/references/, found $($refFiles.Count)")
}
foreach ($rf in $refFiles) {
    $content = Get-Content -Path $rf.FullName -Raw -Encoding UTF8
    foreach ($sec in $RequiredSections) {
        if ($content -notlike "*$sec*") {
            $Errors.Add("appsec/references/$($rf.Name) missing section '$sec'")
        }
    }
}

if ($Errors.Count -gt 0) {
    Write-Error ("Skill validation failed:`n - " + ($Errors -join "`n - "))
    exit 1
}

Write-Host "OK: PowerShell validation passed for $($SkillDirs.Count) skills and $($refFiles.Count) references."
exit 0
