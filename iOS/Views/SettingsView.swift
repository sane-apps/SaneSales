import SwiftUI

struct SettingsView: View {
    @Environment(SalesManager.self) private var manager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingKeyEntry = false
    @State private var editingProvider: SalesProviderType?
    @State private var newAPIKey = ""
    @State private var isValidating = false
    @State private var showError = false
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showRemoveConfirmation = false
    @State private var removingProvider: SalesProviderType?
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @AppStorage("demo_mode") private var demoMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                SaneBackground().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        #if os(macOS)
                            macOSAppearanceSection
                        #endif
                        providersSection
                        dataSection
                        aboutSection
                        trustTagline
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingKeyEntry) {
                apiKeySheet
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
        }
    }

    // MARK: - macOS Appearance Section

    #if os(macOS)
        @AppStorage("showInMenuBar") private var showInMenuBar = true
        @AppStorage("showInDock") private var showInDock = true
        @AppStorage("showRevenueInMenuBar") private var showRevenueInMenuBar = false

        private var macOSAppearanceSection: some View {
            GlassSection("Appearance", icon: "macwindow", iconColor: .blue) {
                VStack(spacing: 0) {
                    Toggle(isOn: Binding(
                        get: { showInMenuBar },
                        set: { newValue in
                            if !newValue, !showInDock { showInDock = true }
                            showInMenuBar = newValue
                        }
                    )) {
                        GlassRow("Show in Menu Bar", icon: "menubar.rectangle", iconColor: .salesGreen) {
                            EmptyView()
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    GlassDivider()

                    Toggle(isOn: Binding(
                        get: { showInDock },
                        set: { newValue in
                            if !newValue, !showInMenuBar { showInMenuBar = true }
                            showInDock = newValue
                        }
                    )) {
                        GlassRow("Show in Dock", icon: "dock.rectangle", iconColor: .blue) {
                            EmptyView()
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    if showInMenuBar {
                        GlassDivider()

                        Toggle(isOn: $showRevenueInMenuBar) {
                            GlassRow("Show Revenue in Menu Bar", iconAssetName: "CoinTemplate", iconColor: .salesGreen) {
                                EmptyView()
                            }
                        }
                        .toggleStyle(.switch)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    #endif

    // MARK: - Providers Section

    private var providersSection: some View {
        GlassSection("Providers", icon: "link.circle.fill", iconColor: .salesGreen) {
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
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.salesSuccess)
                        .font(.body)

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
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.textMuted)
                    }
                }
            } else {
                Button("Connect Account") {
                    editingProvider = provider
                    showingKeyEntry = true
                }
                .font(.saneSubheadlineBold)
                .foregroundStyle(Color.salesGreen)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - API Key Sheet

    private var apiKeySheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: editingProvider?.icon ?? "key.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(editingProvider?.brandColor ?? .salesGreen)
                    .padding(.top, 20)

                Text("Connect \(editingProvider?.displayName ?? "Provider") Account")
                    .font(.title3.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    SecureField("API Key", text: $newAPIKey)
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

                    Text("Used only to read your existing merchant data.")
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
                        showingKeyEntry = false
                        newAPIKey = ""
                        editingProvider = nil
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
                        .disabled(newAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        guard let provider = editingProvider else { return "" }
        switch provider {
        case .lemonSqueezy: return "lemonsqueezy.com \u{2192} Settings \u{2192} API"
        case .gumroad: return "gumroad.com \u{2192} Settings \u{2192} Advanced \u{2192} Applications"
        case .stripe: return "dashboard.stripe.com \u{2192} Developers \u{2192} API keys (use Secret key)"
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        GlassSection("Data", icon: "internaldrive", iconColor: .blue) {
            VStack(spacing: 0) {
                if let date = manager.lastUpdated {
                    GlassRow("Last Updated", icon: "clock", iconColor: .salesGreen) {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.saneSubheadline)
                    }
                    GlassDivider()
                }
                GlassRow("Cached Orders", icon: "list.bullet", iconColor: .blue) {
                    Text("\(manager.orders.count)")
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
                        iconColor: demoMode ? .orange : .purple
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
                    Button {
                        exportURL = exportOrdersCSV(manager.orders)
                        if exportURL != nil { showExportSheet = true }
                    } label: {
                        GlassRow("Export Orders (CSV)", icon: "square.and.arrow.up", iconColor: .blue) {
                            Image(systemName: "tablecells")
                                .foregroundStyle(Color.textMuted)
                        }
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
        GlassSection("About", icon: "info.circle", iconColor: .secondary) {
            VStack(spacing: 0) {
                GlassRow("Version", icon: "number", iconColor: .secondary) {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .font(.saneSubheadline)
                }
                GlassDivider()
                GlassRow("Build", icon: "hammer", iconColor: .secondary) {
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
                if let url = URL(string: "https://github.com/sane-apps/SaneSales/issues") {
                    Link(destination: url) {
                        GlassRow("Report Bug", icon: "ladybug", iconColor: .orange) {
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(Color.textMuted)
                                .font(.saneSubheadline)
                        }
                    }
                }
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
                if let url = URL(string: "mailto:hi@saneapps.com") {
                    Link(destination: url) {
                        GlassRow("Email Us", icon: "envelope", iconColor: .blue) {
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(Color.textMuted)
                                .font(.saneSubheadline)
                        }
                    }
                }
            }
        }
    }

    private var trustTagline: some View {
        Text("Made with love in the USA \u{00B7} 100% On-Device \u{00B7} No Analytics")
            .font(.saneCallout)
            .foregroundStyle(Color.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    // MARK: - Actions

    private func saveKey() {
        guard let provider = editingProvider else { return }
        isValidating = true
        let key = newAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            let success: Bool = switch provider {
            case .lemonSqueezy:
                await manager.setLemonSqueezyAPIKey(key)
            case .gumroad:
                await manager.setGumroadAPIKey(key)
            case .stripe:
                await manager.setStripeAPIKey(key)
            }
            isValidating = false
            if success {
                showingKeyEntry = false
                newAPIKey = ""
                editingProvider = nil
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
                default:
                    errorTitle = "Connection Failed"
                    errorMessage = "Could not connect with that key. Check it and try again."
                }
                showError = true
            }
        }
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
}

private extension SettingsView {
    func exportOrdersCSV(_ orders: [Order]) -> URL? {
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
                order.refundedAt.map { dateFormatter.string(from: $0) } ?? ""
            ]
            rows.append(row.joined(separator: ","))
        }

        let filename = "SaneSales-Export-\(fileDateFormatter.string(from: Date())).csv"
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
                    .buttonStyle(.borderedProminent)
                    .tint(Color.salesGreen)
                }
                .padding(40)
            }
        }
    }
#endif
