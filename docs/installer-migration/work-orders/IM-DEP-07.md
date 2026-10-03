# IM-DEP-07: standalone CPU artifact validation and staging

Date: 2026-10-02. Parent explicitly authorized a minimal consumer validator/stager
under `cpu-native-artifact-v1.md`. Owned only these new files:

- `installer/install-cpu-native-artifact.py`
- `.github/tests/test_cpu_native_install.py`
- `docs/installer-migration/work-orders/IM-DEP-07.md`

Root owns manifest, PowerShell and Inno integration and qualification. No existing
producer, helper, test, source packet, manifest or integration file was edited.
No network, vendor action, native execution, installation, acceptance or
qualification occurred in this assignment.

## Interface and behavior

Standalone stdlib helper; no `pefile`, executable build tool, repository import
or `__file__` dependency. CLI arguments:

```text
--archive <local ZIP>
--archive-sha256 <exact lowercase SHA256>
--archive-bytes <exact positive byte count>
--runtime-id <exact immutable identity>
--wheelhouse <protected local owned wheel directory>
--source-output <protected local owned source/evidence directory>
```

`stage(args)` authenticates one in-memory archive snapshot, then validates the
schema1 manifest identity, CPU/win_x64/cp311 fields, exact member inventory and
per-member bytes/hashes. The immutable original `UNQUALIFIED_CANDIDATE` state is
preserved. Distribution authorization remains a separately scoped exact receipt
validated by the caller; staging does not establish it.

The producer receipt must retain known source pins, `profile=cpu`, strictly false
`install_nvidia_gpu`, CPU CMake flags, exact wheel byte/hash rows and FFmpeg
configuration hash. Actual FFmpeg config/header/log exclusions and source/notice
associations are validated. Unsupported schemas, duplicate JSON fields, member
and parent case aliases, Windows unsafe names, traversal, links/reparse paths,
unindexed/changed members, forbidden tool/binary/cache payloads and unsafe
nested source archives fail before destination mutation.

Exactly the two controlled wheel paths are staged:

- `wheelhouse/av-18.1.0-cp311-abi3-win_amd64.whl`
- `wheelhouse/ctranslate2-4.8.2-cp311-cp311-win_amd64.whl`

Their real inner ZIP/CRC and RECORD inventory/hash/size checks execute with the
stdlib. The controlled seven FFmpeg DLL paths and single CT2 DLL path are
checked. Native PE imports, static incorporation and ABI execution remain
producer/final qualification; the consumer does not acquire native build tools
to repeat those checks.

All nonwheel payloads retain original bytes and paths under source-output,
including `build/native-build-receipt.json`, `build/ffmpeg-config.*`, `sources/`
and the native manifest. Both destinations are inspected before any mutation;
existing matching subsets can resume, while changed/foreign files, directories
or extras fail. Existing identical files preserve their bytes and timestamps.
Each new file is atomically published with an exclusive same-volume hard link.
Temporary files owned by the current attempted write are cleaned; prior data
is never deleted. Complete exact payload inventories are rechecked before the
native manifest is published last as the local completion record.

The caller must hold protected local staging ACLs throughout, matching the
existing protected-extractor boundary. A power-loss orphan temporary file is
treated as a foreign extra on retry; this helper does not delete preexisting
data. The caller must validate all staged files on retry rather than trust the
presence of a completion filename alone. There is no network or source-build
fallback. Success prints JSON with technical `status=STAGED_VERIFIED`, exact
runtime identity and caller archive pins.

## RED, GREEN and verification

Exact commands, from `D:\Projects\autoclip-runtime`:

```powershell
python -m unittest discover -s .github/tests -p test_cpu_native_install.py -v
python -m py_compile installer/install-cpu-native-artifact.py .github/tests/test_cpu_native_install.py
python installer/install-cpu-native-artifact.py --help
git diff --check -- installer/install-cpu-native-artifact.py .github/tests/test_cpu_native_install.py docs/installer-migration/work-orders/IM-DEP-07.md
```

Initial RED before production creation: six capability assertions failed because
the authorized standalone helper was absent. Subsequent meaningful behavioral
REDs found that differently cased implicit ZIP parent directories could reach
staging and that a missing newly staged payload could still receive a completion
manifest. Those tests failed at the no-mutation/no-completion requirements;
minimal directory-alias and complete-inventory checks made them GREEN.

Final focused GREEN: eight tests pass. They stage and compare real source,
receipt and wheel archive bytes, preserve unchanged retries, reject outer pins,
identity/schema/profile changes, substituted outer members and a deliberately
changed native member despite corrected outer manifest/receipt hashes, reject
foreign/changed output and actual Windows junctions, resume interrupted partial
output without a premature completion marker, and reject lost payloads and
implicit parent case aliases. The inner wheel hashes and RECORD checks are
real; synthetic native PE fixture contents are never executed or inspected as
real native binaries. There is no mock of package integrity or inventory.

Compilation, CLI help and scoped diff whitespace checks pass. No actual native
artifact stage, installed-release/Setup smoke, hardware, E2E or final review
check was performed by this assignment; root performs the exact integration
and acceptance checks. This helper and unit evidence do not qualify the artifact.

Suggested commit: `feat: validate and stage pinned CPU native artifacts`.
