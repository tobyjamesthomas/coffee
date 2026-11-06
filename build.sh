#!/bin/zsh
# Builds "Coffee.app" next to this script.
set -euo pipefail

cd "$(dirname "$0")"
APP="Coffee.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O main.swift -o "$APP/Contents/MacOS/Coffee"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Coffee</string>
    <key>CFBundleIdentifier</key><string>com.tobyjamesthomas.coffee</string>
    <key>CFBundleExecutable</key><string>Coffee</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

echo "Built $PWD/$APP"
