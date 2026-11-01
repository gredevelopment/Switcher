# Releasing Switcher

This document describes how maintainers produce a signed macOS build and DMG for [GitHub Releases](https://github.com/gre-dev/Switcher/releases).

## Prerequisites

- macOS with Xcode installed
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [create-dmg](https://github.com/create-dmg/create-dmg) (`brew install create-dmg`), or the script falls back to `hdiutil`
- Apple **Developer ID Application** certificate for team `TN65L8H2L8` in Keychain
- Optional: notarization credentials for `xcrun notarytool` (recommended before wide distribution)

## Version

Set `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`, then tag the repository (for example `v1.0.0`).

## One-command build

From the repository root:

```bash
chmod +x scripts/release.sh
./scripts/release.sh 1.0.0
```

Outputs:

| Artifact | Path |
|----------|------|
| Archive | `build/Switcher.xcarchive` |
| Exported app | `build/export/Switcher.app` |
| DMG | `build/Switcher-<version>.dmg` |

## Manual steps (equivalent)

```bash
xcodegen generate

xcodebuild archive \
  -project Switcher.xcodeproj \
  -scheme Switcher \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath build/Switcher.xcarchive \
  DEVELOPMENT_TEAM=TN65L8H2L8 \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Developer ID Application"

xcodebuild -exportArchive \
  -archivePath build/Switcher.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

Then run `scripts/release.sh` (which wraps DMG creation) or use `create-dmg` on `build/export/Switcher.app`.

## Notarization (recommended)

After the DMG is created:

```bash
xcrun notarytool submit "build/Switcher-<version>.dmg" --wait
xcrun stapler staple "build/Switcher-<version>.dmg"
```

Use your Apple ID app-specific password or keychain profile; do not commit credentials.

## Publish on GitHub

1. Commit version bumps and push `main`.
2. Create an annotated tag: `git tag -a v1.0.0 -m "Switcher 1.0.0"`.
3. Push the tag: `git push origin v1.0.0`.
4. Create a release and upload the DMG:

```bash
gh release create v1.0.0 "build/Switcher-1.0.0.dmg" \
  --title "Switcher 1.0.0" \
  --notes "See repository README for requirements and usage."
```

DMG files are listed in `.gitignore` and should not be committed to git; only attach them to releases.
