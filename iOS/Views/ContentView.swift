import SwiftUI

struct ContentView: View {
    @Environment(SalesManager.self) private var manager

    var body: some View {
        if manager.isConnected {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

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
        #if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: .showSettingsTab)) { _ in
                selectedTab = 3
            }
        #endif
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    private let phi: CGFloat = 1.618
    private let providerOptions: [SalesProviderType] = [.lemonSqueezy, .gumroad, .stripe]
    @Environment(SalesManager.self) private var manager
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedProvider: SalesProviderType = .lemonSqueezy
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var showError = false

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
                            providerPicker
                            keyEntrySection
                            connectButton
                            demoButton
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
            .alert("Invalid API Key", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text("Could not connect with that key. Check it and try again.")
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
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("Track sales from your existing\nLemon Squeezy, Gumroad, and Stripe accounts.")
                .font(.body)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
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

            SecureField("Paste your API key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .autocorrectionDisabled()

            Text(keyHelpText)
                .font(.saneFootnote)
                .foregroundStyle(Color.textMuted)
                .padding(.leading, 4)

            Text("Read-only connection. No checkout links and no in-app purchasing.")
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
        .buttonStyle(.borderedProminent)
        .tint(.salesGreen)
        .controlSize(.large)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .disabled(normalizedAPIKey.isEmpty || isValidating)
    }

    private var demoButton: some View {
        Button("Try Demo Data") {
            manager.enableDemoMode()
        }
        .buttonStyle(.bordered)
        .tint(.salesGreen)
        .controlSize(.large)
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
            if !success { showError = true }
        }
    }

    private var normalizedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
