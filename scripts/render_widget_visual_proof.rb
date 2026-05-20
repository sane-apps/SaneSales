#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

project_root = File.expand_path('..', __dir__)
output_dir = File.expand_path(ARGV[0] || File.join(project_root, 'outputs', 'customer-ui', 'widget'), project_root)
widget_source_path = File.join(project_root, 'Widgets', 'SalesWidget.swift')
source = File.read(widget_source_path)

source = source.sub(/\Aimport SwiftUI\nimport WidgetKit\n\n/, '')
source = source.sub(/@main\nstruct SalesWidgetBundle: WidgetBundle \{\n(?:.|\n)*?^}\n\n/, '')
source = source.sub(/struct SalesWidget: Widget \{\n(?:.|\n)*?^}\n\n/, '')
source = source.sub('@Environment(\\.widgetFamily) var family', 'let family: WidgetFamily')

renderer_source = <<~SWIFT
  import AppKit
  import SwiftUI
  import WidgetKit

  #{source}

  @MainActor
  private func proofCard<Content: View>(
      _ title: String,
      width: CGFloat,
      height: CGFloat,
      @ViewBuilder content: () -> Content
  ) -> some View {
      VStack(alignment: .leading, spacing: 8) {
          Text(title)
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(.white)
          ZStack {
              RoundedRectangle(cornerRadius: 16, style: .continuous)
                  .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
              content()
                  .padding(10)
          }
          .frame(width: width, height: height)
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      }
  }

  @MainActor
  private func writePNG<Content: View>(_ path: URL, content: Content) throws {
      let renderer = ImageRenderer(content: content)
      renderer.scale = 2
      guard let image = renderer.nsImage,
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let png = bitmap.representation(using: .png, properties: [:]) else {
          throw NSError(domain: "SaneSalesWidgetProof", code: 1)
      }
      try png.write(to: path)
  }

  @main
  struct SaneSalesWidgetProofRenderer {
      @MainActor
      static func main() throws {
          let outputDir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
          try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
          let paid = SalesWidgetEntry(
              date: Date(timeIntervalSince1970: 1_779_292_800),
              todayRevenue: 42750,
              todayOrders: 18,
              monthRevenue: 829500,
              currency: "USD"
          )
          let locked = SalesWidgetEntry.locked
          let sheet = VStack(alignment: .leading, spacing: 18) {
              Text("SaneSales WidgetKit Proof")
                  .font(.system(size: 24, weight: .bold))
                  .foregroundStyle(.white)
              Text("Actual macOS SalesWidgetView renders: paid data and locked Pro states")
                  .font(.system(size: 15, weight: .medium))
                  .foregroundStyle(.white.opacity(0.92))
              HStack(alignment: .top, spacing: 18) {
                  proofCard("System Small - Paid", width: 170, height: 170) {
                      SalesWidgetView(entry: paid, family: .systemSmall)
                  }
                  proofCard("System Medium - Paid", width: 360, height: 170) {
                      SalesWidgetView(entry: paid, family: .systemMedium)
                  }
                  proofCard("System Small - Locked", width: 170, height: 170) {
                      SalesWidgetView(entry: locked, family: .systemSmall)
                  }
              }
          }
          .padding(24)
          .frame(width: 900, height: 340, alignment: .topLeading)
          .background(Color(red: 0.02, green: 0.025, blue: 0.035))
          .environment(\\.colorScheme, .dark)

          try writePNG(outputDir.appendingPathComponent("widget-proof-contact-sheet.png"), content: sheet)
      }
  }
SWIFT

Dir.mktmpdir('sanesales-widget-proof') do |dir|
  renderer_path = File.join(dir, 'WidgetProofRenderer.swift')
  renderer_bin = File.join(dir, 'WidgetProofRenderer')
  File.write(renderer_path, renderer_source)
  FileUtils.mkdir_p(output_dir)
  output, status = Open3.capture2e('xcrun', 'swiftc', '-parse-as-library', renderer_path, '-o', renderer_bin)
  unless status.success?
    warn output
    exit status.exitstatus || 1
  end

  output, status = Open3.capture2e(renderer_bin, output_dir)
  unless status.success?
    warn output
    exit status.exitstatus || 1
  end
end

puts File.join(output_dir, 'widget-proof-contact-sheet.png')
