# Pillow 12.3.0 fribidi-shim

Pillow's exact wheel SBOM declares its `fribidi-shim` component as
`LGPL-2.1-or-later`. Pillow's build recipe compiles the shim into the
`PIL._imagingft` extension. This component is distinct from the FriBiDi DLL,
which is loaded separately when available and is not part of this wheel.

The exact Pillow 12.3.0 source archive delivered with AutoClip contains:

| Source member | SHA-256 |
| --- | --- |
| `pillow-12.3.0/src/thirdparty/fribidi-shim/fribidi.c` | `7e8cfa78dcd21cebeb0ad91c0cd23e0dba6496c0fbd66e1ec3d25c5b1b365d11` |
| `pillow-12.3.0/src/thirdparty/fribidi-shim/fribidi.h` | `1751c311ab8a3017e30cace05c48e08abe75a3597dd897c0f53d2dbee9293329` |

The full LGPL 2.1 text is delivered at
`notices-and-source/candidate-native-notices/FFmpeg-8.1.2-COPYING.LGPLv2.1`.
That file is a common license text; its filename describes an earlier FFmpeg
association. The Pillow source archive and this notice identify the shim
specifically.

This notice records the declared license and delivered source. It does not
establish that every applicable source, replacement, or relinking obligation
for this wheel has been fulfilled. That disposition remains open.
