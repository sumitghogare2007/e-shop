#!/bin/bash
set -e

echo "=== [Vercel Build] Current Directory ==="
pwd

echo "=== [Vercel Build] Installing / Checking Flutter SDK ==="
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Cloning Flutter stable SDK..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "=== [Vercel Build] Flutter Version ==="
flutter --version

echo "=== [Vercel Build] Configuring Flutter Web ==="
flutter config --enable-web --no-analytics

echo "=== [Vercel Build] Installing Dependencies ==="
flutter pub get

echo "=== [Vercel Build] Building Web Application ==="
flutter build web --release

echo "=== [Vercel Build] Verifying Output ==="
if [ -f "build/web/index.html" ]; then
  echo "SUCCESS: build/web/index.html exists!"
  ls -lh build/web
else
  echo "ERROR: build/web/index.html not found!"
  exit 1
fi

echo "=== [Vercel Build] Completed Successfully! ==="
