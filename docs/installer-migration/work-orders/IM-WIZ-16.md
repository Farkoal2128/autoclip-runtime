# IM-WIZ-16 — verified app health before source completion

Status: focused host tests and adjacent regressions passed; frozen for parent
integration. Owned files: `install.ps1`, the pin allowlist only in
`installer/run-source-build.ps1`, new `tests/InstallerBuildAppHealth.Tests.ps1`,
and this report. No existing fixture adaptations were needed. Other writers'
Inno, builder, contracts, helper and VM files were preserved.

## Requirement and boundary

The installer contract requires application health before completion marker,
shortcuts or activation. The source previously completed after native imports
without checking the installed application. Add optional bootstrap parameter
`AppHealthHelperSha256`. Managed builds with `CancelPath` require a valid SHA256
before acquisition/native work. Existing standalone/component callers without
either parameter retain their previous behavior.

The fixed helper basename is `verify-installed-app.ps1`, adjacent to the
bootstrap, with the existing repository `installer/` fallback. No caller can
provide an arbitrary executable path. Verify its bytes through the existing
secure-input reader and execute the captured UTF8 scriptblock. The wrapper
accepts this pin as a typed 64-hex string; no other interface was broadened.

Invoke the helper before the completion action and serialized commit, with
current install root and pinned release manifest. Managed builds supply the
fresh fixed protected attempt path `health-result.json`; existing output is
preserved and rejected. Require exactly one verified status/result object,
regular/non-reparse protected output, bounded JSON, matching root/manifest,
actual helper status and child exit/health/home statuses, and Boolean scope
fields. Hold a read lock while hashing, validating and recording the result.
Check cooperative cancellation after health and before/after receipt work.

The existing native receipt gains optional `setup_app_health` containing
`result_path`, `bytes`, `sha256`, `install_root`, `manifest_sha256`, and `status`.
It preserves the immutable recipe receipt fields and installed-file meaning.
Inspected consumers `update.ps1` read `installed_files` and `profile`, and
bootstrap launcher retry reads `setup_owned_launcher`; they do not reject this
additional field. Parent owns the contract documentation and setup consumer.

## RED and GREEN evidence

`powershell -NoProfile -File tests/InstallerBuildAppHealth.Tests.ps1`
first exited 1: actual source lacked the verified app-health boundary. After
the minimal hook, an added malformed Boolean case exited 1 because string
`True` incorrectly allowed completion; strict Boolean validation made it GREEN.
Final run exited 0: 18 actual native PowerShell boundary scenarios plus actual
wrapper typed-pin acceptance/rejection. Fixtures cover success/pinned result,
helper failure, foreign root/manifest, failed/duplicate statuses, cancellation
after health, wrong/changed/missing helper, missing pin, preexisting result
preservation, directory/reparse/oversized output, malformed Boolean scope,
legacy behavior, and execution of the actual health helper's failure path.
Tests use actual extracted production functions/completion action, real
protected filesystem output and COM shortcuts. Synthetic health helper success
proves integration only; it does not claim that the application itself worked.
CPU22 owns the actual isolated ASGI health/home success evidence.

Final exact commands, all exit 0:

- `powershell -NoProfile -File tests/InstallerBuildAppHealth.Tests.ps1`
- `powershell -NoProfile -File tests/InstallerBuildProcess.Tests.ps1`
- `powershell -NoProfile -File tests/InstallerCompletion.Tests.ps1`
- `powershell -NoProfile -File tests/InstallerMsys2SourceGuard.Tests.ps1`
- `powershell -NoProfile -File tests/InstallLaunchers.Tests.ps1`
- `powershell -NoProfile -File tests/InstallerSecureAcquisition.Tests.ps1`
- `powershell -NoProfile -File tests/InstallerNoAcquisition.Tests.ps1`
- `git diff --check` (existing CRLF conversion warnings only).

No vendor, VM, archive/recipe, frozen server bootstrap, network, compiled setup
or uninstaller execution occurred. Full installer success remains a parent
gate. Uninstall tests must follow production-ready installer verification.
Current Inno attempt placement under temporary storage makes result/log paths
ephemeral on setup exit; parent has identified durable attempt storage as
follow-on work. This hook does not claim durable logs or desktop/media/model
acceptance from the isolated health result.

## Frozen SHA256 interface

- `install.ps1` (407214 bytes): `2e2372a0c29cfa933eebccb0cb4495a179c3ad249ed747f8f5db048b32edbe2d`
- `installer/run-source-build.ps1` (15104 bytes): `caf6485da1d9411b6c9fd44180097d8428a08b464b0b24a75dc62623e6a2639d`
- `tests/InstallerBuildAppHealth.Tests.ps1` (8888 bytes): `62392de517d8d1657c378c23721b4e0eb44772d54b7ac2a81a46ab2efd7aaaa6`
- CPU22's unchanged `installer/verify-installed-app.ps1`: `9f5656ccad347fba939b16fd1ca26003b01c8d50ec4af82270c8c1be37f70756`

Parent passes `AppHealthHelperSha256` in the authenticated argument dictionary
and packages the exact fixed-basename helper; the wrapper's own changed SHA
must also be updated in the existing parent pin/compile interface.
