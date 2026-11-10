"""Clean reference implementation demonstrating Suraksha secure defaults."""

from pathlib import Path
import sqlite3


def fetch_order_for_tenant(conn: sqlite3.Connection, tenant_id: str, order_id: int):
    """Fetch a single order strictly scoped to the authenticated tenant."""
    cur = conn.cursor()
    cur.execute(
        "SELECT id, status, total_cents FROM orders WHERE id = ? AND tenant_id = ?",
        (order_id, tenant_id),
    )
    return cur.fetchone()


def read_safe_workspace_file(workspace_root: Path, relative_path: str) -> str:
    """Read a UTF-8 file after verifying canonical containment inside workspace_root."""
    root = workspace_root.resolve()
    candidate = (root / relative_path).resolve()
    if not candidate.is_relative_to(root) or candidate.is_symlink():
        raise ValueError("Invalid path: escapes workspace root")
    return candidate.read_text(encoding="utf-8")

