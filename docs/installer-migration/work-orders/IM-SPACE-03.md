# IM-SPACE-03: retire obsolete AT01 work folder

User explicitly requested removal of `D:/AutoClip-AT01` on 2026-10-02.
Read-only specialist inventory and root checks found no active executable or
registered VM dependency in that folder. Its measured file inventory was
404,276 files / 48,206,542,461 bytes; this is logical size, not measured recovery.

The current r7 objective packet already preserves its exact r18 base ZIP at
`D:/Projects/autoclip-runtime-evidence/IM-DEP-13-cpu-candidate-r7-objective-r2/candidate/base-candidate-r18.zip`.
Root freshly verified SHA-256
`31414e7b25beb51f03f809f12d8be713bc6385ce155067d077d69267c770c8e8`.

Root used native `git worktree move` to retain the clean source replay and
historical app worktrees under
`D:/Projects/autoclip-runtime-evidence/retired-AT01-20261002/`.
The replay remains at commit `ddee4ef42aa4bf2076c81a939d225c5bbdb397d4`.
Also retained 136 small original review records (46,086,306 bytes), checking
every copied file's size and SHA-256. Immutable historical origins were not
rewritten. `retained-records.json` maps the copies.

Automatic approval review rejected the bounded native PowerShell removal
command with only `blocked by policy`. It did not run: the original folder,
its junctions and other contents remain; no reclaimed-space claim is made.
`cleanup-status.json` records this state, SHA-256
`c2193a9829ad9a604a09e0f7b4e4fab0e5c8c93b4ea8929aee9e46e3131c341e`.

Separately, the approved old r2/r3 VM was unregistered using native no-delete
unregister. The five approved disk/RAM files remain because their removal
command was also rejected. The retained shared parent disk remains accessible.
Current r7 is paused at its actual installation failure; logs still require
inspection. No application completion, actual uninstall or release is claimed.
