#!/bin/bash
# Script to perform a clean build and run the app with diagnostic output
# Usage: ./scripts/clean_build_and_test.sh

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "========================================="
echo "Clean Build and Test Script"
echo "========================================="
echo ""

# Step 1: Clean build folder
echo "[1/5] Cleaning build folder..."
if xcodebuild clean -project DownloadFullInstaller.xcodeproj -scheme DownloadFullInstaller -quiet; then
    echo "✓ Build folder cleaned"
else
    echo "✗ Failed to clean build folder"
    exit 1
fi
echo ""

# Step 2: Clean derived data
echo "[2/5] Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/DownloadFullInstaller-*
echo "✓ Derived data cleaned"
echo ""

# Step 3: Build
echo "[3/5] Building project..."
echo "  (This may take a minute...)"
if xcodebuild -project DownloadFullInstaller.xcodeproj \
    -scheme DownloadFullInstaller \
    -configuration Debug \
    build \
    CODE_SIGN_IDENTITY="-" > /tmp/build_output.txt 2>&1; then
    echo "✓ Build completed successfully"
else
    echo "✗ Build failed. Showing last 20 lines of output:"
    echo ""
    tail -20 /tmp/build_output.txt
    echo ""
    echo "Full build output saved to: /tmp/build_output.txt"
    exit 1
fi
echo ""

# Step 4: Find the built app
echo "[4/5] Locating built application..."
BUILD_DIR=$(xcodebuild -project DownloadFullInstaller.xcodeproj -scheme DownloadFullInstaller -configuration Debug -showBuildSettings 2>/dev/null | grep " BUILD_DIR " | sed 's/.*= //')
APP_PATH="$BUILD_DIR/Debug/Download Full Installer.app"

if [ ! -d "$APP_PATH" ]; then
    echo "✗ Application not found at: $APP_PATH"
    echo "Please check build errors above"
    exit 1
fi
echo "✓ Application found at: $APP_PATH"
echo ""

# Step 5: Verify entitlements
echo "[5/5] Verifying entitlements..."
if codesign -d --entitlements - "$APP_PATH" 2>/dev/null; then
    echo ""
    echo "✓ Entitlements verified"
else
    echo "⚠  Warning: Could not verify entitlements (app may not be signed yet)"
    echo "   This is normal for debug builds without code signing"
    echo "   The app should still run on your local machine"
fi
echo ""

echo "========================================="
echo "Build Complete!"
echo "========================================="
echo ""
echo 
