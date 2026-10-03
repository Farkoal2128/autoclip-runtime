# IM-WIZ-13 — serialize cancellation acceptance and completion

Status: focused first-party host race/regression checks passed; frozen for
parent Inno integration. Parent authorized the two existing helper/bootstrap
files, their behavioral test and this report. Contract basis: version-1 build
cancellation/commit serialization paragraphs. Root owns Inno UI, builder and
contract edits. No VM, vendor executable, network, immutable recipe, diagnostic
source copy, compiled installer or uninstaller execution occurred.

## Requirement and implementation

A button click requests cancellation; it does not establish acceptance.
Accepted cancellation must win before completion starts, while a request after
completion begins must leave that commit intact and report that cancellation
is too late. IM-WIZ-12 checks alone had a gap between the final check and
launcher writes.

The existing hidden helper now supports `-RequestCancellation`, using exactly
the same mandatory path/SHA parameters, typed argument JSON and five held
input readlocks as supervisor/worker modes. It launches no worker in request
mode. Supervisor creates a fixed zero-byte `decision.lock` in its fresh protected
attempt before launching the actual worker. Requester and completion function
open this file exclusively with `FileShare.None`. Requests arriving before
startup wait up to ten seconds for the protected directory/lock; lock contention
has its own ten-second bound. No timeout triggers a kill or restart.

Requester validates directory/file ACLs, owners and reparse ancestors, then
under the decision lock validates any `commit.json`. If no commit exists it
writes the fixed protected `cancel.txt` and returns **0** (accepted). If a valid
commit exists it writes no signal and returns **170** (too late). Startup timeout
returns **2**; unsafe/malformed state and other failures return nonzero. A busy
lock may time out rather than invent an acceptance decision. Requester cannot
unprotect a directory, create the attempt or launch the bootstrap.

The source bootstrap's `Invoke-AutoClipBuildCommit` holds that same exclusive
lock, rejects accepted cancellation and preexisting decisions, and creates
`commit.json` with `CreateNew` before executing the actual existing completion
action. That action writes `.install-complete` and creates owned launchers.
The commit records exactly schema 1, `COMMIT_STARTED`, install root, archive
SHA256, release-manifest SHA256 and dependency-manifest SHA256. The broker
compares them with its pinned local manifest and arguments; logs cannot supply
authority. Existing commit decisions are never overwritten. Worker and supervisor
also validate any existing commit before reporting terminal state.

A request during launcher execution waits for the exclusive lock, then observes
the immutable recorded decision and returns 170. It cannot write a cancellation
signal, so worker/supervisor do not turn committed success into cancellation.
The commit record identifies commit *start*, not application health or eventual
success. A launcher/health failure still requires ordinary failure handling;
commit state is not a success waiver. An external same-SID malicious actor is
not excluded by recipient-owned ACLs; these are application serialization and
ordinary-recipient integrity controls, not new elevation authority.

All IM-WIZ-12 checks between bootstrap-controlled commands remain intact. The
immutable recipe still runs until its whole invocation returns. Direct legacy
invocation without `CancelPath` executes the original completion action without
creating attempt/commit state. A supplied `CancelPath` now requires fixed
`cancel.txt` in the protected attempt with its existing decision lock.

## Inno integration interface

No new mandatory parameter is added. Reuse all existing supervisor parameters
and their exact pins; add only `-RequestCancellation` for a request. `-Worker`
and `-RequestCancellation` together reject. Invoke request asynchronously and
continue observing both the request and the original supervisor process.

- Request exit **0**: set the wizard's accepted-cancellation flag, display the
  cooperative wait and retain the actual worker observation/logs.
- Request exit **170**: do not set cancellation; disclose that commit began and
  continue observing the same worker.
- Request exit **2/other**: disclose request failure/pending status accurately;
  do not invent accepted cancellation or modify the worker's result.

Inno must stop directly writing build cancellation signals. Its accepted
cancel flag still overrides a raced helper zero. Ordinary download cancellation
uses its existing separate boundary and is outside this change.

## RED / GREEN and commands

Before production edits, extended the existing behavioral test with an actual
protected requester invocation. Exact command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildProcess.Tests.ps1
```

RED: exit 1, `A parameter cannot be found that matches parameter name
'RequestCancellation'`. No production edit preceded this failing request test.

Final GREEN: same command exit 0. It proves:

- Request-before-commit returns 0 without launching a worker, and the actual
  serialized completion function then rejects marker/launcher work.
- A real first-party requester process launched during the actual source
  completion action's launcher boundary returns 170, writes no signal and leaves
  committed marker/launcher work intact.
- A requester started before the actual supervisor creates its attempt waits
  for the real protected decision lock, returns 0, and that actual supervisor
  observes terminal worker cancellation 1223.
- The real live-worker cancellation test now uses the broker rather than a
  direct signal write; input readlocks and terminal observation remain proved.
- Malformed, foreign-writable, reparse and wrong-bound commit states fail closed
  without writing cancellation signals.
- All eighteen IM-WIZ-12 CPU/NVIDIA fixture scenarios, uncancelled controls,
  chatty disk logging, Unicode/spaces, typed/hash/path/ACL guards, exit7 and
  terminal cancellation checks remain green.

Adjacent commands, each exit 0:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2SourceGuard.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerNoAcquisition.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerSecureAcquisition.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallLaunchers.Tests.ps1
git diff --check
```

Diff check emitted existing CRLF warnings only. Assertions were preserved where
their contract remains applicable. The previous unsynchronized completion-slice
test was replaced with execution of the actual new completion assignment,
actual call and helper, covering both policy orderings rather than an obsolete
direct late signal. Native commands/launcher effects remain first-party fixture
boundaries; no NVIDIA hardware claim follows.

## Frozen hashes

| File | SHA256 |
| --- | --- |
| `install.ps1` | `edf3fda3081257fc2919630c104e534e0bc5ccd65ce15f760bd5875d3f59359b` |
| `installer/run-source-build.ps1` | `daa1b1ac6094938770845b287e729993317c58d428b4601123a5a29ed2cad9e8` |
| `tests/InstallerBuildProcess.Tests.ps1` | `e4f6966771e091ae1a0dc150c095f16fce22a8bf34ef29ec6204e86146af4813` |

Root still must integrate and verify the exact Inno cancellation UI and final
generated executable. Real build, installed health/media, lifecycle, payload
review and release gates remain separate. Uninstaller testing waits until the
installer works and is production ready, then occurs before release.
