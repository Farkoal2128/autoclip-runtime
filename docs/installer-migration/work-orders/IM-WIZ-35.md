# IM-WIZ-35: finalization integration and native registration spelling

## Scope

Root integrated the WIZ33 receipt producer and WIZ34 source handoff into the
Inno source and builder. This is component verification and syntax compilation;
it is not production installer qualification. No generated uninstaller ran.
User sequencing remains production-ready installer first, then exact generated
uninstaller cleanup and data preservation tests, then release.

## Integration

The builder holds the new receipt helper under the same Windows sharing locks
as other inputs, binds its hash and four notice rows in compiler definitions,
and records its pin. The meaningful helper write/rename regression was RED
before adding it to held inputs and GREEN afterward; the complete eleven
builder checks passed (`python .github/tests/test_inno_build.py`). These tests
use an inert compiler invocation fixture and do not qualify native Setup.

The finalization CLI validates the pinned request, helper and source supervisor,
holds the existing target lock, observes native HKCU registration and generated
uninstaller files, then publishes the complete receipt and bounded descriptor.
Importing its source ownership functions does not finalize setup. Actual native
PowerShell CLI rejection tests proved missing request, unsupported schema and
changed SHA failures without registry mutation or final receipt publication.

The initial native CLI test was RED because the earlier library ignored the
finalization switch and returned zero. The resulting focused CLI suite is GREEN:

```powershell
powershell -NoProfile -File tests/InstallerSetupFinalize.Tests.ps1
```

Final observed native child exits were 1,1,1 with original handles captured.
Full positive native registration/event composition is still unperformed.

## Native InstallLocation RED/GREEN

Read-only integration review found that tagged Inno7.1 writes
`InstallLocation` with `AddBackslash(WizardDirValue)`:
[native producer](https://github.com/jrsoftware/issrc/blob/is-7_1_0/Projects/Src/Setup.Install.pas#L270-L280).
Earlier fixture registration omitted that separator and did not represent the
native producer. Changed the fixture to its exact native value and asserted
that the snapshot retains it; added rejection of the non-native spelling.

```powershell
powershell -NoProfile -File tests/InstallerSetupReceipt.Tests.ps1
```

RED exit1: `Native registration snapshot binding differs.` Minimum fix changed
both library and CLI comparisons to the exact setup root plus one backslash.
No broad normalization or relaxed path binding was added. GREEN exit0, including
native spelling preservation and wrong spelling rejection. Existing provenance,
inventory, changed-file, ACL, reparse and conflicting receipt checks also pass.
Actual first-party COM shortcut/filesystem fixtures are used; no native Setup,
vendor installation or uninstaller operation occurred.

Current helper SHA256:
`ba215751b9708e1507dbef591b11910b5766877286ce5a144f016a5eafcf889d`.
Current library-test SHA256:
`32fb9b13040ee310b5faa1870a437197d650360189556dc71bc6ab1b823808ea`.
CLI-test SHA256:
`6794ceada9d17160e3de3b8ab84b8454ab523cd783b7b6728261e19308a71a2b`.

After the native-spelling fix, the complete source-receipt integration suite
was rerun: six PASS groups, exit0 (`powershell -NoProfile -File
tests/InstallerSetupReceiptSource.Tests.ps1`). The eleven builder tests also
passed again. This verifies actual helper import/completion composition and
held input plumbing with the current helper bytes; the scope remains host
component tests.

WIZ34 producer subsequently reconciled the bootstrap size discrepancy using
exact reconstruction of only its eight edited regions: pre-WIZ34 407214B,
SHA256 `2e2372a0c29cfa933eebccb0cb4495a179c3ad249ed747f8f5db048b32edbe2d`;
current 411748B, SHA256
`a09ccee22724855ab6b31321397b5deec9e02946795ebf781893b910d21a2734`.
The embedded prerequisite-terms region remains 318039B, SHA256
`547a57d219ccc13eeb4a5f951a1bbedad20d5d79ee77f6c9fdd7fde4ceb6ccae`.
The earlier summary's 1407214B figure was erroneous. No source or historical
evidence was altered to perform this comparison.

## Syntax compilation

Existing approved ISCC7.1 executable SHA256
`d06ebd38f38e3cee60a3c50cc45bd449d77e0bc6a5cabc607ea9886808e4de1a`
compiled the current source while all inputs were readlocked. The external
syntax-only driver preserves input hashes, exact command and output identity:

```powershell
python D:/AutoClip-Inno-Migration/compile-current-inno-r2.py
```

Exit0. Latest unexecuted output:
`D:/AutoClip-Inno-Migration/im-wiz-35-syntax-id_i7_p_/AutoClip-Setup-v1.exe`,
3393953B, SHA256
`1fe83f5ffd946cf68fc72403692f248b6dfe4eff3b3e8d5f2071a93557930f3d`.
Its `compile-inputs.json` SHA256:
`4b4f48841e228d4d974be3dada245d396873f057259930627e825a2a1421db39`.
Inno source SHA256:
`40c65622d4f86ff21d8886351551eb9d2bcb9204f797027961b7c4edd5fbccc6`.
Driver SHA256:
`08cd87145abef3c9b79cae106117b3ac54f3e1b2cc47136865875daebad525b6`.

This compile deliberately records `SYNTAX_COMPILE_ONLY_UNEXECUTED`. Canonical
production builder still refuses BLOCKED prerequisites. Neither `/AUDIT` nor
the syntax-only output has executed. `git diff --check` passes.

## Remaining concrete issues

Inno rewrites FinishedLabel after ssPostInstall; the current failure caption
must move to a hook after that native write and needs a real native UI RED/GREEN.
The finalizer also launches before entering its UI try/finally; a display
exception could leave its exact child unobserved. These are open integration
findings, not a release approval. Receipt-backed repair/reinstall, exact Setup
installation and ordinary-user real workflow remain required.

## VM state preservation

Cold-engine VM displayed a Windows scheduled restart prompt. Root selected
the native Another time action, then saved the VM with its pending VS42 help
process and retained handles. No process was killed or inferred terminal.
A separate linked clone from the original clean snapshot was registered as
`AutoClip-Inno-Win11-Direct-20261002`, UUID
`e6661e4b-cdcd-4e1c-baa3-cb34ad5cd3c0`, 8GB/6CPU. The snapshot inherited saved
state; a redundant modify request was refused as not mutable without changing
its settings. No saved state was discarded. The exact SDK agreement consent
question remains pending; no SDK acceptance or product installation occurred.
