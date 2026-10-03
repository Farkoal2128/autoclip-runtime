# IM-VC-02: manifest-bound VC runtime preparation helper

- Parent: production Inno installer first, then generated-uninstaller acceptance,
  then authorized release. NVIDIA hardware tests deferred.
- Authorization: implementation/TDD of contract's Microsoft runtime preparation.
- Role: implementer, configured GPT-6.1 Sol/medium; actual routing not exposed.
- Own only NEW `installer/install-vc-runtime.ps1`, NEW
  `tests/InstallerVcRuntime.Tests.ps1`, and one NEW external report.
- Root owns contract/ISS/compiler binding/bootstrap and all other files. You are
  not alone: Python handoff agent owns ISS/tests; don't revert any other edits.
- Read exact objective attachment, AGENTS/updater skill/architecture, contract,
  manifest's `microsoft_vc_redist_x64` row, Python/tool/source storage patterns.

## Bounded deliverable

One first-party helper, no new package/plugin/generic framework or acquisition.
Expose mandatory ManifestPath/ManifestSha256/StateDirectory, CheckOnly and an
install mode with InstallerPath plus explicit AcceptMicrosoftTerms. CheckOnly
checks pending boot state before system DLL capability; no artifact execution,
consent default, download or system mutation. Read the reviewed identity/args
from the setup-bound manifest; do not independently maintain artifact URLs/pins.
Internal result JSON/exit codes must clearly distinguish ready0, missing2,
pending3010, UAC/vendor cancellation, failure and unresolved interrupted state.
Root will integrate this helper in the wizard after your files are frozen.

Follow the new contract section: signed exact vendor input, ordinary helper,
actual vendor UI, `/install /norestart`, serialized attempts, same-input locks,
protected recipient state, persist in-progress before launch and pending3010
without early capability reuse. Same-boot unresolved interruption preserves and
refuses; after reboot recheck capability before retiring only owned state.
Wait for any owned vendor child through observation/cleanup errors; never kill
it, restart it solely on timeout, or report rollback of shared vendor changes.
Fixed system DLL identities/version/signature/PE x64/loader probe are required;
full CTranslate2/app inference is a separate later gate. Existing compatible
versions should avoid new acquisition/consent/install. Preserve foreign records.

Reuse existing plain PowerShell/.NET/native Windows patterns. Do not add a
production test-only URL, verifier bypass, process callback or fake clock switch.
Tests may AST-load actual functions or make explicitly adapted temporary copies
at native system/signature/clock/process boundaries; never mock result handling,
state publication, pending detection or the decision being tested. Use real
first-party files, protected ACLs and ordinary-user child processes for locking.

## Proof and restrictions

Meaningful RED before helper exists/behavior changes; GREEN for actual state and
decision flow. Cover pending result followed by a fresh same-boot invocation,
post-reboot fresh capability, decline/no launch, bad pins/signature/publisher,
vendor failure/UAC, changed/foreign state and actual concurrent-attempt exclusion.
Keep tests bounded; stop expanding once actual risks above are covered.

ONLY inert host PowerShell tests/parser. NO real vendor execution or DLL loading,
VM, actual Setup/uninstaller, vendor acquisition/download/preparation command,
agreement acceptance, real installed/user data, trust/policy/clock change,
dependency promotion, commit/push or release. Prior automatic review rejection
of fresh VM acquisition preparation (`blocked by policy`) must not be retried,
encoded or bypassed. Existing VM-only Microsoft consent is not host-test consent.

Return exact API/result schema, RED/GREEN commands, real test boundaries and
limits, files/hashes/diff and frozen external report. Do not call this production
qualification or blind independent review. Flag any requirement conflict.
