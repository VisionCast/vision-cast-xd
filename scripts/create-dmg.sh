#!/bin/bash

# DMG creation script for VisionCast XD
# Creates a distributable DMG with proper layout and signing

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Creating DMG for VisionCast XD ===${NC}"

# Configuration
APP_PATH="${1:-./build/Vision Cast XD.app}"
DMG_NAME="${2:-VisionCastXD}"
DMG_PATH="./build/$DMG_NAME.dmg"
TEMP_DMG_PATH="./build/$DMG_NAME-temp.dmg"
VOLUME_NAME="Vision Cast XD"
SIGNING_IDENTITY="${DEVELOPER_ID_IDENTITY:-Developer ID Application}"

# Get app version from Info.plist if available
if [ -f "$APP_PATH/Contents/Info.plist" ]; then
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "")
    if [ -n "$VERSION" ]; then
        DMG_PATH="./build/$DMG_NAME-$VERSION.dmg"
        TEMP_DMG_PATH="./build/$DMG_NAME-$VERSION-temp.dmg"
    fi
fi

# Validate inputs
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Application not found at $APP_PATH${NC}"
    echo "Usage: $0 [path-to-app] [dmg-name]"
    exit 1
fi

# Verify the app is signed and notarized
echo -e "${YELLOW}Verifying code signature...${NC}"
if ! codesign --verify --deep --strict "$APP_PATH" 2>/dev/null; then
    echo -e "${RED}Warning: Application is not properly signed${NC}"
    echo "It's recommended to sign with ./scripts/sign.sh first"
fi

echo -e "${YELLOW}Checking notarization...${NC}"
if ! xcrun stapler validate "$APP_PATH" 2>/dev/null; then
    echo -e "${YELLOW}Warning: Application is not notarized${NC}"
    echo "It's recommended to notarize with ./scripts/notarize.sh first"
fi

# Create a temporary directory for DMG contents
TEMP_DIR="./build/dmg-temp"
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi
mkdir -p "$TEMP_DIR"

# Copy the app to the temporary directory
echo -e "${YELLOW}Copying application to DMG staging area...${NC}"
cp -R "$APP_PATH" "$TEMP_DIR/"

# Create a symbolic link to /Applications
echo -e "${YELLOW}Creating Applications symlink...${NC}"
ln -s /Applications "$TEMP_DIR/Applications"

# Calculate the size needed for the DMG
echo -e "${YELLOW}Calculating DMG size...${NC}"
SIZE=$(du -sm "$TEMP_DIR" | cut -f1)
SIZE=$((SIZE + 50))  # Add some padding

# Create the temporary DMG
echo -e "${YELLOW}Creating temporary DMG...${NC}"
if [ -f "$TEMP_DMG_PATH" ]; then
    rm "$TEMP_DMG_PATH"
fi

hdiutil create -srcfolder "$TEMP_DIR" \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${SIZE}m \
    "$TEMP_DMG_PATH"

# Mount the temporary DMG
echo -e "${YELLOW}Mounting DMG for customization...${NC}"
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG_PATH" | grep -o '/Volumes/.*$')

# Wait for mount
sleep 2

# Customize the DMG appearance (if running with GUI)
if [ -n "$DISPLAY" ]; then
    echo -e "${YELLOW}Customizing DMG appearance...${NC}"
    
    # Set icon size and position (requires osascript)
    osascript <<EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 450}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set position of item "Vision Cast XD.app" of container window to {125, 150}
        set position of item "Applications" of container window to {375, 150}
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF
fi

# Unmount the temporary DMG
echo -e "${YELLOW}Unmounting DMG...${NC}"
hdiutil detach "$MOUNT_DIR"

# Convert to compressed, read-only DMG
echo -e "${YELLOW}Creating final compressed DMG...${NC}"
if [ -f "$DMG_PATH" ]; then
    rm "$DMG_PATH"
fi

hdiutil convert "$TEMP_DMG_PATH" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH"

# Clean up
rm "$TEMP_DMG_PATH"
rm -rf "$TEMP_DIR"

# Sign the DMG
echo -e "${YELLOW}Signing DMG...${NC}"
codesign --sign "$SIGNING_IDENTITY" \
    --timestamp \
    "$DMG_PATH" 2>/dev/null || echo -e "${YELLOW}Note: DMG signing skipped (requires Developer ID)${NC}"

# Verify DMG
echo -e "${YELLOW}Verifying DMG...${NC}"
hdiutil verify "$DMG_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ DMG created successfully: $DMG_PATH${NC}"
    
    # Display DMG info
    ls -lh "$DMG_PATH"
    
    echo -e "${YELLOW}Next step: Verify with ./scripts/verify.sh${NC}"
else
    echo -e "${RED}✗ DMG verification failed${NC}"
    exit 1
fi
