#!/bin/bash

# Notarization script for VisionCast XD using notarytool
# Submits the app to Apple's notarization service and waits for completion

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Notarizing VisionCast XD with notarytool ===${NC}"

# Configuration
APP_PATH="${1:-./build/Vision Cast XD.app}"
ZIP_PATH="${2:-./build/VisionCastXD-notarization.zip}"
APPLE_ID="${NOTARIZATION_APPLE_ID}"
TEAM_ID="${NOTARIZATION_TEAM_ID}"
PASSWORD="${NOTARIZATION_PASSWORD}"  # App-specific password
KEYCHAIN_PROFILE="${NOTARIZATION_KEYCHAIN_PROFILE:-notarytool-profile}"

# Validate inputs
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Application not found at $APP_PATH${NC}"
    echo "Usage: $0 [path-to-app] [path-to-zip]"
    exit 1
fi

# Check if credentials are available
if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$PASSWORD" ]; then
    echo -e "${YELLOW}Note: Notarization credentials not set in environment${NC}"
    echo -e "${YELLOW}You can either:${NC}"
    echo "  1. Set environment variables:"
    echo "     export NOTARIZATION_APPLE_ID='your-apple-id@example.com'"
    echo "     export NOTARIZATION_TEAM_ID='YOUR_TEAM_ID'"
    echo "     export NOTARIZATION_PASSWORD='your-app-specific-password'"
    echo ""
    echo "  2. Store credentials in keychain (recommended):"
    echo "     xcrun notarytool store-credentials $KEYCHAIN_PROFILE \\"
    echo "       --apple-id 'your-apple-id@example.com' \\"
    echo "       --team-id 'YOUR_TEAM_ID' \\"
    echo "       --password 'your-app-specific-password'"
    echo ""
    
    # Check if keychain profile exists
    if xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Found keychain profile: $KEYCHAIN_PROFILE${NC}"
        USE_KEYCHAIN_PROFILE=true
    else
        echo -e "${RED}Error: No credentials available${NC}"
        exit 1
    fi
else
    USE_KEYCHAIN_PROFILE=false
fi

# Verify the app is signed
echo -e "${YELLOW}Verifying code signature...${NC}"
if ! codesign --verify --deep --strict "$APP_PATH" 2>/dev/null; then
    echo -e "${RED}Error: Application is not properly signed${NC}"
    echo "Please run ./scripts/sign.sh first"
    exit 1
fi
echo -e "${GREEN}✓ Code signature verified${NC}"

# Create a zip archive for notarization
echo -e "${YELLOW}Creating notarization archive...${NC}"
if [ -f "$ZIP_PATH" ]; then
    rm "$ZIP_PATH"
fi

# Use ditto to create a signed archive that preserves code signatures
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo -e "${GREEN}✓ Archive created: $ZIP_PATH${NC}"

# Submit for notarization
echo -e "${YELLOW}Submitting for notarization...${NC}"
if [ "$USE_KEYCHAIN_PROFILE" = true ]; then
    SUBMISSION_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait 2>&1)
else
    SUBMISSION_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$PASSWORD" \
        --wait 2>&1)
fi

echo "$SUBMISSION_OUTPUT"

# Extract submission ID
SUBMISSION_ID=$(echo "$SUBMISSION_OUTPUT" | grep -o 'id: [a-z0-9\-]*' | head -1 | cut -d' ' -f2)

# Check if notarization succeeded
if echo "$SUBMISSION_OUTPUT" | grep -q "status: Accepted"; then
    echo -e "${GREEN}✓ Notarization successful!${NC}"
    
    # Staple the notarization ticket
    echo -e "${YELLOW}Stapling notarization ticket...${NC}"
    xcrun stapler staple "$APP_PATH"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Notarization ticket stapled successfully${NC}"
        
        # Verify stapling
        echo -e "${YELLOW}Verifying stapled ticket...${NC}"
        xcrun stapler validate "$APP_PATH"
        
        echo -e "${GREEN}✓ Notarization complete!${NC}"
        echo -e "${YELLOW}Next step: Create DMG with ./scripts/create-dmg.sh${NC}"
    else
        echo -e "${RED}✗ Failed to staple notarization ticket${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Notarization failed${NC}"
    
    if [ -n "$SUBMISSION_ID" ]; then
        echo -e "${YELLOW}Fetching notarization log...${NC}"
        if [ "$USE_KEYCHAIN_PROFILE" = true ]; then
            xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "$KEYCHAIN_PROFILE"
        else
            xcrun notarytool log "$SUBMISSION_ID" \
                --apple-id "$APPLE_ID" \
                --team-id "$TEAM_ID" \
                --password "$PASSWORD"
        fi
    fi
    exit 1
fi

# Clean up zip file (optional)
# rm "$ZIP_PATH"
