#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<USAGE
usage: APP_STORE_APP_IDENTITY="3rd Party Mac Developer Application: ..." \\
       APP_STORE_INSTALLER_IDENTITY="3rd Party Mac Developer Installer: ..." \\
       $0

Creates a release .app and Mac App Store .pkg under dist/AppStore.

Optional environment:
  APP_VERSION      Marketing version, default: 0.1.0
  APP_BUILD        Build number, default: 1
  BUNDLE_ID        Bundle identifier, default: at.ostheimer.klarfoliopdf
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

APP_NAME="Klarfolio PDF Editor"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist/AppStore"
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BUILD="${APP_BUILD:-1}"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
PKG_PATH="$DIST_DIR/Klarfolio-PDF-Editor-$APP_VERSION-$APP_BUILD.pkg"
APP_IDENTITY="${APP_STORE_APP_IDENTITY:-}"
INSTALLER_IDENTITY="${APP_STORE_INSTALLER_IDENTITY:-}"

if [[ -z "$APP_IDENTITY" || -z "$INSTALLER_IDENTITY" ]]; then
  usage
  echo >&2
  echo "error: APP_STORE_APP_IDENTITY and APP_STORE_INSTALLER_IDENTITY are required." >&2
  echo >&2
  echo "Available signing identities on this Mac:" >&2
  security find-identity -v 2>/dev/null || true
  exit 2
fi

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

APP_VERSION="$APP_VERSION" \
APP_BUILD="$APP_BUILD" \
CONFIGURATION=release \
OUTPUT_APP_BUNDLE="$APP_BUNDLE" \
SIGN_IDENTITY="$APP_IDENTITY" \
"$ROOT_DIR/script/build_app_bundle.sh" --configuration release --output "$APP_BUNDLE" --sign-identity "$APP_IDENTITY"

codesign --verify --strict --verbose=2 "$APP_BUNDLE"
codesign -dvvv --entitlements :- "$APP_BUNDLE"

xcrun productbuild \
  --sign "$INSTALLER_IDENTITY" \
  --component "$APP_BUNDLE" \
  /Applications \
  "$PKG_PATH"

pkgutil --check-signature "$PKG_PATH"

echo "$PKG_PATH"
