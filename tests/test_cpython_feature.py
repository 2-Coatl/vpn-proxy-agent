#!/usr/bin/env python3
"""
Test CPython Feature Integration
Tests for DevContainer feature and installation
"""

import unittest
import json
import subprocess
from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


class TestDevContainerFeature(unittest.TestCase):
    """Test DevContainer feature configuration"""
    
    def test_devcontainer_feature_json_exists(self):
        """Test devcontainer_feature.json exists"""
        feature_file = PROJECT_ROOT / 'installer' / 'devcontainer_feature.json'
        self.assertTrue(feature_file.exists(), "devcontainer_feature.json should exist")
    
    def test_devcontainer_feature_valid_json(self):
        """Test devcontainer_feature.json is valid JSON"""
        feature_file = PROJECT_ROOT / 'installer' / 'devcontainer_feature.json'
        with open(feature_file) as f:
            try:
                data = json.load(f)
                self.assertIsInstance(data, dict)
            except json.JSONDecodeError as e:
                self.fail(f"Invalid JSON: {e}")
    
    def test_devcontainer_feature_has_required_fields(self):
        """Test feature has required fields"""
        feature_file = PROJECT_ROOT / 'installer' / 'devcontainer_feature.json'
        with open(feature_file) as f:
            data = json.load(f)
        
        required_fields = ['id', 'version', 'name', 'description']
        for field in required_fields:
            self.assertIn(field, data, f"Feature should have '{field}' field")
    
    def test_devcontainer_feature_has_options(self):
        """Test feature has configuration options"""
        feature_file = PROJECT_ROOT / 'installer' / 'devcontainer_feature.json'
        with open(feature_file) as f:
            data = json.load(f)
        
        self.assertIn('options', data, "Feature should have options")
        options = data['options']
        
        # Check for key options
        expected_options = ['version', 'installDocker', 'setupSSH']
        for option in expected_options:
            self.assertIn(option, options, f"Should have '{option}' option")


class TestFeatureInstallScript(unittest.TestCase):
    """Test feature installation script"""
    
    def test_feature_install_exists(self):
        """Test feature_install.sh exists"""
        script = PROJECT_ROOT / 'scripts' / 'feature_install.sh'
        self.assertTrue(script.exists(), "feature_install.sh should exist")
    
    def test_feature_install_executable(self):
        """Test feature_install.sh is executable"""
        script = PROJECT_ROOT / 'scripts' / 'feature_install.sh'
        import os
        self.assertTrue(os.access(script, os.X_OK), "Should be executable")
    
    def test_feature_install_syntax(self):
        """Test feature_install.sh has valid syntax"""
        script = PROJECT_ROOT / 'scripts' / 'feature_install.sh'
        result = subprocess.run(['bash', '-n', str(script)], capture_output=True)
        self.assertEqual(result.returncode, 0, f"Syntax error: {result.stderr.decode()}")
    
    def test_feature_install_uses_utilities(self):
        """Test installation script uses utility functions"""
        script = PROJECT_ROOT / 'scripts' / 'feature_install.sh'
        content = script.read_text()
        
        self.assertIn('source', content, "Should source utilities")
        self.assertIn('log_', content, "Should use logging")


class TestFeatureOptions(unittest.TestCase):
    """Test feature option handling"""
    
    def test_docker_option_type(self):
        """Test installDocker option is boolean"""
        feature_file = PROJECT_ROOT / 'installer' / 'devcontainer_feature.json'
        with open(feature_file) as f:
            data = json.load(f)
        
        docker_option = data['options']['installDocker']
        self.assertEqual(docker_option['type'], 'boolean')
        self.assertIn('default', docker_option)
    
    def test_wireguard_option_exists(self):
        """Test installWireguard option exists"""
        feature_file = PROJECT_ROOT / 'installer' / 'devcontainer_feature.json'
        with open(feature_file) as f:
            data = json.load(f)
        
        self.assertIn('installWireguard', data['options'])
    
    def test_ssh_option_exists(self):
        """Test setupSSH option exists"""
        feature_file = PROJECT_ROOT / 'installer' / 'devcontainer_feature.json'
        with open(feature_file) as f:
            data = json.load(f)
        
        self.assertIn('setupSSH', data['options'])


class TestFeatureEnvironment(unittest.TestCase):
    """Test feature environment configuration"""
    
    def test_feature_sets_environment_vars(self):
        """Test feature defines environment variables"""
        feature_file = PROJECT_ROOT / 'installer' / 'devcontainer_feature.json'
        with open(feature_file) as f:
            data = json.load(f)
        
        self.assertIn('containerEnv', data, "Should define container environment")
        env = data['containerEnv']
        
        # Check for proxy variables
        self.assertIn('HTTP_PROXY', env, "Should set HTTP_PROXY")
        self.assertIn('HTTPS_PROXY', env, "Should set HTTPS_PROXY")


class TestFeatureIntegration(unittest.TestCase):
    """Test feature integration with project"""
    
    def test_feature_install_calls_setup_scripts(self):
        """Test installation calls appropriate setup scripts"""
        script = PROJECT_ROOT / 'scripts' / 'feature_install.sh'
        content = script.read_text()
        
        # Should call various setup scripts
        setup_scripts = ['setup_docker.sh', 'setup_ssh.sh', 'setup_wireguard.sh']
        for setup_script in setup_scripts:
            self.assertIn(setup_script, content, 
                         f"Should reference {setup_script}")
    
    def test_all_referenced_scripts_exist(self):
        """Test all scripts referenced in feature exist"""
        scripts_dir = PROJECT_ROOT / 'scripts'
        required_scripts = [
            'setup_docker.sh',
            'setup_ssh.sh', 
            'setup_wireguard.sh',
            'feature_install.sh'
        ]
        
        for script_name in required_scripts:
            script_path = scripts_dir / script_name
            self.assertTrue(script_path.exists(), 
                          f"{script_name} should exist")


class TestFeatureDocumentation(unittest.TestCase):
    """Test feature documentation"""
    
    def test_installer_readme_exists(self):
        """Test installer README exists"""
        readme = PROJECT_ROOT / 'installer' / 'README.md'
        self.assertTrue(readme.exists(), "installer/README.md should exist")
    
    def test_installer_readme_has_content(self):
        """Test README has sufficient content"""
        readme = PROJECT_ROOT / 'installer' / 'README.md'
        content = readme.read_text()
        self.assertGreater(len(content), 500, "README should have substantial content")
    
    def test_readme_mentions_devcontainer(self):
        """Test README mentions DevContainer feature"""
        readme = PROJECT_ROOT / 'installer' / 'README.md'
        content = readme.read_text()
        self.assertIn('devcontainer', content.lower(), 
                     "README should mention DevContainer")


if __name__ == '__main__':
    unittest.main(verbosity=2)
