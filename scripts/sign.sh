#!/bin/bash

# Code signing script for VisionCast XD with Developer ID
# Signs the application bundle and all embedded frameworks

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Signing VisionCast XD with Developer ID ===${NC}"

# Configuration
APP_PATH="${1:-./build/Vision Cast XD.app}"
ENTITLEMENTS_PATH="./VisionCastXD/VisionCastXD-DeveloperID.entitlements"
SIGNING_IDENTITY="${DEVELOPER_ID_IDENTITY:-Developer ID Application}"

# Validate inputs
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Application not found at $APP_PATH${NC}"
    echo "Usage: $0 [path-to-app]"
    echo "Example: $0 ./build/Vision\ Cast\ XD.app"
    exit 1
fi

if [ ! -f "$ENTITLEMENTS_PATH" ]; then
    echo -e "${RED}Error: Entitlements file not found at $ENTITLEMENTS_PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}App Path: $APP_PATH${NC}"
echo -e "${YELLOW}Entitlements: $ENTITLEMENTS_PATH${NC}"
echo -e "${YELLOW}Signing Identity: $SIGNING_IDENTITY${NC}"

# Function to sign a file
sign_file() {
    local file="$1"
    echo -e "${YELLOW}Signing: $(basename "$file")${NC}"
    
    codesign --force \
        --sign "$SIGNING_IDENTITY" \
        --entitlements "$ENTITLEMENTS_PATH" \
        --options runtime \
        --timestamp \
        --verbose \
        "$file"
}

# Remove any existing signatures
echo -e "${YELLOW}Removing existing signatures...${NC}"
codesign --remove-signature "$APP_PATH" 2>/dev/null || true

# Sign embedded frameworks and libraries first (deep signing)
echo -e "${YELLOW}Signing embedded frameworks and libraries...${NC}"
if [ -d "$APP_PATH/Contents/Frameworks" ]; then
    find "$APP_PATH/Contents/Frameworks" -type f \( -name "*.dylib" -o -name "*.framework" \) | while read -r file; do
        sign_file "$file"
    done
fi

# Sign any embedded helper tools or executables
if [ -d "$APP_PATH/Contents/MacOS" ]; then
    find "$APP_PATH/Contents/MacOS" -type f -perm +111 ! -name "$(basename "$APP_PATH" .app)" | while read -r file; do
        sign_file "$file"
    done
fi

# Sign the main application bundle
echo -e "${YELLOW}Signing main application bundle...${NC}"
codesign --force \
    --sign "$SIGNING_IDENTITY" \
    --entitlements "$ENTITLEMENTS_PATH" \
    --options runtime \
    --timestamp \
    --deep \
    --verbose \
    "$APP_PATH"

# Verify the signature
echo -e "${YELLOW}Verifying signature...${NC}"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Application signed successfully${NC}"
    
    # Display signature details
    echo -e "${YELLOW}Signature details:${NC}"
    codesign --display --verbose=4 "$APP_PATH" 2>&1
    
    echo -e "${GREEN}Next step: Notarize with ./scripts/notarize.sh${NC}"
else
    echo -e "${RED}✗ Signature verification failed${NC}"
    exit 1
fi
