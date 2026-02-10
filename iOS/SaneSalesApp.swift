import SwiftUI

@main
struct SaneSalesApp: App {
    @State private var manager = SalesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(manager)
        }
    }
}
