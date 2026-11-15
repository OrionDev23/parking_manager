
#!/usr/bin/env bash
set -euo pipefail

echo "Installing Flutter stable..."

FLUTTER_DIR="/tmp/flutter-sdk"

git clone --depth 1 --branch stable \
  https://github.com/flutter/flutter.git \
  "$FLUTTER_DIR"

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "Enabling Web..."
flutter config --enable-web

echo "Installing dependencies..."
flutter pub get

echo "Building Parcoto Web..."
flutter build web --release

echo "Build completed successfully."
