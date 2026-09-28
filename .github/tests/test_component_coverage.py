import hashlib
import importlib.util
import unittest
from pathlib import Path

spec=importlib.util.spec_from_file_location('coverage_recipe',Path(__file__).resolve().parents[2]/'scripts/build-source-routed-release.py')
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class NativeComponentCoverageTest(unittest.TestCase):
    def test_backend_with_only_root_license_is_rejected(self):
        artifact=dict(sha256='a'*64,components=[])
        required=[dict(artifact_sha256='a'*64,component='vendored-libffi')]
        with self.assertRaisesRegex(ValueError,'native component route'):
            module.validate_native_component_routes([artifact],required,lambda path:b'fixture grant')

    def test_compiler_route_cannot_claim_exception_without_build_evidence(self):
        raw=b'fixture grant'
        component=dict(name='gcc-runtime',license_paths=[dict(path='grant',sha256=hashlib.sha256(raw).hexdigest())],fulfillment_status='fulfilled',exception_eligibility='pending',build_evidence=[])
        artifact=dict(sha256='b'*64,components=[component])
        required=[dict(artifact_sha256='b'*64,component='gcc-runtime',requires_exception_eligibility=True)]
        with self.assertRaisesRegex(ValueError,'exception eligibility'):
            module.validate_native_component_routes([artifact],required,lambda path:raw)
        component['fulfillment_status']='pending_exact_publisher_build_evidence'
        module.validate_native_component_routes([artifact],required,lambda path:raw)
        with self.assertRaisesRegex(ValueError,'grant hash'):
            module.validate_native_component_routes([artifact],required,lambda path:b'changed')


if __name__=='__main__':unittest.main()
