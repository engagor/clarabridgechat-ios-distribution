#!/bin/bash
set -e
set +u

# Clear Old XCFramework
rm -rf ./build/ClarabridgeChat.xcframework
rm -rf ./build/*.xcarchive

# Make a temporary directory, and delete it on exit/interrupt/terminate.
TMPDIR=$(mktemp -d /tmp/CLB.XXXXXXXXX)
trap "rm -rf ./tmp" 0 2 3 15

# Build the Archive
echo "Building Xcode Archive for Device..."
xcodebuild archive \
    -quiet \
    -scheme ClarabridgeChat \
    -destination "generic/platform=iOS" \
    -archivePath ./${TMPDIR}/build/ClarabridgeChat-iOS \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "Building Xcode Archive for Simulator..."
xcodebuild archive \
    -quiet \
    -scheme ClarabridgeChat \
    -destination "generic/platform=iOS Simulator" \
    -archivePath ./${TMPDIR}/build/ClarabridgeChat-simulator \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build the XCFramework
echo "Building XCFramework..."
xcodebuild -create-xcframework \
    -framework ./${TMPDIR}/build/ClarabridgeChat-iOS.xcarchive/Products/Library/Frameworks/ClarabridgeChat.framework \
    -framework ./${TMPDIR}/build/ClarabridgeChat-simulator.xcarchive/Products/Library/Frameworks/ClarabridgeChat.framework \
    -output ./build/ClarabridgeChat.xcframework

echo "✅ XCFramework built successfully."
