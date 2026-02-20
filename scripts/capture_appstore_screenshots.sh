#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/Screenshots"
DERIVED_DATA="${ROOT_DIR}/build/ScreenshotDerivedData"
IPHONE_NAME="${IPHONE_NAME:-iPhone 17 Pro}"
IPAD_NAME="${IPAD_NAME:-iPad Pro 13-inch (M5)}"

mkdir -p "${OUT_DIR}"

log() {
  printf '[screenshots] %s\n' "$1"
}

device_udid() {
  local device_name="$1"
  xcrun simctl list devices available --json \
    | jq -r --arg NAME "${device_name}" '.devices[][] | select(.name == $NAME) | .udid' \
    | head -n1
}

boot_device() {
  local udid="$1"
  xcrun simctl boot "${udid}" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "${udid}" -b
  xcrun simctl ui "${udid}" appearance dark
  xcrun simctl status_bar "${udid}" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --batteryState charged \
    --batteryLevel 100 >/dev/null 2>&1 || true
}

capture_ios_shot() {
  local udid="$1"
  local bundle_id="$2"
  local output_file="$3"
  shift 3

  xcrun simctl terminate "${udid}" "${bundle_id}" >/dev/null 2>&1 || true
  xcrun simctl launch "${udid}" "${bundle_id}" -- "$@" >/dev/null
  sleep 2.5
  xcrun simctl io "${udid}" screenshot "${output_file}" >/dev/null
  log "Saved ${output_file}"
}

capture_mac_shot() {
  local app_path="$1"
  local output_file="$2"
  shift 2

  local x=80
  local y=60
  local width=1280
  local height=900

  pkill -x SaneSales >/dev/null 2>&1 || true
  open -na "${app_path}" --args "$@" >/dev/null 2>&1
  sleep 2.5

  osascript <<EOF >/dev/null
tell application "SaneSales" to activate
delay 0.2
tell application "System Events"
  tell process "SaneSales"
    set frontmost to true
    if exists window 1 then
      set position of window 1 to {${x}, ${y}}
      set size of window 1 to {${width}, ${height}}
    end if
  end tell
end tell
EOF
  sleep 0.8

  screencapture -x -R "${x},${y},${width},${height}" "${output_file}"
  log "Saved ${output_file}"
}

log "Building iOS app (simulator)..."
xcodebuild \
  -project "${ROOT_DIR}/SaneSales.xcodeproj" \
  -scheme SaneSalesIOS \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "${DERIVED_DATA}" \
  build >/dev/null

IOS_APP="${DERIVED_DATA}/Build/Products/Debug-iphonesimulator/SaneSales.app"
if [[ ! -d "${IOS_APP}" ]]; then
  echo "Missing built iOS app at ${IOS_APP}" >&2
  exit 1
fi
IOS_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${IOS_APP}/Info.plist")"

IPHONE_UDID="$(device_udid "${IPHONE_NAME}")"
IPAD_UDID="$(device_udid "${IPAD_NAME}")"
if [[ -z "${IPHONE_UDID}" || -z "${IPAD_UDID}" ]]; then
  echo "Could not find required simulators (${IPHONE_NAME}, ${IPAD_NAME})." >&2
  exit 1
fi

log "Booting simulators..."
boot_device "${IPHONE_UDID}"
boot_device "${IPAD_UDID}"

log "Installing iOS app on simulators..."
xcrun simctl install "${IPHONE_UDID}" "${IOS_APP}"
xcrun simctl install "${IPAD_UDID}" "${IOS_APP}"

log "Capturing iPhone screenshots..."
capture_ios_shot "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/01-onboarding-dark-6.7.png" --force-onboarding
capture_ios_shot "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/02-dashboard-dark-6.7.png" --demo --screenshot-tab dashboard
capture_ios_shot "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/03-orders-dark-6.7.png" --demo --screenshot-tab orders
capture_ios_shot "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/04-products-dark-6.7.png" --demo --screenshot-tab products
capture_ios_shot "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/05-settings-dark-6.7.png" --demo --screenshot-tab settings

log "Capturing iPad screenshots..."
capture_ios_shot "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/01-onboarding-dark-ipad.png" --force-onboarding
capture_ios_shot "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/02-dashboard-dark-ipad.png" --demo --screenshot-tab dashboard
capture_ios_shot "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/03-orders-dark-ipad.png" --demo --screenshot-tab orders
capture_ios_shot "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/04-products-dark-ipad.png" --demo --screenshot-tab products
capture_ios_shot "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/05-settings-dark-ipad.png" --demo --screenshot-tab settings

log "Building macOS app..."
xcodebuild \
  -project "${ROOT_DIR}/SaneSales.xcodeproj" \
  -scheme SaneSales \
  -configuration Debug \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath "${DERIVED_DATA}" \
  build >/dev/null

MAC_APP="${DERIVED_DATA}/Build/Products/Debug/SaneSales.app"
if [[ ! -d "${MAC_APP}" ]]; then
  echo "Missing built macOS app at ${MAC_APP}" >&2
  exit 1
fi

log "Capturing macOS screenshots..."
capture_mac_shot "${MAC_APP}" "${OUT_DIR}/01-onboarding-dark-mac.png" --force-onboarding
capture_mac_shot "${MAC_APP}" "${OUT_DIR}/02-dashboard-dark-mac.png" --demo --screenshot-tab dashboard
capture_mac_shot "${MAC_APP}" "${OUT_DIR}/03-orders-dark-mac.png" --demo --screenshot-tab orders
capture_mac_shot "${MAC_APP}" "${OUT_DIR}/04-products-dark-mac.png" --demo --screenshot-tab products
capture_mac_shot "${MAC_APP}" "${OUT_DIR}/05-settings-dark-mac.png" --demo --screenshot-tab settings

pkill -x SaneSales >/dev/null 2>&1 || true
xcrun simctl terminate "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" >/dev/null 2>&1 || true
xcrun simctl terminate "${IPAD_UDID}" "${IOS_BUNDLE_ID}" >/dev/null 2>&1 || true

log "Done. Fresh screenshots are in ${OUT_DIR}"
