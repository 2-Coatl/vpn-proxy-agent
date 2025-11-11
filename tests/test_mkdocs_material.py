#!/usr/bin/env python3
"""Tests for the Material for MkDocs configuration."""

import json
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


class TestMkDocsMaterialConfiguration(unittest.TestCase):
    """Validate that the MkDocs configuration enables Material features."""

    @classmethod
    def setUpClass(cls):
        cls.mkdocs_config_path = PROJECT_ROOT / "docs" / "mkdocs.yml"
        cls.mkdocs_text = cls.mkdocs_config_path.read_text(encoding="utf-8")

    def test_material_theme_selected(self):
        self.assertIn("theme:", self.mkdocs_text)
        self.assertIn("name: material", self.mkdocs_text)

    def test_color_palette_toggle_defined(self):
        self.assertIn("palette:", self.mkdocs_text)
        self.assertIn("scheme: default", self.mkdocs_text)
        self.assertIn("scheme: slate", self.mkdocs_text)
        self.assertIn("toggle:", self.mkdocs_text)
        self.assertIn("material/weather-night", self.mkdocs_text)
        self.assertIn("material/weather-sunny", self.mkdocs_text)

    def test_custom_fonts_configured(self):
        self.assertIn("font:", self.mkdocs_text)
        self.assertIn("Merriweather Sans", self.mkdocs_text)
        self.assertIn("Red Hat Mono", self.mkdocs_text)

    def test_markdown_extensions_enabled(self):
        for extension in [
            "attr_list",
            "md_in_html",
            "pymdownx.emoji",
            "pymdownx.superfences",
            "pymdownx.highlight",
            "pymdownx.inlinehilite",
            "pymdownx.snippets",
            "pymdownx.tabbed",
            "admonition",
            "pymdownx.details",
            "pymdownx.plantuml",
        ]:
            with self.subTest(extension=extension):
                self.assertIn(f"- {extension}", self.mkdocs_text)

    def test_plantuml_configured(self):
        self.assertIn("custom_fences:", self.mkdocs_text)
        self.assertIn("name: plantuml", self.mkdocs_text)
        self.assertIn("class: plantuml", self.mkdocs_text)
        self.assertIn("pymdownx.plantuml", self.mkdocs_text)
        self.assertIn("server:", self.mkdocs_text)

    def test_theme_uses_builtin_logo_icon(self):
        self.assertIn("icon:", self.mkdocs_text)
        self.assertIn("logo: material/shield-check", self.mkdocs_text)
        self.assertNotIn("logo: assets/", self.mkdocs_text)
        self.assertNotIn("favicon:", self.mkdocs_text)

    def test_footer_and_social_links_configured(self):
        self.assertIn("navigation.footer", self.mkdocs_text)
        self.assertIn("extra:", self.mkdocs_text)
        self.assertIn("fontawesome/brands/youtube", self.mkdocs_text)
        self.assertIn("fontawesome/brands/linkedin", self.mkdocs_text)


class TestMkDocsSupportingFiles(unittest.TestCase):
    """Validate supporting assets for the Material configuration."""

    def test_no_custom_binary_assets_present(self):
        assets_dir = PROJECT_ROOT / "docs" / "assets"
        if not assets_dir.exists():
            return

        disallowed_suffixes = {".png", ".ico", ".svg", ".jpg", ".jpeg", ".gif"}
        offending_files = [
            path
            for path in assets_dir.rglob("*")
            if path.is_file() and path.suffix.lower() in disallowed_suffixes
        ]

        self.assertListEqual(
            [],
            offending_files,
            "Binary image assets should be removed from docs/assets",
        )

    def test_vscode_yaml_schema_configured(self):
        settings_path = PROJECT_ROOT / ".vscode" / "settings.json"
        self.assertTrue(settings_path.is_file(), ".vscode/settings.json should exist")

        content = json.loads(settings_path.read_text(encoding="utf-8"))
        schemas = content.get("yaml.schemas", {})
        schema_url = "https://squidfunk.github.io/mkdocs-material/schema.json"
        self.assertIn(schema_url, schemas)
        self.assertIn("docs/mkdocs.yml", schemas[schema_url])

    def test_docs_build_script_present_instead_of_github_actions(self):
        workflow_path = PROJECT_ROOT / ".github" / "workflows" / "ci.yml"
        self.assertFalse(
            workflow_path.exists(),
            "GitHub Actions workflow should be removed for MkDocs automation",
        )

        build_script = PROJECT_ROOT / "scripts" / "build_docs.sh"
        self.assertTrue(build_script.is_file(), "scripts/build_docs.sh should exist")
        self.assertTrue(
            build_script.stat().st_mode & 0o111,
            "scripts/build_docs.sh must be executable",
        )

        build_text = build_script.read_text(encoding="utf-8")
        for snippet in [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "mkdocs build --config-file docs/mkdocs.yml",
        ]:
            with self.subTest(snippet=snippet):
                self.assertIn(snippet, build_text)

        serve_script = PROJECT_ROOT / "scripts" / "serve_docs.sh"
        self.assertTrue(serve_script.is_file(), "scripts/serve_docs.sh should exist")
        self.assertTrue(
            serve_script.stat().st_mode & 0o111,
            "scripts/serve_docs.sh must be executable",
        )

        serve_text = serve_script.read_text(encoding="utf-8")
        for snippet in [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "mkdocs serve --config-file docs/mkdocs.yml",
        ]:
            with self.subTest(snippet=snippet):
                self.assertIn(snippet, serve_text)


if __name__ == "__main__":
    unittest.main()
