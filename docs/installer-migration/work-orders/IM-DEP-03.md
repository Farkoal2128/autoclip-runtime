# IM-DEP-03: preserve IM-DEP-01 evidence and qualify a new CPU runtime

Date: 2026-10-02. User-provided disposition explicitly authorizes Stage A
preservation and Stage B qualification of a new publisher-built CPU artifact.
This work order closes only Stage A evidence verification. Stage B is the next
qualification route; no publisher runtime was built or approved here.

## Stage A: exact preservation and verification

The immutable packet is
`D:/Projects/autoclip-runtime-evidence/IM-DEP-03-20261002-6d338ca1977e`.
It preserves byte-exact copies of the before and after dependency manifests and
the user-provided disposition, an automated parsed-field diff, content hashes
for the verifier/tests, and original-evidence references with hashes and
original scopes. Existing primary receipts were only read and hashed; they were
not edited or copied into this packet.

| Snapshot | Bytes | SHA-256 |
| --- | ---: | --- |
| Before manifest from the frozen blind-review policy snapshot | 33,216 | `f9689639b6227756fc9164dde57e713f4b755bea59f3cd2bf93dfffe5621b774` |
| Current after manifest in this working tree | 36,230 | `614420f1e4b4f8767f569cd309764e5d6ff587b8a770153f504e4ccf2b0ed3e7` |

A recursive JSON comparison produced exactly **40 changed fields**: **26
`delivery_classification` fields** and **14 `reason` fields**. The other parsed
fields are equal. `artifact-evidence-map.json` traces every changed
classification path to its parent manifest row and supporting original primary
evidence hash/scope. It enumerates 14 promoted parent rows: uv, Gyan FFmpeg,
MinGit, MSYS2, Python, and the nine native source/build inputs. The MSYS2
parent's nested key, archive-signature, package, and package-signature fields
are individually mapped. `exact-json-diff.json` contains the exact before/after
values for all 40 paths.

Historical evidence remains bound to its original scope. In particular,
`vm-native-r2-primary-95192fd7e134.json` proves acquisition of the nine exact
protected official inputs; it does not claim a build. IM-CPU-23/26 are separate
prepared-machine private CPU output/media evidence. Neither that private build
evidence nor a direct-recipient classification authorizes publisher
redistribution. Gyan CLI evidence does not qualify the separately controlled
PyAV/FFmpeg libraries. User VM consent does not establish general recipient
consent. No whole-wizard, final installed-notice, Inno Setup, release, or legal
approval is inferred.

The verifier and focused test revisions are bound by working-tree SHA-256 in
`verification-and-revisions.json`; repository base HEAD was
`ccc14a25014a35daf9e2de2edc595f8e02927671`. These content hashes identify the
files tested, including files not yet tracked by Git; the HEAD value is not a
commit claim. The user disposition attachment SHA-256 is
`5fa29ac4b874f5d41549aee1a3f3b4826833b61faac1dafcfa0baece55685245`.

Commands run from `D:/Projects/autoclip-runtime`:

```powershell
python -m unittest discover -s .github/tests -p test_installer_manifest.py
python -m unittest discover -s .github/tests -p test_inno_build.py
python scripts/verify-installer-manifest.py --manifest release/manifests/installer-dependencies-v1.json --archive D:/AutoClip-Inno-Migration/autoclip-source-build-v40-provenance-continuity.zip
python scripts/verify-installer-manifest.py --manifest release/manifests/installer-dependencies-v1.json --archive D:/AutoClip-Inno-Migration/autoclip-source-build-v40-provenance-continuity.zip --profile cpu --require-installable
```

Results: manifest tests **17 passed**; guarded builder tests **11 passed**;
actual v40 archive inventory **passed** (1,108 members, 74 publisher wheels,
3 external assets); CPU `--require-installable` **failed closed** with
`required prerequisite is blocked: Visual Studio 2022 Build Tools`. The
Windows SDK row is also still `BLOCKED`. Thus v40 is not installable under the
current required graph. This verifier run establishes archive/manifest
eligibility only, not a successful installer or runtime installation.

The Microsoft rows represent a **scoped missing route**, not a categorical
prohibition on Microsoft tools. The current exact AutoClip route still lacks
sufficient qualification of acquisition, applicable vendor terms/consent,
downstream payload identity and integrity, and capability/operation behavior.
A later exact route may be evaluated with those facts bound; the CPU failure
must not be bypassed by deleting either row or altering the v40 identity.

## Stage B: new publisher-built CPU runtime qualification

The accepted consumer alternative is a **new immutable publisher-built CPU
runtime artifact**. Existing v40 remains the recipient source-build artifact;
it is not reinterpreted as publisher-built, installable, or approved for this
route. Build Tools/SDK, MSYS2, native source checkout, and recipient native
compilation may be removed from the consumer path only after the new exact
artifact passes its own gates. Microsoft runtime prerequisites, OpenBLAS,
NumPy, FFmpeg CLI, Python, and other qualified external routes retain their
separate identities and obligations.

Before this artifact can replace v40 for the CPU consumer route, its new
identity must bind:

1. Exact source repositories/revisions, source hashes, build host/toolchain,
   compiler and SDK identities, architecture, build flags/configuration, and
   reproducible build inputs/receipt.
2. Final wheel/DLL/file inventory and hashes, imports and native dependency
   closure, controlled CPU configuration, and absence of prohibited Microsoft
   or NVIDIA payloads, publisher caches, and excluded NumPy/native artifacts.
3. Actual artifact redistribution rights for every incorporated component,
   linking mode, notices, source/corresponding-source and replacement/relink
   obligations. Private recipient build evidence is not redistribution
   permission; inspect final bytes and deliver required source/notices.
4. A clean Windows install without recipient build tools: exact artifact
   integrity and notices, CPU imports/int8 transcription, representative media
   decode/render, health checks, failure-before-activation, upgrade rollback,
   and the generated uninstaller for the exact candidate.
5. A new versioned manifest/receipt and technical review for that exact
   candidate. Keep GPU/NVIDIA configuration and qualification separate.

No Stage B build, VM operation, vendor execution/acquisition, terms acceptance,
consent, install, release action, or publication occurred in this work order.
No approval from the v40 source-build evidence or IM-DEP-01 is inherited by the
new artifact. Actual model routing telemetry is not exposed.

## Packet contents

- `before-installer-dependencies-v1.json`, `after-installer-dependencies-v1.json`
- `exact-json-diff.json`: exact 40-path parsed JSON diff
- `artifact-evidence-map.json`: 26 changed classification fields, 14 parent
  rows, primary receipt hashes/scopes, and the two unchanged blockers
- `original-evidence-index.json`: source paths, original hashes, and evidence
  scope, without rebinding or rewriting historical receipts
- `verification-and-revisions.json`: exact commands/results and source hashes
- `user-research-disposition.txt`: byte-exact copy of the user's disposition
- `packet-manifest.json`: hashes and lengths of packet files


## Revision supplement

A byte-exact revision supplement is preserved at
`D:/Projects/autoclip-runtime-evidence/IM-DEP-03-revisions-20261002-8c4255e45271`.
Its `supplement-manifest.json` (SHA-256
`1e41def7007988049269158f40c74b3acde7b31d15e00d853c0f7ab770f5b1cc`)
binds to the original Stage A `packet-manifest.json` SHA-256
`0215338396345042595f63f9b4816642b8efca283a4076f5408788c66b06251b` and
`verification-and-revisions.json` SHA-256
`e190905b6b6efb6fc53cbfe1743b81583480d6087739017108e8da063085e70d`. The
original Stage A packet was revalidated and left unchanged.

The supplement contains byte-exact copies of the verifier and both focused test
files. Before copying, all three matched their Stage A revision hashes exactly:
verifier `65796bc7fe8d2aa913bac05000a87778ae0183440a0575c092ddf80a237cb6b7`,
manifest tests `c01775d05d6f42fe0f793459db0689ca7dafcf4666b3248385707c28653700ba`,
and builder tests
`b5e663f21c8518b21748f061cef4b0a4178af7e256750a8d83e1e0dd9b54d69a`.

It also preserves `scripts/build-inno.py` at SHA-256
`0e648c52299ac4e825452cc687046eb06ee53590c9e063e02b26e2c141552bc2`. That
file was not included in the Stage A revision list. The supplement binds its
current exact bytes, but cannot retroactively prove they were the bytes imported
by the earlier builder-test run. No tests were rerun for this evidence-only
supplement.

Proof-document copies are included with their source hashes. IM-DEP-01 matches
the Stage A evidence-index hash
`57a7e509081b521359c76f0d7d83b9732749e64964082a79e63c4615dbe8456e`. The
frozen contract snapshot matches its blind-review `snapshot-manifest.json`
record, SHA-256
`8b004efe373c47b039adeecfc51e031e31ddd81f7fed3df596db1525318e07a5`. IM-DEP-02
was not previously hash-pinned in Stage A; the supplement captures its current
worktree bytes at SHA-256
`29ffc439b246d70ff2d18d06115936d184e0c15e7345a75b8da66049f748b6c1`.
