# IM-WIZ-08 — hidden, logged, cooperative source-build boundary

Status: first-party host behavioral checks passed; frozen for parent integration.
Installer/updater change authorized by parent IM-WIZ-08. Contract basis:
`contract-v1.md` responsive build page and cooperative cancellation paragraphs,
runtime architecture progress/activation requirements, and IM-WIZ-07 handoff.
Ponytail Full: reuse native PowerShell, existing source bootstrap, and Inno's
asynchronous page loop. No plugin, job object, process kill, immutable recipe
change, application code, VM action, or uninstaller test.

## Owned files and frozen hashes

| File | SHA256 |
| --- | --- |
| `install.ps1` | `6f2809b3aa7a007606d00e65570013a04637a65a06ad47c79b84dd97066a5a93` |
| `installer/run-source-build.ps1` | `c69cace7ce9f5988918e0208118b4838316d39c3e6e4d3aa0ff1a8d3267c1ead` |
| `tests/InstallerBuildProcess.Tests.ps1` | `cd946fe45123bc8d604a13c3c72f5e29c23afe3afcc5587b4c6b8d529a0dc5dd` |
| `tests/InstallerMsys2SourceGuard.Tests.ps1` | `42e88b24f33f42d070e80ea3e2b6589780edfd406b5081ab072aa1a4a90013cf` |

The last file was separately authorized for one fixture dependency allowlist
addition. Its assertions remain intact. Previous edits by other agents were
preserved; no original diagnostic/bootstrap copies were changed.

## Integration interface

Builder must bind/include the helper as a first-party setup input and add
`SourceBuildHelperPath` and `SourceBuildHelperSha256` compiler definitions.
The parent owns builder and Inno changes; none is claimed implemented here.

Call the helper with these mandatory parameters:

- `BootstrapPath`, `BootstrapSha256`: exact new standalone bootstrap.
- `ManifestPath`, `ManifestSha256`: exact setup dependency manifest.
- `DownloaderPath`, `DownloaderSha256`: exact production downloader.
- `ArgumentsPath`, `ArgumentsSha256`: locally authored argument JSON and pin.
- `HelperSha256`: exact helper pin, including when its worker reloads itself.
- `AttemptDirectory`: fresh nonexistent directory under trusted staging.

Arguments JSON has only `schema_version: 1` and `parameters`. Paths allowed:
`InstallRoot`, `ArchivePath`, `ExternalCache`, `NativeBuildRoot`, `MsysBash`,
`MsysPackageReceiptPath`, `MsysBaseArchivePath`, `GitExePath`, `UvExePath`,
`CudaRoot`, `FfmpegArchivePath`. Hash strings allowed:
`MsysPackageReceiptSha256`, `ToolArchiveHelperSha256`,
`RuntimeToolPathHelperSha256`. Boolean switches allowed: `NonInteractive`,
`NoPrerequisiteAcquisition`, `SkipDesktopShortcut`, `InstallNvidiaGpu`,
`AcceptNvidiaTerms`, `AcceptCublasTerms`, `AcceptMicrosoftTerms`,
`AllowPinnedNvidiaAcquisition`, `OfflinePublisherCache`.
The first three must be Boolean true; `InstallRoot` and `ArchivePath` are
required. Consent values must come from the parent's actual recipient decision.
No prerequisite-only, release-info, terms-display, arbitrary script, evaluated
command, or supplied cancellation-path argument is accepted. The helper inserts
its own manifest/downloader pins and `CancelPath` into the typed splat.

The helper protects the new attempt DACL for current SID/SYSTEM/Administrators,
rejects reparse ancestors and foreign effective writers on selected paths,
and holds five `FileShare.Read` input streams across the actual worker. Worker
mode repeats the same validations/pins; it is not an integrity bypass. These
are ordinary-recipient integrity controls, not permission to elevate code from
a recipient-writable directory or protection against every same-SID ancestor
directory race.

The supervisor launches its own same helper in worker mode through the absolute
native Windows PowerShell path resolved using Windows' special-folder API. All
worker stdout/stderr go to protected `stdout.log` and `stderr.log`; outer output
remains bounded (normally empty). Output text is never parsed as authority.
`tail.txt` contains at most 2048 bytes from each log decoded as display text.
`status.json` is atomically replaced with schema, attempt/release binding, all
five pins, coarse phase, worker PID/start time, state, cancellation Boolean,
and nullable integer exit code. States are `RUNNING`, `CANCELLATION_PENDING`,
`TERMINAL`. Inno should poll files while animating its existing page and show
full-log paths. A phase percentage is not inferred from native output.

Write `cancel.txt` in the attempt to request cooperative cancellation. Never
kill or restart the worker on an observation timeout. Both ordinary/nonzero
completion and cancellation retain logs/staging. Cancellation overrides a
raced zero process result with exit **1223**. Other integer worker exits are
propagated (fixture **7** proved). An observation exception keeps input locks
and waits for actual worker terminal state before returning; it is not a
claim of prompt cancellation or descendant containment.

The source bootstrap's optional `CancelPath` is validated before acquisition,
before immutable recipe invocation, before completion marker, and before
launcher work. Cancellation arriving immediately after the new marker causes
only that exact unchanged newly created marker to be removed before launchers;
modified or reparse-marked paths are preserved/rejected. Without `CancelPath`,
the existing standalone behavior remains unchanged. Inno's own cancelled flag
must still override helper success. Marker/exit success is not application
health or installed media evidence.

## RED and GREEN evidence

Before production edits, command:
`powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerBuildProcess.Tests.ps1`
failed exit 1: `RED: source-build process boundary is missing.`

Additional original-behavior reproduction used the preserved exact old
`D:/AutoClip-Inno-Migration/install-ms16-019478ef1a87.ps1` completion slice
after implementation, without vendor execution: an existing cancellation file
still produced `.install-complete` and one launcher call, expected exit 1.
This is an original-behavior reproduction, not claimed pre-edit RED timing.

The same focused suite final run passed exit 0:

- Real first-party child emits over 1 MB, finishes without pipe deadlock, and
  retains full disk logs with bounded tail.
- Spaces and Unicode in the actual typed install-root argument survive.
- Wrong hash, diagnostic argument, and string-instead-of-Boolean reject.
- Real child exit 7 propagates with retained logs.
- Worker is observed live; concurrent bootstrap write is denied by readlocks;
  cooperative cancellation waits for actual terminal process, exits 1223,
  and the observed owned worker PID no longer exists.
- Foreign-write input ACL and junction attempt reject before worker execution.
- Actual new source completion slice refuses cancellation before marker and
  launcher; deterministic cancellation immediately after marker removes it
  before launcher execution.

Adjacent exact commands, each exit 0:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerNoAcquisition.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2SourceGuard.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerSecureAcquisition.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallLaunchers.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerFFmpegIntegration.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InlineInstaller.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerPythonPin.Tests.ps1
git diff --check
```

Source guard initially failed because the fixture did not load the new helper
dependency; parent authorized adding it to the AST extraction allowlist.
Actual source queries/actions and all existing negative assertions then passed.
Diff check printed existing CRLF warnings, with no whitespace error.

These are first-party host tests, not an exact setup executable, actual vendor
build, VM wizard/visual responsiveness, clean installation, application health,
media workflow, technical review or release approval. Native detached-child
behavior and final Inno page/error integration remain parent verification.
Actual uninstaller testing explicitly waits until the installer is working and
production ready, then occurs before release under the latest user instruction.
