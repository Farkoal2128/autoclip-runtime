# IM-DEP-06: actual CPU source and notice preparation

Date: 2026-10-02. Parent authorized preparation of the corresponding source and
notice packet for the newly built publisher CPU artifact. Owned only
`D:\acpu-1002-3343baed\distribution-source` and this work order. Root owns its
future `provenance.json` and final packaging. No producer source, control,
packager, tests or other repository files were edited.

Requirement: `docs/installer-migration/cpu-native-artifact-v1.md`. Read the
IM-DEP-04 prereview at
`D:\Projects\autoclip-runtime-evidence\IM-DEP-04-e5aaac82516345629e76f5a84bf1a342\cpu-distribution-prereview.md`
before assembling the packet. This assembles actual source evidence; it does
not revise production behavior, so no new RED/GREEN claim is made.

## Prepared evidence

Original tar copies retain the required hashes:

- FFmpeg 8.1.2, 11,710,924 bytes, SHA256
  `464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c`.
- PyAV 18.1.0, 4,451,061 bytes, SHA256
  `47bfc286e1bc9de7ab4681fc2b575cd2460a66919d31ffe1bd5aa54fae531a28`.

Fresh Git archives were created with the fresh build's actual
`tools\mingit\cmd\git.exe`, from these actual checkout HEADs:

| Component | Checkout folder under build root | Exact commit |
| --- | --- | --- |
| CT2 | ctranslate2-v4.8.2-source | d44d2d069eb88c7b7804da864c10c201501cb4a9 |
| oneDNN | onednn-v3.1.1-source | 64f6bcbcbab628e96f33a62c3e975f8535a7bde4 |
| cpu_features | ctranslate2-v4.8.2-source/third_party/cpu_features | 8a494eb1e158ec2050e5f699a504fbc9b896a43b |
| spdlog | ctranslate2-v4.8.2-source/third_party/spdlog | 76fb40d95455f249bd70824ecfcae7a8f0930fa3 |
| cxxopts | ctranslate2-v4.8.2-source/third_party/cxxopts | 44380e5a44706ab7347f400698c703eb2a196202 |

Each original Git TAR is paired with an actual-build-inputs TAR of every regular
tracked source member's actual checkout bytes. Per-member comparisons identified
CRLF-to-LF changes only: CT2 497/505 files, cpu_features 85/85, spdlog 158/163,
cxxopts 33/35; oneDNN 0/3595. Both representations are retained with hashes.
No corrupted historical source ZIP was reused. Cxxopts supports the producer's
default `BUILD_CLI=ON` reconstruction; no CLI executable is shipped here.

All 10,111 original FFmpeg regular source members match the actual build tree.
PyAV has 51 differing original members after generation/build, including its
generated C sources and egg-info. Their exact bytes are retained in
`archives/pyav-18.1.0-generated-build-inputs.tar`, SHA256
`fd6a20a0c934a2a702f62245d6e47e5e5f0fed2f9483c5e8b71fe4c2a72e5b4d`.
`build-instructions/README.md` explains the original-tar overlay reconstruction.

The packet retains exact immutable producer control scripts under
`build-instructions/`, original LGPL/BSD/MIT/Apache texts, FFmpeg LICENSE.md,
full oneDNN THIRD-PARTY-PROGRAMS, cpu_features, spdlog/fmt, CT2 AVX math and
AVX512 notices, original PyAV and CT2 notices, and the pure source/header and
metadata members of the exact pybind11 3.1.0 build wheel. Binary build tools,
vendor runtimes, wheels and caches are excluded. Complete top-level source
archives retain applicable unused-platform source notices. CPU-used submodules
are supplied; CUDA/ruy/test-only submodule source is omitted from this CPU recipe.

FFmpeg's three IJG-derived source files match their original tar bytes and
`jfdctfst.o`, `jfdctint.o`, `jrevdct.o` existed in the actual build tree. Their
original notice-bearing sources and a separate IJG acknowledgment are supplied.
This FFmpeg configuration retains built-in codecs.

CT2's actual includes identify `avx_mathfun.h`, `avx512_mathfun.h` and
`BS_thread_pool.hpp`. With parent's explicit notice-research authorization,
the original [BS thread-pool v5.1.0 MIT text](https://raw.githubusercontent.com/bshoshany/thread-pool/v5.1.0/LICENSE.txt)
was fetched, SHA256
`712a867cc12ebfcdecf6cea097f5aa7ec5acaa435a8f818c9f370960df35acbf`.
Its original copyright/version matches CT2's header; comparing the exact
[upstream v5.1.0 header](https://raw.githubusercontent.com/bshoshany/thread-pool/v5.1.0/include/BS_thread_pool.hpp)
found only removal of its final newline. Original upstream header, actual CT2
header and difference record are retained. AVX512's full BSD text was copied
from the inspected v40 notice member with its exact prereview SHA256
`dfaa54b4188ffa0e6298ce7ea27c865d12edcf73d742e2200ce9812db6268c0f`;
its historical source basis is preserved, not relabeled as a fresh upstream fetch.

## Exact commands and verification

External Git commands used, for every checkout/commit in the table:

```text
D:\acpu-1002-3343baed\tools\mingit\cmd\git.exe -C <absolute checkout> rev-parse HEAD
D:\acpu-1002-3343baed\tools\mingit\cmd\git.exe -C <absolute checkout> archive --format=tar --output=D:\acpu-1002-3343baed\distribution-source\archives\<component>-<commit>-source.tar HEAD
D:\acpu-1002-3343baed\tools\mingit\cmd\git.exe -C D:\acpu-1002-3343baed\ctranslate2-v4.8.2-source submodule status --recursive
```

Inline stdlib Python copied immutable inputs, compared every archived regular
member against its actual checkout, retained all original-member changes,
created TAR companions, fetched only versioned plain source/license text,
and wrote the source associations/records. The tool transcript contains those
exact inline preparation commands. No Git checkout, native compilation,
vendor installation, terms acceptance or production source editing occurred.

Exact repeatable inspection command, from `D:\Projects\autoclip-runtime`:

```powershell
python -c @'
from pathlib import Path
import importlib.util
spec = importlib.util.spec_from_file_location('packager', Path('scripts/package-cpu-native-artifact.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
root = Path('D:/acpu-1002-3343baed/distribution-source')
files = [p for p in root.rglob('*') if p.is_file()]
for path in files:
    module.inspect_source(path.relative_to(root).as_posix(), path.read_bytes())
print('PASS', len(files), 'source/notice/evidence files')
'@
```

Result before root provenance: all 46 files pass the actual packager source
inspector, including every nested ZIP/TAR member; no exclusions or silently
dropped upstream payloads were required. Exact hashes/bytes for all payloads
are in `source-inspection.json` (its own hash is excluded from its internal rows).
SHA256:

- `source-associations.json`:
  `b90170c31c15785a70663f8749c4f14cf66b38030504ee9571b9d429f4a9ac7d`.
- `source-records.json`:
  `f2607c1e59ec1c2193f3894f3ac81312ed3edba4eda2d55679042874c9bed8bf`.
- `source-inspection.json`:
  `62d58de074e0102ea954850d9bb61f642a498a07fdb2ebf6d6a28e939f673b53`.

Limits: final producer provenance, exact actual-link closure, installed notice
mapping, FFmpeg replacement proof, source/legal completeness disposition,
clean-machine Setup/runtime acceptance and release permission remain root work.
The source inventory is evidence for those gates, not their approval. No final
artifact was packaged here and no `provenance.json` was written.
