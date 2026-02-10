import SwiftUI

#if os(macOS)
    @main
    struct SaneSalesMacApp: App {
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
                        setupMenuBar()
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

            Settings {
                SettingsView()
                    .environment(manager)
            }
        }

        private func setupMenuBar() {
            if showInMenuBar {
                menuBarManager = MenuBarManager(salesManager: manager, showRevenue: showRevenueInMenuBar)
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
