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
