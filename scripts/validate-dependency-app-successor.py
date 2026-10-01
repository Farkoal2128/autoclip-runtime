"""Strict input checks for an unpublished dependency-and-app successor.

The v40 review-successor recipe carries legal/SBOM bytes unchanged and assumes
74 publisher wheels. It must not be reused when a new binary wheel is selected.
This module validates new inputs before a future candidate assembly. The build
receipt check establishes only internal consistency: it cannot prove that a
wheel was built from a clean committed tree. That requires separate Git-object
and reproducible-build verification before a successor can be released. This
module does not create an asset or alter public installer/updater pins.
"""

import base64
import csv
import hashlib
import io
import json
import re
import zipfile
from email.parser import BytesParser
from email.policy import default
from pathlib import Path, PurePosixPath


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _safe_members(archive: zipfile.ZipFile) -> list[str]:
    names = archive.namelist()
    if len(names) != len(set(names)):
        raise ValueError("Duplicate wheel members")
    for name in names:
        parts = PurePosixPath(name).parts
        if (not name or name.startswith("/") or "\\" in name
                or ".." in parts or ":" in parts[0]):
            raise ValueError("Unsafe wheel member: " + name)
    return names


def verify_wheel(path: Path) -> dict:
    """Check exact wheel identity, ZIP membership, RECORD and declared evidence."""
    if not path.is_file() or not path.name.endswith(".whl"):
        raise ValueError("Wheel path is missing or invalid")
    filename_parts = path.name[:-4].split("-")
    if len(filename_parts) < 5:
        raise ValueError("Wheel filename is invalid")
    filename_name, filename_version = filename_parts[:2]
    raw = path.read_bytes()
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        names = _safe_members(archive)
        records = [name for name in names if name.endswith(".dist-info/RECORD")]
        if len(records) != 1:
            raise ValueError("Wheel must contain exactly one RECORD")
        dist_info = records[0].split("/", 1)[0]
        metadata_path = dist_info + "/METADATA"
        if metadata_path not in names:
            raise ValueError("Wheel METADATA is missing")
        metadata = BytesParser(policy=default).parsebytes(archive.read(metadata_path))
        name, version = metadata.get("Name"), metadata.get("Version")
        normalize = lambda value: re.sub(r"[-_.]+", "-", value).lower()
        if (not name or not version or normalize(name) != normalize(filename_name)
                or version != filename_version
                or dist_info != f"{filename_name}-{filename_version}.dist-info"):
            raise ValueError("Wheel filename and METADATA identity differ")
        rows = list(csv.reader(io.StringIO(archive.read(records[0]).decode("utf-8"))))
        if len(rows) != len(names) or len({row[0] for row in rows}) != len(rows):
            raise ValueError("Wheel RECORD member set differs")
        if {row[0] for row in rows} != set(names):
            raise ValueError("Wheel RECORD member set differs")
        for member, record_hash, record_size in rows:
            if member == records[0]:
                if record_hash or record_size:
                    raise ValueError("Wheel RECORD self-entry differs")
                continue
            content = archive.read(member)
            expected = "sha256=" + base64.urlsafe_b64encode(
                hashlib.sha256(content).digest()).rstrip(b"=").decode("ascii")
            if record_hash != expected or record_size != str(len(content)):
                raise ValueError("Wheel RECORD hash or size differs: " + member)
        legal_files = []
        for declared in metadata.get_all("License-File", []):
            member = dist_info + "/licenses/" + declared
            if member not in names:
                raise ValueError("Wheel declared license file is missing: " + member)
            legal_files.append({"path": member, "sha256": sha(archive.read(member))})
        sbom_files, components = [], []
        for member in names:
            if not member.startswith(dist_info + "/sboms/") or member.endswith("/"):
                continue
            content = archive.read(member)
            sbom_files.append({"path": member, "sha256": sha(content)})
            if member.endswith(".json"):
                document = json.loads(content)
                if document.get("bomFormat") != "CycloneDX":
                    raise ValueError("Unsupported wheel SBOM")
                declarations = document.get("components")
                if not isinstance(declarations, list):
                    raise ValueError("Wheel SBOM components are missing")
                for component in declarations:
                    bom_ref = component.get("bom-ref")
                    if not bom_ref or bom_ref in {row["bom_ref"] for row in components}:
                        raise ValueError("Wheel SBOM component identity differs")
                    components.append({"bom_ref": bom_ref, "purl": component.get("purl"),
                                       "name": component.get("name"),
                                       "version": component.get("version"),
                                       "licenses": component.get("licenses", [])})
    return {"name": normalize(name), "version": version, "filename": path.name,
            "bytes": len(raw), "sha256": sha(raw),
            "license_expression": metadata.get("License-Expression"),
            "legal_files": legal_files, "sbom_files": sbom_files,
            "sbom_components": components, "record_rows": len(rows)}


def validate_publisher_delta(path: Path, route: dict) -> dict:
    """Require a complete exact PyPI route for the newly selected wheel."""
    info = verify_wheel(path)
    tags = ["-".join(path.name[:-4].split("-")[-3:])]
    if (route.get("package") != info["name"]
            or route.get("version") != info["version"]
            or route.get("filename") != info["filename"]
            or route.get("tags") != tags
            or route.get("bytes") != info["bytes"]
            or route.get("sha256") != info["sha256"]
            or route.get("delivery_policy") != "publisher"
            or not route.get("publisher_identity")
            or not route.get("url", "").startswith("https://files.pythonhosted.org/")):
        raise ValueError("New publisher wheel route differs from exact bytes")
    return info


def validate_app_build_receipt_consistency(app_wheel: Path, evidence: dict,
                                           read_evidence) -> dict:
    """Check a receipt's claimed commit/hash; do not infer actual build provenance."""
    info = verify_wheel(app_wheel)
    revision = evidence.get("app_commit", "")
    path = evidence.get("build_receipt_path", "")
    if (info["name"] != "autoclip"
            or not re.fullmatch(r"[0-9a-f]{40}", revision)
            or evidence.get("app_wheel_sha256") != info["sha256"]
            or not path or not evidence.get("build_receipt_sha256")):
        raise ValueError("Exact app source build receipt is required")
    receipt_bytes = read_evidence(path)
    if sha(receipt_bytes) != evidence["build_receipt_sha256"]:
        raise ValueError("Exact app source build receipt differs")
    receipt = json.loads(receipt_bytes)
    if (receipt.get("app_commit") != revision
            or receipt.get("app_wheel_sha256") != info["sha256"]
            or receipt.get("clean_source") is not True):
        raise ValueError("Exact app source build receipt differs")
    return info


def validate_review_delta(review: dict, publisher: dict | None = None,
                          app_sha: str | None = None) -> None:
    """Fail closed until the new wheel, app notices and SBOM have decisions."""
    if (review.get("schema_version") != 1 or not review.get("reviewer")
            or not review.get("publisher_legal_files")
            or not review.get("app_legal_files")
            or not isinstance(review.get("component_dispositions"), list)):
        raise ValueError("Exact dependency/app review delta is required")
    if publisher is not None:
        components = publisher["sbom_components"]
        dispositions = review["component_dispositions"]
        if (review.get("publisher_wheel_sha256") != publisher["sha256"]
                or review["publisher_legal_files"] != publisher["legal_files"]
                or {row.get("bom_ref") for row in dispositions}
                != {row["bom_ref"] for row in components}
                or len(dispositions) != len(components)
                or any(not row.get("notice_status") or not row.get("license_evidence")
                       for row in dispositions)):
            raise ValueError("Exact publisher review component/notice mapping differs")
    if app_sha is not None and review.get("app_wheel_sha256") != app_sha:
        raise ValueError("Exact app review wheel identity differs")
