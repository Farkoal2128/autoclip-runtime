# IM-FF-05: guarded FFmpeg bootstrap integration

Authorization: parent work order owns `install.ps1`,
`tests/InstallerFFmpegIntegration.Tests.ps1` and this report only. Existing
guarded acquisition changes were preserved. Parent owns Inno embedding/flags,
build-fixed hashes, canonical manifest disposition and installed qualification.
No vendor installation, live download, agreement acceptance, immutable v40
script change, launcher change, commit or publication was performed.

## Contract and accepted interface

Installer contract-v1 and runtime architecture require verified prerequisites,
preserved supplier files, scoped tool ownership and offline selected-runtime
startup before completion/activation. IM-FF-04 supplies the trusted .pth helper.
This is installer/updater integration; no source-build version/runtime identity
or global PATH was changed.

Added parameters:

- `-FfmpegArchivePath`
- `-ToolArchiveHelperSha256`
- `-RuntimeToolPathHelperSha256`

All three are required when the existing secure acquisition route is selected;
none are accepted without that route. Legacy installation without the secure
route keeps its existing tool acquisition/detection behavior. Fixed sibling
helpers are `install-tool-archive.ps1` and `install-runtime-toolpath.ps1`.
No arbitrary helper path or production verification bypass was added.

The FFmpeg row must be exactly DIRECT, version 9.0.1 x64, the official Gyan
essentials URL, 111253802 bytes and ZIP SHA-256
`fec81ae03971d9dd4be3ebe02e263bd2ec1d789483f931bdba5f5715e65da2e9`.
Both selected EXE pins and native capabilities remain enforced by the existing
archive helper. The production manifest was not modified by this task; tests
use an explicitly separate DIRECT fixture.

## Implemented flow

1. Before prerequisite checks, revalidate fixed sibling helper bytes and the
   already trusted outer manifest with Read-AutoClipSecureInput. Revalidate and
   snapshot the complete pinned ZIP/manifest into an owned private TEMP root.
   Execute the just-verified archive-helper bytes in memory, avoiding an
   executable script reread. Its actual traversal/hash/version/filter checks
   extract the complete original tree. Save the verified full file/directory
   inventory and prepend only its verified bin to this process's PATH. Before
   the existing FFmpeg prerequisite check, prepend again and require both
   selected commands to match the exact staged executable paths.
2. After exact v40 extraction and file verification, retain the untouched full
   extraction under `<ReleaseRoot>/tools/ffmpeg`. Copy into a new sibling stage,
   compare against the initial verified inventory, write the first-party owner
   marker outside the official prefix, then publish with a same-volume directory
   move. Source tree mutation after extraction, altered notices, reparse paths,
   foreign trees and extra/missing entries fail closed. Existing exact owned
   content is reused without overwrite.
3. After the release .venv exists and before native build/completion/launchers,
   recheck runtime-helper and manifest bytes and invoke the fixed helper in
   memory on pinned manifest snapshots. It registers the persistent .pth for
   direct Python/Pythonw and app-only overlay startup. Store its complete return
   receipt in `.inno-runtime-tools.json` under the release root. That schema-1
   receipt says only `configured`; it does not assert installation approval.
   Exclusive same-directory staging, flush and no-replacement move publish it
   atomically. An exact existing receipt is retained; foreign/conflicting bytes
   are preserved and rejected.
4. An encompassing finally restores this process's original PATH and removes
   only the verified owned TEMP root on success, prerequisite failure or later
   native failure. Retained release-owned tools/receipt remain available for a
   verified incomplete-install retry. User/machine PATH is never changed.

## Bounded retry decision

The parent approved an owner marker `.autoclip-ffmpeg-owner.json` outside
`ffmpeg-9.0.1-essentials_build`. It pins ZIP, outer manifest and both helpers.
Every official file/directory is compared to the freshly verified inventory
before accepting a matching rerun; supplier files are never rewritten.

The existing incomplete-install inventory gate gains only two scoped exceptions:
the already verified owned `tools/ffmpeg/` tree, and an existing
`.inno-runtime-tools.json` whose first-party envelope matches the pinned route
and whose current hash matches the just-inspected receipt. Registration later
requires that receipt's complete bytes equal the freshly produced expected
receipt before continuing. Unrelated root files retain the existing rejection.
Existing completed-install rejection remains intact. The receipt's owner pins
must remain unchanged; a new manifest/helper identity is not silently adopted.

## RED and GREEN

Before production integration, the test removed FFmpeg from its process PATH
and failed with: `Guarded prerequisite checks must discover the verified
FFmpeg/FFprobe without winget acquisition.` This was actual command discovery
with the exact local archive present, not an absent-fixture or parser failure.

GREEN uses the real 111 MB ZIP, the actual existing archive helper and the
frozen runtime-toolpath helper
`699977ea1234b6cd681b6bf89cae24312cbd9270e13fea2f83a315fdd6d62802`.
No helper, executable or filesystem behavior is mocked. A real disposable
Python 3.11.9 venv is created with stdlib venv --without-pip. Before registration,
isolated startup finds neither tool; afterwards shutil.which selects both exact
retained executables. Real FFmpeg filter/encoder probes verify ass, subtitles
and libx264. Complete retained inventory and original LICENSE bytes match the
verified extraction.

Tests also cover all-or-none/unguarded inputs, canonical BLOCKED rejection,
changed helper inputs before use, PATH delimiter rejection, temporary and
retained notice mutation, foreign retained tree/receipt preservation, exact
receipt rerun, the actual retry-inventory loop rejecting unrelated root files,
stage ordering, and the actual outer finally restoring PATH/removing TEMP.
Saved user/machine PATH values remain unchanged.

Executed commands from `D:\Projects\autoclip-runtime`:

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerFFmpegIntegration.Tests.ps1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerSecureAcquisition.Tests.ps1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallerNoAcquisition.Tests.ps1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InlineInstaller.Tests.ps1
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tests/InstallLaunchers.Tests.ps1
C:\Users\beilo\AppData\Local\Programs\Python\Python311\python.exe -I -B -m unittest discover -s .github/tests -p test_cpu_bootstrap_contract.py
git diff --check -- install.ps1 tests/InstallerFFmpegIntegration.Tests.ps1 docs/installer-migration/work-orders/IM-FF-05.md
```

All passed, including three CPU contract tests. The focused test defaults to
the exact local ZIP at `D:\AutoClip-Inno-Migration` and the already installed
host Python 3.11.9. It installs no packages and creates/removes only scratch
tools and a disposable venv.

Limits: no full AutoClip source build, guest setup, actual desktop/media workflow,
app-only update, rollback or uninstall lifecycle was exercised. Parent must embed
and pass both fixed helper hashes, pass the archive and secure inputs, bind the
persistent configured-only receipt into the final setup receipt, retain tool
ownership for selected/rollback runtimes and qualify the exact setup. Native
Git and MSYS login behavior remain the previously documented separate risks.
This record makes no vendor, legal, release or independent-review gate claim.
