# IM-VS-39 — remove an unsupported argument from layout generation

Status: prepared and focused fixture-verified, 2026-10-02. Root authorizes this deliberate bounded argument correction from actual native failure evidence and owns the later operation. Only the two new external files and this report were written. Frozen VS38 source/tests/report, receipts, controls and other writers are preserved. No VM/server/vendor/acquisition/trust-store operation was performed by this author.

## Actual behavioral RED and requirement correction

Rehashed actual VS38 full primary `D:/AutoClip-Inno-Migration/vm-vs38-layout-primary-2d74d969cb6c.json`:2,230,545 bytes/SHA256 `2d74d969cb6c45c938e4762d508ae76d61dcc1faed001f46ca1fd5d01a4220f5`. It remains `FAILED_PRESERVED`, native vendor PID7956 exit5007, start09:36:50.0473127Z and exit09:36:54.7011035Z. Root-owned parent PID5896/handle1836 returned2. Protected408 copy matched; current bootstrap/OPC trusted; installed868 matched before/after;397 payload differences zero. These successful guards do not make layout generation successful.

Native bootstrap log `vm-vs38-native-0000.log-f919c08bcbdb.log`,2,489 bytes/SHA256 `f919c08bcbdbb2a72854612d3b501c636eb9aced1bc03f790a068095686e1726`, records the selected layout command and error: “Noweb is specified in an unsupported scenario.” Root preserves both raw native logs and the original exit.

The correction removes `--noWeb` from **layout generation only**. Microsoft's reference describes that option as installing product packages from a layout. It documents layout arguments, bootstrapper `--wait`, and `--noUpdateInstaller` preventing self-update when quiet is specified, with nonzero failure when an installer update is required. The actual fixed vendor command supplies the decisive evidence that `--noWeb` is unsupported in this layout scenario. [Microsoft command reference](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022).

This intentionally supersedes VS38's report restriction against removing flags for a retry only for the demonstrated invalid layout argument. Physical guest NIC isolation, current normal trust, exact inputs/engine, protected write points and no-update condition remain required. No online fallback, latest adoption, force/NoCheck, product-install flag revision or automatic retry is authorized by this snapshot.

## Exact minimal snapshot

| External file under `D:/AutoClip-Inno-Migration/vm-transfer` | Bytes | SHA256 |
| --- | ---: | --- |
| `vs-admin-layout-probe-r2.ps1` |22,620|`cae1f1f20778101fa6f9eda983bce8373ae2b53f71e1740dc1026f5989321267`|
| `vs-admin-layout-probe-r2.Tests.ps1` |5,117|`81314cfdb83f1e123c894cf3c0ff99f1adfcc73eb431a4ef8901be959dd59b19`|

Verified original22630-byte source still SHA256 `14f7a74b7301dc097e376d8fc3f17d11451abf10862e1e15fd5720e05506cdec`. New source is exactly its bytes with the single ten-byte token `,'--noWeb'` removed from `Get-AdminLayoutArguments`; every other byte is unchanged. Thus all existing guarded context/ACL/readlock/native-handle/authentication/receipt/output/log behavior remains the reviewed VS38 implementation.

Fixed native command becomes:

```text
<protected exact bootstrapper> --layout <new protected layout> --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --lang en-US --quiet --wait --noUpdateInstaller
```

Default remains read-only. Root reviews exact r2 bytes, stages a fresh protected first-party admin copy, rechecks inputs/current trust/external NIC OFF and invokes one bounded same-input operation:

```powershell
powershell.exe -NoProfile -File <exact protected r2 driver> -RunLayout -SeedRoot 'C:\Users\autocliplab\AppData\Local\Temp\vs s-eaff683d\layout' -SeedReceiptPath 'C:\Users\autocliplab\AppData\Local\Temp\vs s-eaff683d\receipt.json' -SeedReceiptSha256 '8300e91e41a275188d9e9a068896a1e26fcb027fe633ca2c16727a38354c965c'
```

Literal actual VS37 seed/root/552453-byte receipt and VS36 authentication210068-byte/`ca647e67878cecded40988c12b6e2f6953b2475e01b5b6e284170db5f2755fe4` bindings are unchanged. Do not overwrite the previous failed vendor stage. A nonzero vendor exit still fails closed and preserves output without retry. Generated controls still require review/new pins/vendor verification before native product installation; canonical route and final fresh Inno wizard gates remain outstanding.

## Focused RED → GREEN

RED command:

```powershell
powershell.exe -NoProfile -File 'D:/AutoClip-Inno-Migration/vm-transfer/vs-admin-layout-probe-r2.Tests.ps1' -Legacy
```

Actual frozen VS38 function returns the unsupported token: exit1, `RED: native layout must omit unsupported --noWeb.` This is the smallest function-level regression paired with the primary native5007 behavioral RED.

GREEN command:

```powershell
powershell.exe -NoProfile -File 'D:/AutoClip-Inno-Migration/vm-transfer/vs-admin-layout-probe-r2.Tests.ps1'
```

Final exit0 retains all focused checks: supported fixed arguments/context/NIC, ACL object policy, native first-party CreateNew/pin/no-overwrite/readlock/reparse behavior,408-row receipt drift, actual process stanza cmd exits0/7 and readonly default. PS5.1 parsing passes. Applied admin ACLs/native vendor generation remain guest-only observations; no fake vendor-success result is claimed. Exact byte comparison confirmed the one-token source difference.

The cancelled prefix diagnostic remains unimplemented/unexecuted: only `vs38-prestage-readonly.Tests.ps1` scaffold exists, whose initial RED reported absent driver. Root found the earlier native PowerShell assembly-load/pagefile error in actual event evidence; no new prefix source or runtime invocation was created, and no source/security bypass follows from that environment failure.

## Root actual execution in progress

Root reviewed source/test/report, verified the exact ten-byte-only source change,
and reran focused legacy RED exit1/current GREEN exit0. Fresh protected driver
`C:\ProgramData\ac-driver-39d17bc2\vs-admin-layout-probe-r2.ps1` was staged by
original5192/handle3732/start2026-10-02T10:08:42.3759269Z, terminal0. Full staging
primary `D:/AutoClip-Inno-Migration/vm-vs39-staging-primary-d9fbe6c560aa.json`,
SHA256 `d9fbe6c560aa09ee8941897aa53861317e64549b02e6f3b6b871107ce8020e9b`,
binds22620/cae1 and protected BA-owner/SYS+BA FullControl/recipientReadExecute ACL.
Native helper rechecked root/file ACL and locked source pin before invocation.

VBox cable independently OFF before operation, with8GiB available virtual reserve
guard. Original native driver9832/handle3696/start2026-10-02T10:10:49.3633997Z
is retained in ordinary native64 console2852, variable `$layout39Proc`.
Fresh observed stage `C:\ProgramData\ac-layout-c1e65b39`; native bootstrapper8072
and child5060 observed. Driver remained live at10:13Z; no terminal result,
generated-control qualification or success claim exists yet. The separate live
progress diagnostic used parsed local start time without UTC normalization and
also listed the older VS38 stage; that broad list is not stage attribution.
Frozen driver/full eventual receipt supplies authoritative stage attribution.
No kill/restart/network fallback/product install/uninstaller has occurred.

### Terminal result and preserved primary

Original driver9832/handle3696 is terminal2. Original native bootstrapper8072
started2026-10-02T10:12:12.8104284Z, exited5003 at10:17:21.4741947Z.
Full2,230,813-byte primary:
`D:/AutoClip-Inno-Migration/vm-vs39-layout-primary-7bcc7d69cc5e.json`, SHA256
`7bcc7d69cc5e279f63d2276e66a8d37c01a58fc818ebac1ed6a0c6200aef5736`.
Original terminal observation SHA256
`83b93999ed4a4a6ed6c8cf98fb919d3bfbcd1ac2b56dc8907156a7aead11b38b`.
Root checked six transport chunks and the full hash, then independently compared
every408 source/copy/after triple to VS37 and868 engine-before/after triples to
VS25; all match, no payload differences, full authentication documents equal
VS36. Current bootstrap normal native chain trusted with empty statuses. This
is a failed layout operation, not product installation or route qualification.

Exact38,470-byte bootstrap log SHA256
`88c257577bc14f37e0cfc5d2d13b205ef354c59375a7e245a1f07f4e019a1f21`
and1264-byte extraction log
`0d76152f970f9305153917f0fa8ce9c22f507c5bd2ac600ae44cfdcd79d5d81a`
were preserved from their frozen receipt rows. Full53,289-byte native-log envelope
SHA256 `8ff24d75e727099f8f31360d8f4c834cc54df4e96b4b9d66cccbda4534005299`.
Native logs show fixed bootstrapper-corresponding installer URL
`https://aka.ms/vs/17/release/525981922_-560036080/installer`, repeated DNS12007
failures with NIC OFF, and a separate latest/feed lookup failure. No latest
installer adoption is evidenced. This establishes that these controls and
`--noUpdateInstaller` do not eliminate layout-packaging engine acquisition.
All vendor log snapshots captured without collection errors; global monitor/log
completeness remains false. Network reconnected only after the original terminal
result for metadata transport. No automatic vendor retry or product install.

Microsoft documents bootstrapper-corresponding installer selection when
useLatestInstaller:true is absent; current355-byte controls already satisfy that.
No documented switch was found guaranteeing reuse of the preloaded OPC during
layout generation. --keepLayoutVersion concerns product version, and install
Catalog/Channel switches do not establish a layout-generation remedy. Further
supported acquisition/validation work is required; root requested a bounded
internal contract review of a normal online vendor layout route before the next
operation. It is not blind final review or an approval.

Bounded internal contract review concluded that one connected layout-only
experiment is supported: Microsoft requires Internet for initial layout creation,
and quiet/noUpdateInstaller prevents installed-client self-update or fails if
required. The failed temporary OPC download is a layout artifact acquisition;
it is not proof that downloaded engine code executed. The next experiment keeps
all exact pre-execution identities and protected staging. Before product install,
root must verify fetched OPC expected identity/signature, generated complete
layout/control/payload pins, vendor --verify and unchanged selected installed868.
Native command/log/execution evidence must resolve any indication of unknown
executed source or engine replacement. Incomplete samples are corroboration,
not absence proof; no new whole-machine tracing gate was added. This review
authorizes an experiment only and does not qualify cold acquisition, full Inno,
legal clearance, final technical review or release. Root delegated new external
online helper/tests and IM-VS-40 preparation; frozen VS39 remains unchanged.
