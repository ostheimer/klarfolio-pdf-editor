#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<USAGE
usage: $0 [--configuration debug|release] [--output path] [--sign-identity identity|-] [--no-sign]

Builds Klarfolio PDF Editor and assembles a macOS .app bundle.

Environment overrides:
  APP_NAME               Display and bundle name, default: Klarfolio PDF Editor
  APP_VERSION            Marketing version, default: 0.1.0
  APP_BUILD              Build number, default: 1
  BUNDLE_ID              Bundle identifier, default: at.ostheimer.klarfoliopdf
  MIN_SYSTEM_VERSION     Minimum macOS version, default: 14.0
  APP_CATEGORY           LSApplicationCategoryType, default: public.app-category.productivity
USAGE
}

CONFIGURATION="${CONFIGURATION:-debug}"
OUTPUT_APP_BUNDLE="${OUTPUT_APP_BUNDLE:-}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
SIGN_APP="${SIGN_APP:-1}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --output)
      OUTPUT_APP_BUNDLE="$2"
      shift 2
      ;;
    --sign-identity)
      SIGN_IDENTITY="$2"
      shift 2
      ;;
    --no-sign)
      SIGN_APP=0
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

case "$CONFIGURATION" in
  debug|release)
    ;;
  *)
    echo "error: --configuration must be debug or release" >&2
    exit 2
    ;;
esac

APP_NAME="${APP_NAME:-Klarfolio PDF Editor}"
EXECUTABLE_NAME="KlarfolioPDFEditor"
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BUILD="${APP_BUILD:-1}"
BUNDLE_ID="${BUNDLE_ID:-at.ostheimer.klarfoliopdf}"
MIN_SYSTEM_VERSION="${MIN_SYSTEM_VERSION:-14.0}"
APP_CATEGORY="${APP_CATEGORY:-public.app-category.productivity}"
COPYRIGHT="${COPYRIGHT:-Copyright (c) 2026 Klarfolio PDF Editor.}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="${OUTPUT_APP_BUNDLE:-$DIST_DIR/$APP_NAME.app}"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$EXECUTABLE_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON_SOURCE="$ROOT_DIR/Sources/KlarfolioPDFEditor/Resources/AppIcon.icns"
ENTITLEMENTS="$ROOT_DIR/Packaging/KlarfolioPDFEditor.entitlements"

if [[ ! -f "$ENTITLEMENTS" ]]; then
  echo "error: missing entitlements at $ENTITLEMENTS" >&2
  exit 1
fi

if [[ "$CONFIGURATION" == "release" ]]; then
  swift build -c release
  BUILD_BINARY="$(swift build -c release --show-bin-path)/$EXECUTABLE_NAME"
else
  swift build
  BUILD_BINARY="$(swift build --show-bin-path)/$EXECUTABLE_NAME"
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

if [[ -f "$APP_ICON_SOURCE" ]]; then
  cp "$APP_ICON_SOURCE" "$APP_RESOURCES/AppIcon.icns"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>de</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeExtensions</key>
      <array>
        <string>pdf</string>
      </array>
      <key>CFBundleTypeIconFile</key>
      <string>AppIcon</string>
      <key>CFBundleTypeName</key>
      <string>PDF Document</string>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>com.adobe.pdf</string>
      </array>
    </dict>
  </array>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>MacOSX</string>
  </array>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>LSApplicationCategoryType</key>
  <string>$APP_CATEGORY</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSSupportsOpeningDocumentsInPlace</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>$COPYRIGHT</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSSupportsAutomaticTermination</key>
  <true/>
  <key>NSSupportsSuddenTermination</key>
  <true/>
</dict>
</plist>
PLIST

plutil -lint "$INFO_PLIST" >/dev/null

if [[ "$SIGN_APP" == "1" ]]; then
  codesign_args=(--force --sign "$SIGN_IDENTITY" --entitlements "$ENTITLEMENTS")
  if [[ -n "${SIGN_OPTIONS:-}" ]]; then
    codesign_args+=(--options "$SIGN_OPTIONS")
  fi
  codesign "${codesign_args[@]}" "$APP_BUNDLE"
fi

echo "$APP_BUNDLE"
