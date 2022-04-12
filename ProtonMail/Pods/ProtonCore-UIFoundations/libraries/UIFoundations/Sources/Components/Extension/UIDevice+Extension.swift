//
//  UIDevice+Extension.swift
//  ProtonCore-UIFoundations - Created on 03.06.2021
//
//  Copyright (c) 2021 Proton Technologies AG
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

// swiftlint:disable identifier_name

import Foundation
import UIKit

public extension UIDevice {
    
    var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    var isSmallIphone: Bool {
        return screenType == .iPhones_4_4S || screenType == .iPhones_5_5s_5c_SE
    }

    enum ScreenType: String {
        case iPhones_4_4S = "iPhone 4 or iPhone 4S"
        case iPhones_5_5s_5c_SE = "iPhone 5, iPhone 5s, iPhone 5c or iPhone SE"
        case iPhones_6_6s_7_8 = "iPhone 6, iPhone 6S, iPhone 7 or iPhone 8"
        case iPhones_6Plus_6sPlus_7Plus_8Plus = "iPhone 6 Plus, iPhone 6S Plus, iPhone 7 Plus or iPhone 8 Plus"
        case iPhones_XR_11 = "iPhone XR or iPhone 11"
        case iPhones_X_XS_11Pro_12Mini = "iPhone X or iPhone XS or iPhone 11 Pro or iPhone 12 mini"
        case iPhone_12 = "iPhone 12"
        case iPhones_XSMax_11ProMax = "iPhone XS Max or iPhone 11 Pro Max"
        case unknown
    }

    var screenType: ScreenType {
        switch UIScreen.main.nativeBounds.height {
        case 960:
            return .iPhones_4_4S
        case 1136:
            return .iPhones_5_5s_5c_SE
        case 1334:
            return .iPhones_6_6s_7_8
        case 1792:
            return .iPhones_XR_11
        case 1920, 2208:
            return .iPhones_6Plus_6sPlus_7Plus_8Plus
        case 2436:
            return .iPhones_X_XS_11Pro_12Mini
        case 2532:
            return .iPhone_12
        case 2688:
            return .iPhones_XSMax_11ProMax
        default:
            return .unknown
        }
    }
}
