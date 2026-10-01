"""An unpublished dependency/app successor must require completed exact evidence."""

import importlib.util
import pathlib
import tempfile
import tarfile
import io
import hashlib
import json
import re
import zipfile
import base64
import csv
import shutil
import subprocess

from test_dependency_app_successor import wheel as make_wheel


def add_pillow_requirement(path):
    with zipfile.ZipFile(path) as archive:
        files = {name: archive.read(name) for name in archive.namelist()}
    metadata = next(name for name in files if name.endswith(".dist-info/METADATA"))
    record = next(name for name in files if name.endswith(".dist-info/RECORD"))
    files[metadata] += b"Requires-Dist: pillow<13,>=12.3\n"
    rows = []
    for name, data in files.items():
        if name == record:
            rows.append((name, "", ""))
        else:
            digest = base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=").decode()
            rows.append((name, "sha256=" + digest, str(len(data))))
    text = io.StringIO(newline="")
    csv.writer(text, lineterminator="\n").writerows(rows)
    files[record] = text.getvalue().encode()
    with zipfile.ZipFile(path, "w") as archive:
        for name, data in files.items():
            archive.writestr(name, data)
import unittest


SCRIPT = pathlib.Path(__file__).resolve().parents[2] / "scripts/build-dependency-app-successor.py"
spec = importlib.util.spec_from_file_location("build_dependency_app_successor", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DependencyAppBuilderTest(unittest.TestCase):
    def test_pillow_child_inventory_matches_delivered_notices(self):
        delivered = module._pillow_notice_inputs()
        inventory = json.loads(module._pillow_child_inventory(delivered))
        sharpyuv = next(row for row in inventory["components"]
                         if row["name"] == "libsharpyuv")
        self.assertIn("libwebp-1.6.0-PATENTS",
                      {notice["path"] for notice in sharpyuv["notices"]})
        altered = dict(delivered)
        catalog = json.loads(altered["components.json"])
        catalog["components"][0]["notices"][0]["sha256"] = "0" * 64
        altered["components.json"] = module.encoded(catalog)
        with self.assertRaisesRegex(ValueError, "child component notice"):
            module._pillow_child_inventory(altered)
        catalog = json.loads(delivered["components.json"])
        sharpyuv = next(row for row in catalog["components"]
                         if row["name"] == "libsharpyuv")
        sharpyuv["notices"] = [notice for notice in sharpyuv["notices"]
                                if notice["path"] != "libwebp-1.6.0-PATENTS"]
        altered["components.json"] = module.encoded(catalog)
        with self.assertRaisesRegex(ValueError, "libsharpyuv patent grant"):
            module._pillow_child_inventory(altered)

    def test_source_controlled_pillow_notices_are_hash_bound_and_linked(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            names = module.PILLOW_NOTICE_REQUIRED_FILES + ("fribidi-shim-NOTICE.md",)
            rows = []
            contents = {}
            for name in names:
                raw = (name + " exact bytes\n").encode()
                contents[name] = raw
                (root / name).write_bytes(raw)
                rows.append({"path": name, "sha256": module.sha(raw),
                             "url": "https://example.invalid/" + name})
            (root / "sources.json").write_text(json.dumps({"schema_version": 1,
                "scope": "test notice inputs", "files": rows}))
            delivered = module._pillow_notice_inputs(root)
            self.assertEqual(set(delivered), set(names) | {"sources.json"})
            self.assertEqual({path: delivered[path] for path in names}, contents)
            licenses = module._link_pillow_notices(b"# Runtime notices\n", delivered)
            for name in names:
                self.assertIn(("component-evidence/pillow-12.3.0/" + name).encode(), licenses)
            self.assertIn(b"component-evidence/pillow-12.3.0/sources.json", licenses)
            (root / names[0]).write_bytes(b"altered")
            with self.assertRaisesRegex(ValueError, "hash/size"):
                module._pillow_notice_inputs(root)

    def test_pillow_notice_catalog_rejects_path_escape(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            raw = b"exact input"
            names = module.PILLOW_NOTICE_REQUIRED_FILES
            rows = []
            for name in names:
                (root / name).write_bytes(raw)
                rows.append({"path": name, "sha256": module.sha(raw),
                             "url": "https://example.invalid/" + name})
            rows.append({"path": "../outside.txt", "sha256": module.sha(raw),
                         "url": "https://example.invalid/outside.txt"})
            (root / "sources.json").write_text(json.dumps({"schema_version": 1, "files": rows}))
            with self.assertRaisesRegex(ValueError, "invalid entry"):
                module._pillow_notice_inputs(root)

    def test_required_component_supplementary_notices_are_exact_and_delivered(self):
        evidence = module.PILLOW_EVIDENCE_PREFIX
        lgpl = "notices-and-source/candidate-native-notices/FFmpeg-8.1.2-COPYING.LGPLv2.1"
        mapping = {
            "pkg:generic/freetype2": ["ACKNOWLEDGEMENTS.md"],
            "pkg:generic/libjpeg": ["ACKNOWLEDGEMENTS.md"],
            "pkg:pypi/pillow@12.3.0#thirdparty/fribidi-shim": ["fribidi-shim-NOTICE.md"],
            "pkg:pypi/pillow@12.3.0#c-ext/PIL._avif": [
                "AOM-3.14.1-LICENSE", "AOM-3.14.1-PATENTS", "dav1d-1.5.3-COPYING",
                "libyuv-644251f-LICENSE", "libwebp-1.6.0-COPYING",
                "libwebp-1.6.0-PATENTS"],
            "pkg:generic/libavif": [
                "AOM-3.14.1-LICENSE", "AOM-3.14.1-PATENTS", "dav1d-1.5.3-COPYING",
                "libyuv-644251f-LICENSE", "libwebp-1.6.0-COPYING",
                "libwebp-1.6.0-PATENTS"],
            "pkg:pypi/pillow@12.3.0#c-ext/PIL._webp": [
                "libwebp-1.6.0-COPYING", "libwebp-1.6.0-PATENTS"],
            "pkg:generic/libwebp": ["libwebp-1.6.0-COPYING", "libwebp-1.6.0-PATENTS"],
        }
        items = []
        delivered = {evidence + name for names in mapping.values() for name in names} | {lgpl}
        for ref, names in mapping.items():
            paths = [evidence + name for name in names]
            legal_paths = [lgpl] if ref.endswith("thirdparty/fribidi-shim") else []
            row = {"bom_ref": ref, "supplementary_notice_paths": paths,
                   "installed_legal_paths": legal_paths}
            items.append({"bom_ref": ref, "plan_row": dict(row), "index_row": dict(row)})
        module._require_supplementary_notice_mappings(items, delivered)
        with self.assertRaisesRegex(ValueError, "undelivered archive bytes"):
            module._require_supplementary_notice_mappings(
                items, delivered - {evidence + "AOM-3.14.1-PATENTS"})
        items[3]["index_row"]["supplementary_notice_paths"].pop()
        with self.assertRaisesRegex(ValueError, "Supplementary notice mapping"):
            module._require_supplementary_notice_mappings(items, delivered)

    def test_required_component_supplementary_notice_inputs_cannot_be_missing(self):
        row = {"bom_ref": "pkg:generic/freetype2", "supplementary_notice_paths": ["NOTICE"]}
        item = {"bom_ref": row["bom_ref"], "plan_row": dict(row), "index_row": dict(row)}
        delivered = {module.PILLOW_EVIDENCE_PREFIX + name
                     for names in module.SUPPLEMENTARY_NOTICES.values() for name in names}
        delivered.add(module.FRIBIDI_LGPL_PATH)
        with self.assertRaisesRegex(ValueError, "Supplementary notice mapping"):
            module._require_supplementary_notice_mappings([item], delivered)

    def test_pillow_notice_catalog_rejects_missing_and_altered_inputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            raw = b"exact input"
            names = module.PILLOW_NOTICE_REQUIRED_FILES + ("fribidi-shim-NOTICE.md",)
            catalog = {"schema_version": 1, "files": []}
            for name in names:
                (root / name).write_bytes(raw)
                catalog["files"].append({"path": name, "sha256": module.sha(raw),
                    "url": "https://example.invalid/" + name})
            catalog["files"].append({"path": "future-notice.md", "sha256": module.sha(raw),
                                     "source": "parent-supplied source record"})
            (root / "sources.json").write_text(json.dumps(catalog))
            (root / "future-notice.md").write_bytes(raw)
            delivered = module._pillow_notice_inputs(root)
            self.assertIn("future-notice.md", delivered)
            (root / "future-notice.md").unlink()
            with self.assertRaisesRegex(ValueError, "input is missing"):
                module._pillow_notice_inputs(root)
            (root / "future-notice.md").write_bytes(raw)
            (root / names[0]).write_bytes(b"altered")
            with self.assertRaisesRegex(ValueError, "hash/size"):
                module._pillow_notice_inputs(root)

    def test_component_rows_bind_to_sbom_identity(self):
        component = {"bom_ref": "pkg:pypi/pillow@12.3.0#thirdparty/raqm",
                     "name": "raqm", "version": "0.10.5", "purl": None}
        item = {"bom_ref": component["bom_ref"],
                "plan_row": {"bom_ref": component["bom_ref"], "name": "raqm",
                             "version": "0.10.5", "purl": None},
                "index_row": {"bom_ref": component["bom_ref"], "name": "raqm",
                              "version": "0.10.5", "purl": None}}
        module._require_component_identity(item, component)
        item["index_row"]["version"] = "other"
        with self.assertRaisesRegex(ValueError, "identity"):
            module._require_component_identity(item, component)

    def test_raqm_row_must_map_exact_source_notice_and_mit(self):
        notice = "notices-and-source/source-notices/pillow-12.3.0/src/thirdparty/raqm/COPYING"
        item = {"bom_ref": "pkg:pypi/pillow@12.3.0#thirdparty/raqm",
                "plan_row": {"installed_legal_paths": [notice],
                             "expressions": [{"licenses": ["MIT"]}]},
                "index_row": {"installed_legal_paths": [notice],
                              "selected_expressions": ["MIT"]}}
        module._require_raqm_notice_mapping(item, {notice})
        item["plan_row"]["installed_legal_paths"] = []
        with self.assertRaisesRegex(ValueError, "RAQM"):
            module._require_raqm_notice_mapping(item, {notice})

    def test_pillow_sdist_is_build_context_for_external_components(self):
        source = {"filename": "pillow-12.3.0.tar.gz", "sha256": "a" * 64,
                  "url": "https://example.invalid/pillow.tar.gz"}
        item = {"bom_ref": "pkg:generic/freetype2",
                "plan_row": {"pillow_build_source": {"path": "notices-and-source/sbom-sources/pillow-12.3.0.tar.gz",
                    "sha256": "a" * 64, "url": source["url"]},
                    "installed_source_path": None, "source_url": None, "source_sha256": None,
                    "source_fulfillment": {"installed_source_path": None, "source_url": None,
                        "source_sha256": None, "complete_corresponding_source_for_entire_binary": False}},
                "index_row": {"pillow_build_source": {"path": "notices-and-source/sbom-sources/pillow-12.3.0.tar.gz",
                    "sha256": "a" * 64, "url": source["url"]},
                    "installed_source_path": None, "source_url": None, "source_sha256": None,
                    "source_fulfillment": {"installed_source_path": None, "source_url": None,
                        "source_sha256": None, "complete_corresponding_source_for_entire_binary": False}}}
        module._require_component_source_scope(item, source, set())
        item["plan_row"]["installed_source_path"] = "notices-and-source/sbom-sources/pillow-12.3.0.tar.gz"
        with self.assertRaisesRegex(ValueError, "source scope"):
            module._require_component_source_scope(item, source, set())

    def test_vendor_source_members_are_checked_against_raw_sdist(self):
        source = {"filename": "pillow-12.3.0.tar.gz", "sha256": "a" * 64,
                  "url": "https://example.invalid/pillow.tar.gz"}
        source_path = "notices-and-source/sbom-sources/pillow-12.3.0.tar.gz"
        descriptor = {"path": source_path, "sha256": source["sha256"], "url": source["url"]}
        fulfillment = {"installed_source_path": source_path, "source_sha256": source["sha256"],
                       "source_url": source["url"],
                       "complete_corresponding_source_for_entire_binary": False,
                       "members": ["pillow-12.3.0/src/thirdparty/raqm/"]}
        item = {"bom_ref": "pkg:pypi/pillow@12.3.0#thirdparty/raqm",
                "plan_row": {"pillow_build_source": descriptor,
                    "installed_source_path": source_path, "source_url": source["url"],
                    "source_sha256": source["sha256"], "source_fulfillment": fulfillment},
                "index_row": {"pillow_build_source": descriptor,
                    "installed_source_path": source_path, "source_url": source["url"],
                    "source_sha256": source["sha256"], "source_fulfillment": dict(fulfillment)}}
        members = {"pillow-12.3.0/src/thirdparty/raqm/raqm.c"}
        module._require_component_source_scope(item, source, members)
        item["plan_row"]["source_fulfillment"]["members"] = ["pillow-12.3.0/src/missing/"]
        with self.assertRaisesRegex(ValueError, "members"):
            module._require_component_source_scope(item, source, members)

    def test_app_font_summary_uses_current_wheel_inventory(self):
        fonts = {
            "autoclip/assets/fonts/Anton-Regular.ttf": b"anton",
            "autoclip/static/assets/Anton-Regular-12345678.ttf": b"anton",
            "autoclip/static/assets/Archivo-Variable-12345678.ttf": b"archivo",
            "autoclip/assets/fonts/Inter-Variable.ttf": b"inter",
            "autoclip/static/assets/Inter-Variable-12345678.ttf": b"inter",
            "autoclip/assets/fonts/Roboto-Variable.ttf": b"roboto",
            "autoclip/static/assets/InstrumentSerif-Regular-12345678.ttf": b"serif regular",
            "autoclip/static/assets/InstrumentSerif-Italic-12345678.ttf": b"serif italic",
        }
        notices = {f"autoclip/assets/licenses/{name}-OFL.txt": b"license"
                   for name in ("Anton", "Archivo", "InstrumentSerif", "Inter", "Roboto")}
        row = {"research_resolution": "all 5 font payloads"}
        module._refresh_app_font_summary(row, fonts, notices)
        self.assertEqual(row["research_resolution"],
                         "all 6 distinct font payloads (8 font paths, 5 families, 5 OFL notices)")

    def test_app_must_declare_selected_pillow_version(self):
        with tempfile.TemporaryDirectory() as directory:
            app = pathlib.Path(directory) / "autoclip-0.1.0.dev0-py3-none-any.whl"
            make_wheel(app, "autoclip", "0.1.0.dev0")
            with self.assertRaisesRegex(ValueError, "Pillow requirement"):
                module._app_requires_pillow(app, "12.3.0")
            add_pillow_requirement(app)
            module._app_requires_pillow(app, "12.3.0")
            with self.assertRaisesRegex(ValueError, "Pillow requirement"):
                module._app_requires_pillow(app, "13.0.0")

    def test_final_mode_rejects_pending_component_plan_or_index_state(self):
        accepted = {"disposition": "accepted_exact_bytes",
                    "plan_row": {"notice_status": "reviewed_exact_notice",
                                 "installed_legal_paths": ["notices/raqm/COPYING"]},
                    "index_row": {"state": "staged_packet_verified",
                                  "installed_legal_paths": ["notices/raqm/COPYING"]}}
        module._require_final_component_state(accepted)
        with self.assertRaisesRegex(ValueError, "legal paths"):
            module._require_final_component_state({**accepted,
                "plan_row": {"notice_status": "reviewed_exact_notice"}})
        with self.assertRaisesRegex(ValueError, "legal paths"):
            module._require_final_component_state({**accepted,
                "index_row": {"state": "staged_packet_verified",
                              "installed_legal_paths": ["notices/other/COPYING"]}})
        with self.assertRaisesRegex(ValueError, "legal paths"):
            module._require_final_component_state(accepted, {"notices/other/COPYING"})
        with self.assertRaisesRegex(ValueError, "pending"):
            module._require_final_component_state({**accepted,
                "plan_row": {"notice_status": "pending_independent_review"}})
        with self.assertRaisesRegex(ValueError, "pending"):
            module._require_final_component_state({**accepted,
                "index_row": {"state": "pending_independent_review"}})

    def test_reviewed_wheel_notice_paths_must_match_actual_members(self):
        info = {"name": "pillow", "version": "12.3.0", "filename": "pillow.whl",
                "bytes": 7, "sha256": "a" * 64, "record_rows": 1, "sbom_files": [],
                "sbom_components": []}
        legal = {"pillow.dist-info/licenses/LICENSE": "b" * 64}
        row = {"normalized_name": "pillow", "version": "12.3.0",
               "filename": "pillow.whl", "bytes": 7, "sha256": "a" * 64,
               "record_rows": 1, "legal_files": list(legal), "legal_sha256": legal,
               "sbom_files": [], "sbom_components": [], "notice_coverage": "present",
               "disposition": "accepted_exact_bytes",
               "verified_sidecar_copies": ["notices-and-source/wheel-notices/pillow.whl/missing"]}
        with self.assertRaisesRegex(ValueError, "sidecar"):
            module._review_row({"publisher_legal_row": row}, "publisher_legal_row", info, legal)

    def test_rejects_pending_review_before_creating_any_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            output = root / "successor.zip"
            installer = root / "installer.ps1"
            with self.assertRaisesRegex(ValueError, "disposition"):
                module.build(
                    base=root / "missing.zip", expected_base="a" * 64,
                    publisher_wheel=root / "missing-pillow.whl",
                    publisher_route={}, publisher_source=root / "missing-source.tar.gz",
                    app_wheel=root / "missing-app.whl", app_receipt=root / "missing-receipt.json",
                    app_bundle=root / "missing.bundle", review={"disposition": "pending_review"},
                    release_id="test-successor", output=output, installer=installer,
                )
            self.assertFalse(output.exists())
            self.assertFalse(installer.exists())

    def test_rejects_empty_or_nonfinal_component_dispositions(self):
        for disposition in (None, "pending", "unreviewed", "candidate", ""):
            with self.subTest(disposition=disposition):
                with self.assertRaisesRegex(ValueError, "disposition"):
                    module.require_final_disposition({"disposition": disposition})
        self.assertEqual(
            module.require_final_disposition({"disposition": "accepted_exact_bytes"}),
            "accepted_exact_bytes",
        )

    def test_rejects_mutating_public_or_existing_outputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            output = root / "successor.zip"
            output.write_bytes(b"do not replace")
            with self.assertRaisesRegex(ValueError, "output"):
                module.require_new_outputs(output, root / "installer.ps1")
            self.assertEqual(output.read_bytes(), b"do not replace")

    def test_auxiliary_packet_includes_new_dependency_and_app_notices(self):
        old = "notices-and-source/wheel-notices/autoclip-old.whl/LICENSE"
        pillow = "notices-and-source/wheel-notices/pillow-new.whl/LICENSE"
        app = "notices-and-source/wheel-notices/autoclip-new.whl/LICENSE"
        source = "notices-and-source/sbom-sources/pillow-new.tar.gz"
        review = "notices-and-source/review/dependency-app-review.json"
        packet = {"files": [{"path": old, "bytes": 1, "sha256": "0" * 64}], "file_count": 1}
        module._update_packet_rows(packet, {pillow: b"p", app: b"a", source: b"s",
                                            review: b"r"},
                                   "notices-and-source/wheel-notices/autoclip-old.whl/")
        self.assertEqual({row["path"] for row in packet["files"]},
                         {pillow, app, source, review})

    def test_extracts_exact_source_notice_sidecar(self):
        member = "pillow-12.3.0/src/thirdparty/raqm/COPYING"
        raw = b"RAQM test license\n"
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode="w:gz") as archive:
            info = tarfile.TarInfo(member)
            info.size = len(raw)
            archive.addfile(info, io.BytesIO(raw))
        references = {member: {"bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}}
        sidecars = module._source_notices(stream.getvalue(), references)
        self.assertEqual(sidecars, {
            "notices-and-source/source-notices/pillow-12.3.0/src/thirdparty/raqm/COPYING": raw,
        })

    def test_builds_consistent_unpublishable_fixture_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            publisher_wheel = root / "pillow-12.3.0-py3-none-any.whl"
            app_wheel = root / "autoclip-0.1.0.dev0-py3-none-any.whl"
            make_wheel(publisher_wheel, "pillow", "12.3.0")
            make_wheel(app_wheel, "autoclip", "0.1.0.dev0")
            add_pillow_requirement(app_wheel)
            publisher = module._validator().verify_wheel(publisher_wheel)
            app = module._validator().verify_wheel(app_wheel)
            notice = b"RAQM test license\n"
            notice_name = "pillow-12.3.0/src/thirdparty/raqm/COPYING"
            stream = io.BytesIO()
            with tarfile.open(fileobj=stream, mode="w:gz") as tar:
                item = tarfile.TarInfo(notice_name)
                item.size = len(notice)
                tar.addfile(item, io.BytesIO(notice))
            source = root / "pillow-12.3.0.tar.gz"
            source.write_bytes(stream.getvalue())
            bundle = root / "app-source.bundle"
            bundle.write_bytes(b"fixture committed source bundle")
            commit = "a" * 40
            receipt = root / "app-build-receipt.json"
            receipt.write_text(json.dumps({"app_commit": commit, "app_wheel_sha256": app["sha256"],
                                           "app_source_bundle_sha256": module.sha(bundle.read_bytes()),
                                           "clean_source": True}))
            route = {"package": "pillow", "version": "12.3.0", "filename": publisher_wheel.name,
                     "tags": ["py3-none-any"], "bytes": publisher["bytes"],
                     "sha256": publisher["sha256"], "url": "https://files.pythonhosted.org/pillow.whl",
                     "publisher_identity": "PyPI pillow", "delivery_policy": "publisher"}
            source_route = {"filename": source.name, "bytes": source.stat().st_size,
                            "sha256": module.sha(source.read_bytes()),
                            "url": "https://files.pythonhosted.org/pillow.tar.gz"}
            def legal_row(info):
                _, legal = module._wheel_members(publisher_wheel if info is publisher else app_wheel, info)
                return {"normalized_name": info["name"], "version": info["version"],
                        "filename": info["filename"], "bytes": info["bytes"],
                        "sha256": info["sha256"], "record_rows": info["record_rows"],
                        "legal_files": sorted(legal), "legal_sha256": legal,
                        "verified_sidecar_copies": [
                            "notices-and-source/wheel-notices/" + info["filename"] + "/" + name
                            for name in sorted(legal)],
                        "notice_coverage": "present", "disposition": module.LOCAL_TEST}
            app_row = legal_row(app)
            publisher_row = legal_row(publisher)
            publisher_row["source_legal_paths"] = [
                "notices-and-source/source-notices/" + notice_name]
            review = {"schema_version": 1, "reviewer": "fixture producer", "disposition": module.LOCAL_TEST,
                      "local_test_only": True, "publisher_route": route,
                      "publisher_wheel_sha256": publisher["sha256"], "app_wheel_sha256": app["sha256"],
                      "publisher_source_sha256": source_route["sha256"],
                      "publisher_source": source_route,
                      "publisher_source_notices": {notice_name: {"bytes": len(notice),
                                                         "sha256": module.sha(notice)}},
                      "app_build_receipt_sha256": module.sha(receipt.read_bytes()),
                      "app_source_bundle_sha256": module.sha(bundle.read_bytes()),
                      "publisher_legal_row": publisher_row, "app_legal_row": app_row,
                      "component_dispositions": []}
            previous = [dict(filename=f"dep{i}.whl", package=f"dep{i}", version="1",
                             sha256="b" * 64) for i in range(74)]
            previous.sort(key=lambda row: row["filename"])
            old_app = "wheelhouse/" + app_wheel.name
            base_files = {
                old_app: app_wheel.read_bytes(),
                "LICENSES.md": b"# Runtime licenses\n",
                "notices-and-source/MANIFEST.md": b"# Runtime notice inventory\n",
                "notices-and-source/legal-index.json": module.encoded({
                    "publisher_wheels": previous, "packages": [
                        {"normalized_name": f"dep{i}"} for i in range(74)] + [app_row],
                    "wheel_count": 75, "native_build": {}}),
                "notices-and-source/sbom-component-plan.json": module.encoded({
                    "components": [], "component_count": 0}),
                "notices-and-source/sbom-component-index.json": module.encoded({
                    "components": [], "component_count": 0}),
                "notices-and-source/sbom-packet-manifest.json": module.encoded({
                    "files": [], "file_count": 0}),
                "notices-and-source/source-and-build/source-artifact-manifest.json": module.encoded({
                    "artifacts": []}),
                "notices-and-source/build-provenance.json": module.encoded({}),
                "build-native-from-source.ps1": b"old native\n",
                "notices-and-source/build-provenance/current/build-native-from-source.ps1": b"old native\n",
                "install-source-build.ps1": b"$expectedArchiveSha256 = 'stale-v14-pin'\n",
                "notices-and-source/build-provenance/current/install-source-build.ps1": b"$expectedArchiveSha256 = 'stale-v14-pin'\n",
                "publisher-wheel-manifest.json": module.encoded({"wheels": previous}),
                "distribution-inventory.json": module.encoded({"publisher_wheels": [],
                    "publisher_wheel_identities": [], "publisher_wheel_count": 74}),
            }
            native_selection = {
                "python": "3.11", "ffmpeg_source_sha256": "1" * 64,
                "pyav_source_sha256": "2" * 64, "onednn_commit": "3" * 40,
                "ctranslate2_commit": "4" * 40, "cuda_toolkit": "12.8",
                "cuda_architectures": "Common plus sm_120",
                "cuda_installer_sha256": "5" * 64,
                "cuda_components": ["nvcc_12.8", "cudart_12.8"],
            }
            base_manifest = {"publisher_wheels": previous,
                             "native_build": native_selection,
                             "external_assets": [{"kind": "openblas_archive",
                                                  "sha256": "6" * 64}],
                             "files": [{"path": n, "bytes": len(raw), "sha256": module.sha(raw)}
                                       for n, raw in sorted(base_files.items())]}
            base_files["release-manifest.json"] = module.encoded(base_manifest)
            base = root / "base.zip"
            with zipfile.ZipFile(base, "w") as archive:
                for name, raw in base_files.items():
                    archive.writestr(name, raw)
            base_hash = module.sha(base.read_bytes())
            base_installer = root / "base-installer.ps1"
            base_installer.write_text(
                "$expectedArchiveSha256 = '" + base_hash + "'\n"
                "$expectedManifestSha256 = '" + module.sha(base_files["release-manifest.json"]) + "'\n"
                "$releaseId = 'old-fixture-release'\n"
                "$uv = Require-Tool 'uv' 'astral-sh.uv' '0.12.19'\n"
                "if ($PrerequisitesOnly) { Write-Host 'Prerequisites are ready.'; return }\n"
                "$downloaded = $false\n"
                "    if (-not $ArchivePath) {\n"
                "    $actualArchiveSha256 = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()\n"
                "    & (Join-Path $InstallRoot 'Prepare-AutoClipOfflineCache.ps1') -ManifestPath $manifestPath -CacheRoot $publisherCache -StageWheelhouse $externalWheels -Offline:$OfflinePublisherCache -InstallNvidiaGpu:$InstallNvidiaGpu\n"
                "    & $uv.Source venv @venvOptions --python 3.11 $venv\n"
                "        $NativeBuildRoot = Join-Path $ExternalCache \"native-build-v11-20260926-$buildProfile\"\n"
                "    & (Join-Path $InstallRoot 'build-native-from-source.ps1') -BuildRoot $NativeBuildRoot -Wheelhouse $externalWheels -OpenBlasArchive $openblasArchive -MsysBash $MsysBash -CudaRoot $CudaRoot -InstallNvidiaGpu:$InstallNvidiaGpu -Python $python -Uv $uv.Source\n"
                "    & $uv.Source pip install --python $python --no-cache --offline --no-index --find-links $wheelhouse --find-links $externalWheels $autoclipPackage\n"
                "    & $uv.Source pip check --python $python\n"
                "    [IO.File]::WriteAllText((Join-Path $InstallRoot '.install-complete'), $expectedArchiveSha256)\n"
                "} finally {\n"
                "    if ($downloaded -and (Test-Path -LiteralPath $ArchivePath)) {\n")
            output = root / "new.zip"
            installer = root / "new.ps1"
            native_script = root / "new-native.ps1"
            native_script.write_bytes(b"fixed native\n")
            module.build(base=base, expected_base=base_hash, base_installer=base_installer,
                         expected_base_installer=module.sha(base_installer.read_bytes()),
                         publisher_wheel=publisher_wheel, publisher_route=route,
                         publisher_source=source, app_wheel=app_wheel,
                         app_receipt=receipt, app_bundle=bundle, review=review,
                         release_id="new-fixture-release", output=output,
                         installer=installer, local_test_only=True,
                         native_script=native_script,
                         expected_native_script=module.sha(native_script.read_bytes()))
            with zipfile.ZipFile(output) as archive:
                catalog_path = pathlib.Path(module.__file__).resolve().parents[1] / "release/notices/pillow/sources.json"
                catalog = json.loads(catalog_path.read_text())
                licenses = archive.read("LICENSES.md")
                for row in catalog["files"]:
                    path = module.PILLOW_EVIDENCE_PREFIX + row["path"]
                    delivered = archive.read(path)
                    self.assertEqual(module.sha(delivered), row["sha256"])
                    self.assertIn(("component-evidence/pillow-12.3.0/" + row["path"]).encode(), licenses)
                self.assertIn(b"component-evidence/pillow-12.3.0/sources.json", licenses)
                child_path = module.PILLOW_EVIDENCE_PREFIX + "components.json"
                children = json.loads(archive.read(child_path))
                self.assertEqual({row["name"] for row in children["components"]},
                                 {"AOM", "dav1d", "libyuv", "libsharpyuv"})
                legal_index = json.loads(archive.read("notices-and-source/legal-index.json"))
                route = legal_index["pillow_child_components"]
                self.assertEqual(route["path"], child_path)
                self.assertEqual(route["sha256"], module.sha(archive.read(child_path)))
                self.assertEqual(route["pillow_wheel_sha256"], publisher["sha256"])
                self.assertIn(child_path.encode(), archive.read("notices-and-source/MANIFEST.md"))
                manifest = module._verify_manifest(archive, publisher_count=75)
                self.assertNotIn(
                    "wheelhouse/" + publisher_wheel.name,
                    archive.namelist(),
                    "Publisher Pillow must be acquired into the external publisher cache only",
                )
                packet = json.loads(archive.read("notices-and-source/sbom-packet-manifest.json"))
                packet_paths = {row["path"] for row in packet["files"]}
                for row in catalog["files"]:
                    self.assertIn(module.PILLOW_EVIDENCE_PREFIX + row["path"], packet_paths)
                for row in packet["files"]:
                    self.assertEqual(module.sha(archive.read(row["path"])), row["sha256"])
                self.assertNotIn("release-manifest.json", {row["path"] for row in manifest["files"]})
                self.assertIn("UNPUBLISHABLE_LOCAL_TEST_ONLY",
                              archive.read("notices-and-source/legal-index.json").decode())
                source_manifest = json.loads(archive.read(
                    "notices-and-source/source-and-build/source-artifact-manifest.json"))
                pillow_source = source_manifest["artifacts"][-1]
                self.assertIn("Pillow build/source context", pillow_source["relationship"])
                self.assertIn("not complete source for external native components",
                              pillow_source["relationship"])
                self.assertEqual(archive.read("build-native-from-source.ps1"),
                                 archive.read("notices-and-source/build-provenance/current/build-native-from-source.ps1"))
                provenance = json.loads(archive.read("notices-and-source/build-provenance.json"))
                self.assertEqual(provenance["source_state"],
                                 "local_test_uncommitted_native_script_override")
                internal = archive.read("install-source-build.ps1")
                self.assertIn(b"companion standalone", internal)
                self.assertIn(installer.name.encode(), internal)
                self.assertNotIn(b"stale-v14-pin", internal)
                self.assertEqual(archive.read(
                    "notices-and-source/build-provenance/current/install-source-build.ps1"),
                    b"$expectedArchiveSha256 = 'stale-v14-pin'\n")
            standalone = installer.read_bytes()
            self.assertNotIn(b"\r\r\n", standalone)
            self.assertIn(b"Building native runtime", standalone)
            self.assertIn(b"Native build completed", standalone)
            self.assertIn(b"Native build failed", standalone)
            for phase in (b"Checking prerequisites", b"Verifying release archive",
                          b"Preparing publisher cache", b"Creating Python environment",
                          b"Installing offline wheels", b"Verifying installed runtime"):
                self.assertIn(phase, standalone)
            self.assertIn(b"Write-Progress", standalone)
            self.assertIn(b"& (Join-Path $InstallRoot 'build-native-from-source.ps1')", standalone)
            self.assertNotIn(b"Start-Job -ScriptBlock", standalone)
            self.assertNotIn(b"-EncodedCommand $command64", standalone)
            self.assertNotIn(b"Register-ObjectEvent", standalone)
            self.assertIn(b"Write-Progress -Id 1 -Activity 'AutoClip installation'", standalone)
            self.assertIn(b"Write-Progress -Id 2 -Activity 'Native source build'", standalone)
            self.assertIn(b"} finally {\r\n    Write-Progress -Id 1 -Activity 'AutoClip installation' -Completed", standalone)
            successor_standalone = module._standalone_from_base(
                base_installer.read_bytes(), base_hash,
                module.sha(base_files["release-manifest.json"]), "old-fixture-release",
                "a" * 64, "b" * 64, "new-fixture-r15", local_test_only=True,
                native_cache_key=module._native_cache_key(
                    native_script.read_bytes(), base_manifest))
            cache_route = rb"native-build-v41-[a-z0-9]+-\$buildProfile"
            self.assertEqual(re.search(cache_route, standalone).group(),
                             re.search(cache_route, successor_standalone).group())
            self.assertNotEqual(
                module._native_cache_key(b"changed native", base_manifest),
                module._native_cache_key(native_script.read_bytes(), base_manifest))
            different_inputs = json.loads(json.dumps(base_manifest))
            different_inputs["external_assets"][0]["sha256"] = "7" * 64
            self.assertNotEqual(
                module._native_cache_key(native_script.read_bytes(), different_inputs),
                module._native_cache_key(native_script.read_bytes(), base_manifest))
            different_inputs = json.loads(json.dumps(base_manifest))
            different_inputs["native_build"]["cuda_components"].append("curand_12.8")
            self.assertNotEqual(
                module._native_cache_key(native_script.read_bytes(), different_inputs),
                module._native_cache_key(native_script.read_bytes(), base_manifest))
            self.assertNotIn(b"native-build-v11-20260926-$buildProfile", standalone)
            powershell = shutil.which("powershell")
            if powershell:
                native = root / "build-native-from-source.ps1"
                native.write_text(
                    "param($BuildRoot,$Wheelhouse,$OpenBlasArchive,$MsysBash,$CudaRoot,"
                    "[switch]$InstallNvidiaGpu,$Python,$Uv)\n"
                    "Start-Sleep -Milliseconds 200\nWrite-Output 'NATIVE_DONE'\n")
                generated = standalone.decode("utf-8-sig").replace("\r\n", "\n")
                start = generated.index("    $nativeBuildStarted = Get-Date")
                stop = generated.index("\n", generated.index(
                    "    Write-Host ('Native build completed", start) + 5)
                fragment = generated[start:stop]
                prelude = (
                    "$ErrorActionPreference='Stop'\n"
                    "function Write-Progress { param([int]$Id,[string]$Activity,"
                    "[string]$Status,[int]$PercentComplete,[switch]$Completed); "
                    "if($Completed){ Write-Host ('PROGRESS_COMPLETED:' + $Id) } "
                    "elseif($Status){ Write-Host ('PROGRESS:' + $Status) } }\n"
                    f"$InstallRoot='{str(root).replace(chr(39), chr(39) * 2)}'\n"
                    "$NativeBuildRoot='test';$externalWheels='test';$openblasArchive='test'\n"
                    "$MsysBash='test';$CudaRoot='test';$InstallNvidiaGpu=$false\n"
                    "$python='test';$uv=[pscustomobject]@{Source='test'}\n")
                probe = root / "native-progress-probe.ps1"
                probe.write_text(prelude + fragment, encoding="utf-8")
                command = [powershell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(probe)]
                result = subprocess.run(command, capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("NATIVE_DONE", result.stdout)
                self.assertIn("PROGRESS_COMPLETED:2", result.stdout)
                native.write_text(
                    "param($BuildRoot,$Wheelhouse,$OpenBlasArchive,$MsysBash,$CudaRoot,"
                    "[switch]$InstallNvidiaGpu,$Python,$Uv)\n"
                    "& python -c \"import sys; sys.stderr.write('BENIGN_UV_STATUS\\n')\"\n"
                    "if ($LASTEXITCODE -ne 0) { throw 'NATIVE_EXIT_FAILED' }\n"
                    "Write-Output 'NATIVE_DONE_AFTER_STDERR'\n")
                benign = subprocess.run(command, capture_output=True, text=True, timeout=30)
                self.assertEqual(benign.returncode, 0, benign.stdout + benign.stderr)
                self.assertIn("NATIVE_DONE_AFTER_STDERR", benign.stdout)
                self.assertIn("BENIGN_UV_STATUS", benign.stdout + benign.stderr)
                self.assertIn("PROGRESS_COMPLETED:2", benign.stdout)
                native.write_text(
                    "& python -c \"import sys; sys.exit(23)\"\n")
                nonzero = subprocess.run(command, capture_output=True, text=True, timeout=30)
                self.assertNotEqual(nonzero.returncode, 0)
                self.assertIn("Native build failed", nonzero.stdout)
                self.assertIn("PROGRESS_COMPLETED:2", nonzero.stdout)
                native.write_text("throw 'NATIVE_FAILED'\n")
                failed = subprocess.run(command, capture_output=True, text=True, timeout=30)
                self.assertNotEqual(failed.returncode, 0)
                self.assertIn("Native build failed", failed.stdout)
                self.assertIn("PROGRESS_COMPLETED:2", failed.stdout)


if __name__ == "__main__":
    unittest.main()
