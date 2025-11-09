#!/usr/bin/env python3
"""Regression tests for the MCP server implementation plan document."""

from pathlib import Path
import unittest


PROJECT_ROOT = Path(__file__).resolve().parent.parent
PLAN_PATH = PROJECT_ROOT / "docs" / "mcp_server_plan.md"


class TestMcpServerPlanDocument(unittest.TestCase):
    """Ensure the MCP server task breakdown stays documented."""

    @classmethod
    def setUpClass(cls):
        cls.plan_path = PLAN_PATH
        cls.plan_text = (
            cls.plan_path.read_text(encoding="utf-8") if cls.plan_path.exists() else ""
        )
        cls.mkdocs_config = (PROJECT_ROOT / "docs" / "mkdocs.yml").read_text(
            encoding="utf-8"
        )

    def test_document_exists(self):
        self.assertTrue(
            self.plan_path.is_file(),
            "The MCP server plan document should exist under docs/",
        )

    def test_document_contains_required_sections(self):
        required_snippets = [
            "# Plan Maestro para el Servidor MCP sin Docker",
            "## Tareas Principales",
            "### 1. Definir parámetros y dependencias",
            "### 2. Implementar scripts de instalación y operación",
            "### 3. Integración con systemd",
            "### 4. Extender bootstrap",
            "### 5. Pruebas y calidad continua",
            "## Backlog Proactivo",
            "## Prompt Engineering de referencia",
        ]

        for snippet in required_snippets:
            with self.subTest(snippet=snippet):
                self.assertIn(
                    snippet,
                    self.plan_text,
                    f"The plan document must include the section '{snippet}'",
                )

    def test_document_includes_checkbox_tasks(self):
        self.assertIn(
            "- [ ]",
            self.plan_text,
            "The plan should enumerate tasks using Markdown checkboxes.",
        )

    def test_document_mentions_additional_concerns(self):
        for keyword in ["Observabilidad", "Seguridad", "Capacitación"]:
            with self.subTest(keyword=keyword):
                self.assertIn(
                    keyword,
                    self.plan_text,
                    "The plan should call out missing areas the agent identified.",
                )

    def test_mkdocs_navigation_references_document(self):
        self.assertIn(
            "mcp_server_plan.md",
            self.mkdocs_config,
            "MkDocs navigation must surface the MCP server plan document.",
        )


if __name__ == "__main__":
    unittest.main()
