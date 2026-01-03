#!/bin/bash

# Example validation commands for VisionCast XD distribution
# This file demonstrates the commands used by the verify.sh script
# Run these individually to understand and diagnose any distribution issues

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_PATH="${1:-./build/Vision Cast XD.app}"

echo -e "${BLUE}=== Example Validation Commands ===${NC}"
echo ""
echo "App Path: $APP_PATH"
echo ""

# 1. Basic code signature verification
echo -e "${YELLOW}1. Verify code signature:${NC}"
echo "   codesign --verify --deep --strict \"$APP_PATH\""
echo ""

# 2. Display signature information
echo -e "${YELLOW}2. Display signature details:${NC}"
echo "   codesign --display --verbose=4 \"$APP_PATH\" 2>&1"
echo ""

# 3. Check entitlements
echo -e "${YELLOW}3. Display entitlements:${NC}"
echo "   codesign --display --entitlements - \"$APP_PATH\" 2>/dev/null | xmllint --format -"
echo ""

# 4. Check for hardened runtime
echo -e "${YELLOW}4. Check hardened runtime:${NC}"
echo "   codesign --display --verbose \"$APP_PATH\" 2>&1 | grep flags"
echo ""

# 5. Validate notarization ticket
echo -e "${YELLOW}5. Validate notarization ticket:${NC}"
echo "   xcrun stapler validate \"$APP_PATH\""
echo ""

# 6. Gatekeeper assessment
echo -e "${YELLOW}6. Gatekeeper assessment:${NC}"
echo "   spctl --assess --verbose --type execute \"$APP_PATH\""
echo ""

# 7. Check embedded frameworks
echo -e "${YELLOW}7. List and verify embedded frameworks:${NC}"
echo "   find \"$APP_PATH/Contents/Frameworks\" -type f \\( -name \"*.dylib\" -o -name \"*.framework\" \\)"
echo "   # Then verify each:"
echo "   codesign --verify <framework-path>"
echo ""

# 8. Check for quarantine attribute (simulates downloaded app)
echo -e "${YELLOW}8. Add/remove quarantine attribute (for testing):${NC}"
echo "   # Add quarantine (simulates download)"
echo "   xattr -w com.apple.quarantine \"0081;\$(date +%s);Safari;\" \"$APP_PATH\""
echo "   # Check quarantine"
echo "   xattr -l \"$APP_PATH\""
echo "   # Remove quarantine"
echo "   xattr -d com.apple.quarantine \"$APP_PATH\""
echo ""

# 9. Check certificate chain
echo -e "${YELLOW}9. Check certificate chain:${NC}"
echo "   codesign -dvv \"$APP_PATH\" 2>&1 | grep Authority"
echo ""

# 10. List all code signatures in bundle
echo -e "${YELLOW}10. List all signatures in bundle:${NC}"
echo "   find \"$APP_PATH\" -type f -perm /111 -exec codesign --verify {} \\; -print"
echo ""

# 11. Check app bundle structure
echo -e "${YELLOW}11. Check app bundle structure:${NC}"
echo "   ls -la \"$APP_PATH/Contents\""
echo "   cat \"$APP_PATH/Contents/Info.plist\""
echo ""

# 12. Notarization history
echo -e "${YELLOW}12. Check notarization history:${NC}"
echo "   xcrun notarytool history --keychain-profile notarytool-profile"
echo ""

# 13. Get notarization log
echo -e "${YELLOW}13. Get notarization log (if you have submission ID):${NC}"
echo "   xcrun notarytool log <submission-id> --keychain-profile notarytool-profile"
echo ""

# 14. Check available signing identities
echo -e "${YELLOW}14. List available signing identities:${NC}"
echo "   security find-identity -v -p codesigning"
echo ""

# 15. DMG verification (if applicable)
echo -e "${YELLOW}15. DMG verification:${NC}"
echo "   hdiutil verify \"./build/VisionCastXD.dmg\""
echo "   codesign --verify --deep \"./build/VisionCastXD.dmg\""
echo ""

echo -e "${GREEN}To run any command, copy and paste it into your terminal.${NC}"
echo -e "${GREEN}For automated checking, use: ./scripts/verify.sh${NC}"
