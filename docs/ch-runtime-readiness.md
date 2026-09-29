# CH application runtime readiness

2026-09-29. This is an unpublished source handoff. Public v40 ZIP, tag,
installer pin and `app-release.json` remain unchanged.

- AutoClip source commit: `388da710ed1a989bcdbabd424b50c315db0c8f2f`.
- Local wheel: `D:\AutoClip-CR09\ch-app-candidate\autoclip-0.1.0.dev0-py3-none-any.whl`;
  2,104,824 bytes; SHA-256
  `8fd93ede30ece052e7f9acb94284163dad37116a91a969d27c469ef6bd25eb3c`.
- The wheel contains its built frontend, Roboto font and OFL notice. Its base
  metadata declares `pillow<13,>=12.3`.
- The exact locally installed v40 CPU Python has no Pillow. Importing
  `autoclip.chat.assets` with that Python fails with `ModuleNotFoundError: No
  module named 'PIL'`. The current updater's isolated fixture now rejects this
  exact wheel against v40 as a missing runtime dependency without changing the
  active app. It also rejects a synthetic missing base dependency; the previous
  updater activated that wheel (RED).

The next releasable route needs a **new immutable runtime identity** with an
exact Windows Pillow wheel, publisher URL, size, SHA-256, notice/source and
component review evidence. Build the app wheel and runtime candidate together,
audit the manifest and member delta, qualify local CPU and applicable optional
NVIDIA paths, and review the changed material and runtime/app compatibility.
Publish and verify exact immutable assets before changing public pins; then
test the real update and rollback paths. Do not reinterpret v40 or list it as
compatible with this CH app wheel.

The public root commands stay at their documented locations. Release inputs
remain under `release/scripts`, `release/manifests`, and `release/review`.
