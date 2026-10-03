# IM-UN-09: retain the selection-removal refusal outcome

Date: 2026-10-02. Parent authorizes this bounded diagnostic correction after the
exact r5 blind review observed a generic selection-cleanup refusal. The original
cause remains unresolved; this change does not identify it or waive that review.

Implementer owns uninstall-owned-release.ps1, InstallerUninstallReceipt.Tests.ps1,
this order and one contract sentence. No primitive safety behavior, retry, vendor,
VM, release, frozen packet or original failed fixture is changed. Actual per-run
model telemetry is not exposed. Other agents own integration and candidate work.

## Requirement and smallest change

The existing primitive already reports a finite result. Store that result and
include `outcome=<status>` when exact current-only selection removal refuses.
Exit1 and preservation of selection/release remain unchanged. There is no retry,
assertion weakening, skipped check or relaxed ACL/hash/ancestry rule.

## Meaningful RED and GREEN

The actual native first-party fixture uses the full verified launcher/handoff
ancestry and exclusive DAT lifetime. A separate real read-only FileShare.Read
handle pins active.json during actual cleanup. Bytes and trusted ACLs remain
unchanged; DELETE is refused by Windows. The test requires `outcome=LOCKED` and
preserved selection/release files, followed by the existing ordinary cleanup,
unknown/modified/ADS/process/rollback/app-reference assertions.

Before production change, expected RED:
`Locked selection refusal discarded the native primitive outcome.`
Fixture: `C:/Users/beilo/AppData/Local/Temp/autoclip-uninstall-receipt-ae2005a4a2584586aea7431c0a97e6e5`.
Its callback stderr retained the old generic refusal. This controlled sharing
case is distinct from the original unresolved reviewer failure; do not infer
that the reviewer encountered LOCKED.

Commands from D:/Projects/autoclip-runtime:

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerUninstallReceipt.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerOwnedFileRemoval.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerUninstallWizard.Tests.ps1
git diff --check
```

Results and final hashes are recorded after focused verification. A changed
consumer requires new exact candidate hashes and scoped review. These inert
boundary tests do not qualify the generated installer/uninstaller or VM lifecycle.

GREEN: full receipt test PASS0, including controlled LOCKED refusal and subsequent
ordinary cleanup. Fixture:
`C:/Users/beilo/AppData/Local/Temp/autoclip-uninstall-receipt-92b8d1b330b748f19c36ac720294c3a9`.
Owned-file regression PASS0; compiled uninstall callback regression PASS0,
evidence `C:/Users/beilo/AppData/Local/Temp/autoclip-uninstall-wizard-804c76c6ca0f46808e04d3d23b4e4bdf`.
Diff check PASS. After these runs, the test additionally preserves the already
captured controlled diagnostic as locked-selection-refusal.err before later
callbacks overwrite callback.err; this evidence-copy-only adjustment was not
rerun. No further optional test repetition was performed.

Consumer SHA256:
127aabd282226510929a810c6997a870ae4f9cf6821a11757a8a36f740f0a305.
No claim is made that the original reviewer failure was LOCKED. Its frozen
packet, report and failed fixture remain untouched and its cause unresolved.
