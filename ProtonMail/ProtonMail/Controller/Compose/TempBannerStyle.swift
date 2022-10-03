// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_UIFoundations
import UIKit

// This is a temporary workaround of banner style
// Should be deleted after upgrading to the correct core library
// 3.3.2+, depends on the situation
enum TempPMBannerNewStyle: PMBannerStyleProtocol {
    case success
    case warning
    case error
    case info

    /// Color of banner background
    var bannerColor: UIColor {
        switch self {
        case .success:
            return ColorProvider.NotificationSuccess
        case .warning:
            return ColorProvider.NotificationWarning
        case .error:
            return ColorProvider.NotificationError
        case .info:
            return UIColor(named: "NotificationInfo") ?? .black
        }
    }

    /// Color of banner text message
    var bannerTextColor: UIColor {
        switch self {
        case .success, .error:
            return UIColor.white
        case .warning:
            return UIColor.black
        case .info:
            return ColorProvider.TextInverted
        }
    }

    /// Color of assist button background
    var assistBgColor: UIColor {
        switch self {
        case .success, .warning, .error, .info:
            return ColorProvider.TextInverted.withAlphaComponent(0.2)
        }
    }

    /// Color of assist highlighted button background
    var assistHighBgColor: UIColor {
        switch self {
        case .success, .warning, .error, .info:
            return ColorProvider.TextInverted.withAlphaComponent(0.4)
        }
    }

    /// Color of assist button text
    var assistTextColor: UIColor {
        switch self {
        case .success, .error:
            return UIColor.white
        case .warning:
            return UIColor.black
        case .info:
            return ColorProvider.TextInverted
        }
    }

    /// Color of banner icon
    var bannerIconColor: UIColor {
        switch self {
        case .success, .warning, .error:
            return UIColor.white
        case .info:
            return ColorProvider.IconInverted
        }
    }

    /// Color of banner icon background
    var bannerIconBgColor: UIColor {
        switch self {
        case .success, .warning, .error, .info:
            return UIColor.clear
        }
    }

    /// Lock swipe if button is shown
    var lockSwipeWhenButton: Bool {
        return false
    }

    /// Banner border radius
    var borderRadius: CGFloat {
        return 6
    }

    /// Banner paddings
    var borderInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 12)
    }

    /// Message font
    var messageFont: UIFont {
        return .preferredFont(forTextStyle: .subheadline)
    }

    /// Button font
    var buttonFont: UIFont {
        return .preferredFont(forTextStyle: .subheadline)
    }

    /// Button vertical alignment
    var buttonVAlignment: ButtonVAlignment {
        return .center
    }

    /// Button tittle paddings
    var buttonInsets: UIEdgeInsets? {
        return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
}
