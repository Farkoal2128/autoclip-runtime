# IM-CPU-19 — actual CPU source-build guest driver

Status: preparation complete, guest execution pending. Parent-only VM operation.
No production source, canonical manifest, vendor download, vendor execution,
VM state, or prior receipt was changed by this work order.

## Authorization and expected behavior

The parent authorized one fresh private recipient CPU source build using the
existing production source-install entry point. This driver does not implement
another build recipe. It invokes the frozen `install.ps1` once with CPU-only
arguments after ordinary-user/context/input checks and official protected
acquisition. Existing MSVC/SDK/Python and VCOMP are prerequisites; Microsoft
installation and NVIDIA selection/acceptance are outside this operation.

The exact combined diagnostic manifest is
`92fcd18f5f8e7fd905a25513702e45906d7f134cfceb5ac835437f1b45ccb116`.
It differs from canonical `90d618...` only in 25 existing
`BLOCKED` to `DIRECT_RECIPIENT_DOWNLOAD` classifications: MSYS2 and its
signature/key/five package/signature pairs, Gyan FFmpeg, uv, MinGit and nine
native build assets. Full parsed equality after reverting all 25 is checked
before vendor acquisition. Python and VS classifications remain blocked.
There is no production route promotion or publication decision here.

The fresh MSYS base/package chain must naturally bind this final manifest.
The parent supplies the actual current root, package receipt path/hash and
base TAR path; old manifests/receipts cannot substitute or be rewritten.

## Frozen new artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-real-build-probe.ps1` | 18866 | `4be4d06a28ec3cf46ddda27c84d62154695c4109e994c66f89c4393e7b20250e` |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-real-build-probe.tests.ps1` | 4278 | `39c2b47da20052006c0fcb3308923ae9f6e55b109b8fa074d7c688089fbf11bd` |

No writer may mutate these while the parent serves/runs them. The frozen
standalone source input is `019478ef1a87a10eabbd978534fc46632c3b55601df78db2aa94afda5c3b6aeb`;
the server's existing `install.ps1` copy matched that pin during preparation.
New canonical installer changes are separate snapshots.

## Flow and input transport

Default invocation returns `READ_ONLY_PLAN` without paths, network or execution.
`-RunCpuBuild` first requires native 64-bit Windows and an unelevated
`autocliplab` token, explicit frozen manifest hash, actual receipt/root binding,
local absolute paths and no reparse ancestors. It then creates one new short
TEMP stage with protected recipient/SYSTEM/admin-only DACL and at least
35 GiB available disk. The install target remains absent; native and external
roots start empty. No existing installation/cache is selected.

The following first-party controls must be served at
`http://10.0.2.2:8765/<filename>` with their frozen bytes. HTTP serves no vendor
payload in this operation. Every control is hash-checked then kept read-locked
with write/delete sharing denied throughout the build/result validation:

- `install.ps1`: `019478ef...`.
- `download-artifact.ps1`: `75ac92e4108a6fd3165617b2c94be02b44ca86c61a5397672d898eaa38635ad6`.
- `install-tool-archive.ps1`: `685cc6a5924e851dd5387704030a44e42db479a0e147fb994d3c716dc688f7f8`.
- `install-runtime-toolpath.ps1`: `699977ea1234b6cd681b6bf89cae24312cbd9270e13fea2f83a315fdd6d62802`.
- `install-python.ps1`: `081b312795cc8b038de2ce511d2a8baabd23ffec55f7ef2f7269dbbb105f02e3`.
- `installer-dependencies-v1.json`: unchanged canonical `90d618...`.
- `cpu-build-diagnostic-manifest.json`: final `92fcd18...`.

The driver's own bytes, receipt/TAR and synthesized child controls are also
held read-locked. The fixed pinned downloader fetches exact official v40 ZIP,
MinGit, uv and Gyan FFmpeg bytes; extraction reuses the production tool helper
for Git/uv. Every extracted Git/uv file is held read-locked during the child.
The source installer performs all remaining pinned publisher/native/external
acquisitions through its existing guarded callback, and the existing native
recipe performs its exact pinned Git/source checkouts. No host vendor bytes
are mirrored or transported.

Actual registered Python is checked with the pinned production `-CheckOnly`
helper before environment isolation. Compatible installed VCOMP is checked
before acquisition. The actual source installer also performs its normal
VS/SDK/uv/MSYS/FFmpeg prerequisite checks. Missing prerequisites fail; no
winget fallback or automatic vendor consent is supplied.

The production child alone receives a new isolated LOCALAPPDATA/TEMP/TMP
under the stage. This prevents the source installer's hardcoded publisher
cache path from touching the recipient's existing AutoClip cache. Both actual
original and isolated LOCALAPPDATA paths are recorded. Parent environment is
unchanged. `uv venv --python 3.11.9 --no-python-downloads` still must find the
actual installed Python or fail. This isolated-path diagnostic is not proof
of a production wizard/default-user-path installation.

## Child and success evidence

The exact invocation uses `-NoPrerequisiteAcquisition -NonInteractive
-SkipDesktopShortcut`, an exact local v40 archive, explicit empty native/cache
roots and bound MSYS/helper/manifest inputs. It does not pass
`-PrerequisitesOnly`, offline cache, GPU, CUDA or terms-acceptance switches.
There is one hidden child PowerShell host, full stdout/stderr files, durable
PID/start time/absolute executable/phase/exit state and immutable observation
JSON files. Optional `-PostResult` sends bounded first-party state to
`/msys-state`; preserve the prior mutable host receipt before running.

The driver polls the same actual child handle without a timeout, retry or
kill. Transfer errors preserve the running process and local receipts. If
receipt writing fails while the child is live, the existing process finishes
before readlocks are released. Every phase/failure root and complete logs
remain on disk for parent inspection; no cleanup is performed by this driver.

Success requires actual integer child exit zero, exact v40 completion marker,
release/publisher manifest and archived recipe pins, CPU-only native receipt,
both exact generated wheel hashes, FFmpeg configuration hash, all eight
installed native DLL hashes and a separate installed isolated Python import/
CPU int8 capability check with Python 3.11.9, PyAV 18.1.0 and CTranslate2 4.8.2.
The source installer's actual production wheel RECORD/integrity, offline
installation and dependency checks must also have passed to produce child
exit zero. `source_build_performed` is marked true only after this complete
result validation, not merely because the child was started.

`VERIFIED_FULL_CPU_HELPER_BUILD` proves this diagnostic helper path only.
It does not prove ordinary application launch, health, model inference,
transcription/media workflow, final Inno wizard, cleanup/uninstall or release.
The latest user explicitly requires uninstall execution after the installer
is production-ready; this work order executes no uninstaller.

## Parent invocation

After separately verifying the final fresh MSYS chain and staging this driver
by its full frozen hash, the parent alone may invoke:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <verified-driver.ps1> -RunCpuBuild -PostResult -ManifestSha256 92fcd18f5f8e7fd905a25513702e45906d7f134cfceb5ac835437f1b45ccb116 -MsysRoot <actual-fresh-msys64-root> -MsysPackageReceiptPath <actual-protected-package-receipt> -MsysPackageReceiptSha256 <actual-receipt-sha256> -MsysBaseArchivePath <actual-authenticated-base-tar>
```

The actual guest build, complete logs/receipts, source/configuration/notice
inspection and later wizard/application/lifecycle acceptance remain pending.

### Fresh CPU18 chain received after driver freeze

The parent subsequently reported fresh base/package completion and terminal
PID 4108. This agent independently rehashed the transported primary receipts
and inspected their JSON: base `b52300400b18b2dbeeeba53043231c3a1e37d95aa4d7bfaa5e381f40aefc0906`
is `VERIFIED_PINNED_BASE`; package
`429f0aef4a0cf8e0bb67a841ac35f94feb17436396c67924152e386f394fa565`
is `VERIFIED_PINNED_PACKAGES`, binds that base hash and final `92fcd18...`
manifest, and names root `C:\ProgramData\acm-ee01cf00\msys64` with private
HOME under that root. This is transported primary evidence inspection, not
independent VM execution or live filesystem revalidation.

The concrete root-owned invocation, after driver/control staging and current
guest-path checks, is:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <verified-driver.ps1> -RunCpuBuild -PostResult -ManifestSha256 92fcd18f5f8e7fd905a25513702e45906d7f134cfceb5ac835437f1b45ccb116 -MsysRoot 'C:\ProgramData\acm-ee01cf00\msys64' -MsysPackageReceiptPath 'C:\Users\autocliplab\AppData\Local\Temp\acmp-71bb0b7cf892\logs\package-receipt.json' -MsysPackageReceiptSha256 429f0aef4a0cf8e0bb67a841ac35f94feb17436396c67924152e386f394fa565 -MsysBaseArchivePath 'C:\Users\autocliplab\AppData\Local\Temp\autoclip-msys-tar-20261001\msys2-base-x86_64-20260611.tar.xz'
```

The parent confirmed that retained base TAR path separately; the base primary
receipt binds its exact hash but does not contain an `archive_path` field.
The driver authenticates the actual TAR bytes before invocation. Both receipt
inputs remain explicit parameters; this fresh chain does not change frozen
driver/test bytes and does not reuse old `8c75...` receipts.

## RED and GREEN verification

Command, Windows PowerShell 5.1, host first-party fixtures only:

```powershell
powershell -NoProfile -File D:/AutoClip-Inno-Migration/vm-transfer/cpu-real-build-probe.tests.ps1
```

RED exited 1 with `RED: actual CPU build driver absent` before implementation.
GREEN exited 0 after implementation and subsequent bounded refinements.
Fixtures check ordinary-user/native64/elevation rejection, exact final
classification-only clone and mutations of URL/hash/size/version/reason/
extra fields/classification, full CPU argument map and forbidden switches,
failed child with marker and zero child without marker rejection, real
first-party readlock write/rename denial, wrong size/hash, relative/UNC paths,
immutable live/null-exit observation snapshots and nonoperational default.
PowerShell AST parser found zero errors. No vendor bytes/code or VM operation
was used to obtain RED/GREEN. Fixture roots were retained; only the three
assigned new artifact/report files were edited.
