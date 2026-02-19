import SwiftUI

@main
struct SaneSalesApp: App {
    @State private var manager = SalesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(manager)
                .preferredColorScheme(.dark)
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
