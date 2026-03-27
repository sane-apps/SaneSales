import Foundation
import SaneUI
import SwiftUI

@main
struct SaneSalesApp: App {
    @State private var manager = SalesManager()
    @State private var licenseService = LicenseService(
        appName: "SaneSales",
        purchaseBackend: .appStore(productID: "com.sanesales.app.pro.unlock.v2")
    )
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("demo_mode") private var demoModeEnabled = false

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
                .task {
                    licenseService.checkCachedLicense()
                    if CommandLine.arguments.contains("--uitest-reset") {
                        manager.resetForUITests()
                    }
                    if CommandLine.arguments.contains("--demo") {
                        DemoData.loadInto(manager: manager)
                    }
                }
        }
    }

    private var shouldShowInitialSetup: Bool {
        SalesSetupFlowPolicy.shouldShowInitialSetup(
            hasSeenWelcome: hasSeenWelcome,
            demoModeEnabled: demoModeEnabled,
            hasConnectedProviders: manager.isAnyConnected,
            hasAnyData: !manager.orders.isEmpty || !manager.products.isEmpty || !manager.stores.isEmpty,
            hasError: manager.error != nil
        )
    }

    private func debugLogStartupState(reason: String) {
        #if DEBUG
            let hasAnyData = !manager.orders.isEmpty || !manager.products.isEmpty || !manager.stores.isEmpty
            NSLog(
                "%@",
                "[SaneSales iOS startup] reason=\(reason) bundle=\(Bundle.main.bundleIdentifier ?? "unknown") " +
                    "welcome=\(hasSeenWelcome) demo=\(demoModeEnabled) connected=\(manager.isAnyConnected) " +
                    "orders=\(manager.orders.count) products=\(manager.products.count) stores=\(manager.stores.count) " +
                    "hasAnyData=\(hasAnyData) error=\(manager.error?.localizedDescription ?? "none") " +
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
            let hasAnyData = !manager.orders.isEmpty || !manager.products.isEmpty || !manager.stores.isEmpty
            Text(
                "welcome=\(hasSeenWelcome) demo=\(demoModeEnabled) connected=\(manager.isAnyConnected) " +
                    "orders=\(manager.orders.count) products=\(manager.products.count) stores=\(manager.stores.count) " +
                    "data=\(hasAnyData) error=\(manager.error == nil ? "none" : "yes") " +
                    "setup=\(shouldShowInitialSetup)"
            )
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.white)
            .padding(8)
            .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
            .padding(12)
        #endif
    }
}
