#!/bin/bash

# Master build script for VisionCast XD distribution
# Runs all build, sign, notarize, and package steps

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  VisionCast XD - Complete Distribution Build Pipeline    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "VisionCastXD.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}Error: Must run from repository root${NC}"
    exit 1
fi

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check for required tools
MISSING_TOOLS=0

if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}  ✗ xcodebuild not found${NC}"
    MISSING_TOOLS=$((MISSING_TOOLS + 1))
else
    echo -e "${GREEN}  ✓ xcodebuild found${NC}"
fi

if ! command -v codesign &> /dev/null; then
    echo -e "${RED}  ✗ codesign not found${NC}"
    MISSING_TOOLS=$((MISSING_TOOLS + 1))
else
    echo -e "${GREEN}  ✓ codesign found${NC}"
fi

if ! command -v xcrun &> /dev/null; then
    echo -e "${RED}  ✗ xcrun not found${NC}"
    MISSING_TOOLS=$((MISSING_TOOLS + 1))
else
    echo -e "${GREEN}  ✓ xcrun found${NC}"
fi

if [ $MISSING_TOOLS -gt 0 ]; then
    echo -e "${RED}Missing required tools. Please install Xcode and command line tools.${NC}"
    exit 1
fi

# Check for Developer ID certificate
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo -e "${YELLOW}  ⚠ No Developer ID certificate found${NC}"
    echo -e "${YELLOW}    The build will succeed but signing may fail${NC}"
    echo -e "${YELLOW}    See DISTRIBUTION.md for setup instructions${NC}"
else
    echo -e "${GREEN}  ✓ Developer ID certificate found${NC}"
fi

echo ""

# Step 1: Build
echo -e "${BLUE}[Step 1/5] Building application...${NC}"
if ./scripts/build.sh; then
    echo -e "${GREEN}✓ Build completed${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo ""

# Step 2: Sign
echo -e "${BLUE}[Step 2/5] Signing application...${NC}"
if ./scripts/sign.sh; then
    echo -e "${GREEN}✓ Signing completed${NC}"
else
    echo -e "${RED}✗ Signing failed${NC}"
    echo -e "${YELLOW}Note: If you don't have a Developer ID certificate, see DISTRIBUTION.md${NC}"
    exit 1
fi
echo ""

# Step 3: Notarize
echo -e "${BLUE}[Step 3/5] Notarizing application...${NC}"
echo -e "${YELLOW}This may take 5-30 minutes...${NC}"
if ./scripts/notarize.sh; then
    echo -e "${GREEN}✓ Notarization completed${NC}"
else
    echo -e "${RED}✗ Notarization failed${NC}"
    echo -e "${YELLOW}Note: See DISTRIBUTION.md for notarization setup instructions${NC}"
    exit 1
fi
echo ""

# Step 4: Create DMG
echo -e "${BLUE}[Step 4/5] Creating DMG...${NC}"
if ./scripts/create-dmg.sh; then
    echo -e "${GREEN}✓ DMG created${NC}"
else
    echo -e "${RED}✗ DMG creation failed${NC}"
    exit 1
fi
echo ""

# Step 5: Verify
echo -e "${BLUE}[Step 5/5] Verifying distribution package...${NC}"
DMG_PATH=$(find ./build -name "*.dmg" -type f | head -n 1)
if [ -n "$DMG_PATH" ]; then
    if ./scripts/verify.sh "$DMG_PATH"; then
        echo -e "${GREEN}✓ Verification passed${NC}"
    else
        echo -e "${RED}✗ Verification failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Could not find DMG to verify${NC}"
    exit 1
fi
echo ""

# Success!
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Distribution Package Ready!                  ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Output:${NC}"
ls -lh "$DMG_PATH"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Test the DMG on a clean macOS system"
echo "  2. Upload to your distribution channel (GitHub Releases, website, etc.)"
echo "  3. Users can download and install without security warnings"
echo ""
echo -e "${BLUE}For more information, see DISTRIBUTION.md${NC}"
