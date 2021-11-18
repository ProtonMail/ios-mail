//
//  ColorProvider.swift
//  ProtonCore-UIFoundations - Created on 04.11.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
}

public struct ProtonColor {
    let name: String
    init(name: String) {
        self.name = name
    }
}

@dynamicMemberLookup
public final class ColorProviderBase {
    public var brand: Brand {
        get { ProtonColorPallete.brand }
        set { ProtonColorPallete.brand = newValue }
    }
    fileprivate init() {}
}

#if canImport(UIKit)
import UIKit

extension ColorProviderBase {
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPallete, ProtonColor>) -> UIColor {
        ProtonColorPallete.instance[keyPath: keypath].uiColor
    }
}

extension ProtonColor {
    var uiColor: UIColor { UIColor(named: name, in: PMUIFoundations.bundle, compatibleWith: nil)! }
}
#endif

#if canImport(AppKit)
import AppKit

extension ColorProviderBase {
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPallete, ProtonColor>) -> NSColor {
        ProtonColorPallete.instance[keyPath: keypath].nsColor
    }
}

extension ProtonColor {
    var nsColor: NSColor { NSColor(named: name, bundle: PMUIFoundations.bundle)! }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ColorProviderBase {
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPallete, ProtonColor>) -> Color {
        ProtonColorPallete.instance[keyPath: keypath].color
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ProtonColor {
    var color: Color { Color(name, bundle: PMUIFoundations.bundle) }
}
#endif

public let ColorProvider = ColorProviderBase()

@available(*, deprecated, renamed: "ColorProvider")
public let ColorManager = ColorProviderBase()

@available(*, deprecated, renamed: "ColorProvider")
public let UIColorManager = ColorProviderBase()
