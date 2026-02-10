import AppKit
import SwiftUI

@MainActor
final class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private weak var salesManager: SalesManager?
    private var showRevenue: Bool

    init(salesManager: SalesManager, showRevenue: Bool) {
        self.salesManager = salesManager
        self.showRevenue = showRevenue
        super.init()
        setupMenuBar()
    }

    func tearDown() {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }

    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = item.button {
            // Prefer a branded coin image (template) so it matches light/dark menu bar automatically.
            let image =
                NSImage(named: "MenuBarIcon")
                ?? NSImage(systemSymbolName: SFSymbols.coin, accessibilityDescription: "SaneSales")
                ?? NSImage(systemSymbolName: SFSymbols.coinFallback, accessibilityDescription: "SaneSales")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(statusItemClicked)

            // Set initial title
            updateTitle()
        }

        statusItem = item
    }

    func updateTitle() {
        guard let button = statusItem?.button else { return }

        if showRevenue, let manager = salesManager {
            let revenue = Double(manager.metrics.todayRevenue) / 100.0
            button.title = String(format: " $%.2f", revenue)
        } else {
            button.title = ""
        }
    }

    func setShowRevenue(_ show: Bool) {
        showRevenue = show
        updateTitle()
    }

    @objc private func statusItemClicked() {
        // Activate the app and bring the main window to front
        NSApp.activate(ignoringOtherApps: true)

        // Find the main window and make it key
        if let mainWindow = NSApp.windows.first(where: { $0.isVisible && !$0.isSheet }) {
            mainWindow.makeKeyAndOrderFront(nil)
        }
    }
}
