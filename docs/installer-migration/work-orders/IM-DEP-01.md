# IM-DEP-01: clear qualified dependency delivery blocks

Date: 2026-10-02. User direction: clear blocked dependencies or choose a better
consumer alternative. This changes dependency delivery metadata, not release
approval. Original source-build artifacts and historical reviews remain intact.

## Work allocation and decision

Root owns contract, manifest, test and documentation integration. Read-only
`dependency_block_disposition` (release reviewer) reconciled exact component
evidence and tested the actual verifier against the actual v40 ZIP. Read-only
`consumer_binary_alternative` (contract reviewer, IM-DEP-02) compared upstream
binary routes and the current native policy. Neither performed vendor, VM or
release actions. Actual per-run model telemetry is not exposed.

The prior manifest made whole-wizard qualification a dependency acquisition
block even for qualified components. Separate these decisions: direct delivery
requires component rights/notices, official identity, integrity and applicable
operation evidence. Final setup, failure/lifecycle, installed application,
generated uninstaller and exact review remain release gates. The builder still
writes `UNVERIFIED_CANDIDATE`; its required-dependency checks remain enforced.

Promoted nine native inputs plus uv, Gyan FFmpeg, MinGit, MSYS2 and Python to
`DIRECT_RECIPIENT_DOWNLOAD`. MSYS2's signature, key and five package/signature
pairs also use that classification. No artifact becomes bundled. URLs, sizes,
hashes, signatures, redirects, terms and detection/capability checks are retained.
Visual Studio Build Tools and Windows SDK remain `BLOCKED`.

## Evidence checked

Root rehashed and inspected these primary receipts; producer and historical
manifest scopes are preserved:

| Evidence under `D:/AutoClip-Inno-Migration/` | SHA-256 | Supported scope |
| --- | --- | --- |
| `vm-native-r2-primary-95192fd7e134.json` | `95192fd7e13430a038b5637b01d04a7ce3bc79048925b9b1deb0c1e656189fe2` | All nine exact protected official inputs; no build in this receipt |
| `vm-ff07-primary-8eff5e351bb2.json` | `8eff5e351bb260bdc6b2d2e44631f6f8a6b03c480651913f0f00ef74e9c3b826` | Exact CLI archive, notices, discovery and synthetic media |
| `vm-msys-source-r2-primary-8526d4ae4ae6.json` | `8526d4ae4ae6979e5af2f3e17cd4e9f24451916278d8ee66b33de9a57be747d1` | Protected startup and real selected-package/source queries |
| `vm-tools-20261001.json` | `340b29f5664e9192b408922d107c2a9f86f8a30805d4f338df5c854f38534440` | Exact uv/MinGit acquisition, extraction, signature and version |
| `vm-cpu23-completed-primary-fd74bfe29b4c.json` | `fd74bfe29b4cc6eca9bc17cbb3c60e9a811f782da0ac56ffc3186f050c95e69e` | Existing complete CPU build, unchanged recipe/output identities and imports |

IM-ACQ-18 records original/nested notices and private recipient native-use
disposition. IM-MS-14/16 bind the complete MSYS2 chain. IM-PY-01/02 and the
Python records in the evidence ledger retain the consented real helper install
scope; VM consent is not production-recipient consent. IM-TOOL-02/03 bind uv
texts/source index; actual final installed-notice inspection remains pending.
IM-CPU-26's root addendum records actual CPU int8 transcription and rendered
media. These results do not establish a clean complete wizard installation.

Before manifest SHA: `f9689639b6227756fc9164dde57e713f4b755bea59f3cd2bf93dfffe5621b774`.
Preserved exact bytes are in the blind-review policy snapshot. After SHA:
`614420f1e4b4f8767f569cd309764e5d6ff587b8a770153f504e4ccf2b0ed3e7`.
No historical receipt is rebound to this new hash.
Read-only review compared the preserved exact before bytes with the current
manifest: exactly 40 changed fields, comprising 26 classifications and fourteen
reasons. Every other field, including both VS/SDK rows, is unchanged.

## RED, GREEN and remaining gate

Working directory: `D:/Projects/autoclip-runtime`.

```powershell
python -m unittest discover -s .github/tests -p test_installer_manifest.py
```

New behavioral test supplies the canonical fourteen component routes to the
actual verifier using a first-party synthetic indexed archive/recipe. Before
the manifest change, expected RED: required native build asset blocked at
`ffmpeg-8.1.2.tar.xz`. After change: all 17 tests GREEN. The same test separately
adds each unresolved Microsoft dependency and requires its rejection. Existing
malicious nested payload, omitted/changed native pins, redirect and MSYS2 child
signature tests remain enabled.

```powershell
python -m unittest discover -s .github/tests -p test_inno_build.py
python scripts/verify-installer-manifest.py --manifest release/manifests/installer-dependencies-v1.json --archive D:/AutoClip-Inno-Migration/autoclip-source-build-v40-provenance-continuity.zip
python scripts/verify-installer-manifest.py --manifest release/manifests/installer-dependencies-v1.json --archive D:/AutoClip-Inno-Migration/autoclip-source-build-v40-provenance-continuity.zip --profile cpu --require-installable
```

Results: builder 11 tests PASS; actual graph PASS (1108 members, 74 publisher
wheels, 3 external assets); CPU installability still FAILS at Visual Studio
Build Tools. Read-only reviewer simulation omitting that row separately rejects
Windows SDK. Omitting both in-memory proves only the remaining graph's metadata
eligibility, not a supported consumer install or test bypass.

Affected read-only preflight regression also passed:
`powershell.exe -NoProfile -NonInteractive -File tests/InstallerPreflight.Tests.ps1`.
Protected downloader regression passed:
`powershell.exe -NoProfile -NonInteractive -File tests/InstallerDownload.Tests.ps1`
(redirects, delivery classification, size/hash, retry and verified/corrupt cache).
Root independently repeated the recursive exact before/current metadata comparison:
26 classification and fourteen reason changes; all other fields unchanged.
`git diff --check` passed with existing CRLF conversion warnings.

No rejected acquisition preparation was retried. No vendor terms, signature,
trust, manifest requirement or release acceptance was bypassed. No fresh Setup,
uninstaller, vendor acquisition, publication or NVIDIA test was performed here.

## Next dependency route

IM-DEP-02 selects a new controlled publisher-built CPU native artifact for
qualification. It could remove recipient compiler/SDK/MSYS2/native checkout
requirements while preserving the controlled native configuration and direct
restricted vendor routes. Current v40 remains source-built; it is not silently
reinterpreted. Exact new artifact, rights/source inventory, receipt contract and
clean-machine evidence are required before this alternative can replace it.
