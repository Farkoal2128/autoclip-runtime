# IM-WIZ-32 - proposed minimal setup receipt handshake

Status: read-only proposal for parent review. Only this document was added.
No production/test edits or installer/uninstaller execution. The parent owns
contract approval and any later implementation assignment. User sequencing:
production installer ready first, generated uninstaller tested before release.

## Concrete recommendation

Use two small versioned records and one first-party receipt helper, with explicit
source and final entry points. Reuse existing source manifest, health result,
launcher pin, protected-path/read-lock/atomic-write idioms and Inno native
files/shortcut/uninstall/ARP mechanisms. Do not introduce a generic journal,
dependency ownership system, alternate uninstaller or recipe modification.

1. Source handoff: fixed `<InstallRoot>/.setup-source-ownership.json`, produced
   inside the existing serialized completion action **before** `.install-complete`.
   Keeping it at a fixed release-relative path permits exact retry lookup without
   searching historical attempt logs. The final receipt hashes this handoff;
   the handoff excludes itself from its inventory to avoid self-hashing.
2. Final local receipt: fixed
   `<LocalAppData>/AutoClip/Setup/installation-receipts/<ReleaseId>.json`,
   published atomically by the setup completion helper from ssPostInstall after
   native outputs exist and are checked. ReleaseId must be the fixed compiled
   value and a safe basename, not a recipient-provided arbitrary path.

The final receipt's own fixed path is an explicitly owned evidence container;
it is not recursively hashed into itself. Both metadata paths require regular
nonreparse files, trusted ordinary-user ownership/write permissions and safe
ancestors. The final directory follows existing protected Setup storage rules.
Refuse conflicting existing metadata; permit idempotent revalidation only for
the same bound installation. Neither record grants elevated execution authority
or authorizes removal of a parent tree.

## Small schema and exact responsibilities

| Record | Required fields |
| --- | --- |
| Source handoff schema1 | `schema_version=1`, `status=VERIFIED_SOURCE_OUTPUTS`, canonical `install_root`, recipient SID, fixed `release_id`, selected `profile`, `archive_sha256`, `release_manifest_sha256`, `dependency_manifest_sha256`, `bootstrap_sha256`, source-helper pin, health-helper pin; `native_receipt` path/bytes/SHA256; `app_health` bound result path/bytes/SHA256/status; `launcher` existing exact byte/hash/semantic pin; `files` exact relative regular path/bytes/SHA256 rows; `directories` exact relative managed empty-directory candidates. |
| Final receipt schema1 | `schema_version=1`, `status=COMPLETE`, same recipient/root/release/profile/payload/source/dependency identities; `setup_sha256`; source-handoff path/bytes/SHA256; health evidence binding; `release_files` copied validated source rows plus actual marker and handoff rows; `release_directories`; `setup_files` exact notices and generated uninstaller outputs path/bytes/SHA256; `shortcuts` exact native Start Menu and source-folder shortcut identities/semantics; `registration` exact per-user native AppId key/view and relevant installed values. |

Use lowercase SHA256 and integer lengths, reject duplicate case-insensitive
paths and unsupported schema/status. Release inventory paths are relative only;
native setup paths must stay under fixed Setup root, except the fixed native
shortcut and exact native HKCU registration. No arbitrary registry/file scopes.
Separate native evidence from additional release ownership; it does not replace
Inno's uninstall log or add new registrations. Record exact native outputs
actually generated, rather than assume `unins000` names. Modified-file-sensitive
native cleanup is a subsequent bounded lifecycle concern from IM-WIZ-31.

Source inventory includes validated archive files/manifest, newly generated
`.venv/**`, in-release staged wheels/wheelhouse if present, retained managed
FFmpeg files/toolpath receipt, native-build receipt and required folder launcher.
It excludes the source handoff itself and marker; marker content is predetermined
and the final helper validates/captures its actual bytes. External caches,
durable attempt/health logs, private MSYS2/native build roots, shared/vendor
prerequisites and user media/settings/projects are never owned release files.
Existing native `installed_files` only covers eight DLLs and cannot substitute
for this inventory. Preserve its existing schema meaning.

## Exact caller handshake

**Source bootstrap caller**: normal pinned Inno route only. Add one compiled
receipt-helper SHA parameter following existing fixed adjacent-helper verified
bytes invocation (no arbitrary code path). Inputs to its source entry point:
InstallRoot, ReleaseId/profile, expected archive/release/dependency/source pins,
existing verified native receipt/health result/launcher evidence and proven
starting provenance. Source obtains starting provenance **before any release
overwrite or native invocation**, validates it, and performs the build with its
existing target lock. After health and required launcher succeed, the completion
action captures actual source outputs and writes the fixed handoff, then writes
the marker. Cancellation and write failure still propagate through the existing
commit boundary. Direct standalone installs without the new pin retain their
current retained workflow and are not falsely labeled setup-owned.

**PrepareToInstall / RunSourceBuild**: existing exact hidden-worker invocation
and terminal status remain. Require terminal success with no accepted cancel,
then capture the fixed handoff SHA and the native receipt binding for this
attempt; verify archive/manifest/root/compiled inputs and actual rows rather than
accept metadata alone. No stdout or marker-only authority. Keep this captured
binding in setup state for the final call. The final helper reopens pinned
inputs with read handles denying writes/deletes and revalidates actual files.
Use the existing target lock across final receipt validation/publication too,
so another source worker cannot change the target during that boundary.

**ssPostInstall**: invoke the same pinned first-party helper's final entry point
with fixed InstallRoot/SetupRoot, ReleaseId/profile, actual executing setup path
and its expected observed SHA, compiled payload/dependency/bootstrap/helper/notice
pins, captured source-handoff/native-receipt SHA, expected native shortcut/key
locations and the fixed final receipt path. The helper observes native outputs
and the existing bound health evidence, verifies source files/marker/shortcut,
then atomically publishes the receipt. It returns one small typed descriptor:
fixed receipt path, bytes, SHA256 and COMPLETE status; failure is nonzero and
stops setup's final success claim. Do not collect bulk file inventory through
COM pipes. A final write failure may leave the source marker; it remains source
completion only and must be reported/repaired as unfinished setup completion.

Actual ordinary-user launch/application qualification remains the existing
production readiness gate. Receipt publication cannot turn an unperformed check
into verified evidence or add a GPU claim to CPU success.

## Provenance and safe matching retry

IM-WIZ-31 identified the source:1288-1304 prefix allowances. Replace them only in
the new receipt-enabled route with exact checks against verified archive rows
and, for retained dynamic output, an existing valid source handoff. Validate the
existing tree **before** Expand-Archive at1252-1253. A fresh missing root supplies
fresh provenance. An existing static-only partial root can be retried only when
every present regular file matches the pinned archive inventory and paths are
safe; unknown files cause refusal and remain untouched.

For a receipt-backed partial root, all retained dynamic files must match earlier
handoff rows exactly, with no additions, changed bytes or reparse entries.
Matching outputs may be reused/rebuilt by the existing route; write a fresh
handoff after this attempt's health/launcher checks. Missing marker after a
handoff write or final receipt failure must not make a proven matching tree
foreign. The narrowly scoped source-marker-present/final-receipt-missing repair
must validate complete retained source output and finish setup-shell publication
without rerunning the source build or overwriting a completed unrelated release.
Existing source currently rejects **all** marker-present roots (928-940); this
would be an intentional new Inno repair branch, not a silent standalone waiver.

Legacy partial roots and early failed builds with `.venv`/staged-wheel contents
but no handoff do not supply dynamic provenance. Preserve them in place and
refuse ownership adoption. A fresh explicit InstallRoot is the safe fallback;
do not automatically rename/move/delete the old tree or invent hash rows for
its existing contents. **Compatibility decision for parent:** current Inno
ReleaseRoot is fixed and offers no target-selection flow, so either authorize
a bounded fresh sibling-target selection with native shortcut/root bindings,
or retain the visible refusal/manual fresh-target guidance for those unproven
partials. Matching *proven* retries remain supported. Universal legacy partial
reuse cannot honestly be preserved with exact ownership. This decision must
precede implementation and be stated in the contract/retry message.

## Minimum implementation ownership after approval

- `install.ps1`: receipt-enabled starting provenance check and one source
  completion producer call; keep immutable recipe, existing health/commit order
  and no-pin standalone behavior.
- One new `installer/write-setup-receipt.ps1`: explicit source/final functions,
  exact inventory validation and protected publication; no generic framework.
- `installer/run-source-build.ps1`: allowlist the new helper pin only, unless
  parent deliberately chooses an additional typed terminal descriptor.
- `installer/AutoClip.iss`: capture handoff binding, fixed final ssPostInstall
  invocation and narrowly qualified incomplete-setup repair decision.
- `scripts/build-inno.py` and focused build verification: lock/package/pin the
  new helper, capture exact compiler inputs and update compiler receipt.
- Contract-v1/schema wording and focused receipt tests; reuse existing fixture
  helpers rather than change unrelated historical tests or app source.

## Smallest meaningful RED fixtures (proposed, not performed)

1. First-party protected fresh release fixture with archive manifest, inert
   generated venv/wheel/tool files, real fixture shortcut and bound health/native
   evidence. Actual source completion boundary must produce a handoff **before**
   marker. Missing producer is RED; receipt/hash rows and marker order are GREEN.
2. Exact source provenance boundary on a static-only partial and receipt-backed
   partial. Inject `.venv/unrelated.txt` and `publisher-wheels/unrelated.txt`;
   require refusal before any side effect and preserved bytes. Valid matching
   retained files remain retryable. Do not mock inventory/provenance behavior.
3. Actual final producer with inert first-party native output fixtures: absence
   of final receipt is RED; verified setup/source/notice/root bindings and exact
   publication are GREEN. Changed source row, handoff pin, wrong root/profile,
   duplicate/traversal/reparse record and denied final write must fail closed.
4. Extract the actual Inno final/repair decision boundary into an inert fixture
   and verify completion failure propagation plus marker-present/final-missing
   qualified repair. Any compiled fixture execution requires parent approval;
   never retry a previously refused execution through a substitute route.

Reuse InstallerCompletion/BuildAppHealth/BuildProcess/BuildStorage fixtures
identified in IM-WIZ-31. These fixtures prove producer/decision behavior only;
they do not qualify real installation, native uninstall-log lifecycle or GPU.
After exact production installer readiness, assign and execute the generated
uninstaller test required by the user. No such execution is part of this draft.
