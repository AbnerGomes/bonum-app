#!/usr/bin/env bash
# Build da versão web no Render (o ambiente do Render não tem Flutter).
# Usa a MESMA versão do container (Dockerfile), para web e APK saírem iguais.
set -euo pipefail

FLUTTER_VERSION="3.44.0"
FLUTTER_DIR="$HOME/flutter-$FLUTTER_VERSION"

# Clona a tag (não a branch): assim o Flutter sabe a própria versão.
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --no-analytics --enable-web
flutter --version
flutter pub get
flutter build web --release
