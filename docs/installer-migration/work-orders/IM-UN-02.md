# IM-UN-02: exact owned-file removal primitive

## Assignment

- Parent: working production Inno installer, then exact generated uninstaller
  cleanup/data-preservation tests, then authorized release.
- Authorization: implementation of one internal cleanup primitive under the
  existing uninstall ownership contract. No actual generated uninstaller test.
- Preferred role: implementer, GPT-6.1 Sol/medium; actual routing not exposed.
- Owned files: new `installer/remove-owned-file.ps1`, new
  `tests/InstallerOwnedFileRemoval.Tests.ps1`, and a new external evidence report.
- Not alone in the codebase: preserve others' edits; do not modify existing
  installer/bootstrap/receipt/build/manifest/tests/contracts/docs.
- Sequential TDD: read the ownership contract and existing receipt path/relative
  validators; add a runnable behavioral test and demonstrate expected RED before
  creating the production helper; minimum implementation, GREEN, then report.
- Parallel safe: root records review and decides the higher-level receipt/hook
  boundary. This primitive is not yet delivered or called by native uninstall.

## Bounded requirement

For a caller-authorized protected local root and a validated exact relative file
row (path, nonnegative integer byte count, lowercase SHA256), remove only the
unchanged regular file represented by that row. Root authorization comes from
the future complete receipt consumer; a row or directory name alone is not
uninstall authority. Missing files are idempotent; changed, unsafe and locked
files are preserved with explicit outcomes. No recursive deletion, directory
deletion, registry/shortcut handling, receipt authority, new dependency, elevated
execution, or acquisition is included.

The same native Windows handle used to hash/measure the file must grant deletion
and perform disposition. Keep it open with sharing that forbids file writes,
renames and replacement through the decision. Hold the ancestor directory chain
against rename/replacement and reject reparse points on the actual opened handles;
path-only prechecks or unlock-then-delete do not prove this boundary. Reuse pinned
existing validation functions where safe; do not import arbitrary caller code.
Reject unsafe local/relative paths, invalid row types, directories, reparse points,
foreign ownership/write ACLs and elevated tokens. Preserve handle cleanup on all
outcomes. Do not add test-only callbacks to production code.

Use built-in .NET/Windows APIs. Read official CreateFileW,
GetFileInformationByHandle, SetFileInformationByHandle and FILE_DISPOSITION_INFO
documentation before interop. Keep any native glue narrowly scoped to this need.

## Evidence and limits

Run actual Windows ordinary-user tests only on fresh protected inert first-party
fixture roots owned by this test. Test successful unchanged deletion, zero-byte
file, changed/missing/locked files, invalid/traversal/root escape, directory and
junction rejection, write/rename exclusion and release of handles after refusal.
Any cleanup of fixture directories must verify containment and use one shell;
preserving the fixture is preferred. Do not touch real installs, caches, user
data, prerequisites, VMs, Setup/uninstaller binaries, execution policy, clock,
certificate trust, signing, vendor agreements, release assets or publication.

Return exact RED/GREEN commands/results, source/test/report hashes, fixture paths,
case outcomes, native API assumptions and concrete remaining limitations. Failure
because a helper is absent is acceptable only if the behavioral assertions then
exercise actual implementation. Stop and report unresolved architecture/security
contradictions instead of weakening tests. This primitive alone closes no
installation, uninstall, technical-review, legal or release gate.

## Returned implementation and root verification

Worker `/root/owned_file_removal` returned only the two assigned new repository
files and external evidence report. Helper SHA256 is
`5309434273bda5107118937daf5622ddc2703660ea3c2af53f5f6fde2ff855fb`;
test SHA256 is
`dcaf4e16559cbf48eb2c8fe6f78c8d104b06bc979911c1039aeeb89c5c135d32`.
Complete report at
`C:/Users/beilo/AppData/Local/Temp/autoclip-IM-UN-02-evidence-20261002.md`,
SHA256 `eb8db999249c586f1c550e23a008cfc0661a2eb66a4a6933f375712d0e8a766c`.
Root read the complete source/test/report and independently checked these pins.

Initial RED command `powershell.exe -NoProfile -File
tests/InstallerOwnedFileRemoval.Tests.ps1` exited1 before helper creation. The
expanded actual concurrency test then found a meaningful production defect:
READ_CONTROL-only directory handles did not exclude a GENERIC_WRITE handle,
even with share=READ. Adding GENERIC_READ to that directory access mask fixed
the actual sharing boundary; the unchanged write exclusion assertion passes.
Intermediate fixture/test setup failures remain distinct in the report.

Root independently ran `powershell.exe -NoProfile -NonInteractive -File
tests/InstallerOwnedFileRemoval.Tests.ps1` from the runtime repository: exit0,
fixture `autoclip-owned-removal-e730f4b2ae3e4322ab344c54f6ceab23` under recipient
TEMP. Actual unchanged/zero-byte removal, changed/missing/locked/unsafe outcomes,
foreign writer and junction/hard-link refusals pass. During actual hashing,
file write, replacement and file/directory/root rename probes returned Win32 32;
later handle release passed. No test-only production callbacks were introduced.
The timing observer uses a 512 MiB inert file and 250 ms delay; it explicitly
fails when no overlap is observed. It is host evidence, not a deterministic
proof on every filesystem or hardware platform.

Source61c2, bootstrap5b2994 and receipt producerba21 remain unchanged. The helper
currently has no build delivery, complete receipt consumer or native uninstall
caller. Elevated/foreign-owner and live mapped-write behavior remain unexecuted;
missing root is a filesystem outcome, never ownership authority. Native
disposition can defer storage reclamation until compatible external readers
close. These limits must remain explicit through integration. This component
GREEN does not qualify the production installer or actual generated uninstaller.

## Later preservation RED: alternate streams

Root identified unrecorded NTFS alternate data streams as a concrete preservation
risk. Worker added the behavioral case before any stream-handling implementation:
an unchanged default row with a new `secret` stream must remain UNSAFE/preserved.
Actual test exits1 because the helper returns REMOVED. A separate native writer
with compatible sharing created/wrote an ADS while hashing; the helper still
removed the file. Default-stream write exclusion does not cover other streams.
The earlier Set-Content concurrency refusal was specific to its sharing mode and
is explicitly not evidence of file-wide exclusion.

Helper remains unchanged530943; current test is
`be5078dd5bc47f4e2d67adf8fb6026b09eafbd84892fe7d65dac67c4dea9a2b1`.
New complete report
`C:/Users/beilo/AppData/Local/Temp/autoclip-IM-UN-02-ADS-blocker-20261002.md`,
SHA256 `1475fc35ca8243578abbc11243344935dc5cd9f1b5849c9699800827eec1e1ba`.
Root read the actual test and complete report; historical report is preserved.
No stream handling, trust exception, generic framework or production hook was
implemented to disguise this failure. Current primitive status is RED and not
ready for integration; the earlier GREEN remains only historical scoped evidence.

## Minimum reproduced-case correction, still unqualified

Root authorized only same-handle FileStreamInfo checks before and after hash
comparison. Added native observed-overlap preservation assertion was RED before
this production change: native ADS writer succeeded with Win32 0 while hashing,
then helper returned REMOVED. The unchanged preexisting-stream case remains.

Current helper SHA256
`905b0c7950d9637cffabbd5beb70ef73c2d90a5fb590bf5009226cfd1b205b95`;
current test SHA256
`03c3ab14785e77aab8b17708b574a54d253777f3bfd954f48ea9ccae7ab4baa6`.
New complete report
`C:/Users/beilo/AppData/Local/Temp/autoclip-IM-UN-02-ADS-candidate-20261002.md`,
SHA256 `62a21baad03d76f99828338f0573ad0be4fd74470b6c26f4b66a921ecb773b26`.
Root read complete source/test/report, checked pins, and independently reran
`powershell.exe -NoProfile -NonInteractive -File
tests/InstallerOwnedFileRemoval.Tests.ps1`: exit0, protected inert fixture
`autoclip-owned-removal-f262a61aa2fd4d11adf45f3a0ef7a15c` under recipient TEMP.
Native during-hash stream creation succeeded, helper returned UNSAFE, and secret
contents remained. Preexisting ADS and earlier file/ACL/path/locking cases pass.
Root separately reproduced the prior ADS RED on fixture43a8eab before the change.

Guard buffer is bounded at64KiB; successful response must contain sole exact
unnamed data stream and same-handle size. Extra/unsupported/error/ambiguous
responses preserve the file. No stream stripping, path relookup, temporary
delete-pending, new dependency or framework was added. This fixes observed cases;
the final query-to-disposition interval remains exposed to compatible ordinary
nonparticipating stream writers. Comments and reports retain UNQUALIFIED status.
Full preservation guarantee, authenticated native integration and release remain
unverified; supported-actor reconciliation is not waived. No actual generated
uninstaller test ran, and installer/source/bootstrap/receipt pins remain unchanged.
