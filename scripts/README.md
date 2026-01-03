# Distribution Scripts

This directory contains scripts for building, signing, notarizing, and packaging VisionCast XD for distribution outside the Mac App Store.

## Quick Start

### Complete Build (Automated)

Run all steps automatically:

```bash
./scripts/build-all.sh
```

This will:
1. Build the application
2. Sign with Developer ID
3. Notarize with Apple
4. Create a DMG package
5. Verify the distribution package

### Manual Build (Step by Step)

Run each step individually for more control:

```bash
# 1. Build
./scripts/build.sh

# 2. Sign
./scripts/sign.sh

# 3. Notarize (5-30 minutes)
./scripts/notarize.sh

# 4. Create DMG
./scripts/create-dmg.sh

# 5. Verify
./scripts/verify.sh "./build/VisionCastXD.dmg"
```

## Scripts

### `build.sh`
Builds the application in Release configuration without code signing.

**Usage:**
```bash
./scripts/build.sh
```

**Output:** `./build/Vision Cast XD.app`

### `sign.sh`
Signs the application with Developer ID certificate, enables hardened runtime, and applies notarization-ready settings.

**Usage:**
```bash
./scripts/sign.sh [path-to-app]
```

**Options:**
- `path-to-app`: Path to the app bundle (default: `./build/Vision Cast XD.app`)

**Environment Variables:**
- `DEVELOPER_ID_IDENTITY`: Developer ID certificate name (default: `Developer ID Application`)

**Example:**
```bash
export DEVELOPER_ID_IDENTITY="Developer ID Application: Company Name (TEAM_ID)"
./scripts/sign.sh
```

### `notarize.sh`
Submits the app to Apple's notarization service using `notarytool` and staples the notarization ticket.

**Usage:**
```bash
./scripts/notarize.sh [path-to-app] [path-to-zip]
```

**Options:**
- `path-to-app`: Path to the app bundle (default: `./build/Vision Cast XD.app`)
- `path-to-zip`: Path for the notarization archive (default: `./build/VisionCastXD-notarization.zip`)

**Environment Variables (Option 1):**
```bash
export NOTARIZATION_APPLE_ID="your-apple-id@example.com"
export NOTARIZATION_TEAM_ID="YOUR_TEAM_ID"
export NOTARIZATION_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

**Keychain Profile (Option 2 - Recommended):**
```bash
# Store credentials once
xcrun notarytool store-credentials notarytool-profile \
  --apple-id "your-apple-id@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"

# Then use the script
./scripts/notarize.sh
```

### `create-dmg.sh`
Creates a distributable DMG with the application and an Applications folder symlink.

**Usage:**
```bash
./scripts/create-dmg.sh [path-to-app] [dmg-name]
```

**Options:**
- `path-to-app`: Path to the app bundle (default: `./build/Vision Cast XD.app`)
- `dmg-name`: Base name for the DMG (default: `VisionCastXD`)

**Output:** `./build/VisionCastXD-[version].dmg`

### `verify.sh`
Verifies the distribution package is properly signed, notarized, and will pass Gatekeeper checks.

**Usage:**
```bash
./scripts/verify.sh [path-to-app-or-dmg]
```

**Checks:**
1. ✓ Code signature validity
2. ✓ Hardened runtime enabled
3. ✓ Entitlements (no sandbox for Developer ID)
4. ✓ Notarization ticket stapled
5. ✓ Gatekeeper assessment
6. ✓ Embedded libraries signed
7. ✓ DMG signature (if DMG provided)

**Example:**
```bash
./scripts/verify.sh "./build/VisionCastXD.dmg"
./scripts/verify.sh "./build/Vision Cast XD.app"
```

### `build-all.sh`
Master script that runs all steps in sequence with progress reporting.

**Usage:**
```bash
./scripts/build-all.sh
```

This is the recommended way to build distribution packages.

## Prerequisites

See [DISTRIBUTION.md](../DISTRIBUTION.md) for complete setup instructions.

**Required:**
- macOS with Xcode
- Apple Developer Account
- Developer ID Application certificate
- App-specific password for notarization

## Troubleshooting

### Code Signing Errors

```bash
# List available signing identities
security find-identity -v -p codesigning

# Check if certificate is valid
security find-identity -v -p codesigning | grep "Developer ID Application"
```

### Notarization Errors

```bash
# View notarization history
xcrun notarytool history --keychain-profile notarytool-profile

# Get detailed log for a submission
xcrun notarytool log <submission-id> --keychain-profile notarytool-profile
```

### Gatekeeper Issues

```bash
# Test Gatekeeper assessment
spctl --assess --verbose --type execute "./build/Vision Cast XD.app"

# Simulate downloaded app (adds quarantine attribute)
xattr -w com.apple.quarantine "0081;$(date +%s);Safari;" "./build/Vision Cast XD.app"
```

## CI/CD Integration

These scripts can be used in CI/CD pipelines. Example for GitHub Actions:

```yaml
- name: Build distribution package
  env:
    DEVELOPER_ID_IDENTITY: ${{ secrets.DEVELOPER_ID_IDENTITY }}
    NOTARIZATION_APPLE_ID: ${{ secrets.NOTARIZATION_APPLE_ID }}
    NOTARIZATION_TEAM_ID: ${{ secrets.NOTARIZATION_TEAM_ID }}
    NOTARIZATION_PASSWORD: ${{ secrets.NOTARIZATION_PASSWORD }}
  run: ./scripts/build-all.sh

- name: Upload DMG
  uses: actions/upload-artifact@v3
  with:
    name: VisionCastXD-DMG
    path: build/*.dmg
```

## Additional Resources

- [DISTRIBUTION.md](../DISTRIBUTION.md) - Complete distribution guide
- [Apple Developer - Notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)

## Support

For issues with these scripts:
1. Check [DISTRIBUTION.md](../DISTRIBUTION.md) troubleshooting section
2. Review script output for specific errors
3. Check Apple Developer Forums for notarization issues

---

**Note:** These scripts are designed for Developer ID distribution outside the Mac App Store. For Mac App Store distribution, different certificates and entitlements are required.
