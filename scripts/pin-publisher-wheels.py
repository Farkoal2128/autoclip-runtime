"""Resolve reviewed wheel hashes to immutable PyPI file URLs for candidate preparation.

This is a build-time evidence step. Installation uses the generated manifest only.
"""

import argparse
import concurrent.futures
import json
import urllib.request
from pathlib import Path


def resolve(row: dict) -> dict:
    name, version, filename = row["normalized_name"], row["version"], row["filename"]
    request = urllib.request.Request(
        f"https://pypi.org/pypi/{name}/{version}/json",
        headers={"Accept": "application/json", "User-Agent": "AutoClip-release-pin/1"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        metadata = json.load(response)
    matches = [item for item in metadata["urls"] if item["filename"] == filename]
    if len(matches) != 1:
        raise ValueError(f"Exact wheel missing from PyPI: {filename}")
    item = matches[0]
    if item["size"] != row["bytes"] or item["digests"]["sha256"] != row["sha256"]:
        raise ValueError(f"PyPI identity differs from reviewed bytes: {filename}")
    if not item["url"].startswith("https://files.pythonhosted.org/"):
        raise ValueError(f"Unexpected PyPI file host: {filename}")
    stem = filename.removesuffix(".whl")
    tags = stem.rsplit("-", 3)[1:]
    pinned = {
        "package": name, "version": version, "filename": filename,
        "tags": ["-".join(tags)], "bytes": row["bytes"], "sha256": row["sha256"],
        "url": item["url"], "publisher_identity": f"PyPI project {name}",
        "delivery_policy": "publisher",
        "pypi_project_url": f"https://pypi.org/project/{name}/{version}/",
    }
    if name == "numpy":
        provenance_url = f"https://pypi.org/integrity/{name}/{version}/{filename}/provenance"
        with urllib.request.urlopen(provenance_url, timeout=30) as response:
            provenance = json.load(response)
        bundles = provenance.get("attestation_bundles", [])
        if not bundles:
            raise ValueError("Expected NumPy PyPI provenance is absent")
        pinned["pypi_provenance_url"] = provenance_url
        pinned["pypi_trusted_publisher"] = bundles[0]["publisher"]
        pinned["provenance_note"] = "PyPI reported attestation; signature verification remains a separate gate"
    return pinned


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("audit", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    audit = json.loads(args.audit.read_text(encoding="utf-8"))
    rows = [row for row in audit["packages"] if row["normalized_name"] != "autoclip"]
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        entries = list(pool.map(resolve, rows))
    args.output.write_text(json.dumps({"schema_version": 1, "source_audit_sha256":
        audit["candidate_archive_sha256"], "wheels": entries}, indent=2) + "\n", encoding="utf-8")
    print(f"Pinned {len(entries)} exact PyPI wheels")


if __name__ == "__main__":
    main()
