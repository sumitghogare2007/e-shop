#!/bin/bash
set -e

echo "=== [Vercel Admin Build] Current Working Directory ==="
pwd

echo "=== [Vercel Admin Build] Installing / Verifying Flutter SDK ==="
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Cloning Flutter stable SDK into $FLUTTER_DIR..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "=== [Vercel Admin Build] Flutter Version ==="
flutter --version

echo "=== [Vercel Admin Build] Enabling Flutter Web ==="
flutter config --enable-web --no-analytics

echo "=== [Vercel Admin Build] Fetching Dependencies ==="
flutter pub get

echo "=== [Vercel Admin Build] Building Release Web Bundle ==="
flutter build web --release

echo "=== [Vercel Admin Build] Verifying Build Output ==="
if [ -f "build/web/index.html" ]; then
  echo "SUCCESS: build/web/index.html created successfully!"
  ls -lh build/web
else
  echo "ERROR: build/web/index.html not found!"
  exit 1
fi

echo "=== [Vercel Admin Build] Completed Successfully! ==="
