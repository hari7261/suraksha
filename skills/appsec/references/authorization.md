# Authorization Security

## 1. Objective
Enforce server-side, deny-by-default access control on every endpoint, resource, tenant boundary, and administrative function. **Authentication is not authorization.**

## 2. Threat Model
- **Attackers:** Authenticated low-privilege users probing other users' IDs (IDOR/BOLA), manipulating role parameters, or reaching unguarded admin routes (BFLA).
- **Attack surface:** Path parameters (`/orders/{id}`), GraphQL resolvers, bulk export endpoints, background job triggers, and multi-tenant queries.

## 3. Common Vulnerabilities
- **BOLA / IDOR (CWE-639):** Fetching records by primary key without checking `record.owner_id == current_user.id` or `record.tenant_id == current_user.tenant_id`.
- **BFLA (CWE-285):** Admin or staff endpoints missing role/capability checks.
- **Client-controlled authorization:** Trusting `is_admin`, `role`, or `tenant_id` from request JSON, query params, or unsigned headers.
- **Mass assignment:** Binding incoming JSON directly onto database models containing `role`, `plan`, or `is_verified`.

## 4. Vulnerable Example
```python
# VULNERABLE: Authenticated user can read any tenant's invoice (IDOR / BOLA)
@app.get("/api/invoices/{invoice_id}")
def get_invoice(invoice_id: int, current_user=Depends(get_current_user)):
    invoice = db.get_invoice(invoice_id)
    if not invoice:
        raise HTTPException(status_code=404)
    return invoice
```

## 5. Secure Example
```python
# SECURE: Deny-by-default ownership + tenant scoping in the query itself
@app.get("/api/invoices/{invoice_id}")
def get_invoice(invoice_id: int, current_user=Depends(get_current_user)):
    invoice = db.get_invoice_for_tenant(
        invoice_id=invoice_id,
        tenant_id=current_user.tenant_id,
    )
    if not invoice:
        raise HTTPException(status_code=404)
    if invoice.owner_id != current_user.id and "billing:read_all" not in current_user.permissions:
        raise HTTPException(status_code=403, detail="Forbidden")
    return invoice
```

## 6. Framework Notes
- **RBAC / ABAC:** Centralize policy checks in reusable dependencies/middleware or policy engines rather than scattering ad-hoc `if` checks.
- **Admin separation:** Separate admin routes/tokens/scopes from standard user routes; audit all privileged actions.
- **Mass assignment:** Use explicit Pydantic/Zod input DTOs that only list user-editable fields.

## 7. Detection Strategy
- Audit every route handler for: (1) auth middleware, (2) role/permission check, (3) object ownership/tenant predicate on DB lookups.
- Flag handlers that accept `user_id` or `tenant_id` from request body instead of the verified session/token.

## 8. Remediation
- Scope all repository queries by `tenant_id` / `owner_id` derived strictly from server-side auth context.
- Enforce explicit allowlists on update DTOs and default-deny middleware on router groups.

## 9. Testing Requirements
- Write cross-user and cross-tenant integration tests (User A tries to GET/PUT/DELETE User B's resource -> assert 403 or 404).
- Test non-admin users calling every admin endpoint -> assert 403.

## 10. Standards References
- OWASP API Security Top 10 (2023) — API1:2023 BOLA, API5:2023 BFLA
- OWASP ASVS 4.0.3 (V4 Access Control)
- CWE-285, CWE-639, CWE-862

