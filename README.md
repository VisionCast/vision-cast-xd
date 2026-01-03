<h3 align="center">
  <a href="https://github.com/Stengo/DeskPad/blob/main/DeskPad/Assets.xcassets/AppIcon.appiconset/Icon-256.png">
  <img src="https://github.com/Stengo/DeskPad/blob/main/DeskPad/Assets.xcassets/AppIcon.appiconset/Icon-256.png?raw=true" alt="DeskPad Icon" width="128">
  </a>
</h3>

# DeskPad
A virtual monitor for screen sharing

<h3 align="center">
  <a href="https://github.com/Stengo/DeskPad/blob/main/screenshot.jpg">
  <img src="https://github.com/Stengo/DeskPad/blob/main/screenshot.jpg?raw=true" alt="DeskPad Screenshot">
  </a>
</h3>

Certain workflows require sharing the entire screen (usually due to switching through multiple applications), but if the presenter has a much larger display than the audience it can be hard to see what is happening.

DeskPad creates a virtual display that is mirrored within its application window so that you can create a dedicated, easily shareable workspace.

# Installation

You can either download the [latest release binary](https://github.com/Stengo/DeskPad/releases) or install via [Homebrew](https://brew.sh) by calling `brew install deskpad`.

# Usage
DeskPad behaves like any other display. Launching the app is equivalent to plugging in a monitor, so macOS will take care of properly arranging your windows to their previous configuration.

You can change the display resolution through the system preferences and the application window will adjust accordingly.

Whenever you move your mouse cursor to the virtual display, DeskPad will highlight its title bar in blue and move the application window to the front to let you know where you are.

# Building & Distribution

For developers who want to build and distribute VisionCast XD:

## Quick Build
```bash
./scripts/build-all.sh
```

This automated script will:
1. Build the application
2. Sign with Developer ID
3. Notarize with Apple
4. Create a DMG package
5. Verify the distribution

## Documentation
- **[DISTRIBUTION.md](DISTRIBUTION.md)** - Complete distribution guide with step-by-step instructions
- **[QUICKREF.md](QUICKREF.md)** - Quick reference for common commands
- **[scripts/README.md](scripts/README.md)** - Detailed script documentation

## Requirements
- macOS with Xcode
- Apple Developer Account with Developer ID certificate
- App-specific password for notarization

See [DISTRIBUTION.md](DISTRIBUTION.md) for detailed setup instructions.

<h3 align="center">
  <a href="https://github.com/Stengo/DeskPad/blob/main/demonstration.gif">
  <img src="https://github.com/Stengo/DeskPad/blob/main/demonstration.gif?raw=true" alt="DeskPad Demonstration">
  </a>
</h3>
