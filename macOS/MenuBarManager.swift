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
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let image = NSImage(systemSymbolName: SFSymbols.coin, accessibilityDescription: "SaneSales")?
                .withSymbolConfiguration(config)
                ?? NSImage(systemSymbolName: SFSymbols.coinFallback, accessibilityDescription: "SaneSales")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])

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

    // MARK: - Click Handling

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            activateWindow()
        }
    }

    private func activateWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if let mainWindow = NSApp.windows.first(where: {
            !$0.isSheet && $0.className != "NSStatusBarWindow"
        }) {
            mainWindow.makeKeyAndOrderFront(nil)
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Show SaneSales", action: #selector(menuShowWindow), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(.separator())

        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(menuRefresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let updateItem = NSMenuItem(title: "Check for Updates\u{2026}", action: #selector(menuCheckForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        let settingsItem = NSMenuItem(title: "Settings\u{2026}", action: #selector(menuOpenSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit SaneSales", action: #selector(menuQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        // Clear menu so left-click still activates the window
        statusItem?.menu = nil
    }

    // MARK: - Menu Actions

    @objc private func menuShowWindow() {
        activateWindow()
    }

    @objc private func menuRefresh() {
        guard let manager = salesManager else { return }
        Task { await manager.refresh() }
    }

    @objc private func menuCheckForUpdates() {
        UpdateService.shared.checkForUpdates()
    }

    @objc private func menuOpenSettings() {
        activateWindow()
        // Switch to Settings tab after window is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NotificationCenter.default.post(name: .showSettingsTab, object: nil)
        }
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let showSettingsTab = Notification.Name("com.sanesales.showSettingsTab")
}
