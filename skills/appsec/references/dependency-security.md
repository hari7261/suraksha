# Dependency & Supply-Chain Security

## 1. Objective
Reduce exposure to known CVEs, malicious packages, dependency confusion, typosquatting, and unverified build artifacts across ecosystems.

## 2. Threat Model
- **Attackers:** Supply-chain attackers publishing typosquatted packages, hijacking maintainer accounts, exploiting unpinned transitive dependencies, or poisoning build pipelines.
- **Attack surface:** `package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, install scripts (`postinstall`), and third-party GitHub Actions.

## 3. Common Vulnerabilities
- Missing lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `uv.lock`, `poetry.lock`) or unpinned ranges allowing silent malicious upgrades.
- Typosquatting or dependency confusion against internal private package names.
- Unpatched critical/high CVEs in reachable runtime dependencies.
- GitHub Actions referenced by mutable tags (`@v4` / `@main`) instead of full commit SHAs.
- Executing untrusted `postinstall` scripts during CI or local inspection of unknown repos.

## 4. Vulnerable Example
```json
// VULNERABLE: Unpinned wildcard / latest versions + no integrity lockfile
{
  "dependencies": {
    "express": "*",
    "lodash": "latest",
    "internal-auth-sdk": "^1.0.0"
  }
}
```

## 5. Secure Example
```yaml
# SECURE: Pin GitHub Actions by full commit SHA and lock dependency versions
steps:
  - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
  - run: npm ci --ignore-scripts
```

## 6. Framework Notes
- **Node.js:** Commit `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock`; install in CI with `npm ci` (consider `--ignore-scripts` for untrusted repos).
- **Python:** Use hash-pinned `requirements.txt` (`pip-compile --generate-hashes`) or `uv.lock` / `poetry.lock`; verify package names carefully on PyPI.
- **Provenance & SBOM:** Generate CycloneDX or SPDX SBOMs on release builds and verify checksums/signatures for downloaded binaries.

## 7. Detection Strategy
- Run `pip-audit`, `npm audit`, `trivy fs`, or `osv-scanner` when available.
- Inspect manifests for `*` / `latest` / `git+http://` dependencies and unpinned CI actions.

## 8. Remediation
- Upgrade vulnerable packages to patched versions, evaluate reachability/breaking changes, and regenerate the lockfile.
- Scope private package namespaces (`.npmrc` `@org:registry`) so public registries cannot hijack internal names.

## 9. Testing Requirements
- Run full test suite after dependency bumps; enforce automated lockfile integrity and vulnerability gates in CI.

## 10. Standards References
- OWASP Top 10 (2021) — A06:2021 Vulnerable and Outdated Components, A08:2021 Software and Data Integrity Failures
- SLSA v1.0 (Supply-chain Levels for Software Artifacts)
- NIST SSDF 1.1 (PW.4, RV.1)
- CWE-1104, CWE-494, CWE-829

