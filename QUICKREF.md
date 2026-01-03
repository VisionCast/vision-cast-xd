# Quick Reference - VisionCast XD Distribution

## One-Command Build
```bash
./scripts/build-all.sh
```
This runs all steps: build → sign → notarize → package → verify

## Individual Steps
```bash
./scripts/build.sh          # 1. Build app
./scripts/sign.sh           # 2. Sign with Developer ID
./scripts/notarize.sh       # 3. Notarize (5-30 min)
./scripts/create-dmg.sh     # 4. Create DMG
./scripts/verify.sh         # 5. Verify package
```

## First-Time Setup

### 1. Install Developer ID Certificate
1. Download from [developer.apple.com](https://developer.apple.com/account/resources/certificates/)
2. Double-click to install in Keychain

### 2. Generate App-Specific Password
1. Go to [appleid.apple.com](https://appleid.apple.com/)
2. Sign in → Security → App-Specific Passwords
3. Generate new password

### 3. Store Notarization Credentials
```bash
xcrun notarytool store-credentials notarytool-profile \
  --apple-id "your-apple-id@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

## Environment Variables

### Option 1: Export Variables
```bash
export DEVELOPER_ID_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
export NOTARIZATION_APPLE_ID="your-apple-id@example.com"
export NOTARIZATION_TEAM_ID="YOUR_TEAM_ID"
export NOTARIZATION_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

### Option 2: Use Keychain (Recommended)
Store credentials once with `notarytool store-credentials`, then scripts automatically use them.

## Common Commands

### Check Code Signature
```bash
codesign --verify --deep --strict "./build/Vision Cast XD.app"
codesign --display --verbose=4 "./build/Vision Cast XD.app"
```

### Check Notarization
```bash
xcrun stapler validate "./build/Vision Cast XD.app"
spctl -a -vv "./build/Vision Cast XD.app"
```

### List Certificates
```bash
security find-identity -v -p codesigning
```

### Notarization History
```bash
xcrun notarytool history --keychain-profile notarytool-profile
xcrun notarytool log <submission-id> --keychain-profile notarytool-profile
```

## Troubleshooting

### "No identity found"
```bash
# Check for Developer ID certificate
security find-identity -v -p codesigning | grep "Developer ID"
```
If missing, download and install from developer.apple.com

### "Notarization failed"
```bash
# Get the notarization log
xcrun notarytool log <submission-id> --keychain-profile notarytool-profile
```
Common issues: unsigned frameworks, missing hardened runtime

### "Application is damaged"
- Re-download the DMG (corruption during download)
- Or ensure notarization ticket is stapled

### "Cannot be opened"
```bash
# Manually staple the ticket
xcrun stapler staple "./build/Vision Cast XD.app"
```

## Test Gatekeeper
```bash
# Simulate downloaded app
xattr -w com.apple.quarantine "0081;$(date +%s);Safari;" "./build/Vision Cast XD.app"

# Try to open
open "./build/Vision Cast XD.app"

# Remove quarantine after testing
xattr -d com.apple.quarantine "./build/Vision Cast XD.app"
```

## Output Location
- **Built app:** `./build/Vision Cast XD.app`
- **DMG:** `./build/VisionCastXD-[version].dmg`
- **Build log:** `./build/build.log`
- **Notarization archive:** `./build/VisionCastXD-notarization.zip`

## Files
- `DISTRIBUTION.md` - Complete documentation
- `scripts/README.md` - Script documentation
- `VisionCastXD/VisionCastXD-DeveloperID.entitlements` - Non-sandboxed entitlements
- `scripts/build.sh` - Build script
- `scripts/sign.sh` - Signing script
- `scripts/notarize.sh` - Notarization script
- `scripts/create-dmg.sh` - DMG creation script
- `scripts/verify.sh` - Verification script
- `scripts/build-all.sh` - Complete pipeline

## Key Differences: Developer ID vs Mac App Store

| Feature | Developer ID | Mac App Store |
|---------|--------------|---------------|
| Distribution | Outside App Store | Only through App Store |
| Sandbox | Not required | Required |
| Certificate | Developer ID Application | Mac App Store |
| Notarization | Required | Not needed |
| Entitlements | `VisionCastXD-DeveloperID.entitlements` | `VisionCastXD.entitlements` |
| System APIs | Full access | Limited |

## CI/CD Quick Setup

```yaml
# GitHub Actions
- name: Import Certificate
  run: |
    echo ${{ secrets.DEVELOPER_ID_CERT_P12 }} | base64 -d > cert.p12
    security create-keychain -p actions build.keychain
    security import cert.p12 -k build.keychain -P ${{ secrets.CERT_PASSWORD }}
    
- name: Build Distribution
  env:
    NOTARIZATION_APPLE_ID: ${{ secrets.NOTARIZATION_APPLE_ID }}
    NOTARIZATION_TEAM_ID: ${{ secrets.NOTARIZATION_TEAM_ID }}
    NOTARIZATION_PASSWORD: ${{ secrets.NOTARIZATION_PASSWORD }}
  run: ./scripts/build-all.sh
```

## Links
- [Apple Developer Portal](https://developer.apple.com/)
- [Notarization Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)

---

For detailed information, see [DISTRIBUTION.md](DISTRIBUTION.md)
