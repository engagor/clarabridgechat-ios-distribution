#!/bin/bash
set -e
set +u

# Clean previous build.
rm -rf ./build/ClarabridgeChat.framework
rm -rf ./build/ClarabridgeChat.framework.dSYM

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

echo "Building Xcode Archive for Simulator (without arm64)..."
xcodebuild archive \
    -quiet \
    -scheme ClarabridgeChat \
    -destination "generic/platform=iOS Simulator" \
    -archivePath ./${TMPDIR}/build/ClarabridgeChat-simulator \
    EXCLUDED_ARCHS="arm64" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build the XCFramework
echo "Building XCFramework (without arm64 simulator)..."
xcodebuild -create-xcframework \
    -framework ./${TMPDIR}/build/ClarabridgeChat-iOS.xcarchive/Products/Library/Frameworks/ClarabridgeChat.framework \
    -framework ./${TMPDIR}/build/ClarabridgeChat-simulator.xcarchive/Products/Library/Frameworks/ClarabridgeChat.framework \
    -output ./${TMPDIR}/build/ClarabridgeChat.xcframework

echo "✅ XCFramework built successfully."

PROJECT_NAME="ClarabridgeChat"
SCHEME="ClarabridgeChat"
XCFRAMEWORK="./${TMPDIR}/build/ClarabridgeChat.xcframework"
RELEASE_DIRECTORY="./build"

echo "💼 Building Fat Framework..."
BINARY_FRAMEWORK=${PROJECT_NAME}.framework
BINARY_FRAMEWORK_PATH=${PROJECT_NAME}.framework/${PROJECT_NAME}

FRAMEWORK_SIMULATOR_DIR_NAME=$(ls $XCFRAMEWORK/ | grep simulator)
SIMULATOR_FRAMEWORK="${XCFRAMEWORK}/${FRAMEWORK_SIMULATOR_DIR_NAME}/${BINARY_FRAMEWORK}"

FRAMEWORK_DEVICE_DIR_NAME=$(ls $XCFRAMEWORK/ | grep armv7)
DEVICE_FRAMEWORK="${XCFRAMEWORK}/${FRAMEWORK_DEVICE_DIR_NAME}/${BINARY_FRAMEWORK}"

# Copy framework to Release directory
echo "Copying device binary to release directory..."
cp -R ${DEVICE_FRAMEWORK} ${RELEASE_DIRECTORY}

FAT_FRAMEWORK=${RELEASE_DIRECTORY}/${BINARY_FRAMEWORK}

# Create Fat Framework
echo "Creating Fat Framework..."
lipo -create \
    "${SIMULATOR_FRAMEWORK}/${PROJECT_NAME}" \
    "${DEVICE_FRAMEWORK}/${PROJECT_NAME}" \
    -output "${FAT_FRAMEWORK}/${PROJECT_NAME}"

# Create dSYMs for Fat Framework
echo "Linking dSYMs for Fat Framework..."
mkdir -p "${RELEASE_DIRECTORY}/${PROJECT_NAME}.framework.dSYM/Contents/Resources/DWARF"
lipo -create \
    "./${TMPDIR}/build/${PROJECT_NAME}-iOS.xcarchive/dSYMs/${PROJECT_NAME}.framework.dSYM/Contents/Resources/DWARF/${PROJECT_NAME}" \
    "./${TMPDIR}/build/${PROJECT_NAME}-simulator.xcarchive/dSYMs/${PROJECT_NAME}.framework.dSYM/Contents/Resources/DWARF/${PROJECT_NAME}" \
     -output "${RELEASE_DIRECTORY}/${PROJECT_NAME}.framework.dSYM/Contents/Resources/DWARF/${PROJECT_NAME}"

echo "✅ ClarabridgeChat.framework built successfully in: ${RELEASE_DIRECTORY}."

exit 0
