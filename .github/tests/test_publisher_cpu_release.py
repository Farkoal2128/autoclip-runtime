"""Successor packaging checks; native fixture bytes are synthetic, not approval."""
import copy
import importlib.util
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from test_installer_manifest import InstallerManifestTests, cpu_native_fixture, digest, encoded, nested_zip

ROOT = Path(__file__).resolve().parents[2]


class PublisherCpuReleaseTests(unittest.TestCase):
    def setUp(self):
        self.fixture = InstallerManifestTests()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.directory = self.fixture.root
        spec = importlib.util.spec_from_file_location('cpu_producer', ROOT / 'scripts/build-publisher-cpu-release.py')
        self.producer = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.producer)
        canonical = json.loads((ROOT / 'release/manifests/installer-dependencies-v1.json').read_bytes())
        wheel = self.fixture.wheel
        wheels = [dict(wheel, filename=f'example{i}-1-py3-none-any.whl') for i in range(75)]
        self.files = {'app/AutoClip.bin': b'original first-party bytes',
                      'build-native-from-source.ps1': ''.join(
                          "Get-VerifiedSource '{filename}' '{url}' {bytes} '{sha256}'\n".format(**r)
                          for r in canonical['native_build_assets']).encode(),
                      'publisher-wheel-manifest.json': encoded({'schema_version': 1, 'wheels': wheels})}
        self.release = {'schema_version': 3, 'native_build': {'python': '3.11'},
                        'publisher_wheels': wheels, 'external_assets': canonical['external_assets']}
        self.files['distribution-inventory.json'] = encoded({
            'schema_version': 1, 'autoclip_wheels': [], 'publisher_wheel_count': 75,
            'publisher_wheels': [r['filename'] for r in wheels],
            'publisher_wheel_identities': wheels, 'native_build': self.release['native_build'],
            'external_assets': [dict(r, profiles=['nvidia'] if r['profile'] == 'nvidia' else ['cpu', 'nvidia'],
                                     cpu_default=r['profile'] != 'nvidia', optional_nvidia=r['profile'] == 'nvidia')
                                for r in canonical['external_assets']]})
        self.write_base()
        outer = self.fixture._outer_manifest()
        outer['external_assets'] = canonical['external_assets']
        outer['publisher_wheels']['count'] = 75
        outer['native_build_assets'] = canonical['native_build_assets']
        outer['build_prerequisites'] = canonical['build_prerequisites']
        self.fixture.manifest_path.write_bytes(encoded(outer))
        descriptor, native = cpu_native_fixture(self.directory)
        self.native = native
        self.report = self.directory / 'report.md'
        self.report.write_bytes(b'Original exact component review; synthetic fixture scope.')
        self.disposition = self.directory / 'disposition.json'
        self.review = {'schema_version': 1, 'disposition': 'QUALIFIED_COMPONENT_DISTRIBUTION',
                       'scope': 'synthetic fixture', 'artifact': {
                           'path': str(native), **{k: descriptor[k] for k in ('runtime_id', 'bytes', 'sha256')}}}
        self.disposition.write_bytes(encoded(self.review))
        self.arguments = dict(base=self.fixture.archive, base_sha256=digest(self.fixture.archive.read_bytes()),
                              outer=self.fixture.manifest_path, native=native,
                              disposition=self.disposition, disposition_sha256=digest(self.disposition.read_bytes()),
                              report=self.report, report_sha256=digest(self.report.read_bytes()),
                              bootstrap=ROOT / 'install.ps1', release_id='cpu-successor-test',
                              release_url='https://github.com/example/runtime/releases/download/test/successor.zip',
                              native_url='https://github.com/example/runtime/releases/download/test/' + native.name,
                              output=self.directory / 'successor.zip', manifest_output=self.directory / 'outer-new.json',
                              bootstrap_output=self.directory / 'bootstrap-new.ps1')

    def write_base(self):
        release = copy.deepcopy(self.release)
        release['files'] = [{'path': p, 'bytes': len(raw), 'sha256': digest(raw)} for p, raw in sorted(self.files.items())]
        self.fixture.archive.write_bytes(nested_zip(dict(self.files, **{'release-manifest.json': encoded(release)})))

    def test_successor_preserves_inputs_and_passes_cpu_gate(self):
        before = {p: p.read_bytes() for p in (self.fixture.archive, self.fixture.manifest_path, self.native, self.disposition, self.report)}
        result = self.producer.build(**self.arguments)
        self.assertEqual(result['publication_state'], 'UNPUBLISHABLE_REVIEW_PENDING')
        for p, raw in before.items():
            self.assertEqual(p.read_bytes(), raw)
        with self.producer.zipfile.ZipFile(self.arguments['output']) as z:
            for p, raw in self.files.items():
                if p != 'distribution-inventory.json':
                    self.assertEqual(z.read(p), raw)
            self.assertNotIn(self.native.name, z.namelist())
            prefix = 'notices-and-source/publisher-cpu/'
            self.assertEqual(z.read(prefix + 'original-component-disposition.json'), before[self.disposition])
            self.assertEqual(z.read(prefix + 'original-component-report.md'), before[self.report])
            receipt = json.loads(z.read(prefix + 'consuming-component-receipt.json'))
            self.assertEqual(receipt['decision'], 'QUALIFIED_COMPONENT_DISTRIBUTION')
            self.assertEqual(receipt['artifact']['sha256'], digest(before[self.native]))
            self.assertIn(b'publisher-wheels/cpu/native-artifact/sources', z.read(prefix + 'README.md'))
            updater = prefix + 'producer-inputs/update.ps1'
            self.assertEqual(z.read(updater), (ROOT / 'update.ps1').read_bytes())
            controls = json.loads(z.read(prefix + 'provenance.json'))['producer_inputs']
            row = next(r for r in controls if r['path'] == updater)
            self.assertEqual(row['sha256'], digest(z.read(updater)))
        self.producer.verifier()['check'](self.arguments['manifest_output'], self.arguments['output'], 'cpu', True, self.native)
        with self.assertRaisesRegex(ValueError, 'blocked'):
            self.producer.verifier()['check'](self.arguments['manifest_output'], self.arguments['output'], 'nvidia', True, self.native)
        with self.assertRaises(ValueError):
            self.producer.build(**self.arguments)

    def test_changed_indexed_member_rejected_before_output(self):
        self.fixture.archive.write_bytes(nested_zip(dict(self.files, **{'release-manifest.json': encoded({**self.release, 'files': []})})))
        self.arguments['base_sha256'] = digest(self.fixture.archive.read_bytes())
        with self.assertRaises(ValueError):
            self.producer.build(**self.arguments)
        self.assertFalse(self.arguments['output'].exists())

    def test_wrong_original_disposition_and_substitution_rejected(self):
        for change in ('decision', 'artifact', 'report'):
            with self.subTest(change=change):
                review = copy.deepcopy(self.review)
                if change == 'decision': review['disposition'] = 'BLOCKED_NOTICE_CLOSURE'
                if change == 'artifact': review['artifact']['sha256'] = '0' * 64
                self.disposition.write_bytes(encoded(review))
                self.arguments['disposition_sha256'] = digest(self.disposition.read_bytes())
                if change == 'report': self.report.write_bytes(b'substituted')
                with self.assertRaises(ValueError): self.producer.build(**self.arguments)
                self.assertFalse(self.arguments['output'].exists())

    def test_input_pin_and_output_alias_rejected(self):
        for extra in ({'outer_sha256': '0' * 64},
                      {'bootstrap_sha256': '0' * 64},
                      {'manifest_output': self.arguments['output']},
                      {'output': self.fixture.archive}):
            with self.subTest(extra=extra):
                with self.assertRaises(ValueError):
                    self.producer.build(**dict(self.arguments, **extra))
                self.assertFalse(self.arguments['output'].exists())

    def test_changed_source_native_wheel_rejected(self):
        raw = bytearray(self.native.read_bytes())
        raw[0] ^= 1
        self.native.write_bytes(raw)
        with self.assertRaises((ValueError, self.producer.zipfile.BadZipFile)):
            self.producer.build(**self.arguments)
        self.assertFalse(self.arguments['output'].exists())


if __name__ == '__main__':
    unittest.main()
