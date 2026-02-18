import SwiftUI

@main
struct SaneSalesWatchApp: App {
    @StateObject private var viewModel = WatchDashboardViewModel()

    var body: some Scene {
        WindowGroup {
            WatchDashboardView(viewModel: viewModel)
                .task {
                    viewModel.refresh(useDemoIfEmpty: CommandLine.arguments.contains("--demo"))
                }
        }
    }
}
