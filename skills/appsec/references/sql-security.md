# SQL Security

## 1. Objective
Prevent SQL injection, unauthorized cross-tenant data access, unsafe dynamic identifiers, and database credential/query leakage across relational databases and ORMs.

## 2. Threat Model
- **Attackers:** Unauthenticated users, authenticated users escalating across tenants, or indirect inputs from webhooks/LLMs reaching SQL sinks.
- **Attack surface:** Query parameters, JSON filters, dynamic `ORDER BY` / table / column names, raw ORM escapes (`extra()`, `text()`, `$queryRawUnsafe`), and stored procedures.

## 3. Common Vulnerabilities
- CWE-89: String concatenation, f-strings, `%` formatting, or template literals in SQL queries.
- Unsafe dynamic identifiers (`ORDER BY {sort_col}`) not mapped through a strict allowlist.
- Missing tenant predicate (`WHERE tenant_id = ?`) on multi-tenant queries.
- Over-privileged DB accounts (`SUPERUSER` / `sa`) used by web workers.
- Logging raw SQL queries containing passwords, tokens, or PII.

## 4. Vulnerable Example
```python
# Python / PostgreSQL — VULNERABLE to SQL injection
def find_user(conn, email: str):
    cur = conn.cursor()
    cur.execute(f"SELECT id, email FROM users WHERE email = '{email}'")
    return cur.fetchone()
```

```javascript
// Node.js / MySQL — VULNERABLE to SQL injection & dynamic sort injection
async function listOrders(pool, status, sortCol) {
  const sql = `SELECT id, total FROM orders WHERE status = '${status}' ORDER BY ${sortCol}`;
  return pool.query(sql);
}
```

## 5. Secure Example
```python
# Python / PostgreSQL — Parameterized query + strict identifier allowlist
ALLOWED_SORT = {"created_at": "created_at", "total": "total_cents"}

def list_orders(conn, tenant_id: str, status: str, sort_key: str):
    col = ALLOWED_SORT.get(sort_key, "created_at")
    with conn.cursor() as cur:
        cur.execute(
            f"SELECT id, total_cents FROM orders WHERE tenant_id = %s AND status = %s ORDER BY {col} DESC",
            (tenant_id, status),
        )
        return cur.fetchall()
```

```javascript
// Node.js / MySQL2 — Parameterized placeholders + mapped sort column
const SORT_COLS = { created_at: "created_at", total: "total_cents" };
async function listOrders(pool, tenantId, status, sortKey) {
  const col = SORT_COLS[sortKey] ?? "created_at";
  const [rows] = await pool.execute(
    `SELECT id, total_cents FROM orders WHERE tenant_id = ? AND status = ? ORDER BY ${col} DESC`,
    [tenantId, status]
  );
  return rows;
}
```

## 6. Framework Notes
- **SQLAlchemy:** Use bound parameters (`text("... WHERE id = :id").bindparams(id=val)`) or ORM expressions; avoid f-strings inside `text()`.
- **Django ORM:** Avoid `.raw()` with string formatting and `.extra()`; use `Model.objects.filter(...)`.
- **Prisma:** Use `prisma.$queryRaw\`... ${val}\`` (tagged template = parameterized), never `$queryRawUnsafe`.
- **Stored procedures:** Parameterize inside the procedure too; avoid `EXECUTE IMMEDIATE` with concatenated strings.
- **Connections:** Enforce TLS (`sslmode=require` / `verify-full`), least-privilege app roles (no `DDL` in web runtime), and separate migration credentials.

## 7. Detection Strategy
- Search for `execute(f"`, `+ req.`, `.raw(`, `$queryRawUnsafe`, and `ORDER BY ${`.
- Run `semgrep` (`p/sql-injection`) or `bandit` (`B608`) when available.

## 8. Remediation
- Replace every interpolated value with bound placeholders (`%s`, `?`, `$1`, `:name`).
- Replace dynamic table/column names with a server-side dictionary allowlist.
- Wrap multi-step updates in explicit transactions with appropriate isolation levels.

## 9. Testing Requirements
- Add negative tests sending `' OR '1'='1`, `'; DROP TABLE users; --`, and invalid `sort_key` values, asserting safe error handling and zero unintended row access.

## 10. Standards References
- OWASP Top 10 (2021) — A03:2021 Injection
- OWASP ASVS 4.0.3 (V5.3.4, V5.3.5)
- CWE-89 (SQL Injection)

