#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHOT_DIR="${1:-${ROOT_DIR}/Screenshots}"

if [[ ! -d "${SHOT_DIR}" ]]; then
  echo "Missing screenshot directory: ${SHOT_DIR}" >&2
  exit 1
fi

swift - "${SHOT_DIR}" <<'SWIFT'
import Foundation
import Vision
import AppKit

let shotDir = URL(fileURLWithPath: CommandLine.arguments[1])
let fm = FileManager.default
let manifestPath = shotDir.appendingPathComponent(".capture_manifest").path
let filePrefix = "appstore-"

let expectedByPlatform: [String: [String]] = [
  "iphone": [
    "\(filePrefix)01-onboarding-dark-6.7.png",
    "\(filePrefix)02-dashboard-dark-6.7.png",
    "\(filePrefix)03-orders-dark-6.7.png",
    "\(filePrefix)04-products-dark-6.7.png",
    "\(filePrefix)05-settings-dark-6.7.png"
  ],
  "ipad": [
    "\(filePrefix)01-onboarding-dark-ipad.png",
    "\(filePrefix)02-dashboard-dark-ipad.png",
    "\(filePrefix)03-orders-dark-ipad.png",
    "\(filePrefix)04-products-dark-ipad.png",
    "\(filePrefix)05-settings-dark-ipad.png"
  ],
  "mac": [
    "\(filePrefix)01-onboarding-dark-mac.png",
    "\(filePrefix)02-dashboard-dark-mac.png",
    "\(filePrefix)03-orders-dark-mac.png",
    "\(filePrefix)04-products-dark-mac.png",
    "\(filePrefix)05-settings-dark-mac.png"
  ],
  "watch": [
    "\(filePrefix)01-dashboard-dark-watch.png",
    "\(filePrefix)02-recent-dark-watch.png"
  ]
]

func expectedPlatforms() -> [String] {
  guard fm.fileExists(atPath: manifestPath),
        let text = try? String(contentsOfFile: manifestPath),
        let line = text.split(separator: "\n").first(where: { $0.hasPrefix("platforms=") }) else {
    return ["iphone", "ipad", "mac"]
  }

  let list = line.replacingOccurrences(of: "platforms=", with: "")
    .split(separator: ",")
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    .filter { !$0.isEmpty }
  if list.isEmpty { return ["iphone", "ipad", "mac"] }
  return list
}

let expectedPlatformsList = expectedPlatforms()
let expected = expectedPlatformsList.flatMap { expectedByPlatform[$0] ?? [] }

let blacklist = [
  "youtube", "premium", "forbes", "trump", "codex", "claude", "github", "watch?v", "babish", "create"
]

func tabHints(_ file: String) -> [String] {
  if file.contains("watch") && file.contains("dashboard") { return ["today", "sanesales", "month", "all time"] }
  if file.contains("watch") && file.contains("recent") { return ["recent", "sales", "sanesales"] }
  if file.contains("watch") { return ["today", "sanesales", "month"] }
  if file.contains("onboarding") { return ["demo", "connect", "try demo", "sanesales"] }
  if file.contains("dashboard") { return ["dashboard", "revenue"] }
  if file.contains("orders") { return ["orders", "order"] }
  if file.contains("products") { return ["products", "product"] }
  if file.contains("settings") { return ["settings", "provider", "stripe", "gumroad", "lemonsqueezy"] }
  if file.contains("recent") { return ["recent", "sales", "sanesales"] }
  return ["sanesales"]
}

func expectedSize(_ file: String) -> (Int, Int)? {
  if file.contains("-6.7") { return (1206, 2622) }
  if file.contains("-ipad") { return (2064, 2752) }
  if file.contains("-mac") { return (1280, 900) }
  return nil
}

func validateSize(_ file: String, _ actual: (Int, Int)) -> String? {
  if let exp = expectedSize(file), exp != actual {
    return "size_\(actual.0)x\(actual.1)_expected_\(exp.0)x\(exp.1)"
  }

  if file.contains("-watch") {
    let shortEdge = min(actual.0, actual.1)
    if shortEdge < 340 {
      return "watch_size_too_small_\(actual.0)x\(actual.1)"
    }
  }

  return nil
}

func ocr(_ imagePath: String) throws -> String {
  guard let image = NSImage(contentsOfFile: imagePath),
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let cg = rep.cgImage else {
    throw NSError(domain: "ocr", code: 1, userInfo: [NSLocalizedDescriptionKey: "image load failed"])
  }
  let req = VNRecognizeTextRequest()
  req.recognitionLevel = .accurate
  req.usesLanguageCorrection = true
  try VNImageRequestHandler(cgImage: cg).perform([req])
  return (req.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
}

func imageSize(_ path: String) -> (Int, Int)? {
  guard let image = NSImage(contentsOfFile: path),
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff) else { return nil }
  return (Int(rep.pixelsWide), Int(rep.pixelsHigh))
}

let now = Date()
let staleMinutes = 30

var failed = false
print("INFO|platforms|\(expectedPlatformsList.joined(separator: ","))")
print("STATUS|FILE|AGE_MIN|DETAILS")
for name in expected {
  let path = shotDir.appendingPathComponent(name).path
  guard fm.fileExists(atPath: path) else {
    print("FAIL|\(name)|NA|missing")
    failed = true
    continue
  }

  let attrs = try fm.attributesOfItem(atPath: path)
  let modified = (attrs[.modificationDate] as? Date) ?? Date(timeIntervalSince1970: 0)
  let ageMin = Int(now.timeIntervalSince(modified) / 60)

  var reasons: [String] = []
  if ageMin > staleMinutes { reasons.append("stale_file") }

  if let actual = imageSize(path), let sizeIssue = validateSize(name, actual) {
    reasons.append(sizeIssue)
  }

  do {
    let text = try ocr(path).lowercased()
    if text.count < 45 { reasons.append("low_ocr_signal") }
    if !tabHints(name).contains(where: { text.contains($0) }) {
      reasons.append("missing_expected_tab_content")
    }
    for bad in blacklist where text.contains(bad) {
      reasons.append("blacklist_\(bad)")
    }
  } catch {
    reasons.append("ocr_error")
  }

  if reasons.isEmpty {
    print("PASS|\(name)|\(ageMin)|ok")
  } else {
    failed = true
    print("FAIL|\(name)|\(ageMin)|\(reasons.joined(separator: ","))")
  }
}

exit(failed ? 2 : 0)
SWIFT
