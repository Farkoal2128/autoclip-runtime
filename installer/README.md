# Inno Setup draft

`AutoClip.iss` is a diagnostic draft. CPU is the default profile; NVIDIA is
optional and its hardware checks are deferred. Neither profile is qualified
for public installation. The guarded build refuses required `BLOCKED`
dependencies before invoking ISCC.

From the repository root, with the exact public v40 source archive and the
verified Inno Setup 7.1.0 `ISCC.exe`:

```powershell
python scripts/verify-installer-manifest.py --manifest release/manifests/installer-dependencies-v1.json --archive <v40.zip> --profile cpu
python scripts/build-inno.py --manifest release/manifests/installer-dependencies-v1.json --archive <v40.zip> --iscc <ISCC.exe> --output-dir <new-output-dir> --profile cpu
```

The second command currently exits `BLOCKED` for required unqualified inputs. A direct ISCC compile
is for diagnostic inspection only. `AutoClip-Setup-v1.exe /AUDIT /LOG=<log>`
extracts and hashes the declared embedded helpers, manifest and notices, then exits 1 before
installation. Run `tests/InstallerPreflight.Tests.ps1 -SetupExe <exe>` to
compare those hashes with the source. This check does not prove the complete
EXE payload inventory or installation behavior.

The Inno wizard invokes the pinned `run-source-build.ps1` helper with typed
JSON arguments. Native build output goes to protected full logs; the wizard
shows a bounded recent tail and remains responsive. Cancellation waits for
the current native command and prevents completion/activation. The actual
uninstaller cleanup test follows production installer qualification and must
pass before release; preserve user data and shared prerequisites.
