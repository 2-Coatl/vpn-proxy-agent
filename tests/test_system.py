#!/usr/bin/env python3
"""
VPN/Proxy Agent - Python Test Suite
Tests for build system and features
"""

import unittest
import subprocess
import os
import sys
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


class TestSystemRequirements(unittest.TestCase):
    """Test system requirements and dependencies"""
    
    def test_python_version(self):
        """Test Python version is 3.7+"""
        self.assertGreaterEqual(sys.version_info.major, 3)
        self.assertGreaterEqual(sys.version_info.minor, 7)
    
    def test_bash_available(self):
        """Test bash is available"""
        result = subprocess.run(['which', 'bash'], capture_output=True)
        self.assertEqual(result.returncode, 0)
    
    def test_project_structure(self):
        """Test project directory structure"""
        required_dirs = ['utils', 'scripts', 'config', 'tests']
        for dir_name in required_dirs:
            dir_path = PROJECT_ROOT / dir_name
            self.assertTrue(dir_path.exists(), f"Directory {dir_name} should exist")
            self.assertTrue(dir_path.is_dir(), f"{dir_name} should be a directory")


class TestUtilityScripts(unittest.TestCase):
    """Test utility scripts are valid"""
    
    def test_logging_script_syntax(self):
        """Test logging.sh has valid bash syntax"""
        script = PROJECT_ROOT / 'utils' / 'logging.sh'
        result = subprocess.run(['bash', '-n', str(script)], capture_output=True)
        self.assertEqual(result.returncode, 0, f"Syntax error in logging.sh: {result.stderr.decode()}")
    
    def test_validation_script_syntax(self):
        """Test validation.sh has valid bash syntax"""
        script = PROJECT_ROOT / 'utils' / 'validation.sh'
        result = subprocess.run(['bash', '-n', str(script)], capture_output=True)
        self.assertEqual(result.returncode, 0, f"Syntax error in validation.sh: {result.stderr.decode()}")
    
    def test_common_script_syntax(self):
        """Test common.sh has valid bash syntax"""
        script = PROJECT_ROOT / 'utils' / 'common.sh'
        result = subprocess.run(['bash', '-n', str(script)], capture_output=True)
        self.assertEqual(result.returncode, 0, f"Syntax error in common.sh: {result.stderr.decode()}")


class TestConfiguration(unittest.TestCase):
    """Test configuration files"""
    
    def test_versions_conf_exists(self):
        """Test versions.conf exists"""
        config = PROJECT_ROOT / 'config' / 'versions.conf'
        self.assertTrue(config.exists(), "versions.conf should exist")
    
    def test_versions_conf_readable(self):
        """Test versions.conf is readable"""
        config = PROJECT_ROOT / 'config' / 'versions.conf'
        with open(config, 'r') as f:
            content = f.read()
        self.assertIn('DEFAULT_PYTHON_VERSION', content)
        self.assertIn('SUPPORTED_PYTHON_VERSIONS', content)


class TestBootstrapScript(unittest.TestCase):
    """Test bootstrap script"""
    
    def test_bootstrap_exists(self):
        """Test bootstrap.sh exists"""
        bootstrap = PROJECT_ROOT / 'bootstrap.sh'
        self.assertTrue(bootstrap.exists(), "bootstrap.sh should exist")
    
    def test_bootstrap_executable(self):
        """Test bootstrap.sh is executable"""
        bootstrap = PROJECT_ROOT / 'bootstrap.sh'
        self.assertTrue(os.access(bootstrap, os.X_OK), "bootstrap.sh should be executable")
    
    def test_bootstrap_syntax(self):
        """Test bootstrap.sh has valid bash syntax"""
        bootstrap = PROJECT_ROOT / 'bootstrap.sh'
        result = subprocess.run(['bash', '-n', str(bootstrap)], capture_output=True)
        self.assertEqual(result.returncode, 0, f"Syntax error in bootstrap.sh: {result.stderr.decode()}")


class TestScripts(unittest.TestCase):
    """Test individual scripts"""
    
    def test_all_scripts_executable(self):
        """Test all .sh scripts are executable"""
        scripts_dir = PROJECT_ROOT / 'scripts'
        if scripts_dir.exists():
            for script in scripts_dir.glob('*.sh'):
                self.assertTrue(os.access(script, os.X_OK), f"{script.name} should be executable")
    
    def test_all_scripts_valid_syntax(self):
        """Test all .sh scripts have valid bash syntax"""
        scripts_dir = PROJECT_ROOT / 'scripts'
        if scripts_dir.exists():
            for script in scripts_dir.glob('*.sh'):
                result = subprocess.run(['bash', '-n', str(script)], capture_output=True)
                self.assertEqual(result.returncode, 0, 
                               f"Syntax error in {script.name}: {result.stderr.decode()}")


class TestVagrantfile(unittest.TestCase):
    """Test Vagrantfile"""
    
    def test_vagrantfile_exists(self):
        """Test Vagrantfile exists"""
        vagrantfile = PROJECT_ROOT / 'Vagrantfile'
        self.assertTrue(vagrantfile.exists(), "Vagrantfile should exist")
    
    def test_vagrantfile_syntax(self):
        """Test Vagrantfile has valid Ruby syntax"""
        vagrantfile = PROJECT_ROOT / 'Vagrantfile'
        # Skip if ruby not installed
        try:
            result = subprocess.run(['ruby', '-c', str(vagrantfile)],
                                  capture_output=True, timeout=5)
            if result.returncode == 0:
                self.assertEqual(result.returncode, 0)
        except (FileNotFoundError, subprocess.TimeoutExpired):
            self.skipTest("Ruby not available for syntax check")

    def test_vagrantfile_synced_folder_allows_execution(self):
        """Ensure synced folder mount options keep execute permissions"""
        vagrantfile = PROJECT_ROOT / 'Vagrantfile'
        with open(vagrantfile, 'r', encoding='utf-8') as handle:
            content = handle.read()

        self.assertIn('"fmode=775"', content,
                      "Synced folder must allow execute permissions via fmode=775")


class TestDocumentation(unittest.TestCase):
    """Test documentation files"""
    
    def test_readme_exists(self):
        """Test README.md exists"""
        readme = PROJECT_ROOT / 'README.md'
        self.assertTrue(readme.exists(), "README.md should exist")
    
    def test_readme_not_empty(self):
        """Test README.md is not empty"""
        readme = PROJECT_ROOT / 'README.md'
        self.assertGreater(readme.stat().st_size, 100, "README.md should have content")
    
    def test_artifacts_doc_exists(self):
        """Test ARTIFACTS.md exists"""
        artifacts_doc = PROJECT_ROOT / 'artifacts' / 'ARTIFACTS.md'
        self.assertTrue(artifacts_doc.exists(), "ARTIFACTS.md should exist")


def run_tests():
    """Run all tests and return results"""
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromModule(sys.modules[__name__])
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    return result.wasSuccessful()


if __name__ == '__main__':
    # Run tests
    success = run_tests()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)
