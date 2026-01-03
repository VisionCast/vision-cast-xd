# macOS Developer ID Distribution Guide

This guide covers the complete process for building, signing, notarizing, and distributing **VisionCast XD** as a Developer ID application outside the Mac App Store.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Overview](#overview)
- [Step-by-Step Process](#step-by-step-process)
  - [1. Build the Application](#1-build-the-application)
  - [2. Sign with Developer ID](#2-sign-with-developer-id)
  - [3. Notarize the Application](#3-notarize-the-application)
  - [4. Create DMG Package](#4-create-dmg-package)
  - [5. Verify Distribution Package](#5-verify-distribution-package)
- [Troubleshooting](#troubleshooting)
- [Automation](#automation)
- [Additional Resources](#additional-resources)

## Prerequisites

### Required

1. **Apple Developer Account** with Developer ID certificate
   - Enrolled in the Apple Developer Program ($99/year)
   - Developer ID Application certificate installed in Keychain

2. **Xcode** and Command Line Tools
   ```bash
   xcode-select --install
   ```

3. **Developer ID Certificate**
   - Log in to [Apple Developer](https://developer.apple.com/account/resources/certificates/)
   - Create a "Developer ID Application" certificate
   - Download and install in Keychain Access

4. **App-Specific Password** for notarization
   - Go to [Apple ID account page](https://appleid.apple.com/)
   - Generate an app-specific password for notarytool

### Environment Setup

Set these environment variables (or store in keychain - see below):

```bash
export DEVELOPER_ID_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
export NOTARIZATION_APPLE_ID="your-apple-id@example.com"
export NOTARIZATION_TEAM_ID="YOUR_TEAM_ID"
export NOTARIZATION_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-specific password
```

**Recommended:** Store credentials in keychain (more secure):

```bash
xcrun notarytool store-credentials notarytool-profile \
  --apple-id "your-apple-id@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

## Overview

VisionCast XD is a system-level macOS application that uses private APIs for virtual display management. Because it needs system-level access:

- **Cannot use App Sandbox** (required for Mac App Store)
- **Must be signed with Developer ID** (not Mac App Store certificate)
- **Must be notarized** by Apple for Gatekeeper
- **Distributed as DMG** outside the Mac App Store

### Key Files

- `VisionCastXD/VisionCastXD-DeveloperID.entitlements` - Entitlements without sandbox
- `scripts/build.sh` - Build the application
- `scripts/sign.sh` - Sign with Developer ID
- `scripts/notarize.sh` - Submit for notarization
- `scripts/create-dmg.sh` - Package as DMG
- `scripts/verify.sh` - Verify the final package

## Step-by-Step Process

### 1. Build the Application

Build the app without code signing (signing happens in the next step):

```bash
./scripts/build.sh
```

**What it does:**
- Cleans previous builds
- Builds the app in Release configuration
- Copies the built app to `./build/Vision Cast XD.app`
- Generates a build log at `./build/build.log`

**Troubleshooting:**
- If build fails, check `./build/build.log` for detailed errors
- Ensure all dependencies are available (NDI SDK, etc.)
- Make sure you're running from the repository root

### 2. Sign with Developer ID

Sign the application bundle with your Developer ID certificate:

```bash
./scripts/sign.sh
```

**What it does:**
- Signs all embedded frameworks and libraries
- Signs the main application bundle with Developer ID
- Enables hardened runtime
- Applies timestamp from Apple's servers
- Verifies the signature

**Options:**
```bash
# Sign a specific app bundle
./scripts/sign.sh "./path/to/Your App.app"

# Use a specific signing identity
export DEVELOPER_ID_IDENTITY="Developer ID Application: Company Name (TEAM_ID)"
./scripts/sign.sh
```

**Verification:**
```bash
# Check signature
codesign --verify --deep --strict --verbose=2 "./build/Vision Cast XD.app"

# Display signature info
codesign --display --verbose=4 "./build/Vision Cast XD.app"
```

### 3. Notarize the Application

Submit the signed app to Apple's notarization service:

```bash
./scripts/notarize.sh
```

**What it does:**
- Verifies the app is properly signed
- Creates a zip archive preserving code signatures
- Submits to Apple's notarization service
- Waits for notarization to complete (can take 5-30 minutes)
- Staples the notarization ticket to the app
- Verifies the stapled ticket

**Using keychain credentials (recommended):**
```bash
# First time: store credentials
xcrun notarytool store-credentials notarytool-profile \
  --apple-id "your-apple-id@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"

# Then notarize
./scripts/notarize.sh
```

**Using environment variables:**
```bash
export NOTARIZATION_APPLE_ID="your-apple-id@example.com"
export NOTARIZATION_TEAM_ID="YOUR_TEAM_ID"
export NOTARIZATION_PASSWORD="xxxx-xxxx-xxxx-xxxx"
./scripts/notarize.sh
```

**Check notarization status manually:**
```bash
# List recent submissions
xcrun notarytool history --keychain-profile notarytool-profile

# Get details of a specific submission
xcrun notarytool info <submission-id> --keychain-profile notarytool-profile

# Get the notarization log
xcrun notarytool log <submission-id> --keychain-profile notarytool-profile
```

**Troubleshooting:**
- If notarization fails, check the log for specific issues
- Common issues:
  - Unsigned embedded frameworks
  - Missing hardened runtime
  - Code signature issues
  - Entitlements conflicts

### 4. Create DMG Package

Package the signed and notarized app as a DMG:

```bash
./scripts/create-dmg.sh
```

**What it does:**
- Verifies the app is signed and notarized
- Creates a DMG with the app and Applications symlink
- Customizes the DMG appearance (if running with GUI)
- Compresses and signs the DMG
- Outputs to `./build/VisionCastXD-[version].dmg`

**Options:**
```bash
# Create DMG with custom name
./scripts/create-dmg.sh "./build/Vision Cast XD.app" "CustomName"

# Result: ./build/CustomName-[version].dmg
```

**DMG Layout:**
The DMG will contain:
- The application bundle
- A symbolic link to /Applications
- Custom icon positions (if GUI available)

### 5. Verify Distribution Package

Verify the final package is ready for distribution:

```bash
./scripts/verify.sh "./build/VisionCastXD.dmg"
```

or for the app bundle:

```bash
./scripts/verify.sh "./build/Vision Cast XD.app"
```

**What it checks:**
1. ✓ Code signature validity
2. ✓ Hardened runtime enabled
3. ✓ Entitlements (confirms no sandbox for Developer ID)
4. ✓ Notarization ticket stapled
5. ✓ Gatekeeper will allow execution
6. ✓ Embedded libraries are signed
7. ✓ DMG signature (if applicable)

**Successful output:**
```
=== Verification Summary ===
✓ All checks passed!
The application is ready for distribution outside the Mac App Store.
```

## Troubleshooting

### Code Signing Issues

**"No identity found"**
```bash
# List available signing identities
security find-identity -v -p codesigning

# Import Developer ID certificate if missing
# Download from developer.apple.com and double-click to install
```

**"resource fork, Finder information, or similar detritus not allowed"**
```bash
# Clean extended attributes
xattr -cr "./build/Vision Cast XD.app"

# Then re-sign
./scripts/sign.sh
```

### Notarization Issues

**"notarization failed"**
```bash
# Get the submission ID from the error output
SUBMISSION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# View the log
xcrun notarytool log $SUBMISSION_ID --keychain-profile notarytool-profile

# Common fixes:
# 1. Ensure hardened runtime is enabled
# 2. Sign all embedded frameworks
# 3. Remove any debugging symbols
# 4. Check entitlements are valid
```

**"Invalid credentials"**
```bash
# Re-store credentials
xcrun notarytool store-credentials notarytool-profile \
  --apple-id "your-apple-id@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

### Gatekeeper Issues

**"Application is damaged"**
- User needs to download again (corruption during download)
- Or check if notarization ticket is stapled

**"Cannot be opened because the developer cannot be verified"**
- App needs to be notarized
- Or notarization ticket wasn't stapled
- Run: `xcrun stapler staple "./build/Vision Cast XD.app"`

**Testing Gatekeeper on your own Mac:**
```bash
# Quarantine the app (simulates download)
xattr -w com.apple.quarantine "0081;$(date +%s);Safari;F643CD5F-6D2A-4390-9D00-B1F4D3E43B15" "./build/Vision Cast XD.app"

# Try to open it
open "./build/Vision Cast XD.app"

# Remove quarantine after testing
xattr -d com.apple.quarantine "./build/Vision Cast XD.app"
```

## Automation

### Complete Build Pipeline

Create a single script to run all steps:

```bash
#!/bin/bash
set -e

echo "Building VisionCast XD distribution package..."

# 1. Build
./scripts/build.sh

# 2. Sign
./scripts/sign.sh

# 3. Notarize
./scripts/notarize.sh

# 4. Create DMG
./scripts/create-dmg.sh

# 5. Verify
./scripts/verify.sh "./build/VisionCastXD.dmg"

echo "✓ Distribution package ready!"
```

### CI/CD Integration

For GitHub Actions, GitLab CI, or similar:

```yaml
# Example: GitHub Actions
- name: Import certificates
  env:
    CERTIFICATE_P12: ${{ secrets.DEVELOPER_ID_CERT_P12 }}
    CERTIFICATE_PASSWORD: ${{ secrets.DEVELOPER_ID_CERT_PASSWORD }}
  run: |
    # Create temporary keychain
    security create-keychain -p actions build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p actions build.keychain
    
    # Import certificate
    echo $CERTIFICATE_P12 | base64 --decode > certificate.p12
    security import certificate.p12 -k build.keychain -P $CERTIFICATE_PASSWORD -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: -s -k actions build.keychain

- name: Build and sign
  run: |
    ./scripts/build.sh
    ./scripts/sign.sh

- name: Notarize
  env:
    NOTARIZATION_APPLE_ID: ${{ secrets.NOTARIZATION_APPLE_ID }}
    NOTARIZATION_TEAM_ID: ${{ secrets.NOTARIZATION_TEAM_ID }}
    NOTARIZATION_PASSWORD: ${{ secrets.NOTARIZATION_PASSWORD }}
  run: ./scripts/notarize.sh

- name: Create DMG
  run: ./scripts/create-dmg.sh

- name: Verify
  run: ./scripts/verify.sh "./build/VisionCastXD.dmg"
```

## Additional Resources

### Official Apple Documentation

- [Notarizing macOS Software Before Distribution](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)
- [Gatekeeper](https://support.apple.com/en-us/HT202491)
- [notarytool Manual](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)

### Tools Reference

```bash
# Code signing
codesign --help
man codesign

# Notarization
xcrun notarytool --help

# Stapler
xcrun stapler --help

# Gatekeeper
spctl --help
man spctl

# DMG creation
hdiutil --help
man hdiutil
```

### Common Commands

```bash
# List all Developer ID certificates
security find-identity -v -p codesigning | grep "Developer ID"

# Check if app is notarized (online check)
spctl -a -vv -t install "./build/Vision Cast XD.app"

# View all code signatures in bundle
codesign -dvvv --deep "./build/Vision Cast XD.app"

# Check entitlements
codesign -d --entitlements - "./build/Vision Cast XD.app"

# Mount and inspect DMG
hdiutil attach "./build/VisionCastXD.dmg"
# ... inspect
hdiutil detach "/Volumes/Vision Cast XD"
```

### Support

For issues specific to VisionCast XD distribution:
1. Check this documentation
2. Review the script output for errors
3. Check Apple's notarization log for specific issues
4. Consult Apple Developer Forums

For issues with Apple's notarization service:
- [Apple Developer Forums - Code Signing & Notarization](https://developer.apple.com/forums/topics/code-signing-and-notarization)
- [Apple Developer Support](https://developer.apple.com/support/)

---

## Summary

The complete distribution process:

```bash
# 1. Build
./scripts/build.sh

# 2. Sign
./scripts/sign.sh

# 3. Notarize (5-30 minutes)
./scripts/notarize.sh

# 4. Package
./scripts/create-dmg.sh

# 5. Verify
./scripts/verify.sh "./build/VisionCastXD.dmg"

# 6. Distribute!
# Upload the DMG to your website, GitHub Releases, etc.
```

Users can download the DMG, open it, and drag the app to their Applications folder. Gatekeeper will verify the Developer ID signature and notarization, allowing the app to run without security warnings.
