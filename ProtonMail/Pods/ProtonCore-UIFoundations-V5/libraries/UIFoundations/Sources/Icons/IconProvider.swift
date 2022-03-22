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
    let vpnFallbackName: String?

    init(name: String, vpnFallbackName: String? = nil) {
        self.name = name
        self.vpnFallbackName = vpnFallbackName
    }
}

@dynamicMemberLookup
public final class IconProviderBase {
    public var brand: Brand {
        get { Brand.currentBrand }
        set { Brand.currentBrand = newValue }
    }
    fileprivate init() {}
}

#if canImport(UIKit)
import UIKit

extension IconProviderBase {

    public subscript(dynamicMember keypath: KeyPath<ProtonIconSet, ProtonIcon>) -> UIImage {
        guard let image = ProtonIconSet.instance[keyPath: keypath].uiImage else {
            assertionFailure("lack of image in assets catalogue indicates the images misconfiguration")
            return UIImage()
        }
        return image
    }
    
    public func flag(forCountryCode countryCode: String) -> UIImage? {
        ProtonIconSet.instance.flag(forCountryCode: countryCode).uiImage
    }
}

extension ProtonIcon {
    var uiImage: UIImage? {
        darkModeAwareValue {
            image(name: name)
        } protonFallback: {
            image(name: name)
        } vpnFallback: {
            image(name: vpnFallbackName ?? name)
        }
    }
    
    private func image(name: String) -> UIImage? {
        UIImage(named: name, in: PMUIFoundations.bundle, compatibleWith: nil)
    }
}
#endif

#if canImport(AppKit)
import AppKit

public struct DarkModePreferingIcon {
    private let keypath: KeyPath<ProtonIconSet, ProtonIcon>
    
    init(keypath: KeyPath<ProtonIconSet, ProtonIcon>) {
        self.keypath = keypath
    }
    
    public func darkModePrefering() -> NSImage {
        guard let image = ProtonIconSet.instance[keyPath: keypath].darkModePreferingNSImage else {
            assertionFailure("lack of image in assets catalogue indicates the images misconfiguration")
            return NSImage()
        }
        return image
    }
    
    #if canImport(SwiftUI)
    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
    public func darkModePrefering() -> Image {
        let nsImage: NSImage = darkModePrefering()
        return Image(nsImage: nsImage)
    }
    #endif
}

extension IconProviderBase {
    
    public subscript(dynamicMember keypath: KeyPath<ProtonIconSet, ProtonIcon>) -> DarkModePreferingIcon {
        DarkModePreferingIcon(keypath: keypath)
    }
    
    /// By default, the fetched color appearance matches NSApp.effectiveAppearance.
    /// Use .using(appearance: NSAppearance) to customize that.
    public subscript(dynamicMember keypath: KeyPath<ProtonIconSet, ProtonIcon>) -> NSImage {
        guard let image = ProtonIconSet.instance[keyPath: keypath].nsImage else {
            assertionFailure("lack of image in assets catalogue indicates the images misconfiguration")
            return NSImage()
        }
        return image
    }
    
    public func flag(forCountryCode countryCode: String) -> NSImage? {
        ProtonIconSet.instance.flag(forCountryCode: countryCode).nsImage
    }
}

extension ProtonIcon {
    var nsImage: NSImage? {
        darkModeAwareValue {
            image(name: name)
        } protonFallback: {
            image(name: name)
        } vpnFallback: {
            image(name: vpnFallbackName ?? name)
        }
    }
    
    var darkModePreferingNSImage: NSImage? {
        image(name: vpnFallbackName ?? name)
    }
    
    private func image(name: String) -> NSImage? {
        PMUIFoundations.bundle.image(forResource: name)
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
    
    public func flag(forCountryCode countryCode: String) -> Image? {
        #if canImport(UIKit)
        let uiImage: UIImage? = flag(forCountryCode: countryCode)
        guard let image = uiImage else { return nil }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        let nsImage: NSImage? = flag(forCountryCode: countryCode)
        guard let image = nsImage else { return nil }
        return Image(nsImage: image)
        #else
        return ProtonIconSet.instance.flag(forCountryCode: countryCode).image
        #endif
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ProtonIcon {
    var image: Image { Image(name, bundle: PMUIFoundations.bundle) }
}
#endif

public let IconProvider = IconProviderBase()
