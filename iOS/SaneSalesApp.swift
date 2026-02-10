import SwiftUI

@main
struct SaneSalesApp: App {
    @State private var manager = SalesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(manager)
                .task {
                    #if DEBUG
                        if CommandLine.arguments.contains("--demo") {
                            DemoData.loadInto(manager: manager)
                        }
                    #endif
                }
        }
    }
}
