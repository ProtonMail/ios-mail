//
//  PMBannerStyle.swift
//  ProtonMail - Created on 31.08.20.
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

public enum ButtonVAlignment {
    case center
    case bottom
}

public protocol PMBannerStyleProtocol {
    var bannerColor: UIColor {get}
    var bannerTextColor: UIColor {get}
    var assistBgColor: UIColor {get}
    var assistHighBgColor: UIColor {get}
    var assistTextColor: UIColor {get}
    var bannerIconColor: UIColor {get}
    var bannerIconBgColor: UIColor {get}

    var lockSwipeWhenButton: Bool {get}
    var borderRadius: CGFloat {get}
    var borderInsets: UIEdgeInsets {get}
    var messageFont: UIFont {get}
    var buttonFont: UIFont {get}
    var buttonVAlignment: ButtonVAlignment {get}
    var buttonRightOffset: CGFloat {get}
    var buttonInsets: UIEdgeInsets? {get}
}

extension PMBannerStyleProtocol {

    /// Lock swipe if button is shown
    public var lockSwipeWhenButton: Bool {
        return false
    }

    /// Banner border raius
    public var borderRadius: CGFloat {
        return 4
    }

    /// Banner paddings
    public var borderInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }

    /// Message font
    public var messageFont: UIFont {
        return .boldSystemFont(ofSize: 15)
    }

    /// Button font
    public var buttonFont: UIFont {
        return .systemFont(ofSize: 13)
    }

    /// Button vertical alignment
    public var buttonVAlignment: ButtonVAlignment {
        return .bottom
    }

    /// Button padding to the right banner edge
    public var buttonRightOffset: CGFloat {
        return 13
    }

    /// Button tittle paddings
    public var buttonInsets: UIEdgeInsets? {
        return nil
    }
}

public enum PMBannerStyle: PMBannerStyleProtocol {
    case success
    case warning
    case error
    case info

    /// Color of banner background
    public var bannerColor: UIColor {
        switch self {
        case .success:
            return FunctionalColors._Green
        case .warning:
            return FunctionalColors._Yellow
        case .error:
            return FunctionalColors._Red
        case .info:
            return SolidColors._N9
        }
    }

    /// Color of banner text message
    public var bannerTextColor: UIColor {
        switch self {
        case .success, .warning, .error, .info:
            return UIColor.white
        }
    }

    /// Color of assist button background
    public var assistBgColor: UIColor {
        switch self {
        case .success, .warning, .error, .info:
            return UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
        }
    }

    /// Color of assist hightlighted button background
    public var assistHighBgColor: UIColor {
        switch self {
        case .success, .warning, .error, .info:
            return UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
        }
    }

    /// Color of assist button text
    public var assistTextColor: UIColor {
        switch self {
        case .success, .warning, .error, .info:
            return UIColor.white
        }
    }

    /// Color of banner icon
    public var bannerIconColor: UIColor {
        switch self {
        case .success, .warning, .error, .info:
            return UIColor.white
        }
    }

    /// Color of banner icon background
    public var bannerIconBgColor: UIColor {
        switch self {
        case .success, .warning, .error, .info:
            return UIColor.clear
        }
    }

    /// Button position inside view
    public var radius: Float {
        return 4
    }

    /// Button position inside view
    public var buttonVAlignment: ButtonVAlignment {
        return .bottom
    }

}
