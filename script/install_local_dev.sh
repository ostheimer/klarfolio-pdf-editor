#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Klarfolio PDF Editor Dev"
EXECUTABLE_NAME="KlarfolioPDFEditor"
BUNDLE_ID="at.ostheimer.klarfoliopdf.debug"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_APPLICATIONS_DIR="${HOME:?}/Applications"
APPLICATIONS_DIR="${KLARFOLIO_LOCAL_APPLICATIONS_DIR:-$DEFAULT_APPLICATIONS_DIR}"
APP_BUNDLE="$APPLICATIONS_DIR/$APP_NAME.app"

case "$APPLICATIONS_DIR" in
  ""|/|"$HOME"|"$ROOT_DIR")
    echo "error: unsafe local applications directory: $APPLICATIONS_DIR" >&2
    exit 1
    ;;
esac

APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"

if pgrep -f "$APP_EXECUTABLE" >/dev/null 2>&1; then
  echo "error: close Klarfolio PDF Editor Dev normally before updating it: $APP_BUNDLE" >&2
  exit 1
fi

mkdir -p "$APPLICATIONS_DIR"

APP_NAME="$APP_NAME" \
BUNDLE_ID="$BUNDLE_ID" \
APP_VERSION="${APP_VERSION:-0.1.0}" \
APP_BUILD="${APP_BUILD:-1}" \
  "$ROOT_DIR/script/build_app_bundle.sh" \
    --configuration debug \
    --output "$APP_BUNDLE" \
    --sign-identity "${KLARFOLIO_LOCAL_SIGN_IDENTITY:--}" >/dev/null

codesign --verify --strict --verbose=2 "$APP_BUNDLE"
plutil -lint "$APP_BUNDLE/Contents/Info.plist" >/dev/null

/usr/bin/open -n "$APP_BUNDLE"
sleep 1
pgrep -f "$APP_EXECUTABLE" >/dev/null

echo "$APP_BUNDLE"
