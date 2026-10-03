# IM-CPU-18 — combined private CPU diagnostic manifest and fresh MSYS2 chain

## Scope and contract

Parent authorized only three new first-party transfer controls and this report. The runtime updater architecture, installer contract manifest/receipt binding, and parent work order govern the preparation. Existing production helpers, canonical manifest, prior diagnostics, receipts and caches are unchanged. No host network/vendor operation, guest operation, extraction or source build was performed by this work order.

This is a full diagnostic clone of canonical SHA256 `90d6189f173526f9d1d9c9a5f40aa2135f49f59bb7fa23cd68fa61ba11ff2119`. Exactly **25** `delivery_classification` values change from `BLOCKED` to `DIRECT_RECIPIENT_DOWNLOAD`; every other parsed field is preserved:

- `build_prerequisites[3]` MSYS2 parent, detached signature, installer key, and each of five package rows plus each package signature: 13 values, identical to the existing `8c75a8d22a50e0c8a5fada9b50d768b6395e1fe3cde5e70e1e9051404a0e182e` diagnostic selections.
- `build_prerequisites[1]` Gyan FFmpeg: one value, identical to the existing FFmpeg `64514f4460ffd5b0cf16f559a9f77bcd36804a344a97ef46b784394ce2b57c54` selection.
- `native_build_assets[0..8]`: nine values, identical fixed input metadata to the original native fixture `c84cc8f49c79cad7fd65ecaaad6853d0341f076ff45ffaea75d028b10a3eb5d8`.
- Parent follow-up explicitly authorized `build_prerequisites[0]` uv and `[2]` Git for Windows: two additional values. Their URLs, sizes, hashes, notices and all other fields remain canonical. Parent supplied bounded recipient diagnostic evidence IM-TOOL-01/02/03 and guest tools receipt `340b...` as the basis; this report does not independently requalify those tools.

Python, Visual Studio, compiler rows, optional NVIDIA and every other classification remain exactly canonical. Canonical blocked reasons are retained verbatim even on diagnostic direct rows. This fixture is not a canonical promotion or a whole installer/build qualification. IM-ACQ-18 is the parent's private recipient-use basis for the nine native inputs. Parent separately reports actual current-downloader acquisition receipt `vm-native-r2-primary-95192fd7e134.json`; no acquisition is performed or claimed here.

## Probe and receipt binding

The original `msys-production-chain-probe.ps1`, SHA256 `c397f8321fa2a7109c41e91f98de94d88f1466b6d9b9c018ecb4f87c0a33c6c2`, is preserved. The new probe changes only its diagnostic manifest basename/hash and adds held first-party read locks plus immediate hash rechecks. Its `Protect-GuestStage` body, ordinary autocliplab/native x64/unelevated guards, vendor-input cache paths and actual base/package helper commands are retained. Each run creates new protected TEMP `acmp-<12 hex>` staging and short `C:\ProgramData\acm-<8 hex>\msys64` root through the same production base helper. It does not initialize or mutate the old MSYS2 root.

Every downloaded first-party helper and the new manifest is hash-checked and opened with `FileAccess.Read`/`FileShare.Read`; locks are retained through base and optional package execution. All held streams are hashed again immediately before each helper call and disposed in `finally`, including failures. Protected staging prevents another recipient process from replacing input controls while the held streams block writes/deletion. Existing TAR/key/signature/package cache inputs are still verified by unchanged production helpers before native execution; the chain adds no trust, signature or receipt bypass.

The base helper receives the new manifest SHA, and the package helper must return that same SHA plus the newly generated base receipt hash/private home. Old `8c75...` receipts cannot authorize this new manifest. Successful base/package receipts and summary stay under the new protected stage/log paths. Failure roots/output remain preserved.

The original `/msys-tar-packages` laboratory callback is intentionally retained. **Before the parent run, the parent must preserve the old endpoint receipt and redirect that endpoint to a new immutable result target.** This work order did not change the server or old receipt. Endpoint transport failure may prevent the final stdout summary; local summary remains available. The script's package helper SHA parameter retains the original interface; the invocation below supplies the exact frozen `889d...` helper.

## Frozen controls and invocation

| New control | SHA256 |
| --- | --- |
| `D:/AutoClip-Inno-Migration/vm-transfer/cpu-build-diagnostic-manifest.json` | `92fcd18f5f8e7fd905a25513702e45906d7f134cfceb5ac835437f1b45ccb116` |
| `D:/AutoClip-Inno-Migration/vm-transfer/msys-cpu-chain-probe.ps1` | `58fcc7f2465beaf7ac5446ec71599192269362e7bf8258495003d6e0c2aa9a24` |
| `D:/AutoClip-Inno-Migration/vm-transfer/msys-cpu-chain-probe.Tests.py` | `f97fc1ca037efef151affda3803ea405c8d25805dcedb8bf6ae5205a3f55153a` |

Parent serves only these exact first-party basenames at the existing laboratory server: `cpu-build-diagnostic-manifest.json`, `install-msys2-base.ps1` (`70293061a4a5c41e7064e7c7f22e4f6132d08161e0a448196602d018240e61be`), `extract-msys2-base.py` (`23307cdbcafd03fb0d03b209cb2dceb35a4e2eed99c2ecfccda9571374fc1596`), `install-python.ps1` (`081b312795cc8b038de2ce511d2a8baabd23ffec55f7ef2f7269dbbb105f02e3`) and, for package execution, `install-msys2-packages.ps1` (`889dc7106dcc5c076dbe08aca8d45726dfe22edb7d199839755d60bd26a2a48b`). No vendor bytes are served or acquired by this probe. The pre-existing guest TAR/key/signature cache is `%TEMP%\autoclip-msys-tar-20261001`; five packages/signatures are `%TEMP%\autoclip-msys-trust-20261001`.

```powershell
# Read-only default: no IO mutation/network/native action.
powershell.exe -NoProfile -File .\msys-cpu-chain-probe.ps1

# Parent-owned explicit ordinary guest qualification; not run by author.
powershell.exe -NoProfile -File .\msys-cpu-chain-probe.ps1 -InstallBase -InstallPackages -PackageHelperSha256 889dc7106dcc5c076dbe08aca8d45726dfe22edb7d199839755d60bd26a2a48b
```

## RED / GREEN and limits

Exact focused command:

```powershell
python D:\AutoClip-Inno-Migration\vm-transfer\msys-cpu-chain-probe.Tests.py
```

1. Initial RED: absent manifest/probe gave two failures and two errors. With the approved initial 23-field clone and old-chain manifest substitutions present, the meaningful read-lock test still failed `Missing hash guard`, and native-boundary ordering test failed because no immediate recheck existed.
2. GREEN: after adding the held stream guard and pre-call rechecks, all four tests passed. Actual first-party disposable file writes under `FileShare.Read` fail with `IOException`; a mismatched expected hash cannot reach a simulated native boundary; disposal permits subsequent writes. Tests AST-load only the hash function.
3. Parent's uv/MinGit requirement update: RED `test_exact_classification_transform` failed with the old 23-field fixture. After only the two newly authorized classification changes and probe hash rebinding, all four tests passed again (1.018 seconds).
4. Fixture checks entire parsed manifest equality after independently reverting the exact 25 selectors, original MSYS/native/FFmpeg source hashes, nine native field equality, original protected-stage function/native command reuse, new hash binding and recheck-before-helper ordering. Default probe exits 0 with `READ_ONLY_PLAN`; explicit `InstallBase` on the host fails the guest guard before staging/network/native operations.
5. PowerShell parser check reports zero errors for the new probe. Frozen original chain and canonical/helper hashes were independently rechecked after implementation.

The runnable fixtures perform first-party metadata, PowerShell parsing, isolated read-lock operations and host rejection only. They do not qualify real MSYS2 ACL inheritance, signatures, init/login, packages, installed Visual Studio, source compilation, FFmpeg or the full installer. Root owns the real ordinary guest execution and subsequent CPU source-build evidence. No production contract or classification is changed.
