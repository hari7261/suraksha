# Backend Security

## 1. Objective
Eliminate OS command injection, path traversal, unsafe file uploads, unsafe deserialization, and denial-of-service / error-leakage flaws in server-side code.

## 2. Threat Model
- **Attackers:** Users sending crafted filenames (`../../etc/passwd`), shell metacharacters (`; rm -rf`), polyglot/oversized uploads, or pickled/YAML-tagged payloads.
- **Attack surface:** Subprocess wrappers, file download/upload handlers, archive extractors (`tarfile`/`zipfile`), deserializers, and global exception handlers.

## 3. Common Vulnerabilities
- **Command Injection (CWE-78):** Using `subprocess.run(..., shell=True)`, `os.system()`, or `child_process.exec()` with untrusted input.
- **Path Traversal (CWE-22):** Joining user filenames onto a base path without canonicalizing (`resolve()`) and verifying containment (`is_relative_to()`), or following symlinks escaping the root.
- **Insecure Uploads (CWE-434):** Trusting client `Content-Type` or original filename, missing size limits, or storing uploads inside an executable webroot.
- **Unsafe Deserialization (CWE-502):** Using `pickle.loads()`, `yaml.load()` (without `SafeLoader`), or `node-serialize` on untrusted data.
- **Verbose Error Leakage (CWE-209):** Returning stack traces or internal config in HTTP 500 responses.

## 4. Vulnerable Example
```python
# VULNERABLE: shell=True command injection + path traversal + pickle RCE
import os, pickle, subprocess

def convert_file(user_filename: str):
    path = os.path.join("/var/uploads", user_filename)  # ../../etc/passwd escapes!
    subprocess.run(f"convert {path} {path}.png", shell=True, check=True)  # shell injection!

def load_state(raw_bytes: bytes):
    return pickle.loads(raw_bytes)  # arbitrary code execution!
```

## 5. Secure Example
```python
# SECURE: argv-only subprocess, canonical path boundary check, safe JSON parsing
import json, subprocess
from pathlib import Path

UPLOAD_ROOT = Path("/var/uploads").resolve()

def safe_resolve(user_filename: str) -> Path:
    candidate = (UPLOAD_ROOT / user_filename).resolve()
    if not candidate.is_relative_to(UPLOAD_ROOT) or candidate.is_symlink():
        raise ValueError("Invalid file path")
    return candidate

def convert_file(user_filename: str):
    src = safe_resolve(user_filename)
    dst = src.with_suffix(".png")
    subprocess.run(["convert", str(src), str(dst)], shell=False, check=True, timeout=30)

def load_state(raw_bytes: bytes) -> dict:
    return json.loads(raw_bytes.decode("utf-8"))
```

## 6. Framework Notes
- **Uploads:** Generate random UUID storage names, validate magic bytes + allowlisted extensions, enforce strict size caps before reading into memory, serve downloads with `Content-Disposition: attachment` and `X-Content-Type-Options: nosniff` from an isolated bucket/domain.
- **Archives (Zip Slip):** Check every entry's resolved target path before extracting from `zip`/`tar`.
- **Errors:** Log detailed exceptions server-side (redacted) with a correlation ID; return `{"error": "Internal server error", "request_id": "..."}` to clients.

## 7. Detection Strategy
- Run `bandit` / `semgrep` for `shell=True`, `os.system`, `pickle`, `yaml.load`, `eval`, `exec`, `child_process.exec`.
- Inspect all `open()`, `send_file()`, and archive extraction paths.

## 8. Remediation
- Switch all subprocess calls to `argv` arrays (`shell=False`) with timeouts.
- Canonicalize all user-influenced paths and reject symlinks or prefix escapes.
- Replace `pickle`/`yaml.load` with `json` or `yaml.safe_load`.

## 9. Testing Requirements
- Test `../../etc/passwd`, symlink escapes, `; id` / `$(whoami)` inputs, oversized request bodies (> limit -> 413), and malformed YAML/JSON payloads.

## 10. Standards References
- OWASP Top 10 (2021) — A03:2021 Injection, A08:2021 Software and Data Integrity Failures
- OWASP ASVS 4.0.3 (V5 Validation, V12 Files and Resources)
- CWE-22, CWE-78, CWE-434, CWE-502

