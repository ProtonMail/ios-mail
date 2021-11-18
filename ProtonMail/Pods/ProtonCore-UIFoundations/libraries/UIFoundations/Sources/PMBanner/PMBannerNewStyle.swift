//
//  PMBannerNewStyle.swift
//  ProtonCore-UIFoundations - Created on 05.11.20.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

public enum PMBannerNewStyle: PMBannerStyleProtocol {
    case success
    case warning
    case error

    /// Color of banner background
    public var bannerColor: UIColor {
        switch self {
        case .success:
            return ColorProvider.NotificationSuccess
        case .warning:
            return ColorProvider.NotificationWarning
        case .error:
            return ColorProvider.NotificationError
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
            return ColorProvider.TextInverted.withAlphaComponent(0.2)
        }
    }

    /// Color of assist hightlighted button background
    public var assistHighBgColor: UIColor {
        switch self {
        case .success, .warning, .error:
            return ColorProvider.TextInverted.withAlphaComponent(0.4)
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
