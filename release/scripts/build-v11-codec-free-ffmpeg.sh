#!/usr/bin/env bash
# Run inside an MSYS2 shell after vcvars64.bat has set the MSVC environment.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: build_v11_codec_free_ffmpeg.sh /d/path/to/build-root" >&2
  exit 2
fi

build_root=$1
source_dir="$build_root/ffmpeg-8.1.2"
install_dir="$build_root/ffmpeg-install"

if ! command -v cl.exe >/dev/null; then
  echo "MSVC cl.exe is required; run from an x64 VS developer environment" >&2
  exit 2
fi
if ! command -v nasm.exe >/dev/null && ! command -v nasm >/dev/null; then
  echo "NASM is required" >&2
  exit 2
fi

cd "$source_dir"
./configure \
  --prefix="$install_dir" \
  --toolchain=msvc \
  --arch=x86_64 \
  --target-os=win64 \
  --enable-shared \
  --disable-static \
  --disable-gpl \
  --disable-nonfree \
  --disable-libx264 \
  --disable-libx265 \
  --disable-autodetect \
  --disable-programs \
  --disable-doc

cp ffbuild/config.log "$build_root/ffmpeg-config.log"
make -j "$(nproc)"
make install
cp "$install_dir"/bin/*.lib "$install_dir"/lib/
cp ffbuild/config.mak "$build_root/ffmpeg-config.mak"
cp config.h "$build_root/ffmpeg-config.h"
