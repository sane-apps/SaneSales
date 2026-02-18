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
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 40)
                        heroSection
                        providerPicker
                        keyEntrySection
                        connectButton
                        demoButton
                        Spacer()
                    }
                    .padding(.horizontal, 24)
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

            Text("Read-only sales tracking for your existing\nLemon Squeezy, Gumroad, and Stripe accounts.")
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
                ForEach([SalesProviderType.lemonSqueezy, .gumroad, .stripe], id: \.self) { provider in
                    if provider != .lemonSqueezy { Divider().padding(.leading, 48) }
                    Button {
                        selectedProvider = provider
                    } label: {
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
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
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
            Text("\(selectedProvider.displayName) API Key (existing account)")
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

            Text("This app only reads your existing sales data. It does not sell or unlock digital content.")
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
                    Text("Connect Existing Account")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 22)
        }
        .buttonStyle(.borderedProminent)
        .tint(.salesGreen)
        .controlSize(.large)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .disabled(apiKey.isEmpty || isValidating)
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
        isValidating = true
        let key = apiKey
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
}
