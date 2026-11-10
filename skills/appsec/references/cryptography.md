# Cryptography

## 1. Objective
Ensure cryptographic primitives, modes, key lengths, randomness, and TLS configurations use vetted modern standards without homegrown algorithms or broken modes.

## 2. Threat Model
- **Attackers:** Passive network eavesdroppers, active MITM attackers, padding-oracle/chosen-ciphertext attackers, and offline brute-forcers.
- **Attack surface:** Symmetric encryption, password/token hashing, HMACs, CSPRNG usage, TLS client/server settings, and key rotation.

## 3. Common Vulnerabilities
- Broken or deprecated algorithms: MD5, SHA-1 (for integrity/passwords), DES, 3DES, RC4, ECB mode (`AES/ECB`).
- Nonce/IV reuse in AES-GCM or ChaCha20-Poly1305 (catastrophic key/plaintext recovery).
- Unauthenticated encryption (AES-CBC without HMAC/AEAD) vulnerable to padding-oracle/tampering attacks.
- Non-cryptographic PRNG (`random.random()`, `Math.random()`) used for tokens, OTPs, or reset codes.
- Non-constant-time secret comparison (`==` instead of `hmac.compare_digest` / `crypto.timingSafeEqual`).
- Disabling TLS validation (`verify=False`, `InsecureSkipVerify: true`).

## 4. Vulnerable Example
```python
# VULNERABLE: Predictable PRNG token + ECB encryption + disabled TLS verification
import random, requests
from Crypto.Cipher import AES

token = str(random.randint(100000, 999999))  # predictable PRNG!
cipher = AES.new(key, AES.MODE_ECB)          # ECB leaks patterns & lacks integrity!
resp = requests.get("https://partner.example/api", verify=False)  # MITM vulnerable!
```

## 5. Secure Example
```python
# SECURE: CSPRNG, AEAD (AES-256-GCM), constant-time compare, verified TLS
import hmac, os, secrets, requests
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

token = secrets.token_urlsafe(32)  # 256-bit CSPRNG

def encrypt_aead(key_32b: bytes, plaintext: bytes, aad: bytes = b"") -> bytes:
    nonce = os.urandom(12)  # fresh 96-bit random nonce per encryption
    ct = AESGCM(key_32b).encrypt(nonce, plaintext, aad)
    return nonce + ct

def constant_time_equal(a: bytes, b: bytes) -> bool:
    return hmac.compare_digest(a, b)

resp = requests.get("https://partner.example/api", verify=True, timeout=10)
```

## 6. Framework Notes
- **Python:** Use `cryptography` (`AESGCM`, `ChaCha20Poly1305`, `Ed25519`), `argon2-cffi`, `secrets`, and `hmac.compare_digest`.
- **Node.js:** Use `node:crypto` (`crypto.randomBytes`, `crypto.createCipheriv('aes-256-gcm', ...)`, `crypto.timingSafeEqual`).
- **TLS:** Enforce TLS 1.2+ (prefer TLS 1.3), strong AEAD cipher suites, and full hostname + certificate chain verification.

## 7. Detection Strategy
- Search for `MODE_ECB`, `DES`, `RC4`, `MD5`, `SHA1`, `Math.random`, `random.randint` in security contexts, and `verify=False` / `rejectUnauthorized: false`.

## 8. Remediation
- Replace custom crypto and unauthenticated modes with high-level AEAD (`AES-256-GCM` or `ChaCha20-Poly1305`) or envelope encryption via cloud KMS.
- Never reuse nonces under the same key; rotate keys on a schedule and support key IDs (`kid`) for seamless rotation.

## 9. Testing Requirements
- Test tamper detection (modifying 1 byte of ciphertext or tag must fail decryption).
- Test that tokens/OTPs come from CSPRNG and TLS verification rejects self-signed/mismatched certs in integration tests.

## 10. Standards References
- OWASP Top 10 (2021) — A02:2021 Cryptographic Failures
- OWASP ASVS 4.0.3 (V6 Stored Cryptography, V9 Communications)
- NIST SP 800-38D (GCM), SP 800-57
- CWE-295, CWE-327, CWE-329, CWE-338

