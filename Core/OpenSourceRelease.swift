import Foundation

enum OpenSourceRelease {
    #if !APP_STORE
        static let donationURL = URL(string: "https://github.com/sponsors/MrSaneApps")!
    #endif

    static func activate() {
        UserDefaults.standard.set(true, forKey: "SANEAPPS_OPEN_SOURCE")
        setenv("SANEAPPS_FORCE_PRO_MODE", "1", 1)
    }
}
