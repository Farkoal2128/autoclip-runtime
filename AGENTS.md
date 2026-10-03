# Repository agent instructions

This repository publishes the Windows AutoClip installer, updater, and release
assets. Before changing `install.ps1`, `update.ps1`, launchers, manifests,
runtime dependencies, packaging, GitHub releases, or rollback behavior, read
[the runtime updater skill](skills/runtime-updater/SKILL.md). Its architecture
and release-order rules apply to those changes.

For a behavior change, define the intended contract, demonstrate a focused
failing test, implement the change, then run the repository checks and an
applicable installed-release smoke test. Keep user projects and settings
outside managed runtime cleanup. Do not mark an unpublished asset or an
untested platform as verified.

For the Inno Setup migration only, a blinded same-session sub-agent review may
satisfy an independent **technical** review gate. The reviewer must not have
designed, implemented, or debugged the candidate, and must start with fresh
context, without producer conversation, rationale, or a requested verdict.
Freeze the candidate during review. Supply the objective requirements,
applicable contracts and policies, immutable source and binary snapshot,
exact source/setup/artifact/dependency-manifest hashes, and primary evidence;
provide a clean test environment when available. The reviewer must perform
independent checks, not merely adopt producer logs, and write a separate
verdict with scope, hashes, checks, findings, limits, and disposition. A
blocking finding ends review of that snapshot; fix, rehash, and re-review the
changed candidate. Call this a `blinded same-session sub-agent review`, not
external human review or legal opinion. It does not waive human/legal gates,
authorize publication, or broaden historical approvals. If fresh context or
an immutable snapshot is unavailable, this exception cannot be used.
