#if os(macOS)
import AppKit
import SaneUI
import SwiftUI

private enum SaneSalesSettingsTab: String, SaneSettingsTab {
    case general = "General"
    case providers = "Providers"
    case data = "Data"
    case license = "License"
    case about = "About"

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .providers: "link.circle.fill"
        case .data: "internaldrive"
        case .license: "key.fill"
        case .about: "info.circle"
        }
    }

    var iconColor: Color {
        switch self {
        case .general:
            SaneSettingsIconSemantic.general.color
        case .providers:
            SaneSettingsIconSemantic.sync.color
        case .data:
            SaneSettingsIconSemantic.storage.color
        case .license:
            SaneSettingsIconSemantic.license.color
        case .about:
            SaneSettingsIconSemantic.about.color
        }
    }
}

struct SaneSalesMacSettingsView: View {
    @Environment(SalesManager.self) private var manager
    @Environment(LicenseService.self) private var licenseService

    @AppStorage("demo_mode") private var demoMode = false
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("showInDock") private var showInDock = SaneBackgroundAppDefaults.showDockIcon
    @AppStorage("showRevenueInMenuBar") private var showRevenueInMenuBar = false

    @State private var selectedTab: SaneSalesSettingsTab?
    @State private var editingProvider: SalesProviderType?
    @State private var newAPIKey = ""
    @State private var isValidating = false
    @State private var showError = false
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var removingProvider: SalesProviderType?
    @State private var showRemoveConfirmation = false
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var proUpsellFeature: ProFeature?

    #if !APP_STORE
        @State private var automaticallyChecksForUpdates = UpdateService.shared.automaticallyChecksForUpdates
        @State private var updateCheckFrequency = UpdateService.shared.updateCheckFrequency
    #endif

    init() {
        _selectedTab = State(initialValue: Self.initialSettingsTab)
    }

    var body: some View {
        SaneSettingsContainer(defaultTab: .general, selection: $selectedTab, windowSizing: .embedded) { tab in
            switch tab {
            case .general:
                generalTab
            case .providers:
                providersTab
            case .data:
                dataTab
            case .license:
                licenseTab
            case .about:
                aboutTab
            }
        }
        .sheet(item: $editingProvider) { provider in
            apiKeySheet(for: provider)
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
        .sheet(item: $proUpsellFeature) { feature in
            ProUpsellView(feature: feature, licenseService: licenseService)
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .onAppear {
            #if !APP_STORE
                automaticallyChecksForUpdates = UpdateService.shared.automaticallyChecksForUpdates
                updateCheckFrequency = UpdateService.shared.updateCheckFrequency
            #endif
            applyWindowSize(for: selectedTab)
        }
        .onChange(of: selectedTab) { _, newValue in
            applyWindowSize(for: newValue)
        }
    }

    private var generalTab: some View {
        settingsScrollView {
            CompactSection("Appearance", icon: "paintpalette", iconColor: SaneSettingsIconSemantic.appearance.color) {
                if licenseService.isPro {
                    CompactToggle(
                        label: "Show in Menu Bar",
                        icon: "menubar.rectangle",
                        iconColor: .white,
                        isOn: showInMenuBarBinding
                    )

                    if showInMenuBar {
                        CompactDivider()
                        CompactToggle(
                            label: "Show Revenue in Menu Bar",
                            icon: "dollarsign.circle",
                            iconColor: .white,
                            isOn: $showRevenueInMenuBar
                        )
                    }

                    CompactDivider()
                    CompactRow("Desktop Widgets", icon: "widget.small", iconColor: .white) {
                        StatusBadge(widgetsStatusTitle, color: widgetsStatusColor)
                    }
                } else {
                    CompactRow("Show in Menu Bar", icon: "menubar.rectangle", iconColor: .white) {
                        StatusBadge("Pro", color: SaneSettingsIconSemantic.license.color, icon: "lock.fill")
                    }

                    CompactDivider()
                    CompactRow("Desktop Widgets", icon: "widget.small", iconColor: .white) {
                        StatusBadge("Pro", color: SaneSettingsIconSemantic.license.color, icon: "lock.fill")
                    }

                    CompactDivider()
                    hint("Unlock Pro to keep revenue in your menu bar and add desktop widgets.")

                    CompactDivider()
                    CompactRow("Actions", icon: "sparkles", iconColor: SaneSettingsIconSemantic.license.color) {
                        Button {
                            proUpsellFeature = .menuBar
                        } label: {
                            actionLabel("Unlock Pro")
                        }
                        .buttonStyle(SaneActionButtonStyle())
                    }
                }

                CompactDivider()
                SaneDockIconToggle(showDockIcon: showInDockBinding)
                CompactDivider()
                hint("SaneSales always keeps either the Dock or menu bar available so you can reopen it.")
            }

            #if !APP_STORE
                CompactSection("Software Updates", icon: "arrow.triangle.2.circlepath", iconColor: .saneAccent) {
                    SaneSparkleRow(
                        automaticallyChecks: $automaticallyChecksForUpdates,
                        checkFrequency: $updateCheckFrequency,
                        onCheckNow: { UpdateService.shared.checkForUpdates() }
                    )
                    .onChange(of: automaticallyChecksForUpdates) { _, newValue in
                        UpdateService.shared.automaticallyChecksForUpdates = newValue
                    }
                    .onChange(of: updateCheckFrequency) { _, newValue in
                        UpdateService.shared.updateCheckFrequency = newValue
                    }
                }
            #endif
        }
    }

    private var providersTab: some View {
        settingsScrollView {
            CompactSection("Accounts", icon: "link.circle.fill", iconColor: SaneSettingsIconSemantic.sync.color) {
                providerRow(.lemonSqueezy, isConnected: manager.isLemonSqueezyConnected)
                CompactDivider()
                providerRow(.gumroad, isConnected: manager.isGumroadConnected)
                CompactDivider()
                providerRow(.stripe, isConnected: manager.isStripeConnected)
            }
        }
    }

    private var dataTab: some View {
        settingsScrollView {
            CompactSection("Snapshot", icon: "internaldrive", iconColor: SaneSettingsIconSemantic.storage.color) {
                if let date = manager.lastUpdated {
                    CompactRow("Last Updated", icon: "clock", iconColor: .white) {
                        valueText(date.formatted(date: .abbreviated, time: .shortened))
                    }
                    CompactDivider()
                }

                CompactRow("Cached Orders", icon: "list.bullet.rectangle", iconColor: .white) {
                    valueText("\(manager.orders.count)")
                }
                CompactDivider()
                CompactRow("Products", icon: "shippingbox.fill", iconColor: .white) {
                    valueText("\(manager.products.count)")
                }
                CompactDivider()
                CompactToggle(
                    label: "Demo Mode",
                    icon: demoMode ? "sparkles" : "sparkles",
                    iconColor: demoMode ? SaneSettingsIconSemantic.content.color : .white,
                    isOn: demoModeBinding
                )
            }

            CompactSection("Actions", icon: "bolt.fill", iconColor: SaneSettingsIconSemantic.general.color) {
                CompactRow("Refresh Data", icon: "arrow.clockwise", iconColor: .white) {
                    Button {
                        Task { await manager.refresh() }
                    } label: {
                        actionLabel(manager.isLoading ? "Refreshing..." : "Refresh")
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .disabled(manager.isLoading)
                }

                if !manager.orders.isEmpty {
                    CompactDivider()
                    CompactRow("Export Orders (CSV)", icon: "tablecells", iconColor: .white) {
                        if manager.isPro {
                            Button {
                                exportURL = exportOrdersCSV(manager.orders)
                                showExportSheet = exportURL != nil
                            } label: {
                                actionLabel("Export")
                            }
                            .buttonStyle(SaneActionButtonStyle())
                        } else {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 8) {
                                    StatusBadge("Pro", color: SaneSettingsIconSemantic.license.color, icon: "lock.fill")
                                    Button {
                                        proUpsellFeature = .csvExport
                                    } label: {
                                        actionLabel("Unlock")
                                    }
                                    .buttonStyle(SaneActionButtonStyle())
                                }

                                VStack(alignment: .trailing, spacing: 8) {
                                    StatusBadge("Pro", color: SaneSettingsIconSemantic.license.color, icon: "lock.fill")
                                    Button {
                                        proUpsellFeature = .csvExport
                                    } label: {
                                        actionLabel("Unlock")
                                    }
                                    .buttonStyle(SaneActionButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var licenseTab: some View {
        settingsScrollView(maxWidth: 460) {
            LicenseSettingsView(licenseService: licenseService, style: .panel)
        }
    }

    private var aboutTab: some View {
        SaneAboutView(
            appName: "SaneSales",
            githubRepo: "SaneSales",
            diagnosticsService: .shared,
            licenses: saneSalesAboutLicenses(),
            feedbackExtraAttachments: [("link.circle.fill", "Connected providers and local cache summary")]
        )
    }

    @ViewBuilder
    private func providerRow(_ provider: SalesProviderType, isConnected: Bool) -> some View {
        CompactRow(provider.displayName, icon: provider.icon, iconColor: provider.brandColor) {
            if isConnected {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        StatusBadge("Connected", color: .green, icon: "checkmark.circle.fill")
                        Menu {
                            Button("Change Key") {
                                beginEditing(provider)
                            }
                            Button("Disconnect", role: .destructive) {
                                removingProvider = provider
                                showRemoveConfirmation = true
                            }
                        } label: {
                            actionLabel("Manage")
                        }
                        .buttonStyle(SaneActionButtonStyle())
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        StatusBadge("Connected", color: .green, icon: "checkmark.circle.fill")
                        Menu {
                            Button("Change Key") {
                                beginEditing(provider)
                            }
                            Button("Disconnect", role: .destructive) {
                                removingProvider = provider
                                showRemoveConfirmation = true
                            }
                        } label: {
                            actionLabel("Manage")
                        }
                        .buttonStyle(SaneActionButtonStyle())
                    }
                }
            } else if manager.needsProForAdditionalProvider {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        StatusBadge("Pro", color: SaneSettingsIconSemantic.license.color, icon: "lock.fill")
                        Button {
                            proUpsellFeature = .multipleProviders
                        } label: {
                            actionLabel("Unlock")
                        }
                        .buttonStyle(SaneActionButtonStyle())
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        StatusBadge("Pro", color: SaneSettingsIconSemantic.license.color, icon: "lock.fill")
                        Button {
                            proUpsellFeature = .multipleProviders
                        } label: {
                            actionLabel("Unlock")
                        }
                        .buttonStyle(SaneActionButtonStyle())
                    }
                }
            } else {
                Button {
                    beginEditing(provider)
                } label: {
                    actionLabel("Connect")
                }
                .buttonStyle(SaneActionButtonStyle())
            }
        }
    }

    private func beginEditing(_ provider: SalesProviderType) {
        newAPIKey = ""
        editingProvider = provider
    }

    private func disconnectProvider(_ provider: SalesProviderType) {
        switch provider {
        case .lemonSqueezy:
            manager.removeLemonSqueezyAPIKey()
        case .gumroad:
            manager.removeGumroadAPIKey()
        case .stripe:
            manager.removeStripeAPIKey()
        }
    }

    private var showInMenuBarBinding: Binding<Bool> {
        Binding(
            get: { showInMenuBar },
            set: { newValue in
                if !newValue, !showInDock {
                    showInDock = true
                }
                showInMenuBar = newValue
            }
        )
    }

    private var showInDockBinding: Binding<Bool> {
        Binding(
            get: { showInDock },
            set: { newValue in
                if !newValue, !showInMenuBar {
                    showInMenuBar = true
                }
                showInDock = newValue
            }
        )
    }

    private var demoModeBinding: Binding<Bool> {
        Binding(
            get: { demoMode },
            set: { newValue in
                if newValue {
                    manager.enableDemoMode()
                } else {
                    manager.disableDemoMode()
                }
                demoMode = newValue
            }
        )
    }

    private var widgetsEnabled: Bool {
        SharedStore.userDefaults().bool(forKey: SharedStore.macOSWidgetsProEnabledKey)
    }

    private var widgetsStatusTitle: String {
        widgetsEnabled ? "Enabled" : "Ready"
    }

    private var widgetsStatusColor: Color {
        widgetsEnabled ? .green : .white
    }

    private static var initialSettingsTab: SaneSalesSettingsTab {
        let args = CommandLine.arguments

        if let inlineValue = args.first(where: { $0.hasPrefix("--screenshot-settings-tab=") })?
            .split(separator: "=", maxSplits: 1).last,
           let tab = SaneSalesSettingsTab(rawValue: String(inlineValue).capitalized) {
            return tab
        }

        if let index = args.firstIndex(of: "--screenshot-settings-tab"),
           args.indices.contains(index + 1),
           let tab = SaneSalesSettingsTab(rawValue: args[index + 1].capitalized) {
            return tab
        }

        return .general
    }

    private func applyWindowSize(for tab: SaneSalesSettingsTab?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.canBecomeMain && !$0.isSheet }) else {
                return
            }

            let metrics = SaneSalesSettingsWindowSizing.metrics(for: tab ?? .general)
            let currentContentSize = window.contentRect(forFrameRect: window.frame).size
            let widthDelta = abs(currentContentSize.width - metrics.preferred.width)
            let heightDelta = abs(currentContentSize.height - metrics.preferred.height)

            window.contentMinSize = metrics.minimum

            if currentContentSize.width < metrics.minimum.width ||
                currentContentSize.height < metrics.minimum.height ||
                widthDelta > 80 ||
                heightDelta > 80 {
                window.setContentSize(metrics.preferred)
            }
        }
    }

    private func valueText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }

    private func actionLabel(_ title: String) -> some View {
        Text(title)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
    }

    private func settingsScrollView<Content: View>(
        maxWidth: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 20)
            .frame(maxWidth: maxWidth ?? .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func apiKeySheet(for provider: SalesProviderType) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: provider.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(provider.brandColor)
                    .padding(.top, 20)

                Text("Connect \(provider.displayName) Account")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    SecureField("API Key", text: $newAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .autocorrectionDisabled()

                    Text(keyHelpText(for: provider))
                        .font(.saneCallout)
                        .foregroundStyle(Color.textMuted)

                    Text("Reads your existing sales data. Nothing is modified.")
                        .font(.saneFootnote)
                        .foregroundStyle(Color.textMuted)
                }
                .padding(.horizontal)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        editingProvider = nil
                        newAPIKey = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isValidating {
                        ProgressView()
                            .tint(.salesGreen)
                    } else {
                        Button("Save") {
                            saveKey(for: provider)
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
        .frame(width: 420, height: 320)
    }

    private func keyHelpText(for provider: SalesProviderType) -> String {
        switch provider {
        case .lemonSqueezy:
            "lemonsqueezy.com → Settings → API"
        case .gumroad:
            "gumroad.com → Settings → Advanced → Applications"
        case .stripe:
            "dashboard.stripe.com → Developers → API keys (use Secret key)"
        }
    }

    private func saveKey(for provider: SalesProviderType) {
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
                editingProvider = nil
                newAPIKey = ""
                return
            }

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

    private func exportOrdersCSV(_ orders: [Order]) -> URL? {
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

private enum SaneSalesSettingsWindowSizing {
    struct Metrics {
        let minimum: NSSize
        let preferred: NSSize
    }

    static func metrics(for tab: SaneSalesSettingsTab) -> Metrics {
        switch tab {
        case .general:
            Metrics(
                minimum: NSSize(width: 640, height: 500),
                preferred: NSSize(width: 700, height: 560)
            )
        case .providers:
            Metrics(
                minimum: NSSize(width: 640, height: 380),
                preferred: NSSize(width: 700, height: 430)
            )
        case .data:
            Metrics(
                minimum: NSSize(width: 640, height: 420),
                preferred: NSSize(width: 700, height: 480)
            )
        case .license:
            Metrics(
                minimum: NSSize(width: 640, height: 320),
                preferred: NSSize(width: 680, height: 360)
            )
        case .about:
            Metrics(
                minimum: NSSize(width: 640, height: 390),
                preferred: NSSize(width: 680, height: 430)
            )
        }
    }
}

private func saneSalesAboutLicenses() -> [SaneAboutView.LicenseEntry] {
    #if !APP_STORE
        [
            SaneAboutView.LicenseEntry(
                name: "Sparkle",
                url: "https://sparkle-project.org",
                text: """
                Copyright (c) 2006-2013 Andy Matuschak.
                Copyright (c) 2009-2013 Elgato Systems GmbH.

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """
            )
        ]
    #else
        []
    #endif
}
#endif
