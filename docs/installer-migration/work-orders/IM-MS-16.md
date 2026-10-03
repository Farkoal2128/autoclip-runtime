# IM-MS-16 — align source guard with inherited extraction-root ACL

## Authorization and requirement

Parent explicitly authorized a bounded production bug fix in `Invoke-AutoClipMsysSource`, its focused test, a new r2 guest probe/test companion and this report. Parent owns canonical contract changes. Existing concurrent edits were preserved. No guest/vendor/MSYS execution, VM/root ACL mutation, host operational configuration change or delivery-route promotion was performed.

The base/extraction contract protects the owned extraction **parent**. The extracted `msys64` descendant inherits the same recipient/SYSTEM/Administrators rules; it need not carry its own protected-DACL bit. The source guard must validate that protected parent and the root's effective ownership/write ACL independently. Receipt-parent protection and all existing file/path/pin checks remain required.

## Primary failure evidence

Read and independently hashed `D:\AutoClip-Inno-Migration\vm-msys-source-failure-39a44eacc111.json`: SHA-256 `39a44eacc111ea5cd6d54afbb9ffd8a77084d132925394e86d523296e2134245`.

The parent-performed original probe reported `FAILED_PRESERVED`, `queries_completed=false`, no native process, and `MSYS2 source path requires recipient ownership and protected DACL.` at the unmodified prerequisite-section phase. Parent independently observed a protected recipient-owned extraction parent and an unprotected child root with precisely the same three inherited allow rules. This worker did not run the guest probe or modify that root. Original full receipt remains guest `acmsq-f248f03dbfc8/source-query-receipt.json`, with transport/preservation parent-owned.

## RED → GREEN

Exact focused command from `D:\Projects\autoclip-runtime`:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerMsys2SourceGuard.Tests.ps1
```

Before production modification, the test stopped manually protecting the child root, asserted the root had exactly three inherited rules and no protected bit, then executed the real guard/prerequisite section. RED exit 1 reproduced `MSYS2 source path requires recipient ownership and protected DACL.` before native queries.

The minimum production delta replaces the root protected-bit requirement with:

```powershell
Assert-AutoClipMsysProtectedPath (Split-Path -Parent $root) -RequireProtected
Assert-AutoClipMsysProtectedPath $root
```

Final GREEN exit 0: the same inherited-root fixture successfully executes the actual prerequisite and build-entrypoint boundaries. New negative controls reject an unprotected extraction parent while a separate receipt anchor remains protected, and reject an explicit Everyone write grant on the inherited root. All existing missing-binding, tamper, duplicate/extra closure, elevation, package/schema, archive/manifest binding, private HOME, real file-lock and success/error environment-restoration controls pass.

An intermediate fixture ACL update through `Set-Acl` raised a `SeSecurityPrivilege` error. The fixture uses standard `DirectoryInfo.SetAccessControl` and explicitly marks restoration DACL state before applying it; no privileges were enabled and no production ACL API changed.

Related PS5.1 commands, all exit 0:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerSecureAcquisition.Tests.ps1
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerNoAcquisition.Tests.ps1
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InlineInstaller.Tests.ps1
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerFFmpegIntegration.Tests.ps1
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File tests/InstallerPythonPin.Tests.ps1
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File D:\AutoClip-Inno-Migration\vm-transfer\msys-source-query-probe-r2.Tests.ps1
```

## r2 preparation and frozen hashes

New `msys-source-query-probe-r2.ps1` differs from the frozen original probe **only** in the exact `install.ps1` SHA-256. It retests the existing qualified root and unchanged manifest/package/archive bindings. It preserves the ordinary-user/native-x64 context checks, protected fresh receipt stage, actual unmodified query slice, bound startup guard, missing-binding/restoration controls and captured non-login observed-version query. It never modifies the existing root ACL. The new runnable companion differs only in the probe filename and reuses the focused production fixture suite.

Parent guest command:

```powershell
powershell.exe -NoProfile -File .\msys-source-query-probe-r2.ps1 -VerifyQueries -PostResult
```

Frozen SHA-256:

- `install.ps1`: `019478ef1a87a10eabbd978534fc46632c3b55601df78db2aa94afda5c3b6aeb`.
- `tests/InstallerMsys2SourceGuard.Tests.ps1`: `f7b0a51468342f7cbf0e43b140104ec5a63ca1d84aa95008324a687d5696bd9d`.
- New r2 probe: `9d77e7e7d03d24f3919881c072eb1f6c9133e42da1e27ffa2c7f942a2af103d8`.
- New r2 tests: `22b0e5689882d9b05c589739c397e533aa3106f9ba0d52de10a8b5b11f010eb6`.
- Preserved original probe: `8ae676cf1970a2ee5285ea0f7c792a5182036d3849ba5f966cc58ce3d21bfddd`.
- Preserved original tests: `c2b53d76b1930ac996d211338de31510998bc574603e8254a0d5419796ccb944`.

## Limits

This is host first-party fixture GREEN and guest preparation. It does not claim successful r2 guest queries, real source compilation or whole-wizard qualification. Root performs native guest retest and preserves the full protected receipt separately from the compact `/msys-state` POST. Individual file-lock and native query timeout limits from IM-MS-13/15 remain unchanged. Production remains `BLOCKED`; the original immutable v40 recipe and original IM-MS-15 evidence remain preserved.

## Parent real guest integration

The original full failed receipt was transported unchanged and verified:
`D:/AutoClip-Inno-Migration/vm-msys-source-failure-primary-164b1c372dfa.json`,
SHA256 `164b1c372dfabc8ead18719b088d98ebddfe1eb97f39d198a649398981729963`.
The separate read-only ACL observation is preserved as
`vm-msys-source-acl-714436d35297.json`, SHA256
`714436d352977446d6785858916953a6a222c5abc8103cfe596566fa41c40832`.
It proves protected parent, inherited recipient-owned root and protected logs,
with exactly recipient/SYSTEM/Administrators full-control grants.

The hash-frozen r2 probe then passed on the SAME existing root and unchanged
receipts, without an ACL mutation or root replacement. Full primary receipt:
`D:/AutoClip-Inno-Migration/vm-msys-source-r2-primary-8526d4ae4ae6.json`,
SHA256 `8526d4ae4ae6979e5af2f3e17cd4e9f24451916278d8ee66b33de9a57be747d1`.
The compact summary is `vm-msys-source-r2-success-df0101262ab3.json`, SHA256
`df0101262ab36c480614d93daa3677cac270d14da796c1e8d944df0965d5c3f5`.

Root independently checked VERIFIED_SOURCE_GUARD_QUERIES, completed actual
prerequisite section, exact installer input pin, three environment restoration
flags, and the fixed observed-version process exit 0 with `live=false`.
Observed versions match all five package pins and Make/diff/pkgconf/NASM
capabilities. The actual section suppresses individual stdout; this receipt
does not infer a native process count from that suppressed output.
The extra non-login observation used UCRT64, authenticated private HOME,
controlled PATH and process-only Git longpaths configuration. Whole source
compilation, complete Inno installation and final release remain unverified.
