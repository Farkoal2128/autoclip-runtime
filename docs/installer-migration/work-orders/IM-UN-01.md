# IM-UN-01: uninstaller ownership integration inventory

## Assignment

- Authorization: read-only contract and implementation inventory for the active
  Inno migration. No behavior revision or uninstall execution is assigned.
- Preferred role: contract_reviewer, configured GPT-6.1 Sol/high; actual routing
  is not exposed unless runtime tools report it.
- Parent: qualify production installer first, then test its exact generated
  uninstaller cleanup/data preservation, then release.
- Allowed: current runtime AGENTS, updater skill/architecture, installer contract,
  Inno source, receipt helper/producer and relevant tests/build gates. A separate
  new external inventory report is the only owned write.
- Forbidden: source/tests/contracts/docs edits, vendor/acquisition/acceptance,
  VM changes, executing Setup or an uninstaller, publication or gate approval.
- Parallel safe: read-only inventory during bounded native error verification;
  current installer source61c2 and receipt helperba21 are stable.

## Bounded question

Map the existing exact installation receipt and native uninstall ownership.
Determine which already implemented helpers can support removal of unchanged
owned runtime files without recursive parent deletion or loss of unknown/modified
files, user data, rollback targets, caches or shared prerequisites. Identify the
smallest missing consumer/hook and its actual trust/path/locking/receipt boundary.
Distinguish inspected behavior from unexecuted claims. Native Inno shell cleanup
alone does not prove helper-created runtime cleanup. Do not design a second
installer or generic deletion framework.

Return source references, existing reusable checks, concrete missing behavior,
required focused behavioral RED cases and eventual exact generated-uninstaller
acceptance checks. Any nonempty-folder, locked-file or invalid receipt outcome
must remain accurate. Root decides requirements/tests/implementation; no test of
the actual generated uninstaller precedes production installer qualification.

## Returned inventory and root reconciliation

Read-only agent `/root/uninstall_contract_inventory` returned
`D:/AutoClip-Inno-Migration/uninstall-inventory-d82b65729e414ebf8cc2be6def3431df.md`,
18049 bytes, SHA256
`94d8842e85f37d82c2748b60c779a982e31e644e8b91044367e490c383300131`.
Root read the complete report and verified its hash. Source61c2 and helperba21
were checked twice unchanged. The agent used file/source/hash inspection only;
it ran no behavior test or native Setup/uninstaller.

The existing COMPLETE receipt already inventories release files/directories,
source/marker/handoff, four native notices, generated uninstaller pair,
shortcuts and exact Registry64 registration. No uninstall consumer/hook exists.
Existing receipt and supervisor helpers are setup-temporary `dontcopy` inputs;
later cleanup therefore also needs durable authenticated code delivery. The
strict repair reader rejects any changed/unknown tree and is unsuitable as
the whole per-file cleanup decision. Holding its FileShare.Read streams forbids
deletion; releasing a stream before path deletion does not prove race safety.

Root accepts the bounded missing consumer/delivery/native-hook boundary. New
requirement decisions and focused behavioral RED must precede implementation.
Receipt/helper retirement, partial/locked/unknown/modified outcomes, native
modified registration/shortcut preservation and retained/app-referenced runtime
ownership require explicit scope. No generic recursive cleanup or replacement
receipt model is warranted. This planning inventory is not independent technical
approval and changes no readiness, legal, publication or lifecycle gate.
