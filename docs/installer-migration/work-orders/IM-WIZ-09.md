# IM-WIZ-09 — adapt the MSYS wizard decision fixture

Status: fixture compilation passed; runtime cases not executed.
Parent authorized only `tests/InstallerMsys2Wizard.Tests.ps1` and this report.
Root owns Inno source, builder, manifests and integration. No vendor code,
network acquisition, VM action, compiled fixture execution or uninstaller test.

The fixture extracts the actual `PrepareToInstall` and MSYS decision functions.
Its former fake synchronous `ExecWithNativeSysDir` boundary became obsolete
when production began calling `RunSourceBuild`. The test now leaves extracted
decision functions verbatim and supplies the new first-party boundary signature.
It requires exact prepared MSYS root, base/package receipt paths, package pin,
no cancelled state, exact existing archive path, and the fixture's already
available tools before counting a build. It produces the same first-party
marker/manifest/launcher outputs. A fake `BuildAttemptDirectory` supplies error
text. All existing thirteen cases and their assertions remain intact; the
unused production `MsysBuildArguments` was not changed.

## Verification

Exact command, before and after the fixture adaptation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Wizard.Tests.ps1 -CompileOnly
```

Before: exit 1, actual compiler error `Unknown identifier 'RunSourceBuild'`.
Evidence directory:
`C:/Users/beilo/AppData/Local/Temp/autoclip-msys-wizard-20e81ab6290547e0a3de1fcace5e0137`.

After: exit 0, using the existing approved Inno 7.1.0 compiler pinned
`d06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a`.
Evidence directory:
`C:/Users/beilo/AppData/Local/Temp/autoclip-msys-wizard-b35faaf59c664c7da13b60199353f29e`.

| Artifact | SHA256 |
| --- | --- |
| `tests/InstallerMsys2Wizard.Tests.ps1` | `d75e9853b024027fecef222a1049d59570eb7cbe33ae8ec1bfa365263b7b1704` |
| `diagnostic.iss` | `c3fd5b6c8df71381c966450604f651d904a11940d09201a9a453f09abed1bfbe` |
| `msys-decision-diagnostic.exe` | `fe81bb6154247b3e6ae736614d1ead8604b5413cf08c69dff665cebd90ee6704` |
| `compile.log` | `72992e64a0a22d0a448674567bdb829149a28362de58a9d436392098a945348e` |

`git diff --check` exit 0, with existing CRLF warnings.

This proves fixture syntax/interface compatibility only. The thirteen runtime
case assertions and isolated guards were preserved but not executed here.
The previously refused compiled audit/diagnostic action was not retried through
this fixture. No claim of actual wizard responsiveness, cancellation,
prerequisite installation, source build, health, lifecycle, blind review or
release readiness follows from compilation. Uninstaller tests remain scheduled
after the installer works and is production ready, before release.
