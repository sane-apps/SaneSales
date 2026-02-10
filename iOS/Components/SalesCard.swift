import SwiftUI

// MARK: - Brand Colors

extension Color {
    // SaneSales accent (green — from Assets.xcassets)
    static let salesAccent = Color("AccentColor")

    // Fallback green if asset not loaded
    static let salesGreen = Color(red: 0.204, green: 0.690, blue: 0.384)
    static let salesGreenLight = Color(red: 0.298, green: 0.780, blue: 0.459)

    // Brand navy (shared SaneApps palette)
    static let brandNavy = Color(red: 0.102, green: 0.153, blue: 0.267)
    static let brandDeepNavy = Color(red: 0.051, green: 0.082, blue: 0.145)

    // Surfaces
    static let surfaceCarbon = Color(red: 0.078, green: 0.078, blue: 0.098)
    static let surfaceSmoke = Color(red: 0.133, green: 0.133, blue: 0.157)

    // Provider brand colors
    static let providerLemonSqueezy = Color(red: 0.988, green: 0.761, blue: 0.200) // #FCC233 yellow
    static let providerGumroad = Color(red: 1.0, green: 0.565, blue: 0.910) // #FF90E8 pink
    static let providerStripe = Color(red: 0.388, green: 0.357, blue: 1.0) // #635BFF indigo

    // Semantic
    static let salesSuccess = Color(red: 0.133, green: 0.773, blue: 0.369) // #22c55e
    static let salesWarning = Color(red: 0.961, green: 0.620, blue: 0.043) // #f59e0b
    static let salesError = Color(red: 0.937, green: 0.267, blue: 0.267) // #ef4444

    // Muted text (replaces .secondary for readability)
    static let textMuted: Color = .primary.opacity(0.7)

    // Platform background
    static var saneBackground: Color {
        #if os(macOS)
            Color(nsColor: .windowBackgroundColor)
        #else
            Color(.systemBackground)
        #endif
    }
}

// MARK: - macOS Visual Effect Background

#if os(macOS)
    struct VisualEffectBackground: NSViewRepresentable {
        let material: NSVisualEffectView.Material
        let blendingMode: NSVisualEffectView.BlendingMode

        init(material: NSVisualEffectView.Material = .hudWindow,
             blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
            self.material = material
            self.blendingMode = blendingMode
        }

        func makeNSView(context _: Context) -> NSVisualEffectView {
            let view = NSVisualEffectView()
            view.material = material
            view.blendingMode = blendingMode
            view.state = .followsWindowActiveState
            return view
        }

        func updateNSView(_ view: NSVisualEffectView, context _: Context) {
            view.material = material
            view.blendingMode = blendingMode
        }
    }
#endif

struct SaneBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        #if os(macOS)
            ZStack {
                VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                LinearGradient(
                    colors: [
                        Color.salesGreen.opacity(0.06),
                        Color.blue.opacity(0.03),
                        Color.salesGreen.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        #else
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color.brandDeepNavy, Color.black]
                    : [Color.saneBackground, Color.salesGreen.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
        #endif
    }
}

// MARK: - Provider Color Helper

extension SalesProviderType {
    var brandColor: Color {
        switch self {
        case .lemonSqueezy: .providerLemonSqueezy
        case .gumroad: .providerGumroad
        case .stripe: .providerStripe
        }
    }
}

// MARK: - Sales Card

struct SalesCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let subtitle: String
    private let iconSystemName: String?
    private let iconAssetName: String?
    var iconColor: Color = .salesGreen
    var trend: Trend?

    init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        iconColor: Color = .salesGreen,
        trend: Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        iconSystemName = icon
        iconAssetName = nil
        self.iconColor = iconColor
        self.trend = trend
    }

    init(
        title: String,
        value: String,
        subtitle: String,
        iconAssetName: String,
        iconColor: Color = .salesGreen,
        trend: Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        iconSystemName = nil
        self.iconAssetName = iconAssetName
        self.iconColor = iconColor
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                iconView
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textMuted)
                Spacer()
                if let trend {
                    trendBadge(trend)
                }
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.callout)
                .foregroundStyle(Color.textMuted)
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(cardBorder)
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.06),
            radius: colorScheme == .dark ? 10 : 8,
            x: 0,
            y: 4
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(colorScheme == .dark
                ? Color.white.opacity(0.07)
                : Color.white
            )
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.10)
                    : Color.black.opacity(0.06),
                lineWidth: 0.5
            )
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconSystemName {
            Image(systemName: iconSystemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
        } else if let iconAssetName {
            Image(iconAssetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(iconColor)
        }
    }

    @ViewBuilder
    private func trendBadge(_ trend: Trend) -> some View {
        HStack(spacing: 3) {
            Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
            Text(trend.label)
        }
        .font(.footnote.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(trend.isPositive ? Color.salesSuccess.opacity(0.15) : Color.salesError.opacity(0.15))
        .foregroundStyle(trend.isPositive ? Color.salesSuccess : Color.salesError)
        .clipShape(Capsule())
    }
}

struct Trend: Sendable {
    let label: String
    let isPositive: Bool
}

// MARK: - Metric Row

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.textMuted)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Glass Section

struct GlassSection<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let icon: String?
    let iconColor: Color
    let content: Content

    init(
        _ title: String,
        icon: String? = nil,
        iconColor: Color = .secondary,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.subheadline)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.leading, 4)

            // Content card
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.07)
                        : Color.white
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.10)
                            : Color.black.opacity(0.06),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.06),
                radius: colorScheme == .dark ? 10 : 8,
                x: 0,
                y: 4
            )
        }
    }
}

// MARK: - Glass Row

struct GlassRow<Content: View>: View {
    let label: String
    let iconSystemName: String?
    let iconAssetName: String?
    let iconColor: Color
    let content: Content

    init(
        _ label: String,
        icon: String? = nil,
        iconColor: Color = .secondary,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        iconSystemName = icon
        iconAssetName = nil
        self.iconColor = iconColor
        self.content = content()
    }

    init(
        _ label: String,
        iconAssetName: String,
        iconColor: Color = .secondary,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        iconSystemName = nil
        self.iconAssetName = iconAssetName
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            if let iconSystemName {
                Image(systemName: iconSystemName)
                    .foregroundStyle(iconColor)
                    .frame(width: 22)
                    .font(.subheadline)
            } else if let iconAssetName {
                Image(iconAssetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(iconColor)
                    .frame(width: 18, height: 18)
                    .frame(width: 22)
            }
            Text(label)
                .font(.subheadline)
            Spacer()
            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Glass Divider

struct GlassDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 48)
    }
}

// MARK: - Status Badge

struct SalesBadge: View {
    let text: String
    let color: Color
    let icon: String?

    init(_ text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.footnote)
            }
            Text(text)
                .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Provider Badge

struct ProviderBadge: View {
    let provider: SalesProviderType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: provider.icon)
                .font(.footnote)
            Text(provider.displayName)
                .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(provider.brandColor.opacity(0.12))
        .foregroundStyle(provider.brandColor)
        .clipShape(Capsule())
    }
}
