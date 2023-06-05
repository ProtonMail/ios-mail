import Foundation
import ProtonCore_UIFoundations

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
        let color: UIColor
        if #available(iOS 13.0, *) {
            let trait = UITraitCollection(userInterfaceStyle: .dark)
            color = ColorProvider.Shade0.resolvedColor(with: trait)
        } else {
            color = .black
        }
        return color
    }
}
