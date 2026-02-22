#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/Videos"
DERIVED_DATA="${ROOT_DIR}/build/VideoDerivedData"

IPHONE_NAME="${IPHONE_NAME:-iPhone 17 Pro}"
IPAD_NAME="${IPAD_NAME:-iPad Pro 13-inch (M5)}"
WATCH_NAME="${WATCH_NAME:-Apple Watch Series 10 (46mm)}"

IOS_SCHEME="${IOS_SCHEME:-SaneSalesIOS}"
WATCH_SCHEME="${WATCH_SCHEME:-SaneSalesWatch}"
MAC_SCHEME="${MAC_SCHEME:-SaneSales}"

CAPTURE_IPHONE="${CAPTURE_IPHONE:-1}"
CAPTURE_IPAD="${CAPTURE_IPAD:-1}"
CAPTURE_WATCH="${CAPTURE_WATCH:-auto}"
CAPTURE_MAC="${CAPTURE_MAC:-1}"
REQUIRE_WATCH="${REQUIRE_WATCH:-0}"

CLIP_SECONDS="${CLIP_SECONDS:-6}"
MAC_RECT="${MAC_RECT:-80,60,1280,900}"
HIDE_DESKTOP_ICONS="${HIDE_DESKTOP_ICONS:-1}"

ORIGINAL_KEYBOARD_UI_MODE="__UNSET__"
ORIGINAL_CREATE_DESKTOP="__UNSET__"

mkdir -p "${OUT_DIR}"

log() {
  printf '[demo-video] %s\n' "$1"
}

has_scheme() {
  local scheme_name="$1"
  xcodebuild -project "${ROOT_DIR}/SaneSales.xcodeproj" -list 2>/dev/null \
    | awk '/Schemes:/{flag=1;next} flag && NF{print $1}' \
    | grep -Fxq "${scheme_name}"
}

resolve_flag() {
  local value="$1"
  local default_enabled="$2"
  local normalized
  normalized="$(printf '%s' "${value}" | tr '[:upper:]' '[:lower:]')"
  case "${normalized}" in
    1|true|yes) echo 1 ;;
    0|false|no) echo 0 ;;
    auto) echo "${default_enabled}" ;;
    *) echo "${default_enabled}" ;;
  esac
}

device_udid_exact() {
  local device_name="$1"
  xcrun simctl list devices available --json \
    | jq -r --arg NAME "${device_name}" '.devices[][] | select(.name == $NAME) | .udid' \
    | head -n1
}

device_udid_first_matching() {
  local pattern="$1"
  xcrun simctl list devices available --json \
    | jq -r --arg PATTERN "${pattern}" '.devices[][] | select(.name | test($PATTERN; "i")) | .udid' \
    | head -n1
}

device_udid_auto() {
  local preferred_name="$1"
  local fallback_pattern="$2"
  local udid
  udid="$(device_udid_exact "${preferred_name}")"
  if [[ -z "${udid}" ]]; then
    udid="$(device_udid_first_matching "${fallback_pattern}")"
  fi
  echo "${udid}"
}

boot_device() {
  local udid="$1"
  xcrun simctl boot "${udid}" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "${udid}" -b
  xcrun simctl ui "${udid}" appearance dark >/dev/null 2>&1 || true
  xcrun simctl status_bar "${udid}" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --batteryState charged \
    --batteryLevel 100 >/dev/null 2>&1 || true
}

record_simulator_clip() {
  local udid="$1"
  local output_file="$2"
  local seconds="$3"
  xcrun simctl io "${udid}" recordVideo --codec h264 --force "${output_file}" >/dev/null 2>&1 &
  local rec_pid=$!
  sleep "${seconds}"
  kill -INT "${rec_pid}" >/dev/null 2>&1 || true
  wait "${rec_pid}" >/dev/null 2>&1 || true
  log "Saved ${output_file}"
}

capture_ios_clip() {
  local udid="$1"
  local bundle_id="$2"
  local output_file="$3"
  shift 3
  xcrun simctl terminate "${udid}" "${bundle_id}" >/dev/null 2>&1 || true
  xcrun simctl launch "${udid}" "${bundle_id}" -- "$@" >/dev/null
  sleep 1.8
  record_simulator_clip "${udid}" "${output_file}" "${CLIP_SECONDS}"
}

capture_watch_clip() {
  local udid="$1"
  local bundle_id="$2"
  local output_file="$3"
  shift 3
  xcrun simctl terminate "${udid}" "${bundle_id}" >/dev/null 2>&1 || true
  xcrun simctl launch "${udid}" "${bundle_id}" -- "$@" >/dev/null
  sleep 2.2
  record_simulator_clip "${udid}" "${output_file}" "${CLIP_SECONDS}"
}

prepare_mac_recording_env() {
  ORIGINAL_KEYBOARD_UI_MODE="$(defaults read -g AppleKeyboardUIMode 2>/dev/null || echo '__UNSET__')"
  defaults write -g AppleKeyboardUIMode -int 0 >/dev/null 2>&1 || true

  if [[ "${HIDE_DESKTOP_ICONS}" == "1" ]]; then
    ORIGINAL_CREATE_DESKTOP="$(defaults read com.apple.finder CreateDesktop 2>/dev/null || echo '__UNSET__')"
    defaults write com.apple.finder CreateDesktop -bool false >/dev/null 2>&1 || true
    killall Finder >/dev/null 2>&1 || true
    sleep 0.8
  fi
}

restore_mac_recording_env() {
  if [[ "${ORIGINAL_KEYBOARD_UI_MODE}" == "__UNSET__" ]]; then
    defaults delete -g AppleKeyboardUIMode >/dev/null 2>&1 || true
  else
    defaults write -g AppleKeyboardUIMode -int "${ORIGINAL_KEYBOARD_UI_MODE}" >/dev/null 2>&1 || true
  fi

  if [[ "${HIDE_DESKTOP_ICONS}" == "1" ]]; then
    if [[ "${ORIGINAL_CREATE_DESKTOP}" == "__UNSET__" ]]; then
      defaults delete com.apple.finder CreateDesktop >/dev/null 2>&1 || true
    else
      defaults write com.apple.finder CreateDesktop -bool "${ORIGINAL_CREATE_DESKTOP}" >/dev/null 2>&1 || true
    fi
    killall Finder >/dev/null 2>&1 || true
  fi
}

capture_mac_clip() {
  local app_path="$1"
  local output_file="$2"
  shift 2

  local x y width height
  IFS=',' read -r x y width height <<<"${MAC_RECT}"

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

  screencapture -x -v -V "${CLIP_SECONDS}" -R "${x},${y},${width},${height}" "${output_file}"
  log "Saved ${output_file}"
}

cleanup() {
  restore_mac_recording_env
  pkill -x SaneSales >/dev/null 2>&1 || true
}

trap cleanup EXIT

SUPPORTS_WATCH=0
if has_scheme "${WATCH_SCHEME}"; then
  SUPPORTS_WATCH=1
fi

WANT_IPHONE="$(resolve_flag "${CAPTURE_IPHONE}" 1)"
WANT_IPAD="$(resolve_flag "${CAPTURE_IPAD}" 1)"
WANT_WATCH="$(resolve_flag "${CAPTURE_WATCH}" "${SUPPORTS_WATCH}")"
WANT_MAC="$(resolve_flag "${CAPTURE_MAC}" 1)"

IOS_BUNDLE_ID=""
WATCH_BUNDLE_ID=""

if [[ "${WANT_IPHONE}" == "1" || "${WANT_IPAD}" == "1" ]]; then
  log "Building iOS app for simulator clips..."
  xcodebuild \
    -project "${ROOT_DIR}/SaneSales.xcodeproj" \
    -scheme "${IOS_SCHEME}" \
    -configuration Debug \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "${DERIVED_DATA}" \
    build >/dev/null

  IOS_APP="${DERIVED_DATA}/Build/Products/Debug-iphonesimulator/SaneSales.app"
  IOS_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${IOS_APP}/Info.plist")"

  if [[ "${WANT_IPHONE}" == "1" ]]; then
    IPHONE_UDID="$(device_udid_auto "${IPHONE_NAME}" "iphone")"
    if [[ -z "${IPHONE_UDID}" ]]; then
      echo "No iPhone simulator found." >&2
      exit 1
    fi
    boot_device "${IPHONE_UDID}"
    xcrun simctl install "${IPHONE_UDID}" "${IOS_APP}"
    capture_ios_clip "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/iphone-onboarding.mov" --force-onboarding
    capture_ios_clip "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/iphone-dashboard.mov" --demo --screenshot-tab dashboard
    capture_ios_clip "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/iphone-orders.mov" --demo --screenshot-tab orders
    capture_ios_clip "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/iphone-products.mov" --demo --screenshot-tab products
    capture_ios_clip "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/iphone-settings.mov" --demo --screenshot-tab settings
  fi

  if [[ "${WANT_IPAD}" == "1" ]]; then
    IPAD_UDID="$(device_udid_auto "${IPAD_NAME}" "ipad")"
    if [[ -z "${IPAD_UDID}" ]]; then
      echo "No iPad simulator found." >&2
      exit 1
    fi
    boot_device "${IPAD_UDID}"
    xcrun simctl install "${IPAD_UDID}" "${IOS_APP}"
    capture_ios_clip "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/ipad-onboarding.mov" --force-onboarding
    capture_ios_clip "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/ipad-dashboard.mov" --demo --screenshot-tab dashboard
    capture_ios_clip "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/ipad-orders.mov" --demo --screenshot-tab orders
    capture_ios_clip "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/ipad-products.mov" --demo --screenshot-tab products
    capture_ios_clip "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/ipad-settings.mov" --demo --screenshot-tab settings
  fi
fi

if [[ "${WANT_WATCH}" == "1" ]]; then
  WATCH_UDID="$(device_udid_auto "${WATCH_NAME}" "apple watch")"
  if [[ -z "${WATCH_UDID}" ]]; then
    if [[ "${REQUIRE_WATCH}" == "1" ]]; then
      echo "Watch capture requested but no watch simulator is available." >&2
      exit 1
    fi
    log "Skipping watch demo clips (no watch simulator available)."
  else
    log "Building watchOS app for simulator clips..."
    xcodebuild \
      -project "${ROOT_DIR}/SaneSales.xcodeproj" \
      -scheme "${WATCH_SCHEME}" \
      -configuration Debug \
      -destination "generic/platform=watchOS Simulator" \
      -derivedDataPath "${DERIVED_DATA}" \
      build >/dev/null

    WATCH_APP="${DERIVED_DATA}/Build/Products/Debug-watchsimulator/SaneSalesWatch.app"
    WATCH_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${WATCH_APP}/Info.plist")"
    boot_device "${WATCH_UDID}"
    xcrun simctl install "${WATCH_UDID}" "${WATCH_APP}"
    capture_watch_clip "${WATCH_UDID}" "${WATCH_BUNDLE_ID}" "${OUT_DIR}/watch-dashboard.mov" --demo
    capture_watch_clip "${WATCH_UDID}" "${WATCH_BUNDLE_ID}" "${OUT_DIR}/watch-recent.mov" --demo --focus-recent
  fi
fi

if [[ "${WANT_MAC}" == "1" ]]; then
  prepare_mac_recording_env
  log "Building macOS app for desktop clips..."
  xcodebuild \
    -project "${ROOT_DIR}/SaneSales.xcodeproj" \
    -scheme "${MAC_SCHEME}" \
    -configuration Debug \
    -destination "platform=macOS,arch=arm64" \
    -derivedDataPath "${DERIVED_DATA}" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build >/dev/null

  MAC_APP="${DERIVED_DATA}/Build/Products/Debug/SaneSales.app"
  capture_mac_clip "${MAC_APP}" "${OUT_DIR}/mac-onboarding.mov" --force-onboarding
  capture_mac_clip "${MAC_APP}" "${OUT_DIR}/mac-dashboard.mov" --demo --screenshot-tab dashboard
  capture_mac_clip "${MAC_APP}" "${OUT_DIR}/mac-orders.mov" --demo --screenshot-tab orders
  capture_mac_clip "${MAC_APP}" "${OUT_DIR}/mac-products.mov" --demo --screenshot-tab products
  capture_mac_clip "${MAC_APP}" "${OUT_DIR}/mac-settings.mov" --demo --screenshot-tab settings
fi

log "Done. Demo clips saved in ${OUT_DIR}"
