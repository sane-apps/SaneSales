import AppKit

@MainActor
enum ActivationPolicyManager {
    static func applyPolicy(showDockIcon: Bool) {
        let policy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        guard let app = NSApp else { return }
        _ = app.setActivationPolicy(policy)
    }
}
