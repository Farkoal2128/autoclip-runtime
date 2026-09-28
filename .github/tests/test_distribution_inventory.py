import copy
import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('inventory_recipe', ROOT/'scripts/build-source-routed-release.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class DistributionInventoryTest(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads((Path(__file__).parent/'fixtures/v31-selected-inputs.json').read_bytes())
        self.apps = ['autoclip-0.1.0.dev0-py3-none-any.whl']

    def test_final_asset_and_publisher_identities_and_profiles(self):
        inventory = module.distribution_inventory(self.manifest, self.apps)
        fields = ('filename', 'kind', 'bytes', 'sha256')
        self.assertEqual([{k:r[k] for k in fields} for r in inventory['external_assets']],
                         [{k:r[k] for k in fields} for r in self.manifest['external_assets']])
        self.assertEqual(inventory['publisher_wheel_count'], 74)
        self.assertEqual(inventory['publisher_wheel_identities'], self.manifest['publisher_wheels'])
        self.assertEqual(inventory['publisher_wheels'], [r['filename'] for r in self.manifest['publisher_wheels']])
        self.assertFalse(any('cudnn' in r['filename'] for r in inventory['external_assets']))
        for row in inventory['external_assets']:
            gpu = row['filename'].startswith('nvidia_cublas_')
            self.assertEqual(row['profiles'], ['nvidia'] if gpu else ['cpu', 'nvidia'])
            self.assertEqual(row['cpu_default'], not gpu)
            self.assertEqual(row['optional_nvidia'], gpu)
        module.validate_distribution_inventory(inventory, self.manifest, self.apps)

    def test_final_reconciliation_rejects_extra_asset_or_identity_scope_drift(self):
        inventory = module.distribution_inventory(self.manifest, self.apps)
        extra = copy.deepcopy(inventory)
        extra['external_assets'].append(dict(filename='nvidia_cudnn_unselected.whl'))
        with self.assertRaisesRegex(ValueError, 'final selected manifest'):
            module.validate_distribution_inventory(extra, self.manifest, self.apps)
        for field in ('filename', 'kind', 'bytes', 'sha256', 'cpu_default', 'optional_nvidia', 'profiles'):
            with self.subTest(field=field):
                changed = copy.deepcopy(inventory)
                changed['external_assets'][0][field] = 'incorrect'
                with self.assertRaises(ValueError):
                    module.validate_distribution_inventory(changed, self.manifest, self.apps)
        changed = copy.deepcopy(inventory)
        changed['publisher_wheel_identities'][0]['sha256'] = '0'*64
        with self.assertRaises(ValueError):
            module.validate_distribution_inventory(changed, self.manifest, self.apps)

    def test_unselected_cudnn_or_wrong_publisher_count_cannot_be_generated(self):
        bad = copy.deepcopy(self.manifest)
        bad['external_assets'].append(dict(kind='python_wheel', filename='nvidia_cudnn_unselected.whl'))
        with self.assertRaises(ValueError):
            module.distribution_inventory(bad, self.apps)
        bad = copy.deepcopy(self.manifest)
        bad['publisher_wheels'].pop()
        with self.assertRaises(ValueError):
            module.distribution_inventory(bad, self.apps)
