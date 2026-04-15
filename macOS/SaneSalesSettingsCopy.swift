#if os(macOS)
import Foundation
import SaneUI

enum SaneSalesSettingsCopy {
    static let tabGeneralTitle = String(
        localized: "sanesales.settings.tab.general",
        defaultValue: "General"
    )
    static let tabProvidersTitle = String(
        localized: "sanesales.settings.tab.providers",
        defaultValue: "Providers"
    )
    static let tabDataTitle = String(
        localized: "sanesales.settings.tab.data",
        defaultValue: "Data"
    )
    static let tabLicenseTitle = String(
        localized: "sanesales.settings.tab.license",
        defaultValue: "License"
    )
    static let tabAboutTitle = String(
        localized: "sanesales.settings.tab.about",
        defaultValue: "About"
    )

    static let appearanceSectionTitle = String(
        localized: "sanesales.settings.section.appearance",
        defaultValue: "Appearance"
    )
    static let showInMenuBarLabel = String(
        localized: "sanesales.settings.appearance.show_in_menu_bar",
        defaultValue: "Show in Menu Bar"
    )
    static let showRevenueInMenuBarLabel = String(
        localized: "sanesales.settings.appearance.show_revenue_in_menu_bar",
        defaultValue: "Show Revenue in Menu Bar"
    )
    static let desktopWidgetsLabel = String(
        localized: "sanesales.settings.appearance.desktop_widgets",
        defaultValue: "Desktop Widgets"
    )
    static let appearanceUnlockHint = String(
        localized: "sanesales.settings.appearance.unlock_hint",
        defaultValue: "Unlock Pro to keep revenue in your menu bar and add desktop widgets."
    )
    static let unlockProButtonTitle = String(
        localized: "sanesales.settings.appearance.unlock_button",
        defaultValue: "Unlock Pro"
    )
    static let availabilityHint = String(
        localized: "sanesales.settings.appearance.availability_hint",
        defaultValue: "SaneSales always keeps either the Dock or menu bar available so you can reopen it."
    )

    static let softwareUpdatesSectionTitle = String(
        localized: "sanesales.settings.section.software_updates",
        defaultValue: "Software Updates"
    )
    static let providersSectionTitle = String(
        localized: "sanesales.settings.section.accounts",
        defaultValue: "Accounts"
    )
    static let snapshotSectionTitle = String(
        localized: "sanesales.settings.section.snapshot",
        defaultValue: "Snapshot"
    )
    static let actionsSectionTitle = String(
        localized: "sanesales.settings.section.actions",
        defaultValue: "Actions"
    )
    static let lastUpdatedLabel = String(
        localized: "sanesales.settings.data.last_updated",
        defaultValue: "Last Updated"
    )
    static let cachedOrdersLabel = String(
        localized: "sanesales.settings.data.cached_orders",
        defaultValue: "Cached Orders"
    )
    static let productsLabel = String(
        localized: "sanesales.settings.data.products",
        defaultValue: "Products"
    )
    static let demoModeLabel = String(
        localized: "sanesales.settings.data.demo_mode",
        defaultValue: "Demo Mode"
    )
    static let refreshDataLabel = String(
        localized: "sanesales.settings.actions.refresh_data",
        defaultValue: "Refresh Data"
    )
    static let refreshButtonTitle = String(
        localized: "sanesales.settings.actions.refresh_button",
        defaultValue: "Refresh"
    )
    static let refreshingButtonTitle = String(
        localized: "sanesales.settings.actions.refreshing_button",
        defaultValue: "Refreshing..."
    )
    static let exportOrdersCSVLabel = String(
        localized: "sanesales.settings.actions.export_orders_csv",
        defaultValue: "Export Orders (CSV)"
    )
    static let exportButtonTitle = String(
        localized: "sanesales.settings.actions.export_button",
        defaultValue: "Export"
    )
    static let unlockButtonTitle = String(
        localized: "sanesales.settings.actions.unlock_button",
        defaultValue: "Unlock"
    )
    static let connectedStatusTitle = String(
        localized: "sanesales.settings.providers.connected_status",
        defaultValue: "Connected"
    )
    static let changeKeyButtonTitle = String(
        localized: "sanesales.settings.providers.change_key_button",
        defaultValue: "Change Key"
    )
    static let disconnectButtonTitle = String(
        localized: "sanesales.settings.providers.disconnect_button",
        defaultValue: "Disconnect"
    )
    static let manageButtonTitle = String(
        localized: "sanesales.settings.providers.manage_button",
        defaultValue: "Manage"
    )
    static let connectButtonTitle = String(
        localized: "sanesales.settings.providers.connect_button",
        defaultValue: "Connect"
    )
    static let widgetsEnabledTitle = String(
        localized: "sanesales.settings.widgets.enabled",
        defaultValue: "Enabled"
    )
    static let widgetsReadyTitle = String(
        localized: "sanesales.settings.widgets.ready",
        defaultValue: "Ready"
    )
    static let disconnectConfirmationFormat = String(
        localized: "sanesales.settings.providers.disconnect_confirmation_format",
        defaultValue: "Disconnect %@?"
    )
    static let providerFallbackName = String(
        localized: "sanesales.settings.providers.provider_fallback_name",
        defaultValue: "Provider"
    )
    static let disconnectConfirmationMessage = String(
        localized: "sanesales.settings.providers.disconnect_confirmation_message",
        defaultValue: "This will remove the API key and cached data for this provider."
    )
    static let providerSummaryAttachmentLabel = String(
        localized: "sanesales.settings.about.provider_summary_attachment",
        defaultValue: "Connected providers and local cache summary"
    )
    static let connectAccountTitleFormat = String(
        localized: "sanesales.settings.sheet.connect_account_title_format",
        defaultValue: "Connect %@ Account"
    )
    static let apiKeyPlaceholder = String(
        localized: "sanesales.settings.sheet.api_key_placeholder",
        defaultValue: "API Key"
    )
    static let apiKeyReadOnlyHint = String(
        localized: "sanesales.settings.sheet.api_key_read_only_hint",
        defaultValue: "Reads your existing sales data. Nothing is modified."
    )
    static let cancelButtonTitle = String(
        localized: "sanesales.settings.sheet.cancel_button",
        defaultValue: "Cancel"
    )
    static let saveButtonTitle = String(
        localized: "sanesales.settings.sheet.save_button",
        defaultValue: "Save"
    )
    static let okButtonTitle = String(
        localized: "sanesales.settings.sheet.ok_button",
        defaultValue: "OK"
    )
    static let invalidAPIKeyTitle = String(
        localized: "sanesales.settings.error.invalid_api_key_title",
        defaultValue: "Invalid API Key"
    )
    static let invalidAPIKeyMessage = String(
        localized: "sanesales.settings.error.invalid_api_key_message",
        defaultValue: "The server rejected this key. Check it and try again."
    )
    static let connectionFailedTitle = String(
        localized: "sanesales.settings.error.connection_failed_title",
        defaultValue: "Connection Failed"
    )
    static let networkErrorMessage = String(
        localized: "sanesales.settings.error.network_error_message",
        defaultValue: "Couldn't reach the server. Check your internet connection and try again."
    )
    static let rateLimitedTitle = String(
        localized: "sanesales.settings.error.rate_limited_title",
        defaultValue: "Rate Limited"
    )
    static let rateLimitedMessage = String(
        localized: "sanesales.settings.error.rate_limited_message",
        defaultValue: "Too many requests. Wait a moment and try again."
    )
    static let serverErrorTitle = String(
        localized: "sanesales.settings.error.server_error_title",
        defaultValue: "Server Error"
    )
    static let serverErrorMessageFormat = String(
        localized: "sanesales.settings.error.server_error_message_format",
        defaultValue: "The server returned an error (%d). Try again later."
    )
    static let genericConnectionFailedMessage = String(
        localized: "sanesales.settings.error.generic_connection_failed_message",
        defaultValue: "Could not connect with that key. Check it and try again."
    )
    static let lemonSqueezyAPIHelpText = String(
        localized: "sanesales.settings.sheet.lemonsqueezy_api_help",
        defaultValue: "lemonsqueezy.com → Settings → API"
    )
    static let gumroadAPIHelpText = String(
        localized: "sanesales.settings.sheet.gumroad_api_help",
        defaultValue: "gumroad.com → Settings → Advanced → Applications"
    )
    static let stripeAPIHelpText = String(
        localized: "sanesales.settings.sheet.stripe_api_help",
        defaultValue: "dashboard.stripe.com → Developers → API keys (use Secret key)"
    )

    static func disconnectConfirmationTitle(providerName: String?) -> String {
        String(format: disconnectConfirmationFormat, providerName ?? providerFallbackName)
    }

    static func connectAccountTitle(providerName: String) -> String {
        String(format: connectAccountTitleFormat, providerName)
    }

    static func serverErrorMessage(code: Int) -> String {
        String(format: serverErrorMessageFormat, code)
    }

    static let aboutLabels = SaneAboutView.Labels(
        githubButtonTitle: String(
            localized: "sanesales.settings.about.github_button",
            defaultValue: "GitHub"
        ),
        licensesButtonTitle: String(
            localized: "sanesales.settings.about.licenses_button",
            defaultValue: "Licenses"
        ),
        reportBugButtonTitle: String(
            localized: "sanesales.settings.about.report_bug_button",
            defaultValue: "Report a Bug"
        ),
        viewIssuesButtonTitle: String(
            localized: "sanesales.settings.about.view_issues_button",
            defaultValue: "View Issues"
        ),
        trustPrefix: String(
            localized: "sanesales.settings.about.trust_prefix",
            defaultValue: "Made with"
        ),
        trustSuffix: String(
            localized: "sanesales.settings.about.trust_suffix",
            defaultValue: "in the USA"
        ),
        secondaryTrustLine: String(
            localized: "sanesales.settings.about.secondary_trust_line",
            defaultValue: "On-Device by Default · No Personal Data"
        ),
        licenseSourceLabel: String(
            localized: "sanesales.settings.about.license_source_label",
            defaultValue: "Source"
        ),
        openSourceButtonTitle: String(
            localized: "sanesales.settings.about.open_source_button",
            defaultValue: "Open Source"
        ),
        licensesSheetTitle: String(
            localized: "sanesales.settings.about.licenses_sheet_title",
            defaultValue: "Licenses"
        ),
        doneButtonTitle: String(
            localized: "sanesales.settings.about.done_button",
            defaultValue: "Done"
        )
    )

    static let languageLabels = SaneLanguageSettingsRow.Labels(
        sectionTitle: String(
            localized: "sanesales.settings.language.section_title",
            defaultValue: "Language"
        ),
        currentLanguageLabel: String(
            localized: "sanesales.settings.language.current_language",
            defaultValue: "App Language"
        ),
        changeButtonTitle: String(
            localized: "sanesales.settings.language.change_button",
            defaultValue: "Change"
        ),
        helperText: String(
            localized: "sanesales.settings.language.helper",
            defaultValue: "Change the app language in System Settings. Restart the app if macOS has not refreshed the UI yet."
        ),
        singleLanguageHelperText: String(
            localized: "sanesales.settings.language.single_language_helper",
            defaultValue: "Add more app localizations to enable per-app language switching in System Settings."
        )
    )

    static let sparkleLabels = SaneSparkleRow.Labels(
        automaticCheckLabel: String(
            localized: "sanesales.settings.updates.automatic_check_label",
            defaultValue: "Check for updates automatically"
        ),
        automaticCheckHelp: String(
            localized: "sanesales.settings.updates.automatic_check_help",
            defaultValue: "Periodically check for new versions"
        ),
        checkFrequencyLabel: String(
            localized: "sanesales.settings.updates.frequency_label",
            defaultValue: "Check frequency"
        ),
        checkFrequencyHelp: String(
            localized: "sanesales.settings.updates.frequency_help",
            defaultValue: "Choose how often automatic update checks run"
        ),
        actionsLabel: String(
            localized: "sanesales.settings.updates.actions_label",
            defaultValue: "Actions"
        ),
        checkingLabel: String(
            localized: "sanesales.settings.updates.checking_label",
            defaultValue: "Checking..."
        ),
        checkNowLabel: String(
            localized: "sanesales.settings.updates.check_now_label",
            defaultValue: "Check Now"
        ),
        checkNowHelp: String(
            localized: "sanesales.settings.updates.check_now_help",
            defaultValue: "Check for updates right now"
        ),
        dailyTitle: String(
            localized: "sanesales.settings.updates.daily_title",
            defaultValue: "Daily"
        ),
        weeklyTitle: String(
            localized: "sanesales.settings.updates.weekly_title",
            defaultValue: "Weekly"
        )
    )

    static let licenseLabels: LicenseSettingsView<LicenseService>.Labels = .init(
        sectionTitle: String(
            localized: "sanesales.settings.license.section_title",
            defaultValue: "License"
        ),
        warningSectionTitle: String(
            localized: "sanesales.settings.license.warning_section_title",
            defaultValue: "Status"
        ),
        statusLabel: String(
            localized: "sanesales.settings.license.status_label",
            defaultValue: "Status"
        ),
        actionsLabel: String(
            localized: "sanesales.settings.license.actions_label",
            defaultValue: "Actions"
        ),
        basicBadgeTitle: String(
            localized: "sanesales.settings.license.basic_badge",
            defaultValue: "Basic"
        ),
        proBadgeTitle: String(
            localized: "sanesales.settings.license.pro_badge",
            defaultValue: "Pro"
        ),
        restorePurchasesLabel: String(
            localized: "sanesales.settings.license.restore_purchases",
            defaultValue: "Restore Purchases"
        ),
        managedBySetappLabel: String(
            localized: "sanesales.settings.license.managed_by_setapp",
            defaultValue: "Managed by Setapp"
        ),
        includedWithSetappLabel: String(
            localized: "sanesales.settings.license.included_with_setapp",
            defaultValue: "Included with Setapp"
        ),
        processingLabel: String(
            localized: "sanesales.settings.license.processing",
            defaultValue: "Processing..."
        ),
        unlockProPrefix: String(
            localized: "sanesales.settings.license.unlock_prefix",
            defaultValue: "Unlock Pro —"
        ),
        fallbackPriceLabel: "$24.99",
        directEntryLabel: String(
            localized: "sanesales.settings.license.enter_license_key",
            defaultValue: "Enter License Key"
        ),
        directManagementLabel: String(
            localized: "sanesales.settings.license.deactivate_pro",
            defaultValue: "Deactivate Pro"
        )
    )
}
#endif
