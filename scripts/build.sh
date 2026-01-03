#!/bin/bash

# Build script for VisionCast XD with Developer ID signing
# This script builds the app with proper settings for Developer ID distribution

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Building VisionCast XD for Developer ID Distribution ===${NC}"

# Configuration
PROJECT_NAME="VisionCastXD"
SCHEME="VisionCastXD"
CONFIGURATION="Release"
BUILD_DIR="./build"
DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"

# Check if we're in the right directory
if [ ! -f "$PROJECT_NAME.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}Error: $PROJECT_NAME.xcodeproj not found in current directory${NC}"
    echo "Please run this script from the repository root"
    exit 1
fi

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR"

# Build the application
echo -e "${YELLOW}Building application...${NC}"
xcodebuild clean build \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE="Manual" \
    DEVELOPMENT_TEAM="" \
    CODE_SIGNING_ALLOWED="NO" \
    | tee "$BUILD_DIR/build.log"

# Check if build succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful${NC}"
    
    # Find and copy the built app
    APP_PATH=$(find "$DERIVED_DATA_PATH" -name "*.app" -type d | head -n 1)
    if [ -n "$APP_PATH" ]; then
        APP_NAME=$(basename "$APP_PATH")
        cp -R "$APP_PATH" "$BUILD_DIR/"
        echo -e "${GREEN}✓ Application copied to: $BUILD_DIR/$APP_NAME${NC}"
        echo -e "${YELLOW}Next steps:${NC}"
        echo "  1. Sign the app with: ./scripts/sign.sh"
        echo "  2. Notarize with: ./scripts/notarize.sh"
        echo "  3. Create DMG with: ./scripts/create-dmg.sh"
    else
        echo -e "${RED}Error: Could not find built application${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Build failed. Check $BUILD_DIR/build.log for details${NC}"
    exit 1
fi
