# IM-DL-03: external assets and publisher wheel resolver

Authorization: parent explicitly assigned this implementation slice and
expected behavior. Owned files are `installer/download-artifact.ps1`,
`tests/InstallerDownload.Tests.ps1`, and this report. No Inno, installer,
manifest, build, installation or publication changes were made by this slice.

Requirement: reuse the protected recipient downloader for v40 external assets
and publisher wheels, under `contract-v1.md` protected acquisition and exact
dependency identity rules. Classification: installer/updater. The parent owns
caller integration and manifest host policies; this slice does not qualify
the existing downstream automatic redirect routes.

## Interface and implementation

Both `Get-InstallerArtifact` and the script entrypoint now accept optional
`-PublisherManifestPath`. Existing target-release and build-prerequisite
resolution remains. External assets match one exact row by identity or
filename. The publisher input must match the outer manifest's
`publisher_wheels.sha256`, schema version 1 and a nonempty wheels list. The
helper hashes and parses one byte snapshot so it never parses different bytes
from those it verified. Reparse-point publisher inputs are rejected.

Publisher wheels match filename only, as explicitly directed by the parent.
They retain their URL/bytes/SHA-256 from the verified publisher manifest and
inherit `DIRECT_RECIPIENT_DOWNLOAD` and exact `redirect_hosts` from the outer
publisher route. No 74-wheel inventory or pins are copied into the outer
manifest. More than one match across target, build prerequisite, external and
supplied publisher rows fails as ambiguous, including duplicate wheel filenames.
Unknown or blocked routes fail before networking. The existing HTTPS,
redirect, size/hash, destination, TEMP staging and cancellation checks apply
to every resolved row.

## RED and GREEN

Before production edits:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerDownload.Tests.ps1
```

Exited 1 with three actual behavioral failures: external `fixture` and
`fixture.zip` routes unavailable, and `PublisherManifestPath` unrecognized.
The tests invoked the helper with concrete fixture manifests and attempted
verified downloads; they did not inspect source strings.

After implementation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerDownload.Tests.ps1 -RealDownloads
```

Exited 0. New cases cover external identity/filename success, inherited wheel
route success, tampered publisher manifest bytes, unsupported publisher schema,
blocked publisher/external routes, unknown filename, cross-group ambiguity and
duplicate wheel filenames. Invalid extended policy cases assert zero transport
requests. Existing redirect, size/hash, cache, timeout, absolute path, reparse,
cancellation and target-release cases also passed. Actual official uv/MinGit
downloads matched the existing exact pins.

## Actual v40 route verification

Extracted `publisher-wheel-manifest.json` unchanged from the local exact v40
ZIP into a new TEMP fixture directory. This used .NET ZipFile entry streams,
with no archive execution or general extraction. The publisher file is 46,462
bytes and SHA-256
`29f1e0b5e42b246e84e01b2e9ca407554faf5118177ecc3d2ff0b138d7b0fd38`.
Using the repository manifest's parent-added official host policies, ran:

```powershell
. .\installer\download-artifact.ps1
$caseRoot = 'C:\Users\beilo\AppData\Local\Temp\autoclip-dl03-real-635365a107714987a6bc8d4aa2337b76'
$caseManifestPath = 'D:\Projects\autoclip-runtime\release\manifests\installer-dependencies-v1.json'
$casePublisherPath = Join-Path $caseRoot 'publisher-wheel-manifest.json'
Get-InstallerArtifact -ManifestPath $caseManifestPath -PublisherManifestPath $casePublisherPath -Identity annotated_doc-0.0.5-py3-none-any.whl -DestinationPath (Join-Path $caseRoot 'annotated_doc-0.0.5-py3-none-any.whl')
Get-InstallerArtifact -ManifestPath $caseManifestPath -Identity OpenBLAS-0.3.30-x64.zip -DestinationPath (Join-Path $caseRoot 'OpenBLAS-0.3.30-x64.zip')
```

Both actual official downloads passed with the real transport and no policy
override. Annotated-doc: 5,302 bytes, SHA-256
`117bac03a25ede5df5440e855b32d556049ca169ead221505badf432fed4b101`.
OpenBLAS: 40,561,566 bytes, SHA-256
`8b04387766efc05c627e26d24797ec0d4ed4c105ec14fa7400aa84a02db22b66`.
These files were retained in the named TEMP directory for parent reuse.

Then exercised the separate script process against verified cached wheel bytes:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File installer/download-artifact.ps1 -ManifestPath D:\Projects\autoclip-runtime\release\manifests\installer-dependencies-v1.json -PublisherManifestPath C:\Users\beilo\AppData\Local\Temp\autoclip-dl03-real-635365a107714987a6bc8d4aa2337b76\publisher-wheel-manifest.json -Identity annotated_doc-0.0.5-py3-none-any.whl -DestinationPath C:\Users\beilo\AppData\Local\Temp\autoclip-dl03-real-635365a107714987a6bc8d4aa2337b76\annotated_doc-0.0.5-py3-none-any.whl
git diff --check -- installer/download-artifact.ps1 tests/InstallerDownload.Tests.ps1 docs/installer-migration/work-orders/IM-DL-03.md
```

Both exited 0. The script returned the verified artifact's absolute path.

## Handoff snapshot and limits

- Helper SHA-256:
  `620698cacf41886ca286abfb7304f461ea75c50c73c61157bbcadc27b36d636c`.
- Tests SHA-256:
  `29daaf51fd8d7efc8748e6ec981808e4e89613063a3fc8d112107519a05c194a`.

Verified: helper resolver behavior, actual one-wheel/OpenBLAS acquisition and
existing official uv/MinGit acquisition on the developer machine. Unperformed:
all-74-wheel acquisition, VC acquisition/execution, caller integration, clean
VM wizard acquisition, installation, media workflow, human/legal and publication
gates. Download verification alone does not approve redistribution or execution.
No new external API was introduced beyond the optional verified-manifest input;
the existing .NET file, SHA-256, JSON and HTTP APIs were reused.
