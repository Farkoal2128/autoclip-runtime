# IM-UN-03: native cleanup and activation race decision

## Assignment

- Parent and order: production installer qualification, then exact generated
  uninstaller qualification, then release; NVIDIA hardware tests deferred.
- Authorization: read-only contract reasoning. No implementation or execution.
- Preferred role: contract_reviewer, GPT-6.1 Sol/high; actual routing not exposed.
- Own one new external decision report only. Do not edit any repository files.
- Not alone: root owns contracts/native integration; IM-UN-02 separately owns
  only the new internal file removal helper and its inert fixture tests.
- Governing sources: AGENTS, updater skill/architecture, installer contract,
  IM-UN-01 inventory, current Inno/receipt/supervisor and both updater scripts.

## Bounded unresolved boundary

The inspected updater activation paths currently do not use the source-worker
target lock. An uninstall snapshot of absent/unrelated active.json/app-active.json
therefore does not prevent later activation of its target during deletion.
Determine the minimum safe integration that preserves retained/app-referenced
runtime ownership, without a general deletion framework or new dependency.
Identify whether existing native Windows file/parent handles alone can serialize
the actual updater writers, or a narrowly shared cooperative selection lock is
required; specify exact producers/consumers and focused behavioral RED needed.

Also reconcile native ownership: official Inno Abort documentation explicitly
allows termination from CurUninstallStepChanged(usUninstall). Determine minimal
read-only initialization, post-confirmation cleanup, failure/partial retry and
native teardown sequencing. Four notices and Start Menu icon currently undergo
automatic removal; modified versions must remain preserved. Durable authenticated
helper/receipt retirement and multiple receipts/upgrades need a concrete bounded
decision. Do not pretend current temporary dontcopy helpers are durable.

Use official primary docs/source only for uncertain native event behavior and
cite exact links. File/source/hash reads and browser research only. No binaries,
tests, Setup/uninstaller, VM, vendor, acquisition/agreements, policy/trust/clock,
release/publication, repository writes or technical gate closure.

Return a short exact recommended contract decision, affected files/callers,
test-first implementation order, unresolved facts and limits. No redesign of
application updates, new receipt schema, recursive cleanup or root migration
unless evidence establishes an unavoidable need. This is planning evidence,
not blind technical approval or qualification of any actual uninstaller.

## Returned read-only decision

Report `D:/AutoClip-Inno-Migration/uninstall-decision-e938f89ee2e04685b0bd269c5f25c40d.md`,
18363 bytes, SHA256
`50b59b9e9c78eaa8c0ea22195db100787be3fdd2aa1ce972f4b4980802a75327`.
Root read the complete report. It recommends a per-base shared selection lock
across updater transactions and cleanup, selection-before-target ordering,
single immutable receipt refusal, post-confirmation usUninstall cleanup/Abort,
conditional notices/icon ownership and durable authenticated delivery.

Versioned official Inno source shows DAT held exclusively before initialization,
and late usPostUninstall exceptions handled after native teardown. Generic row
rehashing cannot read that DAT while running; exact pre-launch/native lifetime
ownership and post-native retirement reporting require deliberate contract work
and actual acceptance. Native CRC is not cryptographic receipt-pin validation.
Mixed legacy/cooperative updater concurrency remains outside the proposed lock's
guarantee. Root records these facts and unresolved choices without waiving current
requirements or approving the proposed exception, identity renewal or retirement.

No code, tests, native binaries, VM or gate changes were produced. IM-UN-02's later
ADS preservation RED supersedes this report's parent-reported isolated GREEN.
