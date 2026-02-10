import Foundation

/// Central place for SF Symbol names we treat as part of the app "brand".
/// Keeping these in one spot prevents drift (and makes swaps easy).
enum SFSymbols {
    /// "Coin" brand mark.
    ///
    /// Note: `coins.fill` is not present on some macOS symbol sets, so we use a
    /// broadly-available symbol that still reads as "money".
    static let coin = "dollarsign.circle.fill"

    /// Fallback that should exist broadly (kept separate for call sites that try/??).
    static let coinFallback = "dollarsign.circle"
}
