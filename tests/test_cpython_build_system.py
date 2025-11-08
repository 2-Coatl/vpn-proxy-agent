#!/usr/bin/env python3
"""
Test CPython Build System
Tests for Python compilation and build scripts
"""

import unittest
import subprocess
import os
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


class TestCPythonBuildScripts(unittest.TestCase):
    """Test CPython build scripts"""
    
    def test_build_cpython_exists(self):
        """Test build_cpython.sh exists"""
        script = PROJECT_ROOT / 'scripts' / 'build_cpython.sh'
        self.assertTrue(script.exists(), "build_cpython.sh should exist")
    
    def test_build_cpython_executable(self):
        """Test build_cpython.sh is executable"""
        script = PROJECT_ROOT / 'scripts' / 'build_cpython.sh'
        self.assertTrue(os.access(script, os.X_OK), "build_cpython.sh should be executable")
    
    def test_build_cpython_syntax(self):
        """Test build_cpython.sh has valid syntax"""
        script = PROJECT_ROOT / 'scripts' / 'build_cpython.sh'
        result = subprocess.run(['bash', '-n', str(script)], capture_output=True)
        self.assertEqual(result.returncode, 0, f"Syntax error: {result.stderr.decode()}")
    
    def test_build_wrapper_exists(self):
        """Test build_wrapper.sh exists"""
        script = PROJECT_ROOT / 'scripts' / 'build_wrapper.sh'
        self.assertTrue(script.exists())
    
    def test_validate_build_exists(self):
        """Test validate_build.sh exists"""
        script = PROJECT_ROOT / 'scripts' / 'validate_build.sh'
        self.assertTrue(script.exists())
    
    def test_validate_wrapper_exists(self):
        """Test validate_wrapper.sh exists"""
        script = PROJECT_ROOT / 'scripts' / 'validate_wrapper.sh'
        self.assertTrue(script.exists())


class TestPythonVersionHandling(unittest.TestCase):
    """Test Python version format handling"""
    
    def test_python_version_format(self):
        """Test valid Python version formats"""
        valid_versions = ['3.11.9', '3.12.6', '3.13.0']
        for version in valid_versions:
            # Version format: X.Y.Z
            parts = version.split('.')
            self.assertEqual(len(parts), 3, f"Version {version} should have 3 parts")
            for part in parts:
                self.assertTrue(part.isdigit(), f"Version part {part} should be numeric")
    
    def test_invalid_version_formats(self):
        """Test detection of invalid version formats"""
        invalid_versions = ['3.12', '3.12.6.1', 'python3', '3.x.x']
        for version in invalid_versions:
            parts = version.split('.')
            # Should either not have 3 parts or have non-numeric parts
            invalid = (len(parts) != 3 or not all(p.replace('x', '').isdigit() or p == 'x' for p in parts))
            self.assertTrue(invalid, f"{version} should be detected as invalid")


class TestBuildDependencies(unittest.TestCase):
    """Test build dependencies are available"""
    
    def test_curl_available(self):
        """Test curl is available for downloads"""
        result = subprocess.run(['which', 'curl'], capture_output=True)
        self.assertEqual(result.returncode, 0, "curl should be available")
    
    def test_tar_available(self):
        """Test tar is available for extraction"""
        result = subprocess.run(['which', 'tar'], capture_output=True)
        self.assertEqual(result.returncode, 0, "tar should be available")
    
    def test_make_available(self):
        """Test make is available for building"""
        result = subprocess.run(['which', 'make'], capture_output=True)
        # May not be installed in all environments, so just log
        if result.returncode != 0:
            self.skipTest("make not installed (optional)")


class TestBuildConfiguration(unittest.TestCase):
    """Test build configuration options"""
    
    def test_build_cpython_has_configure_options(self):
        """Test build script includes configure options"""
        script = PROJECT_ROOT / 'scripts' / 'build_cpython.sh'
        content = script.read_text()
        
        # Check for important configure flags
        self.assertIn('--prefix', content, "Should specify install prefix")
        self.assertIn('--enable-optimizations', content, "Should enable optimizations")
        self.assertIn('make', content, "Should include make command")
    
    def test_build_uses_logging(self):
        """Test build script uses logging utilities"""
        script = PROJECT_ROOT / 'scripts' / 'build_cpython.sh'
        content = script.read_text()
        
        self.assertIn('source', content, "Should source utilities")
        self.assertIn('log_', content, "Should use logging functions")


class TestValidationScripts(unittest.TestCase):
    """Test validation scripts"""
    
    def test_validate_build_checks_binary(self):
        """Test validation checks for Python binary"""
        script = PROJECT_ROOT / 'scripts' / 'validate_build.sh'
        content = script.read_text()
        
        self.assertIn('PYTHON_BIN', content, "Should define Python binary path")
        self.assertIn('--version', content, "Should check version")
    
    def test_validate_build_tests_functionality(self):
        """Test validation tests basic functionality"""
        script = PROJECT_ROOT / 'scripts' / 'validate_build.sh'
        content = script.read_text()
        
        self.assertIn('python', content.lower(), "Should test Python")
        self.assertIn('print', content, "Should test basic print")


if __name__ == '__main__':
    unittest.main(verbosity=2)
