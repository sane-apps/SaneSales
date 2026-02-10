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
        guard let data = UserDefaults.standard.data(forKey: "cached_orders") else { return nil }
        guard let orders = try? JSONDecoder().decode([Order].self, from: data) else { return nil }

        let metrics = SalesMetrics.compute(from: orders)
        let currency = Dictionary(grouping: orders, by: \.currency)
            .mapValues(\.count)
            .max(by: { $0.value < $1.value })?.key ?? "USD"
        return SalesWidgetEntry(
            date: Date(),
            todayRevenue: metrics.todayRevenue,
            todayOrders: metrics.todayOrders,
            monthRevenue: metrics.monthRevenue,
            currency: currency
        )
    }
}
