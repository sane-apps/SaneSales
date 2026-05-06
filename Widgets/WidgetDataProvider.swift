import WidgetKit

struct SalesWidgetProvider: TimelineProvider {
    func placeholder(in _: Context) -> SalesWidgetEntry {
        .placeholder
    }

    func getSnapshot(in _: Context, completion: @escaping (SalesWidgetEntry) -> Void) {
        let entry = loadCachedEntry() ?? .placeholder
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<SalesWidgetEntry>) -> Void) {
        let entry = loadCachedEntry() ?? .placeholder
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCachedEntry() -> SalesWidgetEntry? {
        let defaults = SharedStore.userDefaults()
        guard SharedStore.isProEnabled(defaults: defaults) else {
            return .locked
        }
        guard let snapshot = SharedStore.loadSalesSnapshot(defaults: defaults) else { return nil }
        return SalesWidgetEntry(
            date: Date(),
            todayRevenue: snapshot.todayRevenue,
            todayOrders: snapshot.todayOrders,
            monthRevenue: snapshot.monthRevenue,
            currency: snapshot.currency
        )
    }
}
