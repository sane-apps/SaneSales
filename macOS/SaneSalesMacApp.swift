import SwiftUI
#if !APP_STORE
    import Sparkle
#endif

#if os(macOS)

    // MARK: - Update Service

    @MainActor
    class UpdateService: NSObject, ObservableObject {
        static let shared = UpdateService()

        #if !APP_STORE
            private var updaterController: SPUStandardUpdaterController?
        #endif

        override init() {
            super.init()
            #if !APP_STORE
                updaterController = SPUStandardUpdaterController(
                    startingUpdater: true,
                    updaterDelegate: nil,
                    userDriverDelegate: nil
                )
            #endif
        }

        func checkForUpdates() {
            #if !APP_STORE
                updaterController?.checkForUpdates(nil)
            #endif
        }

        var automaticallyChecksForUpdates: Bool {
            get {
                #if !APP_STORE
                    return updaterController?.updater.automaticallyChecksForUpdates ?? false
                #else
                    return false
                #endif
            }
            set {
                #if !APP_STORE
                    updaterController?.updater.automaticallyChecksForUpdates = newValue
                #endif
            }
        }
    }

    // MARK: - App Delegate

    @MainActor
    class SaneSalesAppDelegate: NSObject, NSApplicationDelegate {
        weak var salesManager: SalesManager?

        func applicationDidFinishLaunching(_: Notification) {
            #if !DEBUG
                SaneAppMover.moveToApplicationsFolderIfNeeded()
            #endif
        }

        func applicationDockMenu(_: NSApplication) -> NSMenu? {
            let menu = NSMenu()

            let showItem = NSMenuItem(title: "Show SaneSales", action: #selector(dockShowWindow), keyEquivalent: "")
            showItem.target = self
            menu.addItem(showItem)

            let refreshItem = NSMenuItem(title: "Refresh", action: #selector(dockRefresh), keyEquivalent: "")
            refreshItem.target = self
            menu.addItem(refreshItem)

            menu.addItem(.separator())

            let updateItem = NSMenuItem(title: "Check for Updates\u{2026}", action: #selector(dockCheckForUpdates), keyEquivalent: "")
            updateItem.target = self
            menu.addItem(updateItem)

            let settingsItem = NSMenuItem(title: "Settings\u{2026}", action: #selector(dockOpenSettings), keyEquivalent: "")
            settingsItem.target = self
            menu.addItem(settingsItem)

            return menu
        }

        @objc private func dockShowWindow() {
            NSApp.activate(ignoringOtherApps: true)
            if let mainWindow = NSApp.windows.first(where: {
                !$0.isSheet && $0.className != "NSStatusBarWindow"
            }) {
                mainWindow.makeKeyAndOrderFront(nil)
            }
        }

        @objc private func dockRefresh() {
            guard let manager = salesManager else { return }
            Task {
                await manager.refresh()
            }
        }

        @objc private func dockCheckForUpdates() {
            UpdateService.shared.checkForUpdates()
        }

        @objc private func dockOpenSettings() {
            NSApp.activate(ignoringOtherApps: true)
            if let mainWindow = NSApp.windows.first(where: {
                !$0.isSheet && $0.className != "NSStatusBarWindow"
            }) {
                mainWindow.makeKeyAndOrderFront(nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .showSettingsTab, object: nil)
            }
        }
    }

    // MARK: - App

    @main
    struct SaneSalesMacApp: App {
        @NSApplicationDelegateAdaptor(SaneSalesAppDelegate.self) private var appDelegate
        @State private var manager = SalesManager()
        @State private var menuBarManager: MenuBarManager?

        @AppStorage("showInMenuBar") private var showInMenuBar = true
        @AppStorage("showInDock") private var showInDock = true
        @AppStorage("showRevenueInMenuBar") private var showRevenueInMenuBar = false

        init() {
            // Apply initial activation policy
            let showDock = UserDefaults.standard.object(forKey: "showInDock") as? Bool ?? true
            ActivationPolicyManager.applyPolicy(showDockIcon: showDock)
        }

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environment(manager)
                    .frame(minWidth: 600, minHeight: 400)
                    .onAppear {
                        appDelegate.salesManager = manager
                        setupMenuBar()
                    }
                    .task {
                        #if DEBUG
                            if CommandLine.arguments.contains("--demo") ||
                                UserDefaults.standard.bool(forKey: "loadDemoData") {
                                DemoData.loadInto(manager: manager)
                            }
                        #endif
                    }
            }
            .defaultSize(width: 800, height: 600)
            .onChange(of: showInMenuBar) { _, newValue in
                handleMenuBarToggle(newValue)
            }
            .onChange(of: showInDock) { _, newValue in
                ActivationPolicyManager.applyPolicy(showDockIcon: newValue)
            }
            .onChange(of: showRevenueInMenuBar) { _, newValue in
                menuBarManager?.setShowRevenue(newValue)
            }
            .onChange(of: manager.metrics) { _, _ in
                // Update menu bar when metrics change
                menuBarManager?.updateTitle()
            }
            .commands {
                CommandGroup(replacing: .appSettings) {
                    Button("Settings\u{2026}") {
                        showSettingsTab()
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
                CommandGroup(after: .appInfo) {
                    Button("Check for Updates\u{2026}") {
                        UpdateService.shared.checkForUpdates()
                    }
                }
            }
        }

        private func setupMenuBar() {
            if showInMenuBar {
                menuBarManager = MenuBarManager(salesManager: manager, showRevenue: showRevenueInMenuBar)
            }
        }

        private func showSettingsTab() {
            NSApp.activate(ignoringOtherApps: true)
            if let mainWindow = NSApp.windows.first(where: {
                !$0.isSheet && $0.className != "NSStatusBarWindow"
            }) {
                mainWindow.makeKeyAndOrderFront(nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .showSettingsTab, object: nil)
            }
        }

        private func handleMenuBarToggle(_ show: Bool) {
            if show {
                menuBarManager = MenuBarManager(salesManager: manager, showRevenue: showRevenueInMenuBar)
            } else {
                menuBarManager?.tearDown()
                menuBarManager = nil
            }
        }
    }

    // Reuse ContentView from iOS/ (shared code)
#endif
