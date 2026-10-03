# IM-WIZ-17 — durable source logs and target worker exclusion

Status: bounded implementation and focused/adjacent verification GREEN; frozen
for parent integration. Owned only `installer/run-source-build.ps1`, new
`tests/InstallerBuildStorage.Tests.ps1`, and this report. No historical test or
report was revised. Bootstrap `install.ps1` remains exact WIZ16 bytes.

## Requirement and agreed interface

The installer contract requires full source logs to remain available and
concurrent work against one install target to be rejected. Prior temporary
attempt placement allowed Inno cleanup to remove the health result and logs;
workers had only per-attempt locks and could enter the same target concurrently.
Parent owns the requirement/contract update and Inno directory selection.

Normal durable `AttemptDirectory` is an immediate child of native recipient
LocalApplicationData `AutoClip/Setup/logs`, named
`source-build-<unique Inno temporary basename>-<attempt index>`; the enforced
basename pattern is `^source-build-[A-Za-z0-9_.-]+-[0-9]+$`. The helper safely
creates only the missing fixed storage parents and fresh attempt. Creation uses
the native directory security overload to set the DACL at creation, granting
current SID, SYSTEM and Administrators FullControl. Existing AutoClip parent
must have trusted ownership/effective write access; existing Setup/logs/locks
parents must also have protected DACLs. Foreign writers, reparse paths and
non-directory parents fail without silently resetting their ACL. Existing
arbitrary precreated fixture parents retain their previous behavior; missing
arbitrary parents still fail. Inputs, output logs and attempt remain pinned and
protected as before.

Cancellation request mode never creates storage or launches a worker. For the
fixed durable route it may observe missing parents and wait up to the existing
10-second startup bound for the supervisor's actual protected decision lock.
It revalidates appearing storage, and only accepts cancellation under that
lock. Missing startup returns2 without a signal or accepted-cancel claim.
Existing accepted/late request codes0/170 and serialized commit remain intact.

Every actual Worker route acquires an exclusive native FileStream target lock
before bootstrap invocation and holds it through bootstrap return/terminal
validation. Key: SHA256 of UTF8 bytes of
`GetFullPath(InstallRoot).Replace('/', '\').TrimEnd('\').ToUpperInvariant()`.
File: native LocalApplicationData `AutoClip/Setup/locks/<lowercase key>.lock`.
Require regular, non-reparse, trusted effective ACL and exactly zero bytes.
OpenOrCreate uses ReadWrite/FileShare.None. Busy/open failure rejects immediately
without waiting, restarting, killing or entering bootstrap. The worker's finally
releases the stream; the empty file persists. Different normalized targets use
different files. Targets overlapping protected Setup storage are rejected.
This is filesystem coordination under the existing trusted recipient/admin
authority, not an isolation promise against that same authority.

## RED evidence

- `powershell -NoProfile -File tests/InstallerBuildStorage.Tests.ps1` exited1:
  two actual first-party Worker processes appended entry evidence for the same
  case/trailing-separator-normalized target concurrently. The test released
  their fixture wait gate and observed terminal exit; no process was killed.
- `powershell -NoProfile -File tests/InstallerBuildStorage.Tests.ps1 -DurableOnly`
  exited1: requester/supervisor could not establish accepted cancellation under
  the durable startup decision lock when its fixed parent was absent.

## GREEN verification

Final exact commands all exited0:

- `powershell -NoProfile -File tests/InstallerBuildStorage.Tests.ps1`
- `powershell -NoProfile -File tests/InstallerBuildProcess.Tests.ps1`
- `powershell -NoProfile -File tests/InstallerBuildAppHealth.Tests.ps1`
- `git diff --check` (existing CRLF conversion warnings only).

New behavioral tests run real first-party native PowerShell workers and
supervisors: same-target second worker fails before bootstrap, the original
worker stays live with input locks, different-root worker proceeds, terminal
release allows retry, and zero-byte lock persists. Actual fixed per-user
directories hold retained stdout/stderr/status/tail/decision and fixture health
result after success or exit7. Startup requests precede actual supervisor
creation; accepted cancellation and missing-startup timeout are distinguished.
Tests preserve/reject existing files, arbitrary missing parents, invalid fixed
names, foreign-write/reparse attempts, and nonzero/directory/foreign-write/
reparse target locks. No assertion was relaxed. A fixture ACL mutation needed
DACL-only native access-control methods because Set-Acl attempted unavailable
SeSecurityPrivilege; assertions and production behavior were unchanged.

The fixture health-result file proves storage retention only; WIZ16 and CPU22
own health validation evidence. Actual Inno cleanup/lifecycle verification is
parent work. No VM, vendor, network, compiled setup, bootstrap, immutable
recipe/archive, server transfer or uninstaller actions occurred. No app/user/
cache or persistent lock cleanup is implemented or tested here. Uninstall
execution remains after production-ready installer verification.

## Frozen SHA256

- `installer/run-source-build.ps1` (18120 bytes): `bdbfe445e72461a5e6256bd67afb8bbbf47003b6d840f86c47c5dab0bf06dbb1`
- `tests/InstallerBuildStorage.Tests.ps1` (13006 bytes): `eb881b926becc7dbec6ecef88a81f2ef987f50bd6e564f717092674782b9703f`
- Unchanged `install.ps1`: `2e2372a0c29cfa933eebccb0cb4495a179c3ad249ed747f8f5db048b32edbe2d`

Parent updates the wrapper pin and uses the agreed fixed durable attempt path;
no new public switches or generated argument fields are required.
