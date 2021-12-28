//
//  NSColor+Helper.swift
//  ProtonCore-UIFoundations - Created on 20.11.20.
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

#if os(macOS)
import AppKit

extension NSColor {
    convenience init?(named name: String, in bundle: Bundle?, compatibleWith: Any?) {
        self.init(named: name, bundle: bundle)
    }
    
    public class func dynamic(lightRGB: Int, lightAlpha: CGFloat, darkRGB: Int, darkAlpha: CGFloat) -> NSColor {
        dynamic(light: NSColor(rgb: lightRGB, alpha: lightAlpha), dark: NSColor(rgb: darkRGB, alpha: darkAlpha))
    }
    
    public class func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        if #available(OSX 10.15, *) {
            return NSColor(name: nil) {
                switch $0.name {
                case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                    return dark
                default:
                    return light
                }
            }
        } else {
            return light
        }
    }
}

public extension NSColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        assert(alpha >= 0.0 && alpha <= 1.0, "Invalid alpha component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
    
    convenience init(rgb: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            alpha: alpha
        )
    }
}

#endif
