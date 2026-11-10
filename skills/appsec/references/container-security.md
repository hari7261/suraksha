# Container & CI/CD Security

## 1. Objective
Harden Docker images, Kubernetes workloads, and CI/CD pipelines against container escape, supply-chain tampering, root execution, and CI secret exfiltration.

## 2. Threat Model
- **Attackers:** Container-breakout exploits from compromised app processes, untrusted PRs triggering CI secret leaks, and tampered base images.
- **Attack surface:** `Dockerfile`, `docker-compose.yml`, Kubernetes `Pod`/`Deployment` specs, Helm charts, and `.github/workflows/*.yml`.

## 3. Common Vulnerabilities
- Running containers as `root` (`UID 0`) without dropping Linux capabilities.
- `privileged: true`, `hostNetwork: true`, `hostPID: true`, or mounting `/var/run/docker.sock`.
- Unpinned mutable image tags (`FROM python:latest`) or baking secrets via `ARG`/`COPY .env`.
- Missing Kubernetes `SecurityContext` (`readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`, resource limits).
- **CI/CD:** `pull_request_target` checking out untrusted PR code with access to repo secrets, or `${{ github.event.pull_request.title }}` interpolated directly in `run:` scripts (GitHub Actions script injection!).

## 4. Vulnerable Example
```dockerfile
# VULNERABLE: latest tag, runs as root, copies .env into image layer
FROM python:latest
WORKDIR /app
COPY . .
CMD ["python", "app.py"]
```

```yaml
# GitHub Actions — VULNERABLE: script injection from PR title + unpinned action
- uses: actions/checkout@v4
- run: echo "PR Title: ${{ github.event.pull_request.title }}"
```

## 5. Secure Example
```dockerfile
# SECURE: Pinned digest, multi-stage minimal image, non-root user
FROM python:3.12-slim@sha256:0000000000000000000000000000000000000000000000000000000000000000 AS runtime
RUN useradd --create-home --uid 10001 appuser
WORKDIR /app
COPY --chown=appuser:appuser . .
USER 10001
CMD ["python", "app.py"]
```

```yaml
# Kubernetes Pod SecurityContext — SECURE
securityContext:
  runAsNonRoot: true
  runAsUser: 10001
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]
```

## 6. Framework Notes
- **Docker:** Always ship a `.dockerignore` excluding `.git/`, `.env`, tests, and secrets; use multi-stage builds to omit compilers from runtime images.
- **GitHub Actions:** Set minimal `permissions:` at workflow/job level (`contents: read`), pin actions by full SHA, and pass untrusted event fields via `env:` instead of `${{ ... }}` inside `run:`.

## 7. Detection Strategy
- Run `trivy image` / `trivy config` when available; inspect `Dockerfile` for `USER`, `.dockerignore`, and `ARG`, and inspect Kubernetes YAML for `privileged`, `capabilities`, and `resources.limits`.

## 8. Remediation
- Drop all Linux capabilities, enforce non-root `USER`, pin image digests, set CPU/memory limits, and sanitize GitHub Actions expressions.

## 9. Testing Requirements
- Verify container starts and runs tests as non-root (`id -u` != 0) with a read-only root filesystem (mounting `/tmp` only if needed).

## 10. Standards References
- OWASP Top 10 (2021) — A05:2021 Security Misconfiguration
- OWASP CI/CD Security Risks (Top 10)
- CIS Docker & Kubernetes Benchmarks
- CWE-250, CWE-269, CWE-94

