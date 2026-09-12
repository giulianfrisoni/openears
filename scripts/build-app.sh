#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
swift build -c release --scratch-path .build --cache-path .build/cache
APP="build/OpenEars.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/OpenEars "$APP/Contents/MacOS/"
cp -R .build/release/OpenEars_OpenEarsCore.bundle "$APP/Contents/Resources/"
cp scripts/Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources/Licenses"
cp LICENSE "$APP/Contents/Resources/Licenses/OpenEars-GPL-3.0.txt"
cp Vendor/SwiftNothingEar/LICENSE.md "$APP/Contents/Resources/Licenses/SwiftNothingEar-GPL-3.0.txt"
cp Vendor/SwiftNothingEar/UPSTREAM.md "$APP/Contents/Resources/Licenses/SwiftNothingEar-UPSTREAM.md"
cp -R Vendor/ProtocolReferences "$APP/Contents/Resources/Licenses/"
codesign --force --deep --sign - "$APP"
echo "Built $APP"
