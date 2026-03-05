import SwiftUI
import SaneUI

@main
struct SaneSalesApp: App {
    @State private var manager = SalesManager()
    @State private var licenseService = LicenseService(
        appName: "SaneSales",
        checkoutURL: URL(string: "https://go.saneapps.com/buy/sanesales")!
    )
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(manager)
                .environment(licenseService)
                .preferredColorScheme(.dark)
                .onAppear {
                    licenseService.checkCachedLicense()
                    manager.isPro = licenseService.isPro
                }
                .onChange(of: licenseService.isPro) { _, isPro in
                    manager.isPro = isPro
                }
                .sheet(isPresented: Binding(
                    get: { !hasSeenWelcome },
                    set: { isShowing in
                        if !isShowing {
                            hasSeenWelcome = true
                        }
                    }
                )) {
                    WelcomeGateView(
                        appName: "SaneSales",
                        appIcon: "dollarsign.circle.fill",
                        freeFeatures: [
                            (icon: "link", text: "Connect 1 sales provider"),
                            (icon: "clock.badge.checkmark", text: "Today's revenue and orders"),
                            (icon: "play.circle", text: "Demo mode to explore")
                        ],
                        proFeatures: [
                            (icon: "checkmark", text: "Everything in Free, plus:"),
                            (icon: "chart.line.uptrend.xyaxis", text: "Yesterday, 7-day, and 30-day trends"),
                            (icon: "list.bullet.rectangle", text: "Full order history"),
                            (icon: "tablecells", text: "CSV export"),
                            (icon: "link.badge.plus", text: "Multiple providers at once"),
                            (icon: "menubar.rectangle", text: "Menu bar quick glance")
                        ],
                        licenseService: licenseService
                    )
                    .preferredColorScheme(.dark)
                }
                .task {
                    if CommandLine.arguments.contains("--uitest-reset") {
                        manager.resetForUITests()
                    }
                    if CommandLine.arguments.contains("--demo") {
                        DemoData.loadInto(manager: manager)
                    }
                }
        }
    }
}
