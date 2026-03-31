import SaneUI
import SwiftUI
#if !APP_STORE
    import Sparkle
#endif

#if os(macOS)

    @MainActor
    final class WindowActionStorage {
        static let shared = WindowActionStorage()
        var openWindow: ((String) -> Void)?
        weak var mainWindow: NSWindow?

        func capture(_ action: OpenWindowAction) {
            openWindow = { id in
                action(id: id)
            }
        }

        func captureMainWindow(_ window: NSWindow?) {
            guard let window, window.canBecomeMain, !window.isSheet else { return }
            mainWindow = window
        }

        func showMainWindow() {
            let candidateWindow = mainWindow ?? NSApp.windows.first(where: {
                $0.canBecomeMain &&
                    !$0.isSheet &&
                    ($0.identifier?.rawValue.contains("main") == true || !$0.title.isEmpty)
            })

            if let candidateWindow {
                if candidateWindow.isMiniaturized {
                    candidateWindow.deminiaturize(nil)
                }
                candidateWindow.makeKeyAndOrderFront(nil)
                mainWindow = candidateWindow
            } else {
                openWindow?("main")
            }

            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Update Service

    #if !APP_STORE
        @MainActor
        class UpdateService: NSObject, ObservableObject {
            static let shared = UpdateService()
            private var updaterController: SPUStandardUpdaterController?

            override init() {
                super.init()
                updaterController = SPUStandardUpdaterController(
                    startingUpdater: true,
                    updaterDelegate: nil,
                    userDriverDelegate: nil
                )
                normalizeUpdateCheckFrequency()
            }

            func checkForUpdates() {
                updaterController?.checkForUpdates(nil)
            }

            var automaticallyChecksForUpdates: Bool {
                get {
                    updaterController?.updater.automaticallyChecksForUpdates ?? false
                }
                set {
                    updaterController?.updater.automaticallyChecksForUpdates = newValue
                }
            }

            var updateCheckFrequency: SaneSparkleCheckFrequency {
                get {
                    let interval = updaterController?.updater.updateCheckInterval ?? SaneSparkleCheckFrequency.daily.interval
                    return SaneSparkleCheckFrequency.resolve(updateCheckInterval: interval)
                }
                set {
                    updaterController?.updater.updateCheckInterval = newValue.interval
                }
            }

            private func normalizeUpdateCheckFrequency() {
                guard let updater = updaterController?.updater else { return }
                updater.updateCheckInterval = SaneSparkleCheckFrequency.normalizedInterval(from: updater.updateCheckInterval)
            }
        }
    #endif

    // MARK: - App Delegate

    @MainActor
    class SaneSalesAppDelegate: NSObject, NSApplicationDelegate {
        weak var salesManager: SalesManager?

        func applicationDidFinishLaunching(_: Notification) {
            NSApp.appearance = NSAppearance(named: .darkAqua)
            #if !DEBUG && !APP_STORE
                if SaneAppMover.moveToApplicationsFolderIfNeeded(prompt: .init(
                    messageText: "Move to Applications?",
                    informativeText: "{appName} works best from your Applications folder. Move it there now? You may be asked for your password.",
                    moveButtonTitle: "Move to Applications",
                    cancelButtonTitle: "Not Now"
                )) { return }
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

            #if !APP_STORE
                let updateItem = NSMenuItem(title: "Check for Updates\u{2026}", action: #selector(dockCheckForUpdates), keyEquivalent: "")
                updateItem.target = self
                menu.addItem(updateItem)
            #endif

            let settingsItem = NSMenuItem(title: "Settings\u{2026}", action: #selector(dockOpenSettings), keyEquivalent: "")
            settingsItem.target = self
            menu.addItem(settingsItem)

            return menu
        }

        @objc private func dockShowWindow() {
            WindowActionStorage.shared.showMainWindow()
        }

        @objc private func dockRefresh() {
            guard let manager = salesManager else { return }
            Task {
                await manager.refresh()
            }
        }

        #if !APP_STORE
            @objc private func dockCheckForUpdates() {
                UpdateService.shared.checkForUpdates()
            }
        #endif

        @objc private func dockOpenSettings() {
            WindowActionStorage.shared.showMainWindow()
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
        #if APP_STORE
            @State private var licenseService = LicenseService(
                appName: "SaneSales",
                purchaseBackend: .appStore(productID: "com.sanesales.app.pro.unlock.v2")
            )
        #else
            @State private var licenseService = LicenseService(
                appName: "SaneSales",
                checkoutURL: LicenseService.directCheckoutURL(appSlug: "sanesales"),
                directCopy: LicenseService.DirectCopy.saneSales
            )
        #endif

        @AppStorage("showInMenuBar") private var showInMenuBar = true
        @AppStorage("showInDock") private var showInDock = SaneBackgroundAppDefaults.showDockIcon
        @AppStorage("showRevenueInMenuBar") private var showRevenueInMenuBar = false
        @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

        init() {
            // Defer Dock/accessory policy until NSApp exists.
            let showDock = Self.defaultShowDockPreference()
            SaneActivationPolicy.applyInitialPolicy(showDockIcon: showDock)
        }

        nonisolated static func defaultShowDockPreference(
            userDefaults: UserDefaults = .standard
        ) -> Bool {
            userDefaults.object(forKey: "showInDock") as? Bool ?? SaneBackgroundAppDefaults.showDockIcon
        }

        var body: some Scene {
            WindowGroup(id: "main") {
                ContentView()
                    .environment(manager)
                    .environment(licenseService)
                    .modifier(WindowActionCapture())
                    .background(MainWindowCaptureView())
                    .preferredColorScheme(.dark)
                    .frame(minWidth: 600, minHeight: 400)
                    .onAppear {
                        appDelegate.salesManager = manager
                        licenseService.checkCachedLicense()

                        // Sync license state into manager for Pro gating
                        manager.isPro = licenseService.isPro

                        // Fire launch event based on tier
                        let tier = licenseService.isPro ? "pro" : "free"
                        let isFirstLaunch = !hasSeenWelcome
                        if SaneBackgroundAppDefaults.launchAtLogin {
                            _ = SaneLoginItemPolicy.enableByDefaultIfNeeded(isFirstLaunch: isFirstLaunch)
                        }
                        Task.detached {
                            await EventTracker.log("app_launch_\(tier)", app: "sanesales")
                            if isFirstLaunch, tier == "free" {
                                await EventTracker.log("new_free_user", app: "sanesales")
                            }
                        }

                        // Only set up menu bar if Pro
                        if licenseService.isPro {
                            setupMenuBar()
                        }
                    }
                    .task {
                        if CommandLine.arguments.contains("--demo") ||
                            UserDefaults.standard.bool(forKey: "loadDemoData") {
                            DemoData.loadInto(
                                manager: manager,
                                connectedProviders: manager.demoConnectedProviders()
                            )
                        }
                    }
                    .sheet(isPresented: Binding(
                        get: { !hasSeenWelcome },
                        set: { isShowing in
                            if !isShowing {
                                hasSeenWelcome = true
                                // Set up menu bar now that welcome is done, if Pro
                                if licenseService.isPro, showInMenuBar, menuBarManager == nil {
                                    menuBarManager = MenuBarManager(
                                        salesManager: manager,
                                        showRevenue: showRevenueInMenuBar
                                    )
                                }
                            }
                        }
                    )) {
                        WelcomeGateView(
                            appName: "SaneSales",
                            appIcon: "dollarsign.circle.fill",
                            freeFeatures: [
                                (icon: "link", text: "Connect any sales provider"),
                                (icon: "clock.badge.checkmark", text: "Live daily sales dashboard"),
                                (icon: "shippingbox", text: "Orders today and full product catalog"),
                                (icon: "play.circle", text: "Demo mode to explore")
                            ],
                            proFeatures: [
                                (icon: "checkmark", text: "Everything in Basic, plus:"),
                                (icon: "chart.line.uptrend.xyaxis", text: "7-day, 30-day, and all-time trends"),
                                (icon: "list.bullet.rectangle", text: "Full order history"),
                                (icon: "tablecells", text: "CSV export"),
                                (icon: "chart.pie", text: "Deeper product comparisons"),
                                (icon: "menubar.rectangle", text: "Menu bar quick glance"),
                                (icon: "widget.small", text: "Desktop widgets")
                            ],
                            licenseService: licenseService,
                            secondaryCompletionActionLabel: "Try Demo Data",
                            secondaryCompletionAccessibilityIdentifier: "onboarding.demoButton",
                            onSecondaryCompletion: {
                                manager.enableDemoMode()
                            }
                        )
                    }
            }
            .defaultSize(width: 800, height: 600)
            .onChange(of: showInMenuBar) { _, newValue in
                handleMenuBarToggle(newValue)
            }
            .onChange(of: showInDock) { _, newValue in
                SaneActivationPolicy.applyPolicy(showDockIcon: newValue)
            }
            .onChange(of: showRevenueInMenuBar) { _, newValue in
                menuBarManager?.setShowRevenue(newValue)
            }
            .onChange(of: manager.metrics) { _, _ in
                menuBarManager?.updateTitle()
            }
            .onChange(of: licenseService.isPro) { _, isPro in
                manager.isPro = isPro
                if isPro, showInMenuBar, menuBarManager == nil {
                    menuBarManager = MenuBarManager(salesManager: manager, showRevenue: showRevenueInMenuBar)
                } else if !isPro {
                    menuBarManager?.tearDown()
                    menuBarManager = nil
                }
            }
            .commands {
                CommandGroup(replacing: .appSettings) {
                    Button("Settings\u{2026}") {
                        showSettingsTab()
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
                #if !APP_STORE
                    CommandGroup(after: .appInfo) {
                        Button("Check for Updates\u{2026}") {
                            UpdateService.shared.checkForUpdates()
                        }
                    }
                #endif
            }
        }

        private func setupMenuBar() {
            guard showInMenuBar, menuBarManager == nil else { return }
            menuBarManager = MenuBarManager(salesManager: manager, showRevenue: showRevenueInMenuBar)
        }

        private func showSettingsTab() {
            WindowActionStorage.shared.showMainWindow()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .showSettingsTab, object: nil)
            }
        }

        private func handleMenuBarToggle(_ show: Bool) {
            guard licenseService.isPro else { return }
            if show {
                menuBarManager = MenuBarManager(salesManager: manager, showRevenue: showRevenueInMenuBar)
            } else {
                menuBarManager?.tearDown()
                menuBarManager = nil
            }
        }
    }

    struct WindowActionCapture: ViewModifier {
        @Environment(\.openWindow) private var openWindow

        func body(content: Content) -> some View {
            content
                .onAppear {
                    WindowActionStorage.shared.capture(openWindow)
                }
        }
    }

    struct MainWindowCaptureView: NSViewRepresentable {
        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async {
                WindowActionStorage.shared.captureMainWindow(view.window)
            }
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {
            DispatchQueue.main.async {
                WindowActionStorage.shared.captureMainWindow(nsView.window)
            }
        }
    }

    // Reuse ContentView from iOS/ (shared code)
#endif
