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
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("demo_mode") private var demoModeEnabled = false

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
                if shouldShowInitialSetup {
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
                    debugLogStartupState(reason: "demoMode")
                }
                .onChange(of: manager.isAnyConnected) { _, _ in
                    debugLogStartupState(reason: "connectedProviders")
                }
                .onChange(of: manager.error?.localizedDescription) { _, _ in
                    debugLogStartupState(reason: "error")
                }
                .onChange(of: manager.orders.count) { _, _ in
                    debugLogStartupState(reason: "orders")
                }
                .onChange(of: licenseService.isPro) { _, isPro in
                    manager.isPro = forcedProModeEnabled || isPro
                    debugLogStartupState(reason: "license")
                }
                .task {
                    licenseService.checkCachedLicense()
                    manager.isPro = forcedProModeEnabled || licenseService.isPro
        if CommandLine.arguments.contains("--uitest-reset") {
                        manager.resetForUITests()
                    }
                    if CommandLine.arguments.contains("--demo") {
                        DemoData.loadInto(
                            manager: manager,
                            connectedProviders: manager.demoConnectedProviders()
                        )
                    }
                }
        }
    }

    private var forcedProModeEnabled: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["SANEAPPS_FORCE_PRO_MODE"] == "1" || CommandLine.arguments.contains("--force-pro-mode")
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
                    "showSetup=\(shouldShowInitialSetup)"
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
                    "setup=\(shouldShowInitialSetup)"
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

        itemAppearances.forEach { itemAppearance in
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
