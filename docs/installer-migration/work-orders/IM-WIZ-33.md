# IM-WIZ-33 - bounded source and final receipt helper

Status: authorized helper implementation complete and frozen for parent wiring.
Owned only new `installer/write-setup-receipt.ps1`,
`tests/InstallerSetupReceipt.Tests.ps1` and this report. No bootstrap, Inno,
builder, contract, manifest, app source, historical report or existing test was
edited. No VM, vendor, Setup, uninstaller, network acquisition or publication
was executed. User ordering remains production installer ready, then generated
uninstaller test before release.

## Requirement and compatibility

Inspected contract-v1 SHA256
`3eb9e4fbfb08d5aeb58f5b0aaa5a57ae044795d7bf537d9febed763c9f966f35`.
Its exact ownership, health-bound final receipt and preservation requirements,
plus the parent-approved IM-WIZ-32 design, authorize these explicit producers.
Source handoff precedes marker; final COMPLETE publication follows actual native
outputs. Neither function replaces Inno's native uninstall/log/ARP mechanisms.
Existing native `installed_files` and launcher/health extension meanings remain.
Actual `setup_owned_launcher.release_manifest_sha256` is reused, not renamed.

The helper is an importable first-party function library, **not** a standalone
command-line installer. Parent imports verified fixed helper bytes once in
source script scope and keeps the returned proof object in that same process.
No arbitrary command, evaluation string, executable, cleanup or registry write
is accepted. Context `source_helper_sha256` means **this new receipt helper's
pin**, as agreed with parent; supervisor provenance remains independently
bound by its pinned invocation/terminal status/compiler inputs and setup hash.

## Exact public interface

`Context` is a hashtable with exactly nine string fields: canonical absolute
`install_root`, safe compiled `release_id`, `profile` (cpu/nvidia), lowercase
64-character `archive_sha256`, `release_manifest_sha256`,
`dependency_manifest_sha256`, `bootstrap_sha256`, `source_helper_sha256`,
`health_helper_sha256`. Recipient SID is observed, not supplied. Extra context
fields are rejected.

1. `Assert-SetupStartingProvenance -Context -ManifestPath` returns a registered
   same-instance proof (`nonce`, context, pinned manifest path, prior handoff
   hash). A copied/invented/foreign proof cannot authorize source publication;
   identity and manifest path are independently retained internally.
2. `Write-SetupSourceReceipt -Context -StartingProof` validates actual archive,
   native receipt/profile, pinned bounded health JSON, actual launcher bytes and
   COM shortcut semantics; inventories permitted newly generated regular files
   and directories, then atomically writes fixed
   `<InstallRoot>/.setup-source-ownership.json`. Returns one descriptor
   `{path,bytes,sha256,status=VERIFIED_SOURCE_OUTPUTS}`. No marker is written by
   this library. Existing marker is refused in this producer: caller repair
   validates retained evidence instead of rerunning source production.
3. `Write-SetupInstallationReceipt -Context -HandoffSha256 -SetupRoot
   -SetupExePath -SetupSha256 -NativeFiles -NativeShortcutPath
   -NativeShortcutSha256 -Registration [-ReceiptPath]` revalidates retained
   source files, health, marker and actual native files/shortcut, then writes
   `<SetupRoot>/installation-receipts/<release_id>.json`. Optional ReceiptPath
   must equal that exact canonical location. Returns one descriptor
   `{path,bytes,sha256,status=COMPLETE}`. Every failure throws; native wrapper
   must propagate it and must not turn import-only execution into success.

NativeFiles uses exact relative `{path,bytes,sha256}` rows: four current notice
names, exactly one generated `unins<number>.exe/.dat` pair and optional matching
`.msg`. No other file scope is accepted. Caller supplies known compiled notice
pins and actual generated native names/pins. Helper independently reads them.
NativeShortcutPath must be the caller's fixed actual native Start Menu path;
helper validates its pin, target, arguments and working directory. Its
description need not equal the source-folder shortcut's description.

Registration is the **native caller-observed** hashtable snapshot with `key`,
`view`, `install_location`, `uninstall_string`. Helper checks the exact current
AppId uninstall key, Registry64, supplied SetupRoot and exact generated
uninstaller command. It does not independently query the registry; parent must
read actual HKCU values, never fabricate expected ones. COMPLETE cannot prove
registration was observed if the caller supplies invented data.

## Provenance, pins and output semantics

Starting validation is read-only and must occur before release overwrites or
native build invocation. Missing root with protected trusted staging parent,
empty protected root, or exact static-only partial files is accepted. Archive
schema3 files and manifest pin are validated first. Existing unknown regular
files or empty foreign directories are preserved/refused. In particular no
whole `.venv` or publisher-wheel prefix is adopted from an unproven partial.
An earlier valid source handoff permits only exact retained rows and directory
inventory; changed, added, duplicate, traversal and reparse data fail closed.
Matching marker-present source output can be validated for caller-owned repair.

Once starting provenance has been established, the controlled source route may
generate archive files and dynamic outputs under `.venv`, publisher-wheels,
wheelhouse and managed tools/ffmpeg, plus the known tool/native receipt and
folder launcher. Unknown generated root files/directories are refused. The
handoff records actual exact rows and explicitly excludes itself and marker.
Final receipt includes those actual metadata files plus source rows, native
notice/uninstaller rows, shortcuts and the observed registration snapshot.
Neither final record nor handoff hashes itself. Paths are bounded to local
regular data, inventories reject case-insensitive duplicates, and JSON is
bounded to16MiB (health64KiB). Read handles deny write/delete sharing through
validation/publication; atomic publication uses an exclusive fresh temporary
file and write-through flush. All read handles are disposed on failure/success.

Same ReleaseId with another valid install_root/profile/setup identity conflicts
at the canonical final receipt path: previous record is preserved, no automatic
selection, overwrite or multi-install journal. Exact identical publication is
idempotent. Same-target native worker exclusion is supplied by the parent:
hold the existing target lock across starting validation/source production and
across final publication. This library does not acquire a second lock scheme.

Existing roots/new publication parents require protected DACLs; selected files
and tree descendants have trusted effective owner/write permissions. Ancestors
are checked for reparse points, using the existing secure-helper pattern rather
than requiring protected bits on every descendant. Trust is ordinary current
recipient/SYSTEM/Admin integrity, not protection against that recipient
deliberately fabricating history. Failed/unproven legacy partials remain intact
and require the parent-approved fresh-target/refusal behavior; no chooser,
movement, deletion or bootstrap retry relaxation is implemented here.

## RED, GREEN and exact verification

Before production helper creation:

```powershell
powershell -NoProfile -File tests/InstallerSetupReceipt.Tests.ps1
```

Exit1, `RED: actual setup receipt producer is missing`, after the new test had
created a real protected first-party manifest/filesystem fixture. Production
implementation then supplied the explicit missing boundary. After minimal
validation/publication implementation, the same command exited0. Final GREEN
fixture preserved at
`C:/Users/beilo/AppData/Local/Temp/autoclip-setup-receipt-4508f7fe9e7b443d9ce87351e48a8a52`.

Executed assertions cover fresh absent/static partial/receipt-backed provenance,
source-before-marker publication and exact inventories/no-self-hash, same-proof
identity, retained marker validation, unknown `.venv`/publisher-wheel bytes
preserved before mutation, changed static payload/health/native notice, wrong
root/profile/handoff pin, canonical final location, duplicate/traversal/modified
inventory, junction and foreign-write ACL rejection, valid conflicting-root
receipt preservation and a real denied atomic final write with no COMPLETE
record. Real COM fixture shortcuts are inspected; fixture interpreters, wheels,
Setup/uninstaller and native registration snapshot are inert. No fixture is
claimed as actual app/installer/vendor health.

Adjacent unchanged behavior:

```powershell
powershell -NoProfile -File tests/InstallerCompletion.Tests.ps1
git diff --check
```

Both exit0. Existing completion suite verifies launcher failure, real denied
marker write and safe retry, foreign/modified shortcut preservation, unexpected
export rejection and locked-receipt cleanup/retry. No valid test was weakened.

## Frozen hashes and integration limits

- Helper: 23,429bytes, SHA256 `6a54eb46dc204f9d1a395219c73817c6597ffe9ba7dea0974267e076bf35013d`.
- New test: 13,604bytes, SHA256 `9c20b1e0b3a8f61f73a78e56b0ab518d3313fec1d750f5760e55fbf6ca72ddad`.

Parent still owns source/Inno/build/contract wiring, fixed notice/compiler pins,
pre-extraction staging of the fresh pinned manifest, protected new-root creation,
actual registry queries, same-target lock lifecycle and receipt conflict/user
messages. Native `unins.dat` may still be open or changing at ssPostInstall;
the parent is researching the correct completed native boundary. These tests
do **not** qualify that event timing, real native file sharing, generated
uninstaller cleanup, actual source build/app health, production readiness,
GPU, release or human/vendor gates. Parent must qualify the exact composed
installer, then execute the user's actual uninstaller test before release.
