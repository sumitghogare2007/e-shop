#!/bin/bash
set -e

echo "=== [Vercel Root Build] Current Directory ==="
pwd

echo "=== [Vercel Root Build] Installing / Checking Flutter SDK ==="
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Cloning Flutter stable SDK..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "=== [Vercel Root Build] Flutter Version ==="
flutter --version

echo "=== [Vercel Root Build] Configuring Flutter Web ==="
flutter config --enable-web --no-analytics

echo "=== [Vercel Root Build] Entering mobile-app directory ==="
cd mobile-app

echo "=== [Vercel Root Build] Installing Dependencies ==="
flutter pub get

echo "=== [Vercel Root Build] Building Web Application ==="
flutter build web --release

echo "=== [Vercel Root Build] Verifying Output ==="
if [ -f "build/web/index.html" ]; then
  echo "SUCCESS: mobile-app/build/web/index.html exists!"
  ls -lh build/web
else
  echo "ERROR: mobile-app/build/web/index.html not found!"
  exit 1
fi

echo "=== [Vercel Root Build] Completed Successfully! ==="
