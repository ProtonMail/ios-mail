// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public enum DS {}

public enum MailColor: Sendable {}
public enum MailIcon: Sendable {}


public extension MailColor {
    static let backgroundSecondary = Color(.backgroundSecondary)

    static let checkbox = Color(.mobileBrandNorm)

    static let strokeDark = Color(.protonCarbonBorderNorm)

    static let backgroundNorm = Color(.mobileBackgroundNorm)

    static let textWeak = Color(.mobileTextWeak)
    static let textNorm = Color(.mobileTextNorm)
}

public extension MailIcon {
    static let icCheckmark = icon(named: "ic-checkmark")
    static let icStar = icon(named: "ic-star")
    static let icStarFilled = icon(named: "ic-star-filled")
}

private extension MailIcon {
    static func icon(named: String) -> UIImage {
        UIImage(named: named, in: .module, with: nil)!
    }
}
