//
//  PMBannerStyle.swift
//  ProtonCore-UIFoundations - Created on 31.08.20.
//
//  Copyright (c) 2022 Proton Technologies AG
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

public enum ButtonVAlignment {
    case center
    case bottom
}

public protocol PMBannerStyleProtocol {
    var bannerColor: UIColor { get }
    var bannerTextColor: UIColor { get }
    var assistBgColor: UIColor { get }
    var assistHighBgColor: UIColor { get }
    var assistTextColor: UIColor { get }
    var bannerIconColor: UIColor { get }
    var bannerIconBgColor: UIColor { get }

    var lockSwipeWhenButton: Bool { get }
    var borderRadius: CGFloat { get }
    var borderInsets: UIEdgeInsets { get }
    var messageFont: UIFont { get }
    var buttonFont: UIFont { get }
    var buttonVAlignment: ButtonVAlignment { get }
    var buttonMargin: CGFloat { get }
    var buttonInsets: UIEdgeInsets? { get }
}

extension PMBannerStyleProtocol {

    /// Lock swipe if button is shown
    public var lockSwipeWhenButton: Bool {
        return false
    }

    /// Banner border radius
    public var borderRadius: CGFloat {
        return 8
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
    public var buttonMargin: CGFloat {
        return 13
    }

    /// Button tittle paddings
    public var buttonInsets: UIEdgeInsets? {
        return nil
    }
}
