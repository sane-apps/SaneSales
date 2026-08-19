import Foundation
import SaneUI

enum OpenSourceRelease {
    static let donationURL = SaneDonation.githubSponsorsURL

    static func activate() {
        UserDefaults.standard.set(true, forKey: "SANEAPPS_OPEN_SOURCE")
        setenv("SANEAPPS_FORCE_PRO_MODE", "1", 1)
    }
}
