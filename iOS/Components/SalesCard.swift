import SwiftUI

// MARK: - Platform Font Scaling

extension Font {
    /// Body text that reads well on both iOS and macOS
    static var saneBody: Font {
        #if os(macOS)
            .system(size: 15)
        #else
            .body
        #endif
    }

    /// Subheadline that doesn't shrink to nothing on Mac
    static var saneSubheadline: Font {
        #if os(macOS)
            .system(size: 14, weight: .medium)
        #else
            .subheadline.weight(.medium)
        #endif
    }

    /// Callout / secondary text
    static var saneCallout: Font {
        #if os(macOS)
            .system(size: 14)
        #else
            .callout
        #endif
    }

    /// Section header
    static var saneSectionHeader: Font {
        #if os(macOS)
            .system(size: 13, weight: .semibold)
        #else
            .subheadline.weight(.semibold)
        #endif
    }

    /// Subheadline with semibold weight (for names, titles in rows)
    static var saneSubheadlineBold: Font {
        #if os(macOS)
            .system(size: 14, weight: .semibold)
        #else
            .subheadline.weight(.semibold)
        #endif
    }

    /// Footnote text
    static var saneFootnote: Font {
        #if os(macOS)
            .system(size: 12, weight: .medium)
        #else
            .footnote
        #endif
    }

    /// Card value (big number)
    static func saneCardValue(size: CGFloat = 28) -> Font {
        #if os(macOS)
            .system(size: size + 6, weight: .bold, design: .rounded)
        #else
            .system(size: size, weight: .bold, design: .rounded)
        #endif
    }
}

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
    static let salesGold = Color(red: 0.85, green: 0.65, blue: 0.13) // Accumulated value / All Time

    // Dashboard metric semantic colors (kept distinct from provider colors).
    static let metricToday = salesSuccess
    static let metricMonth = Color(red: 0.122, green: 0.620, blue: 0.973) // Sky blue
    static let metricRolling30 = Color(red: 0.698, green: 0.498, blue: 0.988) // Violet
    static let metricAllTime = Color(red: 0.243, green: 0.875, blue: 0.827) // Aqua

    // Brand blue for glows (matches SaneBackground ambient)
    static let brandBlueGlow = Color(red: 0.31, green: 0.56, blue: 0.98)

    // Muted text tuned for high contrast in dark mode.
    static var textMuted: Color {
        #if os(iOS) || os(tvOS) || os(watchOS)
            Color(UIColor { trait in
                if trait.userInterfaceStyle == .dark {
                    return UIColor.white.withAlphaComponent(0.92)
                }
                return UIColor.label.withAlphaComponent(0.88)
            })
        #elseif os(macOS)
            Color(NSColor(name: nil) { appearance in
                if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                    return NSColor.white.withAlphaComponent(0.92)
                }
                return NSColor.labelColor.withAlphaComponent(0.88)
            })
        #else
            .primary.opacity(0.9)
        #endif
    }

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

        init(material: NSVisualEffectView.Material = .sidebar,
             blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
            self.material = material
            self.blendingMode = blendingMode
        }

        func makeNSView(context _: Context) -> NSVisualEffectView {
            let view = NSVisualEffectView()
            view.material = material
            view.blendingMode = blendingMode
            view.state = .active
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
            if colorScheme == .dark {
                // Brand blue ambient glow — materials blur this to create frosted glass.
                // Only the brand color (blue #4f8ffa) — no decorative colors.
                ZStack {
                    Color(red: 0.04, green: 0.05, blue: 0.10)

                    Circle()
                        .fill(Color(red: 0.31, green: 0.56, blue: 0.98).opacity(0.20))
                        .frame(width: 400, height: 400)
                        .blur(radius: 140)
                        .offset(x: -120, y: -180)

                    Circle()
                        .fill(Color(red: 0.31, green: 0.56, blue: 0.98).opacity(0.14))
                        .frame(width: 320, height: 320)
                        .blur(radius: 120)
                        .offset(x: 180, y: 160)
                }
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.92, green: 0.95, blue: 0.99),
                        Color(red: 0.94, green: 0.96, blue: 1.0)
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
    #if os(macOS)
        @State private var isHovered = false
    #endif

    let title: String
    let value: String
    let subtitle: String
    private let iconSystemName: String?
    private let iconAssetName: String?
    var iconColor: Color = .salesGreen
    var trend: Trend?

    // Keep card internals optically consistent across all KPI cards.
    private let headerRowHeight: CGFloat = 38
    private let trendBadgeHeight: CGFloat = 30
    private let trendBadgeWidth: CGFloat = 58

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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                iconView
                Text(title)
                    .font(.saneSubheadline)
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .layoutPriority(1)
                Spacer(minLength: 0)
                if let trend {
                    trendBadge(trend)
                }
            }
            .frame(height: headerRowHeight)

            Text(value)
                .font(.saneCardValue())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(subtitle)
                .font(.saneCallout)
                .foregroundStyle(Color.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(cardBorder)
        .shadow(
            color: colorScheme == .dark ? Color.brandBlueGlow.opacity(0.25) : Color.brandBlueGlow.opacity(0.10),
            radius: colorScheme == .dark ? 12 : 8,
            x: 0,
            y: 4
        )
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.15) : .clear,
            radius: 6,
            x: 0,
            y: 2
        )
        #if os(macOS)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(subtitle)")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.brandBlueGlow.opacity(colorScheme == .dark ? 0.08 : 0.04))
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(
                Color.brandBlueGlow.opacity(colorScheme == .dark ? 0.20 : 0.12),
                lineWidth: 1
            )
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconSystemName {
            Image(systemName: iconSystemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)
        } else if let iconAssetName {
            Image(iconAssetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func trendBadge(_ trend: Trend) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))
            Text(trend.label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(width: trendBadgeWidth, height: trendBadgeHeight)
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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.saneSectionHeader)
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
            .shadow(
                color: colorScheme == .dark ? Color.brandBlueGlow.opacity(0.25) : Color.brandBlueGlow.opacity(0.10),
                radius: colorScheme == .dark ? 12 : 8,
                x: 0,
                y: 4
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.15) : .clear,
                radius: 6,
                x: 0,
                y: 2
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
                    .accessibilityHidden(true)
            } else if let iconAssetName {
                Image(iconAssetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(iconColor)
                    .frame(width: 18, height: 18)
                    .frame(width: 22)
                    .accessibilityHidden(true)
            }
            Text(label)
                .font(.saneBody)
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
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// MARK: - Provider Badge

struct ProviderBadge: View {
    let provider: SalesProviderType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: provider.icon)
                .font(.footnote)
                .accessibilityHidden(true)
            Text(provider.displayName)
                .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(provider.brandColor.opacity(0.12))
        .foregroundStyle(provider.brandColor)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(provider.displayName) provider")
    }
}
