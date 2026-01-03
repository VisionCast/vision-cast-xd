#!/bin/bash

# Verification script for VisionCast XD
# Validates code signing, notarization, and Gatekeeper compatibility

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Verifying VisionCast XD Distribution Package ===${NC}"

# Configuration
TARGET="${1:-./build/Vision Cast XD.app}"

# Determine if target is DMG or APP
if [[ "$TARGET" == *.dmg ]]; then
    IS_DMG=true
    DMG_PATH="$TARGET"
    MOUNT_POINT="/tmp/verify-visioncastxd-mount"
    
    # Mount DMG
    echo -e "${YELLOW}Mounting DMG...${NC}"
    if [ -d "$MOUNT_POINT" ]; then
        hdiutil detach "$MOUNT_POINT" 2>/dev/null || true
        rmdir "$MOUNT_POINT" 2>/dev/null || true
    fi
    
    mkdir -p "$MOUNT_POINT"
    hdiutil attach -mountpoint "$MOUNT_POINT" -nobrowse "$DMG_PATH" >/dev/null
    
    # Find the .app bundle
    APP_PATH=$(find "$MOUNT_POINT" -name "*.app" -maxdepth 1 -type d | head -n 1)
    
    if [ -z "$APP_PATH" ]; then
        echo -e "${RED}Error: Could not find .app bundle in DMG${NC}"
        hdiutil detach "$MOUNT_POINT"
        exit 1
    fi
else
    IS_DMG=false
    APP_PATH="$TARGET"
fi

# Validate inputs
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Application not found at $APP_PATH${NC}"
    echo "Usage: $0 [path-to-app-or-dmg]"
    echo "Example: $0 ./build/Vision\ Cast\ XD.app"
    echo "Example: $0 ./build/VisionCastXD.dmg"
    exit 1
fi

echo -e "${BLUE}Verifying: $APP_PATH${NC}"
echo ""

# Track verification results
ERRORS=0
WARNINGS=0

# 1. Code Signature Verification
echo -e "${YELLOW}[1/7] Verifying code signature...${NC}"
if codesign --verify --deep --strict "$APP_PATH" 2>/dev/null; then
    echo -e "${GREEN}  ✓ Code signature is valid${NC}"
    
    # Show signature details
    SIGNATURE_INFO=$(codesign --display --verbose=2 "$APP_PATH" 2>&1)
    echo "$SIGNATURE_INFO" | grep "Authority=" | head -n 1 | sed 's/^/  /'
    echo "$SIGNATURE_INFO" | grep "Identifier=" | sed 's/^/  /'
else
    echo -e "${RED}  ✗ Code signature verification failed${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 2. Check for hardened runtime
echo -e "${YELLOW}[2/7] Checking hardened runtime...${NC}"
if codesign --display --verbose "$APP_PATH" 2>&1 | grep -q "flags=.*runtime"; then
    echo -e "${GREEN}  ✓ Hardened runtime is enabled${NC}"
else
    echo -e "${YELLOW}  ⚠ Hardened runtime is not enabled${NC}"
    echo -e "    This is required for notarization"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 3. Check entitlements
echo -e "${YELLOW}[3/7] Checking entitlements...${NC}"
ENTITLEMENTS=$(codesign --display --entitlements - "$APP_PATH" 2>/dev/null)
if [ -n "$ENTITLEMENTS" ]; then
    echo -e "${GREEN}  ✓ Entitlements are present${NC}"
    
    # Check for sandbox
    if echo "$ENTITLEMENTS" | grep -q "com.apple.security.app-sandbox"; then
        echo -e "${YELLOW}  ⚠ App Sandbox is enabled${NC}"
        echo -e "    Note: Developer ID apps typically don't use sandbox"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}  ✓ App Sandbox is not enabled (correct for Developer ID)${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠ No entitlements found${NC}"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 4. Notarization status
echo -e "${YELLOW}[4/7] Checking notarization status...${NC}"
if xcrun stapler validate "$APP_PATH" 2>&1 | grep -q "The validate action worked"; then
    echo -e "${GREEN}  ✓ Notarization ticket is stapled${NC}"
else
    echo -e "${YELLOW}  ⚠ Notarization ticket is not stapled${NC}"
    echo -e "    The app may still be notarized, but stapling is recommended"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 5. Gatekeeper assessment
echo -e "${YELLOW}[5/7] Running Gatekeeper assessment...${NC}"
GATEKEEPER_OUTPUT=$(spctl --assess --verbose --type execute "$APP_PATH" 2>&1 || true)

if echo "$GATEKEEPER_OUTPUT" | grep -q "accepted"; then
    echo -e "${GREEN}  ✓ Gatekeeper will allow this application${NC}"
    echo "$GATEKEEPER_OUTPUT" | sed 's/^/  /'
elif echo "$GATEKEEPER_OUTPUT" | grep -q "rejected"; then
    echo -e "${RED}  ✗ Gatekeeper will block this application${NC}"
    echo "$GATEKEEPER_OUTPUT" | sed 's/^/  /'
    ERRORS=$((ERRORS + 1))
else
    echo -e "${YELLOW}  ⚠ Gatekeeper status unclear${NC}"
    echo "$GATEKEEPER_OUTPUT" | sed 's/^/  /'
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 6. Check for embedded libraries
echo -e "${YELLOW}[6/7] Checking embedded libraries...${NC}"
if [ -d "$APP_PATH/Contents/Frameworks" ]; then
    FRAMEWORK_COUNT=$(find "$APP_PATH/Contents/Frameworks" -type f \( -name "*.dylib" -o -name "*.framework" \) | wc -l | xargs)
    echo -e "${GREEN}  ✓ Found $FRAMEWORK_COUNT embedded libraries/frameworks${NC}"
    
    # Verify each framework is signed (use process substitution to avoid subshell)
    UNSIGNED_COUNT=0
    while read -r lib; do
        if ! codesign --verify "$lib" 2>/dev/null; then
            echo -e "${RED}    ✗ Unsigned: $(basename "$lib")${NC}"
            UNSIGNED_COUNT=$((UNSIGNED_COUNT + 1))
        fi
    done < <(find "$APP_PATH/Contents/Frameworks" -type f \( -name "*.dylib" -o -name "*.framework" \))
    
    if [ $UNSIGNED_COUNT -eq 0 ]; then
        echo -e "${GREEN}  ✓ All embedded libraries are signed${NC}"
    fi
else
    echo -e "  No embedded frameworks directory found"
fi
echo ""

# 7. Check DMG signature (if applicable)
if [ "$IS_DMG" = true ]; then
    echo -e "${YELLOW}[7/7] Checking DMG signature...${NC}"
    if codesign --verify --deep "$DMG_PATH" 2>/dev/null; then
        echo -e "${GREEN}  ✓ DMG is signed${NC}"
    else
        echo -e "${YELLOW}  ⚠ DMG is not signed${NC}"
        echo -e "    This is optional but recommended"
        WARNINGS=$((WARNINGS + 1))
    fi
    echo ""
    
    # Unmount DMG
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
    rmdir "$MOUNT_POINT" 2>/dev/null || true
else
    echo -e "${YELLOW}[7/7] DMG verification skipped (not a DMG)${NC}"
    echo ""
fi

# Summary
echo -e "${BLUE}=== Verification Summary ===${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo -e "${GREEN}The application is ready for distribution outside the Mac App Store.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Verification completed with $WARNINGS warning(s)${NC}"
    echo -e "${YELLOW}The application should work but may need adjustments for optimal distribution.${NC}"
    exit 0
else
    echo -e "${RED}✗ Verification failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo -e "${RED}Please fix the errors before distributing the application.${NC}"
    exit 1
fi
