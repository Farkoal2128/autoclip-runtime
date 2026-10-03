# IM-MS-08: Python extraction of the pinned MSYS2 base

Status: bounded extractor and synthetic/exact-archive behavioral verification
implemented. Parent integration, native executable-mode qualification, detached
signature verification and initialization remain separate required work.

## Authorization, requirement and contract

Parent authorizes only `installer/extract-msys2-base.py`,
`.github/tests/test_msys2_base_archive.py`, and this work order. Other writers
own the dependency manifest, downloader, package helper, Inno, build/bootstrap,
and VM. Those files were not changed by this assignment.

The [archive boundary](../contract-v1.md#msys2-archive-provisioning-boundary)
and [IM-MS-07 Python follow-up](IM-MS-07.md#follow-up-use-the-already-required-python-then-verify-the-tar-signature)
require exact Python 3.11.9 x64, setup-bound manifest authentication, validated
manual extraction of the single `msys64` tree, and full inventory verification
before archive-delivered native execution. Runtime activation and immutable
release policy remain governed by [the architecture](../../runtime-update-architecture.md).
No schema or canonical dependency classification changes were made here.

## Interface and minimum implementation

```powershell
<verified-python.exe> -I -B installer/extract-msys2-base.py --manifest <manifest.json> --manifest-sha256 <setup-bound-lowercase-sha256> --archive <msys2-base-x86_64-20260611.tar.xz> --parent <existing-empty-owned-parent>
```

Module APIs: `extract_base(manifest_path, manifest_sha256, archive_path, parent)`
returns the receipt; `verify_inventory(parent, inventory)` rechecks the entire
tree without executing it. `ExtractionFailure.receipt` preserves the failure
state. CLI writes receipt JSON to stdout, errors to stderr, and returns 0 only
for verified extraction, otherwise 1. The caller must durably capture this
receipt and register ownership before work; forced process termination cannot
guarantee delivery of a final JSON receipt.

Authenticate raw manifest bytes with the supplied setup hash, reject duplicate
JSON fields, require schema 1 and exactly one case-unambiguous `MSYS2` row.
The row must be `DIRECT_RECIPIENT_DOWNLOAD`, version `20260611`,
`artifact_kind: archive`, `archive_format: tar.xz`, the exact official filename
and release-tagged URL from IM-MS-02. Actual size/SHA come from that authenticated
row. Synthetic test manifests intentionally pin their own tiny fixtures;
those test-only rows do not amend the canonical BLOCKED production manifest.

The parent must already exist, be empty, have a short ASCII absolute local
fixed-drive Windows path, and contain no reparse ancestor. The future isolated
agent browser socket including NUL must fit 108 bytes, as established by
[IM-MS-06](IM-MS-06.md). Protected ACLs, absence of drive substitution, physical
filesystem qualification and ownership registration belong to parent
orchestration. `GetDriveTypeW` rejects mapped/network/removable drives; it is
not a complete substitute for those orchestration checks.

Keep the authenticated archive file open. Check size/SHA before parsing and
after copying; recheck unchanged manifest bytes. Inspect every logical TAR
member before creating `msys64`: allow only regular files/directories; reject
links, devices, sparse/PAX-sparse entries, unsupported types, traversal,
absolute/alternate paths, Windows-invalid/reserved names, missing/conflicting
parents, duplicate/case-colliding paths and anything outside `msys64`.
Bounds from the exact audit are 16,581 members, 288,055,390 total content bytes
and 12,326,813 bytes for any one file. These are fail-closed ceilings, not a
second authentication source.

Create directories exclusively, copy only `extractfile()` regular streams to
exclusive `xb` files, bound reads to declared size, hash the archive stream
while copying, and apply its requested permission bits and timestamps. File
order is retained to avoid repeatedly decompressing XZ for backward seeks.
Then independently read every extracted file, compare size/hash/type/name to
the archive-derived inventory, and reject extra/missing files or directories
anywhere under the extraction parent. No separate vendor inventory payload is
required. No archive ownership, group, symlink, device or cleanup operation is
applied, and no native binary/script, downloader or key initialization runs.

Receipt contains the complete derived inventory (paths, kinds, modes and file
sizes/hashes), manifest/archive pins, created `owned_root`, counts, and explicit
`NOT_STARTED`, `PARTIAL` or `COMPLETE` extraction state. A failure preserves all
created output for the caller's ownership-based recovery; it never deletes a
shared, foreign or partial tree. An inventory by itself cannot authenticate a
different archive or authorize native execution.

## Windows executable-mode evidence limit

[Python tarfile](https://docs.python.org/3.11/library/tarfile.html) documents XZ,
member types and duplicate archive names.
[Python os.chmod](https://docs.python.org/3.11/library/os.html#os.chmod) documents
that Windows applies read-only state and ignores other permission bits. The
implementation does not use extraction filters/backports or `extractall()`;
the actual executed interpreter was 3.11.9, while current 3.11 documentation
also describes newer patches.

The archive's `pacman-key` requested mode `0755` is retained in the receipt and
passed to `os.chmod`; that does **not** prove MSYS-visible execute permissions
on Windows. Parent explicitly accepted this extraction boundary: its protected
parent grants inherited execute rights, then a fresh guest must observe
`stat`, `test -x`, shebang execution and capability behavior after required
detached-signature verification. Receipt always reports
`executable_mode_qualification: PENDING_NATIVE_WINDOWS_VERIFICATION`,
`acl_verified: false`, `signature_verified: false`, and
`native_initialization_performed: false`. No extra ACL mutation is introduced
in Python. Complete extraction is not complete provisioning.

## RED and GREEN evidence

Tests were written before production code. Executed RED:

```powershell
python -I -B .github/tests/test_msys2_base_archive.py ArchiveTests.test_all_members_validated_before_any_write
```

Expected failure: `FileNotFoundError` for the not-yet-created extraction helper;
the behavioral suite had no implementation to inspect/copy/reject its archives.
An additional receipt-boundary RED used
`python -I -B .github/tests/test_msys2_base_archive.py ArchiveTests.test_malformed_manifest_shapes_return_failure_receipts`:
malformed document/list rows escaped as `AttributeError` rather than the
required `NOT_STARTED` receipt. Minimal document/row type checks made it GREEN.
After minimum implementation, the tests execute the actual TAR parser and
filesystem, including synthetic traversal/reserved/colliding names, sparse and
link/device types, resource limits, setup hash/schema/identity/pin failures,
duplicate JSON, existing foreign destination preservation, junction ancestors,
long/nonlocal paths, full inventory corruption/injected-file rejection,
archive mutation after authenticated read and partial failure/CLI exit receipt.
Only I/O fault injection and verification failure are mocked to exercise
honest partial receipts; normal validation/copy/inventory behavior is real.

Executed GREEN from `D:/Projects/autoclip-runtime` using installed Python
**3.11.9 x64**:

```powershell
python -I -B .github/tests/test_msys2_base_archive.py
$env:AUTOCLIP_TEST_MSYS2_ARCHIVE='D:/AutoClip-Inno-Migration/msys-base-audit/msys2-base-x86_64-20260611.tar.xz'
python -I -B .github/tests/test_msys2_base_archive.py
python -I -B -c "import ast,pathlib;[ast.parse(pathlib.Path(p).read_text()) for p in ['installer/extract-msys2-base.py','.github/tests/test_msys2_base_archive.py']];print('syntax PASS')"
git diff --check
```

Default: 13 tests, 12 PASS and one explicit vendor-fixture opt-in skip. Exact
archive: all 13 PASS. Local vendor archive is 53,555,380 bytes, SHA256
`a2d047e8ee213c3c6a49a8de427eb1069df12207c0422ff1b3cbb5c905c34221`;
it yielded 15,529 regular files and 1,052 directories, all read back and
verified, with 288,055,390 content bytes. Tests use exclusively created short
disposable local roots; vendor bytes are never added to the repository.
Syntax and diff checks PASS (existing unrelated LF/CRLF warnings).

Frozen SHA256:

- Helper: `23307cdbcafd03fb0d03b209cb2dceb35a4e2eed99c2ecfccda9571374fc1596`.
- Test: `b068a368c2e18e992fbb93e310acfa8fb957b7c4dffd7598be921c3905e158ec`.

Remaining evidence: parent protected-parent/DACL acquisition, immediate
pre-execution rehashing, detached signature with separately pinned installer
key, Python-extracted native mode/DLL/initialization/package/source-build
qualification, and complete wizard/lifecycle gates. No blind technical review,
vendor-rights decision, legal approval, publication or release qualification
was performed by this work order.
