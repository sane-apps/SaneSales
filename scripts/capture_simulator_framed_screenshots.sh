#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/Screenshots/framed"
DERIVED_DATA="${ROOT_DIR}/build/FramedDerivedData"

IPHONE_NAME="${IPHONE_NAME:-iPhone 17 Pro}"
IPAD_NAME="${IPAD_NAME:-iPad Pro 13-inch (M5)}"
WATCH_NAME="${WATCH_NAME:-Apple Watch Series 11 (46mm)}"

mkdir -p "${OUT_DIR}"

log() {
  printf '[framed] %s\n' "$1"
}

device_udid_auto() {
  local preferred="$1"
  local pattern="$2"
  local udid
  udid="$(xcrun simctl list devices available --json | jq -r --arg NAME "${preferred}" '.devices[][] | select(.name == $NAME) | .udid' | head -n1)"
  if [[ -z "${udid}" ]]; then
    udid="$(xcrun simctl list devices available --json | jq -r --arg PATTERN "${pattern}" '.devices[][] | select(.name | test($PATTERN; "i")) | .udid' | head -n1)"
  fi
  echo "${udid}"
}

boot_device() {
  local udid="$1"
  xcrun simctl boot "${udid}" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "${udid}" -b
  xcrun simctl ui "${udid}" appearance dark >/dev/null 2>&1 || true
}

simulator_window_id() {
  swift - <<'SWIFT'
import Cocoa

let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
if let window = windows.first(where: { ($0[kCGWindowOwnerName as String] as? String) == "Simulator" }),
   let id = window[kCGWindowNumber as String] as? Int {
    print(id)
}
SWIFT
}

capture_framed() {
  local udid="$1"
  local output="$2"
  local bundle="$3"
  local window_bounds="$4"
  shift 3

  xcrun simctl shutdown all >/dev/null 2>&1 || true
  xcrun simctl boot "${udid}" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "${udid}" -b
  xcrun simctl ui "${udid}" appearance dark >/dev/null 2>&1 || true

  xcrun simctl terminate "${udid}" "${bundle}" >/dev/null 2>&1 || true
  xcrun simctl launch "${udid}" "${bundle}" -- "$@" >/dev/null
  killall Simulator >/dev/null 2>&1 || true
  sleep 0.8
  open -a Simulator --args -CurrentDeviceUDID "${udid}"
  sleep 2.2
  osascript -e 'tell application "Simulator" to activate' >/dev/null 2>&1 || true
  osascript -e "tell application \"Simulator\" to if (count of windows) > 0 then set bounds of front window to {${window_bounds}}" >/dev/null 2>&1 || true
  sleep 0.8

  local wid
  wid="$(simulator_window_id)"
  if [[ -z "${wid}" ]]; then
    echo "Could not resolve Simulator window id." >&2
    return 1
  fi

  screencapture -x -o -l "${wid}" "${output}"
  log "Saved ${output}"
}

# Build apps once
log "Building iOS app..."
xcodebuild \
  -project "${ROOT_DIR}/SaneSales.xcodeproj" \
  -scheme SaneSalesIOS \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "${DERIVED_DATA}" \
  build >/dev/null

log "Building watch app..."
xcodebuild \
  -project "${ROOT_DIR}/SaneSales.xcodeproj" \
  -scheme SaneSalesWatch \
  -configuration Debug \
  -destination "generic/platform=watchOS Simulator" \
  -derivedDataPath "${DERIVED_DATA}" \
  build >/dev/null

IOS_APP="${DERIVED_DATA}/Build/Products/Debug-iphonesimulator/SaneSales.app"
WATCH_APP="${DERIVED_DATA}/Build/Products/Debug-watchsimulator/SaneSalesWatch.app"
IOS_BUNDLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${IOS_APP}/Info.plist")"
WATCH_BUNDLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${WATCH_APP}/Info.plist")"

IPHONE_UDID="$(device_udid_auto "${IPHONE_NAME}" "iphone")"
IPAD_UDID="$(device_udid_auto "${IPAD_NAME}" "ipad")"
WATCH_UDID="$(device_udid_auto "${WATCH_NAME}" "apple watch")"

if [[ -z "${IPHONE_UDID}" || -z "${IPAD_UDID}" || -z "${WATCH_UDID}" ]]; then
  echo "Required simulator missing (iphone/ipad/watch)." >&2
  exit 1
fi

boot_device "${IPHONE_UDID}"
boot_device "${IPAD_UDID}"
boot_device "${WATCH_UDID}"

xcrun simctl install "${IPHONE_UDID}" "${IOS_APP}" >/dev/null
xcrun simctl install "${IPAD_UDID}" "${IOS_APP}" >/dev/null
xcrun simctl install "${WATCH_UDID}" "${WATCH_APP}" >/dev/null

capture_framed "${IPHONE_UDID}" "${OUT_DIR}/iphone-dashboard-framed.png" "${IOS_BUNDLE}" "90,60,780,1460" --demo --screenshot-tab dashboard
capture_framed "${IPAD_UDID}" "${OUT_DIR}/ipad-dashboard-framed.png" "${IOS_BUNDLE}" "90,60,1120,1420" --demo --screenshot-tab dashboard
capture_framed "${WATCH_UDID}" "${OUT_DIR}/watch-dashboard-framed.png" "${WATCH_BUNDLE}" "110,80,780,1100" --demo
capture_framed "${WATCH_UDID}" "${OUT_DIR}/watch-recent-framed.png" "${WATCH_BUNDLE}" "110,80,780,1100" --demo --focus-recent

log "Done. Framed screenshots are in ${OUT_DIR}"
