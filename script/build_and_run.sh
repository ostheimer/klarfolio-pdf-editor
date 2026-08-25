#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Klarfolio PDF Editor"
EXECUTABLE_NAME="KlarfolioPDFEditor"
BUNDLE_ID="${BUNDLE_ID:-at.ostheimer.klarfoliopdf.debug}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$EXECUTABLE_NAME"

if pgrep -f "$APP_BINARY" >/dev/null 2>&1; then
  echo "error: close the repository app normally before rebuilding it: $APP_BUNDLE" >&2
  exit 1
fi

BUNDLE_ID="$BUNDLE_ID" "$ROOT_DIR/script/build_app_bundle.sh" \
  --configuration debug \
  --output "$APP_BUNDLE" \
  --sign-identity "${KLARFOLIO_LOCAL_SIGN_IDENTITY:--}" >/dev/null

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$EXECUTABLE_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -f "$APP_BINARY" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
