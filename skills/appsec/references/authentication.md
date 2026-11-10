# Authentication Security

## 1. Objective
Ensure identities are verified robustly using modern password hashing, hardened session/JWT lifecycle controls, brute-force defenses, and secure OAuth/OIDC flows.

## 2. Threat Model
- **Attackers:** Credential stuffers, token forgers, session hijackers, and phishing/reset-flow abusers.
- **Attack surface:** Login, registration, password reset, MFA verification, JWT verification middleware, OAuth callbacks, and cookie attributes.

## 3. Common Vulnerabilities
- Weak or unsalted password hashing (MD5, SHA-1, plain SHA-256) or plaintext storage.
- JWT `alg=none`, algorithm confusion (`RS256` key used as `HS256` secret), or skipping `exp`/`iss`/`aud` verification.
- Account enumeration via distinct login/reset error messages or response timing differences.
- Missing rate limiting and lockout/throttling on login, OTP, and password reset endpoints.
- Long-lived unrotated refresh tokens or missing revocation on password change / logout.
- Session cookies missing `HttpOnly`, `Secure`, or `SameSite` flags.

## 4. Vulnerable Example
```python
# VULNERABLE: SHA-256 password hash, unverified JWT algorithm, verbose enumeration
import hashlib, jwt

def verify_login(user, password: str):
    if hashlib.sha256(password.encode()).hexdigest() != user.pw_hash:
        return {"error": "Wrong password for this account"}  # leaks account existence
    return {"token": jwt.encode({"sub": user.id}, "hardcoded-secret", algorithm="HS256")}

def decode_token(token: str):
    return jwt.decode(token, options={"verify_signature": False})
```

## 5. Secure Example
```python
# SECURE: Argon2id password hashing + strict JWT verification
import os, jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError

ph = PasswordHasher()  # Argon2id defaults

def hash_password(password: str) -> str:
    return ph.hash(password)

def verify_password(stored_hash: str, password: str) -> bool:
    try:
        return ph.verify(stored_hash, password)
    except VerifyMismatchError:
        return False

def verify_jwt(token: str) -> dict:
    key = os.environ["JWT_PUBLIC_KEY"]
    return jwt.decode(
        token,
        key,
        algorithms=["EdDSA", "RS256"],  # explicit allowlist; never HS256 with RSA pubkey
        audience="suraksha-api",
        issuer="https://auth.example.com",
        options={"require": ["exp", "iat", "iss", "aud", "sub"]},
    )
```

## 6. Framework Notes
- **Password hashing:** Prefer **Argon2id**; use `bcrypt` (cost >= 12) or `scrypt` only when Argon2id is unavailable. Enforce >= 12-char passphrases and check breached-password lists when feasible.
- **Sessions & Cookies:** Set `HttpOnly=True`, `Secure=True`, `SameSite=Lax` (or `Strict`), regenerate session ID on login/privilege change, and invalidate sessions on logout/password reset.
- **Refresh tokens:** Rotate on every use with reuse detection; store hashed refresh tokens in DB.
- **OAuth / OIDC:** Require PKCE (`S256`), cryptographically random `state` and `nonce`, and exact `redirect_uri` matching.
- **MFA:** Prefer WebAuthn/FIDO2 or TOTP with single-use backup codes and rate-limited verification.

## 7. Detection Strategy
- Inspect all `jwt.decode` calls for missing `algorithms=[...]` or `verify_signature=False`.
- Search for `md5`, `sha1`, `sha256` near `password`, and cookie setters missing `httpOnly`/`secure`.

## 8. Remediation
- Migrate password hashing to Argon2id via verify-and-rehash on login.
- Enforce explicit JWT algorithm allowlists and short access-token TTLs (5–15 min).
- Return generic messages (`"Invalid credentials"`) and apply per-IP + per-account rate limits.

## 9. Testing Requirements
- Test expired tokens, wrong `aud`/`iss`, `alg=none`, tampered signatures, brute-force throttling, session fixation resistance, and cookie security flags.

## 10. Standards References
- OWASP Top 10 (2021) — A07:2021 Identification and Authentication Failures
- OWASP ASVS 4.0.3 (V2 Authentication, V3 Session Management)
- NIST SP 800-63B (Digital Identity Guidelines)
- CWE-287, CWE-347, CWE-798, CWE-916

