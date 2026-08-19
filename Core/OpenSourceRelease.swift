import Foundation

enum OpenSourceRelease {
    static let donationURL = URL(string: "https://github.com/sponsors/MrSaneApps")!

    static func activate() {
        setenv("SANEAPPS_FORCE_PRO_MODE", "1", 1)
    }
}
