//
//  IconProvider.swift
//  ProtonCore-UIFoundations - Created on 08.02.22.
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

public struct ProtonIcon {
    let name: String

    init(name: String) {
        self.name = name
    }
}

@dynamicMemberLookup
public final class IconProviderBase {
    fileprivate init() {}
}

#if canImport(UIKit)
import UIKit

extension IconProviderBase {
    public subscript(dynamicMember keypath: KeyPath<ProtonIconSet, ProtonIcon>) -> UIImage {
        ProtonIconSet.instance[keyPath: keypath].uiImage
    }
    
    public func flag(forCountryCode countryCode: String) -> UIImage {
        ProtonIconSet.instance.flag(forCountryCode: countryCode).uiImage
    }
}

extension ProtonIcon {
    var uiImage: UIImage {
        UIImage(named: name, in: PMUIFoundations.bundle, compatibleWith: nil)!
    }
}
#endif

#if canImport(AppKit)
import AppKit

extension IconProviderBase {
    public subscript(dynamicMember keypath: KeyPath<ProtonIconSet, ProtonIcon>) -> NSImage {
        ProtonIconSet.instance[keyPath: keypath].nsImage
    }
    
    public func flag(forCountryCode countryCode: String) -> NSImage {
        ProtonIconSet.instance.flag(forCountryCode: countryCode).nsImage
    }
}

extension ProtonIcon {
    var nsImage: NSImage {
        PMUIFoundations.bundle.image(forResource: name)!
    }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension IconProviderBase {
    public subscript(dynamicMember keypath: KeyPath<ProtonIconSet, ProtonIcon>) -> Image {
        ProtonIconSet.instance[keyPath: keypath].image
    }
    
    public func flag(forCountryCode countryCode: String) -> Image {
        ProtonIconSet.instance.flag(forCountryCode: countryCode).image
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ProtonIcon {
    var image: Image { Image(name, bundle: PMUIFoundations.bundle) }
}
#endif

public let IconProvider = IconProviderBase()
