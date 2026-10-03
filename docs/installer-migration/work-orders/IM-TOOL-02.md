# IM-TOOL-02 - Exact uv 0.12.19 top-level notice delivery

Completed 2026-10-01: the two assigned notice files were delivered as exact
upstream bytes. Parent authorization covers documentation/license delivery for
the Inno wizard migration. Ownership is limited to this work order and the two
files below. This is documentation delivery, with no executable behavior or
contract change and therefore no behavioral RED/GREEN claim.

Basis: `AGENTS.md`, `skills/runtime-updater/SKILL.md`,
`docs/runtime-update-architecture.md`, `IM-TOOL-01.md`, and
`dependency-disposition.md`. The identified uv ZIP omits top-level license texts;
this work provides the repository-side notice inputs for later recipient delivery.

## Exact files and attribution

| File under `release/notices/` | Bytes | SHA-256 |
| --- | ---: | --- |
| `uv-0.12.19-LICENSE-MIT.txt` | 1,077 | `860e3d7a86b84e6a7012c7a635fc64df475cebc6cce34dfeb73a5982ec58176c` |
| `uv-0.12.19-LICENSE-APACHE.txt` | 11,357 | `c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4` |

The [versioned Cargo.toml](https://raw.githubusercontent.com/astral-sh/uv/bea138450f0e620a4ce5765b0e38cff7b9f0799f/Cargo.toml)
declares `MIT OR Apache-2.0`. The MIT text carries
`Copyright (c) 2025 Astral Software Inc.` The Apache text is the upstream
Apache License 2.0 text, including its unfilled illustrative appendix; no
copyright substitution or additional attribution was inserted into either file.
Both preserve upstream LF bytes, with no BOM or carriage returns.

Primary text URLs, fetched and byte-compared:

- [MIT at 0.12.19](https://raw.githubusercontent.com/astral-sh/uv/0.12.19/LICENSE-MIT)
- [MIT at the exact commit](https://raw.githubusercontent.com/astral-sh/uv/bea138450f0e620a4ce5765b0e38cff7b9f0799f/LICENSE-MIT)
- [Apache at 0.12.19](https://raw.githubusercontent.com/astral-sh/uv/0.12.19/LICENSE-APACHE)
- [Apache at the exact commit](https://raw.githubusercontent.com/astral-sh/uv/bea138450f0e620a4ce5765b0e38cff7b9f0799f/LICENSE-APACHE)

Source entry points for the later recipient notice index:

- [Exact source tree](https://github.com/astral-sh/uv/tree/bea138450f0e620a4ce5765b0e38cff7b9f0799f)
- [Published 0.12.19 source archive](https://github.com/astral-sh/uv/releases/download/0.12.19/source.tar.gz)
- [Tag identity metadata](https://api.github.com/repos/astral-sh/uv/git/ref/tags/0.12.19)
- [Release asset metadata](https://api.github.com/repos/astral-sh/uv/releases/tags/0.12.19)

The fetched tag metadata resolves directly to commit
`bea138450f0e620a4ce5765b0e38cff7b9f0799f`. The source asset is `uploaded`,
8,720,078 bytes, SHA-256
`26a42b3580e990db68120838c2512a678aedd473c777b34aa802dc100ef7c76a`.
Its recomputed hash agrees with current publisher metadata and IM-TOOL-01.
The two root license members match both raw upstream representations and the
delivered files byte for byte. Source archive inspection occurred in memory,
without extraction or vendor execution.

## Verification commands and results

Working directory: `D:\Projects\autoclip-runtime`. Python runs used
`python -I -B -` through a PowerShell here-string; only Python standard-library
HTTP, hashing, JSON, tarfile, and file-byte operations were used. The acquisition
checked all upstream license sources before writing either assigned artifact,
refused preexisting paths, and reread delivered bytes. It exited 0 with:
`PASS: tag/commit/source/license bytes agree; exact-byte notice files delivered.`

The following exact focused verification command was also run after delivery:

```powershell
@'
import hashlib, json, pathlib, urllib.request
commit = 'bea138450f0e620a4ce5765b0e38cff7b9f0799f'
def fetch(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'AutoClip-IM-TOOL-02-evidence'})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()
ref = json.loads(fetch('https://api.github.com/repos/astral-sh/uv/git/ref/tags/0.12.19'))
assert ref['object'] == {'sha': commit, 'type': 'commit', 'url': f'https://api.github.com/repos/astral-sh/uv/git/commits/{commit}'}
for name, size, digest in [
    ('MIT', 1077, '860e3d7a86b84e6a7012c7a635fc64df475cebc6cce34dfeb73a5982ec58176c'),
    ('APACHE', 11357, 'c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4'),
]:
    path = pathlib.Path(f'release/notices/uv-0.12.19-LICENSE-{name}.txt')
    data = path.read_bytes()
    assert len(data) == size
    assert hashlib.sha256(data).hexdigest() == digest
    assert data == fetch(f'https://raw.githubusercontent.com/astral-sh/uv/{commit}/LICENSE-{name}')
    assert data == fetch(f'https://raw.githubusercontent.com/astral-sh/uv/0.12.19/LICENSE-{name}')
    assert b'\r' not in data and not data.startswith(b'\xef\xbb\xbf')
    print(f'PASS {path}: {size} bytes SHA256 {digest}')
print('PASS exact upstream identity and delivered notice bytes')
'@ | python -I -B -
Get-FileHash -Algorithm SHA256 release/notices/uv-0.12.19-LICENSE-MIT.txt, release/notices/uv-0.12.19-LICENSE-APACHE.txt
git status --short -- release/notices/uv-0.12.19-LICENSE-MIT.txt release/notices/uv-0.12.19-LICENSE-APACHE.txt docs/installer-migration/work-orders/IM-TOOL-02.md
```

Result: all assertions passed, Python exit 0; PowerShell hashes matched the table;
the scoped status listed only the three newly created assigned paths.

## Limits and remaining parent work

This closes repository-side top-level uv text delivery only. The parent still
owns integration of the exact files and source links into the installed recipient
notice index, final manifest bindings, wizard/cancellation qualification, and
all route dispositions. No manifest, setup source, executable tooling, tests,
installation, populated cache, publishing, or approval was changed here.
The uv disposition remains as recorded in the parent-owned dependency document.
No complete embedded/transitive license reconstruction, independent technical
review, human/legal approval, or installed notice-delivery claim is made.
