//
//  InAppTheme.swift
//  ProtonCore-UIFoundations - Created on 05/06/2023.
//
//  Copyright (c) 2023 Proton Technologies AG
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
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum InAppTheme {
    case light
    case dark
    case matchSystem

    public static let `default`: InAppTheme = .matchSystem

    #if canImport(UIKit)
    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .matchSystem:
            return .unspecified
        }
    }
    #elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
    public var appearance: NSAppearance.Name {
        switch self {
        case .light:
            return NSAppearance.Name.aqua
        case .dark:
            if #available(macOS 10.14, macOSApplicationExtension 10.14, *) {
                return NSAppearance.Name.darkAqua
            } else {
                return NSAppearance.current.name
            }
        case .matchSystem:
            return NSAppearance.current.name
        }
    }
    #endif
}
