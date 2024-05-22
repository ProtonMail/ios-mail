import Foundation
import ProtonCoreUIFoundations
import UIKit

extension String {

    static var empty: String {
        return ""
    }

    static var skeletonTemplate: String {
        return "SkeletonTemplate"
    }

    static var toSubscriptionPage: String {
        return "Subscription"
    }

    static var toWebSupportForm: String {
        return "toWebSupportForm"
    }

    static var toWebBrowser: String {
        return "toWebBrowser"
    }

    static var webSupportFormLink: String {
        return "https://proton.me/support/contact"
    }

    static var fullDecryptionFailedViewLink: String {
        return "https://protonmail.local/decryption-failed-detail"
    }

    static var rebrandingReadMoreLink: String {
        "https://proton.me/news/updated-proton"
    }

    static var highlightTextColor: UIColor {
            let trait = UITraitCollection(userInterfaceStyle: .dark)
        return ColorProvider.Shade0.resolvedColor(with: trait)
    }
}
