# IM-MS-14: empty archive-member verification

The first real frozen base/package guest chain failed before GPG or bash.
Python extraction completed, but the base helper's common file-pin check
required every file to have positive length, including authenticated empty
archive placeholders. The first rejected path was
`etc/pki/ca-trust/extracted/pem/objsign-ca-bundle.pem`.

Primary failure receipt:
`D:/AutoClip-Inno-Migration/vm-msys-chain-empty-file-failure-e06a18ee1930.json`,
SHA256 `e06a18ee1930f5a80562769515ac9e835aba903754538fa3e3138f1ffae1a129`.
Protected root `C:/ProgramData/acm-a20c58a6/msys64`, guest first-party inputs,
full extraction receipt and failure logs remain preserved in
`C:/Users/AUTOCL~1/AppData/Local/Temp/acmp-8aeb5803568a`. No partial directory
was deleted or reused. The original chain PID 3392 was checked terminal before
another attempt was prepared.

## Requirement and smallest correction

The contract requires complete authenticated regular-file inventory validation;
valid empty members must be accepted. Add an explicit `AllowEmpty` switch to
the shared pin validator and use it only for archive inventory files. Default
archive/signature/key/helper validation retains positive-size enforcement.
Even in inventory mode, negative sizes and changed bytes/hashes fail closed.
No public/domain API outside the internal helper changed.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/InstallerMsys2Base.Tests.ps1
```

RED: a real empty first-party file with the exact empty-file SHA failed the
actual validator. GREEN: the focused suite passes; inventory mode accepts
exact empty bytes, default mode rejects them, and changing that file is rejected.
No host operational extraction or vendor execution occurred.

Updated helper SHA256:
`70293061a4a5c41e7064e7c7f22e4f6132d08161e0a448196602d018240e61be`.
Updated test SHA256:
`a49c6f1743c60ecc9585e63830b18e2548bda67562a608525863e1259ffcadd5`.
Corrected first-party guest probe SHA256:
`c397f8321fa2a7109c41e91f98de94d88f1466b6d9b9c018ecb4f87c0a33c6c2`.
Historical first-party probe retained as `msys-chain-probe-e846a784.ps1`, exact
original SHA `e846a784fd41b3e32076c7a1f4cfa36d6172fa10092f01a16dee2d0af3814adc`.

The subsequent fresh-directory guest operation remains a separate
qualification. Neither this unit correction nor earlier experiments establish
the full Inno setup, source build or publication gates.

## Fresh real guest chain result

The corrected probe ran in fresh `C:/ProgramData/acm-4cdbdafc/msys64`, with
logs under `C:/Users/AUTOCL~1/AppData/Local/Temp/acmp-dbf0fa6fb19f/logs`.
It returned `VERIFIED_BASE_AND_PINNED_PACKAGES`; previous failed roots remain
preserved. Primary summary:
`D:/AutoClip-Inno-Migration/vm-msys-chain-r2-success-5966b4f4aa4c.json`,
SHA256 `5966b4f4aa4c25800f0e4fb48c4e681b9f6e26bdf71913954fe8060c4cec7c7c`.

Complete extraction checked 15,529 files and 1,052 directories; extraction
receipt SHA256 is
`708ca951ec1c438e7d3fed2b6bada51bff926c09144a80349c8051c6c41fc670`.
The base helper verified archive signature, local default keyring, one upstream
login, documented effects, private HOME, protected paths and 532 code records.
Base receipt SHA256:
`d213446772ad586dcfcf799e4e12ce0237cde47f64ae1df36d942ce0e428c6c3`.
The pinned package helper independently consumed that receipt, completed the
exact five trusted transactions and capability checks, and recorded 547
post-install code records including UCRT64. Package receipt SHA256:
`334569d44ffe3a5e382ab9bfe2809779fe69dac8c98a43c1f35177dd8461a5e8`.
Installed versions are diffutils 3.12-1, make 4.4.1-3, UCRT64 NASM 3.02-1,
UCRT64 zlib 1.3.2-2 and pkgconf 3.0.7-1.

The operation used production helpers with a diagnostic clone marking only
the MSYS2 route DIRECT. The canonical manifest remains BLOCKED, and this pass
does not establish actual source-guard execution, the native AutoClip build,
the complete Inno wizard, or release approval. IM-MS-15 prepares the next
guarded query qualification on this exact root without altering its files.
