"""Offline unit tests for Suraksha Agent Skills (Python stdlib only)."""

from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import validate_skill  # noqa: E402


def route_references_for_prompt(prompt: str, principles_text: str) -> set[str]:
    """Deterministically parse routing rules in security-principles.md and match a prompt."""
    prompt_lower = prompt.lower()
    selected: set[str] = set()
    rule_line_re = re.compile(r"^- (.+?) -> (.+)$")
    kw_re = re.compile(r"`([^`]+)`")

    for line in principles_text.splitlines():
        match = rule_line_re.match(line.strip())
        if not match:
            continue
        keywords = [k.lower() for k in kw_re.findall(match.group(1))]
        refs = [r.strip("` ") for r in kw_re.findall(match.group(2))]
        if any(re.search(rf"\b{re.escape(kw)}\b", prompt_lower) for kw in keywords):
            selected.update(refs)
    return selected


class SkillValidationTests(unittest.TestCase):
    def test_validate_skill_script_succeeds(self) -> None:
        self.assertEqual(validate_skill.main(), 0)

    def test_rejects_unknown_frontmatter_key(self) -> None:
        schema = json.loads((ROOT / "schemas" / "skill.schema.json").read_text(encoding="utf-8"))
        fm = {
            "name": "appsec",
            "description": "Valid description with sufficient length for schema.",
            "license": "Apache-2.0",
            "version": "0.1.0",
            "min_engine_version": "0.1.0",
            "unexpected_key": "bad",
        }
        errors = validate_skill.validate_skill_schema(fm, "appsec", schema)
        self.assertTrue(any("Unknown frontmatter key" in e for e in errors))

    def test_all_four_skills_present_and_concise(self) -> None:
        expected = {"appsec", "secure-review", "secure-implementation", "vulnerability-remediation"}
        found = {d.name for d in (ROOT / "skills").iterdir() if d.is_dir()}
        self.assertEqual(expected, found)
        for name in expected:
            lines = (ROOT / "skills" / name / "SKILL.md").read_text(encoding="utf-8").splitlines()
            self.assertLessEqual(len(lines), 250, f"{name}/SKILL.md exceeded 250 lines")

    def test_golden_prompt_reference_routing(self) -> None:
        principles_path = ROOT / "skills" / "appsec" / "references" / "security-principles.md"
        principles_text = principles_path.read_text(encoding="utf-8")

        golden_cases = [
            (
                "Build a secure login endpoint with JWT sessions and Postgres SQL user lookup",
                {"authentication.md", "sql-security.md", "database-security.md"},
            ),
            (
                "Add role-based admin authorization and fix IDOR on tenant invoices",
                {"authorization.md"},
            ),
            (
                "Create an LLM tool-calling agent connected to a RAG vector store and MCP server",
                {"ai-agent-security.md", "rag-security.md", "mcp-security.md"},
            ),
            (
                "Harden our Dockerfile and Kubernetes deployment manifest for CI",
                {"container-security.md"},
            ),
            (
                "Store mobile auth tokens safely in React Native Expo without leaking secrets in logs",
                {"mobile-security.md", "logging-and-privacy.md"},
            ),
        ]

        for prompt, expected_refs in golden_cases:
            routed = route_references_for_prompt(prompt, principles_text)
            self.assertTrue(
                expected_refs.issubset(routed),
                f"Prompt {prompt!r} routed to {routed}, expected superset of {expected_refs}",
            )
            for ref in routed:
                self.assertTrue(
                    (ROOT / "skills" / "appsec" / "references" / ref).is_file(),
                    f"Routed reference missing: {ref}",
                )


if __name__ == "__main__":
    unittest.main()

