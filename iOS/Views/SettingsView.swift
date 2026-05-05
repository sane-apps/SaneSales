import SaneUI

// swiftlint:disable file_length
import SwiftUI
#if os(iOS)
    import UIKit
#endif

struct SettingsView: View {
    @Environment(SalesManager.self) private var manager
    @Environment(LicenseService.self) private var licenseService
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingKeyEntry = false
    @State private var editingProvider: SalesProviderType?
    @State private var showRemoveConfirmation = false
    @State private var removingProvider: SalesProviderType?
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showFeedback = false
    @AppStorage(SaneSalesDateRangeStore.selectedRangeKey) private var selectedRange: TimeRange = .today
    @AppStorage(SaneSalesDateRangeStore.customStartKey) private var customRangeStartTimestamp = SaneSalesDateRangeStore.defaultCustomStartTimestamp
    @AppStorage(SaneSalesDateRangeStore.customEndKey) private var customRangeEndTimestamp = SaneSalesDateRangeStore.defaultCustomEndTimestamp
    @AppStorage("demo_mode") private var demoMode = false
    @AppStorage("pendingSettingsRoute") private var pendingSettingsRoute = ""
    @State private var showingLicenseEntrySheet = false
    #if os(macOS)
        @State private var proUpsellFeature: ProFeature?
    #endif

    var body: some View {
        #if os(macOS)
            SaneSalesMacSettingsView()
        #else
            NavigationStack {
                ZStack {
                    SaneBackground().ignoresSafeArea()
                    GeometryReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                licenseSection
                                providersSection
                                dataSection
                                aboutSection
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 12)
                            .padding(.bottom, settingsBottomPadding(safeAreaBottom: proxy.safeAreaInsets.bottom))
                        }
                    }
                }
                .navigationTitle("Settings")
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: SaneSalesIOSChrome.floatingTabBarClearance)
                    }
                #endif
                    .sheet(
                        isPresented: $showingKeyEntry,
                        onDismiss: {
                            editingProvider = nil
                        },
                        content: {
                            if let provider = editingProvider {
                                ProviderConnectionSheet(provider: provider)
                            }
                        }
                    )
                    .sheet(isPresented: $showFeedback) {
                        SaneFeedbackView(diagnosticsService: .shared)
                    }
                    .sheet(isPresented: $showingLicenseEntrySheet) {
                        LicenseEntryView(licenseService: licenseService)
                    }
                    .confirmationDialog(
                        "Disconnect \(removingProvider?.displayName ?? "Provider")?",
                        isPresented: $showRemoveConfirmation
                    ) {
                        Button("Disconnect", role: .destructive) {
                            if let provider = removingProvider {
                                disconnectProvider(provider)
                            }
                        }
                    } message: {
                        Text("This will remove the API key and cached data for this provider.")
                    }
                    .task {
                        if licenseService.usesAppStorePurchase {
                            await licenseService.preloadAppStoreProduct()
                        }
                    }
                    .onAppear {
                        consumePendingSettingsRoute()
                    }
                    .onChange(of: pendingSettingsRoute) { _, _ in
                        consumePendingSettingsRoute()
                    }
            }
        #endif
    }

    // MARK: - License Section

    private var licenseSection: some View {
        GlassSection("License", icon: "key.fill", iconColor: SaneSettingsIconSemantic.license.color) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: licenseService.isPro || manager.isPro ? "checkmark.seal.fill" : "lock.fill")
                        .foregroundStyle(licenseService.isPro || manager.isPro ? Color.salesSuccess : .white)
                        .font(.system(size: 15, weight: .semibold))

                    licenseTierBadge(
                        title: licenseTitle,
                        color: licenseService.isPro || manager.isPro ? Color.salesSuccess : .white
                    )

                    Spacer()

                    if let email = licenseService.licenseEmail, licenseService.isPro {
                        Text(email)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, settingsSectionVerticalPadding)

                GlassDivider()

                Text(licenseDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, settingsSectionVerticalPadding)

                GlassDivider()

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        primaryLicenseAction
                        secondaryLicenseAction
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, settingsSectionVerticalPadding)

                    VStack(spacing: 8) {
                        primaryLicenseAction
                        secondaryLicenseAction
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, settingsSectionVerticalPadding)
                }
            }
        }
    }

    // MARK: - Providers Section

    private var providersSection: some View {
        GlassSection("Providers", icon: "link.circle.fill", iconColor: SaneSettingsIconSemantic.sync.color) {
            VStack(spacing: 0) {
                providerRow(.lemonSqueezy, isConnected: manager.isLemonSqueezyConnected)
                GlassDivider()
                providerRow(.gumroad, isConnected: manager.isGumroadConnected)
                GlassDivider()
                providerRow(.stripe, isConnected: manager.isStripeConnected)
            }
        }
    }

    private func providerRow(_ provider: SalesProviderType, isConnected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: provider.icon)
                .font(.title3)
                .foregroundStyle(provider.brandColor)
                .frame(width: 28)

            Text(provider.displayName)
                .font(.saneSubheadline)

            Spacer()

            if isConnected {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        StatusBadge("Connected", color: .salesSuccess, icon: "checkmark.circle.fill")
                        providerManagementMenu(provider)
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        StatusBadge("Connected", color: .salesSuccess, icon: "checkmark.circle.fill")
                        providerManagementMenu(provider)
                    }
                }
            } else {
                #if os(macOS)
                    Button("Connect Account") {
                        startProviderConnection(provider)
                    }
                    .font(.saneSubheadlineBold)
                    .foregroundStyle(Color.salesGreen)
                #else
                    let connectButton = Button("Connect") {
                        startProviderConnection(provider)
                    }
                    .buttonStyle(SaneActionButtonStyle())

                    switch provider {
                    case .lemonSqueezy:
                        connectButton.accessibilityIdentifier("settings.provider.lemonsqueezy.connect")
                    case .gumroad:
                        connectButton.accessibilityIdentifier("settings.provider.gumroad.connect")
                    case .stripe:
                        connectButton.accessibilityIdentifier("settings.provider.stripe.connect")
                    }
                #endif
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, providerRowVerticalPadding)
    }

    // MARK: - Data Section

    private var dataSection: some View {
        GlassSection("Data", icon: "internaldrive", iconColor: SaneSettingsIconSemantic.storage.color) {
            VStack(spacing: 0) {
                if let date = manager.lastUpdated {
                    GlassRow("Last Updated", icon: "clock", iconColor: .salesGreen) {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.saneSubheadline)
                    }
                    GlassDivider()
                }
                GlassRow(manager.isPro ? "Cached Orders" : "Orders Today", icon: "list.bullet", iconColor: .blue) {
                    Text("\(manager.isPro ? manager.orders.count : manager.planScopedOrders(filteredBy: nil).count)")
                        .font(.saneSubheadlineBold)
                }
                GlassDivider()
                GlassRow("Products", icon: "shippingbox", iconColor: .orange) {
                    Text("\(manager.products.count)")
                        .font(.saneSubheadlineBold)
                }
                GlassDivider()
                Button {
                    toggleDemoMode()
                } label: {
                    GlassRow(
                        demoMode ? "Disable Demo Mode" : "Enable Demo Mode",
                        icon: demoMode ? "sparkles.slash" : "sparkles",
                        iconColor: demoMode ? .orange : .teal
                    ) {
                        Text(demoMode ? "On" : "Off")
                            .font(.saneSubheadlineBold)
                            .foregroundStyle(demoMode ? .orange : Color.textMuted)
                    }
                }
                GlassDivider()
                Button {
                    Task { await manager.refresh() }
                } label: {
                    GlassRow("Refresh Now", icon: "arrow.clockwise", iconColor: .salesGreen) {
                        if manager.isLoading {
                            ProgressView()
                                .tint(.salesGreen)
                        }
                    }
                }
                if !manager.orders.isEmpty {
                    GlassDivider()
                    if !manager.isPro {
                        Button {
                            #if os(macOS)
                                proUpsellFeature = .csvExport
                            #else
                                triggerUnlock()
                            #endif
                        } label: {
                            GlassRow("Export Orders (CSV)", icon: "square.and.arrow.up", iconColor: .blue) {
                                StatusBadge("Pro", color: SaneSettingsIconSemantic.license.color, icon: "lock.fill")
                            }
                        }
                        .accessibilityIdentifier("settings.data.export.lockedButton")
                    } else {
                        Button {
                            exportURL = exportOrdersCSV(exportOrders, scopeLabel: exportScopeLabel)
                            if exportURL != nil { showExportSheet = true }
                        } label: {
                            GlassRow("Export Orders (CSV)", icon: "square.and.arrow.up", iconColor: .blue) {
                                Text(exportScopeLabel)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.textMuted)
                                    .lineLimit(1)
                            }
                        }
                        .accessibilityIdentifier("settings.data.export.button")
                    }
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        GlassSection("About", icon: "info.circle", iconColor: SaneSettingsIconSemantic.about.color) {
            VStack(spacing: 0) {
                GlassRow("Version", icon: "number", iconColor: SaneSettingsIconSemantic.about.color) {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .font(.saneSubheadline)
                }
                GlassDivider()
                GlassRow("Build", icon: "hammer", iconColor: SaneSettingsIconSemantic.about.color) {
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .font(.saneSubheadline)
                }
                GlassDivider()
                if let url = URL(string: "https://saneapps.com") {
                    Link(destination: url) {
                        GlassRow("Website", icon: "globe", iconColor: Color.salesGreen) {
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(Color.salesGreen)
                                .font(.saneSubheadline)
                        }
                    }
                }
                GlassDivider()
                Button {
                    showFeedback = true
                } label: {
                    GlassRow("Report a Bug", icon: "ladybug", iconColor: .orange) {
                        Image(systemName: "arrow.up.forward.square")
                            .foregroundStyle(Color.textMuted)
                            .font(.saneSubheadline)
                    }
                }
                .buttonStyle(.plain)
                GlassDivider()
                if let url = URL(string: "https://saneapps.com/privacy") {
                    Link(destination: url) {
                        GlassRow("Privacy Policy", icon: "hand.raised", iconColor: .blue) {
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(Color.textMuted)
                                .font(.saneSubheadline)
                        }
                    }
                }
                GlassDivider()
                if let url = URL(string: "https://github.com/sane-apps/SaneSales/issues") {
                    Link(destination: url) {
                        GlassRow("View Issues", icon: "arrow.up.right.square", iconColor: .blue) {
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(Color.textMuted)
                                .font(.saneSubheadline)
                        }
                    }
                }
            }
        }
    }

    private var licenseTitle: String {
        if licenseService.isPro { return "Pro" }
        if manager.isDemoModeActive { return "Demo Mode" }
        if manager.trialState.isActive { return "Trial" }
        return "Pro Required"
    }

    private var licenseDescription: String {
        if licenseService.isPro {
            return "Pro unlocks custom date ranges, longer history, CSV export, menu bar quick glance, widgets, and deeper comparisons."
        }
        if manager.isDemoModeActive {
            return "Demo data is active. Connect live data to start your 7-day free trial, or unlock Pro now."
        }

        switch manager.trialState {
        case let .active(_, _, daysRemaining):
            return "You have \(daysRemaining) \(daysRemaining == 1 ? "day" : "days") left on your free trial. Unlock Pro to keep live sales tracking after that."
        case .expired:
            return "Your free trial has ended. Unlock Pro to continue tracking live sales. Demo mode remains available."
        case .notStarted:
            return "Connect live data to start your 7-day free trial. Unlock Pro to keep live sales tracking after the trial."
        }
    }

    private func licenseTierBadge(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.16))
            )
    }

    @ViewBuilder
    private var primaryLicenseAction: some View {
        if licenseService.isPro {
            if licenseService.usesAppStorePurchase {
                Button("Restore Purchases") {
                    Task { await licenseService.restorePurchases() }
                }
                .buttonStyle(SaneActionButtonStyle())
                .disabled(licenseService.isPurchasing)
            } else {
                Button(licenseService.accessManagementLabel) {
                    licenseService.deactivate()
                }
                .buttonStyle(SaneActionButtonStyle(destructive: true))
            }
        } else if licenseService.usesAppStorePurchase {
            Button(licenseService.isPurchasing ? "Processing..." : "Unlock Pro — \(licenseService.displayPriceLabel)") {
                triggerUnlock()
            }
            .buttonStyle(SaneActionButtonStyle(prominent: true))
            .disabled(licenseService.isPurchasing)
            .accessibilityIdentifier("settings.license.unlockProButton")
        } else {
            Button("Unlock Pro — \(licenseService.displayPriceLabel)") {
                triggerUnlock()
            }
            .buttonStyle(SaneActionButtonStyle(prominent: true))
            .accessibilityIdentifier("settings.license.unlockProButton")
        }
    }

    @ViewBuilder
    private var secondaryLicenseAction: some View {
        if licenseService.isPro {
            EmptyView()
        } else if licenseService.usesAppStorePurchase {
            Button("Restore Purchases") {
                Task { await licenseService.restorePurchases() }
            }
            .buttonStyle(SaneActionButtonStyle())
            .disabled(licenseService.isPurchasing)
            .accessibilityIdentifier("settings.license.restorePurchasesButton")
        } else {
            Button(licenseService.alternateEntryLabel) {
                showingLicenseEntrySheet = true
            }
            .buttonStyle(SaneActionButtonStyle())
        }
    }

    private func triggerUnlock() {
        Task.detached {
            await EventTracker.log("checkout_clicked", app: "sanesales")
        }
        if licenseService.usesAppStorePurchase {
            Task { await licenseService.purchasePro() }
        } else if let url = licenseService.checkoutURL {
            openURL(url)
        }
    }

    private func providerManagementMenu(_ provider: SalesProviderType) -> some View {
        Menu {
            Button {
                editingProvider = provider
                showingKeyEntry = true
            } label: {
                Label("Change Key", systemImage: "key")
            }
            Button(role: .destructive) {
                removingProvider = provider
                showRemoveConfirmation = true
            } label: {
                Label("Disconnect", systemImage: "xmark.circle")
            }
        } label: {
            Text("Manage")
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .buttonStyle(SaneActionButtonStyle())
        .modifier(SettingsProviderManagementAccessibilityModifier(provider: provider))
    }

    // MARK: - Actions

    private var customRangeStartDate: Date {
        Date(timeIntervalSince1970: customRangeStartTimestamp)
    }

    private var customRangeEndDate: Date {
        Date(timeIntervalSince1970: customRangeEndTimestamp)
    }

    private var exportRangeInterval: DateInterval? {
        SaneSalesDateRangeStore.interval(
            for: selectedRange,
            customStart: customRangeStartDate,
            customEnd: customRangeEndDate
        )
    }

    private var exportOrders: [Order] {
        manager.planScopedOrders(filteredBy: nil, in: exportRangeInterval)
    }

    private var exportScopeLabel: String {
        SaneSalesDateRangeStore.compactLabel(
            for: selectedRange,
            customStart: customRangeStartDate,
            customEnd: customRangeEndDate
        )
    }

    private func disconnectProvider(_ provider: SalesProviderType) {
        switch provider {
        case .lemonSqueezy: manager.removeLemonSqueezyAPIKey()
        case .gumroad: manager.removeGumroadAPIKey()
        case .stripe: manager.removeStripeAPIKey()
        }
    }

    private func toggleDemoMode() {
        if demoMode {
            manager.disableDemoMode()
            demoMode = false
        } else {
            manager.enableDemoMode()
            demoMode = true
        }
    }

    private func settingsBottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        #if os(iOS)
            return max(28, safeAreaBottom + 20)
        #else
            return 20
        #endif
    }

    private var settingsSectionVerticalPadding: CGFloat {
        #if os(iOS)
            return 10
        #else
            return 12
        #endif
    }

    private var providerRowVerticalPadding: CGFloat {
        #if os(iOS)
            return 8
        #else
            return 12
        #endif
    }

    private func consumePendingSettingsRoute() {
        guard !pendingSettingsRoute.isEmpty else { return }

        defer { pendingSettingsRoute = "" }

        if pendingSettingsRoute == "license" {
            DispatchQueue.main.async {
                if licenseService.usesAppStorePurchase {
                    triggerUnlock()
                } else {
                    showingLicenseEntrySheet = true
                }
            }
            return
        }

        guard pendingSettingsRoute.hasPrefix("provider:") else { return }
        let rawValue = String(pendingSettingsRoute.dropFirst("provider:".count))
        guard let provider = SalesProviderType(rawValue: rawValue) else { return }

        DispatchQueue.main.async {
            startProviderConnection(provider)
        }
    }

    private func startProviderConnection(_ provider: SalesProviderType) {
        if manager.requiresProForProviderConnection(provider) {
            Task.detached {
                await EventTracker.log("second_provider_attempt", app: "sanesales")
            }
            triggerUnlock()
            return
        }

        editingProvider = provider
        showingKeyEntry = true
    }
}

struct ProviderConnectionSheet: View {
    @Environment(SalesManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    let provider: SalesProviderType

    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var showError = false
    @State private var errorTitle = ""
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: provider.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(provider.brandColor)
                    .padding(.top, 20)

                Text("Connect \(provider.displayName) Account")
                    .font(.title3.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                    #endif

                    Text(keyHelpText)
                        .font(.saneCallout)
                        .foregroundStyle(Color.textMuted)

                    Text("Reads your existing sales data. Nothing is modified.")
                        .font(.saneFootnote)
                        .foregroundStyle(Color.textMuted)
                }
                .padding(.horizontal)

                Spacer()
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isValidating {
                        ProgressView()
                            .tint(.salesGreen)
                    } else {
                        Button("Save") {
                            saveKey()
                        }
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .tint(.salesGreen)
                    }
                }
            }
            .alert(errorTitle, isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var keyHelpText: String {
        switch provider {
        case .lemonSqueezy: return "lemonsqueezy.com \u{2192} Settings \u{2192} API"
        case .gumroad: return "gumroad.com \u{2192} Settings \u{2192} Advanced \u{2192} Applications"
        case .stripe: return "dashboard.stripe.com \u{2192} Developers \u{2192} API keys (use Secret key)"
        }
    }

    private func saveKey() {
        isValidating = true
        let normalizedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            let success: Bool = switch provider {
            case .lemonSqueezy:
                await manager.setLemonSqueezyAPIKey(normalizedKey)
            case .gumroad:
                await manager.setGumroadAPIKey(normalizedKey)
            case .stripe:
                await manager.setStripeAPIKey(normalizedKey)
            }

            isValidating = false

            if success {
                dismiss()
            } else {
                switch manager.error {
                case .invalidAPIKey:
                    errorTitle = "Invalid API Key"
                    errorMessage = "The server rejected this key. Check it and try again."
                case .networkError:
                    errorTitle = "Connection Failed"
                    errorMessage = "Couldn't reach the server. Check your internet connection and try again."
                case .rateLimited:
                    errorTitle = "Rate Limited"
                    errorMessage = "Too many requests. Wait a moment and try again."
                case let .serverError(code):
                    errorTitle = "Server Error"
                    errorMessage = "The server returned an error (\(code)). Try again later."
                case let .proRequired(feature):
                    errorTitle = "Pro Required"
                    errorMessage = "\(feature) requires Pro."
                case .decodingError:
                    errorTitle = "Provider Response Changed"
                    errorMessage = "The key worked, but the provider returned data this build could not read. Try again from Settings or wait for the next update."
                default:
                    errorTitle = "Connection Failed"
                    errorMessage = "Could not connect with that key. Check it and try again."
                }
                showError = true
            }
        }
    }
}

private extension SettingsView {
    func exportOrdersCSV(_ orders: [Order], scopeLabel: String) -> URL? {
        let headers = "Date,Order #,Customer,Email,Product,Variant,Provider,Status,Subtotal,Tax,Discount,Total,Currency,Refunded"
        let dateFormatter = ISO8601DateFormatter()
        let fileDateFormatter = DateFormatter()
        fileDateFormatter.dateFormat = "yyyy-MM-dd"

        func escapeCSV(_ value: String) -> String {
            value.contains(",") || value.contains("\"") || value.contains("\n")
                ? "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
                : value
        }

        func centsString(_ valueInCents: Int?) -> String {
            guard let valueInCents else { return "" }
            return String(format: "%.2f", Double(valueInCents) / 100.0)
        }

        var rows = [headers]
        for order in orders {
            let row = [
                escapeCSV(dateFormatter.string(from: order.createdAt)),
                escapeCSV(order.orderNumber.map { String($0) } ?? ""),
                escapeCSV(order.customerName),
                escapeCSV(order.customerEmail),
                escapeCSV(order.productName),
                escapeCSV(order.variantName ?? ""),
                escapeCSV(order.provider.displayName),
                escapeCSV(order.status.rawValue),
                centsString(order.subtotal),
                centsString(order.tax),
                centsString(order.discountTotal),
                String(format: "%.2f", Double(order.total) / 100.0),
                escapeCSV(order.currency),
                order.refundedAt.map { dateFormatter.string(from: $0) } ?? "",
            ]
            rows.append(row.joined(separator: ","))
        }

        let safeScope = scopeLabel
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
        let filename = "SaneSales-Export-\(safeScope)-\(fileDateFormatter.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

#if os(iOS)
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]
        func makeUIViewController(context _: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }

        func updateUIViewController(_: UIActivityViewController, context _: Context) {}
    }
#else
    struct ShareSheet: View {
        let activityItems: [Any]
        var body: some View {
            if let url = activityItems.first as? URL {
                VStack(spacing: 16) {
                    Text("Export Ready")
                        .font(.headline)
                    Text(url.lastPathComponent)
                        .font(.saneSubheadline)
                        .foregroundStyle(Color.textMuted)
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                    .buttonStyle(SaneActionButtonStyle(prominent: true))
                }
                .padding(40)
            }
        }
    }
#endif

extension SaneDiagnosticsService {
    static let shared = SaneDiagnosticsService(
        appName: "SaneSales",
        subsystem: Bundle.main.bundleIdentifier ?? "com.sanesales.app",
        githubRepo: "SaneSales",
        settingsCollector: { await collectSaneSalesSettings() }
    )
}

@MainActor
private func collectSaneSalesSettings() -> String {
    let defaults = UserDefaults.standard
    let connectedProviders = [
        KeychainService.exists(account: KeychainService.lemonSqueezyAPIKey) ? "LemonSqueezy" : nil,
        KeychainService.exists(account: KeychainService.gumroadAPIKey) ? "Gumroad" : nil,
        KeychainService.exists(account: KeychainService.stripeAPIKey) ? "Stripe" : nil,
    ].compactMap { $0 }
    let providersSummary = connectedProviders.isEmpty ? "None" : connectedProviders.joined(separator: ", ")
    let demoMode = defaults.bool(forKey: "demo_mode")
    let hasSeenWelcome = defaults.bool(forKey: "hasSeenWelcome")

    #if os(macOS)
        let sharedDefaults = SharedStore.userDefaults()
        let showInMenuBar = defaults.object(forKey: "showInMenuBar") as? Bool ?? true
        let showInDock = defaults.object(forKey: "showInDock") as? Bool ?? true
        let showRevenueInMenuBar = defaults.object(forKey: "showRevenueInMenuBar") as? Bool ?? false
        let widgetsEnabled = sharedDefaults.bool(forKey: SharedStore.macOSWidgetsProEnabledKey)

        return """
        demoMode: \(demoMode)
        hasSeenWelcome: \(hasSeenWelcome)
        connectedProviders: \(providersSummary)

        settings:
          showInMenuBar: \(showInMenuBar)
          showRevenueInMenuBar: \(showRevenueInMenuBar)
          showInDock: \(showInDock)
          widgetsEnabled: \(widgetsEnabled)
        """
    #else
        return """
        demoMode: \(demoMode)
        hasSeenWelcome: \(hasSeenWelcome)
        connectedProviders: \(providersSummary)
        settings:
          platform: iOS
        """
    #endif
}
