# CR-09 v33 independent focused C7 / continuity review

**Review date:** 2026-09-28  
**Reviewer/session:** ChatGPT — GPT-5.6 Sol  
**Target:** exact unpublished `v11-20260928-source-build-candidate-v33-mingw-notices`  
**Candidate SHA-256:** `501ded146e98dedf4071c07e96247752faa7548d60c6379447fc9dbe278013fc`

This is an independent engineering/compliance evidence review. It is not professional legal advice, organizational authority, agreement acceptance, release clearance, or publication approval.

## Decision

**C7 is RESOLVED for the exact v33 candidate.**

The exact MinGW-w64 v8.0.0 runtime and winpthreads notices are present, hash-correct, separately mapped to the exact external OpenBLAS DLL, and recipient-discoverable. The current static-runtime notice validation design rejects missing, wrong-binary, top-level-only, and modified-notice routes.

However, I identified a separate current-candidate metadata inconsistency:

**C8 — correction needed: the current v33 legal index retains unqualified historical GCC/Fortran fields stating `pending_exact_publisher_build_evidence`, `exception_eligibility: pending`, `build_evidence: []`, and a publisher-build `required_input`, even though the later attributable C5 public-evidence reassessment is now the current bounded C5 disposition.**

This does not reopen the substance of C5 and does not negate C7 notice delivery. It does mean I would not close RC-01/RC-02 against exact v33 without a narrow metadata correction and focused continuity check.

## 1. Materials actually inspected

I inspected, read-only:

- exact raw v32 candidate ZIP;
- exact raw v33 candidate ZIP;
- exact v33 standalone installer;
- `identities.json`;
- `member-delta.json`;
- complete `runtime-source.bundle`;
- prior attributable v32 independent review;
- C5 public-evidence reassessment;
- C7 correction requirement;
- v33 engineering handoff;
- committed v33 runtime source through disposable Git-object inspection;
- exact MinGW-w64 v8.0.0 primary notice files through the upstream Git repository interface.

I did **not** execute the installer, build scripts, producer audit/test scripts, wheels, native binaries, or vendor installers; accept terms; contact publishers; publish; change public pins/assets; or start CH.

## 2. Exact v33 identity verification

Reviewer-computed values:

- candidate ZIP: **173,175,679 bytes**
- candidate SHA-256: `501ded146e98dedf4071c07e96247752faa7548d60c6379447fc9dbe278013fc`
- standalone SHA-256: `ea1c2380e3a28f1a5b2aa62ca8b253c419e80e08d30e62e028f2dff6d9986194`
- release manifest SHA-256: `7e2cc930f7a2d6e872b665bb1d693c403967663db13bee154c7c8ba0690e3758`
- legal index SHA-256: `77ecb3c2786953b001fc8d712292764e3f6fc44766c23058746d2f4cbc6046f4`
- distribution inventory SHA-256: `e07c0c78e7444446dde650edb40cb274f3d5eb0415c6d43105ec067f41e28326`
- provenance SHA-256: `d1311e6420e7e13014f8809a9719770ac074d67a8c4bb5f4a3cc1b3e5a476323`
- runtime source commit: `baa8f5d2ae7170a44ca71fa4b8eddcb8a554ef40`
- supplied Git bundle SHA-256: `1fb2a55aea456c34283e920865b32b47418880a1303153673f3000dae86cb6f5`

These match the handoff / identities record.

The standalone is 355,057 bytes. After replacing exactly one occurrence each of the v33 release ID, candidate SHA-256, and manifest SHA-256 with the v32 values, its bytes become exactly identical to the retained v32 standalone. No other standalone difference was found.

## 3. Archive and manifest audit

### v33 archive

- **1,099 members**
- **1,099 unique**
- no unsafe paths
- no duplicate members
- ZIP CRC check passed
- outer manifest lists **1,098 payloads**
- all **1,098/1,098** payload size/SHA-256 records match
- no missing listed payload
- no unlisted payload other than `release-manifest.json`
- auxiliary SBOM manifest contains **875 records**
- all **875/875** auxiliary size/SHA-256 records match

The v32 base independently rehashed to:

`0ca4b7056bbe06406b7e70d0eb11be87aeafcfbfaa624ce08285817f8a79e354`

and its existing manifest/auxiliary checks also passed.

## 4. Independent v32 → v33 continuity

Independent ZIP comparison produced exactly:

- **1,088 unchanged**
- **7 changed**
- **4 added**
- **0 removed**

This exactly matches the supplied `member-delta.json`.

Changed members:

1. `distribution-inventory.json`
2. `notices-and-source/MANIFEST.md`
3. `notices-and-source/build-provenance.json`
4. `notices-and-source/build-provenance/current/scripts/build-review-successor.py`
5. `notices-and-source/build-provenance/current/scripts/build-source-routed-release.py`
6. `notices-and-source/legal-index.json`
7. `release-manifest.json`

Added members:

1. `notices-and-source/build-provenance/current/review-static-runtime-notices.json`
2. `notices-and-source/component-evidence/mingw-w64-v8.0.0-COPYING.MinGW-w64-runtime.txt`
3. `notices-and-source/component-evidence/mingw-w64-v8.0.0-winpthreads-COPYING`
4. `review-static-runtime-notices.json`

No wheelhouse member changed. No native output/receipt changed. No SBOM packet/source material changed. No prerequisite/CUDA/terms material changed. No app wheel changed. No publisher/external selection changed.

The final manifest retains exactly 74 publisher-wheel rows and the same three selected external assets as v32. The distribution inventory differs from v32 only at `native_build.runtime_commit`.

## 5. Git bundle / source association

The supplied bundle verifies as complete SHA-1 Git history with HEAD:

`baa8f5d2ae7170a44ca71fa4b8eddcb8a554ef40`

The v33 commit:

- has tree `259dfbfbe265e3db0c74ddea0f1372e67289da76`;
- has direct parent `8fb854e0fec2155d2d7dc1b9602f97105d3847f8`;
- is exactly one commit ahead of reviewed v32;
- changes six repository paths: one new C7 unit test, two exact notice files, one notice-rule JSON, and two builder scripts.

The candidate provenance contains **21 `committed_source_sha256` associations**. All **21/21** match the corresponding Git object bytes. Candidate copies/snapshots present for those associations also match their expected hashes.

## 6. C7 notice byte verification

The delivered notices are:

### MinGW-w64 runtime

Candidate path:

`notices-and-source/component-evidence/mingw-w64-v8.0.0-COPYING.MinGW-w64-runtime.txt`

- bytes: **10,936**
- SHA-256: `e9b2dc02451ea29092a1f25fa0f3c07207ed421f1807dffb0c4e6dce69dee7bd`

### winpthreads

Candidate path:

`notices-and-source/component-evidence/mingw-w64-v8.0.0-winpthreads-COPYING`

- bytes: **2,883**
- SHA-256: `63263614cdd29f2f93cba85e992f041b31f9fc7b4033692f31269489a8a1b177`

The committed pinned source copies are text-for-text identical to the corresponding MinGW-w64 `v8.0.0` upstream files at:

- `COPYING.MinGW-w64-runtime/COPYING.MinGW-w64-runtime.txt`
- `mingw-w64-libraries/winpthreads/COPYING`

The candidate hashes match the expected exact notice identities.

## 7. Recipient discoverability and legal-index mapping

The exact external asset row is uniquely identified by:

- archive SHA-256: `8b04387766efc05c627e26d24797ec0d4ed4c105ec14fa7400aa84a02db22b66`
- member: `bin/libopenblas.dll`
- DLL SHA-256: `e824cf9fc22e5949807ce995a32e413a345fb97e63e6d10cfbf41aa86382193c`

The v33 legal index has separate component rows for:

- `mingw-w64-runtime`
- `winpthreads`

Each row:

- names the exact DLL path;
- names the exact DLL SHA-256;
- points to exactly one component-specific candidate notice;
- records the exact notice SHA-256;
- records upstream path/source evidence;
- states the mapping is separate from OpenBLAS BSD and GCC runtime material.

`notices-and-source/MANIFEST.md` also contains a recipient-facing section identifying the external OpenBLAS static-runtime notices under `component-evidence/` and directs the reader to `legal-index.json` for exact mapping.

**Recipient discoverability: satisfied.**

## 8. Independent negative-route test

I did not execute the supplied audit/test scripts.

I instead implemented a reviewer-side in-memory check mirroring the documented final-route invariants against the archived legal index and notice bytes.

Results:

- exact v33 route: **accepted**
- remove `winpthreads` component mapping: **rejected**
- wrong `winpthreads` binary SHA: **rejected**
- retain only top-level/non-C7 components: **rejected**
- alter winpthreads notice bytes: **rejected**

The committed validator source independently shows the same requirements: unique component route, exact binary path/hash, exact one-notice path/hash, notice presence, and final notice-byte SHA verification.

**C7 audit behavior: sufficient for the requested bounded scope.**

## 9. C7 disposition

**C7: RESOLVED for exact v33.**

The correction requirement asked for exact v8.0.0 MinGW-w64 runtime and winpthreads notice bytes, distinct recipient delivery, exact mapping to the external OpenBLAS DLL, final manifest verification, and unchanged-byte carry-forward. Those conditions are satisfied in the exact raw v33 bytes inspected here.

No new executable/native/dependency/profile defect was introduced by C7.

## 10. New finding C8 — stale GCC/Fortran current-state fields

The current v33 legal index still contains this GCC/Fortran component state:

- `fulfillment_status: "pending_exact_publisher_build_evidence"`
- `exception_eligibility: "pending"`
- `build_evidence: []`
- `required_input: "Publisher compilation/configuration record ..."`

Those fields accurately preserve the older v31/v32 review state, but they are not marked as historical. The later attributable C5 reassessment now states that the artifact-bound public evidence is sufficient at the project's bounded engineering/compliance scope and that publisher contact is no longer required for that C5 decision.

Because `legal-index.json` is the current machine-readable legal/component index for exact v33, leaving the old `pending` fields unqualified creates an internal current-state conflict.

### C8 disposition

**CORRECTION NEEDED — metadata consistency only.**

Do not reopen the substantive C5 analysis.

Recommended correction:

1. preserve the previous `pending` state explicitly as historical/previous review metadata;
2. add an explicit current-review overlay tied to `cr09-c5-public-evidence-reassessment.md`;
3. record that the C5 GCC Runtime Library Exception eligibility question is `supported_by_artifact_bound_public_evidence` at the bounded engineering/compliance scope;
4. state that exact private publisher build logs/maintainer attestation are optional higher-assurance evidence, not a current required input for C5;
5. do not label this as professional legal clearance or organizational publication authority;
6. keep NumPy's different DLL completely separate;
7. regenerate affected legal index, manifests, provenance, archive identity and standalone pins in a new immutable metadata-only successor.

This should be a narrowly bounded successor. The C7 notice bytes themselves do not need another implementation change.

## 11. Carry-forward scope

The prior v32 decisions may carry forward only where exact relevant bytes and applicability are unchanged.

For exact v33:

- all unchanged app/wheel/native/SBOM/source/prerequisite-term/dependency-selection material retains its prior attributable scope;
- C5 uses the later focused reassessment as the current overlay rather than the older v32 unresolved conclusion;
- C7 notice delivery is newly resolved by this review;
- NumPy private Microsoft DLL and optional cuBLAS actor/authority remain unresolved under RC-03;
- historical cuDNN remains excluded from the operative successor profile.

The 79 historical rows and 574 conservative SBOM declarations are **not** reset or newly cleared by this focused review.

## 12. RC disposition after this review

| Gate | Attributable v33 result |
| --- | --- |
| **C7 / RC-09RC-02A** | **Resolved for exact v33 notice delivery and continuity scope.** |
| **RC-01** | **Still In review** because current v33 legal-index metadata needs C8 consistency correction before exact-row closure. |
| **RC-02** | **Still In review** for the same bounded C8 metadata correction; C7 notice delivery itself passes. |
| **RC-03** | **Unchanged:** Microsoft agreement/actor/entitlement, NumPy private Microsoft DLL route, NVIDIA/cuBLAS authority beyond the documented machine, and publishing-party duties remain unresolved. |
| **RC-05** | Gated; this review does not grant exact app/runtime compatibility. |
| **RC-07 / publication** | Gated; this is not publication approval. |
| **CH** | Untouched. |

## 13. Known limits

- I did not execute the installer, builder, producer audit scripts, wheels, native binaries, or vendor prerequisites.
- I did not accept terms or establish organizational authority.
- Windows runtime repository/public-pin CI is separate engineering evidence; Windows release smoke remains skipped.
- Linux/macOS remain deferred under the selected project scope.
- This review does not create general clearance for separately downloaded FFmpeg CLI, tooling, future model downloads, JavaScript acquisitions, or changed OpenBLAS binaries.

## 14. Next actions

1. **Do not redo C7.** Its exact notice delivery is resolved for v33.
2. Create a **narrow metadata-only successor** correcting the current GCC/Fortran legal-index state (C8) while preserving the historical pending state as historical evidence.
3. Rehash/regenerate only affected legal-index / manifest / provenance / archive / standalone identity material.
4. Produce an exact v33→successor member delta and verify unchanged executable/app/native/SBOM/source/terms/dependency bytes.
5. Perform a focused independent C8 consistency/continuity review.
6. In parallel, resolve the existing RC-03 Microsoft/NumPy/NVIDIA actor and terms decisions.
7. After applicable RC-01/02/03 closure, proceed to exact RC-05 compatibility and then RC-07 final exact-asset/publication disposition.
