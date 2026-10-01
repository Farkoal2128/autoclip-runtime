"""Assemble an unpublished dependency-and-app successor from exact local bytes.

This is intentionally separate from the metadata-only 74-wheel successor recipe.
Inputs are a v40 archive/standalone, verified Pillow publisher wheel and source,
an AutoClip wheel/committed-source receipt/bundle, and an explicit evidence packet.
The packet is producer data. Its final disposition must come from an attributable
review; a local-test-only build is stamped unpublishable and cannot confer one.
"""

import argparse
import hashlib
import importlib.util
import io
import json
import re
import subprocess
import tarfile
import zipfile
from email.parser import BytesParser
from email.policy import default
from pathlib import Path, PurePosixPath


VALID_FINAL = {"accepted_exact_bytes"}
LOCAL_TEST = "pending_local_qualification"
PACKET_PREFIX = "notices-and-source/"
PILLOW_NOTICE_REQUIRED_FILES = (
    "AOM-3.14.1-LICENSE", "AOM-3.14.1-PATENTS", "dav1d-1.5.3-COPYING",
    "libyuv-644251f-LICENSE", "libwebp-1.6.0-COPYING",
    "libwebp-1.6.0-PATENTS", "ACKNOWLEDGEMENTS.md",
)
PILLOW_EVIDENCE_PREFIX = "notices-and-source/component-evidence/pillow-12.3.0/"
FRIBIDI_LGPL_PATH = "notices-and-source/candidate-native-notices/FFmpeg-8.1.2-COPYING.LGPLv2.1"
SUPPLEMENTARY_NOTICES = {
    "pkg:generic/freetype2": ("ACKNOWLEDGEMENTS.md",),
    "pkg:generic/libjpeg": ("ACKNOWLEDGEMENTS.md",),
    "pkg:pypi/pillow@12.3.0#thirdparty/fribidi-shim": ("fribidi-shim-NOTICE.md",),
    "pkg:pypi/pillow@12.3.0#c-ext/PIL._avif": (
        "AOM-3.14.1-LICENSE", "AOM-3.14.1-PATENTS", "dav1d-1.5.3-COPYING",
        "libyuv-644251f-LICENSE", "libwebp-1.6.0-COPYING",
        "libwebp-1.6.0-PATENTS"),
    "pkg:generic/libavif": (
        "AOM-3.14.1-LICENSE", "AOM-3.14.1-PATENTS", "dav1d-1.5.3-COPYING",
        "libyuv-644251f-LICENSE", "libwebp-1.6.0-COPYING",
        "libwebp-1.6.0-PATENTS"),
    "pkg:pypi/pillow@12.3.0#c-ext/PIL._webp": (
        "libwebp-1.6.0-COPYING", "libwebp-1.6.0-PATENTS"),
    "pkg:generic/libwebp": ("libwebp-1.6.0-COPYING", "libwebp-1.6.0-PATENTS"),
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def require_final_disposition(row, *, local_test_only=False):
    value = row.get("disposition")
    if value in VALID_FINAL:
        return value
    if local_test_only and value == LOCAL_TEST:
        return value
    raise ValueError("Exact independent disposition is required")


def require_new_outputs(output, installer):
    if output.exists() or installer.exists():
        raise ValueError("Refusing to replace an existing immutable output")


def _require_final_component_state(item, available_paths=None):
    require_final_disposition(item)
    for field, key in (("plan_row", "notice_status"), ("index_row", "state")):
        value = item.get(field, {}).get(key)
        if not isinstance(value, str) or not value or re.search(
                r"(?i)pending|unreviewed|candidate|unresolved|missing", value):
            raise ValueError("Component has pending or missing final " + field + " disposition")
    plan_paths = item["plan_row"].get("installed_legal_paths")
    index_paths = item["index_row"].get("installed_legal_paths")
    if (not isinstance(plan_paths, list) or not plan_paths
            or not all(isinstance(path, str) and path for path in plan_paths)
            or plan_paths != index_paths
            or (available_paths is not None and not set(plan_paths) <= available_paths)):
        raise ValueError("Component legal paths are missing, inconsistent, or undelivered")


def _validator():
    path = Path(__file__).with_name("validate-dependency-app-successor.py")
    spec = importlib.util.spec_from_file_location("dependency_app_validator", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _safe_names(archive):
    names = archive.namelist()
    if len(names) != len(set(names)):
        raise ValueError("Duplicate archive members")
    for name in names:
        parts = PurePosixPath(name).parts
        if not name or name.startswith("/") or "\\" in name or ".." in parts or ":" in parts[0]:
            raise ValueError("Unsafe archive member: " + name)
    return names


def _verify_manifest(archive, *, publisher_count=74):
    names = _safe_names(archive)
    manifest = json.loads(archive.read("release-manifest.json"))
    rows = manifest["files"]
    if set(names) != {row["path"] for row in rows} | {"release-manifest.json"}:
        raise ValueError("Base manifest membership differs")
    for row in rows:
        raw = archive.read(row["path"])
        if len(raw) != row["bytes"] or sha(raw) != row["sha256"]:
            raise ValueError("Base manifest hash differs: " + row["path"])
    if len(manifest["publisher_wheels"]) != publisher_count:
        raise ValueError("Publisher wheel count differs")
    return manifest


def _wheel_members(wheel, info):
    with zipfile.ZipFile(wheel) as archive:
        names = _safe_names(archive)
        legal = {name: sha(archive.read(name)) for name in names
                 if "/licenses/" in name or name.startswith("autoclip/assets/licenses/")}
        return names, legal


def _app_requires_pillow(app_wheel, selected_version):
    """Check the selected wheel against the app's base Pillow requirement."""
    with zipfile.ZipFile(app_wheel) as archive:
        metadata_members = [name for name in archive.namelist() if name.endswith(".dist-info/METADATA")]
        if len(metadata_members) != 1:
            raise ValueError("App Pillow requirement cannot be established")
        metadata = BytesParser(policy=default).parsebytes(archive.read(metadata_members[0]))
    requirements = [value.strip() for value in metadata.get_all("Requires-Dist", [])
                    if re.match(r"(?i)^pillow\b", value.strip())]
    if len(requirements) != 1:
        raise ValueError("App Pillow requirement is missing or ambiguous")
    match = re.fullmatch(r"(?i)pillow\s*((?:[<>!=]=?\s*[0-9]+(?:\.[0-9]+)*"
                         r"\s*)(?:,\s*[<>!=]=?\s*[0-9]+(?:\.[0-9]+)*\s*)*)", requirements[0])
    if not match:
        raise ValueError("App Pillow requirement has unsupported syntax")
    selected = tuple(int(part) for part in selected_version.split("."))
    for op, number in re.findall(r"([<>!=]=?)\s*([0-9]+(?:\.[0-9]+)*)", match.group(1)):
        target = tuple(int(part) for part in number.split("."))
        width = max(len(selected), len(target))
        left = selected + (0,) * (width - len(selected))
        right = target + (0,) * (width - len(target))
        accepted = {"<": left < right, "<=": left <= right, ">": left > right,
                    ">=": left >= right, "==": left == right, "!=": left != right}.get(op)
        if accepted is not True:
            raise ValueError("Selected Pillow version violates app Pillow requirement")


def _exact_file(path, *, expected_sha=None, expected_bytes=None):
    if not path.is_file():
        raise ValueError("Required exact input is missing: " + str(path))
    data = path.read_bytes()
    if not data or (expected_sha is not None and sha(data) != expected_sha) or (
        expected_bytes is not None and len(data) != expected_bytes
    ):
        raise ValueError("Required exact input hash/size differs: " + str(path))
    return data


def _source_notices(source_raw, references):
    if not isinstance(references, dict) or not any(
        name.endswith("/src/thirdparty/raqm/COPYING") for name in references
    ):
        raise ValueError("Exact RAQM source notice route is required")
    sidecars = {}
    with tarfile.open(fileobj=io.BytesIO(source_raw), mode="r:gz") as archive:
        members = archive.getmembers()
        if len({item.name for item in members}) != len(members):
            raise ValueError("Duplicate publisher source members")
        for name, expected in references.items():
            parts = PurePosixPath(name).parts
            if (not parts or parts[0] != "pillow-12.3.0" or ".." in parts
                    or name.startswith("/") or "\\" in name):
                raise ValueError("Unsafe publisher source notice path")
            item = archive.getmember(name)
            if not item.isfile():
                raise ValueError("Publisher source notice is not a file")
            extracted = archive.extractfile(item)
            if extracted is None:
                raise ValueError("Publisher source notice could not be read")
            raw = extracted.read()
            if len(raw) != expected.get("bytes") or sha(raw) != expected.get("sha256"):
                raise ValueError("Publisher source notice bytes differ")
            sidecars["notices-and-source/source-notices/" + name] = raw
    return sidecars


def _require_component_identity(item, component):
    expected = {key: component.get(key) for key in ("bom_ref", "name", "version", "purl")}
    if item.get("bom_ref") != expected["bom_ref"]:
        raise ValueError("Component identity differs from the wheel SBOM")
    for field in ("plan_row", "index_row"):
        row = item.get(field)
        if not isinstance(row, dict) or any(row.get(key) != value for key, value in expected.items()):
            raise ValueError("Component " + field + " identity differs from the wheel SBOM")


def _require_raqm_notice_mapping(item, available_paths):
    if item.get("bom_ref") != "pkg:pypi/pillow@12.3.0#thirdparty/raqm":
        return
    notice = ("notices-and-source/source-notices/pillow-12.3.0/"
              "src/thirdparty/raqm/COPYING")
    plan, index = item["plan_row"], item["index_row"]
    plan_licenses = {license_id for expression in plan.get("expressions", [])
                     for license_id in expression.get("licenses", [])}
    if (notice not in available_paths
            or notice not in plan.get("installed_legal_paths", [])
            or notice not in index.get("installed_legal_paths", [])
            or "MIT" not in plan_licenses
            or "MIT" not in index.get("selected_expressions", [])):
        raise ValueError("RAQM component must map the delivered exact MIT source notice")


def _require_supplementary_notice_mappings(items, available_paths):
    matched = {}
    for item in items:
        ref = item.get("bom_ref")
        if ref not in SUPPLEMENTARY_NOTICES:
            continue
        if ref in matched:
            raise ValueError("Supplementary notice mapping has duplicate component rows")
        expected = {PILLOW_EVIDENCE_PREFIX + name for name in SUPPLEMENTARY_NOTICES[ref]}
        if not expected <= available_paths:
            raise ValueError("Supplementary notice mapping references undelivered archive bytes")
        rows = [item.get("plan_row"), item.get("index_row")]
        actual = []
        for row in rows:
            paths = row.get("supplementary_notice_paths") if isinstance(row, dict) else None
            if (not isinstance(paths, list) or len(paths) != len(set(paths))
                    or set(paths) != expected):
                raise ValueError("Supplementary notice mapping differs from required component scope")
            actual.append(set(paths))
        if actual[0] != actual[1]:
            raise ValueError("Supplementary notice mapping differs between plan and index")
        if ref == "pkg:pypi/pillow@12.3.0#thirdparty/fribidi-shim":
            if FRIBIDI_LGPL_PATH not in available_paths or any(
                    not isinstance(row, dict)
                    or FRIBIDI_LGPL_PATH not in row.get("installed_legal_paths", [])
                    for row in rows):
                raise ValueError("Supplementary notice mapping omits the delivered fribidi-shim LGPL text")
        matched[ref] = True
    if set(matched) != set(SUPPLEMENTARY_NOTICES):
        raise ValueError("Supplementary notice mapping is missing required component rows")


def _require_component_source_scope(item, source, source_members):
    source_path = PACKET_PREFIX + "sbom-sources/" + source["filename"]
    source_record = {"path": source_path, "sha256": source["sha256"], "url": source["url"]}
    plan, index = item["plan_row"], item["index_row"]
    if plan.get("pillow_build_source") != source_record or index.get("pillow_build_source") != source_record:
        raise ValueError("Pillow build source context differs from the exact sdist")

    ref = item["bom_ref"]
    pillow_owned = ref.startswith("pkg:pypi/pillow@12.3.0#c-ext/")
    vendored = ref in {
        "pkg:pypi/pillow@12.3.0#thirdparty/fribidi-shim",
        "pkg:github/python/pythoncapi-compat",
        "pkg:pypi/pillow@12.3.0#thirdparty/raqm",
    }
    if pillow_owned or vendored:
        for row in (plan, index):
            if (row.get("installed_source_path") != source_path
                    or row.get("source_sha256") != source["sha256"]
                    or row.get("source_url") != source["url"]):
                raise ValueError("Pillow-owned/vendor source association differs")
        fulfillments = [row.get("source_fulfillment") for row in (plan, index)]
        if any(not isinstance(fulfillment, dict)
               or fulfillment.get("installed_source_path") != source_path
               or fulfillment.get("source_sha256") != source["sha256"]
               or fulfillment.get("source_url") != source["url"]
               or fulfillment.get("complete_corresponding_source_for_entire_binary") is not False
               for fulfillment in fulfillments):
            raise ValueError("Pillow source scope must remain incomplete for the entire binary")
        if vendored:
            member_sets = [fulfillment.get("members") for fulfillment in fulfillments]
            if (not member_sets[0] or member_sets[0] != member_sets[1]
                    or not all(any(source_member == path or
                                   source_member.startswith(path.rstrip("/") + "/")
                                   for source_member in source_members)
                               for path in member_sets[0])):
                raise ValueError("Vendored component source members are absent from the exact sdist")
    else:
        for row in (plan, index):
            if any(row.get(field) is not None for field in
                   ("installed_source_path", "source_url", "source_sha256")):
                raise ValueError("External component source scope falsely identifies the Pillow sdist")
        fulfillments = [row.get("source_fulfillment") for row in (plan, index)]
        if any(not isinstance(fulfillment, dict)
               or any(fulfillment.get(field) is not None for field in
                      ("installed_source_path", "source_url", "source_sha256"))
               or fulfillment.get("complete_corresponding_source_for_entire_binary") is not False
               for fulfillment in fulfillments):
            raise ValueError("External component source fulfillment is misattributed")


def _font_family(path):
    stem = PurePosixPath(path).stem
    stem = re.sub(r"-[A-Za-z0-9_-]{8}$", "", stem)
    return re.sub(r"-(?:regular|variable|italic|bold|light|medium|semibold|black)$",
                  "", stem, flags=re.IGNORECASE)


def _refresh_app_font_summary(row, fonts, notices):
    if not fonts:
        raise ValueError("Current app wheel has no font inventory")
    summary = (f"all {len({sha(data) for data in fonts.values()})} distinct font payloads "
               f"({len(fonts)} font paths, {len({_font_family(path) for path in fonts})} families, "
               f"{len(notices)} OFL notices)")
    prior = row.get("research_resolution")
    if not isinstance(prior, str) or not re.search(r"all \d+ (?:distinct )?font payloads", prior):
        raise ValueError("Current app font summary is missing or unrecognized")
    row["research_resolution"] = re.sub(
        r"all \d+ (?:distinct )?font payloads(?: \([^)]*\))?", summary, prior, count=1)


def _pillow_notice_inputs(root=None):
    root = Path(root) if root is not None else Path(__file__).resolve().parents[1] / "release/notices/pillow"
    catalog_raw = _exact_file(root / "sources.json")
    catalog = json.loads(catalog_raw)
    rows = catalog.get("files") if catalog.get("schema_version") == 1 else None
    names = [row.get("path") for row in rows if isinstance(row, dict)] if isinstance(rows, list) else []
    if (not rows or len(names) != len(rows) or len(set(names)) != len(names)
            or not set(PILLOW_NOTICE_REQUIRED_FILES) <= set(names)):
        raise ValueError("Pillow notice source catalog differs from the required files")
    delivered = {}
    for row in rows:
        name = row["path"]
        url, source = row.get("url"), row.get("source")
        if (not isinstance(name, str) or name in {".", "..", "sources.json"}
                or PurePosixPath(name).name != name or "\\" in name
                or not re.fullmatch(r"[A-Za-z0-9._-]+", name)
                or not re.fullmatch(r"[0-9a-f]{64}", row.get("sha256", ""))
                or not (isinstance(url, str) and url.startswith("https://")
                        or isinstance(source, str) and source)):
            raise ValueError("Pillow notice source catalog has an invalid entry")
        delivered[name] = _exact_file(root / name, expected_sha=row["sha256"])
    delivered["sources.json"] = catalog_raw
    return delivered


def _pillow_child_inventory(delivered):
    raw = delivered.get("components.json")
    if raw is None:
        raise ValueError("Pillow child component inventory is missing")
    catalog = json.loads(raw)
    rows = catalog.get("components", [])
    if (catalog.get("schema_version") != 1 or not isinstance(rows, list)
            or {row.get("name") for row in rows if isinstance(row, dict)}
            != {"AOM", "dav1d", "libyuv", "libsharpyuv"} or len(rows) != 4):
        raise ValueError("Pillow child component inventory differs")
    for row in rows:
        if (not row.get("source_ref") or not row.get("source_url")
                or row.get("review_state") != "unresolved" or not row.get("notices")):
            raise ValueError("Pillow child component source or review scope differs")
        if (row["name"] == "libsharpyuv" and
                "libwebp-1.6.0-PATENTS" not in
                {notice.get("path") for notice in row["notices"]}):
            raise ValueError("Pillow libsharpyuv patent grant is missing")
        for notice in row["notices"]:
            path = notice.get("path")
            if path not in delivered or notice.get("sha256") != sha(delivered[path]):
                raise ValueError("Pillow child component notice differs from delivered bytes")
    return raw


def _link_pillow_notices(licenses_raw, delivered):
    if not isinstance(licenses_raw, bytes) or b"\x00" in licenses_raw:
        raise ValueError("Recipient LICENSES.md is not valid UTF-8 text")
    try:
        licenses_raw.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise ValueError("Recipient LICENSES.md is not valid UTF-8 text") from exc
    marker = b"## Pillow 12.3.0 component evidence"
    if marker in licenses_raw:
        raise ValueError("Recipient LICENSES.md already has a Pillow evidence section")
    routes = [(name, PILLOW_EVIDENCE_PREFIX + name)
              for name in delivered if name != "sources.json"]
    routes.append(("Source identity catalog", PILLOW_EVIDENCE_PREFIX + "sources.json"))
    block = ("\n\n## Pillow 12.3.0 component evidence\n\n"
             "Supplemental notice and acknowledgement files delivered with this candidate:\n\n"
             + "\n".join(f"- [{label}]({path})" for label, path in routes)
             + "\n\nTheir delivery does not complete the component mappings or unresolved review items.\n")
    return licenses_raw + block.encode("utf-8")


NATIVE_BUILD_CALL = (
    "    & (Join-Path $InstallRoot 'build-native-from-source.ps1') "
    "-BuildRoot $NativeBuildRoot -Wheelhouse $externalWheels "
    "-OpenBlasArchive $openblasArchive -MsysBash $MsysBash "
    "-CudaRoot $CudaRoot -InstallNvidiaGpu:$InstallNvidiaGpu "
    "-Python $python -Uv $uv.Source"
)


def _native_cache_key(script_raw, manifest):
    native = manifest["native_build"]
    openblas = [row for row in manifest["external_assets"]
                if row["kind"] == "openblas_archive"]
    if len(openblas) != 1:
        raise ValueError("Exact native OpenBLAS input selection is required")
    inputs = {key: native[key] for key in (
        "python", "ffmpeg_source_sha256", "pyav_source_sha256",
        "onednn_commit", "ctranslate2_commit", "cuda_toolkit",
        "cuda_architectures", "cuda_installer_sha256", "cuda_components")}
    inputs["openblas_sha256"] = openblas[0]["sha256"]
    inputs["build_script_sha256"] = sha(script_raw)
    return sha(encoded(inputs))[:16]


def _standalone_from_base(base_raw, old_archive, old_manifest, old_id,
                          new_archive, new_manifest, new_id, *, local_test_only,
                          native_cache_key):
    template = base_raw.decode("utf-8-sig")
    for old, new in ((old_archive, new_archive), (old_manifest, new_manifest),
                     (old_id, new_id)):
        if template.count(old) != 1:
            raise ValueError("Base standalone pin is not unique")
        template = template.replace(old, new, 1)
    if template.count(NATIVE_BUILD_CALL) != 1:
        raise ValueError("Base standalone native-build call differs")
    progress = (
        "    Write-Progress -Activity 'AutoClip installation' -Status 'Building native runtime' -PercentComplete 55\n"
        "    Write-Progress -Activity 'Native source build' -Status 'Starting compiler.'\n"
        "    Write-Host 'Building native runtime from source. This can take several minutes; compiler output follows.'\n"
        "    $nativeBuildStarted = Get-Date\n"
        "    try {\n"
        "        $global:LASTEXITCODE = 0\n"
        + NATIVE_BUILD_CALL + "\n"
        "        $nativeSucceeded = $?\n"
        "        $nativeExitCode = $LASTEXITCODE\n"
        "        if (-not $nativeSucceeded -or ($null -ne $nativeExitCode -and $nativeExitCode -ne 0)) {\n"
        "            throw ('Pinned PyAV/CTranslate2 source build failed with exit code {0}.' -f $nativeExitCode)\n"
        "        }\n"
        "    } catch {\n"
        "        Write-Host ('Native build failed after {0:n1} minutes: {1}' -f "
        "((Get-Date) - $nativeBuildStarted).TotalMinutes, $_.Exception.Message)\n"
        "        throw\n"
        "    } finally {\n"
        "        Write-Progress -Activity 'Native source build' -Completed\n"
        "    }\n"
        "    Write-Host ('Native build completed in {0:n1} minutes.' -f "
        "((Get-Date) - $nativeBuildStarted).TotalMinutes)"
    )
    template = template.replace(NATIVE_BUILD_CALL, progress, 1)
    old_native_cache = "native-build-v11-20260926-$buildProfile"
    if template.count(old_native_cache) != 1:
        raise ValueError("Base standalone native cache route differs")
    template = template.replace(old_native_cache,
                                "native-build-v41-" + native_cache_key + "-$buildProfile", 1)
    stages = (
        ("$uv = Require-Tool 'uv' 'astral-sh.uv' '0.12.19'",
         "Write-Progress -Activity 'AutoClip installation' -Status 'Checking prerequisites' -PercentComplete 5\n"),
        ("$downloaded = $false",
         "Write-Progress -Activity 'AutoClip installation' -Status 'Prerequisites ready' -PercentComplete 15\n"),
        ("    if (-not $ArchivePath) {",
         "    Write-Progress -Activity 'AutoClip installation' -Status 'Acquiring release archive' -PercentComplete 20\n"),
        ("    $actualArchiveSha256 = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()",
         "    Write-Progress -Activity 'AutoClip installation' -Status 'Verifying release archive' -PercentComplete 25\n"),
        ("    & (Join-Path $InstallRoot 'Prepare-AutoClipOfflineCache.ps1')",
         "    Write-Progress -Activity 'AutoClip installation' -Status 'Preparing publisher cache' -PercentComplete 35\n"),
        ("    & $uv.Source venv @venvOptions --python 3.11 $venv",
         "    Write-Progress -Activity 'AutoClip installation' -Status 'Creating Python environment' -PercentComplete 45\n"),
        ("    & $uv.Source pip install --python $python --no-cache --offline",
         "    Write-Progress -Activity 'AutoClip installation' -Status 'Installing offline wheels' -PercentComplete 75\n"),
        ("    & $uv.Source pip check --python $python",
         "    Write-Progress -Activity 'AutoClip installation' -Status 'Verifying installed runtime' -PercentComplete 90\n"),
        ("    [IO.File]::WriteAllText((Join-Path $InstallRoot '.install-complete'), $expectedArchiveSha256)",
         "    Write-Progress -Activity 'AutoClip installation' -Status 'Finalizing installation' -PercentComplete 98\n"),
        ("    if ($downloaded -and (Test-Path -LiteralPath $ArchivePath)) {",
         "    Write-Progress -Activity 'AutoClip installation' -Completed\n"),
    )
    for marker, before in stages:
        if template.count(marker) != 1:
            raise ValueError("Base standalone progress anchor differs: " + marker)
        template = template.replace(marker, before + marker, 1)
    prereq_only = "if ($PrerequisitesOnly) { Write-Host 'Prerequisites are ready.'; return }"
    if template.count(prereq_only) != 1:
        raise ValueError("Base standalone prerequisite exit differs")
    template = template.replace(prereq_only,
        "if ($PrerequisitesOnly) { Write-Progress -Activity 'AutoClip installation' -Completed; "
        "Write-Host 'Prerequisites are ready.'; return }", 1)
    if local_test_only:
        marker = "$releaseId = '" + new_id + "'"
        template = template.replace(marker, marker + "\n" +
            "Write-Host 'UNPUBLISHABLE_LOCAL_TEST_ONLY: installer/updater qualification candidate.'", 1)
    template = template.replace("Write-Progress -Activity 'AutoClip installation'",
                                "Write-Progress -Id 1 -Activity 'AutoClip installation'")
    template = template.replace("Write-Progress -Activity 'Native source build'",
                                "Write-Progress -Id 2 -Activity 'Native source build'")
    return template.replace("\r\n", "\n").replace("\r", "\n").replace("\n", "\r\n").encode("utf-8")


def _disabled_archive_installer(release_id, archive_name, companion_name):
    """Prevent a stale archive-root script from becoming an alternate installer."""
    for name in (archive_name, companion_name):
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]+", name):
            raise ValueError("Unsafe companion installer or archive filename")
    message = (f"Archive-root install-source-build.ps1 is disabled for {release_id}. "
               f"Use the companion standalone {companion_name} with -ArchivePath "
               f"pointing to {archive_name}. The standalone pins exact archive and manifest hashes.")
    return ("# Generated non-entrypoint; historical source is preserved under "
            "notices-and-source/build-provenance/current.\r\n"
            "$ErrorActionPreference = 'Stop'\r\n"
            "throw '" + message + "'\r\n").encode("utf-8")


def _review_row(review, key, info, legal_hashes):
    row = review.get(key)
    if not isinstance(row, dict):
        raise ValueError("Exact reviewed legal package row is required: " + key)
    for field, value in (("normalized_name", info["name"]), ("version", info["version"]),
                         ("filename", info["filename"]), ("bytes", info["bytes"]),
                         ("sha256", info["sha256"]), ("record_rows", info["record_rows"])):
        if row.get(field) != value:
            raise ValueError("Exact reviewed legal package identity differs: " + key)
    if row.get("legal_sha256") != legal_hashes or set(row.get("legal_files", [])) != set(legal_hashes):
        raise ValueError("Exact reviewed legal package notices differ: " + key)
    sidecars = {PACKET_PREFIX + "wheel-notices/" + info["filename"] + "/" + name
                for name in legal_hashes}
    if set(row.get("verified_sidecar_copies", [])) != sidecars:
        raise ValueError("Exact reviewed legal sidecar paths differ: " + key)
    if set(row.get("sbom_files", [])) != {item["path"] for item in info["sbom_files"]}:
        raise ValueError("Exact reviewed legal package SBOM files differ: " + key)
    if ({item.get("purl") for item in row.get("sbom_components", [])}
            != {item["purl"] for item in info["sbom_components"]}
            or len(row.get("sbom_components", [])) != len(info["sbom_components"])):
        raise ValueError("Exact reviewed legal package SBOM components differ: " + key)
    if row.get("notice_coverage") != "present":
        raise ValueError("Exact reviewed legal package coverage is required: " + key)
    require_final_disposition(row, local_test_only=review.get("local_test_only") is True)
    return row


def _checked_packet(review, publisher, app, publisher_legal, app_legal,
                    source_bytes, receipt_bytes, bundle_bytes, local_test_only,
                    additional_available_paths=()):
    if review.get("schema_version") != 1 or not review.get("reviewer"):
        raise ValueError("Exact attributable review packet is required")
    if local_test_only != (review.get("local_test_only") is True):
        raise ValueError("Local-test mode and review packet differ")
    require_final_disposition(review, local_test_only=local_test_only)
    if (review.get("publisher_wheel_sha256") != publisher["sha256"]
            or review.get("app_wheel_sha256") != app["sha256"]
            or review.get("publisher_source_sha256") != sha(source_bytes)
            or review.get("app_build_receipt_sha256") != sha(receipt_bytes)
            or review.get("app_source_bundle_sha256") != sha(bundle_bytes)):
        raise ValueError("Exact review packet input identity differs")
    _review_row(review, "publisher_legal_row", publisher, publisher_legal)
    _review_row(review, "app_legal_row", app, app_legal)
    components = publisher["sbom_components"] + app["sbom_components"]
    decisions = review.get("component_dispositions")
    if not isinstance(decisions, list) or len(decisions) != len(components) or (
        {item.get("bom_ref") for item in decisions} != {item["bom_ref"] for item in components}
    ):
        raise ValueError("Exact component dispositions differ from new wheel SBOMs")
    source = review.get("publisher_source")
    if not isinstance(source, dict) or not source.get("url", "").startswith("https://") or (
        source.get("sha256") != sha(source_bytes) or source.get("bytes") != len(source_bytes)
    ):
        raise ValueError("Exact publisher source association is required")
    if not re.fullmatch(r"pillow-[0-9][A-Za-z0-9.]*\.tar\.gz", source.get("filename", "")):
        raise ValueError("Exact publisher source filename is required")
    notices = _source_notices(source_bytes, review.get("publisher_source_notices"))
    if set(review["publisher_legal_row"].get("source_legal_paths", [])) != set(notices):
        raise ValueError("Exact publisher source notice legal mapping differs")
    available_paths = (set(notices)
                       | set(review["publisher_legal_row"].get("verified_sidecar_copies", []))
                       | set(review["app_legal_row"].get("verified_sidecar_copies", []))
                       | set(additional_available_paths))
    if not local_test_only:
        _require_supplementary_notice_mappings(decisions, available_paths)
    with tarfile.open(fileobj=io.BytesIO(source_bytes), mode="r:gz") as archive:
        source_members = {member.name for member in archive.getmembers() if member.isfile()}
    for item in decisions:
        require_final_disposition(item, local_test_only=local_test_only)
        if not local_test_only:
            component = next(component for component in components
                             if component["bom_ref"] == item["bom_ref"])
            _require_component_identity(item, component)
            _require_raqm_notice_mapping(item, available_paths)
            _require_component_source_scope(item, source, source_members)
            _require_final_component_state(item, available_paths)


def _update_packet_rows(packet, replacements, prefix):
    files = {row["path"]: row for row in packet["files"] if not row["path"].startswith(prefix)}
    for name, data in replacements.items():
        if name.startswith(PACKET_PREFIX) and name != "notices-and-source/sbom-packet-manifest.json":
            files[name] = {"path": name, "bytes": len(data), "sha256": sha(data)}
    packet["files"] = [files[name] for name in sorted(files)]
    packet["file_count"] = len(files)


def local_test_review_from_evidence(*, base, technical_evidence, publisher_wheel,
                                    publisher_source, app_wheel, app_receipt, app_bundle):
    """Make a provisional producer inventory solely for installed-path tests.

    This is intentionally not a review decision. Final mode rejects it.
    """
    evidence_raw = _exact_file(technical_evidence)
    evidence = json.loads(evidence_raw)
    validator = _validator()
    publisher = validator.verify_wheel(publisher_wheel)
    app = validator.verify_wheel(app_wheel)
    if (evidence.get("artifacts", {}).get("wheel", {}).get("sha256") != publisher["sha256"]
            or evidence.get("artifacts", {}).get("sdist", {}).get("sha256") != sha(publisher_source.read_bytes())
            or evidence.get("wheel_checks", {}).get("record_verification_errors") != []
            or evidence.get("wheel_checks", {}).get("sbom_component_count") != len(publisher["sbom_components"])):
        raise ValueError("Exact technical evidence differs from selected Pillow bytes")
    source = evidence["artifacts"]["sdist"]
    wheel = evidence["artifacts"]["wheel"]
    route = {"package": "pillow", "version": publisher["version"],
             "filename": publisher["filename"], "tags": ["-".join(publisher_wheel.stem.split("-")[-3:])],
             "bytes": publisher["bytes"], "sha256": publisher["sha256"],
             "url": wheel["pypi_url"], "publisher_identity": "PyPI project pillow",
             "delivery_policy": "publisher",
             "pypi_project_url": "https://pypi.org/project/pillow/" + publisher["version"] + "/"}
    validator.validate_publisher_delta(publisher_wheel, route)
    with zipfile.ZipFile(base) as archive:
        _verify_manifest(archive)
        legal = json.loads(archive.read("notices-and-source/legal-index.json"))
    base_app = next(row for row in legal["packages"] if row["normalized_name"] == "autoclip")
    _, publisher_legal = _wheel_members(publisher_wheel, publisher)
    app_names, app_legal = _wheel_members(app_wheel, app)
    publisher_row = {
        "normalized_name": publisher["name"], "version": publisher["version"],
        "filename": publisher["filename"], "tags": route["tags"],
        "bytes": publisher["bytes"], "sha256": publisher["sha256"],
        "record_rows": publisher["record_rows"],
        "license_expression": publisher["license_expression"],
        "declared_license_files": [item["path"].split("/licenses/", 1)[1]
                                   for item in publisher["legal_files"]],
        "legal_files": sorted(publisher_legal), "legal_sha256": publisher_legal,
        "sbom_files": [item["path"] for item in publisher["sbom_files"]],
        "sbom_components": [{"name": item["name"], "version": item["version"],
                             "purl": item["purl"], "license_expressions": [
                                 entry.get("expression") or entry.get("license", {}).get("id")
                                 for entry in item["licenses"] if isinstance(entry, dict)],
                             "evidence": publisher["sbom_files"][0]["path"],
                             "relationship": "SBOM-declared; incorporation not established"}
                            for item in publisher["sbom_components"]],
        "notice_coverage": "present", "research_class": "PROVISIONAL_LOCAL_TEST",
        "review_disposition": "pending_exact_component_notice_and_incorporation_review",
        "release_clearance": "not asserted", "delivery_policy": "publisher",
        "verified_sidecar_copies": ["notices-and-source/wheel-notices/" + publisher["filename"] + "/" + n
                                    for n in sorted(publisher_legal)],
        "fulfillment_locations": ["notices-and-source/wheel-notices/" + publisher["filename"] + "/" + n
                                  for n in sorted(publisher_legal)],
        "technical_evidence_sha256": sha(evidence_raw),
        "source_legal_paths": ["notices-and-source/source-notices/" + name
                               for name in sorted(evidence.get("sdist_legal_references", {}))],
        "disposition": LOCAL_TEST,
    }
    with zipfile.ZipFile(publisher_wheel) as publisher_archive:
        native_names = sorted(name for name in publisher_archive.namelist()
                              if name.lower().endswith((".pyd", ".dll")))
        publisher_row["native_files"] = native_names
        publisher_row["native_sha256"] = {
            name: sha(publisher_archive.read(name)) for name in native_names}
        publisher_row["data_assets"] = []
        publisher_row["data_sha256"] = {}
    app_row = dict(base_app)
    app_row.update(bytes=app["bytes"], sha256=app["sha256"], record_rows=app["record_rows"],
                   legal_files=sorted(app_legal), legal_sha256=app_legal,
                   sbom_files=[item["path"] for item in app["sbom_files"]],
                   sbom_components=[{"name": item["name"], "version": item["version"],
                                     "purl": item["purl"], "evidence": app["sbom_files"][0]["path"]}
                                    for item in app["sbom_components"]],
                   verified_sidecar_copies=["notices-and-source/wheel-notices/" + app["filename"] + "/" + n
                                            for n in sorted(app_legal)],
                   fulfillment_locations=["notices-and-source/wheel-notices/" + app["filename"] + "/" + n
                                          for n in sorted(app_legal)],
                   review_disposition="pending_exact_new_app_notice_review",
                   release_clearance="not asserted", disposition=LOCAL_TEST)
    with zipfile.ZipFile(app_wheel) as wheel_archive:
        data_assets = [name for name in app_names if (
            name.startswith("autoclip/static/") or name.startswith("autoclip/assets/fonts/"))
            and not name.endswith("/")]
        app_row["data_assets"] = sorted(data_assets)
        app_row["data_sha256"] = {name: sha(wheel_archive.read(name)) for name in data_assets}
    component_evidence = {row["bom_ref"]: row for row in evidence.get("components", [])}
    if set(component_evidence) != {row["bom_ref"] for row in publisher["sbom_components"]}:
        raise ValueError("Technical evidence component set differs")
    source_path = "notices-and-source/sbom-sources/" + publisher_source.name
    license_paths = ["notices-and-source/wheel-notices/" + publisher["filename"] + "/" + n
                     for n in sorted(publisher_legal)]
    decisions = []
    for component in publisher["sbom_components"]:
        prior = component_evidence[component["bom_ref"]]
        plan_row = {
            "wheel": publisher["filename"], "wheel_sha256": publisher["sha256"],
            "name": component["name"], "version": component["version"],
            "purl": component["purl"], "sbom_evidence": publisher["sbom_files"][0]["path"],
            "relationship": "SBOM declared; Windows incorporation scoped by technical evidence",
            "expressions": [], "notice_status": "pending_exact_independent_disposition",
            "source_url": source["pypi_url"], "source_sha256": source["sha256"],
            "installed_legal_paths": license_paths, "installed_source_path": source_path,
            "technical_assessment": prior.get("assessment"),
        }
        index_row = {
            "wheel": publisher["filename"], "wheel_sha256": publisher["sha256"],
            "purl": component["purl"], "selected_expressions": [],
            "source_url": source["pypi_url"], "source_sha256": source["sha256"],
            "installed_legal_paths": license_paths, "installed_source_path": source_path,
            "state": "pending_independent_review",
            "relationship": "Conservative SBOM declaration, not incorporation proof",
        }
        decisions.append({"bom_ref": component["bom_ref"], "disposition": LOCAL_TEST,
                          "technical_evidence": prior, "plan_row": plan_row, "index_row": index_row})
    return {
        "schema_version": 1, "reviewer": "Automated producer technical inventory; no independent approval",
        "disposition": LOCAL_TEST, "local_test_only": True,
        "publisher_route": route, "publisher_wheel_sha256": publisher["sha256"],
        "app_wheel_sha256": app["sha256"], "publisher_source_sha256": source["sha256"],
        "publisher_source": {"filename": source["filename"], "url": source["pypi_url"],
                             "bytes": source["bytes"], "sha256": source["sha256"]},
        "publisher_source_notices": evidence.get("sdist_legal_references", {}),
        "app_build_receipt_sha256": sha(app_receipt.read_bytes()),
        "app_source_bundle_sha256": sha(app_bundle.read_bytes()),
        "technical_evidence_sha256": sha(evidence_raw),
        "publisher_legal_row": publisher_row, "app_legal_row": app_row,
        "component_dispositions": decisions,
        "limits": ["Unpublishable local installer/updater qualification only",
                   "Pillow wheel/source incorporation and notices await independent review",
                   "RAQM compiled extension notice requires specific disposition"],
    }


def build(*, base, expected_base, publisher_wheel, publisher_route, publisher_source,
          app_wheel, app_receipt, app_bundle, review, release_id, output, installer,
          base_installer=None, expected_base_installer=None, local_test_only=False,
          native_script=None, expected_native_script=None, native_commit=None,
          runtime_repo=None):
    """Build only after validating all inputs; no asset is written on preflight failure."""
    require_final_disposition(review, local_test_only=local_test_only)
    require_new_outputs(output, installer)
    pillow_notices = _pillow_notice_inputs()
    child_inventory_raw = _pillow_child_inventory(pillow_notices)
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{8,120}", release_id):
        raise ValueError("Unique successor release ID is required")
    if not base_installer or not expected_base_installer:
        raise ValueError("Exact base standalone installer is required")
    if not local_test_only and native_script is None:
        raise ValueError("Final successor requires committed native build source")
    native_raw = None
    if native_script is not None:
        if not expected_native_script:
            raise ValueError("Exact native build source hash is required")
        native_raw = _exact_file(native_script, expected_sha=expected_native_script)
        if not local_test_only and not native_commit:
            raise ValueError("Committed native build source association is required")
        if native_commit:
            if not re.fullmatch(r"[0-9a-f]{40}", native_commit) or not runtime_repo:
                raise ValueError("Committed native build source association is required")
            committed = subprocess.check_output([
                "git", "show", native_commit + ":release/scripts/build-native-from-source.ps1"],
                cwd=runtime_repo)
            if committed != native_raw:
                raise ValueError("Committed native build source differs from archived bytes")
    base_raw = _exact_file(base, expected_sha=expected_base)
    base_install_raw = _exact_file(base_installer, expected_sha=expected_base_installer)
    validator = _validator()
    publisher = validator.validate_publisher_delta(publisher_wheel, publisher_route)
    if review.get("publisher_route") != publisher_route:
        raise ValueError("Exact reviewed publisher route differs")
    if publisher["name"] != "pillow":
        raise ValueError("Only the exact Pillow dependency delta is supported")
    receipt_raw = _exact_file(app_receipt)
    receipt = json.loads(receipt_raw)
    app = validator.validate_app_build_receipt_consistency(
        app_wheel, {"app_commit": receipt.get("app_commit"),
                    "app_wheel_sha256": receipt.get("app_wheel_sha256"),
                    "build_receipt_path": app_receipt.name,
                    "build_receipt_sha256": sha(receipt_raw)},
        lambda name: receipt_raw if name == app_receipt.name else b"",
    )
    _app_requires_pillow(app_wheel, publisher["version"])
    bundle_raw = _exact_file(app_bundle, expected_sha=receipt.get("app_source_bundle_sha256"))
    source_raw = _exact_file(publisher_source)
    _, publisher_legal = _wheel_members(publisher_wheel, publisher)
    _, app_legal = _wheel_members(app_wheel, app)
    with zipfile.ZipFile(io.BytesIO(base_raw)) as base_archive:
        base_paths = set(base_archive.namelist())
    delivered_pillow_paths = {
        PILLOW_EVIDENCE_PREFIX + name for name in pillow_notices
    }
    _checked_packet(review, publisher, app, publisher_legal, app_legal,
                    source_raw, receipt_raw, bundle_raw, local_test_only,
                    base_paths | delivered_pillow_paths)
    if not local_test_only:
        with zipfile.ZipFile(app_wheel) as app_archive:
            members = set(app_archive.namelist())
            fonts = {name: app_archive.read(name) for name in members
                     if name.lower().endswith((".ttf", ".otf", ".woff", ".woff2"))}
            ofl_notices = {name: app_archive.read(name) for name in members
                           if name.lower().endswith("-ofl.txt")}
        _refresh_app_font_summary(review["app_legal_row"], fonts, ofl_notices)
    with zipfile.ZipFile(io.BytesIO(base_raw)) as original:
        manifest = _verify_manifest(original)
        old_app = next((name for name in original.namelist()
                        if name.startswith("wheelhouse/autoclip-") and name.endswith(".whl")), None)
        if old_app is None or publisher["filename"] in [row["filename"] for row in manifest["publisher_wheels"]]:
            raise ValueError("Base app or publisher delta identity differs")
        legal = json.loads(original.read("notices-and-source/legal-index.json"))
        if (len(legal["publisher_wheels"]) != 74 or len(legal["packages"]) != 75
                or sum(row["normalized_name"] == "autoclip" for row in legal["packages"]) != 1):
            raise ValueError("Base legal publisher/app inventory differs")
        if manifest["publisher_wheels"] != legal["publisher_wheels"]:
            raise ValueError("Base publisher identities differ")
        old_app_name = old_app.split("/", 1)[1]
        if app["filename"] != old_app_name:
            raise ValueError("New app wheel filename differs from replaceable base path")
        # Publisher wheels are staged by Prepare-AutoClipOfflineCache.ps1 into
        # publisher-wheels/cpu. Keeping Pillow in wheelhouse as well makes the
        # installer pass two copies to verify-install-wheels.py, which requires
        # unique wheel filenames across all install locations.
        changes = {old_app: app_wheel.read_bytes()}
        if original.namelist().count("LICENSES.md") != 1:
            raise ValueError("Base recipient LICENSES.md entry point is missing or duplicated")
        pillow_notice_paths = {
            PILLOW_EVIDENCE_PREFIX + name for name in pillow_notices
        }
        if pillow_notice_paths & set(original.namelist()):
            raise ValueError("Base archive already contains a Pillow notice delivery path")
        changes["LICENSES.md"] = _link_pillow_notices(
            original.read("LICENSES.md"), pillow_notices)
        changes.update({PILLOW_EVIDENCE_PREFIX + name: raw
                        for name, raw in pillow_notices.items()})
        child_inventory_path = PILLOW_EVIDENCE_PREFIX + "components.json"
        changes["notices-and-source/MANIFEST.md"] = (
            original.read("notices-and-source/MANIFEST.md") +
            ("\n\n## Pillow 12.3.0 AVIF child inventory\n\n"
             f"See `{child_inventory_path}` for exact AOM, dav1d, libyuv and "
             "libsharpyuv source and notice identities. `legal-index.json` binds "
             "that inventory to the selected Pillow wheel. Incorporation, "
             "source fulfillment and legal review remain unresolved.\n").encode("utf-8"))
        installer_source_snapshot = (
            "notices-and-source/build-provenance/current/install-source-build.ps1")
        if original.read("install-source-build.ps1") != original.read(installer_source_snapshot):
            raise ValueError("Historical archive installer source snapshot differs")
        internal_stub = _disabled_archive_installer(release_id, output.name, installer.name)
        changes["install-source-build.ps1"] = internal_stub
        if native_raw is not None:
            snapshot = "notices-and-source/build-provenance/current/build-native-from-source.ps1"
            if original.read(snapshot) != original.read("build-native-from-source.ps1"):
                raise ValueError("Base native source snapshot differs")
            changes["build-native-from-source.ps1"] = native_raw
            changes[snapshot] = native_raw
        old_app_prefix = "notices-and-source/wheel-notices/" + old_app_name + "/"
        remove = {name for name in original.namelist() if name.startswith(old_app_prefix)}
        for wheel, info, legal_hashes in ((publisher_wheel, publisher, publisher_legal),
                                          (app_wheel, app, app_legal)):
            with zipfile.ZipFile(wheel) as source_wheel:
                for member, digest in legal_hashes.items():
                    content = source_wheel.read(member)
                    if sha(content) != digest:
                        raise ValueError("Wheel legal sidecar changed")
                    changes["notices-and-source/wheel-notices/" + info["filename"] + "/" + member] = content
        source_name = "notices-and-source/sbom-sources/" + publisher_source.name
        if publisher_source.name != review["publisher_source"]["filename"]:
            raise ValueError("Publisher source filename differs")
        changes[source_name] = source_raw
        changes.update(_source_notices(source_raw, review["publisher_source_notices"]))
        source_artifacts = json.loads(original.read(
            "notices-and-source/source-and-build/source-artifact-manifest.json"))
        source_artifacts["artifacts"].append({
            "owner": publisher["name"] + "-" + publisher["version"],
            "component": "Pillow source distribution, Pillow-owned code, and vendored source context",
            "relationship": "Pillow build/source context; not complete source for external native components",
            "filename": publisher_source.name,
            "url": review["publisher_source"]["url"],
            "bytes": len(source_raw), "sha256": sha(source_raw),
            "installed_path": source_name,
        })
        changes["notices-and-source/source-and-build/source-artifact-manifest.json"] = encoded(source_artifacts)
        changes["notices-and-source/build-provenance/current/app-build-receipt.json"] = receipt_raw
        changes["notices-and-source/build-provenance/current/app-source.bundle"] = bundle_raw
        changes["notices-and-source/review/dependency-app-review.json"] = encoded(review)
        old_app_row = next(row for row in legal["packages"] if row["normalized_name"] == "autoclip")
        legal["packages"] = [row for row in legal["packages"] if row is not old_app_row]
        legal["packages"].extend([review["publisher_legal_row"], review["app_legal_row"]])
        legal["packages"].sort(key=lambda row: row["normalized_name"])
        legal["wheel_count"] = len(legal["packages"])
        legal["publisher_wheels"].append(publisher_route)
        legal["publisher_wheels"].sort(key=lambda row: row["filename"])
        legal["pillow_child_components"] = {
            "path": child_inventory_path,
            "sha256": sha(child_inventory_raw),
            "pillow_wheel_sha256": publisher["sha256"],
            "avif_component_bom_ref": "pkg:pypi/pillow@12.3.0#c-ext/PIL._avif",
            "review_state": "unresolved",
        }
        legal["native_build"]["app_commit"] = receipt["app_commit"]
        if native_raw is not None:
            legal["native_build"]["build_script_sha256"] = sha(native_raw)
            if native_commit:
                legal["native_build"]["runtime_commit"] = native_commit
                legal["runtime_commit"] = native_commit
        legal["decision"] = ("UNPUBLISHABLE_LOCAL_TEST_ONLY; pending independent dependency/app review"
                             if local_test_only else "Exact dependency/app review packet attached; release acceptance separate")
        changes["notices-and-source/legal-index.json"] = encoded(legal)
        plan = json.loads(original.read("notices-and-source/sbom-component-plan.json"))
        index = json.loads(original.read("notices-and-source/sbom-component-index.json"))
        for item in review["component_dispositions"]:
            matches = [c for c in publisher["sbom_components"] + app["sbom_components"]
                       if c["bom_ref"] == item["bom_ref"]]
            if len(matches) != 1:
                raise ValueError("Reviewed component identity differs")
            if not item.get("plan_row") or not item.get("index_row"):
                raise ValueError("Exact component plan/index rows are required")
            plan["components"].append(item["plan_row"])
            index["components"].append(item["index_row"])
        plan["component_count"] = len(plan["components"])
        index["component_count"] = len(index["components"])
        changes["notices-and-source/sbom-component-plan.json"] = encoded(plan)
        changes["notices-and-source/sbom-component-index.json"] = encoded(index)
        packet = json.loads(original.read("notices-and-source/sbom-packet-manifest.json"))
        _update_packet_rows(packet, changes, old_app_prefix)
        changes["notices-and-source/sbom-packet-manifest.json"] = encoded(packet)
        provenance = json.loads(original.read("notices-and-source/build-provenance.json"))
        provenance.update(construction_base_archive_sha256=expected_base,
                          app_wheel_sha256=app["sha256"],
                          dependency_app_successor={
                              "release_id": release_id,
                              "publisher_wheel_sha256": publisher["sha256"],
                              "publisher_source_sha256": sha(source_raw),
                              "app_source_commit": receipt["app_commit"],
                              "app_source_bundle_sha256": sha(bundle_raw),
                              "review_sha256": sha(changes["notices-and-source/review/dependency-app-review.json"]),
                              "publication_state": "UNPUBLISHABLE_LOCAL_TEST_ONLY" if local_test_only else "reviewed_unpublished",
                              "archive_root_installer": {
                                  "state": "disabled_non_entrypoint_stub",
                                  "sha256": sha(internal_stub),
                                  "historical_source_snapshot_sha256": sha(original.read(installer_source_snapshot)),
                                  "companion_standalone_filename": installer.name,
                              },
                          })
        if native_raw is not None:
            provenance["dependency_app_successor"]["native_build_script_sha256"] = sha(native_raw)
            if local_test_only:
                provenance["source_state"] = (
                    "local_test_committed_native_script_override" if native_commit
                    else "local_test_uncommitted_native_script_override")
                provenance.setdefault("committed_source_sha256", {}).pop(
                    "build-native-from-source.ps1", None)
                provenance["local_test_source_overrides"] = {
                    "build-native-from-source.ps1": sha(native_raw)}
            else:
                provenance["source_state"] = "committed_runtime_source"
                provenance["runtime_commit"] = native_commit
                provenance.setdefault("committed_source_sha256", {})[
                    "build-native-from-source.ps1"] = sha(native_raw)
        changes["notices-and-source/build-provenance.json"] = encoded(provenance)
        manifest["publisher_wheels"].append(publisher_route)
        manifest["publisher_wheels"].sort(key=lambda row: row["filename"])
        publisher_manifest = json.loads(original.read("publisher-wheel-manifest.json"))
        if publisher_manifest["wheels"] != [row for row in manifest["publisher_wheels"]
                                                    if row["filename"] != publisher["filename"]]:
            raise ValueError("Base publisher manifest differs")
        publisher_manifest["wheels"] = manifest["publisher_wheels"]
        changes["publisher-wheel-manifest.json"] = encoded(publisher_manifest)
        manifest["native_build"]["app_commit"] = receipt["app_commit"]
        if native_raw is not None:
            manifest["native_build"]["build_script_sha256"] = sha(native_raw)
            if native_commit:
                manifest["native_build"]["runtime_commit"] = native_commit
        inventory = json.loads(original.read("distribution-inventory.json"))
        inventory["publisher_wheels"] = [row["filename"] for row in manifest["publisher_wheels"]]
        inventory["publisher_wheel_identities"] = manifest["publisher_wheels"]
        inventory["publisher_wheel_count"] = 75
        inventory["native_build"] = manifest["native_build"]
        changes["distribution-inventory.json"] = encoded(inventory)
        files = {row["path"]: row for row in manifest["files"] if row["path"] not in remove}
        for name, raw in changes.items():
            files[name] = {"path": name, "bytes": len(raw), "sha256": sha(raw)}
        manifest["files"] = [files[name] for name in sorted(files)]
        changes["release-manifest.json"] = encoded(manifest)
        template = base_install_raw.decode("utf-8-sig")
        old_id = re.search(r"(?m)^\$releaseId = '([^']+)'\r?$", template)
        if old_id is None or old_id.group(1) == release_id:
            raise ValueError("Base standalone release ID differs")
        old_archive = re.search(r"(?m)^\$expectedArchiveSha256 = '([0-9a-f]{64})'\r?$", template)
        old_manifest = re.search(r"(?m)^\$expectedManifestSha256 = '([0-9a-f]{64})'\r?$", template)
        if (old_archive is None or old_archive.group(1) != expected_base
                or old_manifest is None or old_manifest.group(1) != sha(original.read("release-manifest.json"))):
            raise ValueError("Base standalone pins differ")
        output.parent.mkdir(parents=True, exist_ok=True)
        installer.parent.mkdir(parents=True, exist_ok=True)
        try:
            with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as target:
                for member in original.infolist():
                    if member.filename not in remove:
                        target.writestr(member, changes.pop(member.filename, original.read(member.filename)))
                for name, raw in sorted(changes.items()):
                    target.writestr(name, raw)
            new_archive_sha = sha(output.read_bytes())
            installer.write_bytes(_standalone_from_base(
                base_install_raw, expected_base, old_manifest.group(1), old_id.group(1),
                new_archive_sha, sha(encoded(manifest)), release_id,
                local_test_only=local_test_only,
                native_cache_key=_native_cache_key(
                    native_raw if native_raw is not None else original.read(
                        "build-native-from-source.ps1"), manifest)))
            with zipfile.ZipFile(output) as target:
                _verify_manifest(target, publisher_count=75)
                if len(target.read("notices-and-source/sbom-packet-manifest.json")) == 0:
                    raise ValueError("Auxiliary packet is absent")
                for row in packet["files"]:
                    raw = target.read(row["path"])
                    if len(raw) != row["bytes"] or sha(raw) != row["sha256"]:
                        raise ValueError("Auxiliary packet hash differs: " + row["path"])
            return {"release_id": release_id, "archive_sha256": new_archive_sha,
                    "manifest_sha256": sha(encoded(manifest)), "installer_sha256": sha(installer.read_bytes()),
                    "publication_state": provenance["dependency_app_successor"]["publication_state"]}
        except Exception:
            output.unlink(missing_ok=True)
            installer.unlink(missing_ok=True)
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("base", "base-installer", "publisher-wheel", "publisher-source",
                 "app-wheel", "app-receipt", "app-bundle", "output", "installer"):
        parser.add_argument("--" + name, required=True, type=Path)
    parser.add_argument("--review", type=Path,
                        help="Attributable exact review packet for a final unpublished candidate")
    parser.add_argument("--technical-evidence", type=Path,
                        help="Producer evidence; only accepted with --local-test-only")
    for name in ("expected-base", "expected-base-installer", "release-id"):
        parser.add_argument("--" + name, required=True)
    parser.add_argument("--local-test-only", action="store_true")
    parser.add_argument("--native-script", type=Path)
    parser.add_argument("--expected-native-script")
    parser.add_argument("--native-commit")
    parser.add_argument("--runtime-repo", type=Path)
    args = vars(parser.parse_args())
    if args["review"] is not None and args["technical_evidence"] is not None:
        parser.error("Provide one review input route")
    if args["technical_evidence"] is not None:
        if not args["local_test_only"]:
            parser.error("Technical producer evidence requires --local-test-only")
        args["review"] = local_test_review_from_evidence(
            base=args["base"], technical_evidence=args.pop("technical_evidence"),
            publisher_wheel=args["publisher_wheel"], publisher_source=args["publisher_source"],
            app_wheel=args["app_wheel"], app_receipt=args["app_receipt"],
            app_bundle=args["app_bundle"])
    else:
        args.pop("technical_evidence")
        if args["review"] is None:
            parser.error("An exact review packet is required")
        args["review"] = json.loads(args["review"].read_bytes())
    args["publisher_route"] = args["review"].get("publisher_route", {})
    result = build(**{key.replace("-", "_"): value for key, value in args.items()})
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
