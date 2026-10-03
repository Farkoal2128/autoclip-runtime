# IM-CPU-22 — isolated installed application health/home gate

Status: additive helper and first-party native tests frozen. Actual installed
v40 guest invocation, Inno integration and release acceptance remain pending.
Root owns those operations and bootstrap/builder/Inno integration. No existing
installer, updater, archived recipe, archive, manifest or release was changed.

## Requirement and inspected source

The parent explicitly authorized an ordinary-user installed health/home check
before setup success. The setup contract requires application health in
addition to source-build exit, marker, manifest and native import checks.
This helper provides one bounded check; it cannot close full desktop/media
acceptance, model inference, hardware, uninstall or publication gates.

The existing producer is `update.ps1`'s isolated `AUTOCLIP_HOME` check:
`TestClient(create_app())`, lifespan enter/exit and GET `/api/health` and `/`.
This implementation reuses that mechanism; no HTTP listener or service manager
was introduced. Read-only inspection of `autoclip/app.py` in the exact v40
wheel confirmed `create_app`, lifespan, health JSON `status:ok`, and the
packaged frontend home route (503 when the frontend is missing). The exact
v40 `paths.py` separately supports `AUTOCLIP_STORAGE_HOME`; both home overrides
must be isolated to avoid touching a recipient-selected data directory.

## Consumer interface and proof scope

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File <verified-verify-installed-app.ps1> -InstallRoot <actual-installed-release-root> -ManifestSha256 <exact-lowercase-release-manifest-sha256> -ResultPath <new-json-file-in-existing-protected-recipient-log-directory>
```

`ResultPath` is optional; omission chooses `result.json` in a new protected
`ach-<guid>` TEMP stage. Caller result paths must be absolute, local,
non-reparse, with an existing protected recipient-owned parent granting only
recipient/SYSTEM/admin FullControl. All outputs use CreateNew; an existing
result is never overwritten. Setup must check native process exit zero and
the exact result's schema/status/root/manifest/child binding; printed output
alone is not the success decision. Failure leaves full logs and `failure.json`
in the stage where possible and throws for a nonzero PowerShell file exit.

Public parameters expose no executable, script text, arbitrary URL, provider,
model, GPU or test override. The interpreter is fixed to
`<InstallRoot>/.venv/Scripts/python.exe`. The manifest is fixed to
`<InstallRoot>/release-manifest.json`; it must be a regular local non-reparse
file, match the caller's exact SHA-256 and have current source-build schema 3.
Complete manifest member/native/wheel verification remains an earlier
installer gate; this helper does not replace the full inventory verifier.

Require native 64-bit Windows and an unelevated user token. The installed
configuration and Python file must be regular/non-reparse. Configuration
uses the same bounded version/identity/isolation parsing rules as the shared
runtime PATH helper: exact `3.11.9` from `version`/`version_info`, no duplicate
or conflicting identities, one false system-site-packages flag, optional
implementation only `CPython`. The helper does not execute PATH registration
for this check. Python must have valid Python Software Foundation Authenticode.
Manifest, configuration and interpreter are held read-locked with write/delete
sharing denied through native execution and result creation.

The fixed first-party probe asserts actual CPython 3.11.9/x64, expected venv
prefix, isolated/no-user-site flags and cleaned Python path/home environment.
The Python code imports the installed `autoclip.app`, uses real TestClient
lifespan, requires health HTTP 200 with JSON `status:ok`, and home HTTP 200.
After shutdown it writes exclusive bounded child JSON. The helper requires
actual native integer exit zero plus that receipt, the expected installed
app/interpreter paths and exact isolated home. A result cannot be manufactured
from a source-build completion marker or process exit alone.

## Native process and data preservation

Each invocation creates a fresh stage protected to the current recipient,
SYSTEM and administrators. The child receives a fresh `home` there for BOTH
`AUTOCLIP_HOME` and `AUTOCLIP_STORAGE_HOME`. PYTHONPATH/PYTHONHOME are cleared,
PYTHONNOUSERSITE is set, and `-I -B` is fixed. Parent environment is restored
immediately after spawning on both success and failure, before waiting.
No existing user data or AutoClip installation file is removed or rewritten.

A native hidden child runs the fixed stage-local first-party probe. Redirected
stdout/stderr files stream during execution without an unbounded pipe. The
probe file remains read-locked. Exclusive `process.json` and
`process-terminal.json` record actual PID/start/executable/logs/terminal exit.
The helper observes the same process without retry, timeout or kill; even a
receipt-writing error waits for an already-live child before releasing locks.
All stages, logs, smoke databases/data and receipts are preserved for review.

Successful JSON contains schema 1, `VERIFIED_HEALTH_HOME`, exact install root,
manifest hash/bytes, current user SID, configuration/Python hashes and signer,
actual child receipt/exit/PID/log paths, completion time and explicit scope:
`isolated_health_only:true`, desktop/media/model-inference checks false.
This does not start a desktop browser, select a hosted provider, acquire a
model, exercise transcription or establish NVIDIA behavior.

## RED/GREEN evidence

```powershell
powershell -NoProfile -File tests/InstallerAppHealth.Tests.ps1
git diff --check -- installer/verify-installed-app.ps1 tests/InstallerAppHealth.Tests.ps1
```

RED exited 1 before the helper existed: `RED: installed health/home gate
absent`. GREEN exited 0 after implementation and refinements. PowerShell AST
parser and scoped diff check passed.

The tests execute the actual fixed probe and native process function with
normal host CPython 3.11.9. They prepend only a first-party fixture module
directory and existing repository FastAPI/httpx library directory to the
probe for the fixture import setup. A real first-party FastAPI app provides
actual lifespan and ASGI responses; TestClient is neither replaced nor mocked.
No dependency/app installation, vendor installer, download or VM action was
performed. The fixture is not presented as an installed AutoClip application.

Four actual native child cases prove success, health HTTP 503 rejection,
home HTTP 503 rejection and a missing home route's HTTP 404 rejection.
Successful lifespan closes; every case restores all five parent environment
values. Existing caller home/storage sentinel directories remain byte/content
unchanged with no new files. Actual I/O tests also prove manifest readlock
write denial, wrong hash rejection, future schema rejection, protected result
CreateNew overwrite rejection and unsafe relative/UNC/traversal path rejection.
Configuration fixtures accept standard-library and uv forms, and reject
duplicate, conflicting and non-isolated metadata. Fixture stages remain on disk.

The host tests do not prove the production public helper's Authenticode gate
against a newly installed guest venv or the actual v40 application's health.
They prove fixed native-process/TestClient behavior and input/data boundaries
at their stated level. Root must run the full public helper on the actual
installed guest snapshot before accepting setup success.

## Frozen artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `installer/verify-installed-app.ps1` | 12933 | `9f5656ccad347fba939b16fd1ca26003b01c8d50ec4af82270c8c1be37f70756` |
| `tests/InstallerAppHealth.Tests.ps1` | 6630 | `d3e02ced33dbfc9dbc72dd398662fc4c14ddd240b545d9913f0553046ec9c14b` |

Freeze these during parent integration/review. No concurrent writer changed
other assigned modules. Root must add this helper to the locked build input
inventory, Inno temporary payload and exact hash definitions, then bind its
actual receipt to the setup attempt and success gate. Latest user sequencing
still places real uninstaller tests after production-ready installation.
