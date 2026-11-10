# Database Security

## 1. Objective
Harden database deployments, connection security, least-privilege roles, tenant isolation, backups, migrations, and data retention beyond query parameterization.

## 2. Threat Model
- **Attackers:** Compromised app instances abusing DBA credentials, network sniffers intercepting unencrypted DB traffic, or attackers accessing unencrypted backups.
- **Attack surface:** DB connection strings, privilege grants, schema migrations, connection pools, read replicas, and backup storage.

## 3. Common Vulnerabilities
- Application connecting as `postgres` / `root` / `sa` superuser instead of a least-privilege role.
- Database traffic sent over plaintext (`sslmode=disable`) or ignoring server certificates.
- Missing row-level or schema-level isolation in multi-tenant databases.
- Destructive or lock-heavy migrations running unreviewed against production.
- Unencrypted backups or backups stored in publicly accessible object storage.

## 4. Vulnerable Example
```yaml
# VULNERABLE: Superuser DB credential, plaintext connection, no TLS verification
DATABASE_URL: "postgresql://postgres:Admin123!@db.internal:5432/prod?sslmode=disable"
```

## 5. Secure Example
```yaml
# SECURE: Dedicated least-privilege app role + verified TLS + KMS-encrypted backups
DATABASE_URL: "postgresql://app_rw@${DB_HOST}:5432/prod?sslmode=verify-full&sslrootcert=/etc/ssl/certs/rds-ca.pem"
```

```sql
-- Least-privilege application role (no DDL, no superuser)
CREATE ROLE app_rw WITH LOGIN PASSWORD '...';
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA app TO app_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO app_rw;
```

## 6. Framework Notes
- **PostgreSQL:** Consider Row-Level Security (RLS) as defense-in-depth for multi-tenant isolation alongside application-level `WHERE tenant_id = $1` scoping.
- **MongoDB:** Disable unauthenticated binding, avoid `$where` JavaScript execution, and sanitize operator keys (`$ne`, `$gt`) out of user JSON objects (NoSQL injection).
- **Redis:** Require ACL authentication + TLS (`rediss://`), bind to private network only, and disable dangerous commands (`FLUSHALL`, `CONFIG`) where unused.
- **Pooling & Migrations:** Use separate credentials for schema migrations vs runtime traffic; set statement timeouts to prevent runaway query DoS.

## 7. Detection Strategy
- Inspect connection strings for `sslmode=disable`, `tls=false`, `root`/`postgres`/`admin` app users, and hardcoded passwords.
- Audit MongoDB/Mongoose queries for raw `req.body` passed into `find(req.body)`.

## 8. Remediation
- Separate migration roles from runtime CRUD roles; enable TLS verification in transit and KMS encryption at rest (including backups and snapshots).
- Enforce retention schedules and cryptographic/secure deletion for expired PII.

## 9. Testing Requirements
- Verify app DB user fails on `DROP TABLE` / `CREATE ROLE` attempts.
- Test multi-tenant queries and NoSQL filter inputs (`{"$ne": ""}`) to confirm injection resistance.

## 10. Standards References
- OWASP ASVS 4.0.3 (V6 Stored Cryptography, V9 Communications, V14 Configuration)
- NIST SSDF 1.1 (PW.2, PW.7)
- CWE-250 (Execution with Unnecessary Privileges), CWE-319 (Cleartext Transmission), CWE-943 (NoSQLi)

