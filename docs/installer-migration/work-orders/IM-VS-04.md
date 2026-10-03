# IM-VS-04: process-scoped firewall control for native Visual Studio setup

Status: read-only investigation complete. A standard Windows Firewall
program-rule set is **not yet a qualified enforcement boundary** for an
internet-connected, native-interactive Build Tools first install. This is an
internal implementation-collaborator report, not a blind technical review,
vendor agreement, legal approval, or recipient installation result. No file
outside this report, host/guest setting, firewall rule, installer, or VM was
changed or run for this work order.

## Required boundary and supported vendor route

`AGENTS.md:3-13`, `docs/runtime-update-architecture.md:188-208`, the
[installer contract](../contract-v1.md), and [IM-VS-03](IM-VS-03.md) require
exact reviewed inputs and native Microsoft agreement UI, with an affirmative
recipient terms decision before a prerequisite install. The recipient may
acquire the fixed bootstrapper and selected layout directly from Microsoft,
check an independent exact inventory, and run Microsoft's layout `--verify`.
The [Microsoft local-install guide](https://learn.microsoft.com/en-us/visualstudio/install/create-an-offline-installation-of-visual-studio?view=vs-2022)
supports installing interactively from that local layout with `--noWeb`.

The [parameter reference](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022)
documents `--installChannelUri` and `--installCatalogUri` for local install
metadata, and says `--channelUri` may point to a nonexistent local file when
future updates are unwanted. That last option is a **supported update-source
configuration**, worth trying in the guest instead of the mutable `aka.ms`
default or even the local update channel. It is not documented as a control
over the installer's own self-update. Microsoft explicitly warns that
`--noWeb` does not stop installer update checks on an online client, and says
`--noUpdateInstaller` prevents self-update when `--quiet` is specified. Quiet
would remove the required native agreement UI. A separate documented local
`--quiet --update --wait --offline` step can prepare the exact layout OPC
engine before the interactive product step; it does not establish what the
later interactive first install will do.

## What an outbound program rule actually covers

The [Windows Firewall guide](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/configure)
supports an outbound block scoped to a program's full executable path or a
Windows service. Such a rule can leave unrelated programs online if it
matches every network-calling vendor process. The [rule reference](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/rules)
explicitly disallows wildcards in application paths; it describes a separate
App Control policy and `PolicyAppId` tag mechanism for groups of processes.
Neither ordinary program rules nor their service variants automatically
attach to all descendants of a launcher. Microsoft's [firewall authoring
guidance](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ics/general-firewall-rule-authoring-process)
requires identifying each network-facing process, service, driver, and
out-of-process transport. AppID tagging would require a deployed App Control
policy and proof that it tags every relevant process; it is not a one-rule
process-tree switch.

The inspected exact 17.14.41 layout creation log
`%TEMP%\dd_bootstrapper_20261001112202.log:21-41` shows the bootstrapper
downloaded `latestinstaller.json` and `vs_installer.opc` with `WebClient`, then
launched `setup.exe` at
`%TEMP%\1behw0l.aop\resources\app\layout\setup.exe`. The subsequent
vendor `--verify` log
`%TEMP%\dd_bootstrapper_20261001112631.log:13-29` used the local OPC, then
launched `setup.exe` at a *different* path,
`%TEMP%\hixv5bt.fbg\resources\app\layout\setup.exe`. These are layout and
verification runs, **not** an observed interactive first install. They prove
the fixed bootstrapper path alone is an insufficient rule target and that the
child extraction path was not stable across these two runs. Adding the rule
after a child appears has an uncontrolled interval during which its first
request or self-update might occur. Setting a fixed parent `%TEMP%` still
leaves the random child directory; a wildcard program path is unsupported.

Read-only ZIP enumeration of this layout's reviewed `vs_installer.opc`
(SHA-256 `62f68d0d6e2adce5cd65f549cbda234358c1cbda442af4de1c3f7ae43fb8b5a6`)
found 22 executable members, including `setup.exe`, `vs_installer.exe`,
`vs_installer.windows.exe`, `vs_installershell.exe`,
`VSInstallerElevationService.exe`, `vs_layout.exe`, and
`BackgroundDownload.exe`. Membership **does not establish** that any of these
apart from the logged layout process executes or reaches the network during
the native first install. It does make a bootstrapper-only rule especially
unconvincing. The observed layout download engine was `WebClient`, not BITS;
BITS use in the target install has **not** been established. If a transfer is
delegated to BITS or another service, the network caller may be a service host
outside all bootstrapper/engine program rules. [Microsoft documents](https://learn.microsoft.com/en-us/windows/win32/bits/about-bits)
that BITS transfers can continue after the requester exits and resume after
reconnection or reboot. A BITS-service block would affect other consumers of
that shared service, so it cannot be assumed to preserve other applications'
network use.

## Effective-policy and lifecycle constraints

A production attempt would need elevation for rule creation, exact per-run
rule names, all active profiles, and an **effective policy** check before the
first vendor process starts. The [Windows rule reference](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/rules)
notes that policy can disable merging of locally created rules; the
[firewall-profile reference](https://learn.microsoft.com/en-us/powershell/module/netsecurity/set-netfirewallprofile?view=windowsserver2025-ps)
defines `Enabled` and `AllowLocalFirewallRules`. A persisted rule in the local
store is not proof it is enforced by the active profile, managed policy, or a
machine where Windows Firewall is disabled or another firewall has disabled
its application-rule handling. A negative outbound probe for each exact caller
image and a positive probe from an unrelated app would be necessary. A
bootstrapper signature, OPC hash, or installed-rule listing cannot substitute
for that check.

The rule set also needs deterministic cleanup on success, cancellation, UAC
denial, error, process termination, and reboot. Normal `finally` cleanup only
covers execution that returns to the wrapper. [Windows firewall rules can be
removed by identity](https://learn.microsoft.com/en-us/powershell/module/netsecurity/remove-netfirewallrule?view=windowsserver2025-ps),
but persistent rules can survive a crash or reboot. A pre-registered elevated
recovery task plus a journal of exact per-run rule names would make cleanup
recoverable, at the cost of further machine state and a tested failure path.
Removing rules immediately at startup could let a Visual Studio installation
resuming after reboot reach the network; retaining them until the vendor
operation is known complete is safer but requires restart-aware ownership and
manual recovery if the wrapper is gone. Broadly deleting Microsoft or all
blocking rules is unacceptable. Service-wide BITS or `svchost.exe` blocks
would extend the impact beyond this vendor step.

## Smallest bounded experiment, and decision

After a recipient terms decision authorizes a guest install, a clean guest can
use the exact independent layout inventory and vendor `--verify` from
[IM-VS-02](IM-VS-02.md), then try the native interactive command from
[IM-VS-03](IM-VS-03.md) with local `--installChannelUri` and
`--installCatalogUri`, `--noWeb`, and a deliberately nonexistent local
`--channelUri` for update detection. First observe under guest network
isolation, recording every process image/path, service/network caller,
destination, native agreement UI, local OPC use, engine hashes before/after,
and vendor logs. Then, only if all callers can be covered *before launch*, a
second clean guest could test exact path/service outbound rules with live
network, effective-policy and negative-probe checks, unrelated-app online
check, failure/reboot cleanup, and full installed VC Tools/SDK capability
verification. Any remote request by an uncovered process, installer engine
change, unreviewed payload, or rule ineffectiveness fails that candidate.
This is an experiment specification, not a claim that the rule set is already
possible or that native interaction has been observed.

**Decision for the current proposal:** Local-layout plus native UI is a
supported offline vendor step. A fixed-path Windows Firewall rule on the
bootstrapper and known installed engine paths cannot presently *enforce* its
offline boundary on a connected recipient: the vendor demonstrably extracts
a child to a random path, and actual first-install network/service callers
are unobserved. A dynamic rule added after process creation cannot close the
first-request race. Tagging every exact engine/payload process or a supported
vendor control might eventually provide a process-scoped boundary, but that
requires separate policy design and guest evidence, including service
delegation and reboot behavior. Keep the VS Build Tools/SDK clean-machine
auto-install classification `BLOCKED` until that evidence exists. Physical
guest network isolation from [IM-VS-03](IM-VS-03.md) remains a bounded way to
test the native offline path; it does not prove a connected recipient route.
The channel/catalog hash contradiction in IM-VS-03 is unchanged.

Checks performed: primary Microsoft documentation review; read-only exact
layout OPC member enumeration; existing bootstrapper, layout, and verify log
inspection; policy/architecture cross-check. No firewall policy was changed,
no vendor UI or install was run, and no clean-machine outcome is asserted.
