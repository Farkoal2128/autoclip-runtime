# VM testing handoff

Updated: 2026-10-02 (America/Los_Angeles). Some preserved evidence filenames
use the UTC date 20261003. This is a development checkpoint, not a release.

## Start on the other computer

```powershell
git clone --branch work/v41-current-app-at01 https://github.com/Farkoal2128/autoclip-runtime.git
cd autoclip-runtime
git log -1 --format='%H %s'
```

Read this file, `AGENTS.md`, `skills/runtime-updater/SKILL.md`,
`docs/runtime-update-architecture.md`, and the migration `contract-v1.md` and
`plan.md`. Latest work records: `work-orders/IM-DEP-13.md`, `IM-WIZ-42.md`,
and `IM-SEL-02.md`. Continue Ponytail full and the multi-agent workflow:
one implementation owner per mutable file; root owns VM testing and delivery;
a fresh read-only reviewer receives an exact frozen packet for technical review.
Configured model names do not prove per-run model telemetry.
The app repository's `main` already contains the GPT-6.1 Sol specialist routing
and multi-agent skills at commit `841339ef891ed3fbdbb2633694e9e816d5263228`
(local and remote verified at handoff). Clone
`https://github.com/Farkoal2128/myAutoclip.git` if that project configuration
and its `skills/multi-agent-orchestration/SKILL.md` are needed on the new host.
Install/enable Ponytail full and Computer Use in the destination Codex client;
plugins and host-level configuration do not move through this Git commit.

Copy the separate **AutoClip-VM-handoff-20261002.zip** and verify its SHA-256
against `vm-handoff-transfer.json` beside this document. Git does not carry the
unreleased ZIPs, Setup executables, compiler installation, VM disks or external
review evidence. The transfer bundle includes those small testing/reproduction
inputs and exact review material; it contains no VM disk or saved RAM.

Extract to a regular local directory. Its `transfer-index.json` records every
payload file's bytes, SHA-256 and original `mtime_ns`. Verify and restore the
times before attempting an exact rebuild (ZIP extraction alone loses precision):

```powershell
@'
import hashlib, json, os
from pathlib import Path
root = Path('.')
rows = json.loads((root / 'transfer-index.json').read_text())['files']
for row in rows:
    path = root / row['path']
    if path.stat().st_size != row['bytes'] or hashlib.sha256(path.read_bytes()).hexdigest() != row['sha256']:
        raise ValueError('Transfer differs: ' + row['path'])
for row in rows:
    os.utime(root / row['path'], ns=(row['mtime_ns'], row['mtime_ns']))
print('Verified all transfer payloads; restored source timestamps.')
'@ | python -
```

Run that command from the extracted bundle root. Re-run byte/hash validation
after transfer; the index itself is bound by the committed outer bundle hash.
`source-checkpoint/` preserves original source bytes/timestamps for the newer
compiled checkpoint. A normal Git checkout may change line endings and mtimes;
it is suitable for development, but does not establish exact binary reproduction.

## Two candidates: choose deliberately

| Candidate | Bundle location | Status |
| --- | --- | --- |
| r8 | `r8-objective/candidate/AutoClip-Setup-v1.exe` | Reviewed for bounded CPU VM testing; installation incomplete |
| Maintenance checkpoint | `maintenance-checkpoint/AutoClip-Setup-v1.exe` | Compiled with native maintenance GUI and initial selection; no frozen technical review or VM qualification |

r8 Setup: 3,430,626 bytes,
`4e617da88c02ef82a66a095f4e235e3f6b9197a98e07c9756b35d0c410eda14e`.
Its receipt hash:
`f573f3ebaee9c5807feff2bde7276bbe48dd7f40a9826c9a01ac742090eca91b`.
Frozen objective manifest:
`ddd1abbdfd15487954e6ec1e5c8628f35c2d125954b718e8a6228ae5da1dd52b`.
`r8-review/review-disposition.json` says
`ELIGIBLE_FOR_BOUNDED_CPU_VM_TESTING`, `release_eligible: false`.
The complete original packet and report are retained separately. The historical
r7 logs record a supervisor failure signature; a separate controlled test
reproduces it but does not prove the exact original exception. The later
tail-test fixture acquisition fix changes tests,
not the frozen r8 production supervisor. Preserve the original failed reviewer
test and successful retry rather than rewriting that history.

Maintenance Setup: 5,521,995 bytes,
`28a4540c8ed47100c4b9935b26cf8288c9f158b485e6373a117e518479c921ca`.
Its build receipt remains `UNVERIFIED_CANDIDATE`. The Git checkpoint contains
the newer sources, not the sources embedded in r8. Its changes include native
Inno maintenance Update/Rollback UI, pinned hidden worker, schema2 finite
`base_files` for the stable launcher pair, schema1 compatibility, two-phase
launcher preparation/initial activation and selection locking. Integration
documentation and exact review are unfinished; do not apply the r8 verdict to
this new Setup. Existing receipt requirements, vendor checks and release gates
remain enforced.

Both use these exact private CPU inputs under `r8-objective/candidate/`:

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| `autoclip-publisher-cpu-v41-r7.zip` | 225947128 | `b737e574d469f1cf69327d60d81f8674ca5bf047d5bc8360880203553871d629` |
| `autoclip-cpu-native-win_x64-cp311-v1-20261002-3343baed-r2.zip` | 66665645 | `46ee07feb45b12e31c83fd49283f2053c729ca6f2073326b11a036d7c609f437` |
| `install-publisher-cpu.ps1` | 425249 | `d4fc7f8b07494f1d77eaf1a8d60e7a5d6d5801b6c8450d61b6773edae310d209` |
| `installer-dependencies-cpu-v1.json` | 36460 | `a079c0836db331aad30f9c858bc15852a41414aa0b31d404b323c9a374a240ad` |

Release ID: `v41-20261002-publisher-cpu-r7`. Release-manifest hash:
`de8c39c3d6a2c2aaa067b9fb0ff71019a953bb8ae7fbd31a8f45292bb0936808`.
The component distribution review is in `r8-objective/component-review/`;
its scope is the native component, not the complete installed product.
The embedded native-artifact manifest still labels its build
`UNQUALIFIED_CANDIDATE`; the separate component disposition does not qualify
the complete installer or grant broader vendor/public distribution rights.
The original source-build canonical manifest still blocks VS/SDK; use the
separate CPU manifest for this publisher-built alternative. No compiler,
SDK or MSYS2 source-build fallback should occur in this CPU route.

For a *new* maintenance build, from `source-checkpoint/` (or development clone):

```powershell
python scripts/build-inno.py --manifest <bundle>/r8-objective/candidate/installer-dependencies-cpu-v1.json --archive <bundle>/r8-objective/candidate/autoclip-publisher-cpu-v41-r7.zip --bootstrap <bundle>/r8-objective/candidate/install-publisher-cpu.ps1 --native-artifact <bundle>/r8-objective/candidate/autoclip-cpu-native-win_x64-cp311-v1-20261002-3343baed-r2.zip --iscc <bundle>/InnoSetup7/ISCC.exe --output-dir <fresh-output> --profile cpu
```

Replace placeholders with absolute local paths. For exact historical r8
reproduction use `r8-objective/` sources, never the newer checkout. Inno Setup
7.1.0 compiler hash:
`d06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a`.
All copied compiler files and its license are indexed in the transfer bundle.

## VM setup and last observed progress

Use a clean licensed Windows 11 x64 guest, ordinary recipient account,
VirtualBox NAT, one display, 4 GB RAM and 6 vCPUs (adjust for the destination
host). Previous guest was Windows 11 Enterprise Evaluation build 26100.
No GPU passthrough, 3D acceleration or Guest Additions were used. Allow room
for Windows, downloads, unpacking and retained rollback layers; check available
space before starting. A fresh guest avoids transferring the old linked disk
chain. Do not copy a lone differencing VDI: it depends on its ancestor disks.

Old r8 VM: `AutoClip-PublisherCPU-CleanWin11-20261002-r8`, UUID
`dcb787f4-25e7-4a48-82bb-c4c9018c0e48`. Host inspection at handoff reports
`aborted`, not running; it was not restarted. Latest observed guest wizard was
the Python terms page, after CPU-default and prerequisite pages. No completed
r8 installed `COMPLETE` setup receipt/anchor, app/media result or uninstaller
run was obtained. The build receipt exists and is distinct from installed proof.
Start a fresh attempt on the destination; retain the old evidence here.

Create a read-only DVD/ISO/VISO containing the chosen Setup, `media/` from the
bundle, and `cache/` containing both CPU ZIPs. In `cache/`, rename the consumer
archive to **autoclip-source-build.zip**; keep the native archive filename.
The archived `r8-candidate.viso` maps absolute paths on the old host and is
reference only: recreate the mappings for the destination, or make a normal
ISO. Do not edit the frozen packet to relocate it.

These candidate asset URLs are unpublished. For the private cached test,
after Setup creates its temporary `is-*.tmp` directory, use normal File
Explorer to copy both DVD cache ZIPs into that attempt's actual temporary
directory before acquisition. Setup's protected downloader still verifies
size/hash. A private cache success does not qualify public acquisition.
Versioned upstream prerequisite downloads must retain their protected routes.

The wizard installs registered python.org Python 3.11.9 x64 (no Tcl/Tk) and
checks the Microsoft VC/OpenMP runtime. Prior VM-only consent covers the
versioned Python terms and Microsoft vendor agreements for these tests;
production recipients must consent themselves. Project use was declared
non-commercial and VS use rights confirmed. Have the user handle any UAC,
sign-in or security permission prompt. Native GUI testing uses the Computer
Use skill; no guest shell, Run commands or guest automation bridge. The host
may use native VBox CLI for read-only inventory and ordinary VM lifecycle.

Old multi-monitor input was unreliable. Put the VM in a normal window on the
main monitor. Observe fresh state before each action. VirtualBox's native
soft keyboard worked for guest navigation (Alt+N for wizard Next); do not
reuse old window IDs or coordinates. Do not substitute a terminal installer
for the native Inno consumer UI.

## Qualification order on the destination

1. Complete maintenance contract/architecture/work-order integration. Freeze
   the new exact Setup/source/input packet and obtain fresh blinded read-only
   technical review before its bounded VM test. Do not inherit r8 approval.
2. Run actual CPU Setup; preserve full source-worker stdout/stderr, tail,
   terminal status, commit decision, health result, COMPLETE setup receipt
   and anchor. A successful child health check alone is insufficient.
3. Launch from the generated shortcut; verify stable launcher/`active.json`
   select the installed runtime. Test actual CPU int8 transcription and media
   export through the desktop app. `media/source.mp4` is a controlled 27-second
   speech/video fixture; its bytes/hash are indexed. Tiny/int8 is appropriate
   for this 4 GB guest. Use a configured provider; previous host Ollama at
   guest NAT endpoint `http://10.0.2.2:11434`, model `llama3.1:8b`, is only an
   example and needs a working provider on the new host.
4. After working installer/application/media, snapshot the verified guest and
   run its **actual generated uninstaller**. Compare the complete installed
   receipt inventory, helper/EXE/DAT files, shortcuts, anchors and registration
   before/after. Stop owned AutoClip/updater; preserve modified/unknown files,
   projects/settings/media/credentials, shared prerequisites and runtime
   layers referenced by app/rollback state. Test clean removal first; restore
   the snapshot for modified-file and updater lifecycle variations.
5. Qualify native maintenance app-only update, failed activation preservation,
   zero runtime asset fetch, selected app launch and rollback without download
   or dependency reinstall. The current public app manifest supports V11/v40,
   **not this CPU runtime**. A properly qualified exact compatible app manifest
   and wheel are still needed. Pinned local fixture CLI inputs exist for
   bounded tests; do not promote a synthetic compatibility declaration.
6. Build/test/review; publish immutable assets; download public bytes and
   verify hashes; promote public pins; test real update/delivery; release.
   The branch handoff is not asset publication or release acceptance.

CPU is default; NVIDIA installation is optional. User explicitly deferred
NVIDIA hardware testing because there is no GPU passthrough. Its required
dependency rights, pins and usable optional route still need disposition;
hardware deferral does not qualify blocked dependencies.

## Checkpoint verification and unfinished work

Root handoff check: `python -m unittest discover -s .github/tests -p 'test_*.py'`
passed 150 tests with one skip. Native focused results appear below. Git
delivery identifies this document's commit. Historical RED/GREEN details remain
in the individual work orders. This checkpoint preserves ongoing work and
does not claim production readiness, installed lifecycle success or release.

Maintenance agent stopped with no active commands or further source edits.
Remaining integration documentation: architecture/contract wording, finite
schema2 receipt and GUI lifecycle work-order evidence. Initializer work order
records fresh live-health failure and conflict preservation tests; full
successful schema2 initialization in a real install remains a VM gate.
The maintenance worker currently checks every receipt release file before
stopping owned processes; app-written changes such as pycache may make it
refuse an update. Assess this in real app testing; do not relax ownership
checks to get a passing test. Native GUI progress callback/failure behavior
has not yet received the separate inert lifecycle check.

Root repeated these current native PowerShell 5.1 checks, all PASS:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerBuildTail.Tests.ps1
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerBuildProcess.Tests.ps1
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerInitialSelection.Tests.ps1
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/UpdaterOwnedStop.Tests.ps1
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/UpdaterSelectionLock.Tests.ps1
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerMaintenanceWorker.Tests.ps1
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerMaintenanceReceipt.Tests.ps1
git diff --check
```

These host/inert checks are not actual Setup/uninstall/update VM evidence.
The maintenance agent had not rerun two corrected builder fixture failures;
root's subsequent complete 150-test Python run passed on the stable sources.

Transfer audit: read-only `vm_handoff_audit` independently inspected current
source, r8 packet and review; root owns integration. Actual per-run model
telemetry was not exposed. All new source/tests/docs in this checkpoint are
development work; no public release pin was promoted for the CPU candidate.

## Git delivery and CI at handoff

Source checkpoint commit: `4897a044431c476de99008a1ea02eb7c8bf13c58`, pushed
to `origin/work/v41-current-app-at01`; `git ls-remote` confirmed that exact
remote SHA and the working tree was clean. A subsequent documentation-only
commit records this delivery status; use `git log -1` for the final handoff head.
The separate ZIP must still be copied to the destination: it is not uploaded
to GitHub or reachable merely by cloning this branch. Verify the committed
outer SHA-256 in `vm-handoff-transfer.json` before extraction.

GitHub [Runtime release checks for the source checkpoint](https://github.com/Farkoal2128/autoclip-runtime/actions/runs/37090630411)
completed **failure**. Public installer/app pin checks passed. Repository
checks failed at `Pinned upstream asset regression cases` on Ubuntu/macOS and
`Prerequisite consent and CUDA provisioning regression cases` on Windows.
Public annotations report exit1, not the underlying exception; no root cause
or fix is claimed here. Resolve these regressions before release. The listed
local 150-test/seven-suite successes cover different checks and do not make
CI green. `gh` was not authenticated on this host; the public GitHub API
provided the run/jobs/annotations status without changing authentication.
