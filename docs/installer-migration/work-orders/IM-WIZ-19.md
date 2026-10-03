# IM-WIZ-19 — Python log composition and absent-target alias exclusion

Status: meaningful native RED/GREEN and adjacent regressions passed; frozen
for parent integration. Child owned only `installer/run-source-build.ps1`, new
`tests/InstallerBuildComposition.Tests.ps1`, and this report. Parent owned the
one-line Inno configuration fix and contract update. No previous report/test,
Python helper, bootstrap, vendor/VM/server control or volume policy was changed.

## Finding 1: actual Python producer and source storage

The test resolves the actual `PreparePython` function's `-LogDirectory`
ExpandConstant literal from current `AutoClip.iss`, substitutes only the native
LocalAppData environment location with an isolated protected fixture, and
executes the actual extracted `Install-AutoClipPython` function. Declining
terms stops before manifest/vendor work but performs its real Directory
CreateDirectory and receipt write. It then executes actual source
Initialize-BuildStorage with that same isolated LocalAppData dependency.
No producer directory behavior or storage ACL behavior is mocked.

RED command:
`powershell -NoProfile -File tests/InstallerBuildComposition.Tests.ps1 -ProducerOnly`
exited1 with ownership/DACL rejection. Original Inno Python path
`{localappdata}\AutoClip\Setup\logs\python` caused inherited, unprotected Setup
and logs parents, which correctly failed WIZ17's existing-parent protection.

Parent then moved the one Inno argument to
`{localappdata}\AutoClip\PythonSetupLogs`, preserving prior log directories and
the Python helper policy. The identical test rerun exited0: actual declined
receipt remained byte-identical and source storage obtained protected parents.
No source protection assertion was weakened.

## Finding 2: distinguish existing and absent aliases

The review concern needed runtime qualification. On native Windows PowerShell
5.1.26100.9444 / CLR4, an existing short target is expanded by .NET GetFullPath,
and actual alias workers already excluded one another before this change.
Microsoft documents short-name expansion for
[Path.GetFullPath](https://learn.microsoft.com/en-us/dotnet/api/system.io.path.getfullpath?view=netframework-4.8.1).
Native GetFullPathNameW's different behavior alone did not prove this .NET
implementation wrong. The review's broad existing-target claim is narrowed,
not erased from the historical review.

However, a genuinely absent suffix left its immediate existing short ancestor
unexpanded. The initial fixture that created the target before observation was
GREEN; it did not expose this gap. Tightened fixture holds the first actual
bootstrap before creating the absent target. Its second actual worker uses a
confirmed distinct GetShortPathName alias of the same existing ancestor plus
the same absent suffix. Both spellings remain absent during lock observation.

RED command:
`powershell -NoProfile -File tests/InstallerBuildComposition.Tests.ps1 -AliasOnly`
exited1 after both actual bootstrap-entry signals appeared. Recorded normalized
inputs differed: long ended `long existing target ancestor True\new target`,
short ended `LONGEX~2\new target`. Existing-target case remained GREEN. Fixture
finally created/released only its own target and observed both terminal workers;
no worker was killed or restarted to produce evidence.

## Minimum production fix

One small `Get-BuildTargetIdentity` normalizer walks to the deepest existing
ancestor, uses existing Assert-BuildPath/.NET GetFullPath expansion on that
ancestor, appends the known-safe absent components, revalidates and uppercases
before hashing. It also rejects a file ancestor and foreign-write/reparse
ancestors. This reuses standard library behavior and existing security checks;
no new production native API, dependencies, public switches or argument fields
were added. Existing exclusive lock acquisition/holding/release is unchanged.

## Final GREEN commands

All final exact commands exited0:

- `powershell -NoProfile -File tests/InstallerBuildComposition.Tests.ps1`
- `powershell -NoProfile -File tests/InstallerBuildStorage.Tests.ps1`
- `powershell -NoProfile -File tests/InstallerBuildProcess.Tests.ps1`
- `git diff --check` (existing CRLF conversion warnings only).

Composition test covers the actual producer path, real short/long existing
target and two-component absent target. It records equal actual canonical
identities, rejects the second worker before bootstrap while the first stays
live, and proves short-alias retry after terminal release. Direct actual
normalizer cases reject foreign-write, reparse and file ancestors. Adjacent
suites preserve durable logs, independent-root concurrency, input locks,
cooperative cancellation, serialized completion and unsafe-path refusal.

GetShortPathName confirmed real 8.3 aliases on eligible newly created temporary
fixtures. The test tries recipient TEMP then a writable repository-parent
fixture; if neither exposes an alias it reports UNSUPPORTED/exit3, never fake
GREEN. Read-only volume queries were performed; no volume settings were
changed. Fixture paths/receipts/logs are preserved. No VM, vendor installation,
network acquisition, compiled setup, application, immutable recipe/archive,
server transfer or uninstall execution occurred. Full Inno/cold-machine and
production-ready-before-uninstall gates remain parent work.

## Frozen SHA256

- `installer/run-source-build.ps1` (18901 bytes): `95a40597f6d196ad3ae23a6bc5a869899f5c0602fb89dcd2de11bf6277475ae0`
- `tests/InstallerBuildComposition.Tests.ps1` (11720 bytes): `ad86112fcd5ddce9eecc34c9c7c43df0340dffe470daec723e201bdc369402b7`
- Unchanged `install.ps1`: `2e2372a0c29cfa933eebccb0cb4495a179c3ad249ed747f8f5db048b32edbe2d`

Parent updates the existing wrapper pin. The agreed WIZ17 durable attempt
directory, zero-byte native target lock and cancellation interface remain.
