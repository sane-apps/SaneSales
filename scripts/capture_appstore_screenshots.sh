#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/Screenshots"
DERIVED_DATA="${ROOT_DIR}/build/ScreenshotDerivedData"
IPHONE_NAME="${IPHONE_NAME:-iPhone 17 Pro}"
IPAD_NAME="${IPAD_NAME:-iPad Pro 13-inch (M5)}"
WATCH_NAME="${WATCH_NAME:-Apple Watch Series 10 (46mm)}"
WATCH_SCREENSHOT_MASK="${WATCH_SCREENSHOT_MASK:-black}"
IOS_SCHEME="${IOS_SCHEME:-SaneSalesIOS}"
WATCH_SCHEME="${WATCH_SCHEME:-SaneSalesWatch}"
NAME_PREFIX="${NAME_PREFIX:-appstore-}"
CAPTURE_IPHONE="${CAPTURE_IPHONE:-auto}"
CAPTURE_IPAD="${CAPTURE_IPAD:-auto}"
CAPTURE_WATCH="${CAPTURE_WATCH:-auto}"
CAPTURE_MAC="${CAPTURE_MAC:-1}"
REQUIRE_WATCH="${REQUIRE_WATCH:-0}"
MINI_HOST="${MINI_HOST:-mini}"
ALLOW_LOCAL_CAPTURE="${ALLOW_LOCAL_CAPTURE:-0}"
PRUNE_STALE_SCREENSHOTS="${PRUNE_STALE_SCREENSHOTS:-1}"

mkdir -p "${OUT_DIR}"
CAPTURE_MANIFEST="${OUT_DIR}/.capture_manifest"
captured_platforms=()
IOS_BUNDLE_ID=""
WATCH_BUNDLE_ID=""
IPHONE_UDID=""
IPAD_UDID=""
WATCH_UDID=""
ORIGINAL_KEYBOARD_UI_MODE="__UNSET__"

log() {
  printf '[screenshots] %s\n' "$1"
}

enforce_mini_first() {
  local host_short host_lc user_lc
  host_short="$(hostname -s 2>/dev/null || hostname)"
  host_lc="$(printf '%s' "${host_short}" | tr '[:upper:]' '[:lower:]')"
  user_lc="$(printf '%s' "${USER:-}" | tr '[:upper:]' '[:lower:]')"

  if [[ "${host_lc}" == *mini* ]] || [[ "${user_lc}" == "stephansmac" ]]; then
    return 0
  fi

  if [[ "${ALLOW_LOCAL_CAPTURE}" == "1" ]]; then
    log "ALLOW_LOCAL_CAPTURE=1 set; bypassing mini-first enforcement."
    return 0
  fi

  if command -v ssh >/dev/null 2>&1 && ssh -o BatchMode=yes -o ConnectTimeout=2 "${MINI_HOST}" true >/dev/null 2>&1; then
    echo "Refusing local screenshot capture while Mini is reachable." >&2
    echo "Run this on Mini instead:" >&2
    echo "  ssh ${MINI_HOST} 'cd ${ROOT_DIR} && bash scripts/capture_appstore_screenshots.sh'" >&2
    echo "Override once (only if Mini unavailable): ALLOW_LOCAL_CAPTURE=1 bash scripts/capture_appstore_screenshots.sh" >&2
    exit 2
  fi

  log "Mini unreachable; continuing locally."
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

capture_watch_shot() {
  local udid="$1"
  local bundle_id="$2"
  local output_file="$3"
  shift 3

  xcrun simctl terminate "${udid}" "${bundle_id}" >/dev/null 2>&1 || true
  xcrun simctl launch "${udid}" "${bundle_id}" -- "$@" >/dev/null
  sleep 3.0
  xcrun simctl io "${udid}" screenshot --mask "${WATCH_SCREENSHOT_MASK}" "${output_file}" >/dev/null
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

check_mac_capture_prereqs() {
  if ! osascript <<'OSA' >/dev/null 2>&1
tell application "System Events"
  name of first process whose frontmost is true
end tell
OSA
  then
    echo "macOS screenshot capture blocked: osascript lacks Assistive Access." >&2
    echo "Grant Accessibility permission to Terminal/Codex on the Mini and re-run." >&2
    return 1
  fi

  if ! screencapture -x /tmp/sanesales-screencap-preflight.png >/dev/null 2>&1; then
    echo "macOS screenshot capture blocked: screencapture cannot access display." >&2
    echo "Run this script from an active GUI session on the Mini (not headless SSH-only)." >&2
    return 1
  fi
  rm -f /tmp/sanesales-screencap-preflight.png
}

prepare_mac_focus_state() {
  ORIGINAL_KEYBOARD_UI_MODE="$(defaults read -g AppleKeyboardUIMode 2>/dev/null || echo '__UNSET__')"
  defaults write -g AppleKeyboardUIMode -int 0 >/dev/null 2>&1 || true
}

restore_mac_focus_state() {
  if [[ "${ORIGINAL_KEYBOARD_UI_MODE}" == "__UNSET__" ]]; then
    defaults delete -g AppleKeyboardUIMode >/dev/null 2>&1 || true
  else
    defaults write -g AppleKeyboardUIMode -int "${ORIGINAL_KEYBOARD_UI_MODE}" >/dev/null 2>&1 || true
  fi
}

SUPPORTS_WATCH=0
enforce_mini_first
if has_scheme "${WATCH_SCHEME}"; then
  SUPPORTS_WATCH=1
fi

WANT_IPHONE=0
WANT_IPAD=0
WANT_WATCH="$(resolve_flag "${CAPTURE_WATCH}" "${SUPPORTS_WATCH}")"
WANT_MAC="$(resolve_flag "${CAPTURE_MAC}" 1)"

if has_scheme "${IOS_SCHEME}"; then
  log "Building iOS app (simulator)..."
  xcodebuild \
    -project "${ROOT_DIR}/SaneSales.xcodeproj" \
    -scheme "${IOS_SCHEME}" \
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

  DEVICE_FAMILIES="$(plutil -extract UIDeviceFamily json -o - "${IOS_APP}/Info.plist" 2>/dev/null || echo '[]')"
  SUPPORTS_IPHONE="$(jq -r 'if index(1) != null then 1 else 0 end' <<<"${DEVICE_FAMILIES}")"
  SUPPORTS_IPAD="$(jq -r 'if index(2) != null then 1 else 0 end' <<<"${DEVICE_FAMILIES}")"
  WANT_IPHONE="$(resolve_flag "${CAPTURE_IPHONE}" "${SUPPORTS_IPHONE}")"
  WANT_IPAD="$(resolve_flag "${CAPTURE_IPAD}" "${SUPPORTS_IPAD}")"

  if [[ "${WANT_IPHONE}" == "1" ]]; then
    IPHONE_UDID="$(device_udid_auto "${IPHONE_NAME}" "iphone")"
    if [[ -z "${IPHONE_UDID}" ]]; then
      echo "Could not find an iPhone simulator (preferred: ${IPHONE_NAME})." >&2
      exit 1
    fi
    log "Booting iPhone simulator..."
    boot_device "${IPHONE_UDID}"
    log "Installing iOS app on iPhone simulator..."
    xcrun simctl install "${IPHONE_UDID}" "${IOS_APP}"
    log "Capturing iPhone screenshots..."
    capture_ios_shot "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}01-onboarding-dark-6.7.png" --force-onboarding
    capture_ios_shot "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}02-dashboard-dark-6.7.png" --demo --screenshot-tab dashboard
    capture_ios_shot "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}03-orders-dark-6.7.png" --demo --screenshot-tab orders
    capture_ios_shot "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}04-products-dark-6.7.png" --demo --screenshot-tab products
    capture_ios_shot "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}05-settings-dark-6.7.png" --demo --screenshot-tab settings
    captured_platforms+=("iphone")
  else
    log "Skipping iPhone screenshots (unsupported or CAPTURE_IPHONE=${CAPTURE_IPHONE})"
  fi

  if [[ "${WANT_IPAD}" == "1" ]]; then
    IPAD_UDID="$(device_udid_auto "${IPAD_NAME}" "ipad")"
    if [[ -z "${IPAD_UDID}" ]]; then
      echo "Could not find an iPad simulator (preferred: ${IPAD_NAME})." >&2
      exit 1
    fi
    log "Booting iPad simulator..."
    boot_device "${IPAD_UDID}"
    log "Installing iOS app on iPad simulator..."
    xcrun simctl install "${IPAD_UDID}" "${IOS_APP}"
    log "Capturing iPad screenshots..."
    capture_ios_shot "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}01-onboarding-dark-ipad.png" --force-onboarding
    capture_ios_shot "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}02-dashboard-dark-ipad.png" --demo --screenshot-tab dashboard
    capture_ios_shot "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}03-orders-dark-ipad.png" --demo --screenshot-tab orders
    capture_ios_shot "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}04-products-dark-ipad.png" --demo --screenshot-tab products
    capture_ios_shot "${IPAD_UDID}" "${IOS_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}05-settings-dark-ipad.png" --demo --screenshot-tab settings
    captured_platforms+=("ipad")
  else
    log "Skipping iPad screenshots (unsupported or CAPTURE_IPAD=${CAPTURE_IPAD})"
  fi
else
  log "Skipping iOS/iPad screenshots (scheme missing: ${IOS_SCHEME})"
fi

if [[ "${WANT_WATCH}" == "1" ]]; then
  WATCH_UDID="$(device_udid_auto "${WATCH_NAME}" "apple watch")"
  if [[ -z "${WATCH_UDID}" ]]; then
    if [[ "${REQUIRE_WATCH}" == "1" ]]; then
      echo "Watch capture requested but no watchOS simulator is available." >&2
      exit 1
    fi
    log "Skipping watch screenshots (no watchOS simulator available)."
  else
    log "Building watchOS app (simulator)..."
    xcodebuild \
      -project "${ROOT_DIR}/SaneSales.xcodeproj" \
      -scheme "${WATCH_SCHEME}" \
      -configuration Debug \
      -destination "generic/platform=watchOS Simulator" \
      -derivedDataPath "${DERIVED_DATA}" \
      build >/dev/null

    WATCH_APP="${DERIVED_DATA}/Build/Products/Debug-watchsimulator/SaneSalesWatch.app"
    if [[ ! -d "${WATCH_APP}" ]]; then
      echo "Missing built watchOS app at ${WATCH_APP}" >&2
      exit 1
    fi
    WATCH_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${WATCH_APP}/Info.plist")"

    log "Booting watch simulator..."
    boot_device "${WATCH_UDID}"
    log "Installing watchOS app on simulator..."
    xcrun simctl install "${WATCH_UDID}" "${WATCH_APP}"
    log "Capturing watchOS screenshots..."
    capture_watch_shot "${WATCH_UDID}" "${WATCH_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}01-dashboard-dark-watch.png" --demo
    capture_watch_shot "${WATCH_UDID}" "${WATCH_BUNDLE_ID}" "${OUT_DIR}/${NAME_PREFIX}02-recent-dark-watch.png" --demo --focus-recent
    captured_platforms+=("watch")
  fi
else
  log "Skipping watch screenshots (unsupported or CAPTURE_WATCH=${CAPTURE_WATCH})"
fi

if [[ "${WANT_MAC}" == "1" ]]; then
  prepare_mac_focus_state
  trap 'restore_mac_focus_state' EXIT
  check_mac_capture_prereqs
  log "Building macOS app..."
  xcodebuild \
    -project "${ROOT_DIR}/SaneSales.xcodeproj" \
    -scheme SaneSales \
    -configuration Debug \
    -destination "platform=macOS,arch=arm64" \
    -derivedDataPath "${DERIVED_DATA}" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build >/dev/null

  MAC_APP="${DERIVED_DATA}/Build/Products/Debug/SaneSales.app"
  if [[ ! -d "${MAC_APP}" ]]; then
    echo "Missing built macOS app at ${MAC_APP}" >&2
    exit 1
  fi

  log "Capturing macOS screenshots..."
  capture_mac_shot "${MAC_APP}" "${OUT_DIR}/${NAME_PREFIX}01-onboarding-dark-mac.png" --force-onboarding
  capture_mac_shot "${MAC_APP}" "${OUT_DIR}/${NAME_PREFIX}02-dashboard-dark-mac.png" --demo --screenshot-tab dashboard
  capture_mac_shot "${MAC_APP}" "${OUT_DIR}/${NAME_PREFIX}03-orders-dark-mac.png" --demo --screenshot-tab orders
  capture_mac_shot "${MAC_APP}" "${OUT_DIR}/${NAME_PREFIX}04-products-dark-mac.png" --demo --screenshot-tab products
  capture_mac_shot "${MAC_APP}" "${OUT_DIR}/${NAME_PREFIX}05-settings-dark-mac.png" --demo --screenshot-tab settings
  captured_platforms+=("mac")
  restore_mac_focus_state
  trap - EXIT
else
  log "Skipping macOS screenshots (CAPTURE_MAC=${CAPTURE_MAC})"
fi

pkill -x SaneSales >/dev/null 2>&1 || true
if [[ -n "${IOS_BUNDLE_ID}" && -n "${IPHONE_UDID}" ]]; then
  xcrun simctl terminate "${IPHONE_UDID}" "${IOS_BUNDLE_ID}" >/dev/null 2>&1 || true
fi
if [[ -n "${IOS_BUNDLE_ID}" && -n "${IPAD_UDID}" ]]; then
  xcrun simctl terminate "${IPAD_UDID}" "${IOS_BUNDLE_ID}" >/dev/null 2>&1 || true
fi
if [[ -n "${WATCH_BUNDLE_ID}" && -n "${WATCH_UDID}" ]]; then
  xcrun simctl terminate "${WATCH_UDID}" "${WATCH_BUNDLE_ID}" >/dev/null 2>&1 || true
fi

{
  echo "platforms=$(IFS=,; echo "${captured_platforms[*]}")"
  echo "generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
} > "${CAPTURE_MANIFEST}"

if [[ "${PRUNE_STALE_SCREENSHOTS}" == "1" ]]; then
  while IFS= read -r -d '' stale_file; do
    if command -v trash >/dev/null 2>&1; then
      trash "${stale_file}"
    else
      rm -f "${stale_file}"
    fi
    log "Pruned stale screenshot: ${stale_file}"
  done < <(find "${OUT_DIR}" -maxdepth 1 -type f -name '*.png' ! -name "${NAME_PREFIX}*" -print0)
fi

log "Done. Fresh screenshots are in ${OUT_DIR}"
log "Capture manifest: ${CAPTURE_MANIFEST}"
