import SwiftUI

#if os(macOS)
    class SaneSalesAppDelegate: NSObject, NSApplicationDelegate {
        weak var salesManager: SalesManager?

        func applicationDockMenu(_: NSApplication) -> NSMenu? {
            let menu = NSMenu()

            let refreshItem = NSMenuItem(title: "Refresh", action: #selector(dockRefresh), keyEquivalent: "")
            refreshItem.target = self
            menu.addItem(refreshItem)

            menu.addItem(.separator())

            let settingsItem = NSMenuItem(title: "Settings\u{2026}", action: #selector(dockOpenSettings), keyEquivalent: "")
            settingsItem.target = self
            menu.addItem(settingsItem)

            return menu
        }

        @objc private func dockRefresh() {
            guard let manager = salesManager else { return }
            Task { @MainActor in
                await manager.refresh()
            }
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

        // Window transparency is now handled by WindowTransparencyAccessor in SaneBackground
    }

    // Reuse ContentView from iOS/ (shared code)
#endif
