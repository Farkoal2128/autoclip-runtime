# IM-INNO-DL-02: Inno protected downloader integration

Authorization: parent work order explicitly authorizes replacing native Inno
downloads in `installer/AutoClip.iss`, with this report. Parent subsequently
expanded ownership to `installer/download-artifact.ps1`,
`tests/InstallerDownload.Tests.ps1`, and the IM-DL-01 report for cooperative
cancellation. Root owns manifest, guarded builder/receipt and other tests.
No Python integration, prerequisite installation, publication or commit was
performed.

Requirements: `contract-v1.md` installation steps 3 and 6, protected exact
official acquisition, no unapproved redirect requests, responsive cancellation,
safe staging cleanup, verified cache retry, and unchanged active installation.
Classification: installer/updater. Existing dependency identities remain
manifest-derived, with no new acquisition approval or distribution route.

## Change

The setup embeds and audits the downloader. Before every helper call, Inno
verifies the embedded dependency manifest against its compile-time SHA-256.
It invokes the exact embedded PowerShell script via an absolute native system
PowerShell path with fixed `ManifestPath`, `Identity`, `DestinationPath` and
`CancelPath` arguments. The helper resolves the manifest's exact URL, bytes,
SHA-256, classification and redirect host policy. Inno checks the returned
local artifact hash against the existing compile-time pin before extraction.
The MinGit, uv and source-release paths all use this route.

Inno's built-in COM automation launches the child without a synchronous
`Exec` window-disabler. A native marquee page keeps the UI responsive while
polling child status every 100 ms. Its Stop button writes the TEMP cancellation
signal, disables further clicks and waits for child cleanup/exit. No force
termination or new plugin is used. Child output/error is logged after exit;
the marquee displays the current artifact phase, not a fabricated percentage.

The optional helper cancellation path is validated as absolute, under TEMP,
with no traversal, alternate stream, destination collision or reparse point.
Header and body async waits poll it every 100 ms and cancel/dispose pending
transport before owned staging cleanup. Header timeout remains five minutes;
body inactivity remains 30 seconds. A completed download is not installation
success and does not activate a release.

## RED and GREEN

1. Before production Inno edits, ran the exact historical diagnostic
   `D:\AutoClip-Inno-Migration\diagnostic-20261001h\AutoClip-Setup-v1.exe`
   with `/AUDIT /VERYSILENT /SUPPRESSMSGBOXES /LOG=<new log>` using
   `Start-Process -WindowStyle Hidden -Wait -PassThru`. Asserted that the
   executable audit exposed `download-artifact.ps1` with its embedded hash.
   The command exited 1: `RED: exact diagnostic EXE does not expose embedded
   approved downloader.` This inspected actual executable extraction/audit
   behavior, not source text. Evidence log:
   `C:\Users\beilo\AppData\Local\Temp\autoclip-inno-dl-red-70461b7fac0e40d68645d989413f37e7\audit.log`.
2. Before helper extension, ran
   `powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerDownload.Tests.ps1`.
   RED exited 1: `A parameter cannot be found that matches parameter name
   'CancelPath'.` The new test schedules a cancellation file from a .NET timed
   writer while a real `Task<int>` remains pending. It checks header/body
   cancellation and exit within five seconds, without timeout shortening or
   production transport bypass.
3. After implementation,
   `powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerDownload.Tests.ps1 -RealDownloads`
   exited 0. All behavioral cases and actual official uv/MinGit downloads
   passed. Exact downloaded sizes/hashes are in IM-DL-01.
4. Direct diagnostic ISCC compile exited 0. This diagnostic deliberately does
   not claim to pass the guarded installable-build gate, since required
   dependency routes remain blocked. Exact command expanded below.
5. Ran the new exact diagnostic executable with `/AUDIT` and checked all six
   embedded audit hashes against local source/helper/manifest/notice hashes.
   GREEN exited 0. This proves exact helper packaging and extraction, not the
   interactive download/Stop workflow.

## Exact diagnostic command

Run from `D:\Projects\autoclip-runtime`; compiler arguments were passed as
separate PowerShell array entries. The original output directory was new.

```powershell
& D:\AutoClip-Inno-Migration\InnoSetup7\ISCC.exe `
  --output-dir=D:\AutoClip-Inno-Migration\diagnostic-DL02-98fd1f0b0c31468992c2eb97bf2c85cf `
  --output-filename=AutoClip-Setup-v1 `
  --define=ReleaseUrl=https://github.com/Farkoal2128/autoclip-runtime/releases/download/v0.1.0-dev0-windows-source-v40-20260928/autoclip-source-build-v40-provenance-continuity.zip `
  --define=ReleaseSha256=f2b3be779294bc55d6f5f56c2a780a2d6b863486f3af9bd7d19f30051961fc9f `
  --define=ReleaseManifestSha256=7fbf72038be30522bc176002082fddd92fd4e057159765726e77806a296658e2 `
  --define=ReleaseId=v11-20260928-source-build-candidate-v40-provenance-continuity `
  --define=DependencyManifestSha256=76035b84bb228382cb2dcb88775b8c238dbd14aa110398312525656cf264b526 `
  --define=BootstrapScriptPath=D:\Projects\autoclip-runtime\install.ps1 `
  --define=DependencyManifestPath=D:\Projects\autoclip-runtime\release\manifests\installer-dependencies-v1.json `
  --define=MinGitUrl=https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.3/MinGit-2.55.0.3-64-bit.zip `
  --define=MinGitSha256=f48e2d2dc74a24454adc6d8fd0ac25bf9c2386f19cfb06202b9465aaad4f9f05 `
  --define=UvUrl=https://github.com/astral-sh/uv/releases/download/0.12.19/uv-x86_64-pc-windows-msvc.zip `
  --define=UvSha256=6dbb02d79e419522f1c500f0adb1cddcff0cda7d59b0d66ea7f5e3b4a1b2f5f0 `
  D:\Projects\autoclip-runtime\installer\AutoClip.iss

Start-Process -FilePath D:\AutoClip-Inno-Migration\diagnostic-DL02-98fd1f0b0c31468992c2eb97bf2c85cf\AutoClip-Setup-v1.exe `
  -ArgumentList '/AUDIT', '/VERYSILENT', '/SUPPRESSMSGBOXES', '/LOG="D:\AutoClip-Inno-Migration\diagnostic-DL02-98fd1f0b0c31468992c2eb97bf2c85cf\audit.log"' `
  -WindowStyle Hidden -Wait -PassThru

git diff --check -- installer/AutoClip.iss installer/download-artifact.ps1 tests/InstallerDownload.Tests.ps1 docs/installer-migration/work-orders/IM-DL-01.md docs/installer-migration/work-orders/IM-INNO-DL-02.md
```

## Exact snapshot and limits

- Setup executable SHA-256:
  `706815bb9bc46c477e802fa0481aa072374bfd6151a31cc161eca09f7e6f257d`.
- `installer/AutoClip.iss` SHA-256:
  `4ed830ee73cd39d054e10b3ecce8478d249f348b60917c419b939b07a3910cf1`.
- Downloader SHA-256:
  `31c3586f1ccde612ddafb72e74f69e264d00404fbc0b6f4ef2e7f45b752f9369`.
- Downloader tests SHA-256:
  `5adb81f47486cc01f721f6e950326ec0861e3e601b207deba5647f758975da47`.

This is developer-machine helper/network and exact executable audit evidence.
No clean-machine download, actual wizard Stop click, prerequisite installation,
source build, installed media workflow, human/legal review or publication gate
was performed by this work order. The parent received the exact EXE/source
hashes for its VM test. External process termination or machine shutdown can
still interrupt cleanup; cooperative Stop waits for the helper's normal failure
cleanup instead of force killing it.

Primary API documentation/source inspected:
[Inno COM automation](https://jrsoftware.org/ishelp/topic_scriptautomation.htm),
[native marquee page](https://jrsoftware.org/ishelp/topic_isxfunc_createoutputmarqueeprogresspage.htm),
[native path redirection](https://jrsoftware.org/ishelp/topic_isxfunc_applypathredirrulesforcurrentprocess.htm),
[Inno Exec implementation](https://github.com/jrsoftware/issrc/blob/main/Projects/Src/Setup.ScriptFunc.pas),
[Windows Script Host Exec](https://learn.microsoft.com/en-us/archive/msdn-magazine/2002/may/scripting-windows-script-host-5-6-boasts-windows-xp-integration-security-new-object-model).
