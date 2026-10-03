# Dependency disposition for the Inno candidate

This is a current work record, not approval of a released installer. Current
manifest after IM-DEP-01 reconciliation has SHA256
`614420f1e4b4f8767f569cd309764e5d6ff587b8a770153f504e4ccf2b0ed3e7`.
The earlier internal analysis below inspected historical `90d618...` bytes;
those results are not rebound to the current manifest.
The immutable selected v40 graph contains 74 publisher wheels; later Pillow
successor requirements do not retroactively change that graph.

| Component | Canonical delivery | Remaining evidence/action |
| --- | --- | --- |
| AutoClip first-party setup helpers/notices | Candidate bundled first-party code | Bind final source/helper/notice hashes; inspect exact compiled nested payload. |
| v40 application/source archive and 74 publisher wheels | Recipient direct download | Preserve exact legal corpus and archive pins; final setup must contain no publisher cache. |
| Native FFmpeg 8.1.2, PyAV 18.1.0, seven build wheels | Recipient direct download | Exact protected acquisition and nested notices (IM-DL-06/ACQ-18), complete prepared-machine CPU output and media (IM-CPU-23/26) support delivery. Whole wizard and publisher binary redistribution remain unqualified. |
| CTranslate2 4.8.2 / oneDNN 3.1.1 | Recipient source build in v40 | Exact Git/submodule and SIMD notice records, constrained startup, CPU inference, locally generated wheel/DLL receipts. |
| Gyan FFmpeg 9.0.1 essentials | Recipient direct download | IM-FF-07 passed acquisition/extraction, notices, discovery and media capabilities. Whole wizard remains unqualified; no supplier static-source closure or redistribution approval is inferred. |
| uv 0.12.19 | Recipient direct download | Exact archive/signature/version and repository MIT/Apache/source index support acquisition. Final installed notice audit and wizard/cancellation remain pending; no redistributed populated cache. |
| MinGit 2.55.0.3 | Recipient direct download | Exact archive/signature/version and complete retained notices/package-version tree support acquisition. Qualify exact wizard checkout route. |
| MSYS2 20260611 TAR, key/signature, five packages/signatures | Recipient direct download | Ordinary-user base/package chain and corrected source guards passed (IM-MS-14/16). Preserve private recipient scope and exact signatures. Whole wizard remains unverified. |
| Python 3.11.9 x64 | Recipient direct download | Real consented guest helper installation passed; complete wizard consent/reboot/retry/cancellation remains open. VM consent is not general recipient consent. |
| Build Tools 17.14.41 / SDK 26100 | BLOCKED | Historical 409-file verification, offline native install and real x64 compile/link/run passed; current original source has 368 missing files. All 868 installed engine files match pinned OPC (IM-VS-17). Corrected authenticated JSON passed OS crypto/trust; standalone Catalog selection is explicit (IM-VS-14). Qualify supported fresh engine/control acquisition, preserve vendor contradictions, complete manifest schema and full wizard handling. |
| OpenBLAS 0.3.30 / VC Runtime 14.44.35211.0 | Recipient direct download | Preserve existing C5/C7 scope; verify exact member/DLL, native VC agreement/reboot handling, VCOMP and CPU inference. |
| NumPy 2.4.6 | Recipient direct download | Preserve exact publisher wheel and v40 legal corpus; setup must embed/mirror neither wheel nor private Microsoft DLL. No new universal entitlement approval is inferred. |
| NVIDIA GPU/driver | Already/system provided | Optional profile only; do not replace a functioning driver. Actual hardware/inference unverified and deferred by user instruction. |
| CUDA 12.8 selected build components / cuBLAS 12.4.5.8 | Recipient direct download | Preserve versioned consent, nonbundling and exact capability checks; complete missing manifest fields. GPU test deferral does not waive distribution policy. |
| Pillow | Absent from selected v40 | A later dependency-changing successor requires its own immutable graph and source/notice review. |

Earlier combined CPU testing exposed an additional registration mismatch with
the pinned uv-created venv's `version_info` field (IM-CPU-20/21). The prior
standard-library venv component pass retains its original scope. Canonical
failure and subsequent correction remain recorded. IM-CPU-23/26 establish
prepared-machine output/import/media evidence. IM-DEP-01 intentionally separates
qualified artifact delivery from pending complete-wizard release tests.

## Current dependency gate and consumer alternative

IM-DEP-01 clears fourteen parent delivery blocks and the twelve MSYS2 children,
with all artifact and integrity fields unchanged. The actual full CPU gate now
rejects Visual Studio Build Tools; Windows SDK also remains blocked. Inventory
verification and 17 manifest plus 11 guarded-builder tests pass. This is no
installation or publication approval.

IM-DEP-02 chooses qualification of a new controlled publisher-built CPU native
artifact to remove recipient compiler/SDK/MSYS2/native checkout requirements.
Unmodified official PyAV/CTranslate2 wheels change the approved native graph;
they are not an immediate substitute. The new artifact requires its own exact
inventory, source/notices, receipt contract, clean-machine proof and review.
Current v40 remains source-built until that successor is actually qualified.

## Independently checked scope

Internal release analysis re-ran:

```powershell
python -I -B scripts/verify-installer-manifest.py --manifest release/manifests/installer-dependencies-v1.json --archive D:/AutoClip-Inno-Migration/autoclip-source-build-v40-provenance-continuity.zip
# PASS: 1108 release members, 74 publisher wheels, three external assets
# Add --profile cpu --require-installable:
# FAIL CLOSED: ffmpeg-8.1.2.tar.xz remains BLOCKED
```

The analysis inspected primary nine-download, Python and Microsoft layout
receipts and their hashes; guest operations themselves were parent-performed.
This is internal evidence reconciliation, not blind review, legal opinion or
publication approval. Technical acquisition qualification and explicit rights
decisions remain distinct. Reclassifying a row alone is insufficient: Build
Tools/SDK and optional NVIDIA rows also need required schema fields and an
enforced execution/detection route.

Sources: IM-ACQ-01, IM-FF-02, IM-TOOL-01, IM-PY-01, IM-MS-09, IM-MS-10,
IM-VS-03, IM-VS-05, IM-VS-07 and IM-VS-08 work orders, the versioned setup
contract, and the exact v40 archive/legal index. Preserve their original scope.
The archived v40 Git recipe lacks the current mutable recipe's long-path fix;
testing a different helper cannot establish success of the archived recipe.
