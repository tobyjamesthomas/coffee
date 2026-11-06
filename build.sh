#!/bin/zsh
# Builds Coffee.app next to this script.
#
# ARCHS sets which processors to build for (default: arm64, Apple Silicon).
# For a universal app, run: ARCHS="arm64 x86_64" ./build.sh
# Building x86_64 needs a toolchain that still ships Intel Swift libraries; the macOS 27 Command Line Tools do not.
set -euo pipefail

cd "$(dirname "$0")"
APP_NAME="Coffee.app"
VERSION="0.1"
MINIMUM_MACOS="11.0"
ARCHS=(${=ARCHS:-arm64})

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

# Assemble in the temporary folder so a failed build leaves any existing app untouched.
APP="$BUILD_DIR/$APP_NAME"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

slices=()
for arch in "${ARCHS[@]}"; do
    swiftc -O -target "$arch-apple-macos$MINIMUM_MACOS" main.swift -o "$BUILD_DIR/Coffee-$arch"
    slices+=("$BUILD_DIR/Coffee-$arch")
done
lipo -create "${slices[@]}" -output "$APP/Contents/MacOS/Coffee"

swift scripts/make-icon.swift "$BUILD_DIR/AppIcon.iconset"
iconutil -c icns "$BUILD_DIR/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Coffee</string>
    <key>CFBundleIdentifier</key><string>com.tobyjamesthomas.coffee</string>
    <key>CFBundleExecutable</key><string>Coffee</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>$MINIMUM_MACOS</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

# Ad hoc signature so the bundle is sealed; release builds will use a Developer ID instead.
codesign --force --sign - "$APP"

rm -rf "$APP_NAME"
mv "$APP" "$APP_NAME"
echo "Built $PWD/$APP_NAME for ${ARCHS[*]}"
