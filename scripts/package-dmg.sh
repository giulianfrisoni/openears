#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' scripts/Info.plist)
ARCH=$(uname -m)
APP="build/OpenEars.app"
STAGE="build/dmg-root"
DMG="build/OpenEars-${VERSION}-macOS-${ARCH}-preview.dmg"

sh scripts/build-app.sh
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
cp LICENSE "$STAGE/LICENSE.txt"
cp ACKNOWLEDGMENTS.md "$STAGE/ACKNOWLEDGMENTS.md"
cp docs/COMPATIBILITY.md "$STAGE/COMPATIBILITY.md"

hdiutil create \
  -volname "OpenEars ${VERSION} Preview" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG"

codesign --verify --deep --strict "$APP"
hdiutil verify "$DMG"
shasum -a 256 "$DMG" > "$DMG.sha256"

echo "Packaged $DMG"
echo "Checksum: $DMG.sha256"
