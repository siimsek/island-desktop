#!/usr/bin/env bash
# Builds the two KWin effects against the KWin installed on THIS machine.
# (Prebuilt packages break whenever KWin's minor version changes.)
set -euo pipefail
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
build() { # name url
  git clone --depth=1 "$2" "$WORK/$1"
  cmake -S "$WORK/$1" -B "$WORK/$1/build" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
  cmake --build "$WORK/$1/build" -j"$(nproc)"
  sudo cmake --install "$WORK/$1/build"
}
if command -v paru >/dev/null; then
  paru -S --needed kwin-effect-rounded-corners-git kwin-effects-better-blur-dx
else
  build rounded https://github.com/matinlotfali/KDE-Rounded-Corners.git
  build blur    https://github.com/xarblu/kwin-effects-better-blur-dx.git
fi
