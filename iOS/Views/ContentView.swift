import SaneUI
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @Environment(SalesManager.self) private var manager

    var body: some View {
        MainTabView()
    }
}

private enum MainSection: Int, CaseIterable, Hashable {
    case dashboard
    case orders
    case products
    case settings

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .orders: "Orders"
        case .products: "Products"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "chart.bar.fill"
        case .orders: "list.bullet.rectangle"
        case .products: "shippingbox.fill"
        case .settings: "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedSection: MainSection
    #if os(macOS)
    @State private var previousNonSettingsContentSize: NSSize?
    #endif

    init() {
        _selectedSection = State(initialValue: Self.initialSectionSelection)
    }

    var body: some View {
        Group {
            #if os(macOS)
                macLayout
            #else
                iosLayout
            #endif
        }
        .tint(.salesGreen)
        .accessibilityIdentifier("main.tabView")
        .onReceive(NotificationCenter.default.publisher(for: .showSettingsTab)) { _ in
            selectedSection = .settings
        }
        #if os(macOS)
        .onAppear {
            applyWindowSize(for: selectedSection, previousSection: nil)
        }
        .onChange(of: selectedSection) { oldValue, newValue in
            applyWindowSize(for: newValue, previousSection: oldValue)
        }
        #endif
    }

    #if os(iOS)
    private var iosLayout: some View {
        TabView(selection: $selectedSection) {
            DashboardView()
                .tabItem { Label(MainSection.dashboard.title, systemImage: MainSection.dashboard.icon) }
                .tag(MainSection.dashboard)
            OrdersListView()
                .tabItem { Label(MainSection.orders.title, systemImage: MainSection.orders.icon) }
                .tag(MainSection.orders)
            ProductsView()
                .tabItem { Label(MainSection.products.title, systemImage: MainSection.products.icon) }
                .tag(MainSection.products)
            SettingsView()
                .tabItem { Label(MainSection.settings.title, systemImage: MainSection.settings.icon) }
                .tag(MainSection.settings)
        }
    }
    #endif

    #if os(macOS)
    private var macLayout: some View {
        HStack(spacing: 0) {
            macSidebar
            Divider().overlay(Color.white.opacity(0.08))
            selectedSectionView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(SaneBackground().ignoresSafeArea())
    }

    private var macSidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image("CoinColor")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("SaneSales")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Read sales clearly")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.84))
                }
            }
            .padding(.top, 8)

            VStack(spacing: 6) {
                ForEach(MainSection.allCases, id: \.self) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: section.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 18)
                            Text(section.title)
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedSection == section ? Color.salesGreen.opacity(0.22) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(selectedSection == section ? Color.salesGreen.opacity(0.45) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .frame(width: 228, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(Color.black.opacity(0.16))
    }
    #endif

    @ViewBuilder
    private var selectedSectionView: some View {
        switch selectedSection {
        case .dashboard:
            DashboardView()
        case .orders:
            OrdersListView()
        case .products:
            ProductsView()
        case .settings:
            SettingsView()
        }
    }

    private static var initialSectionSelection: MainSection {
        let args = CommandLine.arguments

        if let inlineValue = args.first(where: { $0.hasPrefix("--screenshot-tab=") })?
            .split(separator: "=", maxSplits: 1).last {
            return section(for: String(inlineValue))
        }

        if let index = args.firstIndex(of: "--screenshot-tab"),
           args.indices.contains(index + 1) {
            return section(for: args[index + 1])
        }

        return .dashboard
    }

    private static func section(for name: String) -> MainSection {
        switch name.lowercased() {
        case "dashboard":
            return .dashboard
        case "orders":
            return .orders
        case "products":
            return .products
        case "settings":
            return .settings
        default:
            return .dashboard
        }
    }

    #if os(macOS)
    private func applyWindowSize(
        for selectedSection: MainSection,
        previousSection: MainSection?,
        attempt: Int = 0
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let window = currentWindow() else {
                guard attempt < 8 else { return }
                applyWindowSize(for: selectedSection, previousSection: previousSection, attempt: attempt + 1)
                return
            }

            let currentContentSize = window.contentRect(forFrameRect: window.frame).size
            let isSettingsTab = selectedSection == .settings
            let wasSettingsTab = previousSection == .settings
            let metrics = SaneSalesWindowSizing.metrics(for: selectedSection)
            let minimumSize = metrics.minimum

            window.contentMinSize = minimumSize

            if isSettingsTab {
                if !wasSettingsTab, previousSection != nil {
                    previousNonSettingsContentSize = currentContentSize
                }

                if currentContentSize.width < metrics.minimum.width ||
                    currentContentSize.height < metrics.minimum.height {
                    window.setContentSize(metrics.preferred)
                    return
                }

                if !wasSettingsTab,
                   currentContentSize.width > metrics.preferred.width + 140 ||
                    currentContentSize.height > metrics.preferred.height + 120 {
                    window.setContentSize(metrics.preferred)
                    return
                }

                return
            }

            if previousSection == nil,
               currentContentSize.width < metrics.preferred.width ||
                currentContentSize.height < metrics.preferred.height {
                window.setContentSize(metrics.preferred)
                return
            }

            if currentContentSize.width < metrics.minimum.width
                || currentContentSize.height < metrics.minimum.height {
                window.setContentSize(metrics.minimum)
                return
            }

            guard wasSettingsTab, let previousNonSettingsContentSize else { return }
            let restoredSize = NSSize(
                width: max(previousNonSettingsContentSize.width, metrics.minimum.width),
                height: max(previousNonSettingsContentSize.height, metrics.minimum.height)
            )
            guard abs(currentContentSize.width - restoredSize.width) > 1 ||
                abs(currentContentSize.height - restoredSize.height) > 1 else {
                return
            }

            window.setContentSize(restoredSize)
        }
    }

    private func currentWindow() -> NSWindow? {
        if let mainWindow = WindowActionStorage.shared.mainWindow {
            return mainWindow
        }

        return NSApp.keyWindow ?? NSApp.windows.first(where: { $0.canBecomeMain && !$0.isSheet })
    }
    #endif
}

#if os(macOS)
private enum SaneSalesWindowSizing {
    struct Metrics {
        let minimum: NSSize
        let preferred: NSSize
    }

    static let dashboard = Metrics(
        minimum: NSSize(width: 920, height: 600),
        preferred: NSSize(width: 1180, height: 760)
    )

    static let orders = Metrics(
        minimum: NSSize(width: 980, height: 620),
        preferred: NSSize(width: 1240, height: 780)
    )

    static let products = Metrics(
        minimum: NSSize(width: 960, height: 600),
        preferred: NSSize(width: 1200, height: 760)
    )

    static let settings = Metrics(
        minimum: NSSize(width: 860, height: 560),
        preferred: NSSize(width: 1040, height: 680)
    )

    static func metrics(for section: MainSection) -> Metrics {
        switch section {
        case .orders:
            orders
        case .products:
            products
        case .settings:
            settings
        case .dashboard:
            dashboard
        }
    }
}
#endif

extension Notification.Name {
    static let showSettingsTab = Notification.Name("com.sanesales.showSettingsTab")
    static let showSettingsProviderSetup = Notification.Name("com.sanesales.showSettingsProviderSetup")
}

// MARK: - Onboarding

struct OnboardingView: View {
    private let phi: CGFloat = 1.618
    private let providerOptions: [SalesProviderType] = [.lemonSqueezy, .gumroad, .stripe]
    @Environment(SalesManager.self) private var manager
    @Environment(LicenseService.self) private var licenseService
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var selectedProvider: SalesProviderType = .lemonSqueezy
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var showError = false
    @State private var errorTitle = "Connection Failed"
    @State private var errorMessage = "Could not connect with that key. Check it and try again."

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                GeometryReader { proxy in
                    let baseUnit = max(8, min(16, proxy.size.height / 56))
                    let sectionSpacing = baseUnit * phi
                    let horizontalPadding = max(18, proxy.size.width / 19)

                    ScrollView {
                        VStack(spacing: sectionSpacing) {
                            heroSection
                            quickStartSection
                            providerPicker
                            keyEntrySection
                            connectButton
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, max(8, proxy.safeAreaInsets.top * 0.38))
                        .padding(.bottom, max(baseUnit, proxy.safeAreaInsets.bottom + baseUnit * 0.6))
                        .frame(
                            minHeight: proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom,
                            alignment: .top
                        )
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .accessibilityIdentifier("onboarding.view")
            .alert(errorTitle, isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .task {
                if licenseService.usesAppStorePurchase {
                    await licenseService.preloadAppStoreProduct()
                }
            }
        }
    }

    private var backgroundGradient: some View {
        SaneBackground()
            .ignoresSafeArea()
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image("CoinColor")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.bottom, 4)

            Text("SaneSales")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))

            Text("Track sales from your existing\nLemon Squeezy, Gumroad, and Stripe accounts.")
                .font(.body)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("START FREE OR UPGRADE")
                .font(.saneSectionHeader)
                .foregroundStyle(Color.textMuted)
                .tracking(0.5)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 12) {
                Text("Choose how you want to start")
                    .font(.saneSubheadlineBold)
                    .foregroundStyle(.white)

                Text("Try demo data right away, unlock Pro now, or connect your existing store below.")
                    .font(.saneFootnote)
                    .foregroundStyle(Color.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                demoButton

                if licenseService.usesAppStorePurchase {
                    Button {
                        Task { await licenseService.purchasePro() }
                    } label: {
                        Text(
                            licenseService.isPurchasing
                                ? "Processing..."
                                : "Unlock Pro — " + (licenseService.appStoreDisplayPrice ?? "$6.99")
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaneActionButtonStyle(prominent: true))
                    .disabled(licenseService.isPurchasing)
                    .accessibilityIdentifier("onboarding.unlockProButton")

                    Button("Restore Purchases") {
                        Task { await licenseService.restorePurchases() }
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .disabled(licenseService.isPurchasing)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("onboarding.restorePurchasesButton")
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.teal.opacity(colorScheme == .dark ? 0.38 : 0.22), lineWidth: 1)
                    )
            )
        }
    }

    private var providerPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CHOOSE A PROVIDER")
                .font(.saneSectionHeader)
                .foregroundStyle(Color.textMuted)
                .tracking(0.5)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(providerOptions.enumerated()), id: \.element) { index, provider in
                    if index > 0 { Divider().padding(.leading, 48) }
                    Button {
                        guard !isValidating else { return }
                        selectedProvider = provider
                        apiKey = ""
                    } label: {
                        let isSelected = selectedProvider == provider
                        HStack(spacing: 12) {
                            Image(systemName: provider.icon)
                                .foregroundStyle(provider.brandColor)
                                .frame(width: 22)
                                .font(.saneSubheadline)
                            Text(provider.displayName)
                                .font(.saneSubheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedProvider == provider {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.salesGreen)
                                    .font(.body)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? provider.brandColor.opacity(0.12) : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? provider.brandColor.opacity(0.45) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isValidating)
                    .accessibilityIdentifier("onboarding.provider.\(provider.rawValue)")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.brandBlueGlow.opacity(colorScheme == .dark ? 0.08 : 0.04))
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        Color.brandBlueGlow.opacity(colorScheme == .dark ? 0.20 : 0.12),
                        lineWidth: 1
                    )
            )
        }
    }

    private var keyEntrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(selectedProvider.displayName) API Key")
                .font(.saneSubheadline)
                .foregroundStyle(Color.textMuted)
                .padding(.leading, 4)
                .accessibilityIdentifier("onboarding.apiKeyLabel")

            SecureField("Paste your API key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .autocorrectionDisabled()
#if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
#endif
                .accessibilityIdentifier("onboarding.apiKeyField")

            Text(keyHelpText)
                .font(.saneFootnote)
                .foregroundStyle(Color.textMuted)
                .padding(.leading, 4)
                .accessibilityIdentifier("onboarding.apiKeyHelp")

            Text("Reads your existing sales data. Nothing is modified.")
                .font(.saneFootnote)
                .foregroundStyle(Color.textMuted)
                .padding(.leading, 4)
        }
    }

    private var keyHelpText: String {
        switch selectedProvider {
        case .lemonSqueezy: "lemonsqueezy.com \u{2192} Settings \u{2192} API"
        case .gumroad: "gumroad.com \u{2192} Settings \u{2192} Advanced \u{2192} Applications"
        case .stripe: "dashboard.stripe.com \u{2192} Developers \u{2192} API keys (use Secret key)"
        }
    }

    private var connectButton: some View {
        Button {
            validateAndSave()
        } label: {
            Group {
                if isValidating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Connect Account")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
        }
        .buttonStyle(SaneActionButtonStyle(prominent: true))
        .disabled(normalizedAPIKey.isEmpty || isValidating)
        .accessibilityIdentifier("onboarding.connectButton")
    }

    private var demoButton: some View {
        Button("Try Demo Data") {
            hasSeenWelcome = true
            manager.enableDemoMode()
        }
        .buttonStyle(SaneActionButtonStyle())
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("onboarding.demoButton")
    }

    private func validateAndSave() {
        guard !normalizedAPIKey.isEmpty else {
            showError = true
            return
        }
        isValidating = true
        let key = normalizedAPIKey
        let provider = selectedProvider
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
                hasSeenWelcome = true
            } else {
                switch manager.error {
                case .invalidAPIKey:
                    errorTitle = "Invalid API Key"
                    errorMessage = "The server rejected this key. Check it and try again."
                case .networkError:
                    errorTitle = "Connection Failed"
                    errorMessage = "Couldn't reach the server. Check your connection and try again."
                case .rateLimited:
                    errorTitle = "Rate Limited"
                    errorMessage = "Too many requests. Wait a moment and try again."
                case let .serverError(code):
                    errorTitle = "Server Error"
                    errorMessage = "The server returned an error (\(code)). Try again later."
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

    private var normalizedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
