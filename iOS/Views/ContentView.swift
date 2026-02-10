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
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label {
                        Text("Dashboard")
                    } icon: {
                        Image("CoinTemplate")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
            OrdersListView()
                .tabItem {
                    Label("Orders", systemImage: "list.bullet.rectangle")
                }
            ProductsView()
                .tabItem {
                    Label("Products", systemImage: "shippingbox.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.salesGreen)
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
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.brandDeepNavy, Color.black]
                : [Color.saneBackground, Color.salesGreen.opacity(0.06)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image("CoinColor")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .padding(.bottom, 4)

            Text("SaneSales")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("Track your sales from\nLemon Squeezy, Gumroad, and Stripe.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var providerPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CHOOSE A PROVIDER")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
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
                                .font(.subheadline)
                            Text(provider.displayName)
                                .font(.subheadline.weight(.medium))
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
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.07)
                        : Color.white)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(colorScheme == .dark
                        ? Color.white.opacity(0.10)
                        : Color.black.opacity(0.06),
                        lineWidth: 0.5)
            )
        }
    }

    private var keyEntrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(selectedProvider.displayName) API Key")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            SecureField("Paste your API key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .autocorrectionDisabled()

            Text(keyHelpText)
                .font(.footnote)
                .foregroundStyle(.secondary)
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
                    Text("Connect \(selectedProvider.displayName)")
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
