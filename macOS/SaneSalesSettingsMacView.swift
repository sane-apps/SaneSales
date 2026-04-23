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

    var title: String {
        switch self {
        case .general:
            SaneSalesSettingsCopy.tabGeneralTitle
        case .providers:
            SaneSalesSettingsCopy.tabProvidersTitle
        case .data:
            SaneSalesSettingsCopy.tabDataTitle
        case .license:
            SaneSalesSettingsCopy.tabLicenseTitle
        case .about:
            SaneSalesSettingsCopy.tabAboutTitle
        }
    }

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
        SaneSettingsContainer(
            defaultTab: .general,
            selection: $selectedTab,
            windowSizing: .embedded
        ) { tab in
            currentTabView(for: tab)
        }
        .sheet(item: $editingProvider) { provider in
            apiKeySheet(for: provider)
        }
        .confirmationDialog(
            SaneSalesSettingsCopy.disconnectConfirmationTitle(providerName: removingProvider?.displayName),
            isPresented: $showRemoveConfirmation
        ) {
            Button(SaneSalesSettingsCopy.disconnectButtonTitle, role: .destructive) {
                if let provider = removingProvider {
                    disconnectProvider(provider)
                }
            }
        } message: {
            Text(SaneSalesSettingsCopy.disconnectConfirmationMessage)
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
        }
    }

    @ViewBuilder
    private func currentTabView(for tab: SaneSalesSettingsTab) -> some View {
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

    private var generalTab: some View {
        settingsScrollView {
            CompactSection(SaneSalesSettingsCopy.appearanceSectionTitle, icon: "paintpalette", iconColor: SaneSettingsIconSemantic.appearance.color) {
                if licenseService.isPro {
                    CompactToggle(
                        label: SaneSalesSettingsCopy.showInMenuBarLabel,
                        icon: "menubar.rectangle",
                        iconColor: .white,
                        isOn: showInMenuBarBinding
                    )

                    if showInMenuBar {
                        CompactDivider()
                        CompactToggle(
                            label: SaneSalesSettingsCopy.showRevenueInMenuBarLabel,
                            icon: "dollarsign.circle",
                            iconColor: .white,
                            isOn: $showRevenueInMenuBar
                        )
                    }

                    CompactDivider()
                    CompactRow(SaneSalesSettingsCopy.desktopWidgetsLabel, icon: "widget.small", iconColor: .white) {
                        StatusBadge(widgetsStatusTitle, color: widgetsStatusColor)
                    }
                } else {
                    CompactRow(SaneSalesSettingsCopy.showInMenuBarLabel, icon: "menubar.rectangle", iconColor: .white) {
                        StatusBadge(
                            SaneSalesSettingsCopy.licenseLabels.proBadgeTitle,
                            color: SaneSettingsIconSemantic.license.color,
                            icon: "lock.fill"
                        )
                    }

                    CompactDivider()
                    CompactRow(SaneSalesSettingsCopy.desktopWidgetsLabel, icon: "widget.small", iconColor: .white) {
                        StatusBadge(
                            SaneSalesSettingsCopy.licenseLabels.proBadgeTitle,
                            color: SaneSettingsIconSemantic.license.color,
                            icon: "lock.fill"
                        )
                    }

                    CompactDivider()
                    hint(SaneSalesSettingsCopy.appearanceUnlockHint)

                    CompactDivider()
                    CompactRow(
                        SaneSalesSettingsCopy.licenseLabels.actionsLabel,
                        icon: "sparkles",
                        iconColor: SaneSettingsIconSemantic.license.color
                    ) {
                        Button {
                            proUpsellFeature = .menuBar
                        } label: {
                            actionLabel(SaneSalesSettingsCopy.unlockProButtonTitle)
                        }
                        .buttonStyle(SaneActionButtonStyle())
                    }
                }

                CompactDivider()
                SaneDockIconToggle(showDockIcon: showInDockBinding)
                CompactDivider()
                hint(SaneSalesSettingsCopy.availabilityHint)
            }

            SaneLanguageSettingsRow(labels: SaneSalesSettingsCopy.languageLabels)

            #if !APP_STORE
                CompactSection(
                    SaneSalesSettingsCopy.softwareUpdatesSectionTitle,
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .saneAccent
                ) {
                    SaneSparkleRow(
                        automaticallyChecks: $automaticallyChecksForUpdates,
                        checkFrequency: $updateCheckFrequency,
                        labels: SaneSalesSettingsCopy.sparkleLabels,
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
            CompactSection(SaneSalesSettingsCopy.providersSectionTitle, icon: "link.circle.fill", iconColor: SaneSettingsIconSemantic.sync.color) {
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
            CompactSection(SaneSalesSettingsCopy.snapshotSectionTitle, icon: "internaldrive", iconColor: SaneSettingsIconSemantic.storage.color) {
                if let date = manager.lastUpdated {
                    CompactRow(SaneSalesSettingsCopy.lastUpdatedLabel, icon: "clock", iconColor: .white) {
                        valueText(date.formatted(date: .abbreviated, time: .shortened))
                    }
                    CompactDivider()
                }

                CompactRow(SaneSalesSettingsCopy.cachedOrdersLabel, icon: "list.bullet.rectangle", iconColor: .white) {
                    valueText("\(manager.orders.count)")
                }
                CompactDivider()
                CompactRow(SaneSalesSettingsCopy.productsLabel, icon: "shippingbox.fill", iconColor: .white) {
                    valueText("\(manager.products.count)")
                }
                CompactDivider()
                CompactToggle(
                    label: SaneSalesSettingsCopy.demoModeLabel,
                    icon: demoMode ? "sparkles" : "sparkles",
                    iconColor: demoMode ? SaneSettingsIconSemantic.content.color : .white,
                    isOn: demoModeBinding
                )
            }

            CompactSection(SaneSalesSettingsCopy.actionsSectionTitle, icon: "bolt.fill", iconColor: SaneSettingsIconSemantic.general.color) {
                CompactRow(SaneSalesSettingsCopy.refreshDataLabel, icon: "arrow.clockwise", iconColor: .white) {
                    Button {
                        Task { await manager.refresh() }
                    } label: {
                        actionLabel(manager.isLoading ? SaneSalesSettingsCopy.refreshingButtonTitle : SaneSalesSettingsCopy.refreshButtonTitle)
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .disabled(manager.isLoading)
                }

                if !manager.orders.isEmpty {
                    CompactDivider()
                    CompactRow(SaneSalesSettingsCopy.exportOrdersCSVLabel, icon: "tablecells", iconColor: .white) {
                        if manager.isPro {
                            Button {
                                exportURL = exportOrdersCSV(manager.orders)
                                showExportSheet = exportURL != nil
                            } label: {
                                actionLabel(SaneSalesSettingsCopy.exportButtonTitle)
                            }
                            .buttonStyle(SaneActionButtonStyle())
                        } else {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 8) {
                                    StatusBadge(SaneSalesSettingsCopy.licenseLabels.proBadgeTitle, color: SaneSettingsIconSemantic.license.color, icon: "lock.fill")
                                    Button {
                                        proUpsellFeature = .csvExport
                                    } label: {
                                        actionLabel(SaneSalesSettingsCopy.unlockButtonTitle)
                                    }
                                    .buttonStyle(SaneActionButtonStyle())
                                }

                                VStack(alignment: .trailing, spacing: 8) {
                                    StatusBadge(SaneSalesSettingsCopy.licenseLabels.proBadgeTitle, color: SaneSettingsIconSemantic.license.color, icon: "lock.fill")
                                    Button {
                                        proUpsellFeature = .csvExport
                                    } label: {
                                        actionLabel(SaneSalesSettingsCopy.unlockButtonTitle)
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
            LicenseSettingsView(
                licenseService: licenseService,
                style: .panel,
                labels: SaneSalesSettingsCopy.licenseLabels
            )
        }
    }

    private var aboutTab: some View {
        SaneAboutView(
            appName: "SaneSales",
            githubRepo: "SaneSales",
            diagnosticsService: .shared,
            licenses: saneSalesAboutLicenses(),
            feedbackExtraAttachments: [("link.circle.fill", SaneSalesSettingsCopy.providerSummaryAttachmentLabel)],
            labels: SaneSalesSettingsCopy.aboutLabels
        )
    }

    @ViewBuilder
    private func providerRow(_ provider: SalesProviderType, isConnected: Bool) -> some View {
        CompactRow(provider.displayName, icon: provider.icon, iconColor: provider.brandColor) {
            if isConnected {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        StatusBadge(SaneSalesSettingsCopy.connectedStatusTitle, color: .green, icon: "checkmark.circle.fill")
                        Menu {
                            Button(SaneSalesSettingsCopy.changeKeyButtonTitle) {
                                beginEditing(provider)
                            }
                            Button(SaneSalesSettingsCopy.disconnectButtonTitle, role: .destructive) {
                                removingProvider = provider
                                showRemoveConfirmation = true
                            }
                        } label: {
                            actionLabel(SaneSalesSettingsCopy.manageButtonTitle)
                        }
                        .buttonStyle(SaneActionButtonStyle())
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        StatusBadge(SaneSalesSettingsCopy.connectedStatusTitle, color: .green, icon: "checkmark.circle.fill")
                        Menu {
                            Button(SaneSalesSettingsCopy.changeKeyButtonTitle) {
                                beginEditing(provider)
                            }
                            Button(SaneSalesSettingsCopy.disconnectButtonTitle, role: .destructive) {
                                removingProvider = provider
                                showRemoveConfirmation = true
                            }
                        } label: {
                            actionLabel(SaneSalesSettingsCopy.manageButtonTitle)
                        }
                        .buttonStyle(SaneActionButtonStyle())
                    }
                }
            } else {
                Button {
                    beginEditing(provider)
                } label: {
                    actionLabel(SaneSalesSettingsCopy.connectButtonTitle)
                }
                .buttonStyle(SaneActionButtonStyle())
            }
        }
    }

    private func beginEditing(_ provider: SalesProviderType) {
        if manager.requiresProForProviderConnection(provider) {
            Task.detached {
                await EventTracker.log("second_provider_attempt", app: "sanesales")
            }
            proUpsellFeature = .multipleProviders
            return
        }

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
        widgetsEnabled ? SaneSalesSettingsCopy.widgetsEnabledTitle : SaneSalesSettingsCopy.widgetsReadyTitle
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

                Text(SaneSalesSettingsCopy.connectAccountTitle(providerName: provider.displayName))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    SecureField(SaneSalesSettingsCopy.apiKeyPlaceholder, text: $newAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .autocorrectionDisabled()

                    Text(keyHelpText(for: provider))
                        .font(.saneCallout)
                        .foregroundStyle(Color.textMuted)

                    Text(SaneSalesSettingsCopy.apiKeyReadOnlyHint)
                        .font(.saneFootnote)
                        .foregroundStyle(Color.textMuted)
                }
                .padding(.horizontal)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(SaneSalesSettingsCopy.cancelButtonTitle) {
                        editingProvider = nil
                        newAPIKey = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isValidating {
                        ProgressView()
                            .tint(.salesGreen)
                    } else {
                        Button(SaneSalesSettingsCopy.saveButtonTitle) {
                            saveKey(for: provider)
                        }
                        .disabled(newAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .tint(.salesGreen)
                    }
                }
            }
            .alert(errorTitle, isPresented: $showError) {
                Button(SaneSalesSettingsCopy.okButtonTitle) {}
            } message: {
                Text(errorMessage)
            }
        }
        .frame(width: 420, height: 320)
    }

    private func keyHelpText(for provider: SalesProviderType) -> String {
        switch provider {
        case .lemonSqueezy:
            SaneSalesSettingsCopy.lemonSqueezyAPIHelpText
        case .gumroad:
            SaneSalesSettingsCopy.gumroadAPIHelpText
        case .stripe:
            SaneSalesSettingsCopy.stripeAPIHelpText
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
                errorTitle = SaneSalesSettingsCopy.invalidAPIKeyTitle
                errorMessage = SaneSalesSettingsCopy.invalidAPIKeyMessage
            case .networkError:
                errorTitle = SaneSalesSettingsCopy.connectionFailedTitle
                errorMessage = SaneSalesSettingsCopy.networkErrorMessage
            case .rateLimited:
                errorTitle = SaneSalesSettingsCopy.rateLimitedTitle
                errorMessage = SaneSalesSettingsCopy.rateLimitedMessage
            case let .serverError(code):
                errorTitle = SaneSalesSettingsCopy.serverErrorTitle
                errorMessage = SaneSalesSettingsCopy.serverErrorMessage(code: code)
            default:
                errorTitle = SaneSalesSettingsCopy.connectionFailedTitle
                errorMessage = SaneSalesSettingsCopy.genericConnectionFailedMessage
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
