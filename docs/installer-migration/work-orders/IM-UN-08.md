# IM-UN-08: register the verified native uninstall launcher

Date: 2026-10-02. Parent assignment authorizes the bounded integration following
the IM-UN-07 generated-uninstaller DAT sharing finding. The root owns the updated
contract, new candidate, review and VM lifecycle qualification. The receipt agent
owns the consumer, handoff authority and receipt writer. This work owns Inno
integration and its compiled diagnostic. No generated AutoClip Setup or
uninstaller was executed here.

## Requirement and boundary

Inno opens its DAT exclusively before InitializeUninstall. The separate consumer
therefore authenticates the native pair before native launch and issues a
receipt-bound live-launcher handoff. Callbacks require that handoff; the consumer
checks its authority and locked DAT metadata. Callback integration never
substitutes a successful unreadable DAT hash check.

Setup deliberately writes both Registry64 uninstall commands after native
registration exists and before final receipt production. The default command
starts the native Inno UI through absolute system PowerShell and the pinned
existing consumer's `-LaunchNativeUninstall` mode. The quiet command additionally
passes the finite `-NativeSilent` switch; its consumer maps that switch to fixed
native silent arguments. No arbitrary arguments are forwarded. The final request
supplies `native_uninstaller`, `uninstall_command`, and
`quiet_uninstall_command` for the writer to bind to the actual registration and
finite native pair. The five durable helpers are unchanged.

The generated loader checks reparse ancestors, opens the consumer with read and
delete sharing, and checks its exact hash before executing it. Delete sharing
allows the native uninstaller to retire its durable helper while the launcher
waits; writes remain excluded. This uses the existing trusted recipient,
administrator and SYSTEM actor scope. Missing handoff path or malformed SHA-256
refuses the callback before its child process boundary. Full handoff validation
remains in the pinned consumer.

Existing confirmed cleanup, preservation reporting, native abort on authority
failure, and post-native receipt retirement are retained from IM-UN-07.

## RED and GREEN

The diagnostic compiles the actual Inno functions. Native process and registry
boundaries are replaced by inert first-party fixtures; original lifecycle and
receipt retirement assertions remain enabled.

RED before integration: compiled callback diagnostic reported
`Direct invocation accepted missing/invalid handoff` in
`C:/Users/beilo/AppData/Local/Temp/autoclip-uninstall-wizard-acc9f953ec474c608ed41a4a1839a3b3/result.txt.log`.
A separate quiet-registration RED reported
`Quiet uninstall registration lost fixed native silent semantics` before the
intentional quiet switch was implemented.

GREEN checks the actual compiled callback refusal before launching a child,
both captured registered commands, final request binding, default and quiet
loader execution with an inert pinned consumer, every delegated helper hash,
and rejection of changed consumer bytes without another invocation. The actual
receipt anchor and finite retirement commands still run against protected
private fixtures. Latest diagnostic evidence:
`C:/Users/beilo/AppData/Local/Temp/autoclip-uninstall-wizard-7c9c7f9f205d4cdc9ab8d327532b3912`.

Commands from `D:/Projects/autoclip-runtime`:

```powershell
powershell.exe -NoProfile -NonInteractive -File tests/InstallerUninstallWizard.Tests.ps1
python -m unittest discover -s .github/tests -p test_inno_build.py
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpuConsent.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerPublisherCpuWizard.Tests.ps1
powershell.exe -NoProfile -NonInteractive -File tests/InstallerMsys2Wizard.Tests.ps1
git diff --check -- installer/AutoClip.iss scripts/build-inno.py .github/tests/test_inno_build.py tests/InstallerUninstallWizard.Tests.ps1
```

Results: uninstall diagnostic PASS; 14 builder tests PASS; consent PASS; CPU
wizard PASS; all 13 MSYS decisions PASS; diff check PASS. Builder code and builder
tests need no additional change because this integration uses existing macros
and the existing pinned five-helper inventory.

## Integration identities and remaining evidence

| File | SHA-256 |
| --- | --- |
| `installer/AutoClip.iss` | `a87968bf63bbbef82338abbf75b222e3bb1c91f544e7af128f2509736a161ad7` |
| `tests/InstallerUninstallWizard.Tests.ps1` | `37ba71d8476dd4440c8dc92ac09d5b18a46210443fe26f8042e29eb63789f1a6` |
| unchanged `scripts/build-inno.py` | `87ba28d0fa4fc1dd8697e8f4f72ca4a308f6ff4ca20cb7dfe0be2e5703871277` |
| unchanged `.github/tests/test_inno_build.py` | `dc8c749282882de87d4b1cde155abb2aeb527922cee85642de54573711392ea3` |

These tests prove the compiled integration and delegated parameter contract.
They do not prove actual native DAT locking, live process ancestry, full
consumer launch mode, or a generated install/uninstall lifecycle. Consumer
verification, new artifact review, and then the authorized clean-machine
installer followed by generated-uninstaller test remain with their owners.
