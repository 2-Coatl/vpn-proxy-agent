#!/usr/bin/env python3
"""Quality checks for shell scripts."""

from pathlib import Path
import unittest
import re

PROJECT_ROOT = Path(__file__).resolve().parent.parent


class TestShellScriptQuality(unittest.TestCase):
    """Ensure shell scripts do not hide failures."""

    def test_scripts_do_not_mask_failures(self) -> None:
        """Selected scripts should not contain patterns that hide errors."""
        scripts_with_forbidden_patterns = {
            "scripts/backup_daily.sh": [r"\|\|\s*true", r"tar .*2>/dev/null", r"docker export .*2>/dev/null"],
            "scripts/backup_system.sh": [r"tar .*2>/dev/null"],
            "scripts/master_setup.sh": [r"tar .*2>/dev/null"],
            "scripts/restart_services.sh": [r"\|\|\s*true"],
            "scripts/safe_update.sh": [r"\|\|\s*true", r"tar .*2>/dev/null"],
        }

        for relative_path, patterns in scripts_with_forbidden_patterns.items():
            script_path = PROJECT_ROOT / relative_path
            self.assertTrue(script_path.exists(), f"Script {relative_path} must exist for quality checks")
            content = script_path.read_text(encoding="utf-8")
            for pattern in patterns:
                self.assertIsNone(
                    re.search(pattern, content),
                    msg=f"Forbidden pattern '{pattern}' found in {relative_path}"
                )


if __name__ == "__main__":
    unittest.main()
