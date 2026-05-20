import AppKit
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

    @MainActor
    final class SettingsTabNavigationStorage {
        static let shared = SettingsTabNavigationStorage()
        private var pendingShowSettingsTab: SaneSalesSettingsTab?

        func requestShowSettingsTab(_ tab: SaneSalesSettingsTab = .general) {
            pendingShowSettingsTab = tab
            WindowActionStorage.shared.showMainWindow()

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .showSettingsTab, object: tab)
            }
        }

        func consumePendingRequest() -> SaneSalesSettingsTab? {
            let tab = pendingShowSettingsTab
            pendingShowSettingsTab = nil
            return tab
        }

        func markRequestHandled() {
            pendingShowSettingsTab = nil
        }
    }

    // MARK: - Update Service

    #if !APP_STORE
        @MainActor
        class UpdateService: NSObject, ObservableObject {
            static let shared = UpdateService()
            nonisolated static let releaseBundleIdentifier = "com.sanesales.app"
            private var updaterController: SPUStandardUpdaterController?
            private let updateEligibility: SaneUpdateEligibility

            override init() {
                updateEligibility = Self.sparkleUpdateEligibility(
                    bundleIdentifier: Bundle.main.bundleIdentifier,
                    bundlePath: Bundle.main.bundlePath
                )
                super.init()
                guard updateEligibility.canUseInAppUpdates else {
                    return
                }
                updaterController = SPUStandardUpdaterController(
                    startingUpdater: true,
                    updaterDelegate: nil,
                    userDriverDelegate: nil
                )
                normalizeUpdateCheckFrequency()
            }

            func checkForUpdates() {
                guard updateEligibility.canUseInAppUpdates else {
                    NSSound.beep()
                    return
                }
                updaterController?.checkForUpdates(nil)
            }

            var automaticallyChecksForUpdates: Bool {
                get {
                    updateEligibility.canUseInAppUpdates && (updaterController?.updater.automaticallyChecksForUpdates ?? false)
                }
                set {
                    guard updateEligibility.canUseInAppUpdates else { return }
                    updaterController?.updater.automaticallyChecksForUpdates = newValue
                }
            }

            var updateCheckFrequency: SaneSparkleCheckFrequency {
                get {
                    let interval = updaterController?.updater.updateCheckInterval ?? SaneSparkleCheckFrequency.daily.interval
                    return SaneSparkleCheckFrequency.resolve(updateCheckInterval: interval)
                }
                set {
                    guard updateEligibility.canUseInAppUpdates else { return }
                    updaterController?.updater.updateCheckInterval = newValue.interval
                }
            }

            var isUpdateChannelEnabled: Bool { updateEligibility.canUseInAppUpdates }
            var updateUnavailableStatus: String { updateEligibility.userFacingStatus }

            nonisolated static func sparkleUpdateEligibility(
                bundleIdentifier: String?,
                bundlePath: String = Bundle.main.bundlePath,
                homeDirectory: String = NSHomeDirectory()
            ) -> SaneUpdateEligibility {
                SaneUpdateEligibility.resolve(
                    bundleIdentifier: bundleIdentifier,
                    releaseBundleIdentifier: releaseBundleIdentifier,
                    bundlePath: bundlePath,
                    homeDirectory: homeDirectory
                )
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
            SaneSalesContextMenu.make(
                target: self,
                actions: .init(
                    open: #selector(dockShowWindow),
                    refresh: #selector(dockRefresh),
                    settings: #selector(dockOpenSettings),
                    license: #selector(dockOpenLicense),
                    checkForUpdates: directUpdateAction,
                    about: #selector(dockOpenAbout),
                    quit: #selector(dockQuit)
                ),
                configureCheckForUpdates: directUpdateConfigurator,
            )
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
            private var directUpdateAction: Selector? {
                #selector(dockCheckForUpdates)
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

            @objc private func dockCheckForUpdates() {
                UpdateService.shared.checkForUpdates()
            }
        #else
            private var directUpdateAction: Selector? { nil }
            private var directUpdateConfigurator: ((NSMenuItem) -> Void)? { nil }
        #endif

        @objc private func dockOpenSettings() {
            SettingsTabNavigationStorage.shared.requestShowSettingsTab()
        }

        @objc private func dockOpenLicense() {
            SettingsTabNavigationStorage.shared.requestShowSettingsTab(.license)
        }

        @objc private func dockOpenAbout() {
            SettingsTabNavigationStorage.shared.requestShowSettingsTab(.about)
        }

        @objc private func dockQuit() {
            NSApp.terminate(nil)
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
        @Environment(\.scenePhase) private var scenePhase
        @AppStorage("showRevenueInMenuBar") private var showRevenueInMenuBar = false
        @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
        @AppStorage("demo_mode") private var demoModeEnabled = false

        private let automaticRefreshInterval: TimeInterval = 12 * 60 * 60

        init() {
            if CommandLine.arguments.contains("--uitest-reset") {
                SalesManager.resetUITestPersistentState()
            }

            SaneSalesLaunchOverrides.applyPersistentUIState()

            // Defer Dock/accessory policy until NSApp exists.
            let showDock = Self.defaultShowDockPreference()
            SaneActivationPolicy.applyInitialPolicy(showDockIcon: showDock)
        }

        nonisolated static func defaultShowDockPreference(
            userDefaults: UserDefaults = .standard
        ) -> Bool {
            userDefaults.object(forKey: "showInDock") as? Bool ?? SaneBackgroundAppDefaults.showDockIcon
        }

        private var forcedProModeEnabled: Bool {
            let environment = ProcessInfo.processInfo.environment
            return environment["SANEAPPS_FORCE_PRO_MODE"] == "1" || CommandLine.arguments.contains("--force-pro-mode")
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
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onAppear {
                        appDelegate.salesManager = manager
                        licenseService.checkCachedLicense()

                        // Sync license and demo state into manager for Pro gating
                        syncProAccess()

                        // Fire launch event based on tier
                        let tier = manager.hasLiveProviderAccess ? "pro" : "free"
                        let isFirstLaunch = !hasSeenWelcome
                        Task.detached {
                            await EventTracker.log("app_launch_\(tier)", app: "sanesales")
                            if isFirstLaunch, tier == "free" {
                                await EventTracker.log("new_free_user", app: "sanesales")
                            }
                        }

                        setupMenuBar()
                    }
                    .task {
                        if CommandLine.arguments.contains("--demo") || demoModeEnabled ||
                            UserDefaults.standard.bool(forKey: "loadDemoData")
                        {
                            DemoData.loadInto(
                                manager: manager,
                                connectedProviders: manager.demoConnectedProviders()
                            )
                            syncProAccess()
                        }
                        await runAutomaticRefreshLoop()
                    }
                    .sheet(isPresented: Binding(
                        get: { !hasSeenWelcome },
                        set: { isShowing in
                            if !isShowing {
                                hasSeenWelcome = true
                                if showInMenuBar, menuBarManager == nil {
                                    menuBarManager = MenuBarManager(
                                        salesManager: manager,
                                        showRevenue: effectiveShowRevenueInMenuBar
                                    )
                                }
                            }
                        }
                    )) {
                        WelcomeGateView(
                            appName: "SaneSales",
                            appIcon: "dollarsign.circle.fill",
                            freeFeatures: [
                                (icon: "play.circle", text: "Demo mode to explore"),
                                (icon: "chart.bar", text: "Sample orders, products, and revenue"),
                                (icon: "lock", text: "Pro required for live provider connections"),
                                (icon: "shield", text: "Private local demo data")
                            ],
                            proFeatures: [
                                (icon: "checkmark", text: "Pro unlocks live tracking:"),
                                (icon: "shield", text: "iCloud Keychain provider sync"),
                                (icon: "chart.line.uptrend.xyaxis", text: "7-day, 30-day, custom date ranges, and all-time trends"),
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
                                Task.detached {
                                    await EventTracker.log("demo_started", app: "sanesales")
                                }
                                let key = "SaneApps.EventTracker.logged.sanesales.first_value_action"
                                if !UserDefaults.standard.bool(forKey: key) {
                                    UserDefaults.standard.set(true, forKey: key)
                                    Task.detached {
                                        await EventTracker.log("first_value_action", app: "sanesales")
                                    }
                                }
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
                menuBarManager?.setShowRevenue(manager.hasLiveProviderAccess && newValue)
            }
            .onChange(of: demoModeEnabled) { _, _ in
                syncProAccess()
            }
            .onChange(of: manager.isAnyConnected) { _, _ in
                syncProAccess()
            }
            .onChange(of: manager.metrics) { _, _ in
                menuBarManager?.updateTitle()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    syncProAccess()
                    Task { await refreshLiveDataIfStale() }
                }
            }
            .onChange(of: licenseService.isPro) { _, _ in
                syncProAccess()
                if showInMenuBar, menuBarManager == nil {
                    menuBarManager = MenuBarManager(salesManager: manager, showRevenue: effectiveShowRevenueInMenuBar)
                }
            }
            .onChange(of: licenseService.hasCompletedPurchaseStateRefresh) { _, _ in
                syncProAccess()
            }
            .commands {
                CommandGroup(replacing: .appSettings) {
                    Button(SaneStandardMenu.settingsTitle) {
                        showSettingsTab()
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
                #if !APP_STORE
                    CommandGroup(after: .appInfo) {
                        Button(SaneStandardMenu.checkForUpdatesTitle) {
                            UpdateService.shared.checkForUpdates()
                        }
                        .disabled(!UpdateService.shared.isUpdateChannelEnabled)
                        .help(UpdateService.shared.isUpdateChannelEnabled ? "" : UpdateService.shared.updateUnavailableStatus)
                    }
                #endif
            }
        }

        private func syncProAccess() {
            let isPaidOrForced = licenseService.isPro || forcedProModeEnabled
            manager.updateProAccess(
                isPaidPro: licenseService.isPro,
                forcePro: forcedProModeEnabled,
                demoModeEnabled: demoModeEnabled || CommandLine.arguments.contains("--demo")
            )
            if licenseService.hasCompletedPurchaseStateRefresh {
                manager.resetUnpaidLiveAccessToDemoIfNeeded(isPaidOrForced: isPaidOrForced)
            }
            menuBarManager?.setShowRevenue(effectiveShowRevenueInMenuBar)
        }

        private func refreshLiveDataIfStale(force: Bool = false) async {
            syncProAccess()
            guard manager.isAnyConnected, !manager.isLoading else { return }
            if force || manager.lastUpdated == nil || Date().timeIntervalSince(manager.lastUpdated!) >= automaticRefreshInterval {
                await manager.refresh()
            }
        }

        private func runAutomaticRefreshLoop() async {
            await refreshLiveDataIfStale()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(automaticRefreshInterval * 1_000_000_000))
                if Task.isCancelled { return }
                await refreshLiveDataIfStale(force: true)
            }
        }

        private func setupMenuBar() {
            guard showInMenuBar, menuBarManager == nil else { return }
            menuBarManager = MenuBarManager(salesManager: manager, showRevenue: effectiveShowRevenueInMenuBar)
        }

        private func showSettingsTab() {
            SettingsTabNavigationStorage.shared.requestShowSettingsTab()
        }

        private func handleDeepLink(_ url: URL) {
            guard url.scheme == "sanesales" else { return }
            if url.host == "license" || url.path == "/license" {
                SettingsTabNavigationStorage.shared.requestShowSettingsTab(.license)
            } else {
                SettingsTabNavigationStorage.shared.requestShowSettingsTab()
            }
        }

        private func handleMenuBarToggle(_ show: Bool) {
            if show {
                menuBarManager = MenuBarManager(salesManager: manager, showRevenue: effectiveShowRevenueInMenuBar)
            } else {
                menuBarManager?.tearDown()
                menuBarManager = nil
            }
        }

        private var effectiveShowRevenueInMenuBar: Bool {
            manager.hasLiveProviderAccess && showRevenueInMenuBar
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
        func makeNSView(context _: Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async {
                WindowActionStorage.shared.captureMainWindow(view.window)
            }
            return view
        }

        func updateNSView(_ nsView: NSView, context _: Context) {
            DispatchQueue.main.async {
                WindowActionStorage.shared.captureMainWindow(nsView.window)
            }
        }
    }

    // Reuse ContentView from iOS/ (shared code)
#endif
