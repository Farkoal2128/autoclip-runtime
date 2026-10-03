# Windows setup contract, version 1

Status: proposed contract for the Inno Setup migration. This document does not
qualify a generated setup executable or authorize publication. The current
public `install.ps1` route remains the supported route until the gates in
`plan.md` pass for the exact replacement executable.

## Platform and identity

- Support Windows 10 and 11 x64 for the current Python 3.11 x64 runtime. Arm64,
  Windows Server, Linux, and macOS are outside this setup contract until tested
  and separately declared supported.
- Compile the setup and its uninstaller as x64. Asynchronous native helper
  launches use the normal System32 executable path from the x64 setup process.
  Use 64-bit installation mode on supported x64 Windows, including the 64-bit
  per-user uninstall registration view. Preserve the application ID and
  per-user scope. This migration has no previously published Inno registration
  to transfer; legacy runtime directories remain outside setup-shell ownership.
- Use a stable Inno application ID across setup upgrades. Install the setup
  shell in its own per-user `%LOCALAPPDATA%\AutoClip\Setup` directory and stage
  each runtime in a separate versioned directory. The shell must never own the
  parent AutoClip directory, recipient caches, user data, or older releases.
  Ordinary launch must not require elevation. Elevate only a vendor
  prerequisite installer that needs it, after consent.
- Keep the existing versioned runtime and application identity, manifest hash
  checks, active selection, and rollback behavior in
  [the runtime architecture](../runtime-update-architecture.md). Do not
  reinterpret a historical release ID or activate an unverified layer.
- Create a Start Menu shortcut and an installation-folder launcher only after
  validation. An optional Desktop shortcut must not replace an existing one.
  A shortcut must launch the verified installed runtime without rebuild or
  network access.

## Inputs and dependency policy

`release/manifests/installer-dependencies-v1.json` is the setup dependency
source of truth. It names exact artifacts or references an exact hashed
release manifest that enumerates them. Every entry has identity, version,
architecture, purpose, CPU/GPU applicability, delivery classification, official
source, expected size and SHA-256 when fetched, detection and capability
checks, execution arguments and exit codes when installed, reboot behavior,
and version-specific licensing evidence. Packaging and setup must consume the
same resolved inventory. Unknown, incomplete, and `BLOCKED` entries may not be
bundled or acquired by setup.

`native_build_assets` records the source archives and build-tool wheels already
pinned in the selected release's `build-native-from-source.ps1`. Derive these
rows from that hash-checked recipe; the packaging gate rejects omitted, duplicate,
added, or changed identities. These inputs remain separate from the ordinary
publisher-wheel inventory and the release's existing external-asset inventory.
Every fetched artifact, including MSYS2 packages and their detached signatures,
requires its own exact HTTPS redirect-host policy. A child cannot grant download
permission when its parent route is blocked.

`BUNDLE_ALLOWED` means the exact bytes and nested contents have an approved
repository evidence route. `DIRECT_RECIPIENT_DOWNLOAD` means the recipient
gets exact bytes from an approved official source; it is not a license waiver.
`SYSTEM_PROVIDED` means setup verifies a compatible system capability and
does not own it. `BLOCKED` means no automated acquisition or redistribution
until the recorded blocker is resolved. Preserve the repository's stricter
Microsoft, NVIDIA, cuBLAS, and NumPy restrictions even if an upstream license
could permit another route.

Delivery permission and complete installer qualification are separate decisions.
An exact artifact may become `DIRECT_RECIPIENT_DOWNLOAD` after its official
acquisition, integrity, applicable terms/notices and component operation have
supported evidence. Pending wizard, lifecycle or final binary tests remain
release blockers in `plan.md`; they must not turn an otherwise qualified
artifact into a licensing or acquisition prohibition. Compilation still creates
an `UNVERIFIED_CANDIDATE`, never a release approval. Existing receipts retain
their original manifest hashes and test scopes. This reconciliation is recorded
in IM-DEP-01; it does not authorize a rejected tool action or clear the specific
fresh Microsoft acquisition requirements below.

The setup executable must contain only AutoClip-owned installer code and
explicitly approved first-party payloads and notices. No publisher cache,
Microsoft/NVIDIA installer, prohibited wheel, or blocked nested archive may be
hidden inside setup or a release asset. Use the existing source-build package
only after independently checking its final nested contents against this
policy; its old hash or prior scoped review alone is insufficient.

## Wizard and installation state machine

1. Before machine changes, determine CPU or explicitly selected NVIDIA mode,
   inspect the target path and existing installation, validate exact identity
   and capabilities, and show all missing or incompatible prerequisites. Show
   each component's purpose, publisher, version, official source, known size,
   elevation, reboot risk, and whether it is required for basic or GPU use.
2. Present applicable version-specific vendor terms or official links and
   request an explicit recipient decision before affected downloads or
   installs. The AutoClip setup acceptance is not vendor-term acceptance.
   Decline or cancellation leaves active AutoClip and user data intact.
3. For an allowed automated route, fetch the exact pinned official HTTPS URL
   into protected staging. Reject unapproved redirects, unexpected host or
   publisher, size/hash mismatch, invalid required signature, wrong version,
   unsafe path, and unverified payload identity. Verify again immediately
   before executing an absolute local path with fixed, documented arguments.
   Do not use remote scripts, command lines, or test bypasses in production.
4. Serialize vendor installers, wait for each result, interpret documented
   exit codes, and recheck both installed identity and the capability AutoClip
   needs. Suppress surprise restarts with supported arguments. A successful
   process exit alone never satisfies the dependency check. If a vendor
   mandates browser, authentication, or interactive installation, explain the
   manual handoff and verify the result before continuing.
5. Stage the AutoClip release beside completed installs. Check all archive
   members, hashes, manifest, notices, native build receipt, imports, media
   capability, and application health before writing the completion marker,
   active selection, or shortcuts. The source-build helper's existing
   `.install-complete` marker is one input, not setup's final success decision.
   Record exact setup, payload, manifest, source, notice, and dependency hashes
   in a local installation receipt after ordinary-user health validation.
6. On failure, cancellation, UAC denial, network loss, locked files, or a
   vendor failure, leave the previous installation and rollback target usable.
   A retry may reuse only verified cached bytes and matching partial state.
   It must not overwrite unrelated or completed installations. Report where
   setup and vendor logs are located and what changed externally.

The setup must reject path traversal, reparse-point escapes, and collisions
with unrelated files; prevent concurrent setup/repair against the same target;
and avoid ownership claims over vendor-installed shared dependencies. A
reboot-required result records pending state and resumes verification only
after reboot; it never reports success early. Reinstall/repair verifies the
current layer before changing it. Legacy installations are validated and
migrated side by side, retaining the old layer until the new one is proven.

The source-build page uses the existing responsive asynchronous process loop,
with a hidden native PowerShell worker, protected incremental stdout/stderr
logs, a bounded displayed tail and named phases. Native compiler output is
display data, never an instruction or authority for a state transition. Do
not drain an unbounded child pipe only after exit. Bind the worker, manifest,
arguments, paths and logs to the exact installation attempt.
Noninteractive source-helper startup and completion must not depend on redirected
standard input reaching EOF. Its verified arguments and attempt files carry the
request; an unused input pipe must not prevent worker readiness or terminal return.
Normal setup retains source-build attempts below the recipient's
`%LOCALAPPDATA%/AutoClip/Setup/logs`, with a fresh setup-specific name and
attempt index. Create missing fixed storage with recipient/SYSTEM/Administrators
authority; validate existing ownership, write grants and reparse status without
silently changing unrelated ACLs. The cancellation requester may wait for the
supervisor's protected decision lock, but creates no staging or acceptance state.
Every actual source worker exclusively holds a protected zero-byte target lock
below `AutoClip/Setup/locks`, keyed by SHA256 of the normalized absolute target.
Resolve the deepest existing ancestor before appending any absent suffix, so
Windows short/long aliases identify one physical target even before creation.
A concurrent worker for the same target fails before bootstrap execution;
different targets remain independent. Hold that lock through worker completion,
including observation failures; release the handle only after terminal state.
The empty lock file persists and can be reused after independently checking it.
Python prerequisite receipts use the separate `AutoClip/PythonSetupLogs` folder;
their storage producer must not create inherited `Setup/logs` parents that
conflict with the source supervisor's protected-storage contract. Preserve
historical Python logs at their original paths.

Managed FFmpeg startup registration accepts the isolated Python 3.11.9 venv
metadata produced by the pinned standard-library venv or pinned uv: respectively
`version` or `version_info`. Require an unambiguous exact version and explicit
disabled system site packages; missing, conflicting, duplicate or incompatible
identity fields fail closed. Retain the executable, path and notice checks.

Build cancellation is cooperative between bootstrap-controlled invocations.
The immutable native recipe contains multiple commands and may run until its
whole invocation returns; disclose that wait, then check cancellation before
each subsequent bootstrap command. Keep the responsive page and full logs.
Serialize accepted cancellation with the completion commit under one protected
attempt lock: an accepted cancellation prevents new marker, launcher and
activation work; after commit begins, report that it is too late to cancel
and finish observing the same worker. A button click is a request, not proof
that cancellation was accepted. Do not overwrite committed state with a late
cancel or report a committed success as cancelled. Record and test both
orderings, including startup before the attempt directory exists. A cancelled
wizard overrides a raced zero helper exit. Before reporting cancellation
complete, observe the actual worker terminal state; a timeout or live child
must remain explicitly pending and must not allow retry into its target.
Source-build completion requires the installation-folder launcher to succeed
before the marker is committed. A launcher or marker failure must propagate
as a failure and leave the matching partial installation safely retryable.
Recovery must distinguish owned launcher output from unrelated files; it may
not weaken the matching-manifest or unexpected-file protections.
The optional `setup_owned_launcher` extension to the existing local native
receipt binds only generated `AutoClip.lnk`: exact byte count/SHA256, expected
target/arguments/working directory/description, archive identity and release
manifest identity. A matching partial installation may retain that output only
after both its bytes and shortcut semantics are independently checked. Missing
or conflicting ownership evidence, changed bytes/semantics or reparse paths
must fail closed. This additive field grants no ownership of user data or
shared prerequisites and does not reinterpret the immutable native recipe.
Managed source builds require the setup-pinned `verify-installed-app.ps1`
helper before completion. It executes the installed isolated Python 3.11.9 x64
interpreter as the ordinary recipient, imports the installed application, runs
its actual lifespan and requires HTTP 200 for `/api/health` with status `ok`
and for `/`. Isolate both application and storage homes from recipient data;
restore the caller's environment. This check proves isolated application health,
not desktop launch, media processing or model inference.
The optional `setup_app_health` extension to the local native receipt records
`result_path`, `bytes`, `sha256`, `install_root`, `manifest_sha256` and `status`
(`VERIFIED_HEALTH_HOME`). Verify the bounded protected result against the
current release manifest and root, including actual Boolean scope flags and
native child status. Its logs and result must survive setup exit. Missing,
tampered or failed validation prevents launcher and marker commitment; this
additive evidence does not replace setup's final ownership/completion receipt.
Never terminate a shared vendor installer as part of this source-build
mechanism. Prompt process-tree cancellation, if introduced, requires separate
containment and failure tests before use (IM-WIZ-07).

### Source ownership and final setup receipt

The receipt-enabled Inno route validates starting provenance before overwriting
release files or starting a native build. A fresh target or static partial may
contain only exact archive-manifest files. Retained generated files require an
earlier valid `.setup-source-ownership.json` and exact unchanged inventory;
directory prefixes alone do not establish ownership. Unknown, modified or
unproven partial contents remain in place and require a fresh target. This
restriction is scoped to the new receipt-enabled route; historical standalone
retry evidence retains its original meaning.

After verified health and launcher creation, the serialized source completion
action writes schema1 `VERIFIED_SOURCE_OUTPUTS` handoff before the marker. Its
context binds recipient SID, canonical install root, release/profile, archive,
release/dependency manifests, bootstrap, receipt producer and health helper.
The field `source_helper_sha256` identifies `write-setup-receipt.ps1`; the source
supervisor remains independently bound by the compiled setup inputs. Exact
regular-file rows and directory candidates exclude the handoff itself and
marker. External caches, logs, user data and shared prerequisites are excluded.

After Inno finalizes its files, shortcut, uninstaller log and per-user
registration, the pinned finalization entry point revalidates the handoff and
actual outputs while holding the same target lock. It writes schema1 `COMPLETE`
at `Setup/installation-receipts/<ReleaseId>.json`, binding the actual setup hash,
source handoff, source/marker rows, four setup notices, generated native
uninstaller outputs, actual shortcuts and the native HKCU Registry64 AppId
registration. The record does not hash itself or grant parent-tree ownership.
A conflicting receipt is preserved and refused; it is not silently reassigned
to a different installation.

Inno's native installation is already committed at `ssPostInstall`. A receipt
failure must produce an explicit incomplete-setup message and nonzero custom
setup exit code; an event exception alone is insufficient. Preserve the source
completion and native outputs for a qualified repair. Do not claim rollback or
final setup success when receipt publication fails. Actual hook, repair and
generated-uninstaller behavior still require tests of the exact setup candidate.

An exact-identity completed source layer may be reused for setup repair only
after its protected source handoff, complete unchanged file/directory inventory,
archive/manifest/profile/producer identities, recipient SID, launcher semantics,
historical health evidence and completion marker are verified. Run fresh isolated
application health into a new protected attempt outside that layer; preserve
the completed source files, native receipt, ownership handoff and marker byte
for byte. Recheck provenance before completing the cooperative decision. Do not
extract, rebuild, install packages, regenerate launchers or rewrite source
receipts in this path. Missing/changed/unproven contents and producer identities
remain refused and preserved; this route does not adopt a legacy installation.
An absent final setup receipt may subsequently be published only after actual
native outputs pass the existing finalization checks. A conflicting existing
final receipt remains refused: source reuse alone does not authorize renewal
of native output ownership or replacement of that receipt.

After a source supervisor or receipt finalizer successfully starts, setup must
observe that exact child until terminal state even if its progress display fails.
Retain the original display error, keep cleanup responsive when possible, and
report failure after the wait; do not release the attempt or allow a retry while
the child is still running. Nested cleanup exception handlers must not cause a
pending body exception to escape before that wait completes. Native failure
injection must inspect the original child's status immediately when the calling
procedure returns, without adding an observer wait that conceals early return.
Final progress-page/control cleanup must preserve an already captured body
error. If only that terminal cleanup fails, report its error as failure after
the child wait; do not silently suppress it or declare setup successful.

Uninstall removes only files in the exact setup-owned installation receipt,
shortcuts, and registrations; it leaves unknown or modified files for manual
review. It never recursively deletes the AutoClip parent, recipient cache,
historical releases, or rollback targets. It never deletes user projects,
settings, layouts, media,
exports, generated ZIPs, credentials, recipient caches, or shared system
prerequisites. Independent vendor installers are outside AutoClip rollback.

### Activation and cleanup serialization

Participating runtime and app updaters acquire one ordinary-user native Windows
mutex per canonical AutoClip base before reading activation/reference state and
retain it through validation, child work and activation/rollback/shortcut changes.
Cleanup acquires that same selection mutex before the release-target file lock
and retains both through reference decisions and removal. Source-only children
use the target lock; they do not reacquire their parent's selection mutex.
Never acquire selection after target. Contention fails before state mutation.

The selection mutex has a versioned fixed global name derived from current
recipient SID and canonical local base identity, protected ownership/DACL limited
to that SID, SYSTEM and Administrators. Reject reparse aliases and foreign or
ambiguous mutex authority. Release/dispose on all outcomes. Abandoned ownership
does not establish state validity: a new owner performs the complete ordinary
state/payload validation before mutation. Native mutexes create no cleanup file.
Standalone updater scripts retain this protocol without an unavailable helper or
unpinned code download. Unchanged immutable older updater copies do not
retroactively participate; no mixed-version serialization claim is authorized.

This mutex serializes supported participating actors; it does not establish
whole-file alternate-stream exclusion against nonparticipating writers.

### Authorized uninstall actor cutoff (2026-10-02)

The recipient explicitly authorized the normal cleanup approach: stop AutoClip
and its updater, check each installed file, and preserve modified or unknown
files. Cleanup holds the selection mutex before the target lock; a running
participating updater therefore blocks cleanup before mutation. It stops only
recipient-owned AutoClip processes whose executable, command and release-root
identity are verified. Unknown processes using the release cause refusal.
Unchanged receipt-owned files may then be removed using the existing native
handle checks. Observed alternate streams, changed bytes, unsafe authority,
reparse paths and locked files remain preserved. This authorization accepts the
remaining final stream-inventory/disposition race against unrelated programs;
it does not claim atomic exclusion against nonparticipating writers.

The generated uninstaller consumes a protected, hash-anchored `COMPLETE` receipt
from the fixed per-release installation-receipts directory. Its durable cleanup
dependencies are exactly `uninstall-owned-release.ps1`, `write-setup-receipt.ps1`,
`remove-owned-file.ps1`, `run-source-build.ps1` and `update.ps1`, independently
pinned by the compiled setup and indexed in the final receipt. Before native
launch, validate its generated uninstaller pair and complete finite Registry64
registration snapshot. An unknown registry value/subkey or changed native
uninstaller fails closed. Notices and owned shortcuts receive the same
preserve-on-change rule as release files. Only recorded empty directories may
be removed; never recursively remove a parent, cache, data or historical layer.
A release referenced by app or rollback state remains preserved. An exact
current-only selection may be reset after validation; do not select an untested
historical layer as part of uninstall.
When selection removal refuses, include its finite native removal outcome in
the diagnostic while preserving the existing failure and retention behavior.

### Native uninstall data lifetime (2026-10-02)

Inno 7.1.0 opens its DAT with exclusive sharing before `InitializeUninstall`
and retains that handle through `usUninstall`. A separate callback process
cannot rehash its contents. The registered uninstall command therefore uses
absolute system PowerShell with a setup-generated loader that verifies the
compiled pin of the existing cleanup consumer before its launch mode runs.
The recipient still receives Inno's native uninstall interface.

Launch mode checks the anchored COMPLETE receipt, all helper pins, registration
and exact EXE/DAT/optional MSG bytes, identities, metadata, paths, authority and
observed streams before starting the verified native uninstaller. It performs
no removal or application stopping at this stage. A fresh protected handoff
binds these observations to the receipt hash, recipient SID, release/root,
nonce and live launcher process identity. Native callbacks require that live
handoff and reject missing, conflicting, stale or replayed authority; direct
native invocation without it refuses cleanup. Accessible native EXE bytes and
DAT identity/metadata are checked again before confirmed removal. The DAT
content hash records the prelaunch observation, not a callback content read.

The launcher releases its DAT read handle so Inno can acquire exclusive native
ownership. This interval uses the authorized trusted recipient/SYSTEM/
Administrators actor scope and participating-updater serialization. It does not
provide continuous content verification or protection against a malicious
trusted recipient or unrelated substitution during that interval. Inno's CRC
is not a cryptographic receipt pin. The native engine owns its DAT while
running; release-file cleanup retains the existing preserve-on-change rules,
selection-before-target locking, verified application stopping and post-native
receipt retirement. Exact generated-uninstaller qualification remains required.

The AutoClip base and fixed Start Menu `AutoClip` directory may have trusted
inherited ACLs. The internal removal primitive's `AllowInheritedRoot` option is
permitted only for the exact validated current-only `active.json` reset and the
receipt-owned fixed Start Menu shortcut. It relaxes only the requirement for the
root DACL to be marked protected; current-recipient/SYSTEM/Administrators owner
and write authority, path/ancestor/reparse, links, hashes and alternate-stream
checks remain required. Release and Setup cleanup retain protected-root checks
by default. The four-argument native primitive retains its original behavior.

## Success and evidence

### Microsoft runtime preparation before source build

For the new Inno route, prepare the manifest-selected x64 VC runtime before
source staging/build. The wizard obtains explicit Microsoft runtime consent
before its direct-recipient acquisition, uses the existing protected downloader,
and invokes a setup-bound first-party helper with the exact manifest hash.
The helper does not acquire vendor artifacts or suppress their native agreement
UI. Use the manifest's reviewed `/install /norestart` arguments and wait for the
actual process. Source work must not become a second prerequisite installer.
Historical standalone behavior remains separately scoped.

The helper rechecks approved artifact size/hash, exact file version, valid
Microsoft publisher signature, local path and authority immediately before
execution while retaining read handles that deny artifact write/delete. It
rejects an elevated helper token; only the vendor process requests elevation.
The native vendor agreement remains visible. UAC denial, vendor failure or
observation failure cannot report successful preparation or allow overlapping
retry while an owned process is still running. No automatic restart is allowed.

Preparation checks System32's x64 `vcruntime140.dll`, `vcruntime140_1.dll`,
`msvcp140.dll` and `vcomp140.dll`: compatible version, valid Microsoft signature,
regular protected system path, native x64 identity and actual loader capability.
Keep signer policy specific to the object: the downloaded vendor installer
executable must retain the manifest's exact publisher CN (`Microsoft
Corporation`). For each installed system DLL only, accept a valid Authenticode
signature whose subject CN is exactly `Microsoft Corporation` or `Microsoft
Windows Software Compatibility Publisher` and whose subject O is exactly
`Microsoft Corporation`. This installed-DLL compatibility-signer allowance
does not relax the downloaded executable check.
This is prerequisite DLL capability, not proof of CTranslate2 inference; the
installed native/application checks remain required before setup success.
Registry presence or a lone VCOMP file never qualifies this prerequisite.

Use one ordinary-recipient protected VC state/log directory outside the release
and outside the source supervisor's Setup storage. Serialize helper attempts
with a held native file lock and reject unsafe existing authority/reparse paths.
Durable schema1 state binds recipient SID, VC artifact/manifest identity,
boot identity, attempt status and actual vendor result. Record an in-progress
attempt before vendor execution; interruption leaves unresolved state rather
than authorizing another vendor launch. Receipt publication is part of outcome
handling. Never silently rewrite a foreign or conflicting record.

A3010 outcome records pending reboot and returns3010, even if DLL detection now
passes. A fresh wizard process on that same boot must return3010 before reuse,
download or execution. After a different verified boot, recheck system capability
before retiring owned pending state or proceeding. Interrupted in-progress state
fails closed on the same boot; after reboot it still requires actual capability
verification. Keep exact outcome logs/receipts, shared prerequisites and user
data. The wizard sets NeedsRestart for interactive pending outcomes and does not
publish a COMPLETE receipt or native setup success. Native qualification remains
required; inert helper tests and compilation cannot establish this route.

Declare installation successful only when the exact source-build or runtime
payload is verified, prerequisite capability checks pass, the installed
ordinary-user launcher starts AutoClip, the intended application health check
passes, and the completion receipt binds these results to the setup hash and
dependency manifest hash. CPU success does not imply GPU success. A GPU claim
requires the selected hardware and a real inference check.

The exact generated `.exe` must pass clean Windows interactive installation,
unattended behavior if supported, failure and lifecycle tests, user-data
preservation, final-payload inventory, and an installed ordinary-user bounded
media workflow with decoded input, required transcription path, rendered
playable output, and audible output. Record commands, environment, logs,
screenshots, versions, and hashes; distinguish mock, prepared-machine, clean
machine, and GPU evidence. Compiler success and developer-machine tests are
insufficient. Human, legal, and publication gates remain separate.

## MSYS2 archive provisioning boundary

The replacement base route uses the exact official `20260611` TAR under the
single MSYS2 manifest identity. The GUI artifact remains historical evidence.
The route and its child artifacts require component acquisition, signature,
initialization and package qualification before direct delivery. Whole-wizard
qualification remains a separate release gate. Preserve
the exact five package identities, trusted signatures and unrelated packages.

Provision Python first and verify its exact 3.11.9 x64 identity and `lzma`
capability. Its standard-library `tarfile` reader inspects the authenticated
base archive; no additional extractor dependency is required. Reject links,
devices, sparse members, duplicate or case-colliding paths, traversal,
Windows-invalid names and any member outside the single `msys64` root before
writing. Extract regular files exclusively into an empty protected owned
parent, preserve executable modes, and verify the complete file inventory
against the hash-authenticated archive. Reject reparse paths and existing roots.
Regular archive members may be empty when their authenticated inventory records
size zero and the exact empty-file SHA-256. Acquired archives, signatures, keys
and other execution inputs still require positive pinned sizes.
Archive-derived inventory is evidence; it cannot authorize a different archive.

Authenticate archive size and SHA-256 against the setup-bound manifest before
extraction. The sole pre-signature native execution permitted by this route is
the archive's hash-verified OpenPGP verifier and its verified DLL closure, in
the protected extracted tree. It must verify the exact detached signature with
the separately pinned installer key and full official fingerprint before any
bash, initialization, package or build execution. An invalid or missing signature
stops provisioning. This exception does not permit executing an unverified
installer, bypassing a required signature, or using an arbitrary downloaded key.

Initialize the default package keyring locally, then perform the one upstream
first login and verify its documented effects without keyserver refresh. Later
package transactions use their separate isolated trusted keyring and no online
repositories. Before source build, verify private HOME and all sourced startup
files, constrain startup environment variables and PATH, and restore caller
state afterward. Keep the selected v40 recipe and its cache identity unchanged.
Fresh-build receipt queries must agree with independent non-login observations.
The private root has durable ownership evidence; retry and uninstall preserve
unknown files, shared installations and user data. Component initialization
alone never establishes whole-setup success.

### Per-user base receipt and execution authority

MSYS2 extraction, initialization and package execution run under the ordinary
recipient account. Both helpers reject an elevated token before any native
execution or filesystem mutation. Their owned extraction parent and receipt
directory use protected DACLs, with ownership and effective write permissions
limited to the current recipient SID, SYSTEM and Administrators. Descendants
must have no reparse points or write grants to another SID. This receipt is
per-user integrity evidence; an elevated process must never treat it as
authority to execute recipient-writable code with administrator privileges.

The base helper writes a schema-version-1 receipt only after all base checks
pass. Required fields are `schema_version`, `status` (`VERIFIED_PINNED_BASE`),
`manifest_sha256`, `archive_sha256`, `archive_bytes`, `root` (the exact absolute
MSYS2 root), `signature_verified`, `signer_fingerprint`, `init_verified`,
`first_login_verified`, `protected_root_verified`, `extraction_inventory` and
`code_files`. The four verification flags must be Boolean true. The signer
fingerprint is `0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`.
`extraction_inventory` contains `receipt_sha256`, `file_count` (15529) and
`directory_count` (1052); the full archive-derived extraction receipt remains
in the protected receipt directory outside the extraction parent.

`code_files` contains exact relative `path`, `bytes` and `sha256` records for
every regular file in `usr/bin/**`, `etc/profile.d/**`, `etc/post-install/**`,
`etc/msystem.d/**`, plus `etc/profile`, `etc/bash.bashrc`, `etc/msystem` and
`msys2_shell.cmd`, after verified initialization. The
package helper independently enumerates that same closure and rejects missing,
added, changed or duplicate records. It also checks the twelve canonical base
pins, including keyring and native executable identities. The setup binds the
base receipt by its SHA-256 and passes `BaseArchivePath`, `BaseReceiptPath` and
`BaseReceiptSha256` to the package helper; receipt claims alone do not replace
file, ACL or identity checks. Recheck the manifest, receipt and code closure
before native execution and immediately before the package transaction.

Private HOME startup files are separately verified against the signed archive
and checked again before source-build login queries. Neither an arbitrary HOME
nor ambient `BASH_ENV`, `ENV`, `GNUPGHOME`, `PS1`, `XDG_CONFIG_HOME`, exported
Bash functions, startup hooks or PATH may authorize
additional code. Plan-only invocation never mutates state. Explicit base and
package installation switches authorize their respective ordinary-user actions;
the wizard obtains the prerequisite decision before invoking either.

Source execution requires the extraction parent and receipt directory to have
protected DACLs. The extracted `msys64` root may inherit the parent's approved
recipient/SYSTEM/Administrators permissions, as the base helper produces it.
Independently validate the root and all selected descendants' effective
permissions, owners and reparse status; an inherited root never permits a
foreign writer or an unprotected extraction parent. Requiring an explicit
protected bit on that child would reject the contracted base helper's output.

### Package receipt and source-build startup

After the exact five trusted package transactions and capability checks, the
package helper returns a schema-version-1 receipt with `status`
(`VERIFIED_PINNED_PACKAGES`), the exact absolute `root`, lowercase 64-character
`manifest_sha256` and `base_receipt_sha256`, `private_home` copied from the
authenticated base receipt, and `post_install_code_files`. The latter contains
the expanded code/startup selector from `code_files` plus every regular file
in `ucrt64/bin/**`, independently enumerated and hashed after the transaction,
with each file's protected path
and effective write permissions verified. The caller writes this result to a
protected receipt directory and binds its SHA-256 before source build.

The original base closure is checked before the package transaction. Installed
packages legitimately change that closure, so post-install verification uses
the new package snapshot rather than comparing it to the original base. Before
any source-build login query, verify the bound package receipt, manifest, root,
complete post-install code snapshot, and archive-derived private HOME startup
files. Use the controlled ordinary-user environment described above and restore
the caller's environment afterward. Preserve the immutable v40 build recipe.
Neither receipt grants administrator execution authority or permits extra
packages, arbitrary HOME startup code, or an unreviewed recipe.

## Setup-owned tool notices

The setup-owned `notices` directory must retain the exact Inno Setup 7.1.0
license, uv 0.12.19 MIT and Apache-2.0 texts, and a first-party source index.
The index identifies uv source commit
`bea138450f0e620a4ce5765b0e38cff7b9f0799f`, the versioned source/terms URLs,
and the scope of recipient acquisition. It must not describe these top-level
texts as an audit of every embedded component or permit tool redistribution.
The build receipt binds every delivered notice/index file by size and SHA-256;
missing or changed versioned texts stop the build before compiler execution.
Hold native Windows read handles that deny write/delete sharing on the exact
manifest, payload archive, compiler executable, setup source, bootstrap,
helpers, notices, verifier and builder before validation begins and through
receipt creation. Capture their pins while locked and use those same pins
for compiler definitions and the receipt. Release all handles on success,
failure and partial acquisition. This prevents a concurrent file rewrite or
rename from producing a receipt for different input bytes (IM-BUILD-04).
These files are setup-owned documentation, independent of recipient caches.
Preserve the complete MinGit package notice tree when extracting that tool.

## Microsoft 17.14.41 integrity source

For this exact Build Tools 17.14.41 / build 17.14.37710.0 selection, the
expected downloaded Catalog is the independently authenticated standalone
artifact: 17,954,732 bytes, SHA256
`f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643`.
The exact ChannelManifest is 91,781 bytes, SHA256
`fca418ba94ffbcfb7a2b25f10f16f39dd09660568d21eef4bd3f274cb0b27b8c`.
Both document signatures, timestamp linkage and normal Windows certificate
chains were verified separately (IM-VS-13 parent integration). This is an
intentional selection of the expected standalone artifact, not a claim that
the channel's external catalog reference matched it.

Keep the channel's signed vendor-declared catalog identity separately:
30,443,537 bytes, SHA256
`6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5`.
Retain that contradiction and all 140 declared/observed payload size conflicts
in the provenance record. Separate expected delivered-byte pins from immutable
vendor-declared reference fields; never silently overwrite either. Expected
payload sizes must be independently observed and match the signed catalog's
payload SHA256 values. This narrow decision applies only to the exact channel,
catalog, versions and reviewed 409-file inventory, and permits no future
metadata or unknown version fallback.

Every incoming file must match its chosen expected size and SHA256, and every
required signature/publisher/version check must pass before execution. A
changed expected file, signature, URL, manifest identity or selection fails
closed. The supported native install uses the explicitly pinned local catalog
and channel; it must not rediscover an unreviewed latest engine or product.
For layout acquisition, pin and verify every execution input before vendor
code runs: the exact bootstrapper, authenticated OPC and complete selected
868-file engine closure, signed Catalog/Channel, all 397 selected payloads,
and every locally authored seed/control file. Keep observed sizes separate
from the conflicting vendor declarations. Reject mutable engine selection,
unknown code/module sources, unsafe paths and changes between validation and
use. A previously installed matching engine is a warm-machine observation,
not proof of supported acquisition on a fresh recipient.

Only controls produced by the supported layout-generation operation may be
reviewed and assigned new expected pins after generation. Before native
product installation, require the complete newly reviewed layout inventory,
including every generated control and payload, plus vendor verification.
Preserve the original 409-file inventory and record any deliberate differences;
never replace a failed historical expected pin with the observed result.
Native product installation requires an explicit recipient decision on the
exact Build Tools and applicable SDK terms before acquisition or installation.
Present the actual accessible vendor terms and record the accepted identities;
decline prevents acquisition and execution. Supported quiet installation is
permitted after that informed acceptance. A quiet flag, acquisition-only
operation or consent to AutoClip alone grants no product-agreement acceptance.

This intentional phase distinction follows IM-VS-18. The first bounded warm
acquisition experiment requires physical guest network disconnection, supported
local controls, immediate input/engine rechecks and retained process/module and
vendor logs. `--noWeb` alone does not prevent engine update checks;
`--noUpdateInstaller` has a documented guarantee only with `--quiet`.
The canonical route remains `BLOCKED` until supported fresh-recipient engine
acquisition, focused failure tests, real recipient verification and final
technical review exist. Prior post-acquisition inventory, offline install and
compiler results cannot retroactively qualify unreviewed acquisition execution.

### Direct Microsoft installation qualification

Layout generation is required for the local-layout route above. A supported
direct installation route may instead be qualified using the fixed reviewed
bootstrapper or exact vendor-installed engine, the pinned authenticated local
catalog and channel, explicit component selection and documented vendor
integrity/version controls. Use documented quiet/noUpdateInstaller controls
only after explicit recipient acceptance of all applicable terms; prevent
surprise reboots. This intentional route decision does not waive any incoming
artifact, nested payload, signature, publisher, version, safe staging or
pre-execution integrity requirement above. A mutable latest engine selection
does not qualify. Preserve conflicting vendor-declared metadata and fail closed
on unexpected resolution. Keep the canonical dependencies BLOCKED until the
fresh-recipient route, exact resulting capabilities, relevant failures and
technical review have been verified. VM-only terms acceptance is evidence for
those tests and does not stand in for production recipients' consent.

Microsoft documents quiet initial installation and noUpdateInstaller with
quiet in its [CLI examples](https://learn.microsoft.com/en-us/visualstudio/install/command-line-parameter-examples?view=vs-2022)
and [parameter reference](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022).
The reviewed [Build Tools March 2024 terms](https://visualstudio.microsoft.com/wp-content/uploads/2024/03/Visual-Studio-2022-Diagnostic-Build-Tools-Agent-License_Update-March-2024_EN.docx)
are 34395 bytes/SHA256
`2f66b86a00e8d9833789897ce23d05a4a2dbea370cf39c8c1098dbc17d0e7bdc`;
separate platform component agreements still require exact inspection and
recipient acceptance. The native-interactive-only restriction chosen earlier
is superseded by this explicit-consent rule; historical tests retain their
original scope. This is a qualification boundary, not an installation pass.
