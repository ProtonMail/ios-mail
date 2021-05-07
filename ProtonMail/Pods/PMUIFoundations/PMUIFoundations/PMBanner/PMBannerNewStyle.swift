//
//  PMBannerNewStyle.swift
//  PMUIFoundations
//
//  Created by Greg on 05.11.20.
//

import UIKit

public enum PMBannerNewStyle: PMBannerStyleProtocol {
    case success
    case warning
    case error

    /// Color of banner background
    public var bannerColor: UIColor {
        switch self {
        case .success:
            return UIColorManager.NotificationSuccess
        case .warning:
            return UIColorManager.NotificationWarning
        case .error:
            return UIColorManager.NotificationError
        }
    }

    /// Color of banner text message
    public var bannerTextColor: UIColor {
        switch self {
        case .success, .error:
            return UIColor.white
        case .warning:
            return UIColor.black
        }
    }

    /// Color of assist button background
    public var assistBgColor: UIColor {
        switch self {
        case .success, .warning, .error:
            return UIColorManager.TextInverted.withAlphaComponent(0.2)
        }
    }

    /// Color of assist hightlighted button background
    public var assistHighBgColor: UIColor {
        switch self {
        case .success, .warning, .error:
            return UIColorManager.TextInverted.withAlphaComponent(0.4)
        }
    }

    /// Color of assist button text
    public var assistTextColor: UIColor {
        switch self {
        case .success, .error:
            return UIColor.white
        case .warning:
            return UIColor.black
        }
    }

    /// Color of banner icon
    public var bannerIconColor: UIColor {
        switch self {
        case .success, .warning, .error:
            return UIColor.white
        }
    }

    /// Color of banner icon background
    public var bannerIconBgColor: UIColor {
        switch self {
        case .success, .warning, .error:
            return UIColor.clear
        }
    }

    /// Lock swipe if button is shown
    public var lockSwipeWhenButton: Bool {
        return true
    }

    /// Banner border raius
    public var borderRadius: CGFloat {
        return 6
    }

    /// Banner paddings
    public var borderInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
    }

    /// Message font
    public var messageFont: UIFont {
        return .systemFont(ofSize: 15)
    }

    /// Button font
    public var buttonFont: UIFont {
        return .systemFont(ofSize: 15)
    }

    /// Button vertical alignment
    public var buttonVAlignment: ButtonVAlignment {
        return .center
    }

    /// Button padding to the right banner edge
    public var buttonRightOffset: CGFloat {
        return 16
    }

    /// Button tittle paddings
    public var buttonInsets: UIEdgeInsets? {
        return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
}
