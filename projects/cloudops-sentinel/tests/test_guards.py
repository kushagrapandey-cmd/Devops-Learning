"""Guard tests run real shell scripts with a fake kubectl; no cloud access."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class GuardTests(unittest.TestCase):
    def test_provision_requires_explicit_opt_in(self):
        result = subprocess.run(['bash', 'azure/provision.sh'], cwd=ROOT, capture_output=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn(b'--create-billable-resources', result.stderr)

    def test_wrong_context_rejects_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            executable = Path(directory) / 'kubectl'
            executable.write_text('#!/bin/sh\nif [ "$*" = "config current-context" ]; then echo other-context; else exit 99; fi\n')
            executable.chmod(0o700)
            env = dict(os.environ, PATH=directory + os.pathsep + os.environ['PATH'],
                       EXPECTED_CONTEXT='expected-lab', IMAGE='sentinel:test')
            result = subprocess.run(['bash', 'scripts/deploy.sh'], cwd=ROOT, env=env, capture_output=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn(b'Context mismatch', result.stderr)
            result = subprocess.run(['bash', 'scripts/drills.sh'], cwd=ROOT, env=env, capture_output=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn(b'kind-sentinel only', result.stderr)

    def test_cleanup_requires_group_specific_flag(self):
        env = dict(os.environ, AZURE_SUBSCRIPTION_ID='test', RESOURCE_GROUP='test-lab')
        result = subprocess.run(['bash', 'azure/cleanup.sh', '--delete-other'], cwd=ROOT, env=env, capture_output=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn(b'--delete-test-lab', result.stderr)
