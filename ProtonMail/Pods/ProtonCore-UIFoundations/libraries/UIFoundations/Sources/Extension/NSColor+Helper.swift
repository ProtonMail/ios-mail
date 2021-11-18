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
#endif
