#!/usr/bin/env python3
"""Zero-dependency Suraksha Agent Skill validator (Python stdlib only)."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"
SCHEMAS_DIR = ROOT / "schemas"
MAX_SKILL_LINES = 250

REQUIRED_REFERENCE_SECTIONS = [
    "## 1. Objective",
    "## 2. Threat Model",
    "## 3. Common Vulnerabilities",
    "## 4. Vulnerable Example",
    "## 5. Secure Example",
    "## 6. Framework Notes",
    "## 7. Detection Strategy",
    "## 8. Remediation",
    "## 9. Testing Requirements",
    "## 10. Standards References",
]

LINK_RE = re.compile(r"\[[^\]]+\]\(([^)#]+)(?:#[^)]*)?\)")
SEMVER_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$")
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def parse_simple_yaml_frontmatter(text: str) -> tuple[dict[str, object], str]:
    """Parse YAML frontmatter subset used in SKILL.md without external packages."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError("Missing opening YAML frontmatter delimiter '---'")
    end_idx = None
    for idx in range(1, len(lines)):
        if lines[idx].strip() == "---":
            end_idx = idx
            break
    if end_idx is None:
        raise ValueError("Missing closing YAML frontmatter delimiter '---'")

    fm_lines = lines[1:end_idx]
    body = "\n".join(lines[end_idx + 1 :])
    data: dict[str, object] = {}
    i = 0
    while i < len(fm_lines):
        line = fm_lines[i]
        if not line.strip() or line.lstrip().startswith("#"):
            i += 1
            continue
        if ":" not in line or line.startswith(" "):
            raise ValueError(f"Unexpected frontmatter syntax at line: {line!r}")
        key, raw_val = line.split(":", 1)
        key = key.strip()
        val = raw_val.strip()

        if val in {"|", ">", ">-", "|-"}:
            block: list[str] = []
            i += 1
            while i < len(fm_lines) and (fm_lines[i].startswith("  ") or not fm_lines[i].strip()):
                block.append(fm_lines[i][2:] if fm_lines[i].startswith("  ") else "")
                i += 1
            data[key] = "\n".join(block).strip()
            continue

        if val == "":
            items: list[object] = []
            i += 1
            while i < len(fm_lines) and fm_lines[i].startswith("  - "):
                item_text = fm_lines[i][4:].strip()
                if item_text.startswith("keywords:"):
                    kw_raw = item_text.split(":", 1)[1].strip()
                    items.append({"keywords": _parse_inline_list(kw_raw)})
                else:
                    items.append(item_text)
                i += 1
            data[key] = items
            continue

        if val.startswith("[") and val.endswith("]"):
            data[key] = _parse_inline_list(val)
        else:
            data[key] = val.strip('"').strip("'")
        i += 1

    return data, body


def _parse_inline_list(raw: str) -> list[str]:
    inner = raw.strip()
    if not (inner.startswith("[") and inner.endswith("]")):
        raise ValueError(f"Expected inline list, got: {raw!r}")
    inner = inner[1:-1].strip()
    if not inner:
        return []
    return [part.strip().strip('"').strip("'") for part in inner.split(",") if part.strip()]


def validate_skill_schema(frontmatter: dict[str, object], dir_name: str, schema: dict) -> list[str]:
    errors: list[str] = []
    allowed = set(schema["properties"].keys())
    required = set(schema["required"])

    unknown = set(frontmatter.keys()) - allowed
    if unknown:
        errors.append(f"Unknown frontmatter key(s): {sorted(unknown)}")
    missing = required - set(frontmatter.keys())
    if missing:
        errors.append(f"Missing required frontmatter key(s): {sorted(missing)}")

    name = frontmatter.get("name")
    if isinstance(name, str):
        if not NAME_RE.match(name):
            errors.append(f"Invalid skill name {name!r}")
        if name != dir_name:
            errors.append(f"Skill name {name!r} does not match directory {dir_name!r}")
    else:
        errors.append("'name' must be a string")

    desc = frontmatter.get("description")
    if not isinstance(desc, str) or len(desc) < 20 or len(desc) > 1024:
        errors.append("'description' must be a string between 20 and 1024 characters")

    for ver_key in ("version", "min_engine_version"):
        ver = frontmatter.get(ver_key)
        if not isinstance(ver, str) or not SEMVER_RE.match(ver):
            errors.append(f"'{ver_key}' must be a valid semver string, got {ver!r}")

    if "activation_triggers" in frontmatter:
        triggers = frontmatter["activation_triggers"]
        if not isinstance(triggers, list) or not triggers:
            errors.append("'activation_triggers' must be a non-empty list")
        else:
            for item in triggers:
                if not isinstance(item, dict) or set(item.keys()) != {"keywords"}:
                    errors.append(f"Invalid activation_triggers entry: {item!r}")
                elif not isinstance(item["keywords"], list) or not item["keywords"]:
                    errors.append(f"activation_triggers.keywords must be non-empty: {item!r}")

    return errors


def validate_metadata_file(meta_path: Path, dir_name: str, schema: dict) -> list[str]:
    errors: list[str] = []
    if not meta_path.is_file():
        return [f"Missing metadata.json at {meta_path}"]

    data = json.loads(meta_path.read_text(encoding="utf-8"))
    allowed = set(schema["properties"].keys())
    required = set(schema["required"])

    unknown = set(data.keys()) - allowed
    if unknown:
        errors.append(f"Unknown metadata key(s): {sorted(unknown)}")
    missing = required - set(data.keys())
    if missing:
        errors.append(f"Missing metadata key(s): {sorted(missing)}")

    if data.get("name") != dir_name:
        errors.append(f"metadata.name {data.get('name')!r} != directory {dir_name!r}")

    valid_categories = set(schema["properties"]["category"]["enum"])
    if data.get("category") not in valid_categories:
        errors.append(f"Invalid metadata.category: {data.get('category')!r}")

    valid_statuses = {"verified", "experimental", "unsupported"}
    compat = data.get("compatibility", {})
    if not isinstance(compat, dict):
        errors.append("metadata.compatibility must be an object")
    else:
        for agent, status in compat.items():
            if status not in valid_statuses:
                errors.append(f"Invalid compatibility status for {agent}: {status!r}")

    for field in ("references", "templates"):
        for rel in data.get(field, []):
            resolved = (meta_path.parent / rel).resolve()
            if not resolved.exists():
                errors.append(f"Broken path in metadata.{field}: {rel}")

    return errors


def validate_links(md_path: Path) -> list[str]:
    errors: list[str] = []
    text = md_path.read_text(encoding="utf-8")
    for match in LINK_RE.finditer(text):
        target = match.group(1).strip()
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        resolved = (md_path.parent / target).resolve()
        if not resolved.exists():
            errors.append(f"Broken relative link in {md_path.relative_to(ROOT)}: {target}")
    return errors


def validate_references(appsec_dir: Path) -> list[str]:
    errors: list[str] = []
    refs_dir = appsec_dir / "references"
    ref_files = sorted(refs_dir.glob("*.md"))
    if len(ref_files) < 19:
        errors.append(f"Expected at least 19 reference files, found {len(ref_files)}")
    for ref in ref_files:
        text = ref.read_text(encoding="utf-8")
        for heading in REQUIRED_REFERENCE_SECTIONS:
            if heading not in text:
                errors.append(f"{ref.relative_to(ROOT)} missing required section: {heading}")
    return errors


def main() -> int:
    skill_schema = json.loads((SCHEMAS_DIR / "skill.schema.json").read_text(encoding="utf-8"))
    meta_schema = json.loads((SCHEMAS_DIR / "metadata.schema.json").read_text(encoding="utf-8"))

    all_errors: list[str] = []
    skill_dirs = sorted([d for d in SKILLS_DIR.iterdir() if d.is_dir()])
    if not skill_dirs:
        print("ERROR: No skill directories found under skills/", file=sys.stderr)
        return 1

    for sdir in skill_dirs:
        skill_md = sdir / "SKILL.md"
        if not skill_md.is_file():
            all_errors.append(f"Missing SKILL.md in {sdir.relative_to(ROOT)}")
            continue

        raw = skill_md.read_text(encoding="utf-8")
        line_count = len(raw.splitlines())
        if line_count > MAX_SKILL_LINES:
            all_errors.append(
                f"{skill_md.relative_to(ROOT)} exceeds {MAX_SKILL_LINES} lines ({line_count})"
            )

        try:
            fm, _ = parse_simple_yaml_frontmatter(raw)
            all_errors.extend(
                f"[{sdir.name}] {err}" for err in validate_skill_schema(fm, sdir.name, skill_schema)
            )
        except ValueError as exc:
            all_errors.append(f"[{sdir.name}] Frontmatter error: {exc}")

        all_errors.extend(validate_links(skill_md))
        all_errors.extend(
            f"[{sdir.name}] {err}"
            for err in validate_metadata_file(sdir / "metadata.json", sdir.name, meta_schema)
        )

    appsec_dir = SKILLS_DIR / "appsec"
    if appsec_dir.is_dir():
        all_errors.extend(validate_references(appsec_dir))

    if all_errors:
        print("Skill validation FAILED:", file=sys.stderr)
        for err in all_errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(f"OK: Validated {len(skill_dirs)} skills, metadata files, links, and references.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

