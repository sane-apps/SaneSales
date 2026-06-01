import Foundation
import SaneUI
import SwiftUI

#if os(iOS)
    import UIKit
#endif

@main
struct SaneSalesApp: App {
    @State private var manager = SalesManager()
    @State private var licenseService = LicenseService(
        appName: "SaneSales",
        purchaseBackend: .appStore(productID: "com.sanesales.app.pro.unlock.v2")
    )
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("demo_mode") private var demoModeEnabled = false
    @AppStorage("pendingSettingsRoute") private var pendingSettingsRoute = ""
    @State private var startupLoadingTimedOut = false

    private let automaticRefreshInterval: TimeInterval = 12 * 60 * 60

    init() {
        #if os(iOS)
            configureTabBarAppearance()
        #endif
        if CommandLine.arguments.contains("--uitest-reset") {
            SalesManager.resetUITestPersistentState()
        }

        SaneSalesLaunchOverrides.applyPersistentUIState()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if shouldShowStartupLoading {
                    StartupLoadingView()
                } else if shouldShowInitialSetup {
                    OnboardingView()
                } else {
                    ContentView()
                }
            }
            .environment(manager)
            .environment(licenseService)
            .preferredColorScheme(.dark)
            .overlay(alignment: .bottomLeading) {
                if shouldShowDebugStartupOverlay {
                    debugStartupOverlay
                }
            }
            .onAppear {
                debugLogStartupState(reason: "appear")
            }
            .onChange(of: hasSeenWelcome) { _, _ in
                debugLogStartupState(reason: "hasSeenWelcome")
            }
            .onChange(of: demoModeEnabled) { _, _ in
                syncProAccess()
                debugLogStartupState(reason: "demoMode")
            }
            .onChange(of: manager.isAnyConnected) { _, _ in
                syncProAccess()
                debugLogStartupState(reason: "connectedProviders")
            }
            .onChange(of: manager.error?.localizedDescription) { _, _ in
                debugLogStartupState(reason: "error")
            }
            .onChange(of: manager.orders.count) { _, _ in
                debugLogStartupState(reason: "orders")
            }
            .onChange(of: licenseService.isPro) { _, _ in
                syncProAccess()
                debugLogStartupState(reason: "license")
            }
            .onChange(of: licenseService.hasCompletedPurchaseStateRefresh) { _, _ in
                if licenseService.hasCompletedPurchaseStateRefresh {
                    startupLoadingTimedOut = false
                }
                syncProAccess()
                debugLogStartupState(reason: "licenseRefresh")
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    syncProAccess()
                    Task { await refreshLiveDataIfStale() }
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .task {
                licenseService.checkCachedLicense()
                syncProAccess()
                if CommandLine.arguments.contains("--uitest-reset") {
                    manager.resetForUITests()
                    SaneSalesLaunchOverrides.applyPersistentUIState()
                }
                if CommandLine.arguments.contains("--demo") {
                    DemoData.loadInto(
                        manager: manager,
                        connectedProviders: manager.demoConnectedProviders()
                    )
                }
                syncProAccess()
                await runAutomaticRefreshLoop()
            }
            .task(id: isWaitingForAppStorePurchaseState) {
                await scheduleStartupLoadingFallback()
            }
        }
    }

    private var forcedProModeEnabled: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["SANEAPPS_FORCE_PRO_MODE"] == "1" || CommandLine.arguments.contains("--force-pro-mode")
    }

    private var forcedFreeModeEnabled: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["SANEAPPS_FORCE_FREE_MODE"] == "1" || CommandLine.arguments.contains("--force-free-mode")
    }

    private func syncProAccess() {
        let forceFree = forcedFreeModeEnabled
        let isPaidOrForced = (licenseService.isPro || forcedProModeEnabled) && !forceFree
        manager.updateProAccess(
            isPaidPro: licenseService.isPro && !forceFree,
            forcePro: forcedProModeEnabled && !forceFree,
            demoModeEnabled: (demoModeEnabled || CommandLine.arguments.contains("--demo")) && !forceFree
        )
        if licenseService.hasCompletedPurchaseStateRefresh {
            manager.resetUnpaidLiveAccessToDemoIfNeeded(isPaidOrForced: isPaidOrForced)
        }
    }

    private var isWaitingForAppStorePurchaseState: Bool {
        licenseService.usesAppStorePurchase && !licenseService.hasCompletedPurchaseStateRefresh
    }

    private var shouldShowStartupLoading: Bool {
        SalesSetupFlowPolicy.shouldShowStartupLoading(
            isWaitingForPurchaseState: isWaitingForAppStorePurchaseState,
            hasTimedOut: startupLoadingTimedOut
        )
    }

    private func scheduleStartupLoadingFallback() async {
        guard isWaitingForAppStorePurchaseState else {
            startupLoadingTimedOut = false
            return
        }

        startupLoadingTimedOut = false
        try? await Task.sleep(nanoseconds: UInt64(SalesSetupFlowPolicy.startupLoadingTimeout * 1_000_000_000))
        guard !Task.isCancelled, isWaitingForAppStorePurchaseState else { return }
        startupLoadingTimedOut = true
        debugLogStartupState(reason: "startupLoadingTimeout")
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "sanesales" else { return }
        hasSeenWelcome = true
        if url.host == "license" || url.path == "/license" {
            pendingSettingsRoute = "license"
        }
    }

    private func refreshLiveDataIfStale(force: Bool = false) async {
        syncProAccess()
        guard manager.isAnyConnected, !manager.isLoading else { return }
        guard !isWaitingForAppStorePurchaseState || manager.hasLiveProviderAccess else { return }
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

    private var shouldShowInitialSetup: Bool {
        SalesSetupFlowPolicy.shouldShowInitialSetup(
            hasSeenWelcome: hasSeenWelcome,
            demoModeEnabled: demoModeEnabled,
            hasConnectedProviders: manager.isAnyConnected,
            hasAnyData: hasUsableDashboardContent,
            hasError: manager.error != nil
        )
    }

    private func debugLogStartupState(reason: String) {
        #if DEBUG
            NSLog(
                "%@",
                "[SaneSales iOS startup] reason=\(reason) bundle=\(Bundle.main.bundleIdentifier ?? "unknown") " +
                    "welcome=\(hasSeenWelcome) demo=\(demoModeEnabled) connected=\(manager.isAnyConnected) " +
                    "orders=\(manager.orders.count) products=\(manager.products.count) stores=\(manager.stores.count) " +
                    "hasAnyData=\(hasUsableDashboardContent) error=\(manager.error?.localizedDescription ?? "none") " +
                    "loading=\(shouldShowStartupLoading) loadingTimedOut=\(startupLoadingTimedOut) showSetup=\(shouldShowInitialSetup)"
            )
        #endif
    }

    private var shouldShowDebugStartupOverlay: Bool {
        #if DEBUG
            CommandLine.arguments.contains("--debug-startup-overlay")
        #else
            false
        #endif
    }

    @ViewBuilder
    private var debugStartupOverlay: some View {
        #if DEBUG
            Text(
                "welcome=\(hasSeenWelcome) demo=\(demoModeEnabled) connected=\(manager.isAnyConnected) " +
                    "orders=\(manager.orders.count) products=\(manager.products.count) stores=\(manager.stores.count) " +
                    "data=\(hasUsableDashboardContent) error=\(manager.error == nil ? "none" : "yes") " +
                    "loading=\(shouldShowStartupLoading) loadingTimedOut=\(startupLoadingTimedOut) setup=\(shouldShowInitialSetup)"
            )
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.white)
            .padding(8)
            .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
            .padding(12)
        #endif
    }

    private var hasUsableDashboardContent: Bool {
        SalesSetupFlowPolicy.hasUsableContent(
            ordersCount: manager.orders.count,
            productsCount: manager.products.count
        )
    }

    #if os(iOS)
        private func configureTabBarAppearance() {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 8 / 255, green: 11 / 255, blue: 20 / 255, alpha: 0.98)
            appearance.shadowColor = UIColor.white.withAlphaComponent(0.08)

            let selectedColor = UIColor(Color.salesGreen)
            let normalColor = UIColor.white.withAlphaComponent(0.78)
            let itemAppearances = [
                appearance.stackedLayoutAppearance,
                appearance.inlineLayoutAppearance,
                appearance.compactInlineLayoutAppearance
            ]

            for itemAppearance in itemAppearances {
                itemAppearance.normal.iconColor = normalColor
                itemAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
                itemAppearance.selected.iconColor = selectedColor
                itemAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
            }

            let proxy = UITabBar.appearance()
            proxy.isTranslucent = false
            proxy.standardAppearance = appearance
            proxy.scrollEdgeAppearance = appearance
        }
    #endif
}

private struct StartupLoadingView: View {
    var body: some View {
        ZStack {
            SaneBackground()
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image("CoinColor")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                ProgressView()
                    .tint(.white)

                VStack(spacing: 6) {
                    Text("Checking SaneSales")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)

                    Text("Checking your access and saved providers.")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)
        }
        .accessibilityIdentifier("startup.loading.view")
    }
}
