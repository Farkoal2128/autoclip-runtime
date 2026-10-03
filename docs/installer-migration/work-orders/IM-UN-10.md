# IM-UN-10: map actual generated-uninstaller evidence

Date: 2026-10-02. User reaffirmed the multi-agent workflow while the exact r7
CPU candidate entered VM testing. Root owns VM execution, integration and release.

## Read-only assignment

`r7_cleanup_evidence_map` (explorer, fresh context, no memory) inspected current
requirements, receipt writer, Inno callbacks and ownership removal helpers.
Parallel-safe scope: evidence paths and cleanup/retention criteria only. No
source edits, VM actions, vendor actions, uninstall or publication were assigned.
Actual per-run model and reasoning metadata: `not exposed`.

Candidate packet:
`D:/Projects/autoclip-runtime-evidence/IM-DEP-13-cpu-candidate-r7-objective-r2`.
Agent independently rehashed the frozen Setup: 3,430,551 bytes, SHA-256
`2ec0a2cb708e4b31f16fd4556bfea37f304fbc5d309cef176abe00575f1082e0`.
Its build receipt remains `UNVERIFIED_CANDIDATE`; this assignment grants no gate
approval. Root reconciled the result against the actual receipt writer,
`RunManagedUninstall`, `RetireUninstallEvidence`, and uninstall consumer source.

## Required actual run evidence

Before uninstall, preserve the COMPLETE installation receipt and SHA-256 anchor
under `%LOCALAPPDATA%/AutoClip/Setup/installation-receipts`, its exact release
and Setup inventories, shortcut rows, native EXE/DAT pair, and HKCU Registry64
registration snapshot. Record actual app/updater processes and concrete user
data, modified/unknown files and shared prerequisite sentinels with hashes/state.

After uninstall, retain the cleanup report under `Setup/logs/uninstall-<guid>.json`
and, for clean removal, `Setup/logs/uninstall-<ReleaseId>/retirement.json` and
retirement helpers. Compare every removed and preserved row with actual state.
Preserve modified/unknown/unsafe/locked files, user data, caches, older releases,
rollback references and shared/system prerequisites.

Process exit alone is insufficient. Independently confirm that the exact
receipt-listed native EXE/DAT pair and optional MSG, the precise HKCU Registry64
uninstall key, and (on clean removal) receipt and anchor are absent. A PRESERVED
result must accurately list retained files and keep the receipt and anchor.
The consumer explicitly reports `native_post_uninstall_observed=false`.

Actual generated-uninstaller execution remains sequenced after the working
installer and application checks, as requested by the user. This record is
source/evidence mapping; it does not report an executed lifecycle test.
