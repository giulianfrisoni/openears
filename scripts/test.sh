#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
# Some Command Line Tools releases omit automatic discovery of TestingMacros.
TOOLCHAIN_ROOT="$(xcode-select -p)"
TESTING_PLUGIN="$TOOLCHAIN_ROOT/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
if [ -f "$TESTING_PLUGIN" ]; then
    swift test --cache-path .build/cache -Xswiftc -load-plugin-library -Xswiftc "$TESTING_PLUGIN"
else
    swift test --cache-path .build/cache
fi
