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

struct MainTabView: View {
    @State private var selectedTab: Int
    #if os(macOS)
    @State private var previousNonSettingsContentSize: NSSize?
    #endif

    init() {
        _selectedTab = State(initialValue: Self.initialTabSelection)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            OrdersListView()
                .tabItem {
                    Label("Orders", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            ProductsView()
                .tabItem {
                    Label("Products", systemImage: "shippingbox.fill")
                }
                .tag(2)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.salesGreen)
        .accessibilityIdentifier("main.tabView")
        .onReceive(NotificationCenter.default.publisher(for: .showSettingsTab)) { _ in
            selectedTab = 3
        }
        #if os(macOS)
            .onAppear {
                applyWindowSize(for: selectedTab, previousTab: nil)
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                applyWindowSize(for: newValue, previousTab: oldValue)
            }
        #endif
    }

    private static var initialTabSelection: Int {
        let args = CommandLine.arguments

        if let inlineValue = args.first(where: { $0.hasPrefix("--screenshot-tab=") })?
            .split(separator: "=", maxSplits: 1).last {
            return tabIndex(for: String(inlineValue))
        }

        if let index = args.firstIndex(of: "--screenshot-tab"),
           args.indices.contains(index + 1) {
            return tabIndex(for: args[index + 1])
        }

        return 0
    }

    private static func tabIndex(for name: String) -> Int {
        switch name.lowercased() {
        case "dashboard":
            return 0
        case "orders":
            return 1
        case "products":
            return 2
        case "settings":
            return 3
        default:
            return 0
        }
    }

    #if os(macOS)
    private func applyWindowSize(for selectedTab: Int, previousTab: Int?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let window = currentWindow() else { return }

            let currentContentSize = window.contentRect(forFrameRect: window.frame).size
            let isSettingsTab = selectedTab == 3
            let wasSettingsTab = previousTab == 3
            let metrics = SaneSalesWindowSizing.metrics(for: selectedTab)
            let minimumSize = metrics.minimum

            window.contentMinSize = minimumSize

            if isSettingsTab {
                if !wasSettingsTab, previousTab != nil {
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

            if previousTab == nil,
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
        minimum: NSSize(width: 820, height: 560),
        preferred: NSSize(width: 1020, height: 700)
    )

    static let orders = Metrics(
        minimum: NSSize(width: 900, height: 560),
        preferred: NSSize(width: 1080, height: 700)
    )

    static let products = Metrics(
        minimum: NSSize(width: 860, height: 540),
        preferred: NSSize(width: 980, height: 680)
    )

    static let settings = Metrics(
        minimum: NSSize(width: 640, height: 460),
        preferred: NSSize(width: 700, height: 500)
    )

    static func metrics(for tab: Int) -> Metrics {
        switch tab {
        case 1:
            orders
        case 2:
            products
        case 3:
            settings
        default:
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
