//
//  DriveExclusiveTemporarilyAvailableColorProvider.swift
//  ProtonCore-UIFoundations - Created on 19.05.22.
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

import ProtonCore_Utilities

@dynamicMemberLookup
public final class DriveExclusiveTemporarilyAvailableColorProviderMobileBase {
    fileprivate init() {}
}

@dynamicMemberLookup
public final class DriveExclusiveTemporarilyAvailableColorProviderDesktopBase {
    fileprivate init() {}
}

#if canImport(UIKit)
extension DriveExclusiveTemporarilyAvailableColorProviderMobileBase {
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPaletteiOS, ProtonColor>) -> UIColor {
        ProtonColorPaletteiOS.instance[keyPath: keypath].uiColor
    }
}
extension DriveExclusiveTemporarilyAvailableColorProviderDesktopBase {
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPalettemacOS, ProtonColor>) -> UIColor {
        ProtonColorPalettemacOS.instance[keyPath: keypath].uiColor
    }
}
#endif

#if canImport(AppKit)
extension DriveExclusiveTemporarilyAvailableColorProviderMobileBase {
    
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPaletteiOS, ProtonColor>) -> AppearanceAwareColor {
        AppearanceAwareColor(keypath: keypath)
    }
    
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPaletteiOS, ProtonColor>) -> NSColor {
        if #available(macOS 10.14, *) {
            return color(for: .left(keypath), using: NSApp.effectiveAppearance)
        } else {
            return color(for: .left(keypath), using: NSAppearance.current)
        }
    }
}

extension DriveExclusiveTemporarilyAvailableColorProviderDesktopBase {

    public subscript(dynamicMember keypath: KeyPath<ProtonColorPalettemacOS, ProtonColor>) -> AppearanceAwareColor {
        AppearanceAwareColor(keypath: keypath)
    }
    
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPalettemacOS, ProtonColor>) -> NSColor {
        if #available(macOS 10.14, *) {
            return color(for: .right(keypath), using: NSApp.effectiveAppearance)
        } else {
            return color(for: .right(keypath), using: NSAppearance.current)
        }
    }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension DriveExclusiveTemporarilyAvailableColorProviderMobileBase {
    
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPaletteiOS, ProtonColor>) -> Color {
        ProtonColorPaletteiOS.instance[keyPath: keypath].color
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension DriveExclusiveTemporarilyAvailableColorProviderDesktopBase {
    
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPalettemacOS, ProtonColor>) -> Color {
        ProtonColorPalettemacOS.instance[keyPath: keypath].color
    }
}
#endif

public let DriveExclusiveTemporarilyAvailableColorProviderMobile = DriveExclusiveTemporarilyAvailableColorProviderMobileBase()
public let DriveExclusiveTemporarilyAvailableColorProviderDesktop = DriveExclusiveTemporarilyAvailableColorProviderDesktopBase()
