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

public struct ProtonColor {
    let name: String
    let vpnFallbackRgb: Int?

    init(name: String, vpnFallbackRgb: Int? = nil) {
        self.name = name
        self.vpnFallbackRgb = vpnFallbackRgb
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
    var uiColor: UIColor {
        if #available(iOS 13.0, *) {
            return color(name: name)
        } else {
            if ProtonColorPallete.brand == .vpn, let vpnFallbackRgb = vpnFallbackRgb {
                return UIColor(rgb: vpnFallbackRgb)
            } else {
                return color(name: name)
            }
        }
    }
    
    private func color(name: String) -> UIColor {
        UIColor(named: name, in: PMUIFoundations.bundle, compatibleWith: nil)!
    }
}

public extension UIColor {
    
    internal var hsba: HSBA {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return HSBA(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    var computedStrongVariant: UIColor {
        let hsbaStrong = computeStrongVariant(from: hsba)
        return UIColor(hue: hsbaStrong.hue, saturation: hsbaStrong.saturation, brightness: hsbaStrong.brightness, alpha: hsbaStrong.alpha)
    }
    
    var computedIntenseVariant: UIColor {
        let hsbaIntense = computeIntenseVariant(from: hsba)
        return UIColor(hue: hsbaIntense.hue, saturation: hsbaIntense.saturation, brightness: hsbaIntense.brightness, alpha: hsbaIntense.alpha)
    }
}

#endif

#if canImport(AppKit)
import AppKit

public struct AppearanceAwareColor {
    private let keypath: KeyPath<ProtonColorPallete, ProtonColor>
    
    init(keypath: KeyPath<ProtonColorPallete, ProtonColor>) {
        self.keypath = keypath
    }
    
    public func using(appearance: NSAppearance) -> NSColor {
        color(for: keypath, using: appearance)
    }
}

private func color(for keypath: KeyPath<ProtonColorPallete, ProtonColor>, using appearance: NSAppearance) -> NSColor {
    var color: NSColor = .clear
    if #available(macOS 11.0, *) {
        appearance.performAsCurrentDrawingAppearance {
            color = fetchColor(keypath: keypath)
        }
    } else {
        let currentAppearance = NSAppearance.current
        NSAppearance.current = appearance
        color = fetchColor(keypath: keypath)
        NSAppearance.current = currentAppearance
    }
    return color
}

private func fetchColor(keypath: KeyPath<ProtonColorPallete, ProtonColor>) -> NSColor {
    let palleteColor = ProtonColorPallete.instance[keyPath: keypath].nsColor
    if let componentColor = palleteColor.usingType(.componentBased) {
        return componentColor
    } else {
        assertionFailure("This color cannot be interpreted as component color. It breaks the assumptions related to macOS appearance")
        return palleteColor
    }
}

extension ColorProviderBase {
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPallete, ProtonColor>) -> AppearanceAwareColor {
        AppearanceAwareColor(keypath: keypath)
    }
    
    /// By default, the fetched color appearance matches NSApp.effectiveAppearance.
    /// Use .using(appearance: NSAppearance) to customize that.
    public subscript(dynamicMember keypath: KeyPath<ProtonColorPallete, ProtonColor>) -> NSColor {
        if #available(macOS 10.14, *) {
            return color(for: keypath, using: NSApp.effectiveAppearance)
        } else {
            return color(for: keypath, using: NSAppearance.current)
        }
    }
}

extension ProtonColor {
    var nsColor: NSColor {
        if #available(OSX 10.14, *) {
            return color(name: name)
        } else {
            if ProtonColorPallete.brand == .vpn, let vpnFallbackRgb = vpnFallbackRgb {
                return NSColor(rgb: vpnFallbackRgb)
            } else {
                return color(name: name)
            }
        }
    }
    
    private func color(name: String) -> NSColor {
        NSColor(named: name, bundle: PMUIFoundations.bundle)!
    }
}

public extension NSColor {
    
    private var hsba: HSBA? {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard let srgbColor = usingColorSpace(.sRGB) else { return nil }
        srgbColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return HSBA(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    var computedStrongVariant: NSColor {
        guard let hsba = hsba else {
            assertionFailure("This color cannot be interpreted in right color space. It breaks the assumptions related to variant computation")
            return self
        }
        let hsbaStrong = computeStrongVariant(from: hsba)
        return NSColor(colorSpace: .sRGB, hue: hsbaStrong.hue, saturation: hsbaStrong.saturation, brightness: hsbaStrong.brightness, alpha: hsbaStrong.alpha)
    }
    
    var computedIntenseVariant: NSColor {
        guard let hsba = hsba else {
            assertionFailure("This color cannot be interpreted in right color space. It breaks the assumptions related to variant computation")
            return self
        }
        let hsbaIntense = computeIntenseVariant(from: hsba)
        return NSColor(colorSpace: .sRGB, hue: hsbaIntense.hue, saturation: hsbaIntense.saturation, brightness: hsbaIntense.brightness, alpha: hsbaIntense.alpha)
    }
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

#if canImport(UIKit)
private typealias NativeColor = UIColor
#elseif canImport(AppKit)
private typealias NativeColor = NSColor
#endif

@available(iOS 14.0, OSX 11.0, tvOS 14.0, watchOS 7.0, *)
public extension Color {
    var computedStrongVariant: Color {
        Color(NativeColor(self).computedStrongVariant)
    }

    var computedIntenseVariant: Color {
        Color(NativeColor(self).computedIntenseVariant)
    }
}
#endif

public let ColorProvider = ColorProviderBase()

@available(*, deprecated, renamed: "ColorProvider")
public let ColorManager = ColorProviderBase()

@available(*, deprecated, renamed: "ColorProvider")
public let UIColorManager = ColorProviderBase()

struct HSBA: Equatable { let hue: CGFloat; let saturation: CGFloat; let brightness: CGFloat; let alpha: CGFloat }
struct HSLA: Equatable { let hue: CGFloat; let saturation: CGFloat; let lightness: CGFloat; let alpha: CGFloat }

func hsbaToHSLA(hsba: HSBA) -> HSLA {
    // algorighm taken from https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_HSL
    let lightnessHSLA = hsba.brightness * (1.0 - hsba.saturation / 2)
    let saturationHSLA: CGFloat
    if lightnessHSLA == 0.0 || lightnessHSLA == 1.0 {
        saturationHSLA = 0.0
    } else {
        saturationHSLA = (hsba.brightness - lightnessHSLA) / min(lightnessHSLA, 1.0 - lightnessHSLA)
    }
    return HSLA(hue: hsba.hue, saturation: saturationHSLA, lightness: lightnessHSLA, alpha: hsba.alpha)
}

func computeStrongVariant(from hsla: HSLA) -> HSLA {
    let hueStrong = max(hsla.hue, 0.0)
    let lightnessStrong = max(hsla.lightness - 0.1, 0.0)
    let saturationStrong = max(hsla.saturation - 0.05, 0.0)
    return HSLA(hue: hueStrong, saturation: saturationStrong, lightness: lightnessStrong, alpha: hsla.alpha)
}

func computeStrongVariant(from hsba: HSBA) -> HSBA {
    let hsla = hsbaToHSLA(hsba: hsba)
    let hslaStrong = computeStrongVariant(from: hsla)
    return hslaToHSBA(hsla: hslaStrong)
}

func computeIntenseVariant(from hsla: HSLA) -> HSLA {
    let hueStrong = max(hsla.hue, 0.0)
    let lightnessStrong = max(hsla.lightness - 0.17, 0.0)
    let saturationStrong = max(hsla.saturation - 0.05, 0.0)
    return HSLA(hue: hueStrong, saturation: saturationStrong, lightness: lightnessStrong, alpha: hsla.alpha)
}

func computeIntenseVariant(from hsba: HSBA) -> HSBA {
    let hsla = hsbaToHSLA(hsba: hsba)
    let hslaStrong = computeIntenseVariant(from: hsla)
    return hslaToHSBA(hsla: hslaStrong)
}

func hslaToHSBA(hsla: HSLA) -> HSBA {
    // algorighm taken from https://en.wikipedia.org/wiki/HSL_and_HSV#HSL_to_HSV
    let brightnessHSBA = hsla.lightness + hsla.saturation * min(hsla.lightness, 1.0 - hsla.lightness)
    let saturationHSBA: CGFloat
    if brightnessHSBA == 0.0 {
        saturationHSBA = 0.0
    } else {
        saturationHSBA = 2.0 * (1.0 - hsla.lightness / brightnessHSBA)
    }
    return HSBA(hue: hsla.hue, saturation: saturationHSBA, brightness: brightnessHSBA, alpha: hsla.alpha)
}
