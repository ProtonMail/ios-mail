//
//  Brand.swift
//  ProtonCore-UIFoundations - Created on 16/11/2021.
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

import Foundation

public enum Brand {
    case proton
    case vpn
    
    public static var currentBrand: Brand = .proton
}

#if canImport(UIKit)

import UIKit

open class DarkModeAwareNavigationViewController: UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }
}

public func darkModeAwareValue<T>(value: () -> T, protonFallback: () -> T, vpnFallback: () -> T) -> T {
    if #available(iOS 13, *) {
        return value()
    } else if ColorProvider.brand == .vpn {
        return vpnFallback()
    } else {
        return protonFallback()
    }
}

public func darkModeAwarePreferredStatusBarStyle() -> UIStatusBarStyle {
    darkModeAwareValue { .default } protonFallback: { .default } vpnFallback: { .lightContent }
}

#endif

#if os(macOS)

public func darkModeAwareValue<T>(value: () -> T, protonFallback: () -> T, vpnFallback: () -> T) -> T {
    if #available(OSX 10.14, *) {
        return value()
    } else if ColorProvider.brand == .vpn {
        return vpnFallback()
    } else {
        return protonFallback()
    }
}

#endif
