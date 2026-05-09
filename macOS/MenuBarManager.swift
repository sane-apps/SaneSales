import AppKit
import SaneUI
import SwiftUI

@MainActor
enum SaneSalesContextMenu {
    struct Actions {
        let open: Selector
        let refresh: Selector
        let settings: Selector
        let license: Selector
        let checkForUpdates: Selector?
        let about: Selector
        let quit: Selector
    }

    static func make(
        target: AnyObject,
        actions: Actions,
        configureCheckForUpdates: ((NSMenuItem) -> Void)?
    ) -> NSMenu {
        let menu = NSMenu()

        menu.addItem(SaneStandardMenu.openAppItem(
            appName: "SaneSales",
            target: target,
            action: actions.open
        ))

        menu.addItem(SaneStandardMenu.item(
            title: "Refresh",
            target: target,
            action: actions.refresh
        ))

        menu.addItem(.separator())

        SaneStandardMenu.addCoreUtilityItems(
            to: menu,
            appName: "SaneSales",
            target: target,
            settingsAction: actions.settings,
            licenseAction: actions.license,
            checkForUpdatesAction: actions.checkForUpdates,
            configureCheckForUpdates: configureCheckForUpdates,
            aboutAndBugReportAction: actions.about,
            quitAction: actions.quit,
            settingsKeyEquivalent: ""
        )

        return menu
    }
}

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
        WindowActionStorage.shared.showMainWindow()
    }

    private func showMenu() {
        let menu = SaneSalesContextMenu.make(
            target: self,
            actions: .init(
                open: #selector(menuShowWindow),
                refresh: #selector(menuRefresh),
                settings: #selector(menuOpenSettings),
                license: #selector(menuOpenLicense),
                checkForUpdates: directUpdateAction,
                about: #selector(menuOpenAbout),
                quit: #selector(menuQuit)
            ),
            configureCheckForUpdates: directUpdateConfigurator,
        )

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        // Clear menu so left-click still activates the window
        statusItem?.menu = nil
    }

    // MARK: - Menu Actions

    @objc private func menuShowWindow() {
        WindowActionStorage.shared.showMainWindow()
    }

    @objc private func menuRefresh() {
        guard let manager = salesManager else { return }
        Task { await manager.refresh() }
    }

    #if !APP_STORE
        private var directUpdateAction: Selector? {
            #selector(menuCheckForUpdates)
        }

        private var directUpdateConfigurator: ((NSMenuItem) -> Void)? {
            { [weak self] item in
                self?.configureUpdateItem(item)
            }
        }

        private func configureUpdateItem(_ item: NSMenuItem) {
            let updateService = UpdateService.shared
            item.isEnabled = updateService.isUpdateChannelEnabled
            item.toolTip = updateService.isUpdateChannelEnabled ? nil : updateService.updateUnavailableStatus
        }

        @objc private func menuCheckForUpdates() {
            UpdateService.shared.checkForUpdates()
        }
    #else
        private var directUpdateAction: Selector? { nil }
        private var directUpdateConfigurator: ((NSMenuItem) -> Void)? { nil }
    #endif

    @objc private func menuOpenSettings() {
        SettingsTabNavigationStorage.shared.requestShowSettingsTab()
    }

    @objc private func menuOpenLicense() {
        SettingsTabNavigationStorage.shared.requestShowSettingsTab(.license)
    }

    @objc private func menuOpenAbout() {
        SettingsTabNavigationStorage.shared.requestShowSettingsTab(.about)
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }
}
